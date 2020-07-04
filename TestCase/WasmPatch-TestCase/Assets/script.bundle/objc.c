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

    replace_instance_method("ReplaceMe", "request", "my_instance_ReplaceMe_request");
    replace_instance_method("ReplaceMe", "requestFrom:to:", "my_instance_ReplaceMe_requestfromto");


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
