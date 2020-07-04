//
//  wap_objc_export_call.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_export_call_h
#define wap_objc_export_call_h

#include "../wap_objc_define.h"


WAPObject __call_objc_method_param(bool is_instance, uint64_t address, WAPSelectorName selector_name, WAPObject params_addr) {
    
    WAPClassName class_name = nullptr;
    WAPInternalObject * instance = nullptr;
    if (is_instance) {
        // call instance method
        instance = GetInternalObject(address);
        class_name = object_getClassName(instance->value);
    } else {
        // call class method
        class_name = (WAPClassName)(void*)address;
    }
    
    
    Class cls = objc_getClass(class_name);
    SEL sel = sel_registerName(selector_name);
    
    NSMethodSignature *methodSignature;
    NSInvocation *invocation;
    
    if (is_instance) {
        methodSignature = [cls instanceMethodSignatureForSelector:sel];
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance->value];
    } else {
        methodSignature = [cls methodSignatureForSelector:sel];
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
        
    }
    
    [invocation setSelector:sel];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    WAPInternalArray *inputArguments = GetInternalArray(params_addr);
    NSUInteger numberOfInputArguments = inputArguments ? inputArguments->items.size() : 0;
    
    if (numberOfInputArguments > numberOfArguments - 2) {
        // varidic arguments
        // not support now
        // todo
        std::cout << "varidic argument not support now" << std::endl;
        return 0;
    }
    
    if (numberOfInputArguments != numberOfArguments - 2) {
        std::cout << "argument count not match" << std::endl;
        return 0;
    }
    
    for (NSInteger paramIndex = 2; paramIndex < numberOfArguments; ++paramIndex) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:paramIndex];
        
        auto inputParamAddr = inputArguments->items[paramIndex - 2];
        
        WAPInternalObject *inputParam = GetInternalObject(inputParamAddr);
        
        if (inputParam->cate == 'p') {
            std::string objectType = inputParam->type;
            
            if (1 == 0) {
                // empty
            } else if (objectType == "int32") {
                NSNumber *obj = (NSNumber*)inputParam->value;
                int32_t arg = [obj intValue];
                [invocation setArgument:&arg atIndex:paramIndex];
            } else if (objectType == "int64") {
                NSNumber *obj = (NSNumber*)inputParam->value;
                int64_t arg = [obj unsignedLongLongValue];
                [invocation setArgument:&arg atIndex:paramIndex];
            } else if (objectType == "float") {
                NSNumber *obj = (NSNumber*)inputParam->value;
                float arg = [obj floatValue];
                [invocation setArgument:&arg atIndex:paramIndex];
            } else if (objectType == "double") {
                NSNumber *obj = (NSNumber*)inputParam->value;
                double arg = [obj doubleValue];
                [invocation setArgument:&arg atIndex:paramIndex];
            } else if (objectType == "string") {
                NSString *obj = (NSString*)inputParam->value;
                const char * arg = obj.UTF8String;
                [invocation setArgument:&arg atIndex:paramIndex];
            } else {
                // empty
            }
        } else if (inputParam->cate == 'o') {
            switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
#define WAP_CALL_ARG_CASE(typeChar, realType, valueSelector) \
case typeChar: { \
NSNumber *obj = (NSNumber*)inputParam->value; \
realType value = [obj valueSelector]; \
[invocation setArgument:&value atIndex:paramIndex]; \
break; \
}
                    
                    WAP_CALL_ARG_CASE('c', char, charValue)
                    WAP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                    WAP_CALL_ARG_CASE('s', short, shortValue)
                    WAP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                    WAP_CALL_ARG_CASE('i', int, intValue)
                    WAP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                    WAP_CALL_ARG_CASE('l', long, longValue)
                    WAP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                    WAP_CALL_ARG_CASE('q', long long, longLongValue)
                    WAP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                    WAP_CALL_ARG_CASE('B', BOOL, boolValue)
                    WAP_CALL_ARG_CASE('f', float, floatValue)
                    WAP_CALL_ARG_CASE('d', double, doubleValue)
                    
                case ':': {
                    NSString *selectorName = (NSString*)inputParam->value;
                    SEL value = NSSelectorFromString(selectorName);
                    [invocation setArgument:&value atIndex:paramIndex];
                    break;
                }
                case '{': {
                    // struct
                    // todo
                    break;
                }
                case '*':
                case '^': {
                    // todo
                    break;
                }
                case '#': {
                    // todo
                    break;
                }
                default: {
                    id valObj = inputParam->value;
                    if (valObj == nil) {
                        [invocation setArgument:&valObj atIndex:paramIndex];
                        break;
                    }
                    // check block ?
                    // todo
                    
                    [invocation setArgument:&valObj atIndex:paramIndex];
                    break;
                }
            }
        } else {
            // unknown category
            return 1;
        }
    }
    
    // invoke now
    [invocation invoke];
    
    // get result
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    
    if (strncmp(returnType, "v", 1) != 0) {
        id returnValue;
        
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            returnValue = (__bridge id)result;
            
            return WAPCreateObjectFromObjcValue("objc",returnValue);
        } else {
            WAPInternalObjectType internalObjectType;
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
#define WAP_CALL_RET_CASE(typeChar, objectType, realType) \
case typeChar: {                              \
realType tempResultSet; \
[invocation getReturnValue:&tempResultSet];\
returnValue = @(tempResultSet); \
internalObjectType = objectType; \
break; \
}
                    
                    WAP_CALL_RET_CASE('c', "i", char)
                    WAP_CALL_RET_CASE('C', "i", unsigned char)
                    WAP_CALL_RET_CASE('s', "i", short)
                    WAP_CALL_RET_CASE('S', "i", unsigned short)
                    WAP_CALL_RET_CASE('i', "i", int)
                    WAP_CALL_RET_CASE('I', "i", unsigned int)
                    WAP_CALL_RET_CASE('l', "I", long)
                    WAP_CALL_RET_CASE('L', "I", unsigned long)
                    WAP_CALL_RET_CASE('q', "I", long long)
                    WAP_CALL_RET_CASE('Q', "I", unsigned long long)
                    WAP_CALL_RET_CASE('B', "i", BOOL)
                    WAP_CALL_RET_CASE('f', "f", float)
                    WAP_CALL_RET_CASE('d', "d", double)
                    
                case '{': {
                    // todo
                    break;
                }
                case '*':
                case '^': {
                    // todo
                    break;
                }
                case '#': {
                    // todo
                    break;
                }
                default: {
                    // todo
                    break;
                }
            }
            return WAPCreateObjectFromObjcValue(internalObjectType, returnValue);
        }
    }
    
    // Void result
    return 0;
}



