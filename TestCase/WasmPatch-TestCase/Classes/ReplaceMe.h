//
//  ReplaceMe.h
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplaceMe : NSObject

// struct bridging coverage
+ (CGRect)classBounds;              // replaced to return a known rect
- (int32_t)sumOfRect:(CGRect)rect;  // replaced; reads the struct argument

+ (void)request;
+ (void)requestFrom:(NSString*)from to:(NSString*)to;
+ (NSString *)classToken;
+ (int32_t)classMagicNumber;
+ (BOOL)classFeatureEnabled;
+ (double)classScore;
+ (const char *)classCString;

- (void)request;
- (void)requestFrom:(NSString*)from to:(NSString*)to;
- (NSString *)instanceToken;
- (int32_t)instanceMagicNumber;
- (BOOL)instanceFeatureEnabled;
- (double)instanceScore;
- (const char *)instanceCString;

@end

NS_ASSUME_NONNULL_END
