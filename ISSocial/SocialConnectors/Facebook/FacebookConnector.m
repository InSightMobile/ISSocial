//
//

#import "FacebookConnector+UserData.h"
#import "FacebookSDK.h"
#import "FacebookConnectorOperation.h"
#import "SUserData.h"
#import "FacebookConnector+Messages.h"
#import "ISSocial.h"
#import "ISSocial+Errors.h"
#import "NSObject+PerformBlockInBackground.h"
#import "ISSAuthorisationInfo.h"

@interface FacebookConnector ()
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) id defaultReadPermissions;
@end

@implementation FacebookConnector


- (id)init
{
    self = [super init];
    if (self) {
        self.supportedSpecifications = [NSSet setWithArray:@[
                @"feedPhoto"
        ]];
    }
    return self;
}


+ (FacebookConnector *)instance
{
    static FacebookConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    [self simpleMethod:nil path:method params:nil object:nil operation:operation processor:processor];
}

- (void)simpleMethod:(NSString *)method params:(NSDictionary *)params operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    [self simpleMethod:nil path:method params:params object:nil operation:operation processor:processor];
}


+ (NSString *)connectorCode
{
    return ISSocialConnectorIdFacebook;
}



- (void)simpleMethodWithURL:(NSString *)urlString operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:nil];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [operation completeWithError:error];
        }
        else {
            processor(result);
        }
    }];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    connection.urlRequest = urlRequest;
    [connection start];
}

- (void)simpleQuery:(NSString *)query operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    FBRequest *fql = [FBRequest requestForGraphPath:@"fql"];
    [fql.parameters setObject:query forKey:@"q"];

    FBRequestConnection *connection =
            [fql startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {

                [operation removeConnection:connection];

                if (error) {
                    NSLog(@"Facebook error on FQL: %@ error: %@", query, error.userInfo);
                    NSLog(@"error = %@", error);
                    [operation completeWithError:error];
                    return;
                }
                processor(result);
            }];
    [operation addConnection:connection];
}

- (void)simpleRequest:(NSString *)method path:(NSString *)path object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    FBRequest *request = [[FBRequest alloc] initWithSession:[FBSession activeSession]
                                                  graphPath:path
                                                 parameters:object
                                                 HTTPMethod:method];

    FBRequestConnection *connection =
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [operation removeConnection:connection];
                if (error) {
                    NSLog(@"Facebook error on method: %@ params: %@ error:%@", method, object, error.userInfo);
                    [self processFacebookError:error operation:operation processor:^(id o) {
                    }];
                }
                else {
                    processor(result);
                }
            }];

    [operation addConnection:connection];
}

- (void)simplePost:(NSString *)method object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    FBRequestConnection *connection =
            [[FBRequest requestForPostWithGraphPath:method graphObject:object] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                [operation removeConnection:connection];
                if (error) {
                    NSLog(@"Facebook error on method: %@ params: %@ error: %@", method, object, error.userInfo);
                    [self processFacebookError:error operation:operation processor:processor];
                }
                else {
                    processor(result);
                }
            }];
    [operation addConnection:connection];
}

- (void)simpleMethod:(NSString *)httpMethod path:(NSString *)path params:(NSDictionary *)params object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    if (!object) {
        FBRequestConnection *connection =
                [[[FBRequest alloc] initWithSession:[FBSession activeSession]
                                          graphPath:path
                                         parameters:params
                                         HTTPMethod:httpMethod]
                        startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {

                            [operation removeConnection:connection];
                            if (error) {
                                NSLog(@"Facebook error on method: %@ error:%@", path, error.userInfo);
                                [self processFacebookError:error operation:operation processor:processor];
                            }
                            else {
                                processor(result);
                            }
                        }];
        [operation addConnection:connection];
    }
    else {
        if (!httpMethod) {
            httpMethod = @"POST";
        }
        FBRequestConnection *connection =
                [[FBRequest requestWithGraphPath:path parameters:object HTTPMethod:httpMethod] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    [operation removeConnection:connection];
                    if (error) {
                        NSLog(@"Facebook error on method: %@ params: %@ error:%@", path, object, error.userInfo);
                        [self processFacebookError:error operation:operation processor:processor];
                    }
                    else {
                        processor(result);
                    }
                }];
        [operation addConnection:connection];
    }
}

- (void)processFacebookError:(NSError *)error operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    if(error.code == FBErrorHTTPError) {
        [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorNetwork sourseError:error.userInfo[FBErrorInnerErrorKey] userInfo:nil]];
        return;
    }

    NSDictionary *errorData = error.userInfo[FBErrorParsedJSONResponseKey];

    int facebookCode = [errorData[@"body"][@"error"][@"code"] intValue];

    int code = ISSocialErrorUnknown;
    if (facebookCode == 240) {
        code = ISSocialErrorOperationNotAllowedByTarget;
    }
    if (facebookCode == 3501) {
        code = ISSocialErrorOperationAlreadyDone;
    }

    NSError *socialError =
            [ISSocial errorWithCode:code sourseError:error userInfo:nil];

    [operation completeWithError:socialError];
}

