//
//  ReplaceMe.m
//  WasmPatch-TestCase
//
//  Created by everettjf on 2020/4/6.
//

#import "ReplaceMe.h"

@implementation ReplaceMe

+ (void)request {
    NSLog(@"+ ReplaceMe request");
}

+ (void)requestFrom:(NSString*)from to:(NSString*)to {
    NSLog(@"+ ReplaceMe requestFrom:%@ to:%@",from,to);
}

- (void)request {
    NSLog(@"- ReplaceMe request");
}

- (void)requestFrom:(NSString*)from to:(NSString*)to {
    NSLog(@"- ReplaceMe requestFrom:%@ to:%@",from,to);
}

@end
