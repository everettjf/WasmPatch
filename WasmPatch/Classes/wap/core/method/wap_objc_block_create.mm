//
//  wap_objc_block_create.mm
//  WasmPatch
//

#import "wap_objc_block_create.h"
#import "wap_objc_method_bridge.h"      // CreateObjectFromObjcTypeEncoding
#import "wap_objc_method_signature.h"
#import "../runtime/wap_objc_runtime.h"
#import "../runtime/wap_objc_define.h"

#include <ffi.h>
#include <vector>
#include <mutex>

// Provided by the Block runtime in libSystem.
extern "C" void * _NSConcreteGlobalBlock[32];

extern "C" id objc_retainBlock(id);

namespace wap {

enum {
    WAP_BLOCK_IS_GLOBAL    = (1 << 28),
    WAP_BLOCK_HAS_SIGNATURE = (1 << 30),
};

struct WAPBlockDescriptorLayout {
    unsigned long reserved;
    unsigned long size;
    const char *signature; // present because WAP_BLOCK_HAS_SIGNATURE is set
};

struct WAPBlockLiteralLayout {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    WAPBlockDescriptorLayout *descriptor;
};

// Everything needed to keep one synthesized block alive and to service its
// invocations.
struct WAPBlockContext {
    std::string funcName;
    ObjcMethodSignature signature;      // full block signature (arg 0 == @? self)
    std::string signatureStorage;       // backing for descriptor->signature
    ffi_closure *closure = nullptr;
    void *closureFn = nullptr;
    ffi_cif cif{};
    ffi_type **argTypes = nullptr;
    WAPBlockLiteralLayout block{};
    WAPBlockDescriptorLayout descriptor{};
};

static std::vector<WAPBlockContext *> g_blocks;
static std::mutex g_blocksMutex;

static char NormalizedLeadChar(const std::string & enc) {
    if (enc.empty()) return 0;
    return (enc.size() > 1 && enc[0] == 'r') ? enc[1] : enc[0];
}

// libffi closure handler: runs on the host's call into the block.
static void BlockTrampoline(ffi_cif *cif, void *ret, void **args, void *user_data) {
    WAPBlockContext *ctx = (WAPBlockContext *)user_data;
    const auto &argTypes = ctx->signature.getArgumentTypes(); // [0] is the block itself
    unsigned int total = ctx->signature.getArgumentCount();

    // Marshal the real arguments (skip arg 0, the block pointer) into an array.
    WAPInternalArray *arr = new WAPInternalArray();
    for (unsigned int i = 1; i < total; ++i) {
        WAPInternalObject *o = CreateObjectFromObjcTypeEncoding(argTypes[i].c_str(), args[i]);
        arr->items.push_back((WAPObject)o);
    }

    NSString *arrAddr = [NSString stringWithFormat:@"%llu", (unsigned long long)(uintptr_t)arr];
    const char *params[2] = { arrAddr.UTF8String, NULL };

    WasmRuntime &rt = ObjcRuntime::instance().runtime();

    char r = NormalizedLeadChar(ctx->signature.getReturnType());
    switch (r) {
        case 0:
        case 'v': {
            rt.call<uint32_t>(ctx->funcName.c_str(), params, 1, nullptr);
            break;
        }
        case '@': {
            uint64_t handle = 0;
            if (rt.call<uint64_t>(ctx->funcName.c_str(), params, 1, &handle) && handle && ret) {
                WAPInternalObject *obj = GetInternalObject((WAPObject)handle);
                id value = obj ? obj->value : nil;
                if (obj) { delete obj; }
                *(void **)ret = (__bridge void *)value;
            } else if (ret) {
                *(void **)ret = nullptr;
            }
            break;
        }
        case 'd': {
            double v = 0;
            if (rt.call<double>(ctx->funcName.c_str(), params, 1, &v) && ret) { *(double *)ret = v; }
            break;
        }
        case 'f': {
            float v = 0;
            if (rt.call<float>(ctx->funcName.c_str(), params, 1, &v) && ret) { *(float *)ret = v; }
            break;
        }
        case 'q': case 'Q': case 'l': case 'L': {
            uint64_t v = 0;
            if (rt.call<uint64_t>(ctx->funcName.c_str(), params, 1, &v) && ret) { *(uint64_t *)ret = v; }
            break;
        }
        default: { // 32-bit scalars and BOOL
            uint32_t v = 0;
            if (rt.call<uint32_t>(ctx->funcName.c_str(), params, 1, &v) && ret) { *(uint32_t *)ret = v; }
            break;
        }
    }

    for (WAPObject item : arr->items) {
        WAPInternalObject *o = GetInternalObject(item);
        if (o) { delete o; }
    }
    delete arr;
}

id CreateWasmBlock(const std::string & funcName, const std::string & encoding, std::string & errorOut) {
    if (funcName.empty() || encoding.empty()) {
        errorOut = "create_block: function name and signature are required";
        return nil;
    }

    WAPBlockContext *ctx = new WAPBlockContext();
    ctx->funcName = funcName;
    ctx->signatureStorage = encoding;
    ctx->signature.parse(encoding.c_str());

    unsigned int total = ctx->signature.getArgumentCount();
    if (total < 1) {
        errorOut = "create_block: malformed block signature (need at least the @? block self)";
        delete ctx;
        return nil;
    }

    ffi_type *returnType = ctx->signature.getFFIReturnType();
    ctx->argTypes = ctx->signature.mallocFFIArgumentTypes();
    if (!returnType || !ctx->argTypes) {
        errorOut = "create_block: unsupported block signature types";
        free(ctx->argTypes);
        delete ctx;
        return nil;
    }

    ctx->closure = (ffi_closure *)ffi_closure_alloc(sizeof(ffi_closure), &ctx->closureFn);
    if (!ctx->closure) {
        errorOut = "create_block: ffi_closure_alloc failed";
        free(ctx->argTypes);
        delete ctx;
        return nil;
    }

    if (ffi_prep_cif(&ctx->cif, FFI_DEFAULT_ABI, total, returnType, ctx->argTypes) != FFI_OK ||
        ffi_prep_closure_loc(ctx->closure, &ctx->cif, BlockTrampoline, ctx, ctx->closureFn) != FFI_OK) {
        errorOut = "create_block: failed to prepare ffi closure";
        ffi_closure_free(ctx->closure);
        free(ctx->argTypes);
        delete ctx;
        return nil;
    }

    // Assemble a global block whose invoke is the closure. Global blocks make
    // Block_copy/Block_release no-ops, so ARC won't try to relocate our custom
    // layout; lifetime is owned by g_blocks instead.
    ctx->descriptor.reserved = 0;
    ctx->descriptor.size = sizeof(WAPBlockLiteralLayout);
    ctx->descriptor.signature = ctx->signatureStorage.c_str();

    ctx->block.isa = (void *)&_NSConcreteGlobalBlock;
    ctx->block.flags = WAP_BLOCK_IS_GLOBAL | WAP_BLOCK_HAS_SIGNATURE;
    ctx->block.reserved = 0;
    ctx->block.invoke = (void (*)(void *, ...))ctx->closureFn;
    ctx->block.descriptor = &ctx->descriptor;

    {
        std::lock_guard<std::mutex> lock(g_blocksMutex);
        g_blocks.push_back(ctx);
    }

    errorOut.clear();
    return (__bridge id)(void *)&ctx->block;
}

void ClearWasmBlocks() {
    std::lock_guard<std::mutex> lock(g_blocksMutex);
    for (WAPBlockContext *ctx : g_blocks) {
        if (ctx->closure) { ffi_closure_free(ctx->closure); }
        free(ctx->argTypes);
        delete ctx;
    }
    g_blocks.clear();
}

}
