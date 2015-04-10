//
// 



#import <Foundation/Foundation.h>
#import "ISSocial.h"

static NSString *const ISSocialErrorDomain = @"ISSocial";

typedef NS_ENUM(NSInteger,ISSocailErrorCodes) {

    ISSocialErrorUnknown,
    ISSocialErrorNetwork,
    ISSocialErrorOperationNotAllowedByTarget,
    ISSocialErrorOperationAlreadyDone,
    ISSocialErrorSystemLoginDisallowed,
    ISSocialErrorSystemLoginAbsent,
    ISSocialErrorAuthorizationFailed,
    ISSocialErrorUserCanceled
} ;

@interface ISSocial (Errors)


+ (NSError *)errorWithCode:(ISSocailErrorCodes)code sourseError:(NSError *)sourecError userInfo:(NSDictionary *)userInfo;

+ (NSError *)errorWithError:(NSError *)error;
@end