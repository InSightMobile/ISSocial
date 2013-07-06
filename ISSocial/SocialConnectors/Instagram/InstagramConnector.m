//
// 



#import "InstagramConnector.h"
#import "IGSession.h"
#import "IGRequest.h"
#import "SUserData.h"


@implementation InstagramConnector
{

}

+ (InstagramConnector *)instance
{
    static InstagramConnector *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (NSString *)connectorCode
{
    return @"Ig";
}

- (NSString *)connectorName
{
    return NSLocalizedString(@"Instagram", @"Instagram");
}

- (NSInteger)connectorPriority
{
    return 4;
}

- (NSInteger)connectorDisplayPriority
{
    return 4;
}


- (SObject *)openSession:(SObject *)params completion:(CompletionBlock)completion
{
    [IGSession openActiveSessionWithPermissions:@[@"comments", @"likes"] completionHandler:^(IGSession *session, IGSessionState status, NSError *error) {
        switch (status) {
            case IGSessionStateOpen: {
                [SObject successful:completion];
                self.loggedIn = YES;
            }
                break;
            case IGSessionStateClosed:
            case IGSessionStateClosedLoginFailed: {
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

- (void)simpleRequest:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor
{
    [[IGRequest requestWithMethod:method path:path parameters:parameters] startWithCompletionHandler:^(IGRequestOperation *connection, id response, NSError *error) {
        if (error) {
            NSLog(@"error = %@", error);
            [operation completeWithError:error];
        }
        else {
            processor(response);
        }
    }];
}


- (SUserData *)dataForUserId:(NSString *)userId
{
    SUserData *data = [[SUserData alloc] initWithHandler:self];
    data.objectId = userId;
    return data;
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [[IGSession activeSession] handleURL:url];
}

@end