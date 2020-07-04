//
//  CallMe.m
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import "CallMe.h"

@implementation CallMe

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

// return value
- (NSString*)returnString {
    return @"Hello WebAssembly";
}

@end
