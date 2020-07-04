//
//  wap_objc_export_array.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_export_array_h
#define wap_objc_export_array_h

#include "../wap_objc_define.h"

// Array Exports
WAPArray alloc_array() {
    return (WAPArray)new WAPInternalArray();
}

__WAP_EXPORT_FUNCTION(alloc_array_raw) {
    m3ApiReturnType (WAPArray)
    WAPArray result = alloc_array();
    m3ApiReturn (result)
}

WAPResultVoid dealloc_array(WAPArray addr) {
    // declare
    extern WAPResultVoid dealloc_object(WAPObject a);

    WAPInternalArray *param = GetInternalArray(addr);
    for (auto item : param->items) {
        dealloc_object(item);
    }
    delete param;
    return 0;
}

__WAP_EXPORT_FUNCTION(dealloc_array_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPArray, addr)
    dealloc_array(addr);
    m3ApiReturn (0)
}

WAPResultVoid append_array(WAPArray addr, WAPObject object) {
    WAPInternalArray *array = GetInternalArray(addr);
    array->items.push_back(object);
    return 0;
}

__WAP_EXPORT_FUNCTION(append_array_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPArray, addr)
    m3ApiGetArg  (WAPObject, object)
    append_array(addr, object);
    m3ApiReturn (0)
}

int get_array_size(WAPArray addr) {
    WAPInternalArray *array = GetInternalArray(addr);
    return (int)array->items.size();
}

__WAP_EXPORT_FUNCTION(get_array_size_raw) {
    m3ApiReturnType (int)
    m3ApiGetArg  (WAPArray, addr)
    int result = get_array_size(addr);
    m3ApiReturn(result);
}

WAPObject get_array_item(WAPArray addr, int index) {
    WAPInternalArray *array = GetInternalArray(addr);
    return array->items.at(index);
}

__WAP_EXPORT_FUNCTION(get_array_item_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPArray, addr)
    m3ApiGetArg  (int, index)
    WAPObject result = get_array_item(addr,index);
    m3ApiReturn(result);
}

#endif /* wap_objc_export_array_h */
