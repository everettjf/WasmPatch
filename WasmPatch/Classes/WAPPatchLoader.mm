#import "WAPPatchLoader.h"

#import "WasmPatch.h"
#import <Security/Security.h>

NSErrorDomain const WAPPatchLoaderErrorDomain = @"com.wasmpatch.loader";
NSString * const WAPPatchLoaderErrorSourceKey = @"WAPPatchLoaderErrorSource";
NSString * const WAPPatchLoaderRuntimeMessageKey = @"WAPPatchLoaderRuntimeMessage";

static WAPPatchLoaderErrorCode WAPPatchLoaderCodeForRuntimeMessage(NSString *message) {
    if ([message containsString:@"already loaded"]) {
        return WAPPatchLoaderErrorCodeAlreadyLoaded;
    }
    if ([message containsString:@"invalid wasm magic"]) {
        return WAPPatchLoaderErrorCodeInvalidWasm;
    }
    if ([message containsString:@"exceeds max_bytes"]) {
        return WAPPatchLoaderErrorCodePayloadTooLarge;
    }
    if ([message containsString:@"sha256 mismatch"]) {
        return WAPPatchLoaderErrorCodeSHA256Mismatch;
    }
    if ([message containsString:@"unable to read wasm file"]) {
        return WAPPatchLoaderErrorCodePatchNotFound;
    }
    return WAPPatchLoaderErrorCodeLoadFailed;
}

static NSError *WAPPatchLoaderMakeError(WAPPatchLoaderErrorCode code, NSString *description, NSString * _Nullable source, NSString * _Nullable runtimeMessage) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    if (source.length > 0) {
        userInfo[WAPPatchLoaderErrorSourceKey] = source;
    }
    if (runtimeMessage.length > 0) {
        userInfo[WAPPatchLoaderRuntimeMessageKey] = runtimeMessage;
    }
    return [NSError errorWithDomain:WAPPatchLoaderErrorDomain
                               code:code
                           userInfo:userInfo];
}

static BOOL WAPPatchLoaderAssignError(NSError * _Nullable * _Nullable error, WAPPatchLoaderErrorCode code, NSString *description, NSString * _Nullable source, NSString * _Nullable runtimeMessage) {
    if (error) {
        *error = WAPPatchLoaderMakeError(code, description, source, runtimeMessage);
    }
    return NO;
}

static NSString *WAPPatchLoaderLastRuntimeErrorMessage(void) {
    const char *message = wap_last_error();
    if (!message || message[0] == 0) {
        return @"WasmPatch runtime reported an unknown error";
    }
    return [NSString stringWithUTF8String:message] ?: @"WasmPatch runtime reported an unknown error";
}

static NSString *WAPPatchLoaderResolvedPatchName(NSString *name) {
    return [name.pathExtension.lowercaseString isEqualToString:@"wasm"] ? name.stringByDeletingPathExtension : name;
}

@implementation WAPPatchLoaderOptions

+ (instancetype)recommendedOptions {
    WAPPatchLoaderOptions *options = [[self alloc] init];
    WAPLoadOptions raw = wap_recommended_load_options();
    options.maxBytes = raw.max_bytes;
    options.allowReload = raw.allow_reload;
    options.resetBeforeLoad = raw.reset_before_load;
    options.strictHooks = raw.strict_hooks;
    return options;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        WAPLoadOptions raw = wap_recommended_load_options();
        _maxBytes = raw.max_bytes;
        _allowReload = raw.allow_reload;
        _resetBeforeLoad = raw.reset_before_load;
        _strictHooks = raw.strict_hooks;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WAPPatchLoaderOptions *copy = [[[self class] allocWithZone:zone] init];
    copy.maxBytes = self.maxBytes;
    copy.expectedSHA256Hex = self.expectedSHA256Hex;
    copy.allowReload = self.allowReload;
    copy.resetBeforeLoad = self.resetBeforeLoad;
    copy.strictHooks = self.strictHooks;
    copy.publicKeyECBase64 = self.publicKeyECBase64;
    copy.signatureBase64 = self.signatureBase64;
    return copy;
}

- (WAPLoadOptions)loadOptionsValue {
    WAPLoadOptions options;
    options.max_bytes = self.maxBytes;
    options.expected_sha256_hex = self.expectedSHA256Hex.length > 0 ? self.expectedSHA256Hex.UTF8String : NULL;
    options.allow_reload = self.allowReload;
    options.reset_before_load = self.resetBeforeLoad;
    options.strict_hooks = self.strictHooks;
    return options;
}

@end

@implementation WAPPatchLoader

// Verify the ECDSA-P256 signature over `data` when the options request it.
// Returns YES when no signature is configured (nothing to check) or when the
// signature is valid; NO with a populated error otherwise.
+ (BOOL)verifySignatureIfNeededForData:(NSData *)data
                               options:(WAPPatchLoaderOptions *)options
                                source:(NSString * _Nullable)source
                                 error:(NSError * _Nullable * _Nullable)error {
    if (options.publicKeyECBase64.length == 0 && options.signatureBase64.length == 0) {
        return YES; // signature checking not requested
    }
    if (options.publicKeyECBase64.length == 0 || options.signatureBase64.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeSignatureInvalid,
                                         @"Both publicKeyECBase64 and signatureBase64 are required to verify a patch.", source, nil);
    }

    NSData *keyData = [[NSData alloc] initWithBase64EncodedString:options.publicKeyECBase64 options:0];
    NSData *sigData = [[NSData alloc] initWithBase64EncodedString:options.signatureBase64 options:0];
    if (keyData.length == 0 || sigData.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeSignatureInvalid,
                                         @"Public key or signature is not valid base64.", source, nil);
    }

    NSDictionary *attrs = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPublic,
        (id)kSecAttrKeySizeInBits: @256,
    };
    CFErrorRef cfError = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)keyData, (__bridge CFDictionaryRef)attrs, &cfError);
    if (!key) {
        NSString *detail = cfError ? [(__bridge NSError *)cfError localizedDescription] : @"unknown";
        if (cfError) { CFRelease(cfError); }
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeSignatureInvalid,
                                         @"Could not parse the EC public key.", source, detail);
    }

    BOOL ok = SecKeyVerifySignature(key,
                                    kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
                                    (__bridge CFDataRef)data,
                                    (__bridge CFDataRef)sigData,
                                    &cfError);
    NSString *detail = cfError ? [(__bridge NSError *)cfError localizedDescription] : nil;
    if (cfError) { CFRelease(cfError); }
    CFRelease(key);

    if (!ok) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeSignatureInvalid,
                                         @"Patch signature verification failed.", source, detail ?: @"signature mismatch");
    }
    return YES;
}

