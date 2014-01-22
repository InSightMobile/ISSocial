//
//

#import "ISSVKSession.h"
#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"
#import "WebLoginController.h"
#import "NSString+ValueConvertion.h"
#import "ISSocial.h"
#import "ISSocial+Errors.h"
#import "NSObject+PerformBlockInBackground.h"

@interface ISSVKSession () <WebLoginControllerDelegate>

@property(nonatomic, copy) VKSessionStateHandler statusHandler;

@property(nonatomic, strong, readwrite) NSString *accessToken;
@property(nonatomic, copy, readwrite) NSString *userId;
@property(nonatomic, copy) NSArray *currentPermissions;
@property(nonatomic) BOOL invalidToken;
@end

@implementation ISSVKSession
{
    BOOL _externalAuthorization;
}

+ (ISSVKSession *)activeSession
{
    static ISSVKSession *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObjects:@"text/html", nil]];
        }
    }

    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://api.vk.com/"]];
        [self.client setDefaultHeader:@"Accept" value:@"application/json"];
        [self.client registerHTTPOperationClass:[AFJSONRequestOperation class]];

        _externalAuthorization = NO;
    }
    return self;
}

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(VKSessionStateHandler)handler
{
    [[self activeSession] openWithPermissions:permissions completionHandler:handler];
}

- (void)reopenSessionWithCompletionHandler:(VKSessionStateHandler)handler
{
    self.invalidToken = YES;
    [self openWithPermissions:self.currentPermissions completionHandler:handler];
}

- (NSString *)redirectURI
{
    if (_externalAuthorization) {
        return [NSString stringWithFormat:@"vk%@://authorize", self.clientId];
    }
    else {
        return @"https://oauth.vk.com/blank.html";
    }
}

- (void)openWithPermissions:(NSArray *)permissions completionHandler:(VKSessionStateHandler)handler
{
    self.currentPermissions = permissions;
    if (!self.clientId) {
        NSString *appID = [[NSBundle mainBundle].infoDictionary objectForKey:@"VkontakteAppID"];
        self.clientId = appID;
    }

    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"VKAccessToken"];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"VKUserId"];
    NSInteger expires = [[NSUserDefaults standardUserDefaults] integerForKey:@"VKAccessExpires"];

    if (!self.invalidToken && accessToken && userId &&
            [[NSDate dateWithTimeIntervalSince1970:expires] timeIntervalSinceDate:[NSDate date]] > 0) {
        self.accessToken = accessToken;
        self.userId = userId;

        return handler(self, ISSVKSessionStateOpen, nil);
    }
    else {
        NSString *permissionsStr = @"wall";
        if (permissions.count) {
                    permissionsStr = [permissions componentsJoinedByString:@","];
        }

        NSString *authLink =
                [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&scope=%@&redirect_uri=%@&display=touch&response_type=token", self.clientId, permissionsStr, self.redirectURI];

        NSURL *url = [NSURL URLWithString:authLink];

        if (_externalAuthorization) {
            [[UIApplication sharedApplication] openURL:url];
        }
        else {
            WebLoginController *controller = [WebLoginController loginController];

            [self performBlock:^(id sender)
            {
                self.statusHandler = handler;
                controller.delegate = self;
                [controller presentWithRequest:[NSURLRequest requestWithURL:url]];
            }       afterDelay:0.1];
        }
    }
}

