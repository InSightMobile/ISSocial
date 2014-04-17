//
// 

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

#import "GPSession.h"
#import "NSObject+PerformBlockInBackground.h"


@interface GPSession () <GPPSignInDelegate>
@property(nonatomic, strong) GPPSignIn *signIn;
@property(nonatomic, copy) GPSessionStateHandler handler;
@property(nonatomic, strong) GTMOAuth2Authentication *auth;
@end

@implementation GPSession
{

}

+ (GPSession *)activeSession
{
    static GPSession *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)didDisconnectWithError:(NSError *)error {


}


- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
    if (error) {
        NSLog(@"error = %@", error);
        if (_handler)self.handler(self, GPSessionStateClosed, error);
        self.handler = nil;
        return;
    }
    self.auth = auth;
    if (_handler)self.handler(self, GPSessionStateOpen, error);
    self.handler = nil;


    // 1. Create a |GTLServicePlus| instance to send a request to Google+.
    GTLServicePlus *plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;

    // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
    [plusService setAuthorizer:auth];

    self.plusService = plusService;
}

- (BOOL)handleURL:(NSURL *)url
sourceApplication:(NSString *)sourceApplication
       annotation:(id)annotation
{
    /*return [GPPURLHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];     */

    return [_signIn handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(GPSessionStateHandler)handler
{
    [[self activeSession] openSessionWithPermissions:permissions completionHandler:handler];
}

- (void)openSessionWithPermissions:(NSArray *)permissions completionHandler:(GPSessionStateHandler)handler
{
    NSString *clientAppId = NSBundle.mainBundle.infoDictionary[@"GooglePlusAppID"];

    self.appId = clientAppId;


    NSString *clientId = [NSString stringWithFormat:@"%@.apps.googleusercontent.com", clientAppId];

    NSArray *scopes = @[kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe];

    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = clientId;
    signIn.shouldFetchGoogleUserID = YES;
    signIn.scopes = scopes;
    signIn.delegate = self;
    //signIn.attemptSSO = NO;

    self.handler = handler;
    self.signIn = signIn;

    if(![signIn trySilentAuthentication]) {

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didActivated:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [signIn authenticate];
    }
}

- (void)didActivated:(NSNotification *)notification
{
    if(self.handler) {
        [self iss_performBlock:^(id sender) {
            if (self.handler) {
                self.handler(self, GPSessionStateClosed, nil);
                self.handler = nil;
            }
        }           afterDelay:1.0];

    }
}


@end


