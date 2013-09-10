//
//  FacebookConnector.m
//  socials
//
//  Created by yar on 18.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <BlocksKit/NSObject+BlocksKit.h>
#import "FacebookConnector+UserData.h"
#import "FacebookSDK.h"
#import "FacebookConnectorOperation.h"
#import "SUserData.h"
#import "FacebookConnector+Messages.h"
#import "ISSocial.h"
#import "ISSocial+Errors.h"

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
    dispatch_once(&pred, ^
    {
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
    return @"Facebook";
}


- (NSInteger)connectorPriority
{
    return 5;
}

- (NSInteger)connectorDisplayPriority
{
    return 5;
}


- (void)simpleMethodWithURL:(NSString *)urlString operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession graphPath:nil];
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
    {
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
            [fql startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
            {

                [operation removeConnection:connection];

                if (error) {
                    NSLog(@"Facebook error on FQL: %@ ", query);
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
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
            {
                [operation removeConnection:connection];
                if (error) {
                    NSLog(@"Facebook error on method: %@ params: %@", method, object);
                    [operation completeWithError:error];
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
            [[FBRequest requestForPostWithGraphPath:method graphObject:object] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
            {
                [operation removeConnection:connection];
                if (error) {
                    NSLog(@"Facebook error on method: %@ params: %@ error: %@", method, object, error);

                    NSDictionary *errorData = error.userInfo[FBErrorParsedJSONResponseKey];

                    int facebookCode = [errorData[@"body"][@"error"][@"code"] intValue];

                    int code = ISSocialErrorUnknown;
                    if (facebookCode == 240) {
                        code = ISSocialErrorOperationNotAllowedByTarget;
                    }

                    NSError *socialError =
                            [ISSocial errorWithCode:code sourseError:error userInfo:nil];

                    [operation completeWithError:socialError];
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
                        startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
                        {

                            [operation removeConnection:connection];
                            if (error) {
                                NSLog(@"Facebook error on method: %@ ", path);
                                [operation completeWithError:error];
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
                [[FBRequest requestWithGraphPath:path parameters:object HTTPMethod:httpMethod] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
                {
                    [operation removeConnection:connection];
                    if (error) {
                        NSLog(@"Facebook error on method: %@ params: %@", path, object);
                        [operation completeWithError:error];
                    }
                    else {
                        processor(result);
                    }
                }];
        [operation addConnection:connection];
    }
}

- (void)checkAuthorizationFor:(NSArray *)permissions  operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    [self authorizeWithPublishPermissions:permissions completion:^(SObject *result)
    {

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
        if([[FBSession activeSession] isOpen]) {
            [[FBSession activeSession] requestNewPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error)
            {

                if (!error) {
                    [self performBlock:^(id sender)
                    {
                        [SObject successful:completion];
                    } afterDelay:0.1];
                }
                else {
                    [SObject failed:completion];
                }
            }
            ];
        }
        else {
            [self openSession:nil completion:^(SObject *result)
            {
                if(self.isLoggedIn) {
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
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {
        // See if we have a valid token for the current state.
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            // To-do, show logged in view
        }
        else {
            // No, display the login page.
        }

        NSArray *permissions = self.defaultReadPermissions;

        if (!permissions) {
            permissions = @[
                    @"user_about_me", @"read_stream", @"user_photos",
                    @"read_mailbox", @"xmpp_login", @"friends_about_me",
                    @"friends_online_presence", @"user_videos", @"email"];
        }

        /*
                [FBSession openActiveSessionWithPermissions:permissions
                                       allowLoginUI:YES
                                 allowSystemAccount:NO
                                             isRead:YES
                                    defaultAudience:FBSessionDefaultAudienceNone
                                  completionHandler:^(FBSession *session,
                                          FBSessionState state, NSError *error)
                                  {
         */

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

                    switch (state) {
                        case FBSessionStateOpen:
                        case FBSessionStateOpenTokenExtended: {

                            [self readUserData:[SUserData new] completion:^(SObject *result)
                            {
                                [self performBlock:^(id sender)
                                {
                                    [SObject successful:completion];
                                } afterDelay:0.1];

                                self.loggedIn = YES;
                                if ([session.permissions indexOfObject:@"xmpp_login"] != NSNotFound) {
                                    if ([self respondsToSelector:@selector(xmppConnect)]) {
                                        [self xmppConnect];
                                    }
                                }
                            }];
                        }
                            break;
                        case FBSessionStateClosed:
                            [operation completeWithError:error];
                            break;
                        case FBSessionStateClosedLoginFailed:
                            if([error.userInfo[FBErrorLoginFailedReason]
                                    isEqualToString:FBErrorLoginFailedReasonSystemDisallowedWithoutErrorValue]) {

                                [operation completeWithError:[ISSocial errorWithCode:ISSocialErrorSystemLoginDisallowed sourseError:error userInfo:nil]];
                            }
                            else {
                                [operation completeWithError:error];
                            }
                            break;
                        default:
                            [SObject failed:completion];
                            break;
                    }
                }];
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

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [[FBSession activeSession] handleOpenURL:url];
}


@end