- (NSString *)stringBetweenString:(NSString *)start
                        andString:(NSString *)end
                      innerString:(NSString *)str
{
    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString *result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

- (WebLoginLoadingTypes)webLogin:(WebLoginController *)webLogin loadingTypeForRequest:(NSURLRequest *)request
{
    if ([self handleURL:request.URL]) {
        [webLogin dismiss];
        return WebLoginDoNotLoad;
    }
    return WebLoginLoadVisible;
}

- (void)webLoginDidCanceled:(WebLoginController *)controller
{
    if (_statusHandler) {
        self.statusHandler(self, ISSVKSessionStateClosed, nil);
        self.statusHandler = nil;
    }
}

- (BOOL)handleURL:(NSURL *)url
{
    NSLog(@"url = %@", url);
    if ([url.absoluteString hasPrefix:self.redirectURI]) {

        NSDictionary *params = [url.fragment exclodeURLQuery];

        NSString *accessToken = params[@"access_token"];
        NSString *error = params[@"error"];
        NSString *userId = params[@"user_id"];
        NSString *expiresIn = params[@"expires_in"];

        NSTimeInterval expires = [[NSDate date] timeIntervalSince1970] + expiresIn.intValue;

        if (accessToken.length) {
            [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"VKUserId"];
            [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"VKAccessToken"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"VKAccessTokenDate"];
            [[NSUserDefaults standardUserDefaults] setDouble:expires forKey:@"VKAccessExpires"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            self.invalidToken = NO;

            self.accessToken = accessToken;
            self.userId = userId;

            if (_statusHandler) {
                self.state = ISSVKSessionStateOpen;
                self.statusHandler(self, ISSVKSessionStateOpen, nil);
                self.statusHandler = nil;
            }
            return YES;
        }
        else if (error.length) {

            NSLog(@"Error: %@", url.absoluteString);

            NSError *error = nil;

            if ([params[@"error_reason"] isEqualToString:@"user_denied"]) {
                error = [ISSocial errorWithCode:ISSocialErrorUserCanceled sourseError:nil userInfo:params];
            }

            self.state = ISSVKSessionStateClosed;
            if (_statusHandler) {
                self.statusHandler(self, ISSVKSessionStateClosed, error);
                self.statusHandler = nil;
            }

            return YES;
        }
    }
    return NO;
}

- (void)webLogin:(WebLoginController *)webLogin didFinishPageLoad:(NSURLRequest *)request
{

}

+ (VKRequestOperation *)uploadDataTo:(NSString *)uploadURL fromURL:(NSURL *)fileUrl name:(NSString *)name fileName:(NSString *)filename mime:(NSString *)mime handler:(VKRequestHandler)handler
{
    AFHTTPClient *client = [ISSVKSession activeSession].client;

    NSMutableURLRequest *request =
            [client multipartFormRequestWithMethod:@"POST" path:uploadURL parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData> formData)
            {

                NSString *mimeType = mime;
                if (!mimeType) {
                    mimeType = @"application/octet-stream";
                }

                NSError *error = nil;

                [formData appendPartWithFileURL:fileUrl
                                           name:name ? name : @"file"
                                       fileName:filename
                                       mimeType:mimeType
                                          error:&error];
            }];

    NSLog(@"request = %@", request);

    AFHTTPRequestOperation *op =
            [client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject)
            {

                NSLog(@"responseObject = %@", responseObject);
                handler(operation, responseObject, nil);

            }                               failure:^(AFHTTPRequestOperation *operation, NSError *error)
            {

                handler(operation, nil, error);

            }];
    [op start];
    return op;
}

- (void)closeAndClearTokenInformation
{
    self.accessToken = nil;
    self.userId = nil;
    self.state = ISSVKSessionStateClosed;
    [self clearCookies];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKUserId"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessTokenDate"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VKAccessExpires"];
    [[NSUserDefaults standardUserDefaults] synchronize];

}

+ (void)sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData handler:(VKRequestHandler)handler
{
    AFHTTPClient *client = [ISSVKSession activeSession].client;

    NSMutableURLRequest *requestM =
            [client multipartFormRequestWithMethod:@"POST" path:reqURl parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData> formData)
            {

                [formData appendPartWithFileData:imageData name:@"photo" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
            }];

    NSLog(@"requestM = %@", requestM);

    AFHTTPRequestOperation *op =
            [client HTTPRequestOperationWithRequest:requestM success:^(AFHTTPRequestOperation *operation, id responseObject)
            {

                NSLog(@"responseObject = %@", responseObject);
                handler(operation, responseObject, nil);

            }                               failure:^(AFHTTPRequestOperation *operation, NSError *error)
            {

                handler(operation, nil, error);

            }];
    [op start];
}

- (void)clearCookies
{

    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *vkCookies1 = [cookies cookiesForURL:
            [NSURL URLWithString:@"http://api.vk.com"]];
    NSArray *vkCookies2 = [cookies cookiesForURL:
            [NSURL URLWithString:@"http://vk.com"]];
    NSArray *vkCookies3 = [cookies cookiesForURL:
            [NSURL URLWithString:@"http://login.vk.com"]];
    NSArray *vkCookies4 = [cookies cookiesForURL:
            [NSURL URLWithString:@"http://oauth.vk.com"]];

    for (NSHTTPCookie *cookie in vkCookies1) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies2) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies3) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies4) {
        [cookies deleteCookie:cookie];
    }
}

@end
