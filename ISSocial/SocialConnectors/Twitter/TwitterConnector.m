//
//

#import "SUserData.h"
#import "TwitterConnector.h"
#import "ISSocial.h"
#import "ISSAuthorisationInfo.h"
#import "YATTwitterHelper.h"
#import "TWAPIManager.h"
#import "MultiImage.h"
#import "SInvitation.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>


#define NSErrorFromString(cd, msg) [NSError errorWithDomain:@"TwitterHelper" code:cd userInfo:@{@"NSLocalizedRecoverySuggestion": msg}]
#define NoAccountFoundError         NSErrorFromString(1, @"You must add a Twitter account in settings before using it")
#define AccessDeniedError           NSErrorFromString(2, @"You must allow Twitter access your account details")
#define UserCancelsError            NSErrorFromString(3, @"User cancelled operation")


@interface TwitterConnector () <UIActionSheetDelegate>
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) ACAccount *account;
@property(nonatomic, copy) NSString *secret;
@property(nonatomic, copy) NSString *token;

@property(nonatomic, strong) TWAPIManager *apiManager;
@property(nonatomic, strong) NSArray *accounts;
@property(nonatomic, copy) AuthSuccessCallback successCallback;
@property(nonatomic, copy) FailureCallback failureCallback;

@property(nonatomic, strong) id tokenSecret;
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

    _apiManager = [TWAPIManager new];
    _apiManager.consumerKey = settings[@"AppKey"];
    _apiManager.consumerSecret = settings[@"AppSecret"];
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
    token.userId = self.currentUserData.objectId;

    return token;
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self reverseAuthWithSuccess:^(NSDictionary *data) {

            self.token = data[@"oauth_token"];
            self.tokenSecret = data[@"oauth_token_secret"];

            [self updateUserDataWithOperation:operation];

        }                    failure:^(NSError *error) {

            NSLog(@"error = %@", error);

            [operation completeWithFailure];
        }];

    }];
}

- (void)updateUserDataWithOperation:(SocialConnectorOperation *)operation
{
    // Now make an authenticated request to our endpoint
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"include_entities"] = @"1";
    
    [self GET:@"account/verify_credentials" parameters:params operation:operation processor:^(NSDictionary * info) {
        SUserData *userData = [self userDataWithResponse:info];
        self.currentUserData = userData;
        _loggedIn = YES;
        [operation complete:[SObject successful]];
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


- (BOOL)isLoggedIn
{
    return _loggedIn;
}


- (void)authWithSuccess:(AuthSuccessCallback)onSuccess failure:(FailureCallback)onError
{
    self.successCallback = onSuccess;
    self.failureCallback = onError;

    if (![TWAPIManager isLocalTwitterAccountAvailable]) {
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
                newSelf.successCallback(self.accounts[0]);
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

- (void)reverseAuthWithSuccess:(ReverseAuthSuccessCallback)onSuccess failure:(FailureCallback)onError
{
    [self authWithSuccess:^(ACAccount *account) {
        self.account = account;
        [self.apiManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
            if (responseData) {
                NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"Twitter Reverse Auth Response: %@", responseStr);

                NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
                NSMutableDictionary *data = [NSMutableDictionary new];

                for (NSString *part in parts) {
                    NSArray *field = [part componentsSeparatedByString:@"="];
                    [data setValue:field[1] forKey:field[0]];
                }

                if (onSuccess) {
                    onSuccess(data);
                }
            }
            else {
                NSLog(@"Twitter Reverse Auth process failed. %@\n", [error localizedDescription]);
                if (onError) {
                    onError(error);
                }
            }
        }];
    }             failure:onError];
}

- (void)GET:(NSString *)path
          parameters:(NSDictionary *)parameters
           operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id))processor
{
    return [self simpleMethod:TWRequestMethodGET path:path parameters:parameters operation:operation processor:processor];
}

- (void)POST:(NSString *)path
       parameters:(NSDictionary *)parameters
        operation:(SocialConnectorOperation *)operation
        processor:(void (^)(id))processor
{
    return [self simpleMethod:TWRequestMethodPOST path:path parameters:parameters operation:operation processor:processor];
}

- (void)simpleMethod:(TWRequestMethod)method
                path:(NSString*)path
          parameters:(NSDictionary *)parameters
           operation:(SocialConnectorOperation *)operation
           processor:(void (^)(id))processor
{
    //  The endpoint that we wish to call
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/%@.json", path]];

    //  Build the request with our parameter
    TWRequest *request = [[TWRequest alloc] initWithURL:url
                                             parameters:parameters
                                          requestMethod:(TWRequestMethod) method];

    // Attach the account object to this request
    [request setAccount:self.account];

    [request performRequestWithHandler:
            ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (!responseData) {
            // inspect the contents of error
            NSLog(@"%@", error);
            [operation completeWithError:error];
        }
        else {
            NSError *jsonError;
            NSDictionary *info =
                    [NSJSONSerialization JSONObjectWithData:responseData
                                                    options:NSJSONReadingMutableLeaves
                                                      error:&jsonError];
            if (info) {
                // at this point, we have an object that we can parse
                NSLog(@"%@", info);

                processor(info);
            }
            else {
                // inspect the contents of jsonError
                NSLog(@"%@", jsonError);
                [operation completeWithError:jsonError];
            }
        }
    }];
}


- (SObject *)sendInvitation:(SInvitation *)invitation completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:invitation completion:completion processor:^(SocialConnectorOperation *operation) {

        // Now make an authenticated request to our endpoint
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        parameters[@"user_id"] = invitation.user.objectId;
        parameters[@"text"] = invitation.message;

        [self POST:@"direct_messages/new" parameters:parameters operation:operation processor:^(NSDictionary *response) {


            [operation complete:[SObject successful]];
        }];
    }];

}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        // Now make an authenticated request to our endpoint
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

        [self GET:@"friends/list" parameters:parameters operation:operation processor:^(NSDictionary *response) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            NSArray *users = response[@"users"];

            for (NSDictionary *user in users) {

                SUserData *userData =[self userDataWithResponse:user];

                [result addSubObject:userData];
            }

            [operation complete:result];
        }];
    }];



}


#pragma mark - UIActionSheetDelgate

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