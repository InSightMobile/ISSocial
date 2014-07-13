//
// 



#import "ISSocial.h"
#import "ISSocial+Errors.h"


@implementation ISSocial (Errors)



+ (NSError *)errorWithCode:(NSInteger)code sourseError:(NSError *)sourecError userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *info = [NSMutableDictionary new];

    if(sourecError) {
        info[NSUnderlyingErrorKey] = sourecError;
    }

    NSString *description = nil;
    switch (code) {
        case ISSocialErrorSystemLoginDisallowed:
        case ISSocialErrorAuthorizationFailed:
            description = @"Authorization failed";
            break;
        case ISSocialErrorUserCanceled:
            break;

    }
    if(description) {
        info[NSLocalizedDescriptionKey] = description;
    }

    if (userInfo) {
        [info setValuesForKeysWithDictionary:userInfo];
    }

    return [NSError errorWithDomain:ISSocialErrorDomain code:code userInfo:info];
}

+ (NSError *)errorWithError:(NSError *)error
{
    if(![error.domain isEqualToString:ISSocialErrorDomain]) {
        error = [ISSocial errorWithCode:ISSocialErrorUnknown sourseError:error userInfo:nil];
    }
    return error;
}
@end