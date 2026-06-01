//
//  wap_objc_runtime.cpp
//  WasmPatch
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#include "wap_objc_runtime.h"

#include <objc/runtime.h>
#include <vector>
#include <string>

#include "../method/wap_objc_method.h"
#include "wap_objc_define.h"
#include "wap_objc_export.h"

namespace wap {

namespace {
std::mutex g_logMutex;
LogHandler g_logHandler = nullptr;
}

void SetLogHandler(LogHandler handler) {
    std::lock_guard<std::mutex> lock(g_logMutex);
    g_logHandler = handler;
}

void EmitLog(LogLevel level, const std::string & message) {
    LogHandler handler = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_logMutex);
        handler = g_logHandler;
    }
    if (handler) {
        handler((int)level, message.c_str());
        return;
    }
    const char *prefix = level == LogLevel::Error ? "WAP Error" : (level == LogLevel::Warning ? "WAP Warning" : "WAP");
    NSLog(@"[%s] %s", prefix, message.c_str());
}

ObjcRuntime & ObjcRuntime::instance() {
    static ObjcRuntime obj;
    return obj;
}

bool ObjcRuntime::load(const std::string & path) {
    if (path.empty()) {
        setError("load failed: empty wasm path");
        return false;
    }

    std::lock_guard<std::mutex> lock(_mutex);
    ensureRuntime();
    std::string buffer;
    if (!read_buffer_from_file(path, buffer)) {
        setError("load failed: unable to read wasm file");
        return false;
    }
    return loadBufferLocked(buffer.data(), buffer.size());
}

bool ObjcRuntime::load(const std::string & path, const LoadOptions & options) {
    if (path.empty()) {
        setError("load failed: empty wasm path");
        return false;
    }

    std::string buffer;
    if (!read_buffer_from_file(path, buffer)) {
        setError("load failed: unable to read wasm file");
        return false;
    }

    std::lock_guard<std::mutex> lock(_mutex);
    if (!validateLoadLocked(path, buffer.data(), buffer.size(), options)) {
        return false;
    }
    return loadBufferLocked(buffer.data(), buffer.size(), options.strictHooks);
}

bool ObjcRuntime::loadData(const void * bytes, size_t size) {
    if (!bytes || size == 0) {
        setError("load failed: empty wasm buffer");
        return false;
    }

    std::lock_guard<std::mutex> lock(_mutex);
    return loadBufferLocked(bytes, size);
}

bool ObjcRuntime::loadData(const void * bytes, size_t size, const LoadOptions & options) {
    if (!bytes || size == 0) {
        setError("load failed: empty wasm buffer");
        return false;
    }

    std::lock_guard<std::mutex> lock(_mutex);
    if (!validateLoadLocked("memory", bytes, size, options)) {
        return false;
    }
    return loadBufferLocked(bytes, size, options.strictHooks);
}

void ObjcRuntime::reset() {
    std::lock_guard<std::mutex> lock(_mutex);
    resetLocked();
}

bool ObjcRuntime::isLoaded() const {
    std::lock_guard<std::mutex> lock(_mutex);
    return _loaded;
}

const std::string & ObjcRuntime::lastError() const {
    return _lastError;
}

WasmRuntime & ObjcRuntime::runtime() {
    std::lock_guard<std::mutex> lock(_mutex);
    ensureRuntime();
    return *_runtime;
}

void ObjcRuntime::setError(const std::string & error) {
    _lastError = error;
    _loaded = false;
}

void ObjcRuntime::clearError() {
    _lastError.clear();
}

void ObjcRuntime::ensureRuntime() {
    if (!_runtime) {
        _runtime = std::make_unique<WasmRuntime>();
    }
}

