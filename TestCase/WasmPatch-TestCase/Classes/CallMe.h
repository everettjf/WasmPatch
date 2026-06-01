//
//  CallMe.h
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallMe : NSObject

// struct bridging coverage (called from the patch)
+ (CGRect)doubleRect:(CGRect)rect;                              // struct arg in, struct return out
+ (void)recordX:(double)x y:(double)y w:(double)w h:(double)h;  // 4-arg call (call_class_method_4)
+ (CGRect)recordedRect;                                         // host-side assertion hook

// class methods
+ (void)sayHi;
+ (void)sayWord:(NSString*)word;
+ (void)sayYou:(NSString*)you andMe:(NSString*)me;

// instance methods
- (void)sayHi;
- (void)sayWord:(NSString*)word;
- (void)sayYou:(NSString*)you andMe:(NSString*)me;

// many arguments
+ (void)callWithManyArguments:(int32_t)p0 p1:(int64_t)p1 p2:(float)p2 p3:(double)p3 p4:(NSString*)p4 p5:(const char*)p5;
+ (const char *)echoCString:(const char *)value;
+ (const char *)staticCString;

// return value
- (NSString*)returnString;

@end

NS_ASSUME_NONNULL_END
