//
//  wap_objc_runtime.hpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_runtime_hpp
#define wap_objc_runtime_hpp

#include "../../core/util/wap_wasm.hpp"

namespace wap {

class ObjcRuntime {
public:
    static ObjcRuntime & instance();
    
    bool load(const std::string & path);
    
    WasmRuntime & runtime() { return _runtime; }
    
private:
    void initRuntime();
    
    ObjcRuntime() {} // disable new instance
    
private:
    WasmRuntime _runtime;
};

}


#endif /* wap_objc_runtime_hpp */
