//
//  FacebookConnector.m
//  socials
//
//  Created by yar on 18.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SUserData.h"
#import "TwitterConnector.h"
#import "STTwitterAPIWrapper.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@interface TwitterConnector ()
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) id defaultReadPermissions;
@property(nonatomic, strong) ACAccount *account;
@end

@implementation TwitterConnector


- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}


+ (TwitterConnector *)instance
{
    static TwitterConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (NSString *)connectorCode
{
    return @"Twitter";
}


- (NSInteger)connectorPriority
{
    return 5;
}

- (NSInteger)connectorDisplayPriority
{
    return 5;
}

- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];

}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    //[FBSession.activeSession closeAndClearTokenInformation];
    self.account = nil;
    _loggedIn = NO;
    completion([SObject successful]);
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType =
            [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

//  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType
                     withCompletionHandler:^(BOOL granted, NSError *error) {
                         if (!granted) {
                             // The user rejected your request
                             NSLog(@"User rejected access to the account.");
                             completion([SObject failed]);
                         }
                         else {
                             // Grab the available accounts
                             NSArray *twitterAccounts =
                                     [store accountsWithAccountType:twitterAccountType];

                             if ([twitterAccounts count] > 0) {
                                 // Use the first account for simplicity
                                 ACAccount *account = twitterAccounts[0];
                                 
                                 self.account = account;

                                 // Now make an authenticated request to our endpoint
                                 NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
                                 params[@"include_entities"] = @"1";

                                 //  The endpoint that we wish to call
                                 NSURL *url =
                                         [NSURL
                                                 URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];

                                 //  Build the request with our parameter
                                 TWRequest *request =
                                         [[TWRequest alloc] initWithURL:url
                                                             parameters:params
                                                          requestMethod:TWRequestMethodGET];

                                 // Attach the account object to this request
                                 [request setAccount:account];

                                 [request performRequestWithHandler:
                                         ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                             if (!responseData) {
                                                 // inspect the contents of error
                                                 NSLog(@"%@", error);
                                                 completion([SObject error:error]);
                                             }
                                             else {
                                                 NSError *jsonError;
                                                 NSDictionary *info =
                                                         [NSJSONSerialization
                                                                 JSONObjectWithData:responseData
                                                                            options:NSJSONReadingMutableLeaves
                                                                              error:&jsonError];
                                                 if (info) {
                                                     // at this point, we have an object that we can parse
                                                     NSLog(@"%@", info);

                                                     SUserData *userData =
                                                             [[SUserData alloc] initWithHandler:self];

                                                     userData.userName = info[@"name"];

                                                     self.currentUserData = userData;
                                                     completion([SObject successful]);
                                                 }
                                                 else {
                                                     // inspect the contents of jsonError
                                                     NSLog(@"%@", jsonError);
                                                     completion([SObject error:jsonError]);
                                                 }
                                             }
                                         }];

                             } // if ([twitterAccounts count] > 0)
                         } // if (granted)
                     }];

    completion([SObject successful]);
    
}



- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;
        if (userId.length == 0) {
            [operation complete:self.currentUserData];
            return;
        }

        [operation completeWithFailure];
    }];
}


- (BOOL)isLoggedIn
{
    return _loggedIn;
}


@end
