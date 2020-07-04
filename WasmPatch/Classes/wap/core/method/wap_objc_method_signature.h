//
//  wap_objc_method_signature.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//


#ifndef ObjcMethodSignature_h
#define ObjcMethodSignature_h

#include <ffi.h>
#include <objc/runtime.h>
#include <string>
#include <vector>
namespace wap {


class ObjcMethodSignature {
private:
    std::string typeEncoding;
    std::vector<std::string> argumentTypes;
    std::string returnType;
    
public:
    ObjcMethodSignature();
    void parse(const char * encoding);

    ffi_type * getFFIReturnType();
    ffi_type ** mallocFFIArgumentTypes();
    
    unsigned int getArgumentCount();
    const std::string & getTypeEncoding() {return typeEncoding;}
    const std::vector<std::string> & getArgumentTypes() {return argumentTypes;}
    const std::string & getReturnType() {return returnType;}
public:
    static ffi_type* ffitypeFromTypeEncoding(const char *encoding);
};

}
#endif /* ObjcMethodSignature_h */
