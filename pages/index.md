---
title: WasmPatch
description: WebAssembly-driven hot patching for iOS & macOS apps
---

# WasmPatch

**Hot-fix iOS/macOS apps with WebAssembly.** Compile a small C patch to a
`.wasm` payload, load it at runtime, and call or replace Objective-C / Swift
methods — no App Store round-trip.

> New here? Start with the **[Tutorial](tutorial.md)** — it goes from install to
> a live method replacement in about ten minutes.

## Why WasmPatch

- **Sandboxed logic** — patch behaviour runs in a wasm interpreter, not raw
  native code injection.
- **Real method replacement** — class & instance methods are swapped via the
  Objective-C runtime + libffi, so callers transparently hit your patch.
- **Swift-ready** — hook `@objc dynamic` methods; bridge strings, numbers,
  structs (incl. unions & bitfields), and blocks.
- **Safe delivery** — SHA-256 integrity *and* EC P-256 signature authenticity,
  with fetch/cache/apply built in.

## Guides

| Guide | What it covers |
|-------|----------------|
| [Tutorial](tutorial.md) | End-to-end: install → write → build → load (Obj-C & Swift) |
| [Authoring patches](guides/authoring.md) | The C SDK, `WAP_REPLACE_*` macros, cleanup pools, calling methods |
| [Swift support](guides/swift.md) | What's hookable, value/struct/block bridging, the surface scanner |
| [Structs](guides/structs.md) | Geometry, arbitrary, union and bitfield structs |
| [Blocks](guides/blocks.md) | Invoking received blocks and creating blocks |
| [Diagnostics](guides/diagnostics.md) | Log handler, strict-hook policy, error codes |
| [Remote delivery](guides/remote-delivery.md) | `WAPPatchManager`: fetch, verify, cache, apply |
| [Patch signing](guides/signing.md) | EC P-256 keygen, signing, and load-time verification |
| [Integration](guides/integration.md) | Swift Package Manager & CocoaPods |
| [Deploying these docs](DEPLOY.md) | Publish this folder to GitHub Pages |

## A 30-second taste

```c
#include <wasmpatch.h>

WAPObject patched_token(WAPObject self, const char *cmd) {
    return new_objc_nsstring("patched at runtime");
}

int entry() {
    // The registered name is derived from the real symbol — a typo won't compile.
    WAP_REPLACE_CLASS(SessionManager, "authToken", patched_token);
    return 0;
}
```

```bash
Tool/wasmpatch build patch.c          # -> patch.wasm (+ sha256/meta)
```

```objc
[WAPPatchLoader loadPatchNamed:@"patch" inBundle:NSBundle.mainBundle
                       options:[WAPPatchLoader recommendedOptions] error:&error];
```

---

WasmPatch is MIT-licensed. Source & issues:
[github.com/everettjf/WasmPatch](https://github.com/everettjf/WasmPatch).
