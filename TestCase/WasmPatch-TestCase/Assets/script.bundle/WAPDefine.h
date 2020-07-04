
#include <stddef.h>
#include <stdint.h>

// basic function
typedef uint64_t WAPObject;
typedef uint64_t WAPArray;
typedef uint32_t WAPResultVoid;
typedef const char * WAPClassName;
typedef const char * WAPSelectorName;
typedef const char * WAPMethodName;

extern WAPObject alloc_string(const char* v);
extern WAPObject alloc_double(double v);
extern WAPObject alloc_float(float v);
extern WAPObject alloc_int64(int64_t v);
extern WAPObject alloc_int32(int32_t v);
extern WAPObject alloc_objc_class(WAPClassName class_name);

extern WAPResultVoid print_object(WAPObject a);
extern WAPResultVoid print_string(const char *str);
extern WAPResultVoid dealloc_object(WAPObject a);

extern WAPArray alloc_array();
extern WAPResultVoid dealloc_array(WAPArray array);
extern WAPResultVoid append_array(WAPArray array, WAPObject object);
extern int get_array_size(WAPArray array);
extern WAPObject get_array_item(WAPArray array, int index);

// method call
extern WAPObject call_class_method_param(WAPClassName class_name, WAPSelectorName selector_name, WAPObject params_addr);
extern WAPObject call_class_method_0(WAPClassName class_name, WAPSelectorName selector_name);
extern WAPObject call_class_method_1(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param);
extern WAPObject call_class_method_2(WAPClassName class_name, WAPSelectorName selector_name, WAPObject param1, WAPObject param2);

extern WAPObject call_instance_method_param(WAPObject instance, WAPSelectorName selector_name, WAPObject params_addr);
extern WAPObject call_instance_method_0(WAPObject instance, WAPSelectorName selector_name);
extern WAPObject call_instance_method_1(WAPObject instance, WAPSelectorName selector_name, WAPObject param1);
extern WAPObject call_instance_method_2(WAPObject instance, WAPSelectorName selector_name, WAPObject param1, WAPObject param2);

// method replace
extern WAPResultVoid replace_class_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name);
extern WAPResultVoid replace_instance_method(WAPClassName class_name, WAPSelectorName selector_name, WAPMethodName method_name);

// helper
extern WAPObject new_objc_nsstring(const char * str);
extern WAPObject new_objc_nsnumber_int(int value);
