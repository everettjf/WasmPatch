---
title: "Swift in depth"
eyebrow: "Writing patches"
description: "What's hookable from Swift, module-qualified names, value/struct/block bridging, and the limits."
---

WasmPatch replaces methods through the **Objective-C runtime**, so a Swift
method is reachable only when it's exposed to that runtime.

## What can be patched

| Swift declaration | Hookable? | Why |
|---|---|---|
| `@objc dynamic func foo()` | ✅ yes | Dispatched via `objc_msgSend`; the IMP can be swapped |
| `@objc func foo()` (no `dynamic`) | ⚠️ not reliably | May be dispatched statically / inlined |
| `func foo()` (plain Swift) | ❌ no | Static / witness-table dispatch — invisible to the runtime |
| `NSObject` subclass overriding ObjC | ✅ yes | Already ObjC-dispatched |

**Make a method patchable:** mark it `@objc dynamic` on an `@objc`/`NSObject`
class, and give the class a stable Objective-C name:

```swift
@objc(SessionManager)
final class SessionManager: NSObject {
    @objc dynamic func authToken() -> String { "original" }
}
```

The class name passed to WasmPatch must be the **runtime name** — the explicit
`@objc(SessionManager)` above, or the mangled `_TtC5MyApp14SessionManager`
without it. Prefer the explicit name so patches don't depend on mangling.

## Finding the hookable surface

```bash
Tool/scan-hookable.sh MyApp.app/Contents/MacOS/MyApp [ClassFilter]
```

It lists the Objective-C method surface of the binary — exactly what WasmPatch
can reach. A method not listed needs `@objc dynamic`.

## Value bridging

These bridge automatically in an `@objc dynamic` signature:

| Swift type | Bridged as | In the patch |
|---|---|---|
| `String` / `NSString` | string | `new_objc_nsstring`, returned as a string object |
| `Bool` | `BOOL` | return `0`/`1` |
| `Int`/`Int32`/`Int64` | integer | `alloc_int32`/`alloc_int64`; return an int |
| `Double`/`Float` | floating point | `alloc_double`/`alloc_float`; return a double |
| `CGPoint`/`CGSize`/`CGRect`/`NSRange` | struct | see [Structs](structs.html) |
| other structs (incl. unions/bitfields) | struct | see [Structs](structs.html) |
| `NSObject` subclasses | objc object | pass the `WAPObject` handle |
| `@escaping` closures | block | see [Blocks](blocks.html) |

`enum`s and `Optional`s of value types aren't specially bridged — expose an
`@objc`-compatible surface (e.g. `NSInteger`, nullable objects) at the patch
boundary.

## Loading from Swift

```swift
import WasmPatch

WAPPatchLoader.setLogHandler { level, message in
    print("[WasmPatch \(level)] \(message)")
}

let options = WAPPatchLoaderOptions.recommended()
options.strictHooks = true
options.expectedSHA256Hex = expectedHash      // optional integrity check
options.publicKeyECBase64 = embeddedPublicKey // optional authenticity check
options.signatureBase64   = deliveredSignature

do {
    try WAPPatchLoader.loadPatch(named: "patch", inBundle: .main, options: options)
} catch {
    print("patch load failed: \(error.localizedDescription)")
}
```

A complete, runnable example: the **`Demo/WasmPatch-SwiftUI`** macOS app
hot-patches an `@objc dynamic` method live with Apply/Reset buttons.

## See also

[Structs](structs.html) · [Blocks](blocks.html) · [Signing](signing.html) ·
[Remote delivery](remote-delivery.html)
