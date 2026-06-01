//
//  wap_objc_block.h
//  WasmPatch
//
//  Minimal Objective-C block support: extract a block's encoded signature and
//  invoke it through libffi. This lets a patch that replaces a method *call
//  back* a completion handler it was handed (the common B3 use case). Creating
//  brand-new blocks from wasm to pass into Obj-C is not covered here.
//

#ifndef wap_objc_block_h
#define wap_objc_block_h

#import <Foundation/Foundation.h>
#include <stdint.h>

namespace wap {

// ABI flags from the Block runtime (see clang's Block_private.h).
enum {
    WAP_BLOCK_HAS_COPY_DISPOSE = (1 << 25),
    WAP_BLOCK_HAS_SIGNATURE    = (1 << 30),
};

struct WAPBlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    // optionally followed by copy/dispose helpers, then the signature string.
};

struct WAPBlockLayout {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct WAPBlockDescriptor *descriptor;
};

// Returns the block's Objective-C type encoding (e.g. "v@?@"), or nullptr when
// the block carries no signature.
static inline const char * BlockSignature(id blockObject) {
    if (!blockObject) {
        return nullptr;
    }
    WAPBlockLayout *block = (__bridge WAPBlockLayout *)blockObject;
    if (!(block->flags & WAP_BLOCK_HAS_SIGNATURE)) {
        return nullptr;
    }
    uint8_t *p = (uint8_t *)block->descriptor + sizeof(WAPBlockDescriptor);
    if (block->flags & WAP_BLOCK_HAS_COPY_DISPOSE) {
        p += 2 * sizeof(void *); // skip copy + dispose helpers
    }
    return *(const char **)p;
}

// Returns the raw invoke function pointer used by ffi_call.
static inline void * BlockInvokeFunction(id blockObject) {
    if (!blockObject) {
        return nullptr;
    }
    WAPBlockLayout *block = (__bridge WAPBlockLayout *)blockObject;
    return (void *)block->invoke;
}

}

#endif /* wap_objc_block_h */
