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
#include <mutex>
#include <string>
#include <vector>

namespace wap {


class ObjcMethod {
public:
    static ObjcMethod & instance();

    void addHook(ObjcMethodHookPtr hook);
    void clearHooks();

    // Diagnostics for hooks attempted since the last clearHookErrors().
    bool hadHookErrors();
    std::string hookErrorSummary();
    void clearHookErrors();

private:
    std::list<ObjcMethodHookPtr> hooks;
    std::vector<std::string> hookErrors;
    std::mutex mutex;
};

}

#endif /* wap_objc_method_hpp */
