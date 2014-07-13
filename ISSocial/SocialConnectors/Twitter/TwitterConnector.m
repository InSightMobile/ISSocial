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


typedef NS_ENUM(NSInteger, TrwitterErrors)
{
    TwitterErrorNoAccount = 1,
    TwitterErrorAccessDenied,
    TwitterErrorUserCancels,
};

#define NSErrorFromString(cd, msg) [NSError errorWithDomain:@"TwitterHelper" code:cd userInfo:@{@"NSLocalizedRecoverySuggestion": msg}]
#define NoAccountFoundError         NSErrorFromString(TwitterErrorNoAccount, @"You must add a Twitter account in settings before using it")
#define AccessDeniedError           NSErrorFromString(TwitterErrorAccessDenied, @"You must allow Twitter access your account details")
#define UserCancelsError            NSErrorFromString(TwitterErrorUserCancels, @"User cancelled operation")


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

        STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                                  consumerKey:self.consumerKey
                                                               consumerSecret:self.consumerSecret];

        [self authWithSuccess:^(ACAccount *account) {

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
        }             failure:^(NSError *error){

            if (error.code == TwitterErrorNoAccount) {

                NSString *callback = [self systemCallbackURL];

                [twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {

                    self.twitterAPI = twitter;
                    self.authorizationOperation = operation;
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

- (void)authWithSuccess:(void (^)(ACAccount *account))onSuccess failure:(void (^)(NSError *error))onError
{
    self.successCallback = onSuccess;
    self.failureCallback = onError;

    if (![self isLocalTwitterAccountAvailable]) {
        if (onError) {
            onError(NoAccountFoundError);
        }
        return;
    }

    ACAccountStore *accountStore = [ACAccountStore new];
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    __weak __typeof(self) weakSelf = self;
    [accountStore requestAccessToAccountsWithType:twitterType options:NULL completion:^(BOOL granted, NSError *error) {
        __unsafe_unretained __typeof(self) newSelf = weakSelf;

        if (granted) {
            newSelf.accounts = [accountStore accountsWithAccountType:twitterType];
            if (newSelf.accounts.count == 1) {
                onSuccess(self.accounts[0]);
            }
            else {
                UIActionSheet *sheet = [[UIActionSheet alloc] init];

                for (ACAccount *acct in self.accounts) {
                    [sheet addButtonWithTitle:acct.username];
                }

                sheet.delegate = newSelf;
                sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [sheet showInView:[UIApplication sharedApplication].keyWindow];
                });
            }
        }
        else {
            if (onError) {
                onError(AccessDeniedError);
            }
        }
    }];
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


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        self.failureCallback(UserCancelsError);
    }
    else {
        self.successCallback(self.accounts[buttonIndex]);
    }
}


@end