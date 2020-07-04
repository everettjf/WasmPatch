//
//  wap_objc_method.hpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#ifndef wap_objc_method_hpp
#define wap_objc_method_hpp

#import <Foundation/Foundation.h>
#include "wap_objc_method_hook.h"
#include <list>
#include <memory>

namespace wap {


class ObjcMethod {
public:
    static ObjcMethod & instance();
    
    void addHook(ObjcMethodHookPtr hook);
    
private:
    std::list<ObjcMethodHookPtr> hooks;
};

}

#endif /* wap_objc_method_hpp */
