//
//  wap_objc_method_bridge.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_method_bridge.h"
#include "wap_objc_define.h"
#include "../runtime/wap_objc_runtime.h"

namespace wap {


WAPInternalObject* CreateObjectFromObjcTypeEncoding(const char * encoding, void * arg) {
    const char *c = encoding;
    
    WAPInternalObject *result = nullptr;
    
    switch (c[0]) {
        case 'v': {
            // &ffi_type_void;
            result = WAPInternalObject::VoidValue();
            break;
        }
        case 'c': {
            // &ffi_type_schar;
            char param = *(char*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'C': {
            // &ffi_type_uchar;
            unsigned char param = *(unsigned char *)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 's': {
            // &ffi_type_sshort;
            short param = *(short*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'S': {
            // &ffi_type_ushort;
            unsigned short param = *(unsigned short*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'i': {
            // &ffi_type_sint;
            int param = *(int*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            
            break;
        }
        case 'I': {
            // &ffi_type_uint;
            char param = *(char*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'l': {
            // &ffi_type_slong;
            long param = *(long*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'L': {
            // &ffi_type_ulong;
            unsigned long param = *(unsigned long*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case 'q': {
            // &ffi_type_sint64;
            int64_t param = *(int64_t*)arg;
            result = WAPInternalObject::PlainValue("int64", @(param));
            break;
        }
        case 'Q': {
            // &ffi_type_uint64;
            uint64_t param = *(uint64_t*)arg;
            result = WAPInternalObject::PlainValue("int64", @(param));
            break;
        }
        case 'f': {
            // &ffi_type_float;
            float param = *(float*)arg;
            result = WAPInternalObject::PlainValue("float", @(param));
            break;
        }
        case 'd': {
            // &ffi_type_double;
            double param = *(double*)arg;
            result = WAPInternalObject::PlainValue("double", @(param));
            break;
        }
        case 'F': {
#if CGFLOAT_IS_DOUBLE
            // &ffi_type_double;
            double param = *(double*)arg;
            result = WAPInternalObject::PlainValue("double", @(param));
            break;
#else
            // &ffi_type_float;
            float param = *(float*)arg;
            result = WAPInternalObject::PlainValue("float", @(param));
            break;
#endif
        }
        case 'B': {
            // &ffi_type_uint8;
            uint8_t param = *(uint8_t*)arg;
            result = WAPInternalObject::PlainValue("int32", @(param));
            break;
        }
        case '^': {
            // &ffi_type_pointer;
            int64_t param = *(int64_t*)arg;
            result = WAPInternalObject::PlainValue("int64", @(param));
            break;
        }
        case '@': {
            // &ffi_type_pointer;
            id param = (__bridge id)(*(void**)arg);
            result = WAPInternalObject::ObjcValue("objc", param);
            break;
        }
        case '#': {
            // &ffi_type_pointer;
            int64_t param = *(int64_t*)arg;
            result = WAPInternalObject::PlainValue("int64", @(param));
            break;
        }
        case ':': {
            // &ffi_type_pointer;
            int64_t param = *(int64_t*)arg;
            result = WAPInternalObject::PlainValue("int64", @(param));
            break;
        }
        case '{': {
            // // http://www.chiark.greenend.org.uk/doc/libffi-dev/html/Type-Example.html
            // todo : struct
            break;
        }
        default: {
            break;
        }
    }
    
    return result;
}

void binding_objc_method(ObjcMethodHook *hook, id _self, SEL _sel, void* args[]) {
    
    ObjcMethodSignature *signature = &(hook->signature);
    
    NSUInteger argumentCount = signature->getArgumentCount();
    
    if (argumentCount < 2) {
        // error
        printf("error : argument count < 2");
        return;
    }
    
    if (argumentCount == 2) {
        // no more arguments except self and cmd
        WAPObject _selfObject = WAPCreateObjectFromObjcValue("objc", _self);
        NSString *_selfString = [NSString stringWithFormat:@"%llu", _selfObject];
        const char *_selString = sel_getName(_sel);
        
        const char * parameters[3] = {
            _selfString.UTF8String,
            _selString,
            NULL
        };
        
        u32 ret = 0;
        wap::ObjcRuntime::instance().runtime().call(hook->replacementName.c_str(), parameters, 2, &ret);
        return;
    }
    
    // has >=3 arguments (including self and cmd)
    WAPInternalArray * array = new WAPInternalArray();
    const auto & argumentTypes = signature->getArgumentTypes();
    for (NSUInteger idx = 2; idx < argumentCount; ++idx) {
        std::string argumentType = argumentTypes[idx];
        WAPInternalObject *object = CreateObjectFromObjcTypeEncoding(argumentType.c_str(), args[idx]);
        
        array->items.push_back((WAPObject)object);
    }
    
    WAPObject _selfObject = WAPCreateObjectFromObjcValue("objc", _self);
    NSString *_selfString = [NSString stringWithFormat:@"%llu", _selfObject];
    const char *_selString = sel_getName(_sel);
    
    NSString *_arrayString = [NSString stringWithFormat:@"%llu", (WAPArray)array];
    
    const char * parameters[4] = {
        _selfString.UTF8String,
        _selString,
        _arrayString.UTF8String,
        NULL
    };

    u32 ret = 0;
    wap::ObjcRuntime::instance().runtime().call(hook->replacementName.c_str(), parameters, 3, &ret);
}


}
