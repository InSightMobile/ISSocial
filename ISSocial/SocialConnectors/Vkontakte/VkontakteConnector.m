//
//  VkontakteConnector+News.m
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "VkontakteConnector+News.h"
//#import "ISSVKSession.h"
#import "VkontakteConnector+UserData.h"
#import "SUserData.h"
#import "ISSocial+Errors.h"
#import "ISSAuthorisationInfo.h"


@interface VkontakteConnector ()
@property(nonatomic) BOOL loggedIn;

@property(nonatomic, strong) SUserData *currentUserData;
@property(nonatomic, strong) SocialConnectorOperation *autorizationOperation;
@property(nonatomic, strong) id clientId;
@property(nonatomic, strong) VKAccessToken *accessToken;
@end

@implementation VkontakteConnector

- (id)init
{
    self = [super init];
    if (self) {

        self.supportedSpecifications = [NSSet setWithArray:@[
                @"messageSmile",
                @"messagePhoto",
                @"messageAudio",
                @"feedPhoto",
                @"feedAudio"
        ]];

    }
    return self;
}


+ (NSString *)connectorCode
{
    return ISSocialConnectorIdVkontakte;
}


- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id response))processor
{
    [self simpleMethod:method parameters:nil operation:operation processor:processor];
}

- (NSInteger)connectorPriority
{
    return 6;
}

- (NSInteger)connectorDisplayPriority
{
    return 6;
}


#pragma mark Session management


- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    //[ISSVKSession.activeSession closeAndClearTokenInformation];
    _loggedIn = NO;
    completion([SObject successful]);
    return [SObject successful];
}


- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {
        NSArray *permissions = self.permissions;
        if (!permissions) {
            permissions = @[@"wall", @"messages", @"photos", @"friends", @"video", @"audio"];
        }

        self.autorizationOperation = operation;
        [VKSdk authorize:permissions];
        /*
        [ISSVKSession openActiveSessionWithPermissions:permissions completionHandler:^(ISSVKSession *session, ISSVKSessionState status, NSError *error)
        {
            switch (status) {
                case ISSVKSessionStateOpen: {
                    self.userId = session.userId;
                    self.currentUserData = [self dataForUserId:self.userId];

                    [self updateUserData:@[self.currentUserData] operation:operation completion:^(SObject *result)
                    {
                        self.loggedIn = YES;
                        [self startPull];
                        [operation complete:[SObject successful]];
                    }];
                }
                    break;
                case ISSVKSessionStateClosed:
                case ISSVKSessionStateClosedLoginFailed: {
                    [operation completeWithError:error];
                }
                    break;
                default:
                    [operation completeWithError:error];
                    break;
            }
        }];
        */
    }];
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (ISSAuthorisationInfo *)authorizatioInfo
{
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = self.accessToken.accessToken;
    token.userId = self.accessToken.userId;
    return token;
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication
{
    return [VKSdk processOpenURL:url fromApplication:sourceApplication];
}

- (void)handleDidBecomeActive
{
    if(![VKSdk isLoggedIn]) {
        [self.autorizationOperation completeWithFailure];
        self.autorizationOperation = nil;
    }
}


- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];
    if (settings[@"AppID"]) {
        //[ISSVKSession activeSession].clientId = settings[@"AppID"];
        self.clientId = settings[@"AppID"];
        [VKSdk initializeWithDelegate:self andAppId:self.clientId];
    }
    if (settings[@"Permissions"]) {
        self.permissions = settings[@"Permissions"];
    }
}


- (void)simpleMethod:(NSString *)method
          parameters:(NSDictionary *)parameters
           operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id))processor
{

    VKRequest * request = [VKRequest requestWithMethod:method andParameters:parameters andHttpMethod:@"GET"];

    [request executeWithResultBlock:^(VKResponse *response) {
        [operation removeSubOperation:request.executionOperation];

        processor(response.json);

    } errorBlock:^(NSError *error) {
        [operation removeSubOperation:request.executionOperation];

        NSLog(@"Vkontakte error on method: %@ params: %@ error: %@", method, parameters, error);
        [operation completeWithError:error];
    }];
    [operation addSubOperation:request.executionOperation];

   /*
    VKRequestOperation *op =
            [[ISSVKRequest requestMethod:method parameters:parameters] startWithCompletionHandler:^(VKRequestOperation *connection, id response, NSError *error)
            {

                [operation removeSubOperation:connection];

                if (error) {

                    NSLog(@"Vkontakte error on method: %@ params: %@ error: %@", method, parameters, error);
                    [operation completeWithError:[self processVKError:error]];

                }
                else {
                    processor(response);
                }
            }];
    [operation addSubOperation:op];
    */
}

- (NSError *)processVKError:(NSError *)error
{
    int code = ISSocialErrorUnknown;
    if (error.code == 214) {
        code = ISSocialErrorOperationNotAllowedByTarget;
    }

    NSError *socialError =
            [ISSocial errorWithCode:code sourseError:error userInfo:nil];

    return socialError;
}

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{

}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{

}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError
{
    [self.autorizationOperation completeWithError:[NSError errorWithVkError:authorizationError]];
    self.autorizationOperation = nil;
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{

}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    self.accessToken = newToken;
    if(!self.currentUserData) {
        self.currentUserData = [[SUserData alloc] initWithHandler:self];
    }
    [self updateUserData:@[self.currentUserData] operation:self.autorizationOperation completion:^(SObject *result)
    {
        self.loggedIn = YES;
        if([self respondsToSelector:@selector(startPull)]) {
            [self startPull];
        }
        [self.autorizationOperation complete:[SObject successful]];
        self.autorizationOperation = nil;
    }];
}


@end
