# Using WasmPatch with Swift

WasmPatch replaces and calls methods through the **Objective-C runtime**. That
single fact drives everything below: a Swift method is reachable only when it is
exposed to the Objective-C runtime.

## What can be patched

| Swift declaration | Hookable? | Why |
|---|---|---|
| `@objc dynamic func foo()` | ✅ yes | Goes through `objc_msgSend`; the IMP can be swapped |
| `@objc func foo()` (no `dynamic`) | ⚠️ not reliably | Exposed to ObjC but may be dispatched statically / inlined |
| `func foo()` (plain Swift) | ❌ no | Static / witness-table dispatch; invisible to the ObjC runtime |
| `NSObject` subclass method overriding ObjC | ✅ yes | Already ObjC-dispatched |

**Rule of thumb:** to make a Swift method patchable, mark it `@objc dynamic`
and make sure the class is an `@objc` class (an `NSObject` subclass is). The
class name you pass to WasmPatch must be **module-qualified**:

```swift
// In module "MyApp"
@objc(MyAppNetworkManager)            // optional explicit ObjC name
class NetworkManager: NSObject {
    @objc dynamic func send(_ url: String) -> Bool { ... }
}
```

```c
// patch.c — use the runtime name of the class
replace_instance_method("MyAppNetworkManager", "send:", "my_send");
// or, without @objc(...), the mangled "MyApp.NetworkManager" form:
// replace_instance_method("_TtC5MyApp14NetworkManager", "send:", "my_send");
```

Prefer giving patch targets a stable explicit `@objc(Name)` so the class name
does not depend on Swift name mangling.

## Finding the hookable surface

Use the scanner to list the Objective-C method surface of your built binary —
that is exactly the set WasmPatch can reach:

```bash
Tool/scan-hookable.sh MyApp.app/Contents/MacOS/MyApp NetworkManager
```

A method that does **not** appear there cannot be patched until you add
`@objc dynamic`.

## Value type bridging

The bridge marshals these automatically when they appear in an `@objc dynamic`
signature:

| Type | Bridged as | Build / read in the patch |
|---|---|---|
| `String` / `NSString` | string | `new_objc_nsstring`, `alloc_string`; returned as a string object |
| `Bool` | `BOOL` (`c`/`B`) | return `0`/`1` from the replacement |
| `Int`, `Int32`, `Int64` | integer | `alloc_int32` / `alloc_int64`; return an int |
| `Double` / `Float` | floating point | `alloc_double` / `alloc_float`; return a double |
| `CGPoint`/`CGSize`/`CGRect` | struct (NSValue) | `alloc_cgrect(...)`, `cgrect_get_x(...)` etc. |
| `NSRange` | struct (NSValue) | forwarded by value (no convenience constructor yet) |
| class instances (`NSObject` subclasses) | objc object | `call_*_method_*`, pass the `WAPObject` handle |

### Struct example

```c
#include <wasmpatch.h>

// Replace `@objc dynamic func boundsForContent() -> CGRect`
WAPObject my_bounds(WAPObject self, const char *cmd) {
    return alloc_cgrect(0, 0, 320, 64);
}

// Replace `@objc dynamic func area(of rect: CGRect) -> Int`
int my_area(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject rect = get_array_item(args, 0);
    return (int)(cgrect_get_width(rect) * cgrect_get_height(rect));
}

int entry() {
    WAP_REPLACE_INSTANCE(MyAppLayout, "boundsForContent", my_bounds);
    WAP_REPLACE_INSTANCE(MyAppLayout, "area:", my_area);
    return 0;
}
```

## Loading from Swift

```swift
import WasmPatch

WAPPatchLoader.setLogHandler { level, message in
    print("[WasmPatch \(level)] \(message)")
}

let options = WAPPatchLoaderOptions.recommended()
options.strictHooks = true            // fail load if a target is missing
options.expectedSHA256Hex = expectedHash

do {
    try WAPPatchLoader.loadPatch(named: "patch", in: .main, options: options)
} catch {
    print("patch load failed: \(error)")
}
```

