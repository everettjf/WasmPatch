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

// A struct with bitfields (4 bytes): a@bits0-3, b@bits4-7, c@bits8-31.
typedef struct WAPFlags {
    uint32_t a : 4;
    uint32_t b : 4;
    uint32_t c : 24;
} WAPFlags;

// A union and a struct that contains it (8 bytes): tag@0, value@4.
typedef union WAPNum {
    int32_t i;
    float f;
} WAPNum;

typedef struct WAPTagged {
    int32_t tag;
    WAPNum value;
} WAPTagged;

@interface ReplaceMe : NSObject

// struct bridging coverage
+ (CGRect)classBounds;              // replaced to return a known rect
- (int32_t)sumOfRect:(CGRect)rect;  // replaced; reads the struct argument

// generic (non-geometry) struct bridging
- (int64_t)sumTriple:(WAPTriple)triple;  // replaced; reads generic struct fields
+ (WAPTriple)buildTriple;                // replaced; builds a generic struct

// bitfield + union bridging
- (int32_t)readFlags:(WAPFlags)flags;    // replaced; reads bitfields
+ (WAPFlags)buildFlags;                  // replaced; builds a bitfield struct
- (int32_t)readTagged:(WAPTagged)tagged; // replaced; reads a struct with a union member

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
