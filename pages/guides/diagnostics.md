---
title: Diagnostics
---

# Diagnostics

[← Docs home](../index.md)

## Log handler

Route runtime diagnostics to your own sink (APM, console, file). Levels:
`0` info, `1` warning, `2` error.

```objc
[WAPPatchLoader setLogHandler:^(NSInteger level, NSString *message) {
    NSLog(@"[WasmPatch %ld] %@", (long)level, message);
}];
```

```swift
WAPPatchLoader.setLogHandler { level, message in
    print("[WasmPatch \(level)] \(message)")
}
```

```c
// C API
void wap_set_log_handler(WAPLogHandler handler); // void(*)(int level, const char *message)
```

Pass `nil`/`NULL` to restore the default (NSLog) sink. You'll see lines such as
`replaced -[NetworkManager send:] -> my_send` on success and structured failure
messages otherwise.

## Strict-hook policy

By default a `replace_*` that targets a missing class or selector is logged and
skipped (the patch still loads). Set `strictHooks` to make such a patch fail to
load instead:

```swift
let options = WAPPatchLoaderOptions.recommended()
options.strictHooks = true
```

## Error codes

`WAPPatchLoader` reports `NSError` in `WAPPatchLoaderErrorDomain`:

| Code | Meaning |
|------|---------|
| `WAPPatchLoaderErrorCodeInvalidArgument` (1) | nil/empty path, data, or bundle |
| `WAPPatchLoaderErrorCodePatchNotFound` (2) | resource/file missing |
| `WAPPatchLoaderErrorCodeAlreadyLoaded` (3) | already loaded and `allowReload` is off |
| `WAPPatchLoaderErrorCodeInvalidWasm` (4) | bad wasm magic |
| `WAPPatchLoaderErrorCodePayloadTooLarge` (5) | exceeds `maxBytes` |
| `WAPPatchLoaderErrorCodeSHA256Mismatch` (6) | `expectedSHA256Hex` didn't match |
| `WAPPatchLoaderErrorCodeLoadFailed` (7) | runtime/strict-hook failure |
| `WAPPatchLoaderErrorCodeSignatureInvalid` (8) | signature missing or invalid |

The underlying runtime message is also available:

```objc
NSString *detail = error.userInfo[WAPPatchLoaderRuntimeMessageKey];
const char *raw = wap_last_error(); // C API
```

## Load policy options

`WAPPatchLoaderOptions` (start from `recommendedOptions`):

| Option | Effect |
|--------|--------|
| `maxBytes` | reject payloads larger than this |
| `expectedSHA256Hex` | integrity check before load |
| `allowReload` | permit loading when already loaded |
| `resetBeforeLoad` | reset the runtime first |
| `strictHooks` | fail load on a missing hook target |
| `publicKeyECBase64` + `signatureBase64` | authenticity check ([Signing](signing.md)) |
