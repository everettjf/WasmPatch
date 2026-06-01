// A minimal Swift consumer of WasmPatch, built by SwiftPM as proof that the
// Objective-C API imports and type-checks cleanly from Swift. It does not load
// a real patch here (no bundle in this context); it exercises the API surface
// described in SWIFT.md.
import Foundation
import WasmPatch

// Route runtime diagnostics into Swift.
WAPPatchLoader.setLogHandler { level, message in
    print("[WasmPatch \(level)] \(message)")
}

// Build options the way a Swift app would.
let options = WAPPatchLoaderOptions.recommended()
options.allowReload = true
options.strictHooks = true

// Apply a patch shipped in a bundle (guarded so the example is runnable).
func applyBundledPatch(named name: String) {
    do {
        try WAPPatchLoader.loadPatch(named: name, inBundle: Bundle.main, options: options)
        print("patch applied; loaded = \(WAPPatchLoader.isLoaded())")
    } catch {
        print("patch load failed: \(error.localizedDescription)")
    }
}

// Remote delivery via WAPPatchManager (verify + cache + apply).
func applyRemotePatch(from url: URL, sha256: String) {
    WAPPatchManager.shared.fetchPatch(from: url, named: "remote", sha256: sha256) { cachedPath, error in
        if let cachedPath = cachedPath {
            try? WAPPatchManager.shared.applyCachedPatch(named: "remote", options: options)
            print("applied cached patch at \(cachedPath)")
        } else {
            print("fetch failed: \(error?.localizedDescription ?? "unknown")")
        }
    }
}

print("WasmPatch Swift example: API surface available. isLoaded=\(WAPPatchLoader.isLoaded())")
_ = applyBundledPatch
_ = applyRemotePatch
