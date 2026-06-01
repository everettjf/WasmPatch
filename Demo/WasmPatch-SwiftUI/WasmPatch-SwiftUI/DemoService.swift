import Foundation

/// The class WasmPatch will hot-patch. Only `@objc dynamic` methods on an
/// `@objc` class go through Objective-C message dispatch and can be replaced.
/// The explicit `@objc(DemoService)` name is what the patch references.
@objc(DemoService)
final class DemoService: NSObject {
    @objc dynamic func greeting() -> String {
        "Hello from the original Swift build"
    }
}
