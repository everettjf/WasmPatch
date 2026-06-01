//
//  ReplaceMe.h
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

// A non-geometry struct to exercise generic struct bridging.
typedef struct WAPTriple {
    int32_t a;
    double b;
    int64_t c;
} WAPTriple;

@interface ReplaceMe : NSObject

// struct bridging coverage
+ (CGRect)classBounds;              // replaced to return a known rect
- (int32_t)sumOfRect:(CGRect)rect;  // replaced; reads the struct argument

// generic (non-geometry) struct bridging
- (int64_t)sumTriple:(WAPTriple)triple;  // replaced; reads generic struct fields
+ (WAPTriple)buildTriple;                // replaced; builds a generic struct

// block bridging coverage: replaced; the patch invokes the completion handler
- (void)fetchWithCompletion:(void (^)(NSString *result))completion;

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
