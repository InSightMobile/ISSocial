//
//

#import "GooglePlusConnector.h"
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>
#import "GPSession.h"
#import "SUserData.h"
#import "MultiImage.h"
#import "NSString+TypeSafety.h"
#import "ISSocial.h"
#import "ISSAuthorisationInfo.h"

@interface GooglePlusConnector ()
@property(nonatomic, strong) GPPSignIn *signIn;
@property(nonatomic, copy) SObjectCompletionBlock openSession;
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) GPSession *session;
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

+ (NSString *)connectorCode
{
    return ISSocialConnectorIdGooglePlus;
}


- (NSInteger)connectorPriority
{
    return 2;
}

- (NSInteger)connectorDisplayPriority
{
    return 2;
}


- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    [GPSession openActiveSessionWithPermissions:nil completionHandler:^(GPSession *session, GPSessionState status, NSError *error) {

        switch (status) {
            case GPSessionStateOpen: {
                [SObject successful:completion];
                self.loggedIn = YES;
                self.session = session;
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

- (ISSAuthorisationInfo *)authorizatioInfo
{
    ISSAuthorisationInfo *token = [ISSAuthorisationInfo new];
    token.handler = self;
    token.accessToken = self.session.accessToken;
    token.userId = self.session.userID;
    return token;
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
                user.userPicture =
                        [[MultiImage alloc] initWithURL:userImage.URLValue];

                [result addSubObject:user];
            }

            [operation complete:result];
        }];
    }];
}


@end
