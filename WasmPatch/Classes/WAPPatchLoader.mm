#import "WAPPatchLoader.h"

#import "WasmPatch.h"

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

+ (BOOL)loadPatchAtPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error {
    return [self loadPatchAtPath:path options:[self recommendedOptions] error:error];
}

+ (BOOL)loadPatchAtPath:(NSString *)path options:(WAPPatchLoaderOptions *)options error:(NSError * _Nullable * _Nullable)error {
    if (path.length == 0) {
        return WAPPatchLoaderAssignError(error, WAPPatchLoaderErrorCodeInvalidArgument, @"Patch path can not be empty.", path, nil);
    }
    WAPPatchLoaderOptions *effectiveOptions = options ?: [self recommendedOptions];
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
