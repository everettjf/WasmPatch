---
title: "Objective-C in depth"
eyebrow: "Writing patches"
description: "Calling and replacing Objective-C methods across every argument and return shape, with real patterns."
---

Objective-C is WasmPatch's native habitat — every method goes through message
dispatch, so anything is reachable. This guide covers the mechanics in detail.
For the bridge fundamentals see [The type bridge](../concepts/type-bridging.html).

## Calling methods

Use the fixed-arity helpers for 0–4 arguments and `*_param` with an array beyond
that:

```c
call_class_method_0("CallMe", "ping");
call_class_method_1("CallMe", "say:", new_objc_nsstring("hi"));
call_class_method_2("CallMe", "x:y:", alloc_int32(1), alloc_int32(2));

WAPObject inst = alloc_objc_class("CallMe");
inst = call_instance_method_0(inst, "init");
WAPObject desc = call_instance_method_0(inst, "description");
```

Selectors include their colons: `sayYou:andMe:` is a two-argument selector. The
argument count must match the selector or the call is rejected and logged.

## Argument types

Each handle is unboxed into the type the method's `NSMethodSignature` expects:

```c
// - (void)configWithCount:(NSInteger)n ratio:(double)r name:(NSString *)s flag:(BOOL)b
WAPArray a = alloc_array();
append_array(a, alloc_int64(3));
append_array(a, alloc_double(0.75));
append_array(a, new_objc_nsstring("beta"));
append_array(a, alloc_int32(1));            // BOOL
call_class_method_param("Config", "configWithCount:ratio:name:flag:", a);
dealloc_array(a);
```

`const char *` parameters take `alloc_string(...)`; object parameters take
`new_objc_nsstring(...)` or any object handle; `Class` parameters take
`alloc_objc_class(...)`.

## Return values

Returns come back as handles boxed per the method's return type:

```c
WAPObject r = call_class_method_0("CallMe", "staticCString"); // const char* -> string
print_object(r);
dealloc_object(r);

WAPObject obj = call_instance_method_0(inst, "returnString");  // id -> objc
```

Read scalars by passing the handle to another call, geometry/struct returns with
the [struct accessors](structs.html), and inspect anything with `print_object`.

## Replacing methods

```c
// Original: - (NSString *)authToken;
WAPObject patched_token(WAPObject self, const char *cmd) {
    return new_objc_nsstring("forced-token");
}

// Original: - (void)track:(NSString *)event;  (1 extra arg -> WAPArray)
int blocked_track(WAPObject self, const char *cmd, WAPArray args) {
    // swallow analytics in a debug patch
    return 0;
}

int entry() {
    WAP_REPLACE_INSTANCE(SessionManager, "authToken", patched_token);
    WAP_REPLACE_INSTANCE(Analytics, "track:", blocked_track);
    return 0;
}
```

### Replacement function shapes

| Method args | Replacement signature |
|-------------|-----------------------|
| none | `RET fn(WAPObject self, const char *cmd)` |
| one or more | `RET fn(WAPObject self, const char *cmd, WAPArray args)` |

`RET` follows the method's return type:

| Returns | `RET` | Produce with |
|---------|-------|--------------|
| `void` | `int` (return 0) | — |
| `BOOL` / integer | `int` | `return 1;` |
| `NSInteger` / `long long` | `int` (or build via int64) | `return n;` |
| `double` / `CGFloat` | `double` | `return 9.5;` |
| `float` | `double`* | `return 1.5;` |
| object / `NSString *` | `WAPObject` | `new_objc_nsstring(...)` |
| `const char *` | `WAPObject` | `alloc_string(...)` |
| `CGRect` etc. | `WAPObject` | `alloc_cgrect(...)` |

<small>*Declare a `double`-returning C function; the bridge narrows to the
method's `float` return.</small>

## Reading arguments in a replacement

```c
// - (int32_t)sumOfRect:(CGRect)rect
int my_sum(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject rect = get_array_item(args, 0);
    return (int)(cgrect_get_width(rect) + cgrect_get_height(rect));
}

// - (void)didReceive:(NSString *)message from:(NSString *)sender
int my_recv(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject message = get_array_item(args, 0);
    WAPObject sender  = get_array_item(args, 1);
    print_object(sender);
    return 0;
}
```

## A realistic fix

Guard a method that crashes on `nil` input by short-circuiting it:

```c
// - (void)renderItem:(Item *)item   — crashes when item is nil in the field
int safe_render(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject item = get_array_item(args, 0);
    if (item == 0) {
        print_string("WasmPatch: skipped renderItem: with nil item");
        return 0;                 // swallow the crash
    }
    // forward to a safe path on the host
    call_instance_method_1(self, "renderItemSafely:", item);
    return 0;
}
int entry() {
    WAP_REPLACE_INSTANCE(FeedViewController, "renderItem:", safe_render);
    return 0;
}
```

See it end to end in [Case study: ship a crash hotfix](../cases/objc-hotfix.html).

## Not supported

- **Variadic** Objective-C methods (true C varargs) can't be called through the
  bridge.
- Struct-by-value **block** parameters — see [Blocks](blocks.html) for what is
  supported.
