//
//  WasmPatch.cpp
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import "WasmPatch.h"
#include "wap/wap.h"

bool wap_load_file(const char * path) {
    if (!path) { return false; }
    
    return wap::ObjcRuntime::instance().load(path);
}
