---
title: "FAQ & troubleshooting"
eyebrow: "Reference"
description: "Common errors, gotchas, and answers — from the wasm toolchain to Swift hookability and App Store policy."
---

## Toolchain

**`No available targets are compatible with triple "wasm32"`**
Apple's `/usr/bin/clang` can't target wasm. Install LLVM: `brew install llvm`
(the `wasmpatch` CLI and `c2wasm.sh` auto-discover it). Run `Tool/wasmpatch
doctor` to confirm.

**`wasm-ld not found`**
Comes with LLVM; ensure `brew install llvm` completed, or set `WASM_LD_BIN`.

**`.wat` generation skipped**
Optional — install `wabt` (`brew install wabt`) if you want the text dump.

## Loading

**`class not found` / `selector not found` at load**
The patch references a class/selector that isn't in the running binary. For
Swift, check it's `@objc dynamic` and you used the **runtime class name**
(`@objc(Name)` or the mangled form). Use `Tool/scan-hookable.sh <binary>` to
list what's actually hookable. Enable `strictHooks` so this fails the load
instead of silently skipping.

**The patch "loads" but nothing changes**
Without `strictHooks`, a hook whose target is missing is logged and skipped.
Turn on `strictHooks`, and add a [log handler](guides/diagnostics.html) — a
successful hook logs `replaced -[Class sel] -> fn`.

**`WAPPatchLoaderErrorCodeAlreadyLoaded` (3)**
A patch is already loaded. Set `allowReload = true` (and usually
`resetBeforeLoad = true`).

**`WAPPatchLoaderErrorCodeSignatureInvalid` (8)**
The signature is missing or doesn't match the bytes under the given public key.
Re-sign the exact `.wasm` you're shipping; confirm the public key embedded in
the app matches the signing key. See [Patch signing](guides/signing.html).

## Swift

**My Swift method isn't being replaced.**
It must be `@objc dynamic` on an `@objc`/`NSObject` class. Plain Swift methods
use static/witness-table dispatch and are invisible to the Obj-C runtime. See
[Swift in depth](guides/swift.html).

**What class name do I pass?**
The Objective-C runtime name: `@objc(MyName)` if you set one, otherwise the
mangled `_TtC<modlen><module><len><Class>`. Prefer setting `@objc(MyName)`.

**Can I bridge a Swift `enum` / `Optional<Int>` / tuple?**
Not directly. Expose an `@objc`-compatible surface (`NSInteger`, nullable
objects, the supported structs) at the patch boundary.

## Values & structs

**How do I find a struct field's offset?**
Mirror the C layout rules (each field aligned to its size). For `struct { int32
a; double b; }` the encoding is `{S=id}` with `a@0, b@8`. See
[Structs](guides/structs.html).

**My bitfield struct reads wrong.**
The `@encode` for a bitfield (`bN`) omits the storage type, so all-bitfield
struct size is inferred from total bits. It's correct when the bitfields fill
their storage unit; pad to a whole unit otherwise.

**Can I pass a bare `union` as an argument?**
Wrap it in a struct — bare top-level union arguments aren't bridged. Floating
point inside a union isn't classified correctly either.

## Blocks

**Can a patch call a completion handler it was given?**
Yes — `invoke_block`. Creating a block to pass *into* Obj-C is `create_block`.
See [Blocks](guides/blocks.html). The created block's callback must run *after*
`entry()` returns (the normal async flow).

## Runtime & threading

**Is there a "call original / super"?**
No — replacement swaps the implementation. Forward valid cases to a different
method, or capture what you need before patching.

**Can hooked methods be called from any thread?**
Yes; the bridge serializes access to the interpreter. Don't invoke a
patch-created block synchronously during `entry()` (it would re-enter the
runtime) — that's the async-callback caveat, not a general threading limit.

**How do I roll back a patch?**
`WAPPatchLoader.reset()` (or `wap_reset_runtime()`) restores original
implementations and frees patch resources — your runtime kill switch.

## Distribution

**Is this App-Store-safe?**
WasmPatch is sandboxed, signed, and reversible, but downloading executable code
is governed by App Store policy and enforcement evolves — that's a
product/legal decision, not a technical guarantee. Many teams use it in
enterprise/internal builds. See the [Security model](concepts/security.html).

## Still stuck?

Open an issue at
[github.com/everettjf/WasmPatch/issues]({{ site.github_repo }}/issues) with the
patch source, the log-handler output, and the error code.
