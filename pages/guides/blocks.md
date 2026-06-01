---
title: "Blocks & completion handlers"
eyebrow: "Writing patches"
description: "Invoke completion handlers you're handed, and create blocks to pass into Objective-C."
---

WasmPatch bridges Objective-C blocks in both directions: a patch can **invoke a
block it was handed**, and **create a block to pass into** an Objective-C
method.

## Invoking a received block

When you replace a method that takes a completion handler, the block arrives as
an argument you can call with `invoke_block`:

```c
// Replace `- (void)fetchWithCompletion:(void (^)(NSString *))completion`
int my_fetch(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject completion = get_array_item(args, 0); // the block argument
    WAPArray cbArgs = alloc_array();
    append_array(cbArgs, new_objc_nsstring("from-wasm"));
    invoke_block(completion, cbArgs);               // call it back
    dealloc_array(cbArgs);
    return 0;
}
```

`invoke_block(block, args)` reads the block's encoded signature and marshals
object / string / integer / floating-point / `BOOL` arguments. Its return value
is the block's result (`0` for `void`).

## Creating a block

To hand a completion handler **to** an Objective-C method, bind a wasm export to
a block with `create_block`:

```c
// The block body: receives the block's arguments as a WAPArray.
WAPObject on_done(WAPArray args) {
    WAPObject value = get_array_item(args, 0);
    call_class_method_1("Analytics", "track:", value);
    return 0; // non-void blocks return a WAPObject / scalar
}

int entry() {
    // "v@?@" == void(^)(id). The leading "@?" is the implicit block self.
    WAPObject block = create_block("on_done", "v@?@");
    call_class_method_1("DataLoader", "loadWithCompletion:", block);
    return 0;
}
```

Common signatures:

| Block type | Encoding |
|------------|----------|
| `void(^)(void)` | `v@?` |
| `void(^)(id)` / `void(^)(NSString *)` | `v@?@` |
| `void(^)(BOOL)` | `v@?B` |
| `void(^)(NSInteger)` | `v@?q` |

## Lifetime & threading

- The block's wasm callback runs when the host **later** invokes the block (the
  normal async-completion flow). Don't rely on invoking it synchronously while
  `entry()` is still on the stack — that would re-enter the wasm runtime.
- Created blocks are owned by the runtime and released on `reset`.

## Limitation

- Block arguments/returns are limited to the scalar/object/string types above;
  struct-by-value block parameters aren't bridged.
