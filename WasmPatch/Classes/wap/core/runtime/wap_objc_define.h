//
//  wap_objc_define.h
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_define_h
#define wap_objc_define_h

#import <Foundation/Foundation.h>

#include "../util/wap_wasm.hpp"
#include <objc/runtime.h>
#include <vector>
#include <string>


#define __WAP_EXPORT_FUNCTION m3ApiRawFunction


/**
 Address of WAPInternalObject
 */
typedef uint64_t WAPObject;


/**
 Result type for some export functions
 */
typedef uint32_t WAPResultVoid;

/**
 Meaningful definition
 */
typedef const char * WAPClassName;
typedef const char * WAPSelectorName;
typedef const char * WAPMethodName;


/**
 Address of WAPInternalArray
 */
typedef uint64_t WAPArray;


/**
 Object define
 */
typedef char WAPInternalObjectCategory;
typedef std::string WAPInternalObjectType;

struct WAPInternalObject {
    /**
     p : Plain type
     o : Objc type
     v : Void // used for function result
     */
    WAPInternalObjectCategory cate;
    /**
     WAPInternalObjectType
     
     when cate == p:
        int32
        int64
        float
        double
        string
     when cate == o:
        objc type
     */
    WAPInternalObjectType type;
    /**
     Objc Object stores value
     */
    id value;
    
    WAPInternalObject(WAPInternalObjectCategory c, WAPInternalObjectType t, id v) {
        this->cate = c;
        this->type = t;
        this->value = v;
    }
    
    static WAPInternalObject * PlainValue(WAPInternalObjectType typ, id val) {
        return new WAPInternalObject('p', typ, val);
    }
    static WAPInternalObject * ObjcValue(WAPInternalObjectType typ, id val) {
        return new WAPInternalObject('o', typ, val);
    }
    static WAPInternalObject * VoidValue() {
        return new WAPInternalObject('v',0, nil);
    }
};

#define WAPCreateObjectFromPlainValue(type,value)   (WAPObject)WAPInternalObject::PlainValue(type,value)
#define WAPCreateObjectFromObjcValue(type,value)    (WAPObject)WAPInternalObject::ObjcValue(type,value)
#define WAPCreateObjectVoidValue                    (WAPObject)WAPInternalObject::VoidValue()

/**
 Array define
 */
struct WAPInternalArray {
    std::vector<WAPObject> items;
};

/**
 Helper convertor
 */
inline WAPInternalObject * GetInternalObject(WAPObject addr) {
    WAPInternalObject *obj = (WAPInternalObject*)(void*)addr;
    return obj;
}

inline WAPInternalArray * GetInternalArray(WAPArray addr) {
    WAPInternalArray * param = (WAPInternalArray*)(void*)addr;
    return param;
}


#endif /* wap_objc_define_h */
