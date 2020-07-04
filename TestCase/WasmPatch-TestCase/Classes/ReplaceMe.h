//
//  ReplaceMe.h
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplaceMe : NSObject

+ (void)request;
+ (void)requestFrom:(NSString*)from to:(NSString*)to;

- (void)request;
- (void)requestFrom:(NSString*)from to:(NSString*)to;

@end

NS_ASSUME_NONNULL_END
