---
title: "Security model"
eyebrow: "Delivery & safety"
description: "The sandbox boundary, integrity vs. authenticity, the threat model, and production guidance."
---

A hot-patch system ships code that runs in your app. WasmPatch's job is to make
that *bounded* and *verifiable*. This page is the honest version of what it does
and doesn't protect.

## The sandbox boundary

A patch is **not** native code. It runs in the wasm3 interpreter and can only do
two things:

1. compute in its own linear memory, and
2. call the **host export functions** WasmPatch links in.

There is no raw syscall surface, no arbitrary native execution, no access to
process memory the bridge doesn't hand it. The attack/blast surface is the
bridge itself.

**But the bridge is powerful.** The exports let a patch call *any* Objective-C
method and replace methods on *any* class. That's the whole point — and it means
a patch is privileged code. Treat a `.wasm` patch with the same trust you'd give
a code change you ship: it must come from you.

## Integrity vs. authenticity

Two independent checks, both before a patch is applied:

| Check | Option | Proves | Defeats |
|-------|--------|--------|---------|
| **Integrity** | `expectedSHA256Hex` | the bytes are exactly what you hashed | accidental corruption, truncation |
| **Authenticity** | `publicKeyECBase64` + `signatureBase64` | *you* produced the bytes | tampering / substitution by anyone without your key |

SHA-256 alone is not a security control for remote delivery: whoever can swap
the patch can also swap the hash. Pair it with an **EC P-256 signature** so a
modified patch can't be re-signed. See [Patch signing](../guides/signing.html).

```objc
WAPPatchLoaderOptions *o = [WAPPatchLoader recommendedOptions];
o.publicKeyECBase64 = embeddedPublicKey;   // shipped in the app binary
o.signatureBase64   = deliveredSignature;  // from your manifest
o.strictHooks       = YES;
```

## Threat model

What WasmPatch defends against, assuming you sign patches and embed the public
key in the app:

- **A man-in-the-middle or compromised CDN** swapping the payload → rejected
  (signature fails, error code 8).
- **A corrupted download** → rejected (bad wasm magic / SHA mismatch).
- **A patch targeting a renamed/removed symbol** → fails loudly with
  `strictHooks` instead of silently doing nothing.

What it does **not** defend against, by design:

- A patch *you* signed that does something harmful — signing proves origin, not
  intent. Review patches like any shipped code.
- An attacker who steals your **private signing key** — protect it like any
  release secret (KMS / CI secret), and plan rotation.
- A jailbroken device where the attacker already controls the process.

## Best practices

- **Always sign** production patches and keep the private key out of the app and
  out of source control.
- **Keep `strictHooks = true`** in production so a patch that no longer matches
  the binary fails instead of half-applying.
- **Cap `maxBytes`** to a sane ceiling for your patches.
- **Serve over HTTPS** and gate patches by app version / staged rollout on the
  server; verify on-device regardless.
- **Have a kill switch** — `reset()` restores original behaviour at runtime.

## Platform policy

App Store guidelines restrict downloading executable code. Interpreted patches
that don't change an app's intended purpose are the common framing, but the
rules evolve and enforcement is at Apple's discretion — this is a product/legal
decision, not a technical one. WasmPatch gives you the verifiable, sandboxed,
reversible mechanism; **using it within policy is your call.** Many teams use it
in enterprise / internal distributions where this isn't a constraint.
