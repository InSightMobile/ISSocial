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
#import "ISSAuthorisationInfo.h"

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
    return ISSocialConnectorIdOdnoklassniki;
}

- (BOOL)isLoggedIn
{
    return [[ODKSession activeSession] isLoggedIn];
}


- (ISSAuthorisationInfo *)authorizatioInfo
{
    if (!self.currentUserData.objectId) {
        return nil;
    }

    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = [ODKSession activeSession].accessToken;
    token.userId = self.currentUserData.objectId;
    return token;
}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    self.currentUserData = nil;
    [[ODKSession activeSession] close];
    _loggedIn = NO;
    completion([SObject successful]);
    return [SObject successful];
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
    NSMutableDictionary *preparedParameters = [NSMutableDictionary dictionaryWithCapacity:parameters.count];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        preparedParameters[key] = [obj stringValue];
    }];

    OKRequest *request = [OKRequest requestWithParams:preparedParameters httpMethod:@"GET" apiMethod:method];

    [request executeWithCompletionBlock:^(id data) {
        processor(data);
    }                        errorBlock:^(NSError *error) {
        NSLog(@"error = %@", error);
        [operation completeWithError:error];
    }];
}


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[OKSession activeSession] handleOpenURL:url];
}


@end
