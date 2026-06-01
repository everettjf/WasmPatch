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
#include <string>
#include <vector>
#include <map>
#include <mutex>

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

// ===========================================================================
// Generic struct support (arbitrary by-value structs beyond the geometry set)
//
// Builds a libffi ffi_type from any Objective-C struct type encoding so structs
// pass/return by value correctly, and bridges the raw bytes to/from the patch
// as an NSData tagged "struct:<encoding>". The patch reads/writes fields by
// byte offset (it knows its own struct layout). Bitfields and unions are not
// supported.
// ===========================================================================

inline size_t GenericEncodingSize(const char *encoding); // defined below

// Map a single scalar encoding char to its ffi_type.
inline ffi_type * GenericScalarFFIType(char c) {
    switch (c) {
        case 'c': return &ffi_type_schar;
        case 'C': return &ffi_type_uchar;
        case 's': return &ffi_type_sshort;
        case 'S': return &ffi_type_ushort;
        case 'i': return &ffi_type_sint;
        case 'I': return &ffi_type_uint;
        case 'l': return &ffi_type_slong;
        case 'L': return &ffi_type_ulong;
        case 'q': return &ffi_type_sint64;
        case 'Q': return &ffi_type_uint64;
        case 'f': return &ffi_type_float;
        case 'd': return &ffi_type_double;
        case 'B': return &ffi_type_uint8;
        case '*': case '^': case '@': case '#': case ':': return &ffi_type_pointer;
        default: return nullptr;
    }
}

// Build an integer "blob" ffi_type of exactly `size` bytes with natural integer
// alignment. Used for unions and bitfield-containing structs, which are
// integer-classified aggregates on arm64/x86_64. Aggregates that mix
// floating-point members into a union/bitfield are NOT handled correctly and
// are documented as unsupported.
inline ffi_type * GenericBlobFFIType(size_t size) {
    if (size == 0) return nullptr;
    ffi_type *unit; size_t width;
    if (size % 8 == 0)      { unit = &ffi_type_uint64; width = 8; }
    else if (size % 4 == 0) { unit = &ffi_type_uint32; width = 4; }
    else if (size % 2 == 0) { unit = &ffi_type_uint16; width = 2; }
    else                    { unit = &ffi_type_uint8;  width = 1; }
    size_t count = size / width;
    ffi_type **elements = (ffi_type **)malloc(sizeof(ffi_type *) * (count + 1));
    for (size_t k = 0; k < count; ++k) elements[k] = unit;
    elements[count] = nullptr;
    ffi_type *t = (ffi_type *)malloc(sizeof(ffi_type));
    t->size = 0; t->alignment = 0; t->type = FFI_TYPE_STRUCT; t->elements = elements;
    return t;
}

// Extract a balanced {...}/(...)/[...] token at s[i], advancing i past it.
inline std::string GenericExtractBalanced(const std::string &s, size_t &i) {
    if (i >= s.size()) return std::string();
    size_t start = i;
    int depth = 0;
    for (; i < s.size(); ++i) {
        char c = s[i];
        if (c == '{' || c == '(' || c == '[') depth++;
        else if (c == '}' || c == ')' || c == ']') { depth--; if (depth == 0) { i++; break; } }
    }
    return s.substr(start, i - start);
}

inline ffi_type * GenericFFITypeForEncoding(const std::string &s, size_t &i);

// Build ffi_type for a complete aggregate token "{...}" (struct) or "(...)"
// (union).
inline ffi_type * GenericAggregateFFIType(const std::string &token) {
    if (token.size() < 2) return nullptr;

    // Unions become an integer blob of the union's size.
    if (token[0] == '(') {
        return GenericBlobFFIType(GenericEncodingSize(token.c_str()));
    }
    if (token[0] != '{') return nullptr;

    // Struct: parse members. A bitfield member (bN) can't be modelled per
    // member, so the whole struct is represented as an integer blob.
    size_t i = 1;
    while (i < token.size() && token[i] != '=' && token[i] != '}') i++;
    if (i < token.size() && token[i] == '=') i++;

    std::vector<ffi_type *> members;
    while (i < token.size() && token[i] != '}') {
        if (token[i] == '"') { // skip quoted field name
            i++;
            while (i < token.size() && token[i] != '"') i++;
            if (i < token.size()) i++;
            continue;
        }
        if (token[i] == 'b' && i + 1 < token.size() && isdigit((unsigned char)token[i + 1])) {
            return GenericBlobFFIType(GenericEncodingSize(token.c_str()));
        }
        ffi_type *m = GenericFFITypeForEncoding(token, i);
        if (!m) return nullptr;
        members.push_back(m);
    }

    ffi_type **elements = (ffi_type **)malloc(sizeof(ffi_type *) * (members.size() + 1));
    for (size_t k = 0; k < members.size(); ++k) elements[k] = members[k];
    elements[members.size()] = nullptr;
    ffi_type *t = (ffi_type *)malloc(sizeof(ffi_type));
    t->size = 0; t->alignment = 0; t->type = FFI_TYPE_STRUCT; t->elements = elements;
    return t;
}

