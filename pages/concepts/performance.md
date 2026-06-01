---
title: "Performance & footprint"
eyebrow: "Reference"
description: "What the interpreter and the bridge cost, where to use patches, and where not to."
---

WasmPatch trades raw speed for safety and portability. Knowing the cost model
tells you where it fits.

## Where the cost is

- **Loading** a patch: parse the `.wasm`, link host exports, run `entry()`. One
  time, milliseconds for typical patches. Signature verification adds one ECDSA
  check.
- **A hooked method, per call:** the call goes through a libffi trampoline →
  arguments are boxed into `WAPObject` handles → the wasm function runs in the
  **interpreter** → the result is unboxed. Every invocation pays this.
- **Calling Obj-C from the patch:** each `call_*` builds an `NSInvocation`,
  marshals arguments, and invokes. Reflection-based, not a direct `objc_msgSend`.

The interpreter (wasm3) is fast *as interpreters go*, but it is not JIT'd native
code, and the marshalling is real work.

## Rule of thumb

> **Patch cold paths, not hot loops.** WasmPatch shines for bug fixes, guarded
> early-returns, feature flips, and config-shaped logic on methods called tens
> or hundreds of times. Avoid hooking a method on a per-frame render path, a
> tight numeric loop, or something called millions of times.

If a hot method needs patching, hook a *coarser* method that runs once (e.g. a
setup/validation entry point) rather than the inner call.

## Footprint

- **Runtime:** wasm3 + libffi are small and statically linked; no JIT pages, no
  large runtime.
- **Patch payloads:** a focused patch is typically a few KB of `.wasm`
  (`-O3 -flto`). The toolchain prints the size on build.
- **Memory:** each created block / libffi closure and each live `WAPObject`
  costs a little host memory; pools and `reset` reclaim it.

## Measuring

- Build prints `sha256` and byte size.
- Use the [log handler](../guides/diagnostics.html) to time load and confirm
  which hooks installed.
- If you suspect a hooked method is hot, profile in Instruments — the trampoline
  frames are visible in the call tree.

## Practical guidance

- Prefer **one patch that registers several hooks** over many loads.
- Do expensive one-time work in `entry()`, not inside a frequently-called
  replacement.
- Keep replacement bodies small; offload heavy logic to the Obj-C side and call
  it, rather than computing in wasm.
- Roll back with `reset()` when a patch is no longer needed to drop the overhead
  entirely.
