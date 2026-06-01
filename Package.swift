// swift-tools-version:5.7
import PackageDescription

// Swift Package Manager support for WasmPatch.
//
// The sources are Objective-C++/C plus per-architecture libffi assembly. They
// rely on internal `#ifdef __arm64__` / `__x86_64__` guards (the same way the
// CocoaPods build consumes them), so every file is compiled and the
// wrong-architecture ones reduce to no-ops.
//
// This target builds the runtime as a C-family (non-Swift) module; Swift apps
// import it as `import WasmPatch` and use the Objective-C API
// (WAPPatchLoader / WasmPatch.h). See SWIFT.md.

let package = Package(
    name: "WasmPatch",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        .library(name: "WasmPatch", targets: ["WasmPatch"]),
        .executable(name: "WasmPatchSwiftExample", targets: ["WasmPatchSwiftExample"]),
    ],
    targets: [
        .target(
            name: "WasmPatch",
            path: "WasmPatch/Classes",
            exclude: [
                "wap/depend/wasm3/CMakeLists.txt",
            ],
            publicHeadersPath: "spm_include",
            // The sources include sibling headers by basename (matching the
            // CocoaPods recursive header search), so every internal header dir
            // must be on the search path.
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("wap"),
                .headerSearchPath("wap/core/util"),
                .headerSearchPath("wap/core/method"),
                .headerSearchPath("wap/core/runtime"),
                .headerSearchPath("wap/core/runtime/export"),
                .headerSearchPath("wap/depend/libffi/include"),
                .headerSearchPath("wap/depend/wasm3"),
            ],
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("wap"),
                .headerSearchPath("wap/core/util"),
                .headerSearchPath("wap/core/method"),
                .headerSearchPath("wap/core/runtime"),
                .headerSearchPath("wap/core/runtime/export"),
                .headerSearchPath("wap/depend/libffi/include"),
                .headerSearchPath("wap/depend/wasm3"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .executableTarget(
            name: "WasmPatchSwiftExample",
            dependencies: ["WasmPatch"],
            path: "Demo/SwiftExample"
        ),
    ],
    cxxLanguageStandard: .cxx17
)
