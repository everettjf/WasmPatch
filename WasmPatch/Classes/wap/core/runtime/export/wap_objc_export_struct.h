//
//  wap_objc_export_struct.h
//  WasmPatch
//
//  Exports that let a patch construct and read the bridged geometry structs
//  (CGPoint / CGSize / CGRect). Values are stored as NSValue-backed
//  WAPInternalObjects tagged with the struct kind; the getters refuse to read a
//  value of the wrong kind so a mismatched accessor returns 0 instead of
//  reading past the stored bytes.
//

#ifndef wap_objc_export_struct_h
#define wap_objc_export_struct_h

#include "../wap_objc_define.h"
#include "../../method/wap_objc_struct.h"

static inline WAPObject WAPMakeStructObject(wap::StructKind kind, const void *bytes) {
    NSValue *boxed = wap::StructWrapBytes(kind, bytes);
    if (!boxed) {
        return 0;
    }
    return WAPCreateObjectFromObjcValue(wap::StructTypeTag(kind), boxed);
}

// Read a field out of a struct object, but only when the stored tag matches the
// kind the accessor expects.
static inline bool WAPReadStruct(WAPObject handle, wap::StructKind kind, void *outBytes) {
    if (handle == 0) {
        return false;
    }
    WAPInternalObject *obj = GetInternalObject(handle);
    if (!obj || obj->type != wap::StructTypeTag(kind)) {
        return false;
    }
    return wap::StructUnwrapBytes(kind, obj->value, outBytes);
}

WAPObject alloc_cgpoint(double x, double y) {
    CGPoint p = CGPointMake(x, y);
    return WAPMakeStructObject(wap::StructKind::CGPointKind, &p);
}

WAPObject alloc_cgsize(double width, double height) {
    CGSize s = CGSizeMake(width, height);
    return WAPMakeStructObject(wap::StructKind::CGSizeKind, &s);
}

WAPObject alloc_cgrect(double x, double y, double width, double height) {
    CGRect r = CGRectMake(x, y, width, height);
    return WAPMakeStructObject(wap::StructKind::CGRectKind, &r);
}

double cgpoint_get_x(WAPObject point) { CGPoint p = {0}; WAPReadStruct(point, wap::StructKind::CGPointKind, &p); return p.x; }
double cgpoint_get_y(WAPObject point) { CGPoint p = {0}; WAPReadStruct(point, wap::StructKind::CGPointKind, &p); return p.y; }
double cgsize_get_width(WAPObject size) { CGSize s = {0}; WAPReadStruct(size, wap::StructKind::CGSizeKind, &s); return s.width; }
double cgsize_get_height(WAPObject size) { CGSize s = {0}; WAPReadStruct(size, wap::StructKind::CGSizeKind, &s); return s.height; }
double cgrect_get_x(WAPObject rect) { CGRect r = {0}; WAPReadStruct(rect, wap::StructKind::CGRectKind, &r); return r.origin.x; }
double cgrect_get_y(WAPObject rect) { CGRect r = {0}; WAPReadStruct(rect, wap::StructKind::CGRectKind, &r); return r.origin.y; }
double cgrect_get_width(WAPObject rect) { CGRect r = {0}; WAPReadStruct(rect, wap::StructKind::CGRectKind, &r); return r.size.width; }
double cgrect_get_height(WAPObject rect) { CGRect r = {0}; WAPReadStruct(rect, wap::StructKind::CGRectKind, &r); return r.size.height; }

__WAP_EXPORT_FUNCTION(alloc_cgpoint_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg (double, x)
    m3ApiGetArg (double, y)
    WAPObject result = alloc_cgpoint(x, y);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_cgsize_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg (double, width)
    m3ApiGetArg (double, height)
    WAPObject result = alloc_cgsize(width, height);
    m3ApiReturn (result)
}

__WAP_EXPORT_FUNCTION(alloc_cgrect_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArg (double, x)
    m3ApiGetArg (double, y)
    m3ApiGetArg (double, width)
    m3ApiGetArg (double, height)
    WAPObject result = alloc_cgrect(x, y, width, height);
    m3ApiReturn (result)
}

#define WAP_DEFINE_STRUCT_GETTER_RAW(fn) \
__WAP_EXPORT_FUNCTION(fn##_raw) { \
    m3ApiReturnType (double) \
    m3ApiGetArg (WAPObject, handle) \
    double result = fn(handle); \
    m3ApiReturn (result) \
}

WAP_DEFINE_STRUCT_GETTER_RAW(cgpoint_get_x)
WAP_DEFINE_STRUCT_GETTER_RAW(cgpoint_get_y)
WAP_DEFINE_STRUCT_GETTER_RAW(cgsize_get_width)
WAP_DEFINE_STRUCT_GETTER_RAW(cgsize_get_height)
WAP_DEFINE_STRUCT_GETTER_RAW(cgrect_get_x)
WAP_DEFINE_STRUCT_GETTER_RAW(cgrect_get_y)
WAP_DEFINE_STRUCT_GETTER_RAW(cgrect_get_width)
WAP_DEFINE_STRUCT_GETTER_RAW(cgrect_get_height)

#endif /* wap_objc_export_struct_h */
