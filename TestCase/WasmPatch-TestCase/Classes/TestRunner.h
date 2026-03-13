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

@end

NS_ASSUME_NONNULL_END
