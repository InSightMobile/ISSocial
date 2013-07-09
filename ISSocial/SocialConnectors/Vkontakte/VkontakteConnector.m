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

+ (VkontakteConnector *)instance
{
    static VkontakteConnector *_instance = nil;
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (NSString *)connectorCode
{
    return @"Vk";
}

- (NSString *)connectorName
{
    return NSLocalizedString(@"Vkontakte", @"VKontakte");
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



- (SObject *)openSession:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSArray *permissions = self.permissions;
        if(!permissions) {
            permissions = @[@"wall", @"messages", @"photos", @"friends", @"video", @"audio"];
        }

        [VKSession openActiveSessionWithPermissions:permissions completionHandler:^(VKSession *session, VKSessionState status, NSError *error) {
            switch (status) {
                case VKSessionStateOpen: {
                    self.userId = session.userId;
                    self.currentUserData = [self dataForUserId:self.userId];

                    [self updateUserData:@[self.currentUserData] operation:operation completion:^(SObject *result) {

                        self.loggedIn = YES;
                        [self startPull];
                        [operation complete:[SObject successful]];
                    }];
                }
                    break;
                case VKSessionStateClosed:
                case VKSessionStateClosedLoginFailed: {
                    [operation completeWithFailure];
                }
                    break;
                default:
                    [operation completeWithFailure];
                    break;
            }
        }];
    }];
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (void)setupSettings:(NSDictionary *)settings {

    [super setupSettings:settings];

    if(settings[@"AppID"]) {
        [VKSession activeSession].clientId = settings[@"AppID"];
    }
    if(settings[@"Permissions"]) {
        self.permissions = settings[@"Permissions"];
    }
}


- (void)simpleMethod:(NSString *)method
          parameters:(NSDictionary *)parameters
           operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id))processor
{
    NSOperation *op =
            [[VKRequest requestMethod:method parameters:parameters] startWithCompletionHandler:^(VKRequestOperation *connection, id response, NSError *error) {

                [operation removeSubOperation:connection];

                if (error) {
                    [operation completeWithError:error];
                }
                else {
                    processor(response);
                }
            }];
    [operation addSubOperation:op];
}

@end
