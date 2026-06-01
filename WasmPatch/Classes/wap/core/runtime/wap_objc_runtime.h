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
#include <memory>
#include <mutex>
#include <string>

namespace wap {

enum class LogLevel {
    Info = 0,
    Warning = 1,
    Error = 2,
};

using LogHandler = void (*)(int level, const char *message);

// Install a host log handler. Pass nullptr to fall back to the default
// (NSLog/printf) sink. Thread-safe.
void SetLogHandler(LogHandler handler);

// Emit a diagnostic. Routed to the host handler when set, otherwise printed.
void EmitLog(LogLevel level, const std::string & message);

struct LoadOptions {
    size_t maxBytes = 0;
    std::string expectedSHA256Hex;
    bool allowReload = false;
    bool resetBeforeLoad = false;
    // When true, a patch whose replace_* calls reference a missing class or
    // selector causes load to fail instead of silently leaving the method
    // unpatched.
    bool strictHooks = false;
};

class ObjcRuntime {
public:
    static ObjcRuntime & instance();
    
    bool load(const std::string & path);
    bool load(const std::string & path, const LoadOptions & options);
    bool loadData(const void * bytes, size_t size);
    bool loadData(const void * bytes, size_t size, const LoadOptions & options);
    void reset();
    bool isLoaded() const;
    const std::string & lastError() const;
    
    WasmRuntime & runtime();
    
private:
    void initRuntime();
    bool loadBufferLocked(const void * bytes, size_t size, bool strictHooks = false);
    bool validateLoadLocked(const std::string & sourceLabel, const void * bytes, size_t size, const LoadOptions & options);
    void resetLocked();
    void setError(const std::string & error);
    void clearError();
    void ensureRuntime();
    
    ObjcRuntime() {} // disable new instance
    
private:
    mutable std::mutex _mutex;
    std::unique_ptr<WasmRuntime> _runtime;
    bool _loaded = false;
    std::string _lastError;
};

}


#endif /* wap_objc_runtime_hpp */
