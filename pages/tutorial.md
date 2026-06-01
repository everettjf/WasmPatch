---
title: Tutorial
---

# Tutorial: your first hot-patch

This walks from a clean machine to a live method replacement. ~10 minutes.

[← Docs home](index.md)

## 1. Install the toolchain

WasmPatch compiles C to `wasm32`, which Apple's `clang` can't target — install
LLVM (and `wabt` for `.wat` dumps):

```bash
brew install llvm wabt
# or: sh Tool/install-llvm.sh
```

Verify everything is in place:

```bash
Tool/wasmpatch doctor
```

You should see green `OK` lines for the wasm-capable clang, `wasm-ld`,
`wasm2wat`, and the author SDK header.

## 2. Add WasmPatch to your app

**Swift Package Manager** — add the package and link the `WasmPatch` product:

```swift
.package(url: "https://github.com/everettjf/WasmPatch.git", branch: "master")
```

**CocoaPods**:

```ruby
pod 'WasmPatch'
```

See [Integration](guides/integration.md) for details.

## 3. Pick something to patch

WasmPatch replaces methods that go through Objective-C message dispatch.

- **Objective-C**: any method works.
- **Swift**: the method must be `@objc dynamic` on an `@objc` class.

```swift
@objc(SessionManager)
final class SessionManager: NSObject {
    @objc dynamic func authToken() -> String { "original-token" }
}
```

Not sure what's hookable in a build? Scan it:

```bash
Tool/scan-hookable.sh MyApp.app/Contents/MacOS/MyApp SessionManager
```

## 4. Write the patch

Patches are C including `<wasmpatch.h>`. Replacement functions are registered
with the `WAP_REPLACE_*` macros, which derive the runtime name from the real C
symbol (so a typo is a compile error, never a silent no-op):

```c
// patch.c
#include <wasmpatch.h>

WAPObject patched_token(WAPObject self, const char *cmd) {
    return new_objc_nsstring("patched-token-from-wasm");
}

int entry() {
    WAP_REPLACE_INSTANCE(SessionManager, "authToken", patched_token);
    return 0;
}
```

`entry()` runs once when the patch loads — register replacements and do any
one-time calls there. See [Authoring patches](guides/authoring.md) for calling
methods, passing arguments, structs, and blocks.

## 5. Build the patch

```bash
Tool/wasmpatch build patch.c
# -> patch.wasm, patch.wasm.sha256, patch.wasm.meta.json
```

The SDK header is injected automatically and a SHA-256 + metadata sidecar is
written next to the `.wasm` for verification.

## 6. Load it in the app

**Objective-C:**

```objc
#import <WasmPatch/WAPPatchLoader.h>

NSError *error = nil;
WAPPatchLoaderOptions *options = [WAPPatchLoader recommendedOptions];
options.strictHooks = YES; // fail if a target class/selector is missing

BOOL ok = [WAPPatchLoader loadPatchNamed:@"patch"
                                inBundle:NSBundle.mainBundle
                                 options:options
                                   error:&error];
if (!ok) { NSLog(@"patch load failed: %@", error); }
```

**Swift:**

```swift
import WasmPatch

let options = WAPPatchLoaderOptions.recommended()
options.strictHooks = true
try WAPPatchLoader.loadPatch(named: "patch", inBundle: .main, options: options)
```

After loading, `SessionManager().authToken()` returns
`"patched-token-from-wasm"` — the original Swift/Obj-C implementation has been
replaced at runtime.

## 7. Observe and verify

Route diagnostics to your logs while developing:

```swift
WAPPatchLoader.setLogHandler { level, message in
    print("[WasmPatch \(level)] \(message)")
}
```

You'll see lines like `replaced -[SessionManager authToken] -> patched_token`.

## Next steps

- Ship patches safely — [Patch signing](guides/signing.md) and
  [Remote delivery](guides/remote-delivery.md).
- Patch UIKit/AppKit APIs that use structs — [Structs](guides/structs.md).
- Patch async APIs — [Blocks](guides/blocks.md).
- See it live — the `Demo/WasmPatch-SwiftUI` app hot-patches an `@objc dynamic`
  method with Apply/Reset buttons.
