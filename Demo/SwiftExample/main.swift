// Real end-to-end Swift demo: define an `@objc dynamic` Swift method, then load
// a WasmPatch payload that replaces it and observe the new behaviour.
//
// Run via the harness which compiles the patch and passes its path:
//   Tool/validate-swift.sh
// or manually:
//   swift run WasmPatchSwiftExample /path/to/greeting.wasm
import Foundation
import WasmPatch

// An @objc dynamic method on an @objc class is the surface WasmPatch can hook.
// The explicit @objc(DemoService) name is what the patch references.
@objc(DemoService)
final class DemoService: NSObject {
    @objc dynamic func greeting() -> String { "original-greeting" }
}

func main() -> Int32 {
    WAPPatchLoader.setLogHandler { level, message in
        FileHandle.standardError.write("[WasmPatch \(level)] \(message)\n".data(using: .utf8)!)
    }

    let service = DemoService()
    let before = service.greeting()
    print("before patch: \(before)")

    guard CommandLine.arguments.count > 1 else {
        print("no patch path provided; API surface OK, isLoaded=\(WAPPatchLoader.isLoaded())")
        return 0
    }

    let patchPath = CommandLine.arguments[1]
    let options = WAPPatchLoaderOptions.recommended()
    options.allowReload = true
    options.resetBeforeLoad = true
    options.strictHooks = true   // fail loudly if DemoService.greeting isn't found

    do {
        try WAPPatchLoader.loadPatch(atPath: patchPath, options: options)
    } catch {
        print("FAIL: patch load failed: \(error.localizedDescription)")
        return 1
    }

    let after = service.greeting()
    print("after patch:  \(after)")

    guard after == "patched-by-wasm" else {
        print("FAIL: expected 'patched-by-wasm', got '\(after)'")
        return 1
    }
    print("SWIFT_DEMO_PASS")
    return 0
}

exit(main())
