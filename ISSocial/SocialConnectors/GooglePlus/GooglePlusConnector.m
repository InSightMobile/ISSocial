//
//  GooglePlusConnector.m
//  socials
//
//  Created by yar on 12.01.13.
//  Copyright (c) 2013 Ярослав. All rights reserved.
//

#import "GooglePlusConnector.h"
#import "GPPSignIn.h"
#import "GPSession.h"
#import "GTLQueryPlus.h"
#import "GTLService.h"
#import "GTLServicePlus.h"
#import "GTLPlusPeopleFeed.h"
#import "GTMLogger.h"
#import "GTLPlusConstants.h"
#import "SUserData.h"
#import "GTLPlusPerson.h"
#import "MultiImage.h"
#import "NSString+TypeSafety.h"

@interface GooglePlusConnector ()
@property(nonatomic, strong) GPPSignIn *signIn;
@property(nonatomic, copy) CompletionBlock openSession;
@property(nonatomic) BOOL loggedIn;
@end

@implementation GooglePlusConnector

+ (GooglePlusConnector *)instance
{
    static GooglePlusConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (NSString *)connectorCode
{
    return @"Gp";
}

- (NSString *)connectorName
{
    return @"GooglePlus";
}

- (NSInteger)connectorPriority
{
    return 2;
}

- (NSInteger)connectorDisplayPriority
{
    return 2;
}


- (SObject *)openSession:(SObject *)params completion:(CompletionBlock)completion
{
    [GPSession openActiveSessionWithPermissions:nil completionHandler:^(GPSession *session, GPSessionState status, NSError *error) {

        switch (status) {
            case GPSessionStateOpen: {
                [SObject successful:completion];
                self.loggedIn = YES;
            }
                break;
            case GPSessionStateClosed:
            case GPSessionStateClosedLoginFailed: {
                [SObject failed:completion];
            }
                break;
            default:
                [SObject failed:completion];
                break;
        }
    }];
    return [SObject objectWithState:SObjectStateProcessing];
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (void)executeQuery:(id <GTLQueryProtocol>)query operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id object))handler
{
    [[GPSession activeSession].plusService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
            id object,
            NSError *error) {
        if (error) {
            GTMLoggerError(@"Error: %@", error);
            //peopleStatus_.text = [NSString stringWithFormat:@"Status: Error: %@", error];
            [operation completeWithError:error];
        } else {

            handler(object);
        }
    }];


}

- (SObject *)readUserFriends:(SUserData *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        GTLQueryPlus *query =
                [GTLQueryPlus queryForPeopleListWithUserId:@"me"
                                                collection:kGTLPlusCollectionVisible];

        [self executeQuery:query operation:operation processor:^(GTLPlusPeopleFeed *peopleFeed) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (GTLPlusPerson *person in peopleFeed.items) {
                SUserData *user = [[SUserData alloc] initWithHandler:self];
                user.objectId = person.identifier;
                user.userName = person.displayName;

                NSString *userImage = person.image.url;
                user.userPicture =
                        [[MultiImage alloc] initWithURL:userImage.URLValue];

                [result addSubObject:user];
            }

            [operation complete:result];
        }];
    }];
}


@end
