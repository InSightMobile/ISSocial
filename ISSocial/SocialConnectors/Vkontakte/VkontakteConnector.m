//
//  VkontakteConnector+News.m
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "VkontakteConnector+News.h"
#import "VKSession.h"
#import "VkontakteConnector+UserData.h"
#import "SUserData.h"
#import "ISSocial+Errors.h"

@interface VkontakteConnector ()
@property(nonatomic) BOOL loggedIn;

@property(nonatomic, strong) SUserData *currentUserData;
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
    return @"Vkontakte";
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
    [VKSession.activeSession closeAndClearTokenInformation];
    _loggedIn = NO;
    completion([SObject successful]);
}


- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        NSArray *permissions = self.permissions;
        if (!permissions) {
            permissions = @[@"wall", @"messages", @"photos", @"friends", @"video", @"audio"];
        }

        [VKSession openActiveSessionWithPermissions:permissions completionHandler:^(VKSession *session, VKSessionState status, NSError *error)
        {
            switch (status) {
                case VKSessionStateOpen: {
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
                case VKSessionStateClosed:
                case VKSessionStateClosedLoginFailed: {
                    [operation completeWithError:error];
                }
                    break;
                default:
                    [operation completeWithError:error];
                    break;
            }
        }];
    }];
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (void)setupSettings:(NSDictionary *)settings
{

    [super setupSettings:settings];

    if (settings[@"AppID"]) {
        [VKSession activeSession].clientId = settings[@"AppID"];
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
    VKRequestOperation *op =
            [[VKRequest requestMethod:method parameters:parameters] startWithCompletionHandler:^(VKRequestOperation *connection, id response, NSError *error)
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


@end
