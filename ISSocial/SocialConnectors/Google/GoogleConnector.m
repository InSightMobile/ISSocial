//
//

#import <ISSocial/SObject.h>
#import <ISSocial/ISSocial+Errors.h>
#import "SUserData.h"
#import "ISSAuthorisationInfo.h"
#import "GoogleConnector.h"
#import "GIDSignIn.h"
#import "GIDGoogleUser.h"
#import "GIDAuthentication.h"
#import "GIDProfileData.h"
#import "MultiImage.h"

@interface GoogleConnector () <GIDSignInDelegate>

@property(nonatomic, strong) GIDSignIn *signIn;
@property(nonatomic, copy) SObjectCompletionBlock openSession;
@property(nonatomic) BOOL loggedIn;
@property(nonatomic, strong) GPSession *session;
@property(nonatomic, strong) NSString *clientID;
@property(nonatomic, strong) NSArray *permissions;
@property(nonatomic, strong) SocialConnectorOperation *signInOperation;
@end

@implementation GoogleConnector {
    SUserData *_currentUserData;
    ISSAuthorisationInfo *_authorizationInfo;
}

+ (GoogleConnector *)instance {
    static GoogleConnector *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

+ (NSString *)connectorCode {
    return ISSocialConnectorIdGoogle;
}

- (void)setupSettings:(NSDictionary *)settings {
    [super setupSettings:settings];

    self.clientID = settings[ISSClientIDKey];
    self.permissions = settings[ISSPermissionsKey];
}

- (GIDSignIn *)signIn {
    if (_signIn) {
        return _signIn;
    }
    _signIn = [GIDSignIn sharedInstance];
    self.signIn.delegate = self;
    self.signIn.allowsSignInWithWebView = NO;
    return _signIn;
}

- (BOOL)handleDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self openSession:nil silent:YES completion:nil];
    return NO;
}


- (SObject *)closeSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        _currentUserData = nil;
        //[[GPSession activeSession] closeSession];
        [operation completed];
    }];
}

- (ISSAuthorisationInfo *)authorizationInfo {
    return _authorizationInfo;
}

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {

    if (error) {
        NSLog(@"error = %@", error);
        if([error.domain isEqualToString:kGIDSignInErrorDomain]) {
            if (error.code == kGIDSignInErrorCodeCanceled) {
                error = [ISSocial errorWithCode:ISSocialErrorUserCanceled sourseError:error userInfo:nil];
            }
            else if (error.code == kGIDSignInErrorCodeHasNoAuthInKeychain) {
                error = [ISSocial errorWithCode:ISSocialErrorStoredLoginAbsent sourseError:error userInfo:nil];
            }
            else if (error.code == kGIDSignInErrorCodeKeychain) {
                [signIn signOut];
                [signIn signIn];
            }
        }

        [self.signInOperation completeWithError:error];
        self.signInOperation = nil;
        self.loggedIn = NO;
        return;
    }
    if (!user) {
        [self.signInOperation completeWithFailure];
        self.signInOperation = nil;
        self.loggedIn = NO;
        return;
    }

    _authorizationInfo = [ISSAuthorisationInfo new];
    _authorizationInfo.handler = self;
    _authorizationInfo.accessToken = user.authentication.idToken;
    _authorizationInfo.userId = user.userID;

    _currentUserData = [[SUserData alloc] initWithHandler:self];
    _currentUserData.objectId = user.userID;
    _currentUserData.userName = user.profile.name;
    _currentUserData.userEmail = user.profile.email;

    self.loggedIn = YES;
    if (user.profile.hasImage) {
        _currentUserData.userPicture = [[MultiImage alloc] initWithURL:[user.profile imageURLWithDimension:200]];
    }

    [self.signInOperation complete:_currentUserData];
    self.signInOperation = nil;
}

- (void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    self.loggedIn = NO;
    if (error) {
        [self.signInOperation completeWithError:error];
    }
    else {
        [self.signInOperation completeWithFailure];
    }
    self.signInOperation = nil;
}


- (SObject *)openSession:(SObject *)params silent:(BOOL)silent completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        self.signInOperation = operation;
        if (silent) {
            [self.signIn signInSilently];
        }
        else {
            [self.signIn signIn];
        }
    }];
}

- (SObject *)closeSessionAndClearCredentials:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        self.loggedIn = NO;
        [self.signIn signOut];
    }];
}

- (SObject *)openSession:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self openSession:params silent:NO completion:completion];
}

