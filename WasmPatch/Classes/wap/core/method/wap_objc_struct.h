//
//  wap_objc_struct.h
//  WasmPatch
//
//  Bridges a small set of common by-value structs (CGPoint / CGSize / CGRect /
//  NSRange) between Objective-C and the wasm patch. Generic struct support is
//  still out of scope; these geometry types cover the overwhelming majority of
//  UIKit/AppKit method signatures.
//
//  A struct value crosses the bridge as a WAPInternalObject whose `value` is an
//  NSValue holding the raw struct bytes, tagged with one of the type strings
//  below. The patch side never sees the raw layout: it builds values with the
//  alloc_cg* exports and reads fields back with the cg*_get_* accessors.
//

#ifndef wap_objc_struct_h
#define wap_objc_struct_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <ffi.h>
#include <string.h>

namespace wap {

enum class StructKind {
    None,
    CGPointKind,
    CGSizeKind,
    CGRectKind,
    NSRangeKind,
};

// Internal type tags stored on WAPInternalObject for struct values.
static inline const char * StructTypeTag(StructKind kind) {
    switch (kind) {
        case StructKind::CGPointKind: return "cgpoint";
        case StructKind::CGSizeKind:  return "cgsize";
        case StructKind::CGRectKind:  return "cgrect";
        case StructKind::NSRangeKind: return "nsrange";
        default: return "";
    }
}

// Recognise the leading struct in an Objective-C type encoding.
// Examples: "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGPoint=dd}", "{_NSRange=QQ}".
static inline StructKind StructKindFromEncoding(const char *encoding) {
    if (!encoding) {
        return StructKind::None;
    }
    const char *c = encoding;
    if (c[0] == 'r') {
        c += 1; // skip const qualifier
    }
    if (c[0] != '{') {
        return StructKind::None;
    }
    if (strncmp(c, "{CGRect", 7) == 0) return StructKind::CGRectKind;
    if (strncmp(c, "{CGPoint", 8) == 0) return StructKind::CGPointKind;
    if (strncmp(c, "{CGSize", 7) == 0) return StructKind::CGSizeKind;
    // NSRange encodes as {_NSRange=...} on most runtimes.
    if (strncmp(c, "{_NSRange", 9) == 0 || strncmp(c, "{NSRange", 8) == 0) return StructKind::NSRangeKind;
    return StructKind::None;
}

static inline size_t StructByteSize(StructKind kind) {
    switch (kind) {
        case StructKind::CGPointKind: return sizeof(CGPoint);
        case StructKind::CGSizeKind:  return sizeof(CGSize);
        case StructKind::CGRectKind:  return sizeof(CGRect);
        case StructKind::NSRangeKind: return sizeof(NSRange);
        default: return 0;
    }
}

// Build the libffi descriptor for a struct kind. Returned pointers reference
// function-local statics with internal linkage; every consumer in a single
// translation unit shares the same instance, which is what libffi needs when
// the same descriptor is used for both arg and return types in one cif.
static inline ffi_type * StructFFIType(StructKind kind) {
    static ffi_type *point_elements[] = { &ffi_type_double, &ffi_type_double, NULL };
    static ffi_type point_type = { 0, 0, FFI_TYPE_STRUCT, point_elements };

    static ffi_type *size_elements[] = { &ffi_type_double, &ffi_type_double, NULL };
    static ffi_type size_type = { 0, 0, FFI_TYPE_STRUCT, size_elements };

    static ffi_type *rect_elements[] = { &ffi_type_double, &ffi_type_double, &ffi_type_double, &ffi_type_double, NULL };
    static ffi_type rect_type = { 0, 0, FFI_TYPE_STRUCT, rect_elements };

    static ffi_type *range_elements[] = { &ffi_type_uint64, &ffi_type_uint64, NULL };
    static ffi_type range_type = { 0, 0, FFI_TYPE_STRUCT, range_elements };

    switch (kind) {
        case StructKind::CGPointKind: return &point_type;
        case StructKind::CGSizeKind:  return &size_type;
        case StructKind::CGRectKind:  return &rect_type;
        case StructKind::NSRangeKind: return &range_type;
        default: return NULL;
    }
}

// Copy `bytes` (a live struct value) into an NSValue tagged with the struct
// encoding so it can round-trip back later.
static inline NSValue * StructWrapBytes(StructKind kind, const void *bytes) {
    switch (kind) {
        case StructKind::CGPointKind: return [NSValue valueWithBytes:bytes objCType:@encode(CGPoint)];
        case StructKind::CGSizeKind:  return [NSValue valueWithBytes:bytes objCType:@encode(CGSize)];
        case StructKind::CGRectKind:  return [NSValue valueWithBytes:bytes objCType:@encode(CGRect)];
        case StructKind::NSRangeKind: return [NSValue valueWithBytes:bytes objCType:@encode(NSRange)];
        default: return nil;
    }
}

// Unpack a previously wrapped NSValue into `outBytes`. Returns false if the
// value is missing or the wrong kind.
static inline bool StructUnwrapBytes(StructKind kind, id value, void *outBytes) {
    if (![value isKindOfClass:[NSValue class]] || !outBytes) {
        return false;
    }
    NSValue *boxed = (NSValue *)value;
    [boxed getValue:outBytes];
    return true;
}

}

#endif /* wap_objc_struct_h */
