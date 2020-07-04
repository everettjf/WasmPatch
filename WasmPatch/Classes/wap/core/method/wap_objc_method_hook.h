//
//  wap_objc_method_hook.h.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef ObjcMethodHook_h
#define ObjcMethodHook_h

#include <ffi.h>
#include <objc/runtime.h>
#include "wap_objc_method_signature.h"
#include <memory>
#include <string>

namespace wap {

class ObjcMethodHook {
public:
    struct HookContext {
        ffi_closure *closure;
        void * function_address;
        ffi_cif cif;
        
        ffi_type *returnType;
        ffi_type **args;
        unsigned int argCount;
    };
    
public:
    std::string className;
    std::string selName;
    std::string replacementName;
    bool isInstance;
    
    HookContext context;
    ObjcMethodSignature signature;

public:
    ObjcMethodHook(const char *className, const char* selName, bool isInstance, const char *replacementName);
    
    void hook();
    
    static void generalBinding(ffi_cif *cif, void *ret, void* args[],void *user_data);
};

using ObjcMethodHookPtr = std::shared_ptr<ObjcMethodHook>;

}

#endif /* ObjcMethodHook_h */

