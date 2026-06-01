import Foundation
import SwiftUI
import WasmPatch

/// Drives loading the bundled WasmPatch payload and exposes the current greeting
/// so the UI can show the before/after of a live hot-patch.
@MainActor
final class PatchController: ObservableObject {
    @Published var greeting: String = DemoService().greeting()
    @Published var status: String = "Not patched yet."
    @Published var isPatched: Bool = false
    @Published var log: [String] = []

    private let service = DemoService()

    init() {
        WAPPatchLoader.setLogHandler { [weak self] level, message in
            let line = "[\(level)] \(message)"
            DispatchQueue.main.async { self?.log.append(line) }
        }
        refresh()
    }

    func refresh() {
        greeting = service.greeting()
    }

    /// Load `greeting.wasm` from the app bundle and apply it.
    func applyPatch() {
        guard let path = Bundle.main.path(forResource: "greeting", ofType: "wasm") else {
            status = "greeting.wasm missing from the app bundle."
            return
        }
        let options = WAPPatchLoaderOptions.recommended()
        options.allowReload = true
        options.resetBeforeLoad = true
        options.strictHooks = true
        do {
            try WAPPatchLoader.loadPatch(atPath: path, options: options)
            refresh()
            isPatched = true
            status = "Patch applied — greeting() is now served from WebAssembly."
        } catch {
            status = "Load failed: \(error.localizedDescription)"
        }
    }

    func reset() {
        WAPPatchLoader.reset()
        isPatched = false
        refresh()
        status = "Runtime reset — back to the original Swift implementation."
    }

    /// Headless self-test for CI: returns true if the patch swaps the greeting.
    static func runHeadlessSelfTest() -> Bool {
        let service = DemoService()
        let before = service.greeting()
        guard let path = Bundle.main.path(forResource: "greeting", ofType: "wasm") else {
            FileHandle.standardError.write("greeting.wasm missing\n".data(using: .utf8)!)
            return false
        }
        let options = WAPPatchLoaderOptions.recommended()
        options.allowReload = true
        options.resetBeforeLoad = true
        options.strictHooks = true
        do {
            try WAPPatchLoader.loadPatch(atPath: path, options: options)
        } catch {
            FileHandle.standardError.write("load failed: \(error.localizedDescription)\n".data(using: .utf8)!)
            return false
        }
        let after = service.greeting()
        FileHandle.standardError.write("before=\(before)\nafter=\(after)\n".data(using: .utf8)!)
        return before != after && after.contains("WebAssembly")
    }
}