// Parse one type token at s[i], advancing i. Handles qualifiers, scalars,
// pointers, nested structs/unions, fixed arrays and standalone bitfields.
inline ffi_type * GenericFFITypeForEncoding(const std::string &s, size_t &i) {
    while (i < s.size() && strchr("rnNoORV", s[i])) i++; // type qualifiers
    if (i >= s.size()) return nullptr;
    char c = s[i];
    if (c == '{' || c == '(') { std::string tok = GenericExtractBalanced(s, i); return GenericAggregateFFIType(tok); }
    if (c == '[') { // array: [count type] -> struct of `count` identical members
        i++;
        int count = 0;
        while (i < s.size() && isdigit((unsigned char)s[i])) { count = count * 10 + (s[i] - '0'); i++; }
        ffi_type *el = GenericFFITypeForEncoding(s, i);
        if (i < s.size() && s[i] == ']') i++;
        if (!el || count <= 0) return nullptr;
        ffi_type **elements = (ffi_type **)malloc(sizeof(ffi_type *) * (count + 1));
        for (int k = 0; k < count; ++k) elements[k] = el;
        elements[count] = nullptr;
        ffi_type *t = (ffi_type *)malloc(sizeof(ffi_type));
        t->size = 0; t->alignment = 0; t->type = FFI_TYPE_STRUCT; t->elements = elements;
        return t;
    }
    if (c == 'b') { // standalone bitfield is only meaningful inside a struct
        i++;
        while (i < s.size() && isdigit((unsigned char)s[i])) i++;
        return nullptr;
    }
    if (c == '^') { i++; size_t j = i; GenericFFITypeForEncoding(s, j); i = j; return &ffi_type_pointer; }
    if (c == '@') { i++; if (i < s.size() && s[i] == '"') { i++; while (i < s.size() && s[i] != '"') i++; if (i < s.size()) i++; } return &ffi_type_pointer; }
    ffi_type *scalar = GenericScalarFFIType(c);
    if (scalar) { i++; return scalar; }
    return nullptr;
}

// Public: ffi_type for a struct or union encoding, cached so the same encoding
// always yields the same pointer (libffi requirement within a cif).
inline ffi_type * GenericStructFFIType(const char *encoding) {
    if (!encoding) return nullptr;
    const char *c = encoding;
    if (c[0] == 'r') c++;
    if (c[0] != '{' && c[0] != '(') return nullptr;

    static std::mutex cacheMutex;
    static std::map<std::string, ffi_type *> cache;
    std::string key(c);
    std::lock_guard<std::mutex> lock(cacheMutex);
    auto it = cache.find(key);
    if (it != cache.end()) return it->second;

    size_t i = 0;
    std::string tok = GenericExtractBalanced(key, i);
    ffi_type *t = GenericAggregateFFIType(tok);
    cache[key] = t; // cache even nullptr to avoid rebuilding on failure
    return t;
}

// Tag stored on a generic struct's WAPInternalObject: "struct:<encoding>".
inline std::string GenericStructTag(const char *encoding) {
    return std::string("struct:") + (encoding ? encoding : "");
}

inline bool IsGenericStructTag(const std::string &type) {
    return type.rfind("struct:", 0) == 0;
}

inline std::string GenericStructEncodingFromTag(const std::string &type) {
    return IsGenericStructTag(type) ? type.substr(7) : std::string();
}

// Box raw struct bytes as NSData so they can round-trip through a WAPObject.
inline NSData * GenericWrapBytes(const void *bytes, size_t size) {
    if (!bytes || size == 0) return nil;
    return [NSData dataWithBytes:bytes length:size];
}

// Copy up to `size` bytes from a boxed NSData into `out`. Returns false unless
// `value` is an NSData of at least `size` bytes.
inline bool GenericUnwrapBytes(id value, void *out, size_t size) {
    if (![value isKindOfClass:[NSData class]] || !out) return false;
    NSData *data = (NSData *)value;
    if (data.length < size) return false;
    memcpy(out, data.bytes, size);
    return true;
}

// --- manual layout (used when NSGetSizeAndAlignment can't, i.e. bitfields) ---

inline void GenericScalarSizeAlign(char c, size_t &size, size_t &align) {
    switch (c) {
        case 'c': case 'C': case 'B': size = 1; align = 1; break;
        case 's': case 'S': size = 2; align = 2; break;
        case 'i': case 'I': case 'f': size = 4; align = 4; break;
        case 'q': case 'Q': case 'd': case 'l': case 'L': size = 8; align = 8; break;
        case '*': case '^': case '@': case '#': case ':': size = 8; align = 8; break;
        default: size = 0; align = 1; break;
    }
}

