//
//  wasmpatch.h
//  WasmPatch author SDK (canonical)
//
//  This is the header patch authors include from their C source. It declares
//  every runtime export the WasmPatch host provides, plus ergonomic macros
//  that remove the most common footguns:
//    - WAP_REPLACE_* derive the registered function name from the real C
//      symbol, so a misspelled name fails to compile instead of silently
//      failing at runtime.
//    - WAP_POOL_* provide scope-based cleanup so you stop hand-pairing every
//      alloc_* with dealloc_object.
//
//  The build tooling (Tool/build-patch.sh / Tool/c2wasm.sh) adds Tool/sdk to
//  the include path automatically, so `#include <wasmpatch.h>` just works.
//

#ifndef WASMPATCH_AUTHOR_SDK_H
#define WASMPATCH_AUTHOR_SDK_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Core types
// ---------------------------------------------------------------------------

typedef uint64_t WAPObject;
typedef uint64_t WAPArray;
typedef uint32_t WAPResultVoid;
typedef const char * WAPClassName;
typedef const char * WAPSelectorName;
typedef const char * WAPMethodName;

// ---------------------------------------------------------------------------
// Value allocation
// ---------------------------------------------------------------------------

extern WAPObject alloc_string(const char* v);
extern WAPObject alloc_double(double v);
extern WAPObject alloc_float(float v);
extern WAPObject alloc_int64(int64_t v);
extern WAPObject alloc_int32(int32_t v);
extern WAPObject alloc_objc_class(WAPClassName class_name);

extern WAPResultVoid print_object(WAPObject a);
extern WAPResultVoid print_string(const char *str);
extern WAPResultVoid dealloc_object(WAPObject a);

extern WAPArray alloc_array(void);
extern WAPResultVoid dealloc_array(WAPArray array);
extern WAPResultVoid append_array(WAPArray array, WAPObject object);
extern int get_array_size(WAPArray array);
extern WAPObject get_array_item(WAPArray array, int index);

// ---------------------------------------------------------------------------
// Geometry struct helpers (CGPoint / CGSize / CGRect)
//   Geometry values are bridged through NSValue under the hood. Construct them
//   with these helpers, pass them like any other WAPObject, and read fields
//   back from a returned value with the get_* accessors.
// ---------------------------------------------------------------------------

extern WAPObject alloc_cgpoint(double x, double y);
extern WAPObject alloc_cgsize(double width, double height);
extern WAPObject alloc_cgrect(double x, double y, double width, double height);

extern double cgpoint_get_x(WAPObject point);
extern double cgpoint_get_y(WAPObject point);
extern double cgsize_get_width(WAPObject size);
extern double cgsize_get_height(WAPObject size);
extern double cgrect_get_x(WAPObject rect);
extern double cgrect_get_y(WAPObject rect);
extern double cgrect_get_width(WAPObject rect);
extern double cgrect_get_height(WAPObject rect);

// ---------------------------------------------------------------------------
// Method calls
// ---------------------------------------------------------------------------

extern WAPObject call_class_method_param(WAPClassName class_name, WAPSelectorName selector_name, WAPObject params_addr);
extern WAPObject call_class_method_0(WAPClassName class_name, WAPSelectorName selector_name);
extern WAPObject call_class_method_1(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param);
extern WAPObject call_class_method_2(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1, WAPObject param2);
extern WAPObject call_class_method_3(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1, WAPObject param2, WAPObject param3);
extern WAPObject call_class_method_4(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1, WAPObject param2, WAPObject param3, WAPObject param4);

extern WAPObject call_instance_method_param(WAPObject instance, WAPSelectorName selector_name, WAPObject params_addr);
extern WAPObject call_instance_method_0(WAPObject instance, WAPSelectorName selector_name);
extern WAPObject call_instance_method_1(WAPObject instance, WAPSelectorName selector_name, WAPObject param1);
extern WAPObject call_instance_method_2(WAPObject instance, WAPSelectorName selector_name, WAPObject param1, WAPObject param2);
extern WAPObject call_instance_method_3(WAPObject instance, WAPSelectorName selector_name, WAPObject param1, WAPObject param2, WAPObject param3);
extern WAPObject call_instance_method_4(WAPObject instance, WAPSelectorName selector_name, WAPObject param1, WAPObject param2, WAPObject param3, WAPObject param4);

// ---------------------------------------------------------------------------
// Method replacement (low level)
// ---------------------------------------------------------------------------

extern WAPResultVoid replace_class_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name);
extern WAPResultVoid replace_instance_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name);

// ---------------------------------------------------------------------------
// Object helpers
// ---------------------------------------------------------------------------

extern WAPObject new_objc_nsstring(const char * str);
extern WAPObject new_objc_nsnumber_int(int value);

// ===========================================================================
// Ergonomic macros
// ===========================================================================

// --- Method replacement registration -------------------------------------
//
// Register a replacement by passing the *real* C function as the third
// argument. The macro stringizes the symbol for the runtime, so the name the
// runtime looks up can never drift from the function you actually defined.
// `sizeof(&(fn))` forces `fn` to be a declared symbol: a typo is now a compile
// error instead of a silent no-op at load time.
//
//   WAP_REPLACE_INSTANCE(ReplaceMe, "request", my_request_impl);
//   WAP_REPLACE_CLASS(ReplaceMe, "classToken", my_token_impl);
//
#define WAP_REPLACE_INSTANCE(cls, sel, fn) \
    ((void)sizeof(&(fn)), replace_instance_method(#cls, (sel), #fn))
#define WAP_REPLACE_CLASS(cls, sel, fn) \
    ((void)sizeof(&(fn)), replace_class_method(#cls, (sel), #fn))

// --- Scope-based cleanup ---------------------------------------------------
//
// Collect allocated WAPObjects in a pool and free them all at scope end, so
// you no longer have to pair every alloc_* with a matching dealloc_object.
//
//   WAP_POOL_BEGIN(pool);
//   WAPObject s = WAP_KEEP(pool, new_objc_nsstring("hi"));
//   call_class_method_1("CallMe", "sayWord:", s);
//   WAP_POOL_END(pool);   // frees s (and anything else kept)
//
#ifndef WAP_POOL_CAPACITY
#define WAP_POOL_CAPACITY 128
#endif

typedef struct WAPPool {
    WAPObject items[WAP_POOL_CAPACITY];
    int count;
} WAPPool;

static inline WAPObject wap_pool_keep(WAPPool *pool, WAPObject object) {
    if (pool && pool->count < WAP_POOL_CAPACITY) {
        pool->items[pool->count++] = object;
    }
    return object;
}

static inline void wap_pool_drain(WAPPool *pool) {
    if (!pool) {
        return;
    }
    for (int i = pool->count - 1; i >= 0; --i) {
        dealloc_object(pool->items[i]);
    }
    pool->count = 0;
}

#define WAP_POOL_BEGIN(name) WAPPool name = { {0}, 0 }
#define WAP_KEEP(name, object) wap_pool_keep(&(name), (object))
#define WAP_POOL_END(name) wap_pool_drain(&(name))

#ifdef __cplusplus
}
#endif

#endif /* WASMPATCH_AUTHOR_SDK_H */
