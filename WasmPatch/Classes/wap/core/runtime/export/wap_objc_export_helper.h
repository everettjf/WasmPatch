//
//  wap_objc_export_helper.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_export_helper_h
#define wap_objc_export_helper_h

#include "../wap_objc_define.h"

WAPObject new_objc_nsstring(WAPClassName str) {
    NSString *string = [NSString stringWithUTF8String:str];
    return WAPCreateObjectFromObjcValue("string",string);
}

__WAP_EXPORT_FUNCTION(new_objc_nsstring_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (char*, str)
    WAPObject result = new_objc_nsstring(str);
    m3ApiReturn (result)
}

WAPObject new_objc_nsnumber_int(int value) {
    return WAPCreateObjectFromPlainValue("int32",@(value));
}

__WAP_EXPORT_FUNCTION(new_objc_nsnumber_int_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (int32_t, number)
    WAPObject result = new_objc_nsnumber_int(number);
    m3ApiReturn (result)
}

#endif /* wap_objc_export_helper_h */
