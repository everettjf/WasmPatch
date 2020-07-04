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

@end

NS_ASSUME_NONNULL_END
