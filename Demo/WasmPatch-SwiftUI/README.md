# WasmPatch SwiftUI Demo

A native macOS **SwiftUI** app (Xcode project) that hot-patches an
`@objc dynamic` Swift method at runtime with a WebAssembly payload.

![flow](../../Image/WasmPatch.png)

## What it shows

- `DemoService.greeting()` is an `@objc dynamic` Swift method (`DemoService.swift`).
- Tapping **Apply Patch** loads `greeting.wasm` from the app bundle via
  `WAPPatchLoader`; the method's implementation is replaced live and the UI
  updates from *"Hello from the original Swift build"* to
  *"Hello from WebAssembly (patched at runtime)"*.
- **Reset** restores the original implementation.
- The runtime log pane shows WasmPatch's diagnostics via `setLogHandler`.

## Running

Open `WasmPatch-SwiftUI.xcodeproj` in Xcode and run the `WasmPatch-SwiftUI`
scheme (the project depends on the local WasmPatch Swift package at the repo
root — no extra setup).

Headless self-test (used by CI):

```bash
sh Tool/validate-swiftui-app.sh
```

## Project layout

| File | Role |
|------|------|
| `WasmPatchDemoApp.swift` | SwiftUI `@main` app (+ headless self-test hook) |
| `ContentView.swift` | UI: greeting, Apply/Reset buttons, log |
| `DemoService.swift` | the `@objc dynamic` class being patched |
| `PatchController.swift` | loads/applies the patch through `WAPPatchLoader` |
| `greeting.wasm` | the compiled patch bundled as a resource |
| `patch/greeting.c` | the patch source (compiled with `Tool/wasmpatch build`, not by Xcode) |

## Rebuilding the patch

```bash
Tool/wasmpatch build Demo/WasmPatch-SwiftUI/patch/greeting.c \
  Demo/WasmPatch-SwiftUI/WasmPatch-SwiftUI/greeting.wasm
```
