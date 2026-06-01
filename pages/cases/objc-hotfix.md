---
title: "Case study: ship a crash hotfix"
eyebrow: "Case study"
description: "A nil-input crash in production, fixed and shipped with a signed WasmPatch payload — start to finish."
---

A walk-through of using WasmPatch to put out a fire: a crash is live, a binary
fix is days away through review, and you want users protected today.

## The bug

Crash reports point at one method:

```objc
// FeedViewController.m
- (void)renderItem:(Item *)item {
    [self.titleLabel setText:item.title];   // 💥 item is nil for a new server shape
}
```

A backend change started returning items your client doesn't expect; `item` is
`nil`, and a downstream access crashes. The proper fix ships in the next
release — but you can guard it now.

## 1. Write the patch

```c
// renderfix.c
#include <wasmpatch.h>

int safe_render(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject item = get_array_item(args, 0);
    if (item == 0) {
        print_string("WasmPatch: renderItem: received nil, skipping");
        return 0;                          // don't crash
    }
    call_instance_method_1(self, "renderItemImpl:", item);  // original safe path
    return 0;
}

int entry() {
    WAP_REPLACE_INSTANCE(FeedViewController, "renderItem:", safe_render);
    return 0;
}
```

> **Tip.** Patch the *symptom method* and forward valid cases to a method that
> still does the real work. Here we assume the real drawing lives in
> `renderItemImpl:`; if it doesn't, move the original body there in your next
> build so patches have a clean forward target.

## 2. Build and sign

```bash
Tool/wasmpatch doctor          # toolchain ready?
Tool/wasmpatch build renderfix.c
Tool/wasmpatch sign  renderfix.wasm patch_key.pem
# -> prints publicKeyECBase64 + signatureBase64; writes renderfix.wasm.sig
```

The public key is already embedded in your shipped app; the signature goes into
the patch manifest your server serves. See [Patch signing](../guides/signing.html).

## 3. Deliver and apply on launch

```swift
import WasmPatch

let mgr = WAPPatchManager.shared
mgr.fetchPatch(from: manifest.url, named: "renderfix", sha256: manifest.sha256) { path, error in
    guard path != nil else { return }            // network/integrity failure: do nothing
    let o = WAPPatchLoaderOptions.recommended()
    o.publicKeyECBase64 = Embedded.publicKey      // authenticity
    o.signatureBase64   = manifest.signature
    o.strictHooks       = true                    // fail if the target moved
    do { try mgr.applyCachedPatch(named: "renderfix", options: o) }
    catch { Telemetry.log("patch apply failed: \(error)") }
}
```

Gate the manifest by app version on your server so the patch only reaches the
build it was written for.

## 4. Verify it took

Route diagnostics during rollout:

```swift
WAPPatchLoader.setLogHandler { level, message in Telemetry.log("[wasm \(level)] \(message)") }
```

You should see `replaced -[FeedViewController renderItem:] -> safe_render`, and
the crash rate for that signature should fall to zero. The skip path logs
`renderItem: received nil, skipping`, which also tells you how often the bad
shape arrives.

## 5. Wind it down

When the real fix ships in a new binary, stop serving the manifest for that
version. On devices that still have it cached you can also call
`WAPPatchLoader.reset()` to restore the original implementation immediately —
your built-in kill switch.

## What this demonstrates

- **Speed:** a targeted guard, live, without a submission cycle.
- **Safety:** signed + integrity-checked, `strictHooks` so a moved symbol fails
  loudly, and reversible via `reset`.
- **Discipline:** patch the narrow symptom, forward valid cases, log the skip,
  and retire the patch once the binary fix lands.
