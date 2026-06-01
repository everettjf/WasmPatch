#include <wasmpatch.h>

// Replacement for -[DemoService greeting]
WAPObject demo_greeting(WAPObject self, const char *cmd) {
    return new_objc_nsstring("Hello from WebAssembly (patched at runtime)");
}

int entry() {
    WAP_REPLACE_INSTANCE(DemoService, "greeting", demo_greeting);
    return 0;
}
