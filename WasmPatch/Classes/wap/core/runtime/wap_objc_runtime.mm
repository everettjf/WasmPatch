//
//  wap_objc_runtime.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_runtime.h"

#include <objc/runtime.h>
#include <vector>
#include <string>

#include "wap_objc_define.h"
#include "wap_objc_export.h"

namespace wap {

ObjcRuntime & ObjcRuntime::instance() {
    static ObjcRuntime obj;
    return obj;
}

bool ObjcRuntime::load(const std::string & path) {
    bool result = _runtime.loadFile(path);
    if (!result) {
        return false;
    }
    
    initRuntime();
    
    if (!_runtime.call("entry")) {
        return false;
    }
    return true;
}

void ObjcRuntime::initRuntime() {
    
    // _runtime.link<call_class_method>("call_class_method", call_class_method_raw);
#define RT_LINK(name) _runtime.link<name>(#name, name##_raw);
    
    // call
    RT_LINK(alloc_objc_class);
    RT_LINK(alloc_int32);
    RT_LINK(alloc_int64);
    RT_LINK(alloc_float);
    RT_LINK(alloc_double);
    RT_LINK(alloc_string);
    
    RT_LINK(print_object);
    RT_LINK(print_string);
    RT_LINK(dealloc_object);
    
    RT_LINK(alloc_array);
    RT_LINK(dealloc_array);
    RT_LINK(append_array);
    RT_LINK(get_array_size);
    RT_LINK(get_array_item);
    
    RT_LINK(call_class_method_param);
    RT_LINK(call_class_method_0);
    RT_LINK(call_class_method_1);
    RT_LINK(call_class_method_2);
    
    RT_LINK(call_instance_method_param);
    RT_LINK(call_instance_method_0);
    RT_LINK(call_instance_method_1);
    RT_LINK(call_instance_method_2);
    
    RT_LINK(new_objc_nsstring);
    RT_LINK(new_objc_nsnumber_int);
    
    RT_LINK(replace_class_method);
    RT_LINK(replace_instance_method);
}

}
