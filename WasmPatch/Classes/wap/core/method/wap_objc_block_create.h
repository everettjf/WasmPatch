//
//  wap_objc_block_create.h
//  WasmPatch
//
//  Synthesize an Objective-C block whose body calls back into a wasm export.
//  This is the inverse of invoke_block: it lets a patch hand a completion
//  handler *to* an Objective-C method.
//
//  A block invokes `block->invoke(block, args...)`, so we build a libffi
//  closure as the invoke function and wrap it in a Block_literal. The wasm
//  callback runs when the host later invokes the block (the normal async
//  completion-handler flow) — it must not be invoked while the patch's entry()
//  is still executing, since that would re-enter the wasm runtime.
//

#ifndef wap_objc_block_create_h
#define wap_objc_block_create_h

#import <Foundation/Foundation.h>
#include <string>

namespace wap {

// Create a block for `funcName` (a wasm export of the form
// `WAPObject fn(WAPArray args)`) with the given Objective-C block type
// `encoding` (e.g. "v@?@" for void(^)(id)). Returns the block (an id) or nil,
// with `errorOut` describing the failure. The block is owned by the runtime and
// freed by ClearWasmBlocks() / a runtime reset.
id CreateWasmBlock(const std::string & funcName, const std::string & encoding, std::string & errorOut);

// Release every block created since the last reset.
void ClearWasmBlocks();

}

#endif /* wap_objc_block_create_h */
