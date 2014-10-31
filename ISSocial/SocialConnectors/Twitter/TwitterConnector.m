//
//

#import "SUserData.h"
#import "TwitterConnector.h"
#import "ISSocial.h"
#import "ISSAuthorisationInfo.h"
#import "MultiImage.h"
#import "SInvitation.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "STTwitter.h"
#import "ISSocial+Errors.h"
#import "WebLoginController.h"
#import "NSString+ValueConvertion.h"
#import "NSObject+PerformBlockInBackground.h"
#import "RACBacktrace.h"


@interface TwitterConnector () <UIActionSheetDelegate, WebLoginControllerDelegate>
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) ACAccount *account;
@property(nonatomic, copy) NSString *secret;
@property(nonatomic, copy) NSString *token;
@property(nonatomic, strong) NSArray *accounts;

@property(nonatomic, copy) NSString *tokenSecret;
@property(nonatomic, copy) NSString *consumerKey;
@property(nonatomic, copy) NSString *consumerSecret;
@property(nonatomic, strong) STTwitterAPI *twitterAPI;
@property(nonatomic, copy) NSString *userID;
@property(nonatomic, copy) NSString *screenName;
@property(nonatomic, strong) SocialConnectorOperation *authorizationOperation;
@property(nonatomic, copy) void (^successCallback)(ACAccount *);
@property(nonatomic, copy) void (^failureCallback)(NSError *);
@property(nonatomic) BOOL urlHandled;
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
    return ISSocialConnectorIdTwitter;
}


- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];

    self.consumerKey = settings[@"AppKey"];
    self.consumerSecret = settings[@"AppSecret"];
}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    //[FBSession.activeSession closeAndClearTokenInformation];
    self.account = nil;
    _loggedIn = NO;
    completion([SObject successful]);
    return [SObject successful];
}

- (ISSAuthorisationInfo *)authorizatioInfo
{
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = self.token;
    token.accessTokenSecret = self.tokenSecret;
    token.userId = self.userID;

    return token;
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        BOOL allowLoginUI = YES;
        if (params[kAllowUserUIKey]) {
            allowLoginUI = [params[kAllowUserUIKey] boolValue];
        }

        STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                                  consumerKey:self.consumerKey
                                                               consumerSecret:self.consumerSecret];

        [self getSystemAuthWithUI:allowLoginUI success:^(ACAccount *account) {

            [twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {

                STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:account];

                [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {

                    [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                        successBlock:^(NSString *oAuthToken,
                                                                                NSString *oAuthTokenSecret,
                                                                                NSString *userID,
                                                                                NSString *screenName) {
                                                                            self.token = oAuthToken;
                                                                            self.tokenSecret = oAuthTokenSecret;
                                                                            self.userID = userID;
                                                                            self.screenName = screenName;
                                                                            self.twitterAPI = twitterAPIOS;

                                                                            [self updateUserDataWithOperation:operation];


                                                                        } errorBlock:^(NSError *error) {
                                [operation completeWithError:[self errorWithError:error]];
                            }];

                }                                    errorBlock:^(NSError *error) {
                    [operation completeWithError:[self errorWithError:error]];
                }];

            }                          errorBlock:^(NSError *error) {
                [operation completeWithError:[self errorWithError:error]];
            }];
        }                 failure:^(NSError *error) {

            if (error.code == ISSocialErrorSystemLoginAbsent && allowLoginUI) {

                NSString *callback = [self systemCallbackURL];

                [twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {

                    self.twitterAPI = twitter;
                    self.authorizationOperation = operation;
                    self.urlHandled = NO;
                    [[UIApplication sharedApplication] openURL:url];

                }           oauthCallback:callback errorBlock:^(NSError *error) {

                    [operation completeWithError:[self errorWithError:error]];
                }];
            }
            else {
                [operation completeWithError:[self errorWithError:error]];
            }
        }];
    }];
}

- (NSString *)systemCallbackURL
{
    return [NSString stringWithFormat:@"%@://iss/twittter", [NSBundle mainBundle].bundleIdentifier];
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.absoluteString hasPrefix:self.systemCallbackURL]) {

        self.urlHandled = YES;
        NSDictionary *query = [url.query explodeURLQuery];

        if (query[@"oauth_token"]) {
            [self setOAuthToken:query[@"oauth_token"] oauthVerifier:query[@"oauth_verifier"]];
        }
        else {
            [[self authorizationOperation] completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:nil userInfo:nil]];
            self.authorizationOperation = nil;
        }
        return YES;
    }
    return NO;
}

- (void)handleDidBecomeActive
{
    [self iss_performBlock:^(id sender) {
        if (self.authorizationOperation && !self.urlHandled) {
            self.urlHandled = YES;
            [[self authorizationOperation] completeWithError:[ISSocial errorWithCode:ISSocialErrorAuthorizationFailed sourseError:nil userInfo:nil]];
            self.authorizationOperation = nil;
        }
    }           afterDelay:1];
}


- (void)setOAuthToken:(NSString *)token oauthVerifier:(NSString *)verifier
{

    [self.twitterAPI postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {

        self.token = oauthToken;
        self.tokenSecret = oauthTokenSecret;
        self.userID = userID;
        self.screenName = screenName;
        [self updateUserDataWithOperation:self.authorizationOperation];
        self.authorizationOperation = nil;

    }                                   errorBlock:^(NSError *error) {

        [[self authorizationOperation] completeWithError:[self errorWithError:error]];
        self.authorizationOperation = nil;
    }];
}

- (NSError *)errorWithError:(NSError *)error
{
    NSLog(@"error = %@", error);
    return [ISSocial errorWithError:error];
}


