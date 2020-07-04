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

namespace wap {

void binding_objc_method(ObjcMethodHook *hook, id _self, SEL _sel, void* args[]);

}

#endif /* wap_objc_method_bridge_hpp */
