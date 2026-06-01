//
//  wap_objc_export_block.h
//  WasmPatch
//
//  invoke_block: call an Objective-C block (e.g. a completion handler passed
//  into a replaced method) from a wasm patch. The block's encoded signature
//  drives the libffi call; arguments come from a WAPArray and are marshalled
//  by the same conventions as method calls.
//

#ifndef wap_objc_export_block_h
#define wap_objc_export_block_h

#include "../wap_objc_define.h"
#include "../wap_objc_runtime.h"
#include "../../method/wap_objc_block.h"
#include "../../method/wap_objc_method_signature.h"
#include <ffi.h>
#include <vector>

// Invoke `block` with the WAPObjects collected in `args`. Returns a WAPObject
// for the block's result (0 for void / on error).
WAPObject invoke_block(WAPObject blockHandle, WAPArray argsHandle) {
    if (blockHandle == 0) {
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: null block");
        return 0;
    }
    WAPInternalObject *blockObj = GetInternalObject(blockHandle);
    if (!blockObj || !blockObj->value) {
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: block object is empty");
        return 0;
    }
    id block = blockObj->value;
    const char *signature = wap::BlockSignature(block);
    if (!signature) {
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: block carries no signature");
        return 0;
    }

    wap::ObjcMethodSignature parser;
    parser.parse(signature);
    const auto &argTypes = parser.getArgumentTypes();
    unsigned int totalArgs = parser.getArgumentCount();        // includes block self (@?)
    if (totalArgs < 1) {
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: malformed block signature");
        return 0;
    }
    unsigned int realArgs = totalArgs - 1;

    WAPInternalArray *inputs = GetInternalArray(argsHandle);
    unsigned int provided = inputs ? (unsigned int)inputs->items.size() : 0;
    if (provided != realArgs) {
        wap::EmitLog(wap::LogLevel::Error,
                     std::string("invoke_block: argument count mismatch (got ") + std::to_string(provided) +
                     ", expected " + std::to_string(realArgs) + ")");
        return 0;
    }

    ffi_type *returnType = parser.getFFIReturnType();
    ffi_type **ffiArgs = parser.mallocFFIArgumentTypes();
    if (!returnType || !ffiArgs) {
        free(ffiArgs);
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: unsupported block signature types");
        return 0;
    }

    ffi_cif cif;
    if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, totalArgs, returnType, ffiArgs) != FFI_OK) {
        free(ffiArgs);
        wap::EmitLog(wap::LogLevel::Error, "invoke_block: ffi_prep_cif failed");
        return 0;
    }

    // Backing storage for marshalled argument values; argValues holds pointers
    // into it. Index 0 is always the block pointer itself.
    std::vector<void *> argValues(totalArgs, nullptr);
    std::vector<uint64_t> intStore(totalArgs, 0);
    std::vector<double> floatStore(totalArgs, 0);
    std::vector<float> f32Store(totalArgs, 0);
    std::vector<void *> ptrStore(totalArgs, nullptr);

    void *blockPtr = (__bridge void *)block;
    argValues[0] = &blockPtr;

    for (unsigned int i = 0; i < realArgs; ++i) {
        const std::string &enc = argTypes[i + 1];
        char t = (enc.size() > 1 && enc[0] == 'r') ? enc[1] : enc[0];
        WAPInternalObject *param = GetInternalObject(inputs->items[i]);
        unsigned int slot = i + 1;
        if (!param) {
            argValues[slot] = &intStore[slot];
            continue;
        }
        switch (t) {
            case '@':
            case '#': {
                ptrStore[slot] = (__bridge void *)param->value;
                argValues[slot] = &ptrStore[slot];
                break;
            }
            case '*': {
                NSString *s = (NSString *)param->value;
                ptrStore[slot] = (void *)(s ? s.UTF8String : NULL);
                argValues[slot] = &ptrStore[slot];
                break;
            }
            case 'f': {
                f32Store[slot] = [(NSNumber *)param->value floatValue];
                argValues[slot] = &f32Store[slot];
                break;
            }
            case 'd': {
                floatStore[slot] = [(NSNumber *)param->value doubleValue];
                argValues[slot] = &floatStore[slot];
                break;
            }
            case 'q':
            case 'Q':
            case 'l':
            case 'L': {
                intStore[slot] = (uint64_t)[(NSNumber *)param->value longLongValue];
                argValues[slot] = &intStore[slot];
                break;
            }
            default: { // c C s S i I B and friends -> 32-bit integer
                intStore[slot] = (uint64_t)[(NSNumber *)param->value longLongValue];
                argValues[slot] = &intStore[slot];
                break;
            }
        }
    }

    uint64_t returnBuffer[2] = {0, 0};
    ffi_call(&cif, FFI_FN(wap::BlockInvokeFunction(block)), returnBuffer, argValues.data());
    free(ffiArgs);

    // Wrap the return value.
    const char *retEnc = parser.getReturnType().c_str();
    char r = (retEnc[0] == 'r' && retEnc[1] != 0) ? retEnc[1] : retEnc[0];
    switch (r) {
        case 'v': case 0:
            return 0;
        case '@': case '#': {
            id result = (__bridge id)(*(void **)returnBuffer);
            return WAPCreateObjectFromObjcValue("objc", result);
        }
        case '*': {
            const char *s = *(const char **)returnBuffer;
            return s ? WAPCreateObjectFromPlainValue("string", [NSString stringWithUTF8String:s]) : 0;
        }
        case 'f':
            return WAPCreateObjectFromPlainValue("float", @(*(float *)returnBuffer));
        case 'd':
            return WAPCreateObjectFromPlainValue("double", @(*(double *)returnBuffer));
        case 'q': case 'Q': case 'l': case 'L':
            return WAPCreateObjectFromPlainValue("int64", @(*(int64_t *)returnBuffer));
        default:
            return WAPCreateObjectFromPlainValue("int32", @((int32_t)(*(uint64_t *)returnBuffer)));
    }
}

__WAP_EXPORT_FUNCTION(invoke_block_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg (WAPObject, block)
    m3ApiGetArg (WAPArray, args)
    WAPObject result = invoke_block(block, args);
    m3ApiReturn (result)
}

#endif /* wap_objc_export_block_h */
