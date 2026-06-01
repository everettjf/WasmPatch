//
//  wap_objc_method_bridge.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_method_bridge.h"
#include "wap_objc_define.h"
#include "wap_objc_struct.h"
#include "../runtime/wap_objc_runtime.h"
#include <CoreFoundation/CoreFoundation.h>

extern "C" id objc_autoreleaseReturnValue(id obj);

namespace wap {

static thread_local std::vector<std::string> g_returnedCStringStorage;

template <typename T>
static bool call_replacement(ObjcMethodHook *hook, const char **parameters, int parameterCount, T *outValue) {
    return wap::ObjcRuntime::instance().runtime().call(hook->replacementName.c_str(), parameters, parameterCount, outValue);
}

static const char * normalized_encoding(const std::string & encoding) {
    if (encoding.empty()) {
        return "";
    }
    return encoding[0] == 'r' && encoding.size() > 1 ? encoding.c_str() + 1 : encoding.c_str();
}

static CFTypeRef consume_objc_return_object_ref(uint64_t rawValue) {
    if (rawValue == 0) {
        return nullptr;
    }

    WAPInternalObject *object = GetInternalObject((WAPObject)rawValue);
    if (!object) {
        return nullptr;
    }

    CFTypeRef value = object->value ? CFRetain((__bridge CFTypeRef)object->value) : nullptr;
    delete object;
    return value;
}

static Class consume_objc_return_class(uint64_t rawValue) {
    if (rawValue == 0) {
        return Nil;
    }

    WAPInternalObject *object = GetInternalObject((WAPObject)rawValue);
    if (!object) {
        return Nil;
    }

    Class value = (Class)object->value;
    delete object;
    return value;
}

static const char * consume_c_string_return_value(uint64_t rawValue) {
    if (rawValue == 0) {
        return nullptr;
    }

    WAPInternalObject *object = GetInternalObject((WAPObject)rawValue);
    if (!object) {
        return nullptr;
    }

    const char *result = nullptr;
    if (object->type == "string") {
        NSString *stringValue = (NSString *)object->value;
        if (stringValue) {
            g_returnedCStringStorage.emplace_back(stringValue.UTF8String ?: "");
            result = g_returnedCStringStorage.back().c_str();
        }
    } else if (object->cate == 'o' && [object->value isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)object->value;
        g_returnedCStringStorage.emplace_back(stringValue.UTF8String ?: "");
        result = g_returnedCStringStorage.back().c_str();
    } else if (object->type == "int64") {
        NSNumber *numberValue = (NSNumber *)object->value;
        result = (const char *)(uintptr_t)[numberValue unsignedLongLongValue];
    }

    delete object;
    return result;
}

static void write_replacement_result(ObjcMethodHook *hook, void *ret, const char **parameters, int parameterCount) {
    const char *returnEncoding = normalized_encoding(hook->signature.getReturnType());
    if (!returnEncoding || returnEncoding[0] == 0 || returnEncoding[0] == 'v') {
        call_replacement<uint32_t>(hook, parameters, parameterCount, nullptr);
        return;
    }

    switch (returnEncoding[0]) {
        case 'c': {
            int32_t value = 0;
            if (call_replacement<int32_t>(hook, parameters, parameterCount, &value)) {
                *(char *)ret = (char)value;
            }
            return;
        }
        case 'C': {
            uint32_t value = 0;
            if (call_replacement<uint32_t>(hook, parameters, parameterCount, &value)) {
                *(unsigned char *)ret = (unsigned char)value;
            }
            return;
        }
        case 's': {
            int32_t value = 0;
            if (call_replacement<int32_t>(hook, parameters, parameterCount, &value)) {
                *(short *)ret = (short)value;
            }
            return;
        }
        case 'S': {
            uint32_t value = 0;
            if (call_replacement<uint32_t>(hook, parameters, parameterCount, &value)) {
                *(unsigned short *)ret = (unsigned short)value;
            }
            return;
        }
        case 'i':
        case 'I':
        case 'B': {
            uint32_t value = 0;
            if (call_replacement<uint32_t>(hook, parameters, parameterCount, &value)) {
                *(uint32_t *)ret = value;
            }
            return;
        }
        case 'l':
        case 'L':
        case 'q':
        case 'Q':
        case '^': {
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value)) {
                *(uint64_t *)ret = value;
            }
            return;
        }
        case '*': {
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value)) {
                *(const char **)ret = consume_c_string_return_value(value);
            }
            return;
        }
        case 'f': {
            float value = 0;
            if (call_replacement<float>(hook, parameters, parameterCount, &value)) {
                *(float *)ret = value;
            }
            return;
        }
        case 'd':
        case 'F': {
            double value = 0;
            if (call_replacement<double>(hook, parameters, parameterCount, &value)) {
                *(double *)ret = value;
            }
            return;
        }
        case '@': {
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value)) {
                CFTypeRef objectValueRef = consume_objc_return_object_ref(value);
                *(void **)ret = (__bridge void *)objc_autoreleaseReturnValue((__bridge id)objectValueRef);
            }
            return;
        }
        case '#': {
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value)) {
                *(void **)ret = (__bridge void *)consume_objc_return_class(value);
            }
            return;
        }
        case ':': {
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value)) {
                id selectorObject = (__bridge_transfer id)consume_objc_return_object_ref(value);
                *(SEL *)ret = [selectorObject isKindOfClass:[NSString class]] ? NSSelectorFromString(selectorObject) : NULL;
            }
            return;
        }
        case '{': {
            StructKind kind = StructKindFromEncoding(returnEncoding);
            if (kind == StructKind::None) {
                call_replacement<uint32_t>(hook, parameters, parameterCount, nullptr);
                return;
            }
            uint64_t value = 0;
            if (call_replacement<uint64_t>(hook, parameters, parameterCount, &value) && value != 0) {
                WAPInternalObject *object = GetInternalObject((WAPObject)value);
                if (object) {
                    StructUnwrapBytes(kind, object->value, ret);
                    delete object;
                }
            }
            return;
        }
        default: {
            call_replacement<uint32_t>(hook, parameters, parameterCount, nullptr);
            return;
        }
    }
}


WAPInternalObject* CreateObjectFromObjcTypeEncoding(const char * encoding, void * arg) {
    const char *c = encoding;
    if (c && c[0] == 'r' && c[1] != 0) {
        c += 1;
    }
    
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
            unsigned int param = *(unsigned int*)arg;
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
        case '*': {
            const char *param = *(const char **)arg;
            result = WAPInternalObject::PlainValue("string", param ? [NSString stringWithUTF8String:param] : nil);
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
            Class param = *(Class*)arg;
            result = WAPInternalObject::ObjcValue("class", param);
            break;
        }
        case ':': {
            // &ffi_type_pointer;
            SEL param = *(SEL*)arg;
            result = WAPInternalObject::ObjcValue("selector", NSStringFromSelector(param));
            break;
        }
        case '{': {
            // libffi hands struct arguments to the closure as a pointer to the
            // live struct value. Wrap the bytes in an NSValue so the patch can
            // read fields back with the cg*_get_* accessors.
            StructKind kind = StructKindFromEncoding(c);
            if (kind != StructKind::None && arg) {
                NSValue *boxed = StructWrapBytes(kind, arg);
                if (boxed) {
                    result = WAPInternalObject::ObjcValue(StructTypeTag(kind), boxed);
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    
    return result;
}

void binding_objc_method(ObjcMethodHook *hook, id _self, SEL _sel, void *ret, void* args[]) {
    
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
        
        write_replacement_result(hook, ret, parameters, 2);
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

    write_replacement_result(hook, ret, parameters, 3);
}


}
