//
//  VKRequest.m
//  socials
//

#import "ISSVKRequest.h"
#import "ISSVKSession.h"
#import "AFHTTPRequestOperation.h"
#import "NSObject+PerformBlockInBackground.h"

@interface ISSVKRequest ()
@property(nonatomic, copy) NSString *method;
@property(nonatomic, copy) NSDictionary *parameters;
@property(nonatomic, strong) ISSVKSession *session;
@property(nonatomic, copy) NSString *url;
@end

@implementation ISSVKRequest
+ (ISSVKRequest *)requestMethod:(NSString *)method parameters:(NSDictionary *)parameters
{
    ISSVKRequest *req = [[ISSVKRequest alloc] init];
    req.method = method;
    req.session = [ISSVKSession activeSession];
    req.parameters = parameters;
    return req;
}

+ (ISSVKRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters
{
    ISSVKRequest *req = [[ISSVKRequest alloc] init];
    req.url = url;
    req.session = [ISSVKSession activeSession];
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
        if (_session.accessToken) {
            [params setObject:_session.accessToken forKey:@"access_token"];
        }
        [params setObject:@"3.0" forKey:@"v"];
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
                            [[ISSVKSession activeSession] reopenSessionWithCompletionHandler:^(ISSVKSession *session, ISSVKSessionState status, NSError *error) {
                                if (status == ISSVKSessionStateOpen) {

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
