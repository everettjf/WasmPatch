//
//  wap_objc_export_genericstruct.h
//  WasmPatch
//
//  Author API for arbitrary by-value structs. A patch builds a struct with
//  alloc_struct(encoding) and reads/writes its fields by byte offset (it knows
//  its own struct layout). Geometry structs keep their dedicated cg* helpers;
//  this is for everything else.
//

#ifndef wap_objc_export_genericstruct_h
#define wap_objc_export_genericstruct_h

#include "../wap_objc_define.h"
#include "../../method/wap_objc_struct.h"

// Allocate a zeroed struct value for the given Objective-C type encoding
// (e.g. "{Point3=ddd}"). Returns a WAPObject backed by mutable bytes.
WAPObject alloc_struct(const char *encoding) {
    if (!encoding) return 0;
    size_t size = wap::GenericEncodingSize(encoding);
    if (size == 0) {
        wap::EmitLog(wap::LogLevel::Error, std::string("alloc_struct: unknown size for encoding ") + encoding);
        return 0;
    }
    NSMutableData *data = [NSMutableData dataWithLength:size];
    return WAPCreateObjectFromObjcValue(wap::GenericStructTag(encoding), data);
}

__WAP_EXPORT_FUNCTION(alloc_struct_raw) {
    m3ApiReturnType (WAPObject)
    m3ApiGetArgMem (char*, encoding)
    WAPObject result = alloc_struct(encoding);
    m3ApiReturn (result)
}

// --- field readers --------------------------------------------------------

static const void * WAPStructReadPtr(WAPObject handle, int offset, size_t width) {
    if (handle == 0 || offset < 0) return nullptr;
    WAPInternalObject *obj = GetInternalObject(handle);
    if (!obj || ![obj->value isKindOfClass:[NSData class]]) return nullptr;
    NSData *data = (NSData *)obj->value;
    if ((size_t)offset + width > data.length) return nullptr;
    return (const uint8_t *)data.bytes + offset;
}

static void * WAPStructWritePtr(WAPObject handle, int offset, size_t width) {
    if (handle == 0 || offset < 0) return nullptr;
    WAPInternalObject *obj = GetInternalObject(handle);
    if (!obj || ![obj->value isKindOfClass:[NSMutableData class]]) return nullptr;
    NSMutableData *data = (NSMutableData *)obj->value;
    if ((size_t)offset + width > data.length) return nullptr;
    return (uint8_t *)data.mutableBytes + offset;
}

int32_t struct_get_int32(WAPObject h, int off)  { const void *p = WAPStructReadPtr(h, off, 4); int32_t v = 0; if (p) memcpy(&v, p, 4); return v; }
int64_t struct_get_int64(WAPObject h, int off)  { const void *p = WAPStructReadPtr(h, off, 8); int64_t v = 0; if (p) memcpy(&v, p, 8); return v; }
float   struct_get_float(WAPObject h, int off)  { const void *p = WAPStructReadPtr(h, off, 4); float v = 0;   if (p) memcpy(&v, p, 4); return v; }
double  struct_get_double(WAPObject h, int off) { const void *p = WAPStructReadPtr(h, off, 8); double v = 0;  if (p) memcpy(&v, p, 8); return v; }

WAPResultVoid struct_set_int32(WAPObject h, int off, int32_t v)  { void *p = WAPStructWritePtr(h, off, 4); if (p) memcpy(p, &v, 4); return 0; }
WAPResultVoid struct_set_int64(WAPObject h, int off, int64_t v)  { void *p = WAPStructWritePtr(h, off, 8); if (p) memcpy(p, &v, 8); return 0; }
WAPResultVoid struct_set_float(WAPObject h, int off, float v)    { void *p = WAPStructWritePtr(h, off, 4); if (p) memcpy(p, &v, 4); return 0; }
WAPResultVoid struct_set_double(WAPObject h, int off, double v)  { void *p = WAPStructWritePtr(h, off, 8); if (p) memcpy(p, &v, 8); return 0; }

__WAP_EXPORT_FUNCTION(struct_get_int32_raw)  { m3ApiReturnType(int32_t) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) int32_t r = struct_get_int32(h,o); m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_get_int64_raw)  { m3ApiReturnType(int64_t) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) int64_t r = struct_get_int64(h,o); m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_get_float_raw)  { m3ApiReturnType(float)   m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) float r = struct_get_float(h,o);   m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_get_double_raw) { m3ApiReturnType(double)  m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) double r = struct_get_double(h,o); m3ApiReturn(r) }

__WAP_EXPORT_FUNCTION(struct_set_int32_raw)  { m3ApiReturnType(WAPResultVoid) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) m3ApiGetArg(int32_t,v) WAPResultVoid r = struct_set_int32(h,o,v); m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_set_int64_raw)  { m3ApiReturnType(WAPResultVoid) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) m3ApiGetArg(int64_t,v) WAPResultVoid r = struct_set_int64(h,o,v); m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_set_float_raw)  { m3ApiReturnType(WAPResultVoid) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) m3ApiGetArg(float,v)   WAPResultVoid r = struct_set_float(h,o,v);   m3ApiReturn(r) }
__WAP_EXPORT_FUNCTION(struct_set_double_raw) { m3ApiReturnType(WAPResultVoid) m3ApiGetArg(WAPObject,h) m3ApiGetArg(int32_t,o) m3ApiGetArg(double,v)  WAPResultVoid r = struct_set_double(h,o,v); m3ApiReturn(r) }

#endif /* wap_objc_export_genericstruct_h */
