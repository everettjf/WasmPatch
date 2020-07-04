//
//  wap_objc_hook.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_hook_h
#define wap_objc_hook_h

#include "../wap_objc_define.h"
#include "../wap_objc_runtime.h"
#include "wap_objc_export_hook.h"
#include "../../method/wap_objc_method.h"

#pragma mark -
#pragma mark 🌈Hook

WAPResultVoid replace_class_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name) {
    auto hook = std::make_shared<wap::ObjcMethodHook>(class_name, selector_name, false, method_name);
    wap::ObjcMethod::instance().addHook(hook);
    return 0;
}

__WAP_EXPORT_FUNCTION(replace_class_method_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (WAPClassName, class_name)
    m3ApiGetArgMem  (WAPSelectorName, selector_name)
    m3ApiGetArgMem  (WAPMethodName, method_name)
    WAPResultVoid ret = replace_class_method(class_name, selector_name, method_name);
    m3ApiReturn (ret)
}

WAPResultVoid replace_instance_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name) {
    auto hook = std::make_shared<wap::ObjcMethodHook>(class_name, selector_name, true, method_name);
    wap::ObjcMethod::instance().addHook(hook);
    return 0;
}

__WAP_EXPORT_FUNCTION(replace_instance_method_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (WAPClassName, class_name)
    m3ApiGetArgMem  (WAPSelectorName, selector_name)
    m3ApiGetArgMem  (WAPMethodName, method_name)
    WAPResultVoid ret = replace_instance_method(class_name, selector_name, method_name);
    m3ApiReturn (ret)
}

#endif /* wap_objc_hook_h */
