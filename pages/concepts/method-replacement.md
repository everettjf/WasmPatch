---
title: "Method replacement internals"
eyebrow: "Core concepts"
description: "How replace_* swaps an implementation: type encodings, a libffi closure trampoline, and the IMP swap."
---

`replace_instance_method` / `replace_class_method` look trivial from the patch,
but underneath they build a tiny machine that turns any Objective-C call into a
wasm call. Here's the whole path.

## Step 1 — find the method

```objc
Class cls = isInstance ? objc_getClass(name) : objc_getMetaClass(name);
SEL sel  = sel_registerName(selector);
Method m = class_getInstanceMethod(cls, sel);   // metaclass for class methods
```

If the class or selector doesn't exist, the hook records a structured error.
With `strictHooks` enabled that fails the whole load (see
[Diagnostics](../guides/diagnostics.html)); otherwise it's logged and skipped.

## Step 2 — read the type encoding

```objc
const char *types = method_getTypeEncoding(m);  // e.g. "@16@0:8" or "i24@0:8{CGRect=...}16"
```

The encoding string describes the return type and every argument (including the
implicit `self` and `_cmd`). WasmPatch parses it into a list of types and maps
each to a libffi `ffi_type` — including [structs, unions and
bitfields](../guides/structs.html).

## Step 3 — build a libffi closure

A *closure* is a runtime-generated function pointer that, when called, invokes
your handler with the original arguments:

```objc
ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &fnPtr);
ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argc, returnType, argTypes);
ffi_prep_closure_loc(closure, &cif, generalBinding, hookContext, fnPtr);
```

`fnPtr` is now a real function with the method's exact signature. `cif` (the
call interface) tells libffi how arguments and the return value are laid out in
registers and memory — which is why correct `ffi_type`s, especially for
structs, matter.

## Step 4 — swap the implementation

```objc
IMP replacement = (IMP)fnPtr;
if (!class_addMethod(cls, sel, replacement, types))
    class_replaceMethod(cls, sel, replacement, types);
```

From now on every `objc_msgSend` to that selector lands in the trampoline. The
original `IMP` is kept so `reset` can restore it.

## Step 5 — the trampoline marshals and calls wasm

When the app calls the method, libffi hands the trampoline `self`, `_cmd`, and
the arguments. WasmPatch:

1. wraps `self`/`_cmd` and each argument into [`WAPObject`
   handles](type-bridging.html) (collected into a `WAPArray` when there are
   extra args);
2. calls the wasm export you named in `WAP_REPLACE_*`, passing the handles;
3. reads the wasm function's return value and writes it back into libffi's
   return slot, converting per the method's return encoding (object, scalar,
   C-string, struct, …).

```c
// Your replacement sees exactly this shape:
int my_send(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject url = get_array_item(args, 0);
    // ... inspect or replace behaviour ...
    return 0;
}
```

## Consequences worth knowing

- **The original implementation is replaced, not wrapped.** There's no implicit
  "call super / call original". If you need the old behaviour, capture what you
  need before patching, or call a *different* method from the patch.
- **Every call pays the bridge cost.** A hooked method does an ffi marshal plus
  a wasm interpreter call per invocation — fine for cold paths, not for tight
  inner loops. See [Performance](performance.html).
- **Return types must be bridgeable.** Scalars, objects, C-strings, selectors,
  and the supported [structs](../guides/structs.html) work. An unsupported
  return type is reported at load instead of corrupting the stack.
- **`reset` is clean.** It restores original `IMP`s and frees every closure, so
  you can hot-swap or roll back patches at runtime.
