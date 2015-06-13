//
// 



#import "ISSocial.h"
#import "ISSocial+Errors.h"

NSString *const ISSocialErrorDomain = @"ISSocialErrorDomain";

@implementation ISSocial (Errors)


+ (NSError *)errorWithCode:(ISSocailErrorCodes)code sourceError:(NSError *)sourceError userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *info = [NSMutableDictionary new];

    if (sourceError) {
        info[NSUnderlyingErrorKey] = sourceError;
    }

    NSString *description = nil;
    if (sourceError) {
        description = sourceError.localizedDescription;
    }
    switch (code) {
        case ISSocialErrorSystemLoginDisallowed:
        case ISSocialErrorAuthorizationFailed:
        case ISSocialErrorStoredLoginAbsent:
            description = @"Authorization failed";
            break;
        case ISSocialErrorUserCanceled:
            description = nil;
            break;
        default:
            break;
    }
    if (description) {
        info[NSLocalizedDescriptionKey] = description;
    }

    if (userInfo) {
        [info setValuesForKeysWithDictionary:userInfo];
    }

    return [NSError errorWithDomain:ISSocialErrorDomain code:code userInfo:info];
}

+ (NSError *)errorWithError:(NSError *)error {
    if (![error.domain isEqualToString:ISSocialErrorDomain]) {
        error = [ISSocial errorWithCode:ISSocialErrorUnknown sourceError:error userInfo:nil];
    }
    return error;
}
@end