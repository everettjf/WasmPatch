//
//  wap_objc_export_basic.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_export_basic_h
#define wap_objc_export_basic_h

#include "../wap_objc_define.h"


WAPObject alloc_objc_class(WAPClassName class_name) {
    Class cls = objc_getClass(class_name);
    id val = [cls alloc];
    return WAPCreateObjectFromObjcValue("objc", val);
}

WAPObject alloc_int32(int32_t v) { return WAPCreateObjectFromPlainValue("int32", @(v)); }
WAPObject alloc_int64(int64_t v) { return WAPCreateObjectFromPlainValue("int64", @(v)); }
WAPObject alloc_float(float v) { return WAPCreateObjectFromPlainValue("float", @(v)); }
WAPObject alloc_double(double v) { return WAPCreateObjectFromPlainValue("double", @(v)); }

WAPObject alloc_string(const char* v) {
    NSString * str = [NSString stringWithUTF8String:v];
    return WAPCreateObjectFromPlainValue("string", str);
}
WAPResultVoid print_object(WAPObject a) {
    if (a == 0) {
        return 1;
    }
    WAPInternalObject *obj = GetInternalObject(a);
    if (obj->cate == 'p') {
        NSLog(@"plain: %@",obj->value);
    } else if (obj->cate == 'o') {
        NSLog(@"objc: %@",obj->value);
    } else if (obj->cate == 'v') {
        NSLog(@"Void");
    } else {
        NSLog(@"Unknown object category : %@" , obj->value);
    }
    return 0;
}

WAPResultVoid print_string(const char *str) {
    NSLog(@"%s",(str?:"NULL"));
    return 0;
}

WAPResultVoid dealloc_object(WAPObject a) {
    if (a == 0) {
        return 1;
    }
    WAPInternalObject *obj = GetInternalObject(a);
    delete obj;
    return 0;
}


__WAP_EXPORT_FUNCTION(alloc_objc_class_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (WAPClassName, class_name)
    WAPObject result = alloc_objc_class(class_name);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_int32_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (int32_t, v)
    WAPObject result = alloc_int32(v);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_int64_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (int64_t, v)
    WAPObject result = alloc_int64(v);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_float_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (float, v)
    WAPObject result = alloc_float(v);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_double_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (double, v)
    WAPObject result = alloc_double(v);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_string_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (const char*, v)
    WAPObject result = alloc_string(v);
    m3ApiReturn (result)
}


__WAP_EXPORT_FUNCTION(print_object_raw) {
    m3ApiReturnType (WAPResultVoid)
    m3ApiGetArg  (WAPObject, addr)
    WAPResultVoid result = print_object(addr);
    m3ApiReturn (result)
}


__WAP_EXPORT_FUNCTION(print_string_raw) {
    m3ApiReturnType (WAPResultVoid)
    m3ApiGetArgMem  (const char*, v);
    WAPResultVoid result = print_string(v);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(dealloc_object_raw) {
    m3ApiReturnType (WAPResultVoid)
    m3ApiGetArg  (WAPObject, addr)
    WAPResultVoid result = dealloc_object(addr);
    m3ApiReturn (result)
}

#endif /* wap_objc_export_basic_h */
