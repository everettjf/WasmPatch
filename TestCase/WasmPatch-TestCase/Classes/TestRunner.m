//
//  TestRunner.m
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import "TestRunner.h"
#import <WasmPatch/WasmPatch.h>
#import "ReplaceMe.h"

@implementation TestRunner

+ (void)runTest:(NSString*)scriptBundlePath {
    NSString *scriptPath = [scriptBundlePath stringByAppendingPathComponent:@"objc.wasm"];
    bool result = wap_load_file(scriptPath.UTF8String);
    if (!result) {
        NSLog(@"failed load file %@", scriptPath);
        return;
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
}

@end
