//
//

#import <ISSocial/SObject.h>
#import <ISSocial/ISSocial+Errors.h>
#import "SUserData.h"
#import "ISSAuthorisationInfo.h"
#import "GoogleConnector.h"
#import "GIDSignIn.h"
#import "GIDGoogleUser.h"
#import "GIDAuthentication.h"
#import "GIDProfileData.h"
#import "MultiImage.h"
#import "ISSocial.h"

@interface GoogleConnector () <GIDSignInDelegate, GIDSignInUIDelegate>

@property(nonatomic, strong) GIDSignIn *signIn;
@property(nonatomic, copy) SObjectCompletionBlock openSession;
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) GPSession *session;
@property(nonatomic, strong) NSString *clientID;
@property(nonatomic, strong) NSArray *permissions;
@property(nonatomic, strong) SocialConnectorOperation *signInOperation;
@end

@implementation GoogleConnector {
    SUserData *_currentUserData;
    ISSAuthorisationInfo *_authorizationInfo;
    UIViewController *_lastDisplayController;
}

+ (GoogleConnector *)instance {
    static GoogleConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (NSString *)connectorCode {
    return ISSocialConnectorIdGoogle;
}

- (void)setupSettings:(NSDictionary *)settings {
    [super setupSettings:settings];

    self.clientID = settings[ISSClientIDKey];
    self.permissions = settings[ISSPermissionsKey];
}

- (GIDSignIn *)signIn {
    if (_signIn) {
        return _signIn;
    }
    _signIn = [GIDSignIn sharedInstance];
    _signIn.delegate = self;
    _signIn.uiDelegate = self;
    _signIn.clientID = self.clientID;
    return _signIn;
}

- (BOOL)handleDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return NO;
}


- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        _currentUserData = nil;
        //[[GPSession activeSession] closeSession];
        [operation completed];
    }];
}

- (ISSAuthorisationInfo *)authorizationInfo {
    return _authorizationInfo;
}

- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    id <ISSocialUIDelegate> o = [ISSocial defaultInstance].uiDelegate;
    if ([o respondsToSelector:@selector(socialConnectorWillDispatch:error:)]) {
        [o socialConnectorWillDispatch:self error:error];
    }
}

- (UIViewController *)displayController {
    UIViewController *controller = nil;
    id <ISSocialUIDelegate> o = [ISSocial defaultInstance].uiDelegate;
    if ([o respondsToSelector:@selector(controllerToDisplayUIFromForSocialConnecto:)]) {
        controller = [o controllerToDisplayUIFromForSocialConnecto:self];
    }
    if (!controller) {
        controller = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    _lastDisplayController = controller;
    return controller;
}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    UIViewController *root = [self displayController];
    [root presentViewController:viewController animated:YES completion:^{
    }];
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [_lastDisplayController dismissViewControllerAnimated:YES completion:^{
    }];
}


- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    if (error) {
        NSLog(@"error = %@", error);
        if ([error.domain isEqualToString:kGIDSignInErrorDomain]) {
            NSInteger code = error.code;
            NSDictionary *userInfo = [error userInfo];
            if (code == kGIDSignInErrorCodeCanceled) {
                error = [ISSocial errorWithCode:ISSocialErrorUserCanceled sourceError:error userInfo:nil];
            }
            else if (code == kGIDSignInErrorCodeHasNoAuthInKeychain) {
                error = [ISSocial errorWithCode:ISSocialErrorStoredLoginAbsent sourceError:error userInfo:nil];
            }
            else if (code == kGIDSignInErrorCodeKeychain) {
                error = [ISSocial errorWithCode:ISSocialErrorAuthorizationRestorationFailed sourceError:error userInfo:nil];
            }
        }

        [self.signInOperation completeWithError:error];
        self.signInOperation = nil;
        self.loggedIn = NO;
        return;
    }
    if (!user) {
        [self.signInOperation completeWithFailure];
        self.signInOperation = nil;
        self.loggedIn = NO;
        return;
    }

    _authorizationInfo = [ISSAuthorisationInfo new];
    _authorizationInfo.handler = self;
    _authorizationInfo.accessToken = user.authentication.idToken;
    _authorizationInfo.userId = user.userID;

    _currentUserData = [[SUserData alloc] initWithHandler:self];
    _currentUserData.objectId = user.userID;
    _currentUserData.userName = user.profile.name;
    _currentUserData.userEmail = user.profile.email;
    _currentUserData.firstName = user.profile.givenName;
    _currentUserData.lastName = user.profile.familyName;

    self.loggedIn = YES;
    if (user.profile.hasImage) {
        _currentUserData.userPicture = [[MultiImage alloc] initWithURL:[user.profile imageURLWithDimension:200]];
    }

    [self.signInOperation complete:_currentUserData];
    self.signInOperation = nil;
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    self.loggedIn = NO;
    if (error) {
        [self.signInOperation completeWithError:error];
    }
    else {
        [self.signInOperation completeWithFailure];
    }
    self.signInOperation = nil;
}


- (SObject *)openSession:(SObject *)params silent:(BOOL)silent completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        self.signInOperation = operation;
        if (silent) {
            [self.signIn signInSilently];
        }
        else {
            [self.signIn signIn];
        }
    }];
}

- (SObject *)closeSessionAndClearCredentials:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        self.loggedIn = NO;
        [self.signIn signOut];
    }];
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self openSession:params silent:NO completion:completion];
}

- (BOOL)isLoggedIn {
    return _loggedIn;
}

- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        bool myself = NO;
        NSString *userId = params.objectId;
        if (userId.length == 0 || [userId isEqualToString:@"me"]) {
            myself = YES;
        }
        if (myself) {
            if (self.currentUserData) {
                [operation complete:self.currentUserData];
                return;
            }
        }
        [operation completeWithFailure];
    }];
}

- (SUserData *)currentUserData {
    return _currentUserData;
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}


- (void)handleDidBecomeActive {
    [super handleDidBecomeActive];
    if (self.signInOperation) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.signInOperation) {
                [self.signInOperation completeWithError:[ISSocial errorWithCode:ISSocialErrorUserCanceled
                                                                    sourceError:nil
                                                                       userInfo:nil]];
                self.signInOperation = nil;
            }
        });
    }
}


@end
