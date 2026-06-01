#include <wasmpatch.h>

// ---------------------------------------------------------------------------
// Replacement implementations
// ---------------------------------------------------------------------------

int my_class_ReplaceMe_request(WAPObject self, const char * cmd) {
    print_string("replaced + ReplaceMe request");
    return 0;
}

int my_class_ReplaceMe_requestfromto(WAPObject self, const char * cmd, WAPArray parameters) {
    print_string("replaced + ReplaceMe requestFrom:Two to:One");
    return 0;
}
int my_instance_ReplaceMe_request(WAPObject self, const char * cmd) {
    print_string("replaced - ReplaceMe request");
    return 0;
}

int my_instance_ReplaceMe_requestfromto(WAPObject self, const char * cmd, WAPArray parameters) {
    print_string("replaced - ReplaceMe requestFrom:Two to:One");
    return 0;
}

WAPObject my_class_ReplaceMe_classtoken(WAPObject self, const char * cmd) {
    return new_objc_nsstring("replaced-class-token");
}

int my_class_ReplaceMe_classmagicnumber(WAPObject self, const char * cmd) {
    return 42;
}

int my_class_ReplaceMe_classfeatureenabled(WAPObject self, const char * cmd) {
    return 1;
}

double my_class_ReplaceMe_classscore(WAPObject self, const char * cmd) {
    return 9.5;
}

WAPObject my_class_ReplaceMe_classcstring(WAPObject self, const char * cmd) {
    return alloc_string("replaced-class-c-string");
}

WAPObject my_instance_ReplaceMe_instancetoken(WAPObject self, const char * cmd) {
    return new_objc_nsstring("replaced-instance-token");
}

int my_instance_ReplaceMe_instancemagicnumber(WAPObject self, const char * cmd) {
    return 43;
}

int my_instance_ReplaceMe_instancefeatureenabled(WAPObject self, const char * cmd) {
    return 1;
}

double my_instance_ReplaceMe_instancescore(WAPObject self, const char * cmd) {
    return 8.75;
}

WAPObject my_instance_ReplaceMe_instancecstring(WAPObject self, const char * cmd) {
    return alloc_string("replaced-instance-c-string");
}

// struct return: hand back a known CGRect
WAPObject my_class_ReplaceMe_classbounds(WAPObject self, const char * cmd) {
    return alloc_cgrect(1.0, 2.0, 3.0, 4.0);
}

// struct argument: read the CGRect passed in and return the field sum
int my_instance_ReplaceMe_sumofrect(WAPObject self, const char * cmd, WAPArray args) {
    WAPObject rect = get_array_item(args, 0);
    double sum = cgrect_get_x(rect) + cgrect_get_y(rect) + cgrect_get_width(rect) + cgrect_get_height(rect);
    return (int)sum;
}

// block argument: invoke the completion handler the method was given
int my_instance_ReplaceMe_fetch(WAPObject self, const char * cmd, WAPArray args) {
    WAPObject completion = get_array_item(args, 0);
    WAPArray callbackArgs = alloc_array();
    append_array(callbackArgs, new_objc_nsstring("from-wasm-block"));
    invoke_block(completion, callbackArgs);
    dealloc_array(callbackArgs);
    return 0;
}

// wasm-created block body: invoked by the host with one NSString argument;
// forwards it back into Objective-C so the host can observe it ran.
WAPObject my_created_block(WAPArray args) {
    WAPObject value = get_array_item(args, 0);
    call_class_method_1("CallMe", "recordBlockResult:", value);
    return 0;
}

// Generic struct WAPTriple { int32_t a; double b; int64_t c; }
// Layout: a @ offset 0, b @ offset 8, c @ offset 16 (size 24).
#define WAP_TRIPLE_ENCODING "{WAPTriple=idq}"

// generic struct argument: read fields by offset and return their sum
int64_t my_instance_ReplaceMe_sumtriple(WAPObject self, const char * cmd, WAPArray args) {
    WAPObject t = get_array_item(args, 0);
    int32_t a = struct_get_int32(t, 0);
    double  b = struct_get_double(t, 8);
    int64_t c = struct_get_int64(t, 16);
    return (int64_t)a + (int64_t)b + c;
}

