//
//  ReplaceMe.m
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import "ReplaceMe.h"

@implementation ReplaceMe

+ (CGRect)classBounds {
    return CGRectZero; // replaced by the patch
}

- (int32_t)sumOfRect:(CGRect)rect {
    return -1; // replaced by the patch
}

+ (void)request {
    NSLog(@"+ ReplaceMe request");
}

+ (void)requestFrom:(NSString*)from to:(NSString*)to {
    NSLog(@"+ ReplaceMe requestFrom:%@ to:%@",from,to);
}

+ (NSString *)classToken {
    return @"native-class-token";
}

+ (int32_t)classMagicNumber {
    return 7;
}

+ (BOOL)classFeatureEnabled {
    return NO;
}

+ (double)classScore {
    return 1.25;
}

+ (const char *)classCString {
    return "native-class-c-string";
}

- (void)request {
    NSLog(@"- ReplaceMe request");
}

- (void)requestFrom:(NSString*)from to:(NSString*)to {
    NSLog(@"- ReplaceMe requestFrom:%@ to:%@",from,to);
}

- (NSString *)instanceToken {
    return @"native-instance-token";
}

- (int32_t)instanceMagicNumber {
    return 8;
}

- (BOOL)instanceFeatureEnabled {
    return NO;
}

- (double)instanceScore {
    return 2.5;
}

- (const char *)instanceCString {
    return "native-instance-c-string";
}

@end
