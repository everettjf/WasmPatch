---
title: "The type bridge"
eyebrow: "Core concepts"
description: "How values cross between wasm and Objective-C: the WAPObject record, type encodings, and the marshalling tables."
---

The wasm side speaks in 32/64-bit integers and floats. The Objective-C side
speaks in objects, primitives, C strings, selectors, and structs. The bridge
translates — and the unit of translation is the `WAPObject` handle.

## The handle

A `WAPObject` is an opaque 64-bit value on the wasm side. Host-side it addresses
a small record:

```
WAPInternalObject {
  category:  'p' plain  | 'o' objc  | 'v' void
  type:      "int32" | "int64" | "float" | "double" | "string"
             | "objc" | "class" | "selector" | "cgrect" | "struct:{…}" | …
  value:     the boxed Objective-C value (NSNumber, NSString, id, NSValue, NSData)
}
```

You never inspect this from the patch — you create handles with `alloc_*` /
`new_objc_*`, pass them to calls, and read returned handles with the typed
accessors. `dealloc_object` (or a [`WAP_POOL`](../guides/authoring.html))
releases them.

## Objective-C type encodings

Methods describe their types with `@encode` strings. The bridge maps each code
to an `ffi_type` (for the call ABI) and to a boxed value (for the patch):

| Encoding | C type | Bridged as |
|----------|--------|------------|
| `c C` | `char` / `BOOL` | int32 |
| `s S` | `short` | int32 |
| `i I` | `int` | int32 |
| `q Q` | `long long` | int64 |
| `f` | `float` | float |
| `d` | `double` | double |
| `*` | `char *` | string |
| `@` | `id` | objc object |
| `#` | `Class` | class |
| `:` | `SEL` | selector |
| `{…}` | struct | struct (NSValue / raw bytes) |
| `(…)` | union | struct bytes |
| `b<n>` | bitfield | struct bits |
| `^` | pointer | int64 (address) |

## Direction 1 — into a replacement (Obj-C → wasm)

When a hooked method fires, each native argument is wrapped per its encoding and
handed to your wasm function (the first two are always `self` and `_cmd`):

```c
int my_method(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject first = get_array_item(args, 0);   // boxed per its encoding
    int32_t n = struct_get_int32(/* … */ 0);     // structs: read by offset
}
```

## Direction 2 — into a call (wasm → Obj-C)

When you call a method, each handle is unboxed into the native type the target
expects (read from the target's `NSMethodSignature`):

```c
WAPArray a = alloc_array();
append_array(a, alloc_int32(10));
append_array(a, new_objc_nsstring("two"));
call_class_method_param("Api", "n:label:", a);   // 10 -> int, NSString -> id
dealloc_array(a);
```

Return values travel the same way: the bridge reads the method's return type and
boxes the result into a handle you read with `print_object`, `get_array_item`,
the `cg*_get_*` / `struct_get_*` accessors, or by passing it straight to another
call.

## Strings and C strings

- `new_objc_nsstring(s)` → an `NSString` (encoding `@`).
- `alloc_string(s)` → a value usable where the method wants `const char *`
  (encoding `*`). Returned C strings are copied into stable storage so they stay
  valid after the call returns.

## Structs, unions, bitfields

These are bridged as raw bytes you read/write by **offset** (you know your own
layout), with typed helpers for the common geometry types. See
[Structs, unions & bitfields](../guides/structs.html).

## What isn't bridged

- Arbitrary C pointers cross only as opaque `int64` addresses — the bridge won't
  dereference them for you.
- Swift value types beyond the `@objc`-compatible surface (custom `enum`s,
  `Optional` of value types) aren't bridged; expose ObjC-friendly types at the
  patch boundary. See [Swift in depth](../guides/swift.html).
