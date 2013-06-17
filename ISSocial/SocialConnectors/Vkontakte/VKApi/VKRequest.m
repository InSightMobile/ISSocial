//
//  VKRequest.m
//  socials
//

#import "VKRequest.h"
#import "VKSession.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "NSObject+BlocksKit.h"

@interface VKRequest ()
@property(nonatomic, copy) NSString *method;
@property(nonatomic, copy) NSDictionary *parameters;
@property(nonatomic, strong) VKSession *session;
@property(nonatomic, copy) NSString *url;
@end

@implementation VKRequest
+ (VKRequest *)requestMethod:(NSString *)method parameters:(NSDictionary *)parameters
{
    VKRequest *req = [[VKRequest alloc] init];
    req.method = method;
    req.session = [VKSession activeSession];
    req.parameters = parameters;
    return req;
}

+ (VKRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters
{
    VKRequest *req = [[VKRequest alloc] init];
    req.url = url;
    req.session = [VKSession activeSession];
    req.parameters = parameters;
    return req;
}

- (VKRequestOperation *)startWithCompletionHandler:(VKRequestHandler)completion
{
    return [self startWithCompletionHandler:completion retries:0];
}

- (VKRequestOperation *)startWithCompletionHandler:(VKRequestHandler)completion retries:(int)retries
{
    static const int kMaxSeesionRetries = 3;

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_parameters];


    NSString *url = _url;
    if (!url) {
        url = [@"method/" stringByAppendingString:_method];
        // add default params if needed
        if (_session.accessToken)
            [params setObject:_session.accessToken forKey:@"access_token"];
    }

    NSMutableURLRequest *req = [_session.client requestWithMethod:@"POST" path:url parameters:params];
    req.cachePolicy = NSURLCacheStorageNotAllowed;

    AFHTTPRequestOperation *op =
            [_session.client HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
                id response = [responseObject objectForKey:@"response"];

                if (response) {
                    completion(operation, response, nil);
                }
                else {
                    id errorData = [responseObject objectForKey:@"error"];
                    if (errorData) {

                        NSLog(@"errorData = %@", errorData);

                        int code = [errorData[@"error_code"] intValue];

                        if (code == 5 && retries < kMaxSeesionRetries) {
                            // restore session
                            [[VKSession activeSession] reopenSessionWithCompletionHandler:^(VKSession *session, VKSessionState status, NSError *error) {
                                if (status == VKSessionStateOpen) {

                                    [self startWithCompletionHandler:completion retries:retries + 1];
                                }
                                else {
                                    NSError *error =
                                            [[NSError alloc] initWithDomain:@"VK" code:code
                                                                   userInfo:@{NSLocalizedDescriptionKey : errorData[@"error_msg"]}];

                                    completion(operation, nil, error);
                                }
                            }];
                            return;
                        }
                        else if (code == 6) {
                            [self performBlock:^(id sender) {
                                [self startWithCompletionHandler:completion retries:retries];
                            }       afterDelay:1.01];
                            return;
                        }

                        NSError *error =
                                [[NSError alloc] initWithDomain:@"VK" code:code
                                                       userInfo:@{NSLocalizedDescriptionKey : errorData[@"error_msg"]}];

                        completion(operation, nil, error);
                    }
                    else {
                        completion(operation, responseObject, nil);
                    }
                }
            }                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                completion(operation, nil, error);
            }];
    [_session.client enqueueHTTPRequestOperation:op];

    return op;
}

@end
