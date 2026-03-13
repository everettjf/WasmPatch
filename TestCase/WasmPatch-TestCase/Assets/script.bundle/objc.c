#include "WAPDefine.h"

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

int entry() {
    // method call - class method
    call_class_method_0("CallMe", "sayHi");
    
    WAPObject word = new_objc_nsstring("I am from c program");
    call_class_method_1("CallMe", "sayWord:", word);
    dealloc_object(word);

    WAPObject word1 = new_objc_nsstring("How are you today");
    WAPObject word2 = new_objc_nsstring("I am happy");
    call_class_method_2("CallMe", "sayYou:andMe:", word1, word2);
    dealloc_object(word1);
    dealloc_object(word2);

    // method call - instance method
    WAPObject call = alloc_objc_class("CallMe");
    call_instance_method_0(call,"sayHi");
    dealloc_object(call);

    WAPObject call1 = alloc_objc_class("CallMe");
    word = new_objc_nsstring("I am from c program");
    call_instance_method_1(call1,"sayWord:", word);
    dealloc_object(word);
    dealloc_object(call1);

    WAPObject call2 = alloc_objc_class("CallMe");
    word1 = new_objc_nsstring("How are you today");
    word2 = new_objc_nsstring("I am happy");
    call_instance_method_2(call2, "sayYou:andMe:", word1, word2);
    dealloc_object(word1);
    dealloc_object(word2);
    dealloc_object(call2);

    // method replace
    replace_class_method("ReplaceMe", "request", "my_class_ReplaceMe_request");
    replace_class_method("ReplaceMe", "requestFrom:to:", "my_class_ReplaceMe_requestfromto");
    replace_class_method("ReplaceMe", "classToken", "my_class_ReplaceMe_classtoken");
    replace_class_method("ReplaceMe", "classMagicNumber", "my_class_ReplaceMe_classmagicnumber");
    replace_class_method("ReplaceMe", "classFeatureEnabled", "my_class_ReplaceMe_classfeatureenabled");
    replace_class_method("ReplaceMe", "classScore", "my_class_ReplaceMe_classscore");
    replace_class_method("ReplaceMe", "classCString", "my_class_ReplaceMe_classcstring");

    replace_instance_method("ReplaceMe", "request", "my_instance_ReplaceMe_request");
    replace_instance_method("ReplaceMe", "requestFrom:to:", "my_instance_ReplaceMe_requestfromto");
    replace_instance_method("ReplaceMe", "instanceToken", "my_instance_ReplaceMe_instancetoken");
    replace_instance_method("ReplaceMe", "instanceMagicNumber", "my_instance_ReplaceMe_instancemagicnumber");
    replace_instance_method("ReplaceMe", "instanceFeatureEnabled", "my_instance_ReplaceMe_instancefeatureenabled");
    replace_instance_method("ReplaceMe", "instanceScore", "my_instance_ReplaceMe_instancescore");
    replace_instance_method("ReplaceMe", "instanceCString", "my_instance_ReplaceMe_instancecstring");


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
