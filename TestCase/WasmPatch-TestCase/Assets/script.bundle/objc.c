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