// generic struct return: build a WAPTriple and hand it back by value
WAPObject my_class_ReplaceMe_buildtriple(WAPObject self, const char * cmd) {
    WAPObject t = alloc_struct(WAP_TRIPLE_ENCODING);
    struct_set_int32(t, 0, 7);
    struct_set_double(t, 8, 2.5);
    struct_set_int64(t, 16, 100);
    return t;
}

// Bitfield struct WAPFlags { a:4; b:4; c:24; } -> "{WAPFlags=b4b4b24}"
#define WAP_FLAGS_ENCODING "{WAPFlags=b4b4b24}"

// bitfield argument: read each bitfield run and combine
int my_instance_ReplaceMe_readflags(WAPObject self, const char * cmd, WAPArray args) {
    WAPObject f = get_array_item(args, 0);
    int64_t a = struct_get_bits(f, 0, 4);   // bits 0-3
    int64_t b = struct_get_bits(f, 4, 4);   // bits 4-7
    int64_t c = struct_get_bits(f, 8, 24);  // bits 8-31
    return (int)(a + b + c);
}

// bitfield return: build a WAPFlags by writing bit runs
WAPObject my_class_ReplaceMe_buildflags(WAPObject self, const char * cmd) {
    WAPObject f = alloc_struct(WAP_FLAGS_ENCODING);
    struct_set_bits(f, 0, 4, 1);    // a = 1
    struct_set_bits(f, 4, 4, 2);    // b = 2
    struct_set_bits(f, 8, 24, 300); // c = 300
    return f;
}

// union-in-struct argument: WAPTagged { int32 tag; union{int32 i; float f;} value; }
// tag @ offset 0, union @ offset 4.
int my_instance_ReplaceMe_readtagged(WAPObject self, const char * cmd, WAPArray args) {
    WAPObject t = get_array_item(args, 0);
    int32_t tag = struct_get_int32(t, 0);
    int32_t value_i = struct_get_int32(t, 4); // union's int interpretation
    return tag + value_i;
}

