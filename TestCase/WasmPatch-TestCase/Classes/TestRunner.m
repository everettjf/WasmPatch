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
    
    ReplaceMe * rm = [[ReplaceMe alloc] init];
    [rm request];
    [rm requestFrom:@"He" to:@"She"];
}

@end
