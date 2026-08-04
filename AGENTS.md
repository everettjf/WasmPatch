# Repository Guidelines

WasmPatch is a WebAssembly-driven Objective-C hot-patch runtime for iOS and macOS. Treat patch loading as security-sensitive code.

## Structure

- `WasmPatch/Classes`: runtime, Objective-C bridge, wasm3, and libffi integration.
- `Demo/SwiftExample`: Swift Package example.
- `Tests/` and demo targets: runtime and integration verification.
- `Tools/`: patch build tooling.
- `SWIFT.md`: Swift integration guide.

## Verification

```bash
swift build
```

Runtime changes require device/host tests for supported architectures, rejected payloads, symbol lookup, method replacement, and rollback behavior.

## Security and Conventions

- Verify patch authenticity and compatibility before execution.
- Fail closed on malformed modules, missing exports, signature errors, or ABI mismatch.
- Keep an auditable record of patch identity and activation outcome without logging secrets.
- Preserve thread safety and Objective-C calling conventions across libffi boundaries.
- Document App Store, code-signing, and production-risk implications prominently.
- Do not update vendored wasm3/libffi code as part of unrelated work.

Keep README and Swift integration docs aligned. Canonical repository: `https://github.com/everettjf/wasmpatch`.
