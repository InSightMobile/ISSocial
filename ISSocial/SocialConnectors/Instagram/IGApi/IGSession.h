//
// 



#import <Foundation/Foundation.h>
#import "WebLoginController.h"


typedef enum
{
    IGSessionStateOpen,
    IGSessionStateClosedLoginFailed,
    IGSessionStateClosed

} IGSessionState;

@class IGSession;
@class AFHTTPClient;


typedef void (^IGSessionStateHandler)(IGSession *session,
        IGSessionState status,
        NSError *error);


@interface IGSession : NSObject <WebLoginControllerDelegate>


@property(nonatomic, readonly) AFHTTPClient *client;
@property(nonatomic, readonly, copy) NSString *accessToken;

- (NSString *)clientId;

+ (IGSession *)activeSession;

- (BOOL)handleURL:(NSURL *)url;

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(IGSessionStateHandler)handler;


@end