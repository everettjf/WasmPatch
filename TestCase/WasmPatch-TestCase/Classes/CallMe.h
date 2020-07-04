//
//  CallMe.h
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallMe : NSObject

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

// return value
- (NSString*)returnString;

@end

NS_ASSUME_NONNULL_END