// class method
WAPObject call_class_method_param(WAPClassName class_name, WAPSelectorName selector_name, WAPObject params_addr) {
    return __call_objc_method_param(false, (uint64_t)class_name, selector_name, params_addr);
}

__WAP_EXPORT_FUNCTION(call_class_method_param_raw) {
    m3ApiReturnType (WAPObject)
    
    m3ApiGetArgMem  (char*, class_name)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param)
    
    WAPObject result = call_class_method_param(class_name, selector_name, param);
    m3ApiReturn(result);
}

WAPObject call_class_method_0(WAPClassName class_name, WAPSelectorName selector_name) {
    return call_class_method_param(class_name, selector_name, NULL);
}

__WAP_EXPORT_FUNCTION(call_class_method_0_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (char*, class_name)
    m3ApiGetArgMem  (char*, selector_name)
    WAPObject result = call_class_method_0(class_name, selector_name);
    m3ApiReturn(result);
}

WAPObject call_class_method_1(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1) {
    auto params = new WAPInternalArray();
    params->items.push_back(param1);
    auto result = call_class_method_param(class_name, selector_name, (WAPObject)(void*)params);
    delete params;
    return result;
}

__WAP_EXPORT_FUNCTION(call_class_method_1_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (char*, class_name)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param1)
    
    auto result = call_class_method_1(class_name, selector_name, param1);
    m3ApiReturn(result);
}
WAPObject call_class_method_2(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1, WAPObject param2) {
    auto params = new WAPInternalArray();
    params->items.push_back(param1);
    params->items.push_back(param2);
    auto result = call_class_method_param(class_name, selector_name, (WAPObject)(void*)params);
    delete params;
    return result;
}

__WAP_EXPORT_FUNCTION(call_class_method_2_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem  (char*, class_name)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param1)
    m3ApiGetArg  (WAPObject, param2)
    
    auto result = call_class_method_2(class_name, selector_name, param1, param2);
    m3ApiReturn(result);
}
// instance method
WAPObject call_instance_method_param(WAPObject instance, WAPSelectorName selector_name, WAPObject params_addr) {
    return __call_objc_method_param(true, (uint64_t)instance, selector_name, params_addr);
}


__WAP_EXPORT_FUNCTION(call_instance_method_param_raw) {
    m3ApiReturnType (WAPObject)
    
    m3ApiGetArg  (WAPObject, address)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param)
    
    WAPObject result = call_instance_method_param(address, selector_name, param);
    m3ApiReturn(result);
}

WAPObject call_instance_method_0(WAPObject instance, WAPSelectorName selector_name) {
    return call_instance_method_param(instance, selector_name, NULL);
}


__WAP_EXPORT_FUNCTION(call_instance_method_0_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPObject, address)
    m3ApiGetArgMem  (char*, selector_name)
    WAPObject result = call_instance_method_0(address, selector_name);
    m3ApiReturn(result);
}

WAPObject call_instance_method_1(WAPObject instance, WAPSelectorName selector_name, WAPObject param1) {
    auto params = new WAPInternalArray();
    params->items.push_back(param1);
    auto result = call_instance_method_param(instance, selector_name, (WAPObject)(void*)params);
    delete params;
    return result;
}


__WAP_EXPORT_FUNCTION(call_instance_method_1_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPObject, address)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param1)
    
    auto result = call_instance_method_1(address, selector_name, param1);
    m3ApiReturn(result);
}

WAPObject call_instance_method_2(WAPObject instance, WAPSelectorName selector_name, WAPObject param1, WAPObject param2) {
    auto params = new WAPInternalArray();
    params->items.push_back(param1);
    params->items.push_back(param2);
    auto result = call_instance_method_param(instance, selector_name, (WAPObject)(void*)params);
    delete params;
    return result;
}


__WAP_EXPORT_FUNCTION(call_instance_method_2_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg  (WAPObject, address)
    m3ApiGetArgMem  (char*, selector_name)
    m3ApiGetArg  (WAPObject, param1)
    m3ApiGetArg  (WAPObject, param2)
    
    auto result = call_instance_method_2(address, selector_name, param1, param2);
    m3ApiReturn(result);
}


#endif /* wap_objc_export_call_h */
