//
//  wap_objc_method_bridge.hpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_method_bridge_hpp
#define wap_objc_method_bridge_hpp

#import <Foundation/Foundation.h>
#import "wap_objc_method_hook.h"
#import "../runtime/wap_objc_define.h"

namespace wap {

void binding_objc_method(ObjcMethodHook *hook, id _self, SEL _sel, void *ret, void* args[]);

// Wrap a native value (read from `arg` per the Objective-C type `encoding`)
// into a WAPInternalObject the wasm side can consume. Defined in the bridge.
WAPInternalObject* CreateObjectFromObjcTypeEncoding(const char * encoding, void * arg);

}

#endif /* wap_objc_method_bridge_hpp */
