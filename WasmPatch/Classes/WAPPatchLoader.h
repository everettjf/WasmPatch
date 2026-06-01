#ifndef WAPPatchLoader_h
#define WAPPatchLoader_h

#import "WasmPatch.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const WAPPatchLoaderErrorDomain;
FOUNDATION_EXPORT NSString * const WAPPatchLoaderErrorSourceKey;
FOUNDATION_EXPORT NSString * const WAPPatchLoaderRuntimeMessageKey;

typedef NS_ERROR_ENUM(WAPPatchLoaderErrorDomain, WAPPatchLoaderErrorCode) {
    WAPPatchLoaderErrorCodeInvalidArgument = 1,
    WAPPatchLoaderErrorCodePatchNotFound = 2,
    WAPPatchLoaderErrorCodeAlreadyLoaded = 3,
    WAPPatchLoaderErrorCodeInvalidWasm = 4,
    WAPPatchLoaderErrorCodePayloadTooLarge = 5,
    WAPPatchLoaderErrorCodeSHA256Mismatch = 6,
    WAPPatchLoaderErrorCodeLoadFailed = 7,
};

@interface WAPPatchLoaderOptions : NSObject <NSCopying>

@property (nonatomic, assign) uint64_t maxBytes;
@property (nonatomic, copy, nullable) NSString *expectedSHA256Hex;
@property (nonatomic, assign) BOOL allowReload;
@property (nonatomic, assign) BOOL resetBeforeLoad;
/// When YES, loading fails if any replace_* call references a missing class or
/// selector, instead of silently leaving the method unpatched.
@property (nonatomic, assign) BOOL strictHooks;

+ (instancetype)recommendedOptions;
- (WAPLoadOptions)loadOptionsValue;

@end

@interface WAPPatchLoader : NSObject

+ (BOOL)loadPatchAtPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchAtPath:(NSString *)path sha256:(NSString * _Nullable)sha256 error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchAtPath:(NSString *)path options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchData:(NSData *)data options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchNamed:(NSString *)name inBundle:(NSBundle *)bundle error:(NSError * _Nullable * _Nullable)error;
+ (BOOL)loadPatchNamed:(NSString *)name inBundle:(NSBundle *)bundle options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error;
+ (WAPPatchLoaderOptions *)recommendedOptions;
+ (BOOL)isLoaded;
+ (NSString * _Nullable)lastErrorMessage;
+ (void)reset;

/// Route WasmPatch runtime diagnostics to a block. Levels: 0 = info, 1 = warning,
/// 2 = error. Pass nil to restore the default (NSLog) sink.
+ (void)setLogHandler:(void (^ _Nullable)(NSInteger level, NSString *message))handler;

@end

NS_ASSUME_NONNULL_END

#endif /* WAPPatchLoader_h */
