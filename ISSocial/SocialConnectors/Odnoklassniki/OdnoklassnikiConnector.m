//
//  OdnoklassnikiConnector.m
//  socials
//
//  Created by yar on 20.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "OdnoklassnikiConnector.h"
#import "ODKSession.h"
#import "ODKRequest.h"
#import "SUserData.h"
#import "ISSocial.h"

@interface OdnoklassnikiConnector ()
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, copy) NSString *appID;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, strong) NSArray *permissions;
@end

@implementation OdnoklassnikiConnector

- (id)init
{
    self = [super init];
    if (self) {
        self.client = [[AFHTTPRequestOperationManager alloc] init];
    }

    return self;
}

- (NSInteger)connectorPriority
{
    return 3;
}

- (NSInteger)connectorDisplayPriority
{
    return 3;
}

- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];

    self.appID = settings[@"AppID"];
    self.appKey = settings[@"AppKey"];
    self.appSecret = settings[@"AppSecret"];
    self.permissions = settings[@"Permissions"];
}


+ (OdnoklassnikiConnector *)instance
{
    static OdnoklassnikiConnector *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (NSString *)connectorCode
{
    return ISSocialConnectorIdOdnoklasniki;
}

- (BOOL)isLoggedIn
{
    return [[ODKSession activeSession] isLoggedIn];
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [ODKSession openActiveSessionWithPermissions:self.permissions appId:self.appID appSecret:self.appSecret appKey:self.appKey
                                   completionHandler:^(ODKSession *session, ODKSessionState status, NSError *error) {
                                       switch (status) {
                                           case ODKSessionStateOpen: {

                                               [self readUserData:nil completion:^(SObject *result) {
                                                   if (!result.isFailed) {
                                                       self.currentUserData = (SUserData *) result;

                                                       [operation complete:[SObject successful]];
                                                   }
                                                   else {
                                                       [operation completeWithFailure];
                                                   }
                                               }];
                                           }
                                               break;
                                           case ODKSessionStateClosed:
                                           case ODKSessionStateClosedLoginFailed: {
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

- (void)simpleMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id response))processor
{
    ODKRequest *requst = [ODKRequest requestMethod:method parameters:parameters];
    [requst startWithCompletionHandler:^(ODKRequest *connection, id response, NSError *error) {

        [operation removeConnection:connection];

        if (error) {
            NSLog(@"error = %@", error);
            [operation completeWithError:error];
        }
        else {
            processor(response);
        }
    }];
    [operation addConnection:requst];
}


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication
{
    return [[OKSession activeSession] handleOpenURL:url];
}


@end
