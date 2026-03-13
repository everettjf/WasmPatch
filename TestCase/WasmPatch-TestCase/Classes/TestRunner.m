//
//  TestRunner.m
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import "TestRunner.h"
#import <WasmPatch/WasmPatch.h>
#import "ReplaceMe.h"
#include <math.h>

@implementation TestRunner

+ (void)runTest:(NSString*)scriptBundlePath {
    [self runValidation:scriptBundlePath errorMessage:nil];
}

+ (BOOL)runValidation:(NSString*)scriptBundlePath errorMessage:(NSString * _Nullable * _Nullable)errorMessage {
    NSString *scriptPath = [scriptBundlePath stringByAppendingPathComponent:@"objc.wasm"];
    bool result = wap_load_file(scriptPath.UTF8String);
    if (!result) {
        NSString *message = [NSString stringWithFormat:@"failed load file %@ error=%s", scriptPath, wap_last_error()];
        NSLog(@"%@", message);
        if (errorMessage) {
            *errorMessage = message;
        }
        return NO;
    }
    
    [ReplaceMe request];
    [ReplaceMe requestFrom:@"One" to:@"Two"];
    NSLog(@"+ ReplaceMe classToken => %@", [ReplaceMe classToken]);
    NSLog(@"+ ReplaceMe classMagicNumber => %d", [ReplaceMe classMagicNumber]);
    NSLog(@"+ ReplaceMe classFeatureEnabled => %@", [ReplaceMe classFeatureEnabled] ? @"YES" : @"NO");
    NSLog(@"+ ReplaceMe classScore => %.2f", [ReplaceMe classScore]);
    NSLog(@"+ ReplaceMe classCString => %s", [ReplaceMe classCString]);
    
    ReplaceMe * rm = [[ReplaceMe alloc] init];
    [rm request];
    [rm requestFrom:@"He" to:@"She"];
    NSLog(@"- ReplaceMe instanceToken => %@", [rm instanceToken]);
    NSLog(@"- ReplaceMe instanceMagicNumber => %d", [rm instanceMagicNumber]);
    NSLog(@"- ReplaceMe instanceFeatureEnabled => %@", [rm instanceFeatureEnabled] ? @"YES" : @"NO");
    NSLog(@"- ReplaceMe instanceScore => %.2f", [rm instanceScore]);
    NSLog(@"- ReplaceMe instanceCString => %s", [rm instanceCString]);

    BOOL passed = YES;
    NSMutableArray<NSString *> *failures = [NSMutableArray array];

#define WAP_ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            passed = NO; \
            [failures addObject:(message)]; \
        } \
    } while (0)

    WAP_ASSERT(wap_runtime_is_loaded(), @"runtime should be loaded");
    WAP_ASSERT([[ReplaceMe classToken] isEqualToString:@"replaced-class-token"], @"classToken mismatch");
    WAP_ASSERT([ReplaceMe classMagicNumber] == 42, @"classMagicNumber mismatch");
    WAP_ASSERT([ReplaceMe classFeatureEnabled] == YES, @"classFeatureEnabled mismatch");
    WAP_ASSERT(fabs([ReplaceMe classScore] - 9.5) < 0.001, @"classScore mismatch");
    WAP_ASSERT(strcmp([ReplaceMe classCString], "replaced-class-c-string") == 0, @"classCString mismatch");

    WAP_ASSERT([[rm instanceToken] isEqualToString:@"replaced-instance-token"], @"instanceToken mismatch");
    WAP_ASSERT([rm instanceMagicNumber] == 43, @"instanceMagicNumber mismatch");
    WAP_ASSERT([rm instanceFeatureEnabled] == YES, @"instanceFeatureEnabled mismatch");
    WAP_ASSERT(fabs([rm instanceScore] - 8.75) < 0.001, @"instanceScore mismatch");
    WAP_ASSERT(strcmp([rm instanceCString], "replaced-instance-c-string") == 0, @"instanceCString mismatch");

#undef WAP_ASSERT

    if (!passed) {
        NSString *message = [failures componentsJoinedByString:@"; "];
        NSLog(@"WasmPatch validation failed: %@", message);
        if (errorMessage) {
            *errorMessage = message;
        }
        return NO;
    }

    NSLog(@"WasmPatch validation passed");
    return YES;
}

@end
