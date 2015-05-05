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
#import "NSObject+PerformBlockInBackground.h"
#import "ISSPresentingViewController.h"
#import "SCommentData.h"
#import "VkontakteConnector+Pull.h"


static const int kMaxRetries = 3;

@interface VkontakteConnector ()
@property(nonatomic) BOOL loggedIn;

@property(nonatomic, strong) SUserData *currentUserData;
@property(nonatomic, strong) SocialConnectorOperation *autorizationOperation;
@property(nonatomic, strong) NSString* clientId;
@property(nonatomic, strong) VKAccessToken *accessToken;
@property(nonatomic, strong) UIViewController *presentedController;
@end

@implementation VkontakteConnector

- (id)init {
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


+ (NSString *)connectorCode {
    return ISSocialConnectorIdVkontakte;
}


- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id response))processor {
    [self simpleMethod:method parameters:nil operation:operation processor:processor];
}


#pragma mark Session management

- (SObject *)closeSessionAndClearCredentials:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self closeSession:params completion:completion];
}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    self.accessToken = nil;
    self.currentUserData = nil;
    [VKSdk forceLogout];
    _loggedIn = NO;
    completion([SObject successful]);
    return [SObject successful];
}




- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        if(!self.clientId.length) {
            [operation completeWithFailure];
            return;
        }

        NSArray *permissions = self.permissions;
        if (!permissions) {
            self.permissions = @[@"wall", @"messages", @"photos", @"friends", @"video", @"audio"];
        }
        self.autorizationOperation = operation;

        if ([VKSdk wakeUpSession]) {
            self.accessToken = [VKSdk getAccessToken];
            [self completeAuthorization];
        }
        else {
            [VKSdk authorize:self.permissions revokeAccess:NO forceOAuth:NO inApp:NO display:VK_DISPLAY_IOS];
        }
    }];
}

- (BOOL)isLoggedIn {
    return _loggedIn;
}

- (ISSAuthorisationInfo *)authorizatioInfo {
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = self.accessToken.accessToken;
    token.userId = self.accessToken.userId;
    return token;
}

- (void)handleDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [VKSdk wakeUpSession:self.permissions];
}


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [VKSdk processOpenURL:url fromApplication:sourceApplication];
}

- (void)handleDidBecomeActive {
    [self iss_performBlock:^(id sender) {
        if (![VKSdk isLoggedIn]) {
            [self.autorizationOperation completeWithFailure];
            self.autorizationOperation = nil;
        }
    }           afterDelay:2];
}


- (void)setupSettings:(NSDictionary *)settings {
    [super setupSettings:settings];
    if (settings[ISSAppIDKey]) {
        self.clientId = settings[ISSAppIDKey];
        [VKSdk initializeWithDelegate:self andAppId:self.clientId];
    }
    if (settings[ISSPermissionsKey]) {
        self.permissions = settings[ISSPermissionsKey];
    }
}


- (void)simpleMethod:(NSString *)method
          parameters:(NSDictionary *)parameters
           operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id))processor {

    VKRequest *request = [VKRequest requestWithMethod:method andParameters:parameters andHttpMethod:@"GET"];

    [self executeRequest:request operation:operation processor:processor retries:0];
}

- (void)executeRequest:(VKRequest *)request operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor retries:(NSInteger)retries {
    NSLog(@"request = %@", request);

    [request executeWithResultBlock:^(VKResponse *response) {
        [operation removeSubOperation:request.executionOperation];

        processor(response.json);

    }                    errorBlock:^(NSError *error) {

        NSLog(@"error = %@", error);


        [operation removeSubOperation:request.executionOperation];

        VKError *vkError = [error vkError];
        if (vkError) {
            if (vkError.errorCode == 5) {
                if (retries == 0) {
                    [self executeRequest:request operation:operation processor:processor retries:1];
                    return;
                }
                else if (retries < kMaxRetries) {
                    [self reauthorizeWithOperation:operation completion:^(SObject *result) {

                        if (result.isSuccessful) {
                            [self executeRequest:request operation:operation processor:processor retries:retries + 1];
                        }
                        else {
                            [operation completeWithError:error];
                        }
                    }];
                    return;
                }
            }
        }
        [operation completeWithError:error];
    }];
    [operation addSubOperation:request.executionOperation];
}

- (void)reauthorizeWithOperation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion {
    SObject *op = [self operationWithObject:operation.object completion:completion];
    self.autorizationOperation = op.operation;
    [VKSdk authorize:self.permissions revokeAccess:NO forceOAuth:NO inApp:NO display:VK_DISPLAY_IOS];
}

- (NSError *)processVKError:(NSError *)error {
    int code = ISSocialErrorUnknown;
    if (error.code == 214) {
        code = ISSocialErrorOperationNotAllowedByTarget;
    }

    NSError *socialError =
            [ISSocial errorWithCode:code sourseError:error userInfo:nil];

    return socialError;
}

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {

}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {

}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {
    if (self.presentedController) {
        [[ISSPresentingViewController presentingController] dismissController:self.presentedController];
        self.presentedController = nil;
    }

    NSError *vkError = [NSError errorWithVkError:authorizationError];
    NSError *socialError;

    if (authorizationError.errorCode == VK_API_CANCELED) {
        socialError = [ISSocial errorWithCode:ISSocialErrorUserCanceled
                                  sourseError:vkError
                                     userInfo:nil];
    }
    else {
        socialError = [ISSocial errorWithCode:ISSocialErrorAuthorizationFailed
                                  sourseError:vkError
                                     userInfo:nil];
    }

    [self.autorizationOperation completeWithError:socialError];
    self.autorizationOperation = nil;

}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    self.presentedController = controller;
    [[ISSPresentingViewController presentingController] presentController:controller];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken {
    if (self.presentedController) {
        [[ISSPresentingViewController presentingController] dismissController:self.presentedController];
        self.presentedController = nil;
    }

    self.accessToken = newToken;
    [self completeAuthorization];
}

- (void)updateCurrentUser {
    if (!self.currentUserData) {
        self.currentUserData = [self dataForUserId:self.accessToken.userId];
    }
}

- (void)completeAuthorization {
    [self updateCurrentUser];

    NSMutableArray *fields = [self.profileFields mutableCopy];
    if([self.permissions containsObject:@"email"]) {
        [fields addObject:@"email"];
    }

    [self updateUserData:@[self.currentUserData] fields:fields operation:self.autorizationOperation completion:^(SObject *result) {
        if (result.isSuccessful && result.subObjects.count == 1) {
            self.currentUserData = result.subObjects[0];
        }

        self.loggedIn = YES;
        if ([self respondsToSelector:@selector(startPull)]) {
            [self startPull];
        }

        self.userId = self.accessToken.userId;

        [self.autorizationOperation complete:[SObject successful]];
        self.autorizationOperation = nil;
    }];
}


@end
