//
//  wap_objc_method_signature.mm
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#import "wap_objc_method_signature.h"

namespace wap {

ffi_type* ObjcMethodSignature::ffitypeFromTypeEncoding(const char *encoding) {
    const char * c = encoding;
    if (c == NULL) {
        return NULL;
    }
    
    switch (c[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'F':
            return &ffi_type_double;
        case 'B':
            return &ffi_type_uint8;
        case '^':
            return &ffi_type_pointer;
        case '@':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case ':':
            return &ffi_type_pointer;
        case '{': {
            // todo struct
            return &ffi_type_pointer;
        }
    }
    return NULL;
}



ObjcMethodSignature::ObjcMethodSignature() {
    
}

void ObjcMethodSignature::parse(const char * encoding) {
    if (encoding == 0) {
        return;
    }
    
    this->typeEncoding = encoding;
    
    int descNum1 = 0; // num of '\"' in signature type encoding
    int descNum2 = 0; // num of '<' in block signature type encoding
    int descNum3 = 0; // num of '{' in signature type encoding
    int structBLoc = 0; // loc of '{' in signature type encoding
    int structELoc = 0; // loc of '}' in signature type encoding
    BOOL skipNext;
    std::string arg;
    std::vector<std::string> argArray;
    
    for (int i = 0; i < typeEncoding.size(); i ++) {
        auto c = typeEncoding.at(i);
        skipNext = NO;
        arg = "";
        
        if (c == '\"') ++descNum1;
        if ((descNum1 % 2) != 0 || c == '\"' || isdigit(c)) {
            continue;
        }
        
        if (c == '<') ++descNum2;
        if (descNum2 > 0) {
            if (c == '>') {
                --descNum2;
            }
            continue;
        }
        
        if (c == '{') {
            if (descNum3 == 0) {
                structBLoc = i;
            }
            ++descNum3;
        }
        if (descNum3 > 0) {
            if (c == '}') {
                --descNum3;
                if (descNum3 == 0) {
                    structELoc = i;
                    arg = typeEncoding.substr(structBLoc, structELoc - structBLoc + 1);
                    structBLoc = 0;
                    structELoc = 0;
                }
            }
            
            if (descNum3 > 0) {
                continue;
            }
        }
        
        if (arg.empty()) {
            if (c == '^') {
                skipNext = YES;
                arg = typeEncoding.substr(i,2);
            } else if (c == '?') {
                // @? is block
                arg = typeEncoding.substr(i-1,2);
                argArray.pop_back();
            } else {
                arg = typeEncoding.substr(i,1);
            }
        }
        
        if (arg.size() > 0) {
            argArray.push_back(arg);
        }
        if (skipNext) i++;
    }
    
    if (argArray.size() > 1) {
        returnType = argArray.front();
        argArray.erase(argArray.begin());
        argumentTypes = argArray;
    }
}

ffi_type * ObjcMethodSignature::getFFIReturnType() {
    return ffitypeFromTypeEncoding(this->returnType.c_str());
}

unsigned int ObjcMethodSignature::getArgumentCount() {
    return (unsigned int)argumentTypes.size();
}

ffi_type ** ObjcMethodSignature::mallocFFIArgumentTypes() {
    int argumentCount = this->getArgumentCount();
    
    ffi_type ** args = (ffi_type**)malloc(sizeof(ffi_type*) * argumentCount) ;

    for (int idx = 0; idx < argumentCount; ++idx) {
        ffi_type * type = ffitypeFromTypeEncoding(argumentTypes[idx].c_str());
        args[idx] = type;
    }
    return args;
}

}

