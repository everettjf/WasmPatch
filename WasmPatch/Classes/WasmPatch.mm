//
//  WasmPatch.cpp
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import "WasmPatch.h"
#include "wap/wap.h"

static wap::LoadOptions ToInternalLoadOptions(WAPLoadOptions options) {
    wap::LoadOptions internal;
    internal.maxBytes = (size_t)options.max_bytes;
    internal.expectedSHA256Hex = options.expected_sha256_hex ? options.expected_sha256_hex : "";
    internal.allowReload = options.allow_reload;
    internal.resetBeforeLoad = options.reset_before_load;
    internal.strictHooks = options.strict_hooks;
    return internal;
}

void wap_set_log_handler(WAPLogHandler handler) {
    wap::SetLogHandler((wap::LogHandler)handler);
}

WAPLoadOptions wap_recommended_load_options(void) {
    WAPLoadOptions options;
    options.max_bytes = 4 * 1024 * 1024;
    options.expected_sha256_hex = nullptr;
    options.allow_reload = false;
    options.reset_before_load = false;
    options.strict_hooks = false;
    return options;
}

bool wap_load_file(const char * path) {
    return wap::ObjcRuntime::instance().load(path ? path : "");
}

bool wap_load_data(const void * bytes, unsigned int size) {
    return wap::ObjcRuntime::instance().loadData(bytes, size);
}

bool wap_load_file_with_options(const char * path, WAPLoadOptions options) {
    return wap::ObjcRuntime::instance().load(path ? path : "", ToInternalLoadOptions(options));
}

bool wap_load_data_with_options(const void * bytes, unsigned int size, WAPLoadOptions options) {
    return wap::ObjcRuntime::instance().loadData(bytes, size, ToInternalLoadOptions(options));
}

void wap_reset_runtime(void) {
    wap::ObjcRuntime::instance().reset();
}

bool wap_runtime_is_loaded(void) {
    return wap::ObjcRuntime::instance().isLoaded();
}

const char * wap_last_error(void) {
    return wap::ObjcRuntime::instance().lastError().c_str();
}