int entry() {
    // method call - class method
    call_class_method_0("CallMe", "sayHi");

    // WAP_POOL: collect allocations and free them all at scope end instead of
    // pairing each alloc with a manual dealloc_object.
    {
        WAP_POOL_BEGIN(pool);
        WAPObject word = WAP_KEEP(pool, new_objc_nsstring("I am from c program"));
        call_class_method_1("CallMe", "sayWord:", word);

        WAPObject word1 = WAP_KEEP(pool, new_objc_nsstring("How are you today"));
        WAPObject word2 = WAP_KEEP(pool, new_objc_nsstring("I am happy"));
        call_class_method_2("CallMe", "sayYou:andMe:", word1, word2);
        WAP_POOL_END(pool);
    }

    // method call - instance method
    WAPObject call = alloc_objc_class("CallMe");
    call_instance_method_0(call,"sayHi");
    dealloc_object(call);

    // method replace via the WAP_REPLACE_* macros: the registered name is
    // derived from the real C symbol, so a typo fails to compile.
    WAP_REPLACE_CLASS(ReplaceMe, "request", my_class_ReplaceMe_request);
    WAP_REPLACE_CLASS(ReplaceMe, "requestFrom:to:", my_class_ReplaceMe_requestfromto);
    WAP_REPLACE_CLASS(ReplaceMe, "classToken", my_class_ReplaceMe_classtoken);
    WAP_REPLACE_CLASS(ReplaceMe, "classMagicNumber", my_class_ReplaceMe_classmagicnumber);
    WAP_REPLACE_CLASS(ReplaceMe, "classFeatureEnabled", my_class_ReplaceMe_classfeatureenabled);
    WAP_REPLACE_CLASS(ReplaceMe, "classScore", my_class_ReplaceMe_classscore);
    WAP_REPLACE_CLASS(ReplaceMe, "classCString", my_class_ReplaceMe_classcstring);
    WAP_REPLACE_CLASS(ReplaceMe, "classBounds", my_class_ReplaceMe_classbounds);

    WAP_REPLACE_INSTANCE(ReplaceMe, "request", my_instance_ReplaceMe_request);
    WAP_REPLACE_INSTANCE(ReplaceMe, "requestFrom:to:", my_instance_ReplaceMe_requestfromto);
    WAP_REPLACE_INSTANCE(ReplaceMe, "instanceToken", my_instance_ReplaceMe_instancetoken);
    WAP_REPLACE_INSTANCE(ReplaceMe, "instanceMagicNumber", my_instance_ReplaceMe_instancemagicnumber);
    WAP_REPLACE_INSTANCE(ReplaceMe, "instanceFeatureEnabled", my_instance_ReplaceMe_instancefeatureenabled);
    WAP_REPLACE_INSTANCE(ReplaceMe, "instanceScore", my_instance_ReplaceMe_instancescore);
    WAP_REPLACE_INSTANCE(ReplaceMe, "instanceCString", my_instance_ReplaceMe_instancecstring);
    WAP_REPLACE_INSTANCE(ReplaceMe, "sumOfRect:", my_instance_ReplaceMe_sumofrect);
    WAP_REPLACE_INSTANCE(ReplaceMe, "fetchWithCompletion:", my_instance_ReplaceMe_fetch);
    WAP_REPLACE_INSTANCE(ReplaceMe, "sumTriple:", my_instance_ReplaceMe_sumtriple);
    WAP_REPLACE_CLASS(ReplaceMe, "buildTriple", my_class_ReplaceMe_buildtriple);
    WAP_REPLACE_INSTANCE(ReplaceMe, "readFlags:", my_instance_ReplaceMe_readflags);
    WAP_REPLACE_CLASS(ReplaceMe, "buildFlags", my_class_ReplaceMe_buildflags);
    WAP_REPLACE_INSTANCE(ReplaceMe, "readTagged:", my_instance_ReplaceMe_readtagged);

    // struct round-trip: build a CGRect, send it through an Obj-C method that
    // returns a CGRect, then forward the doubled fields back via a 4-arg call.
    {
        WAPObject rect = alloc_cgrect(1.0, 2.0, 3.0, 4.0);
        WAPObject doubled = call_class_method_1("CallMe", "doubleRect:", rect);
        call_class_method_4("CallMe", "recordX:y:w:h:",
                            alloc_double(cgrect_get_x(doubled)),
                            alloc_double(cgrect_get_y(doubled)),
                            alloc_double(cgrect_get_width(doubled)),
                            alloc_double(cgrect_get_height(doubled)));
        dealloc_object(rect);
        dealloc_object(doubled);
    }

    // wasm-created block: hand a completion handler (implemented in wasm) to an
    // Obj-C method. The host fires it later; see TestRunner.
    {
        WAPObject block = create_block("my_created_block", "v@?@"); // void(^)(NSString *)
        call_class_method_1("CallMe", "registerCompletion:", block);
    }

    // other
    print_string("hello matrix");

    WAPObject str = new_objc_nsstring("good");
    WAPObject str1 = new_objc_nsstring(" morning");
    print_object(str);
    print_object(str1);
    dealloc_object(str);
    dealloc_object(str1);

    WAPObject num1 = new_objc_nsnumber_int(1);
    print_object(num1);
    dealloc_object(num1);

    // many arguments
    WAPArray params = alloc_array();
    append_array(params, alloc_int32(10));
    append_array(params, alloc_int64(666));
    append_array(params, alloc_float(7.77));
    append_array(params, alloc_double(200.2222));
    append_array(params, new_objc_nsstring("excellent"));
    append_array(params, alloc_string("WebAssembly"));
    call_class_method_param("CallMe", "callWithManyArguments:p1:p2:p3:p4:p5:", params);
    dealloc_array(params);

    // const char * parameter and return value
    WAPObject cstring = alloc_string("hello-c-string");
    WAPObject echoResult = call_class_method_1("CallMe", "echoCString:", cstring);
    print_object(echoResult);
    dealloc_object(echoResult);
    dealloc_object(cstring);

    WAPObject staticCString = call_class_method_0("CallMe", "staticCString");
    print_object(staticCString);
    dealloc_object(staticCString);

    // result
    WAPObject c = alloc_objc_class("CallMe");
    c = call_instance_method_0(c, "init");
    print_object(c);
    WAPObject result = call_instance_method_0(c, "returnString");
    print_object(result);
    dealloc_object(result);
    dealloc_object(c);

    return 0;
}
