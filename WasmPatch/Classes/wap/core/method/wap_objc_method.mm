//
//  wap_objc_method.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_method.h"

namespace wap {

ObjcMethod & ObjcMethod::instance() {
    static ObjcMethod o;
    return o;
}

void ObjcMethod::addHook(ObjcMethodHookPtr hook) {
    hook->hook();
    hooks.push_back(hook);
}

}
