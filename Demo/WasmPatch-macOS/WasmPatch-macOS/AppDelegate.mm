//
//  AppDelegate.m
//  WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#import "AppDelegate.h"
#import <WasmPatch-TestCase/TestRunner.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSString *testCaseBundlePath = [[NSBundle mainBundle] pathForResource:@"WasmPatch-TestCase" ofType:@"bundle"];
    NSString *scriptBundlePath = [testCaseBundlePath stringByAppendingPathComponent:@"Contents/Resources/script.bundle"];
    [TestRunner runTest:scriptBundlePath];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