(The `try`/throwing form comes from the `NSError **` API; method names import as
`loadPatch(named:in:options:)` etc.)

## Completion handlers (blocks)

A replaced method can **invoke a block it was handed** (e.g. a completion
handler) via `invoke_block`:

```c
// Replace `@objc dynamic func fetch(_ completion: @escaping (String) -> Void)`
int my_fetch(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject completion = get_array_item(args, 0);   // the block argument
    WAPArray cbArgs = alloc_array();
    append_array(cbArgs, new_objc_nsstring("from-wasm"));
    invoke_block(completion, cbArgs);                 // call it back
    dealloc_array(cbArgs);
    return 0;
}
```

`invoke_block` reads the block's encoded signature and marshals object / string
/ integer / floating-point / `BOOL` arguments. The end-to-end Swift demo
(`Tool/validate-swift.sh`) hooks an `@objc dynamic` method and verifies this.

A patch can also **create a block** to hand *to* an Objective-C method (e.g. as
a completion handler). `create_block` binds a wasm export to an Obj-C block; the
export runs when the host later invokes the block:

```c
// wasm body: receives the block's arguments as a WAPArray
WAPObject on_done(WAPArray args) {
    WAPObject value = get_array_item(args, 0);
    call_class_method_1("Analytics", "track:", value);
    return 0; // non-void blocks return a WAPObject / scalar
}

int entry() {
    // "v@?@" == void(^)(id). The "@?" is the implicit block self.
    WAPObject block = create_block("on_done", "v@?@");
    call_class_method_1("DataLoader", "loadWithCompletion:", block);
    return 0;
}
```

The block's wasm callback must run **after** `entry()` returns (the normal
async-completion flow); invoking it synchronously while `entry()` is still on
the stack would re-enter the wasm runtime. Created blocks are owned by the
runtime and released on reset.

## Arbitrary structs

Beyond the geometry helpers, any by-value struct is bridged generically: its
libffi type is built from the Objective-C encoding, and the patch reads/writes
fields by byte offset.

```c
// struct Vec3 { float x, y, z; }  ->  encoding "{Vec3=fff}", fields at 0/4/8
WAPObject v = alloc_struct("{Vec3=fff}");
struct_set_float(v, 0, 1.0f);
struct_set_float(v, 4, 2.0f);
struct_set_float(v, 8, 3.0f);
// pass `v` to a method taking a Vec3, or read an incoming one:
//   float x = struct_get_float(incoming, 0);
```

### Unions & bitfields

Structs containing **unions** or **bitfields** bridge too. Read a union member
at its byte offset; read/write bitfields with `struct_get_bits` /
`struct_set_bits` (bit offsets counted from the struct start):

```c
// struct { uint32_t a:4; uint32_t b:4; uint32_t c:24; }  -> "{Flags=b4b4b24}"
WAPObject f = alloc_struct("{Flags=b4b4b24}");
struct_set_bits(f, 0, 4, 1);    // a = 1
struct_set_bits(f, 4, 4, 2);    // b = 2
struct_set_bits(f, 8, 24, 300); // c = 300
// reading an incoming one: int64_t a = struct_get_bits(incoming, 0, 4);
```

## Current limitations

- A **bitfield's storage type isn't in the `@encode` string**, so the layout
  engine infers an all-bitfield struct's size from its total bit count. This is
  correct when the bitfields fill their storage unit (the usual case); pad to a
  whole storage unit if your struct has trailing unused bits in a wider type.
- **Bare top-level union arguments** aren't bridged — wrap the union in a struct.
- Floating-point members inside a union aren't classified correctly.
- Swift `enum`s and `Optional` of value types are not specially bridged; expose
  an `@objc`-compatible surface (e.g. `NSInteger`, nullable objects) at the
  patch boundary.
