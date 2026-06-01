//
//  CallMe.m
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import "CallMe.h"

static CGRect gRecordedRect;

@implementation CallMe

// struct bridging coverage
+ (CGRect)doubleRect:(CGRect)rect {
    return CGRectMake(rect.origin.x * 2, rect.origin.y * 2, rect.size.width * 2, rect.size.height * 2);
}

+ (void)recordX:(double)x y:(double)y w:(double)w h:(double)h {
    gRecordedRect = CGRectMake(x, y, w, h);
    NSLog(@"+ CallMe recordX:%.2f y:%.2f w:%.2f h:%.2f", x, y, w, h);
}

+ (CGRect)recordedRect {
    return gRecordedRect;
}

// class methods
+ (void)sayHi {
    NSLog(@"+ %@ %@", NSStringFromClass(self), NSStringFromSelector(_cmd));
}
+ (void)sayWord:(NSString*)word {
    NSLog(@"+ %@ %@ word=%@", NSStringFromClass(self),NSStringFromSelector(_cmd), word);
}
+ (void)sayYou:(NSString*)you andMe:(NSString*)me {
    NSLog(@"+ %@ %@ you=%@,me=%@", NSStringFromClass(self),NSStringFromSelector(_cmd),you,me);
}

// instance methods
- (void)sayHi {
    NSLog(@"- %@ %@", NSStringFromClass(self.class),NSStringFromSelector(_cmd));
}
- (void)sayWord:(NSString*)word {
    NSLog(@"- %@ %@ word=%@", NSStringFromClass(self.class),NSStringFromSelector(_cmd), word);
}
- (void)sayYou:(NSString*)you andMe:(NSString*)me {
    NSLog(@"- %@ %@ you=%@,me=%@", NSStringFromClass(self.class),NSStringFromSelector(_cmd),you,me);
}

// many arguments
+ (void)callWithManyArguments:(int32_t)p0 p1:(int64_t)p1 p2:(float)p2 p3:(double)p3 p4:(NSString*)p4 p5:(const char*)p5 {
    NSLog(@"+ %@ %@ p0=%d, p1=%lld, p2=%f, p3=%lf, p4=%@, p5=%s",NSStringFromClass(self.class),NSStringFromSelector(_cmd),p0,p1,p2,p3,p4,p5);
}

+ (const char *)echoCString:(const char *)value {
    return value;
}

+ (const char *)staticCString {
    return "Hello from Objective-C";
}

// return value
- (NSString*)returnString {
    return @"Hello WebAssembly";
}

@end
