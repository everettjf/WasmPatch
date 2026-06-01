#import "WAPPatchManager.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString * const kWAPManagerErrorDomain = @"com.wasmpatch.manager";

typedef NS_ENUM(NSInteger, WAPManagerErrorCode) {
    WAPManagerErrorInvalidArgument = 1,
    WAPManagerErrorSHA256Mismatch = 2,
    WAPManagerErrorIO = 3,
    WAPManagerErrorNotFound = 4,
    WAPManagerErrorNetwork = 5,
};

static NSError *WAPManagerError(WAPManagerErrorCode code, NSString *message) {
    return [NSError errorWithDomain:kWAPManagerErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: message ?: @"unknown error" }];
}

@implementation WAPPatchManager

+ (WAPPatchManager *)sharedManager {
    static WAPPatchManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WAPPatchManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *base = dirs.firstObject ?: NSTemporaryDirectory();
        _cacheDirectory = [base stringByAppendingPathComponent:@"WasmPatch"];
    }
    return self;
}

+ (NSString *)sha256HexForData:(NSData *)data {
    if (!data) {
        return @"";
    }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [hex appendFormat:@"%02x", digest[i]];
    }
    return hex;
}

- (NSString *)cachedPathForName:(NSString *)name {
    NSString *file = [name.pathExtension.lowercaseString isEqualToString:@"wasm"] ? name : [name stringByAppendingPathExtension:@"wasm"];
    return [self.cacheDirectory stringByAppendingPathComponent:file];
}

- (BOOL)hasCachedPatchNamed:(NSString *)name {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self cachedPathForName:name]];
}

- (BOOL)ensureCacheDirectory:(NSError * _Nullable * _Nullable)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.cacheDirectory]) {
        return YES;
    }
    NSError *mkError = nil;
    if (![fm createDirectoryAtPath:self.cacheDirectory withIntermediateDirectories:YES attributes:nil error:&mkError]) {
        if (error) {
            *error = WAPManagerError(WAPManagerErrorIO, [NSString stringWithFormat:@"failed to create cache dir: %@", mkError.localizedDescription]);
        }
        return NO;
    }
    return YES;
}

- (NSString *)storePatchData:(NSData *)data
                       named:(NSString *)name
                      sha256:(NSString *)sha256Hex
                       error:(NSError * _Nullable * _Nullable)error {
    if (data.length == 0 || name.length == 0) {
        if (error) {
            *error = WAPManagerError(WAPManagerErrorInvalidArgument, @"data and name are required");
        }
        return nil;
    }

    if (sha256Hex.length > 0) {
        NSString *actual = [WAPPatchManager sha256HexForData:data];
        if (![actual isEqualToString:sha256Hex.lowercaseString]) {
            if (error) {
                *error = WAPManagerError(WAPManagerErrorSHA256Mismatch,
                                         [NSString stringWithFormat:@"sha256 mismatch (expected %@, got %@)", sha256Hex.lowercaseString, actual]);
            }
            return nil;
        }
    }

    if (![self ensureCacheDirectory:error]) {
        return nil;
    }

    NSString *path = [self cachedPathForName:name];
    NSError *writeError = nil;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
        if (error) {
            *error = WAPManagerError(WAPManagerErrorIO, [NSString stringWithFormat:@"failed to write patch: %@", writeError.localizedDescription]);
        }
        return nil;
    }
    return path;
}

- (void)fetchPatchFromURL:(NSURL *)url
                    named:(NSString *)name
                   sha256:(NSString *)sha256Hex
               completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    if (!url || name.length == 0) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, WAPManagerError(WAPManagerErrorInvalidArgument, @"url and name are required"));
            });
        }
        return;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *netError) {
        NSString *cachedPath = nil;
        NSError *resultError = nil;
        if (netError || data.length == 0) {
            resultError = WAPManagerError(WAPManagerErrorNetwork,
                                          netError.localizedDescription ?: @"empty response");
        } else {
            cachedPath = [self storePatchData:data named:name sha256:sha256Hex error:&resultError];
        }
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(cachedPath, resultError);
            });
        }
    }];
    [task resume];
}

- (BOOL)applyCachedPatchNamed:(NSString *)name
                      options:(WAPPatchLoaderOptions *)options
                        error:(NSError * _Nullable * _Nullable)error {
    NSString *path = [self cachedPathForName:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (error) {
            *error = WAPManagerError(WAPManagerErrorNotFound, [NSString stringWithFormat:@"no cached patch named %@", name]);
        }
        return NO;
    }
    WAPPatchLoaderOptions *effective = options ?: [WAPPatchLoader recommendedOptions];
    return [WAPPatchLoader loadPatchAtPath:path options:effective error:error];
}

- (BOOL)removeCachedPatchNamed:(NSString *)name error:(NSError * _Nullable * _Nullable)error {
    NSString *path = [self cachedPathForName:name];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        return YES;
    }
    NSError *rmError = nil;
    if (![fm removeItemAtPath:path error:&rmError]) {
        if (error) {
            *error = WAPManagerError(WAPManagerErrorIO, rmError.localizedDescription);
        }
        return NO;
    }
    return YES;
}

- (void)clearCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:self.cacheDirectory error:NULL];
}

@end
