//
//  wap_objc_method_hook.mm
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#import "wap_objc_method_hook.h"
#import "wap_objc_method_bridge.h"

#import "wap_objc_runtime.h"
namespace wap {


void ObjcMethodHook::generalBinding(ffi_cif *cif, void *ret, void* args[],void *user_data) {
    ObjcMethodHook * hook = (ObjcMethodHook*)user_data;

    // self and sel
    id _self = (__bridge id)(*(void**)args[0]);
    SEL _sel = *(SEL*)args[1];

//    NSLog(@"try calling replaced method : self=%@,sel=%@", _self, NSStringFromSelector(_sel));

    binding_objc_method(hook, _self, _sel, ret, args);
}


ObjcMethodHook::ObjcMethodHook(const char *className, const char* selName, bool isInstance, const char *replacementName) {
    this->className = className;
    this->selName = selName;
    this->replacementName = replacementName;
    this->isInstance = isInstance;
}

ObjcMethodHook::~ObjcMethodHook() {
    if (context.targetClass && context.targetSelector && context.originalImplementation && context.typeEncoding) {
        class_replaceMethod(context.targetClass, context.targetSelector, context.originalImplementation, context.typeEncoding);
    }
    if (context.closure) {
        ffi_closure_free(context.closure);
        context.closure = nullptr;
    }
    if (context.args) {
        free(context.args);
        context.args = nullptr;
    }
}

void ObjcMethodHook::hook() {
    Class cls;
    if (isInstance) {
        cls = objc_getClass(this->className.c_str());
    } else {
        cls = objc_getMetaClass(this->className.c_str());
    }

    if (!cls) {
        printf("WAP Error: no class found for %s\n", this->className.c_str());
        return;
    }
    
    SEL sel = sel_registerName(this->selName.c_str());
    context.targetClass = cls;
    context.targetSelector = sel;

    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        printf("Fatal : no method found for class : %s\n", this->className.c_str());
        return;
    }

    const char * typeEncoding = method_getTypeEncoding(method);
    context.originalImplementation = method_getImplementation(method);
    context.typeEncoding = typeEncoding;

    context.closure = (ffi_closure *)ffi_closure_alloc(sizeof(ffi_closure), (void**)&context.function_address);
    if (!context.closure) {
        return;
    }

    signature.parse(typeEncoding);
    context.args = signature.mallocFFIArgumentTypes();
    context.argCount = signature.getArgumentCount();
    context.returnType = signature.getFFIReturnType();

    if (!context.returnType) {
        printf("WAP Error: unsupported return type for %s %s\n", this->className.c_str(), this->selName.c_str());
        return;
    }

    if (ffi_prep_cif(&context.cif, FFI_DEFAULT_ABI, context.argCount,context.returnType, context.args) != FFI_OK) {
        ffi_closure_free(context.closure);
        context.closure = nullptr;
        return;
    }

    // Initialize the closure
    if (ffi_prep_closure_loc(context.closure, &context.cif, generalBinding, this, context.function_address) != FFI_OK) {
        ffi_closure_free(context.closure);
        context.closure = nullptr;
        return;
    }

    IMP replacementImp = (IMP)context.function_address;
    
    if (!class_addMethod(cls, sel, replacementImp, typeEncoding)) {
        class_replaceMethod(cls, sel, replacementImp, typeEncoding);
    }

}

}
