//
// 

#import "IGSession.h"
#import "NSString+ValueConvertion.h"
#import "AFHTTPSessionManager.h"
#import "AFHTTPRequestOperationManager.h"

@interface IGSession ()
@property(nonatomic, copy) NSString *clientId;
@property(nonatomic, copy, readwrite) NSString *accessToken;
@property(nonatomic, copy) IGSessionStateHandler statusHandler;
@end

@implementation IGSession {

    BOOL _externalAuthorization;
}

+ (IGSession *)activeSession {
    static IGSession *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {

        self.client = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.instagram.com/v1/"]];

        self.client.responseSerializer = [[AFJSONResponseSerializer alloc] init];
        [self.client.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return self;
}


- (BOOL)handleURL:(NSURL *)url {
    if ([url.absoluteString hasPrefix:self.redirectURI]) {
        NSDictionary *params = [url.fragment explodeURLQuery];
        NSString *accessToken = params[@"access_token"];

        if (accessToken) {
            self.accessToken = accessToken;
            self.statusHandler(self, IGSessionStateOpen, nil);

        }
        else {
            self.statusHandler(self, IGSessionStateClosed, [NSError errorWithDomain:@"IGSession" code:1
                                                                           userInfo:@{NSLocalizedDescriptionKey : @"Authorization failed"}]);
        }
        return YES;
    }
    return NO;
}

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(IGSessionStateHandler)handler {
    [[self activeSession] openSessionWithPermissions:permissions completionHandler:handler];
}

- (NSString *)clientId {
    if (!_clientId) _clientId = NSBundle.mainBundle.infoDictionary[@"InstagramAppID"];
    return _clientId;
}

- (NSString *)redirectURI {
    return [NSString stringWithFormat:@"ig%@://authorize", self.clientId];
}

- (void)webLogin:(WebLoginController *)webLogin didFinishPageLoad:(NSURLRequest *)request {

}

- (WebLoginLoadingTypes)webLogin:(WebLoginController *)controller loadingTypeForRequest:(NSURLRequest *)request {
    if ([self handleURL:request.URL]) {
        [controller dismiss];
        return WebLoginDoNotLoad;
    }
    return WebLoginLoadVisible;
}

- (void)webLoginDidCanceled:(WebLoginController *)controller {
    if (_statusHandler) {
        self.statusHandler(self, IGSessionStateClosedLoginFailed, nil);
        self.statusHandler = nil;
    }
}


- (void)openSessionWithPermissions:(NSArray *)permissions completionHandler:(IGSessionStateHandler)handler {
    //self.currentPermissions = permissions;
    NSString *appID = self.clientId;

    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"IGAccessToken"];
    if (accessToken && NO) {
        self.accessToken = accessToken;

        return handler(self, IGSessionStateOpen, nil);
    }
    else {

        NSString *permissionsStr = @"basic";
        if (permissions.count)
            permissionsStr = [permissions componentsJoinedByString:@"+"];


        NSString *authLink =
                [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&scope=%@&redirect_uri=http://oauth.vk.com/blank.html&display=touch&response_type=token", appID, permissionsStr];

        NSString *redirectURI = [self redirectURI];

        authLink =
                [NSString stringWithFormat:@"https://instagram.com/oauth/authorize/?client_id=%@&redirect_uri=%@&scope=%@&response_type=token", appID, redirectURI, permissionsStr];


        self.statusHandler = handler;

        NSURL *authURL = [NSURL URLWithString:authLink];

        if (_externalAuthorization) {

            [[UIApplication sharedApplication] openURL:authURL];
        }
        else {
            WebLoginController *controller = [WebLoginController loginController];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC), dispatch_get_current_queue(), ^{


                controller.delegate = self;
                [controller presentWithRequest:[NSURLRequest requestWithURL:authURL]];

            });
        }
    }
}


@end