inline bool GenericTokenLayout(const std::string &token, size_t &outSize, size_t &outAlign);

// Layout of one member at s[i], advancing i. For a bitfield, sets bits>0.
inline void GenericNextMemberLayout(const std::string &s, size_t &i, size_t &size, size_t &align, int &bits) {
    size = 0; align = 1; bits = 0;
    while (i < s.size() && strchr("rnNoORV", s[i])) i++;
    if (i >= s.size()) return;
    char c = s[i];
    if (c == 'b') { i++; int w = 0; while (i < s.size() && isdigit((unsigned char)s[i])) { w = w * 10 + (s[i] - '0'); i++; } bits = w; return; }
    if (c == '{' || c == '(') { std::string tok = GenericExtractBalanced(s, i); GenericTokenLayout(tok, size, align); return; }
    if (c == '[') {
        i++; int n = 0; while (i < s.size() && isdigit((unsigned char)s[i])) { n = n * 10 + (s[i] - '0'); i++; }
        size_t es = 0, ea = 1; int eb = 0; GenericNextMemberLayout(s, i, es, ea, eb);
        if (i < s.size() && s[i] == ']') i++;
        size = es * (n > 0 ? n : 0); align = ea; return;
    }
    if (c == '^') { i++; size_t j = i; size_t s2; size_t a2; int b2; GenericNextMemberLayout(s, j, s2, a2, b2); i = j; size = 8; align = 8; return; }
    if (c == '@') { i++; if (i < s.size() && s[i] == '"') { i++; while (i < s.size() && s[i] != '"') i++; if (i < s.size()) i++; } size = 8; align = 8; return; }
    GenericScalarSizeAlign(c, size, align); i++;
}

// Compute size/alignment of a "{...}" struct or "(...)" union token, including
// bitfields. Bitfield storage type is not in the encoding, so an all-bitfield
// struct's alignment is inferred from its byte size — correct when the
// bitfields fill their storage unit (the common case).
inline bool GenericTokenLayout(const std::string &token, size_t &outSize, size_t &outAlign) {
    if (token.size() < 2) { outSize = 0; outAlign = 1; return false; }
    bool isUnion = token[0] == '(';
    size_t i = 1;
    while (i < token.size() && token[i] != '=' && token[i] != '}' && token[i] != ')') i++;
    if (i < token.size() && token[i] == '=') i++;

    size_t off = 0, maxAlign = 1; int pendingBits = 0;
    char close = isUnion ? ')' : '}';
    while (i < token.size() && token[i] != close) {
        if (token[i] == '"') { i++; while (i < token.size() && token[i] != '"') i++; if (i < token.size()) i++; continue; }
        size_t ms = 0, ma = 1; int mb = 0;
        GenericNextMemberLayout(token, i, ms, ma, mb);
        if (mb > 0) {
            pendingBits += mb;
        } else if (ms > 0) {
            if (isUnion) {
                if (ms > off) off = ms;            // union: largest member
            } else {
                if (pendingBits) { off += (size_t)((pendingBits + 7) / 8); pendingBits = 0; }
                off = (off + (ma - 1)) & ~(ma - 1); // align
                off += ms;
            }
            if (ma > maxAlign) maxAlign = ma;
        } else {
            break; // unparseable
        }
    }
    if (pendingBits) off += (size_t)((pendingBits + 7) / 8);
    if (maxAlign == 1 && off > 1) { // all-bitfield: infer alignment from size
        size_t p = 1; while (p < off && p < 8) p <<= 1; maxAlign = p;
    }
    outAlign = maxAlign;
    outSize = (off + (maxAlign - 1)) & ~(maxAlign - 1);
    return true;
}

// Size in bytes of an encoding. Uses the Objective-C runtime when possible and
// falls back to manual layout for bitfield-containing structs (which
// NSGetSizeAndAlignment rejects).
inline size_t GenericEncodingSize(const char *encoding) {
    if (!encoding) return 0;
    NSUInteger size = 0, align = 0;
    @try {
        NSGetSizeAndAlignment(encoding, &size, &align);
        return (size_t)size;
    } @catch (__unused id e) {
        // Likely a bitfield; compute manually.
        const char *c = encoding;
        if (c[0] == 'r') c++;
        std::string s(c);
        size_t i = 0;
        std::string tok = GenericExtractBalanced(s, i);
        size_t sz = 0, al = 1;
        if (tok.size() >= 2) GenericTokenLayout(tok, sz, al);
        return sz;
    }
}

}

#endif /* wap_objc_struct_h */