bool ObjcRuntime::loadBufferLocked(const void * bytes, size_t size, bool strictHooks) {
    ensureRuntime();
    bool result = _runtime->loadData(bytes, size);
    if (!result) {
        setError(_runtime->lastError());
        return false;
    }

    initRuntime();

    // Forget hook diagnostics from any earlier load so the summary below only
    // reflects this patch.
    ObjcMethod::instance().clearHookErrors();

    if (!_runtime->call("entry")) {
        setError(_runtime->lastError());
        return false;
    }

    if (ObjcMethod::instance().hadHookErrors()) {
        const std::string summary = ObjcMethod::instance().hookErrorSummary();
        EmitLog(LogLevel::Error, std::string("patch load: ") + summary);
        if (strictHooks) {
            setError(std::string("load rejected by policy: ") + summary);
            return false;
        }
    }

    _loaded = true;
    clearError();
    return true;
}

bool ObjcRuntime::validateLoadLocked(const std::string & sourceLabel, const void * bytes, size_t size, const LoadOptions & options) {
    if (_loaded) {
        if (!options.allowReload) {
            setError("load rejected by policy: runtime already loaded");
            return false;
        }
        if (options.resetBeforeLoad) {
            resetLocked();
        }
    }

    if (options.maxBytes > 0 && size > options.maxBytes) {
        setError("load rejected by policy: wasm exceeds max_bytes");
        return false;
    }

    const uint8_t *raw = static_cast<const uint8_t *>(bytes);
    if (size < 4 || raw[0] != 0x00 || raw[1] != 0x61 || raw[2] != 0x73 || raw[3] != 0x6d) {
        setError("load rejected by policy: invalid wasm magic");
        return false;
    }

    if (!options.expectedSHA256Hex.empty()) {
        const std::string actualHash = sha256_hex(bytes, size);
        const std::string expectedHash = lowercase_string(options.expectedSHA256Hex);
        if (actualHash != expectedHash) {
            setError("load rejected by policy: sha256 mismatch for " + sourceLabel);
            return false;
        }
    }

    return true;
}

void ObjcRuntime::resetLocked() {
    _runtime.reset();
    _loaded = false;
    clearError();
    ObjcMethod::instance().clearHooks();
}

void ObjcRuntime::initRuntime() {
    
    // _runtime.link<call_class_method>("call_class_method", call_class_method_raw);
#define RT_LINK(name) _runtime->link<name>(#name, name##_raw);
    
    // call
    RT_LINK(alloc_objc_class);
    RT_LINK(alloc_int32);
    RT_LINK(alloc_int64);
    RT_LINK(alloc_float);
    RT_LINK(alloc_double);
    RT_LINK(alloc_string);

    RT_LINK(alloc_cgpoint);
    RT_LINK(alloc_cgsize);
    RT_LINK(alloc_cgrect);
    RT_LINK(cgpoint_get_x);
    RT_LINK(cgpoint_get_y);
    RT_LINK(cgsize_get_width);
    RT_LINK(cgsize_get_height);
    RT_LINK(cgrect_get_x);
    RT_LINK(cgrect_get_y);
    RT_LINK(cgrect_get_width);
    RT_LINK(cgrect_get_height);

    RT_LINK(print_object);
    RT_LINK(print_string);
    RT_LINK(dealloc_object);

    RT_LINK(alloc_array);
    RT_LINK(dealloc_array);
    RT_LINK(append_array);
    RT_LINK(get_array_size);
    RT_LINK(get_array_item);

    RT_LINK(call_class_method_param);
    RT_LINK(call_class_method_0);
    RT_LINK(call_class_method_1);
    RT_LINK(call_class_method_2);
    RT_LINK(call_class_method_3);
    RT_LINK(call_class_method_4);

    RT_LINK(call_instance_method_param);
    RT_LINK(call_instance_method_0);
    RT_LINK(call_instance_method_1);
    RT_LINK(call_instance_method_2);
    RT_LINK(call_instance_method_3);
    RT_LINK(call_instance_method_4);

    RT_LINK(new_objc_nsstring);
    RT_LINK(new_objc_nsnumber_int);
    
    RT_LINK(replace_class_method);
    RT_LINK(replace_instance_method);
}

}
