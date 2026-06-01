//
//  TestRunner.h
//  Pods-WasmPatch-macOS
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestRunner : NSObject

+ (void)runTest:(NSString*)scriptBundlePath;
+ (BOOL)runValidation:(NSString*)scriptBundlePath errorMessage:(NSString * _Nullable * _Nullable)errorMessage;

/// End-to-end remote-delivery validation: download the patch from `url` via
/// WAPPatchManager, verify `sha256Hex`, cache it, apply it, then run the same
/// assertions as runValidation.
+ (BOOL)runManagerValidationWithURL:(NSString *)urlString
                             sha256:(nullable NSString *)sha256Hex
                       errorMessage:(NSString * _Nullable * _Nullable)errorMessage;

/// Load the bundled patch while verifying an EC P-256 signature, then run the
/// same assertions. Used to validate asymmetric patch signing (and, with a bad
/// signature, that loading is rejected).
+ (BOOL)runSignedValidation:(NSString *)scriptBundlePath
                  publicKey:(NSString *)publicKeyBase64
                  signature:(NSString *)signatureBase64
               errorMessage:(NSString * _Nullable * _Nullable)errorMessage;

@end

NS_ASSUME_NONNULL_END