- (SObject *)readUserData:(SUserData *)params
               completion:(SObjectCompletionBlock)completion
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


- (void)updateUserDataWithOperation:(SocialConnectorOperation *)operation
{

    [self.twitterAPI getAccountVerifyCredentialsWithIncludeEntites:@NO skipStatus:@YES successBlock:^(NSDictionary *info) {

        SUserData *userData = [self userDataWithResponse:info];
        self.currentUserData = userData;
        _loggedIn = YES;
        [operation complete:[SObject successful]];

    }                                                   errorBlock:^(NSError *error) {
        [operation completeWithError:error];
    }];
}

- (SUserData *)dataForUserId:(NSString *)userId
{
    return (SUserData *) [self mediaObjectForId:userId type:@"users"];
}

- (SUserData *)userDataWithResponse:(NSDictionary *)info
{
    NSString *objectId = [info[@"id"] stringValue];
    SUserData *userData = [self dataForUserId:objectId];

    userData.userName = info[@"name"];
    userData.userPicture = [[MultiImage alloc] initWithURL:[NSURL URLWithString:info[@"profile_image_url"]]];
    return userData;
}

- (BOOL)isLoggedIn
{
    return _loggedIn;
}

- (BOOL)isLocalTwitterAccountAvailable
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)getSystemAuthWithUI:(BOOL)withUI success:(void (^)(ACAccount *account))onSuccess failure:(void (^)(NSError *error))onError
{
    self.successCallback = onSuccess;
    self.failureCallback = onError;

    if (![self isLocalTwitterAccountAvailable]) {
        if (onError) {
            onError([ISSocial errorWithCode:ISSocialErrorSystemLoginAbsent sourseError:nil userInfo:nil]);
        }
        return;
    }

    ACAccountStore *accountStore = [ACAccountStore new];
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    if(!withUI) {
        [self getSystemAuthForStore:accountStore onSuccess:onSuccess failure:onError withUI:withUI];
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [accountStore requestAccessToAccountsWithType:twitterType options:NULL completion:^(BOOL granted, NSError *error) {
        __unsafe_unretained __typeof(self) newSelf = weakSelf;
        if (granted) {
            [newSelf getSystemAuthForStore:accountStore onSuccess:onSuccess failure:onError withUI:withUI];
        }
        else {
            if (onError) {
                onError([ISSocial errorWithCode:ISSocialErrorSystemLoginDisallowed sourseError:nil userInfo:nil]);
            }
        }
    }];
}

- (void)getSystemAuthForStore:(ACAccountStore *)accountStore onSuccess:(void (^)(ACAccount *))onSuccess failure:(void (^)(NSError *error))onError withUI:(BOOL)withUI
{
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    self.accounts = [accountStore accountsWithAccountType:twitterType];
    if (self.accounts.count == 1) {
        onSuccess(self.accounts[0]);
    }
    else if(self.accounts.count > 1 && withUI){
        UIActionSheet *sheet = [[UIActionSheet alloc] init];

        for (ACAccount *acct in self.accounts) {
            [sheet addButtonWithTitle:acct.username];
        }

        sheet.delegate = self;
        sheet.cancelButtonIndex =
                [sheet addButtonWithTitle:NSLocalizedStringWithDefaultValue(@"ISSocial_Cancel", nil, [NSBundle mainBundle], @"Cancel", @"Cancel")];

        dispatch_async(dispatch_get_main_queue(), ^{
            [sheet showInView:[UIApplication sharedApplication].keyWindow];
        });
    }
    else {
        if (onError) {
            onError([ISSocial errorWithCode:ISSocialErrorSystemLoginDisallowed sourseError:nil userInfo:nil]);
        }
    }
}

- (SObject *)sendInvitation:(SInvitation *)invitation completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:invitation completion:completion processor:^(SocialConnectorOperation *operation) {
        [self.twitterAPI postDirectMessage:invitation.message forScreenName:nil orUserID:invitation.user.objectId successBlock:^(NSDictionary *message) {
            [operation complete:[SObject successful]];
        }                       errorBlock:^(NSError *error) {
            [operation completeWithError:[self errorWithError:error]];
        }];
    }];
}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self.twitterAPI getFriendsForScreenName:self.screenName successBlock:^(NSArray *users) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *user in users) {

                SUserData *userData = [self userDataWithResponse:user];

                [result addSubObject:userData];
            }

            [operation complete:result];

        }                             errorBlock:^(NSError *error) {

            [operation completeWithError:[self errorWithError:error]];
        }];
    }];
}

- (SObject *)readUserMutualFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self readUserFriends:operation.object completion:^(SObject *result) {

            if (!result.isSuccessful) {
                [operation completeWithError:result.error];
                return;
            }

            NSArray *friends = result.subObjects;

            [self.twitterAPI getFollowersIDsForScreenName:self.screenName successBlock:^(NSArray *users) {

                NSSet *followers = [NSSet setWithArray:users];

                SObject *mutualFriends = [SObject objectCollectionWithHandler:self];

                for (SUserData *sUserData in friends) {

                    if ([followers containsObject:sUserData.objectId]) {
                        [mutualFriends addSubObject:sUserData];
                    }


                }

                [operation complete:mutualFriends];

            }                                  errorBlock:^(NSError *error) {

                [operation completeWithError:[self errorWithError:error]];
            }];

        }];

    }];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        self.failureCallback([ISSocial errorWithCode:ISSocialErrorUserCanceled sourseError:nil userInfo:nil]);
    }
    else {
        self.successCallback(self.accounts[(NSUInteger) buttonIndex]);
    }
}


@end