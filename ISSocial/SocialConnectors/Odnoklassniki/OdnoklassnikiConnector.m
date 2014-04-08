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

@interface OdnoklassnikiConnector ()
@property(nonatomic) BOOL loggedIn;
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
    return @"Ok";
}

- (NSString *)connectorName
{
    return NSLocalizedString(@"Odnoklassniki", @"Odnoklassniki");
}

- (BOOL)isLoggedIn
{
    return [[ODKSession activeSession] isLoggedIn];
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [ODKSession openActiveSessionWithPermissions:@[@"VALUABLE_ACCESS", @"VALUABLE ACCESS", @"SET STATUS", @"PHOTO CONTENT", @"MESSAGING"] completionHandler:^(ODKSession *session, ODKSessionState status, NSError *error) {
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

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [[OKSession activeSession] handleOpenURL:url];
}


@end
