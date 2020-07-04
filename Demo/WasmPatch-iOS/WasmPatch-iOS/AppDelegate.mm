//
//  AppDelegate.m
//  WasmPatch-iOS
//
//  Created by everettjf on 2020/4/6.
//  Copyright © 2020 everettjf. All rights reserved.
//

#import "AppDelegate.h"
#import <WasmPatch-TestCase/TestRunner.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *testCaseBundlePath = [[NSBundle mainBundle] pathForResource:@"WasmPatch-TestCase" ofType:@"bundle"];
    NSString *scriptBundlePath = [testCaseBundlePath stringByAppendingPathComponent:@"script.bundle"];
    [TestRunner runTest:scriptBundlePath];
    
    return YES;
}

@end
