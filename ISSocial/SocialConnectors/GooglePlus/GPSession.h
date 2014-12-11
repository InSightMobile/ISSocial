//
// 

#import <Foundation/Foundation.h>

typedef enum
{
    GPSessionStateOpen,
    GPSessionStateClosedLoginFailed,
    GPSessionStateClosed

} GPSessionState;

@class GPSession;
@class GPPSignIn;
@class GTMOAuth2Authentication;
@class GTLServicePlus;

typedef void (^GPSessionStateHandler)(GPSession *session,
        GPSessionState status,
        NSError *error);


@interface GPSession : NSObject


@property(nonatomic, copy) NSString *appId;

@property(nonatomic, strong) GTLServicePlus *plusService;

@property(nonatomic, readonly) NSString *accessToken;

@property(nonatomic, readonly) NSString *userID;

+ (GPSession *)activeSession;

- (NSString *)idToken;

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (void)didActivated;

+ (void)openActiveSessionWithClientID:(NSString *)appID permissions:(NSArray *)permissions completionHandler:(GPSessionStateHandler)handler;

- (void)closeSession;


@end