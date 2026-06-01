//
//  TestRunner.m
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import "TestRunner.h"
#import <WasmPatch/WAPPatchLoader.h>
#import <WasmPatch/WAPPatchManager.h>
#import "ReplaceMe.h"
#import "CallMe.h"
#include <math.h>

@implementation TestRunner

+ (void)runTest:(NSString*)scriptBundlePath {
    [self runValidation:scriptBundlePath errorMessage:nil];
}

+ (BOOL)runValidation:(NSString*)scriptBundlePath errorMessage:(NSString * _Nullable * _Nullable)errorMessage {
    NSString *scriptPath = [scriptBundlePath stringByAppendingPathComponent:@"objc.wasm"];
    WAPPatchLoaderOptions *options = [WAPPatchLoader recommendedOptions];
    NSError *loadError = nil;
    bool result = [WAPPatchLoader loadPatchAtPath:scriptPath options:options error:&loadError];
    if (!result) {
        NSString *message = [NSString stringWithFormat:@"failed load file %@ error=%@", scriptPath, loadError.localizedDescription ?: @"unknown"];
        NSLog(@"%@", message);
        if (errorMessage) {
            *errorMessage = message;
        }
        return NO;
    }

    return [self runAssertionsWithError:errorMessage];
}

+ (BOOL)runManagerValidationWithURL:(NSString *)urlString
                             sha256:(NSString *)sha256Hex
                       errorMessage:(NSString * _Nullable * _Nullable)errorMessage {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (errorMessage) { *errorMessage = [NSString stringWithFormat:@"invalid url: %@", urlString]; }
        return NO;
    }

    __block NSString *cachedPath = nil;
    __block NSError *fetchError = nil;
    __block BOOL done = NO;
    NSLog(@"manager: fetching patch from %@", url);
    [[WAPPatchManager sharedManager] fetchPatchFromURL:url
                                                 named:@"remote-validation"
                                                sha256:sha256Hex
                                            completion:^(NSString *path, NSError *error) {
        cachedPath = path;
        fetchError = error;
        done = YES;
    }];

    // Drive the main run loop until the (main-queue) completion fires.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:30];
    while (!done && [deadline timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }

    if (!done || !cachedPath) {
        NSString *message = [NSString stringWithFormat:@"manager fetch failed: %@", fetchError.localizedDescription ?: @"timeout"];
        NSLog(@"%@", message);
        if (errorMessage) { *errorMessage = message; }
        return NO;
    }
    NSLog(@"manager: cached at %@", cachedPath);

    WAPPatchLoaderOptions *options = [WAPPatchLoader recommendedOptions];
    options.allowReload = YES;
    options.resetBeforeLoad = YES;
    NSError *applyError = nil;
    if (![[WAPPatchManager sharedManager] applyCachedPatchNamed:@"remote-validation" options:options error:&applyError]) {
        NSString *message = [NSString stringWithFormat:@"manager apply failed: %@", applyError.localizedDescription ?: @"unknown"];
        NSLog(@"%@", message);
        if (errorMessage) { *errorMessage = message; }
        return NO;
    }
    NSLog(@"manager: applied cached patch");

    return [self runAssertionsWithError:errorMessage];
}

+ (BOOL)runSignedValidation:(NSString *)scriptBundlePath
                  publicKey:(NSString *)publicKeyBase64
                  signature:(NSString *)signatureBase64
               errorMessage:(NSString * _Nullable * _Nullable)errorMessage {
    NSString *scriptPath = [scriptBundlePath stringByAppendingPathComponent:@"objc.wasm"];
    WAPPatchLoaderOptions *options = [WAPPatchLoader recommendedOptions];
    options.publicKeyECBase64 = publicKeyBase64;
    options.signatureBase64 = signatureBase64;

    NSError *loadError = nil;
    if (![WAPPatchLoader loadPatchAtPath:scriptPath options:options error:&loadError]) {
        NSString *message = [NSString stringWithFormat:@"signed load failed (code=%ld): %@",
                             (long)loadError.code, loadError.localizedDescription ?: @"unknown"];
        NSLog(@"%@", message);
        if (errorMessage) { *errorMessage = message; }
        return NO;
    }
    NSLog(@"signed load: signature verified, patch applied");
    return [self runAssertionsWithError:errorMessage];
}

+ (BOOL)runAssertionsWithError:(NSString * _Nullable * _Nullable)errorMessage {
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

    WAP_ASSERT([WAPPatchLoader isLoaded], @"runtime should be loaded");
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

    // struct return from a replaced method
    CGRect bounds = [ReplaceMe classBounds];
    NSLog(@"+ ReplaceMe classBounds => {%.1f, %.1f, %.1f, %.1f}", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    WAP_ASSERT(CGRectEqualToRect(bounds, CGRectMake(1, 2, 3, 4)), @"classBounds struct return mismatch");

    // struct argument into a replaced method (10+20+30+40 = 100)
    int32_t rectSum = [rm sumOfRect:CGRectMake(10, 20, 30, 40)];
    NSLog(@"- ReplaceMe sumOfRect => %d", rectSum);
    WAP_ASSERT(rectSum == 100, @"sumOfRect struct argument mismatch");

    // struct round-trip through a normal call: doubleRect(1,2,3,4) -> (2,4,6,8)
    CGRect recorded = [CallMe recordedRect];
    NSLog(@"+ CallMe recordedRect => {%.1f, %.1f, %.1f, %.1f}", recorded.origin.x, recorded.origin.y, recorded.size.width, recorded.size.height);
    WAP_ASSERT(CGRectEqualToRect(recorded, CGRectMake(2, 4, 6, 8)), @"struct call round-trip mismatch");

    // block bridging: the patched method should invoke our completion handler
    __block NSString *blockResult = nil;
    [rm fetchWithCompletion:^(NSString *result) {
        blockResult = result;
    }];
    NSLog(@"- ReplaceMe fetchWithCompletion => %@", blockResult);
    WAP_ASSERT([blockResult isEqualToString:@"from-wasm-block"], @"completion block bridging mismatch");

    // wasm-created block: the patch handed CallMe a block; fire it and confirm
    // the wasm body ran with our argument and called back into Objective-C.
    [CallMe fireRegisteredCompletionWith:@"created-in-wasm"];
    NSLog(@"+ CallMe recordedBlockResult => %@", [CallMe recordedBlockResult]);
    WAP_ASSERT([[CallMe recordedBlockResult] isEqualToString:@"created-in-wasm"], @"wasm-created block mismatch");

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