+ (BOOL)loadPatchAtPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error {
    return [self loadPatchAtPath:path options:[self recommendedOptions] error:error];
}

+ (BOOL)loadPatchAtPath:(NSString *)path options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error {
    if (path.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Patch path can not be empty.", path, nil);
    }
    WAPPatchLoaderOptions *effectiveOptions = options ?: [self recommendedOptions];
    if (effectiveOptions.signatureBase64.length > 0 || effectiveOptions.publicKeyECBase64.length > 0) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data.length == 0) {
            return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodePatchNotFound,
                                             [NSString stringWithFormat:@"Could not read patch at path %@ for verification.", path], path, nil);
        }
        if (![self verifySignatureIfNeededForData:data options:effectiveOptions source:path error:error]) {
            return NO;
        }
    }
    if (wap_load_file_with_options(path.fileSystemRepresentation, effectiveOptions.loadOptionsValue)) {
        return YES;
    }
    NSString *runtimeMessage = WAPPatchLoaderLastRuntimeErrorMessage();
    NSString *description = [NSString stringWithFormat:@"Failed to load patch at path %@.", path];
    return WAPPatchLoaderAssignError(error, WAPPatchLoaderCodeForRuntimeMessage(runtimeMessage), description, path, runtimeMessage);
}

+ (BOOL)loadPatchAtPath:(NSString *)path sha256:(NSString * _Nullable)sha256 error:(NSError * _Nullable * _Nullable)error {
    if (path.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Patch path can not be empty.", path, nil);
    }

    WAPPatchLoaderOptions *options = [self recommendedOptions];
    options.expectedSHA256Hex = sha256;
    return [self loadPatchAtPath:path options:options error:error];
}

+ (BOOL)loadPatchData:(NSData *)data error:(NSError * _Nullable * _Nullable)error {
    return [self loadPatchData:data options:[self recommendedOptions] error:error];
}

+ (BOOL)loadPatchData:(NSData *)data options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error {
    if (data.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Patch data can not be empty.", @"memory", nil);
    }
    WAPPatchLoaderOptions *effectiveOptions = options ?: [self recommendedOptions];
    if (![self verifySignatureIfNeededForData:data options:effectiveOptions source:@"memory" error:error]) {
        return NO;
    }
    if (wap_load_data_with_options(data.bytes, (unsigned int)data.length, effectiveOptions.loadOptionsValue)) {
        return YES;
    }
    NSString *runtimeMessage = WAPPatchLoaderLastRuntimeErrorMessage();
    return WAPPatchLoaderAssignError(error, WAPPatchLoaderCodeForRuntimeMessage(runtimeMessage), @"Failed to load patch from memory.", @"memory", runtimeMessage);
}

+ (BOOL)loadPatchNamed:(NSString *)name inBundle:(NSBundle *)bundle error:(NSError * _Nullable * _Nullable)error {
    return [self loadPatchNamed:name inBundle:bundle options:[self recommendedOptions] error:error];
}

+ (BOOL)loadPatchNamed:(NSString *)name inBundle:(NSBundle *)bundle options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error {
    if (name.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Patch resource name can not be empty.", nil, nil);
    }
    if (!bundle) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Bundle can not be nil.", nil, nil);
    }

    NSString *resourceName = WAPPatchLoaderResolvedPatchName(name);
    NSString *path = [bundle pathForResource:resourceName ofType:@"wasm"];
    if (path.length == 0) {
        NSString *message = [NSString stringWithFormat:@"Patch resource %@.wasm was not found in bundle %@.", resourceName, bundle.bundlePath];
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodePatchNotFound, message, bundle.bundlePath, nil);
    }

    return [self loadPatchAtPath:path options:options error:error];
}

+ (WAPPatchLoaderOptions *)recommendedOptions {
    return [WAPPatchLoaderOptions recommendedOptions];
}

+ (BOOL)isLoaded {
    return wap_runtime_is_loaded();
}

+ (NSString * _Nullable)lastErrorMessage {
    const char *message = wap_last_error();
    if (!message || message[0] == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:message];
}

+ (void)reset {
    wap_reset_runtime();
}

static void (^gWAPLogBlock)(NSInteger, NSString *) = nil;

static void WAPPatchLoaderLogTrampoline(int level, const char *message) {
    void (^block)(NSInteger, NSString *) = gWAPLogBlock;
    if (!block) {
        return;
    }
    NSString *text = message ? [NSString stringWithUTF8String:message] : @"";
    block((NSInteger)level, text ?: @"");
}

+ (void)setLogHandler:(void (^ _Nullable)(NSInteger level, NSString *message))handler {
    gWAPLogBlock = [handler copy];
    wap_set_log_handler(handler ? WAPPatchLoaderLogTrampoline : NULL);
}

@end
