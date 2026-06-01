---
title: "Comparison & trade-offs"
eyebrow: "Reference"
description: "How WasmPatch compares to JSPatch-style engines, native injection, and remote feature flags."
---

WasmPatch is one point in a design space of "change app behaviour without a new
binary." Here's where it sits.

## At a glance

| Approach | Language | Sandbox | Method replacement | ABI/struct fidelity | Portable |
|----------|----------|---------|--------------------|--------------------|----------|
| **WasmPatch** | C → wasm | ✅ interpreter | ✅ via libffi | ✅ (incl. structs/unions/bitfields) | ✅ arm64/x86_64 |
| JSPatch-style | JavaScript | ✅ JS engine | ✅ via swizzling | partial (dynamic typing) | ✅ |
| Native dylib / fishhook | C/ObjC native | ❌ full native | ✅ | ✅ | per-arch |
| Remote feature flags | config only | ✅ (data) | ❌ behaviour must be pre-built | n/a | ✅ |

## vs. JSPatch-style JS engines

The closest cousins. Both interpret a delivered payload and swizzle methods.
Differences:

- **Language & types.** WasmPatch patches are C, compiled and type-checked
  ahead of time; the `WAP_REPLACE_*` macros make a misspelled target a *compile
  error*. JS is dynamically typed — flexible, but type/argument mistakes surface
  at runtime.
- **ABI fidelity.** WasmPatch builds real libffi call interfaces, so by-value
  structs, unions, and bitfields marshal correctly. Dynamic-typing bridges tend
  to special-case these.
- **Surface.** Both expose a powerful bridge (call/replace any method), so both
  are privileged code that should be signed and reviewed.

## vs. native injection (dylib, fishhook, direct swizzling)

Native approaches are maximally capable and fastest — they *are* native code —
but that's also the downside: no sandbox, full process access, per-architecture
builds, and the highest review/security risk. WasmPatch deliberately gives up
raw speed and unrestricted access for a bounded, portable, reversible mechanism.
Use native injection when you need things the bridge can't express and you own
the security story; use WasmPatch when bounded + verifiable + portable matters.

## vs. remote feature flags

Feature flags are the safest option and should be your default for behaviour you
can anticipate — they ship only *data*, change no code. But they can only toggle
paths you already built and shipped. WasmPatch is for the things you *didn't*
anticipate: a crash you need to guard today, a calculation that's wrong in the
field, a method that needs new logic. Use flags for planned variation; reach for
a patch for unplanned fixes.

## When WasmPatch is the right tool

- You need to **fix or change logic that wasn't behind a flag**, now.
- You want the change **sandboxed, signed, reversible, and portable**.
- The patched paths are **not** performance-critical inner loops
  (see [Performance](performance.html)).

## When it isn't

- You can solve it with a feature flag → use the flag.
- You need to patch a hot path millions of times per second → rethink the hook
  point or use native code.
- Your distribution channel forbids downloaded code and you can't meet policy →
  see the note in the [Security model](security.html).
