//
// 



#import <Foundation/Foundation.h>
#import "ISSocial.h"

extern NSString *const ISSocialErrorDomain;

typedef NS_ENUM(NSInteger,ISSocailErrorCodes) {
    ISSocialErrorUnknown,
    ISSocialErrorNetwork,
    ISSocialErrorOperationNotAllowedByTarget,
    ISSocialErrorOperationAlreadyDone,
    ISSocialErrorSystemLoginDisallowed,
    ISSocialErrorSystemLoginAbsent,
    ISSocialErrorStoredLoginAbsent,
    ISSocialErrorAuthorizationFailed,
    ISSocialErrorUserCanceled,
    ISSocialErrorConnectorNotFound
} ;

@interface ISSocial (Errors)


+ (NSError *)errorWithCode:(ISSocailErrorCodes)code sourceError:(NSError *)sourceError userInfo:(NSDictionary *)userInfo;

+ (NSError *)errorWithError:(NSError *)error;
@end