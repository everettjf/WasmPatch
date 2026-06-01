---
title: Remote delivery
---

# Remote delivery

[← Docs home](../index.md)

`WAPPatchManager` handles the "fetch on launch, verify, cache, apply" flow for
patches delivered from a server.

## API

```objc
@property (class, readonly) WAPPatchManager *sharedManager;
@property (nonatomic, copy) NSString *cacheDirectory; // default: <App Support>/WasmPatch

- (void)fetchPatchFromURL:(NSURL *)url
                    named:(NSString *)name
                   sha256:(nullable NSString *)sha256Hex
               completion:(void (^)(NSString * _Nullable cachedPath, NSError * _Nullable error))completion;

- (BOOL)applyCachedPatchNamed:(NSString *)name
                      options:(nullable WAPPatchLoaderOptions *)options
                        error:(NSError **)error;

- (BOOL)hasCachedPatchNamed:(NSString *)name;
- (NSString *)cachedPathForName:(NSString *)name;
- (BOOL)removeCachedPatchNamed:(NSString *)name error:(NSError **)error;
- (void)clearCache;
+ (NSString *)sha256HexForData:(NSData *)data;
```

## Fetch → verify → cache → apply

```swift
let mgr = WAPPatchManager.shared
mgr.fetchPatch(from: url, named: "login_fix", sha256: expectedHash) { cachedPath, error in
    guard cachedPath != nil else {
        print("fetch failed: \(error?.localizedDescription ?? "unknown")")
        return
    }
    let options = WAPPatchLoaderOptions.recommended()
    options.allowReload = true
    options.resetBeforeLoad = true
    options.strictHooks = true
    try? mgr.applyCachedPatch(named: "login_fix", options: options)
}
```

```objc
WAPPatchManager *mgr = WAPPatchManager.sharedManager;
[mgr fetchPatchFromURL:url named:@"login_fix" sha256:expectedHash
           completion:^(NSString *cachedPath, NSError *error) {
    if (cachedPath) {
        [mgr applyCachedPatchNamed:@"login_fix" options:nil error:nil];
    }
}];
```

The download is SHA-256-verified (when a hash is supplied) **before** it's
written to the cache; `storePatchData:named:sha256:error:` exposes the same
verify+cache step for patches you obtain yourself.

## Recommended hardening

- Pair the SHA-256 integrity check with an **EC P-256 signature** so a tampered
  patch can't be re-signed — see [Patch signing](signing.md). Pass
  `publicKeyECBase64` + `signatureBase64` in the apply options.
- Serve patches over HTTPS and gate them on app version / staged rollout on your
  server.
- Keep `strictHooks = true` in production so a patch targeting a renamed symbol
  fails loudly instead of silently doing nothing.

## Verifying locally

`Tool/validate-remote.sh` serves the test fixture over a local HTTP server and
drives a real fetch → verify → cache → apply → assert cycle through the macOS
demo.
