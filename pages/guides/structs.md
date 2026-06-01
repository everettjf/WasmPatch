---
title: Structs
---

# Structs

[← Docs home](../index.md)

Structs are passed and returned **by value**. WasmPatch builds a libffi type
from the method's Objective-C encoding so the ABI is correct, and bridges the
value to the patch either as typed geometry helpers or as raw bytes you read by
offset.

## Geometry structs

`CGPoint` / `CGSize` / `CGRect` have dedicated constructors and accessors:

```c
WAPObject r = alloc_cgrect(0, 0, 320, 64);
double w = cgrect_get_width(r);   // 320
// also: alloc_cgpoint/alloc_cgsize and cgpoint_get_x/y, cgsize_get_width/height,
// cgrect_get_x/y/width/height
```

Example — replace `@objc dynamic func bounds() -> CGRect`:

```c
WAPObject my_bounds(WAPObject self, const char *cmd) {
    return alloc_cgrect(0, 0, 320, 64);
}
```

## Arbitrary structs

Any other struct bridges generically. Build one with `alloc_struct(encoding)`
and read/write fields by **byte offset** (you know your struct's layout):

```c
// struct Vec3 { float x, y, z; }  ->  "{Vec3=fff}", fields at 0/4/8
WAPObject v = alloc_struct("{Vec3=fff}");
struct_set_float(v, 0, 1.0f);
struct_set_float(v, 4, 2.0f);
struct_set_float(v, 8, 3.0f);

// reading an incoming struct argument:
int32_t a = struct_get_int32(incoming, 0);
double  b = struct_get_double(incoming, 8);
```

Accessors: `struct_get_int32/int64/float/double(obj, offset)` and the matching
`struct_set_*`.

To find a field's offset, mirror the C layout rules (each field is aligned to
its size). For `struct { int32_t a; double b; int64_t c; }` → `"{S=idq}"` →
`a@0, b@8, c@16` (size 24).

## Unions

A struct containing a union bridges too — read the union member at its offset:

```c
// struct { int32_t tag; union { int32_t i; float f; } value; }
//   -> "{Tagged=i(Num=if)}", tag@0, value@4
int my_read(WAPObject self, const char *cmd, WAPArray args) {
    WAPObject t = get_array_item(args, 0);
    int32_t tag = struct_get_int32(t, 0);
    int32_t i   = struct_get_int32(t, 4); // union's int interpretation
    return tag + i;
}
```

## Bitfields

Bitfields aren't byte-addressable — read/write bit runs from the struct start:

```c
// struct { uint32_t a:4; uint32_t b:4; uint32_t c:24; } -> "{Flags=b4b4b24}"
WAPObject f = alloc_struct("{Flags=b4b4b24}");
struct_set_bits(f, 0, 4, 1);     // a = 1   (bits 0-3)
struct_set_bits(f, 4, 4, 2);     // b = 2   (bits 4-7)
struct_set_bits(f, 8, 24, 300);  // c = 300 (bits 8-31)

int64_t a = struct_get_bits(incoming, 0, 4);
```

## Limitations

- A bitfield's **storage type isn't in `@encode`**, so an all-bitfield struct's
  size is inferred from its total bit count — correct when the bitfields fill
  their storage unit (the usual case). Pad to a whole unit otherwise.
- **Bare top-level union arguments** aren't bridged — wrap the union in a struct.
- **Floating-point members inside a union** aren't classified correctly.
- Generic structs are bridged as raw bytes; there are no typed field names, only
  offsets.
