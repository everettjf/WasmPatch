---
title: Patch signing
---

# Patch signing

[← Docs home](../index.md)

SHA-256 (`expectedSHA256Hex`) proves **integrity** — that the bytes didn't
change. An EC P-256 signature proves **authenticity** — that *you* produced
them. Without your private key, an attacker who swaps the patch can't produce a
matching signature.

## 1. Create a signing key (once)

```bash
Tool/wasmpatch keygen patch_key.pem
```

Keep `patch_key.pem` private (CI secret / KMS). The command prints the **public
key** as a base64 uncompressed EC point — embed that in your app.

## 2. Sign a built patch

```bash
Tool/wasmpatch build your_patch.c
Tool/wasmpatch sign  your_patch.wasm patch_key.pem
# prints publicKeyECBase64 + signatureBase64; also writes .pub and .sig sidecars
```

Deliver the `signatureBase64` alongside the patch (e.g. in your manifest).

## 3. Verify at load

```objc
WAPPatchLoaderOptions *options = [WAPPatchLoader recommendedOptions];
options.publicKeyECBase64 = @"<embedded public key>";
options.signatureBase64   = @"<delivered with the patch>";

NSError *error = nil;
if (![WAPPatchLoader loadPatchAtPath:path options:options error:&error] &&
    error.code == WAPPatchLoaderErrorCodeSignatureInvalid) {
    NSLog(@"refused: patch is not authentically signed");
}
```

When both `publicKeyECBase64` and `signatureBase64` are set, the patch bytes are
verified with `Security.framework`
(`kSecKeyAlgorithmECDSASignatureMessageX962SHA256`) **before** loading; a
bad/absent signature fails with `WAPPatchLoaderErrorCodeSignatureInvalid` (8).

## Compatibility

The format is plain ECDSA-P256-SHA256:

- Public key: 65-byte uncompressed point (`0x04‖X‖Y`), base64.
- Signature: X9.62 DER, base64 — exactly what `openssl dgst -sha256 -sign`
  produces and what Apple's `SecKeyVerifySignature` expects.

So you can sign in CI with `openssl` instead of the CLI if you prefer.

## Verifying locally

`Tool/validate-signing.sh` generates a key, signs the fixture, and runs the
macOS demo twice — a valid signature loads, a tampered one is rejected with
code 8.

## Not included

Key **distribution and rotation** tooling (publishing public keys, rolling keys,
multi-key trust) is out of scope — wire signing into your existing release
infrastructure.
