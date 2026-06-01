---
title: "Authoring patches"
eyebrow: "Writing patches"
description: "The C SDK, the WAP_REPLACE_* macros, scope cleanup pools, and calling Objective-C from a patch."
---

A patch is a C file that `#include <wasmpatch.h>` and exports an `entry()`
function. The build tooling puts the SDK header on the include path
automatically.

## Lifecycle

```c
#include <wasmpatch.h>

int entry() {
    // Runs once when the patch is loaded. Register replacements and perform
    // any one-time calls here.
    return 0;
}
```

## Values

Everything that crosses the bridge is a `WAPObject` handle. Create them with the
`alloc_*` / `new_objc_*` helpers:

```c
WAPObject s   = new_objc_nsstring("hello");   // NSString
WAPObject n   = new_objc_nsnumber_int(42);    // NSNumber
WAPObject i32 = alloc_int32(7);
WAPObject i64 = alloc_int64(7);
WAPObject f   = alloc_float(1.5f);
WAPObject d   = alloc_double(1.5);
WAPObject cs  = alloc_string("c-string");     // const char* arg/return
WAPObject cls = alloc_objc_class("CallMe");   // an instance of a class
```

### Cleanup pools

Instead of pairing every alloc with `dealloc_object`, collect handles in a pool
and drain it at scope end:

```c
WAP_POOL_BEGIN(pool);
WAPObject a = WAP_KEEP(pool, new_objc_nsstring("a"));
WAPObject b = WAP_KEEP(pool, new_objc_nsstring("b"));
call_class_method_2("Logger", "logA:b:", a, b);
WAP_POOL_END(pool);   // frees a and b
```

## Calling Objective-C

Fixed-arity helpers cover 0–4 arguments; use the `_param` form with an array for
more:

```c
call_class_method_0("CallMe", "ping");
call_class_method_1("CallMe", "say:", new_objc_nsstring("hi"));
call_class_method_4("Geo", "rectX:y:w:h:",
                    alloc_double(0), alloc_double(0), alloc_double(320), alloc_double(64));

WAPArray args = alloc_array();
append_array(args, alloc_int32(1));
append_array(args, new_objc_nsstring("two"));
call_class_method_param("CallMe", "many:args:", args);
dealloc_array(args);

// Instance methods take a WAPObject receiver:
WAPObject obj = alloc_objc_class("CallMe");
obj = call_instance_method_0(obj, "init");
WAPObject result = call_instance_method_0(obj, "describe");
```

Return values come back as `WAPObject`s; read arrays with `get_array_size` /
`get_array_item`.

## Replacing methods

Use the macros — they stringize the **real C symbol**, so the registered name
can never drift from your function, and a misspelled symbol fails to compile:

```c
int my_send(WAPObject self, const char *cmd, WAPArray args) {
    print_string("intercepted send:");
    return 0;
}

WAPObject my_token(WAPObject self, const char *cmd) {
    return new_objc_nsstring("patched");
}

int entry() {
    WAP_REPLACE_INSTANCE(NetworkManager, "send:", my_send);
    WAP_REPLACE_CLASS(SessionManager, "authToken", my_token);
    return 0;
}
```

Replacement function shapes:

- 0 extra args: `RET fn(WAPObject self, const char *cmd)`
- 1+ extra args: `RET fn(WAPObject self, const char *cmd, WAPArray args)` — read
  arguments with `get_array_item(args, i)`.

`RET` matches the method's return type: `int` for integers/`BOOL`, `double` for
floating point, `WAPObject` for objects/strings/structs, `void`/`int` for void.

## Low-level C API

The high-level `WAPPatchLoader` (Obj-C/Swift) is recommended, but the raw C API
is available:

```c
bool wap_load_file(const char *path);
bool wap_load_data(const void *bytes, unsigned int size);
void wap_reset_runtime(void);
bool wap_runtime_is_loaded(void);
const char * wap_last_error(void);
```

## See also

- [Structs](structs.html) — passing/returning structs by value
- [Blocks](blocks.html) — completion handlers
- [Swift support](swift.html) — what's hookable from Swift
