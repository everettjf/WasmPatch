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

## Current limitations

- **Creating new blocks inside wasm** to pass *into* an Objective-C method is
  not supported — only invoking blocks the patch receives.
- **Generic / arbitrary structs** beyond the geometry set above fall back to
  pointer passing and should not be relied on.
- Swift `enum`s and `Optional` of value types are not specially bridged; expose
  an `@objc`-compatible surface (e.g. `NSInteger`, nullable objects) at the
  patch boundary.
