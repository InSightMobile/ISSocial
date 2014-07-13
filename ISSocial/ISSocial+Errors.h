//
// 



#import <Foundation/Foundation.h>
#import "ISSocial.h"

static NSString *const ISSocialErrorDomain = @"ISSocial";

typedef enum {

    ISSocialErrorUnknown,
    ISSocialErrorOperationNotAllowedByTarget,
    ISSocialErrorOperationAlreadyDone,
    ISSocialErrorSystemLoginDisallowed,
    ISSocialErrorSystemLoginAbsent,
    ISSocialErrorAuthorizationFailed,
    ISSocialErrorUserCanceled
} ISSocailErrorCodes;

@interface ISSocial (Errors)


+ (NSError *)errorWithCode:(NSInteger)code sourseError:(NSError *)sourecError userInfo:(NSDictionary *)userInfo;

+ (NSError *)errorWithError:(NSError *)error;
@end