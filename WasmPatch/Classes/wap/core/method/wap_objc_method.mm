//
//  wap_objc_method.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_method.h"

namespace wap {

ObjcMethod & ObjcMethod::instance() {
    static ObjcMethod o;
    return o;
}

void ObjcMethod::addHook(ObjcMethodHookPtr hook) {
    std::lock_guard<std::mutex> lock(mutex);
    if (!hook->hook()) {
        hookErrors.push_back(hook->lastError);
    }
    hooks.push_back(hook);
}

void ObjcMethod::clearHooks() {
    std::lock_guard<std::mutex> lock(mutex);
    hooks.clear();
    hookErrors.clear();
}

bool ObjcMethod::hadHookErrors() {
    std::lock_guard<std::mutex> lock(mutex);
    return !hookErrors.empty();
}

std::string ObjcMethod::hookErrorSummary() {
    std::lock_guard<std::mutex> lock(mutex);
    if (hookErrors.empty()) {
        return std::string();
    }
    std::string summary = "hook errors (" + std::to_string(hookErrors.size()) + "): ";
    for (size_t i = 0; i < hookErrors.size(); ++i) {
        if (i > 0) {
            summary += "; ";
        }
        summary += hookErrors[i];
    }
    return summary;
}

void ObjcMethod::clearHookErrors() {
    std::lock_guard<std::mutex> lock(mutex);
    hookErrors.clear();
}

}
