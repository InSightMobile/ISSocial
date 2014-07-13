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

    if (userInfo) {
        [info setValuesForKeysWithDictionary:userInfo];
    }

    return [NSError errorWithDomain:ISSocailErrorDomain code:code userInfo:info];
}

+ (NSError *)errorWithError:(NSError *)error
{
    if(![error.domain isEqualToString:ISSocailErrorDomain]) {
        error = [ISSocial errorWithCode:ISSocialErrorUnknown sourseError:error userInfo:nil];
    }
    return error;
}
@end