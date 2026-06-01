//
//  WasmPatch.hpp
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#ifndef WasmPatch_hpp
#define WasmPatch_hpp

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct WAPLoadOptions {
    uint64_t max_bytes;
    const char *expected_sha256_hex;
    bool allow_reload;
    bool reset_before_load;
    // When true, load fails if any replace_* call references a missing class or
    // selector, instead of silently leaving the method unpatched.
    bool strict_hooks;
} WAPLoadOptions;

// Log levels passed to WAPLogHandler: 0 = info, 1 = warning, 2 = error.
typedef void (*WAPLogHandler)(int level, const char *message);

// Install a diagnostics handler (pass NULL to restore the default sink).
void wap_set_log_handler(WAPLogHandler handler);

WAPLoadOptions wap_recommended_load_options(void);
bool wap_load_file(const char * path);
bool wap_load_data(const void * bytes, unsigned int size);
bool wap_load_file_with_options(const char * path, WAPLoadOptions options);
bool wap_load_data_with_options(const void * bytes, unsigned int size, WAPLoadOptions options);
void wap_reset_runtime(void);
bool wap_runtime_is_loaded(void);
const char * wap_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* WasmPatch_hpp */
