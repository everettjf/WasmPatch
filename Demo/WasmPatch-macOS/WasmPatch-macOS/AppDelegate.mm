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
    NSString *autotest = NSProcessInfo.processInfo.environment[@"WASMPATCH_AUTOTEST"];
    if ([autotest isEqualToString:@"1"]) {
        NSString *message = nil;
        NSString *managerURL = NSProcessInfo.processInfo.environment[@"WASMPATCH_MANAGER_URL"];
        NSString *managerSHA = NSProcessInfo.processInfo.environment[@"WASMPATCH_MANAGER_SHA"];
        NSString *pubKey = NSProcessInfo.processInfo.environment[@"WASMPATCH_PUBKEY"];
        NSString *sig = NSProcessInfo.processInfo.environment[@"WASMPATCH_SIG"];
        BOOL ok;
        if (pubKey.length > 0) {
            ok = [TestRunner runSignedValidation:scriptBundlePath publicKey:pubKey signature:sig errorMessage:&message];
        } else if (managerURL.length > 0) {
            ok = [TestRunner runManagerValidationWithURL:managerURL sha256:managerSHA errorMessage:&message];
        } else {
            ok = [TestRunner runValidation:scriptBundlePath errorMessage:&message];
        }
        fprintf(stderr, "%s\n", ok ? "WASMPATCH_AUTOTEST_PASS" : "WASMPATCH_AUTOTEST_FAIL");
        if (!ok && message.length > 0) {
            fprintf(stderr, "%s\n", message.UTF8String);
        }
        fflush(stderr);
        exit(ok ? 0 : 1);
    }
    [TestRunner runTest:scriptBundlePath];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
