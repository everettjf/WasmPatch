---
title: "Case study: gate a Swift feature"
eyebrow: "Case study"
description: "Flip a Swift @objc dynamic method's behaviour with a patch — and roll it back — end to end."
---

A walk-through of changing Swift behaviour in the field: a computed value is
wrong for some users, and you want to correct it (or A/B it) without shipping a
build.

## The setup

A Swift service exposes a value the UI reads:

```swift
@objc(PricingService)
final class PricingService: NSObject {
    @objc dynamic func discountPercent() -> Int { 0 }   // shipped: no discount
}
```

Because it's `@objc dynamic` on an `@objc` class, WasmPatch can replace it. (A
plain `func` could not — see [Swift in depth](../guides/swift.html).) The
explicit `@objc(PricingService)` name is what the patch references, independent
of Swift name mangling.

## 1. Confirm it's hookable

```bash
Tool/scan-hookable.sh MyApp.app/Contents/MacOS/MyApp PricingService
# @ PricingService
#     -[PricingService discountPercent]   ✅ present -> hookable
```

If the method isn't listed, it isn't `@objc dynamic` — fix that in the next
build first.

## 2. Write the patch

```c
// discount.c
#include <wasmpatch.h>

int discount_15(WAPObject self, const char *cmd) {
    return 15;          // turn on a 15% discount
}

int entry() {
    WAP_REPLACE_INSTANCE(PricingService, "discountPercent", discount_15);
    return 0;
}
```

Swift bridges `Int` ↔ the Obj-C integer return, so returning `15` from the C
replacement is all it takes.

## 3. Build, and load from Swift

```bash
Tool/wasmpatch build discount.c
```

```swift
import WasmPatch

let before = PricingService().discountPercent()   // 0

let o = WAPPatchLoaderOptions.recommended()
o.allowReload = true
o.resetBeforeLoad = true
o.strictHooks = true
try WAPPatchLoader.loadPatch(named: "discount", inBundle: .main, options: o)

let after = PricingService().discountPercent()     // 15 — served from wasm
```

In a real rollout you'd deliver `discount.wasm` with
[`WAPPatchManager`](../guides/remote-delivery.html) and a signature, exactly as
in the [Obj-C hotfix case](objc-hotfix.html).

## 4. A/B and roll back

Because applying and resetting are runtime operations, you can drive them from
your experiment system:

```swift
func setDiscountExperiment(_ enabled: Bool) {
    if enabled {
        try? WAPPatchManager.shared.applyCachedPatch(named: "discount", options: opts)
    } else {
        WAPPatchLoader.reset()   // restore the shipped 0% implementation
    }
}
```

Assign users to the treatment server-side (who gets the manifest), measure, and
flip everyone back with `reset()` if the experiment loses.

## Caveats specific to Swift

- Only `@objc dynamic` methods on `@objc`/`NSObject` classes are reachable.
- Pass **module-qualified or explicitly-named** classes; prefer `@objc(Name)` so
  patches don't depend on mangled symbols.
- Return/argument types must be `@objc`-bridgeable (`Int`, `Bool`, `Double`,
  `String`, `NSObject` subclasses, the supported structs). Swift `enum`s and
  `Optional` value types need an ObjC-friendly surface at the boundary.

## A live, runnable version

The repo's **`Demo/WasmPatch-SwiftUI`** app does exactly this with Apply / Reset
buttons — open it to watch an `@objc dynamic` method change under a running UI.
