//
// 

#import "GooglePlus.h"

#import "GPSession.h"
#import "NSObject+PerformBlockInBackground.h"
#import "GTLPlusConstants.h"
#import "GTLServicePlus.h"
#import "GTMOAuth2Authentication.h"


@interface GPSession () <GPPSignInDelegate>
@property(nonatomic, strong) GPPSignIn *signIn;
@property(nonatomic, copy) GPSessionStateHandler handler;
@property(nonatomic, strong) GTMOAuth2Authentication *auth;
@property(nonatomic, readwrite) NSString *accessToken;
@property(nonatomic, readwrite) NSString *userID;
@end

@implementation GPSession {

}

+ (GPSession *)activeSession {
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

- (NSString *)idToken {
    return self.signIn.idToken;
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    if (error) {
        NSLog(@"error = %@", error);
        if (_handler)self.handler(self, GPSessionStateClosed, error);
        self.handler = nil;
        return;
    }
    self.auth = auth;
    if (_handler)self.handler(self, GPSessionStateOpen, error);
    self.handler = nil;

    self.accessToken = auth.accessToken;
    self.userID = auth.userID;


    // 1. Create a |GTLServicePlus| instance to send a request to Google+.
    GTLServicePlus *plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;

    // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
    [plusService setAuthorizer:auth];

    self.plusService = plusService;
}

- (BOOL)handleURL:(NSURL *)url
sourceApplication:(NSString *)sourceApplication
       annotation:(id)annotation {
    return [_signIn handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

+ (void)openActiveSessionWithClientID:(NSString *)appID permissions:(NSArray *)permissions completionHandler:(GPSessionStateHandler)handler {
    [[self activeSession] openSessionWithClientID:appID permissions:permissions completionHandler:handler];
}

- (void)openSessionWithClientID:(NSString *)clientId permissions:(NSArray *)permissions completionHandler:(GPSessionStateHandler)handler {
    NSArray *scopes = @[kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe];

    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = clientId;
    signIn.shouldFetchGoogleUserID = YES;
    signIn.scopes = scopes;
    signIn.delegate = self;
    self.handler = handler;
    self.signIn = signIn;

    if (![signIn trySilentAuthentication]) {
        [signIn authenticate];
    }
}

- (void)didActivated {
    if (self.handler) {
        [self iss_performBlock:^(id sender) {
            if (self.handler) {
                self.handler(self, GPSessionStateClosed, nil);
                self.handler = nil;
            }
        }           afterDelay:1.0];

    }
}


- (void)closeSession {
    [self.signIn signOut];
    self.signIn = nil;
}
@end