- (void)checkAuthorizationFor:(NSArray *)permissions operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    [self authorizeWithPublishPermissions:permissions completion:^(SObject *result) {
        if (result.isFailed) {
            [operation completeWithFailure];
        }
        processor(result);
    }];
}

- (void)authorizeWithPublishPermissions:(NSArray *)permissions completion:(SObjectCompletionBlock)completion
{
    bool ok = YES;
    for (NSString *permission in permissions) {
        if (![[[FBSession activeSession] permissions] containsObject:permission]) {
            ok = NO;
            break;
        }
    }
    if (ok) {
        [SObject successful:completion];
    }
    else {
        if ([[FBSession activeSession] isOpen]) {
            [[FBSession activeSession] requestNewPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {

                if (!error) {
                    [self iss_performBlock:^(id sender) {
                        [SObject successful:completion];
                    }           afterDelay:0.1];
                }
                else {
                    [SObject failed:completion];
                }
            }
            ];
        }
        else {
            [self openSession:nil completion:^(SObject *result) {
                if (self.isLoggedIn) {
                    [self authorizeWithPublishPermissions:permissions completion:completion];
                }
                else {
                    completion([SObject failed]);
                }
            }];
        }

    }
}

- (void)handleDidBecomeActive
{
    [[FBSession activeSession] handleDidBecomeActive];
}


- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];

    if (settings[@"AppID"]) {
        [FBSettings setDefaultAppID:settings[@"AppID"]];
    }
    if (settings[@"ReadPermissions"]) {
        self.defaultReadPermissions = settings[@"ReadPermissions"];
    }

}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    [FBSession.activeSession closeAndClearTokenInformation];
    _loggedIn = NO;
    completion([SObject successful]);
    return [SObject successful];
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        NSArray *permissions = self.defaultReadPermissions;

        if (!permissions) {
            permissions = @[@"user_about_me"];
        }

        BOOL allowLoginUI = YES;
        if (params[kAllowUserUIKey]) {
            allowLoginUI = [params[kAllowUserUIKey] boolValue];
        }

#if 1
        BOOL loggedIn =
                [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {

#else
        FBSession *session = [[FBSession alloc] initWithAppID:nil
                                                   permissions:permissions
                                               defaultAudience:FBSessionDefaultAudienceFriends
                                               urlSchemeSuffix:nil
                                            tokenCacheStrategy:nil];

        [FBSession setActiveSession:session];

        [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
                completionHandler:^(FBSession *session,
                        FBSessionState state, NSError *error)
                {
#endif

                    switch (state) {
                        case FBSessionStateOpen:
                        case FBSessionStateOpenTokenExtended: {

                            [self processLoggedInSession:session completion:completion];
                        }
                            break;
                        case FBSessionStateClosed:
                            [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:error userInfo:nil]];
                            break;
                        case FBSessionStateClosedLoginFailed:
                            if ([error.userInfo[FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonSystemDisallowedWithoutErrorValue]) {
                                [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorSystemLoginDisallowed sourseError:error userInfo:nil]];
                            }
                            else if ([error.userInfo[FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonUserCancelledSystemValue]) {
                                [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorSystemLoginDisallowed sourseError:error userInfo:nil]];
                            }
                            else if ([error.userInfo[FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonUserCancelledValue]) {
                                [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorUserCanceled sourseError:error userInfo:nil]];
                            }

                            else {
                                [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:error userInfo:nil]];
                            }
                            break;
                        default:
                            [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:error userInfo:nil]];
                            break;
                    }
                }];

        if (!loggedIn && !allowLoginUI) {
            [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:nil userInfo:nil]];
        }
    }];


}

- (void)processLoggedInSession:(FBSession *)session completion:(SObjectCompletionBlock)completion
{
    [self readUserData:[SUserData new] completion:^(SObject *result) {
        [self iss_performBlock:^(id sender) {
            [SObject successful:completion];
        }           afterDelay:0.1];

        self.loggedIn = YES;
        if ([session.permissions indexOfObject:@"xmpp_login"] !=
                NSNotFound) {
            if ([self respondsToSelector:@selector(xmppConnect)]) {
                [self xmppConnect];
            }
        }
    }];
}


- (SocialConnectorOperation *)operationWithParent:(SocialConnectorOperation *)operation
{
    return [[FacebookConnectorOperation alloc] initWithHandler:self parent:operation];
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSession activeSession] handleOpenURL:url];
}

- (ISSAuthorisationInfo *)authorizatioInfo
{
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = [FBSession activeSession].accessTokenData.accessToken;
    token.userId = self.currentUserData.objectId;
    return token;
}

- (SObject *)readUserMutualFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self readUserFriends:params completion:completion];
}


@end
