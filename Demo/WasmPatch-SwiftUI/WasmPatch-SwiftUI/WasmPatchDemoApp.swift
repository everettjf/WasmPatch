import SwiftUI
import Foundation

@main
struct WasmPatchDemoApp: App {
    @StateObject private var controller = PatchController()

    init() {
        // Headless self-test for CI: `WASMPATCH_AUTOTEST=1 ./WasmPatch-SwiftUI`
        // loads the bundled patch, verifies the greeting changed, and exits.
        if ProcessInfo.processInfo.environment["WASMPATCH_AUTOTEST"] == "1" {
            let ok = PatchController.runHeadlessSelfTest()
            FileHandle.standardError.write((ok ? "WASMPATCH_AUTOTEST_PASS\n" : "WASMPATCH_AUTOTEST_FAIL\n").data(using: .utf8)!)
            exit(ok ? 0 : 1)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
        }
        .windowResizability(.contentSize)
    }
}
