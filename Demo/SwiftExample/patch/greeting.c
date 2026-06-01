#include <wasmpatch.h>

// Replacement for -[DemoService greeting]
WAPObject demo_greeting(WAPObject self, const char *cmd) {
    return new_objc_nsstring("patched-by-wasm");
}

int entry() {
    // DemoService is the @objc(DemoService) Swift class in main.swift.
    WAP_REPLACE_INSTANCE(DemoService, "greeting", demo_greeting);
    return 0;
}
