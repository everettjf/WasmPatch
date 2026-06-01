#ifndef WAPPatchManager_h
#define WAPPatchManager_h

#import <Foundation/Foundation.h>
#import "WAPPatchLoader.h"

NS_ASSUME_NONNULL_BEGIN

/// High-level remote-delivery helper: download a patch, verify its SHA-256,
/// cache it on disk, and apply it through WAPPatchLoader. Designed for the
/// "fetch on launch, apply if valid, roll back on failure" flow.
///
/// Note: the network path (fetchPatchFromURL:...) talks to a remote server and
/// is not exercised by the repo's offline validation. The verify/cache/apply
/// paths are pure-local and are covered.
@interface WAPPatchManager : NSObject

@property (class, readonly) WAPPatchManager *sharedManager;

/// Directory where downloaded patches are cached. Defaults to
/// <Application Support>/WasmPatch. Created lazily.
@property (nonatomic, copy) NSString *cacheDirectory;

/// Compute the lowercase hex SHA-256 of arbitrary data.
+ (NSString *)sha256HexForData:(NSData *)data;

/// Download a patch into the cache, verifying the SHA-256 first when provided.
/// The completion runs on the main queue. On success `cachedPath` points at the
/// stored `.wasm`; on failure it is nil and `error` is set.
- (void)fetchPatchFromURL:(NSURL *)url
                     named:(NSString *)name
                    sha256:(nullable NSString *)sha256Hex
                completion:(void (^)(NSString * _Nullable cachedPath, NSError * _Nullable error))completion
    NS_SWIFT_NAME(fetchPatch(from:named:sha256:completion:));

/// Store patch bytes into the cache after verifying the SHA-256 (when provided).
/// This is the offline core shared with the network path.
- (nullable NSString *)storePatchData:(NSData *)data
                                 named:(NSString *)name
                                sha256:(nullable NSString *)sha256Hex
                                 error:(NSError * _Nullable * _Nullable)error;

/// Apply a previously cached patch by name. Returns NO and sets `error` if the
/// patch is missing or the load is rejected (e.g. SHA mismatch / strict hooks).
- (BOOL)applyCachedPatchNamed:(NSString *)name
                      options:(nullable WAPPatchLoaderOptions *)options
                        error:(NSError * _Nullable * _Nullable)error
    NS_SWIFT_NAME(applyCachedPatch(named:options:));

/// YES if a cached patch with this name exists.
- (BOOL)hasCachedPatchNamed:(NSString *)name;

/// Absolute path of a cached patch (whether or not it exists).
- (NSString *)cachedPathForName:(NSString *)name;

/// Remove one cached patch / everything in the cache.
- (BOOL)removeCachedPatchNamed:(NSString *)name error:(NSError * _Nullable * _Nullable)error;
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END

#endif /* WAPPatchManager_h */
