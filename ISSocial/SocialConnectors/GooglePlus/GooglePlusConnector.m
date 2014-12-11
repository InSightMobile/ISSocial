//
//

#import <ISSocial/SObject.h>
#import "GooglePlusConnector.h"
#import "GooglePlus.h"
#import "GPSession.h"
#import "SUserData.h"
#import "MultiImage.h"
#import "NSString+TypeSafety.h"
#import "ISSocial.h"
#import "ISSAuthorisationInfo.h"
#import "GTLService.h"
#import "GTMLogger.h"
#import "GTLServicePlus.h"
#import "GTLQueryPlus.h"
#import "GTLPlusPerson.h"
#import "GTLPlusConstants.h"
#import "GTLPlusPeopleFeed.h"

@interface GooglePlusConnector ()
@property(nonatomic, strong) GPPSignIn *signIn;
@property(nonatomic, copy) SObjectCompletionBlock openSession;
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) GPSession *session;
@property(nonatomic, strong) NSString *clientID;
@property(nonatomic, strong) NSArray * permissions;
@end

@implementation GooglePlusConnector
{
    SUserData *_currentUserData;
}

+ (GooglePlusConnector *)instance
{
    static GooglePlusConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (NSString *)connectorCode
{
    return ISSocialConnectorIdGooglePlus;
}

- (void)setupSettings:(NSDictionary *)settings
{
    [super setupSettings:settings];

    self.clientID = settings[@"ClientID"];
    self.permissions = settings[@"Permissions"];
}

- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [[GPSession activeSession] closeSession];

        [operation completed];
    }];
}

- (ISSAuthorisationInfo *)authorizatioInfo
{
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = [GPSession activeSession].idToken;
    token.userId = [GPSession activeSession].userID;
    return token;
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [GPSession openActiveSessionWithClientID:self.clientID permissions:self.permissions completionHandler:^(GPSession *session, GPSessionState status, NSError *error) {

            switch (status) {
                case GPSessionStateOpen: {
                    self.loggedIn = YES;
                    self.session = session;
                    [self updateProfile:operation.object completion:^(id result){
                        [operation complete:[SObject successful]];
                    }];
                }
                    break;
                case GPSessionStateClosed:
                case GPSessionStateClosedLoginFailed: {
                    [SObject failed:completion];
                    [operation completeWithError:error];
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

- (SObject *)updateProfile:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
        [self executeQuery:query operation:operation processor:^(GTLPlusPerson *person) {

            SUserData *user = [[SUserData alloc] initWithHandler:self];
            user.objectId = person.identifier;
            user.userName = person.displayName;

            NSString *userImage = person.image.url;
            user.userPicture =
                    [[MultiImage alloc] initWithURL:userImage.URLValue];

            _currentUserData = user;

            [operation complete:_currentUserData];
        }];
    }];


}

- (SUserData *)currentUserData
{
    return _currentUserData;
}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
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
                user.userPicture = [[MultiImage alloc] initWithURL:userImage.URLValue];

                [result addSubObject:user];
            }

            [operation complete:result];
        }];
    }];
}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[GPSession activeSession] handleURL:url sourceApplication:sourceApplication annotation:annotation];
}


- (void)handleDidBecomeActive
{
    [super handleDidBecomeActive];
    [[GPSession activeSession] didActivated];
}


@end