- (BOOL)isLoggedIn {
    return _loggedIn;
}

- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        bool myself = NO;
        NSString *userId = params.objectId;
        if (userId.length == 0 || [userId isEqualToString:@"me"]) {
            myself = YES;
        }
        if (myself) {
            if (self.currentUserData) {
                [operation complete:self.currentUserData];
                return;
            }
        }
        [operation completeWithFailure];
    }];
}

- (SUserData *)currentUserData {
    return _currentUserData;
}


//- (void)executeQuery:(id <GTLQueryProtocol>)query operation:(SocialConnectorOperation *)operation
//           processor:(void (^)(id object))handler {
//    [[GPSession activeSession].plusService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
//            id object, NSError *error) {
//        if (error) {
//            GTMLoggerError(@"Error: %@", error);
//            //peopleStatus_.text = [NSString stringWithFormat:@"Status: Error: %@", error];
//            [operation completeWithError:error];
//        }
//        else {
//
//            handler(object);
//        }
//    }];
//}

//- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion {
//    bool myself = NO;
//    NSString *userId = params.objectId;
//    if (userId.length == 0 || [userId isEqualToString:@"me"]) {
//        myself = YES;
//    }
//
//    if (myself) {
//        if (self.currentUserData) {
//            completion(self.currentUserData);
//            return self.currentUserData;
//        }
//        else {
//            return [self updateProfile:params completion:completion];
//        }
//    }
//    else {
//        return [self readProfile:params userID:userId completion:completion];
//    }
//}
//
//- (SObject *)readProfile:(SObject *)params userID:(NSString *)userID completion:(SObjectCompletionBlock)completion {
//    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
//        GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:userID];
//        [self executeQuery:query operation:operation processor:^(GTLPlusPerson *person) {
//
//            SUserData *user = [[SUserData alloc] initWithHandler:self];
//            user.objectId = person.identifier;
//            user.userName = person.displayName;
//
//            NSArray *emails = person.emails;
//            NSString *email = nil;
//            for (GTLPlusPersonEmailsItem *item in emails) {
//                if ([item.type isEqualToString:@"account"]) {
//                    email = item.value;
//                }
//            }
//            if (!email) {
//                email = [(GTLPlusPersonEmailsItem * ) [
//                person.emails
//                firstObject] value];
//            }
//            user.userEmail = email;
//
//            if ([person.gender isEqualToString:@"male"]) {
//                user.userGender = @(ISSMaleUserGender);
//            }
//            else if ([person.gender isEqualToString:@"female"]) {
//                user.userGender = @(ISSFemaleUserGender);
//            }
//
//            NSString *userImage = person.image.url;
//            user.userPicture = [[MultiImage alloc] initWithURL:userImage.URLValue];
//
//            [operation complete:user];
//        }];
//    }];
//}
//
//- (SObject *)updateProfile:(SObject *)params completion:(SObjectCompletionBlock)completion {
//    return [self readProfile:params userID:@"me" completion:^(SObject *result) {
//        self->_currentUserData = (SUserData *) result;
//        NSLog(@"result = %@", result);
//        completion(result);
//    }];
//}
//
//- (SUserData *)currentUserData {
//    return _currentUserData;
//}
//
//- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion {
//    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
//        GTLQueryPlus *query =
//                [GTLQueryPlus queryForPeopleListWithUserId:@"me"
//                                                collection:kGTLPlusCollectionVisible];
//
//        [self executeQuery:query operation:operation processor:^(GTLPlusPeopleFeed *peopleFeed) {
//
//            SObject *result = [SObject objectCollectionWithHandler:self];
//
//            for (GTLPlusPerson *person in peopleFeed.items) {
//                SUserData *user = [[SUserData alloc] initWithHandler:self];
//                user.objectId = person.identifier;
//                user.userName = person.displayName;
//
//                NSString *userImage = person.image.url;
//                user.userPicture = [[MultiImage alloc] initWithURL:userImage.URLValue];
//
//                [result addSubObject:user];
//            }
//
//            [operation complete:result];
//        }];
//    }];
//}

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}


- (void)handleDidBecomeActive {
    [super handleDidBecomeActive];
    if (self.signInOperation) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.signInOperation) {
                [self.signInOperation completeWithError:[ISSocial errorWithCode:ISSocialErrorUserCanceled
                                                                    sourseError:nil
                                                                       userInfo:nil]];
                self.signInOperation = nil;
            }
        });
    }
}


@end
