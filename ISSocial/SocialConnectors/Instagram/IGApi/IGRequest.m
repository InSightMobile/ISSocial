//
// 

//
//  IGRequest.m
//  socials
//
//  Created by yar on 20.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "IGRequest.h"
#import "IGSession.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

@interface IGRequest ()
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSDictionary *parameters;
@property(nonatomic, strong) IGSession *session;
@property(nonatomic, copy) NSString *url;
@end

@implementation IGRequest
{
    NSString *_method;
}
+ (IGRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    IGRequest *req = [[IGRequest alloc] init];
    req.path = path;
    req.method = method;
    req.session = [IGSession activeSession];
    req.parameters = parameters;
    return req;
}

- (IGRequestOperation *)startWithCompletionHandler:(IGRequestHandler)completion
{
    return [self startWithCompletionHandler:completion retries:0];
}

- (IGRequestOperation *)startWithCompletionHandler:(IGRequestHandler)completion retries:(int)retries
{
    static const int kMaxSeesionRetries = 3;

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_parameters];

    // add default params
    if (_session.accessToken)
        [params setObject:_session.accessToken forKey:@"access_token"];
    if (_session.clientId)
        [params setObject:_session.clientId forKey:@"client_id"];

    NSMutableURLRequest *req = [_session.client requestWithMethod:_method path:_path parameters:params];

    AFHTTPRequestOperation *op =
            [_session.client HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
                id data = [responseObject objectForKey:@"data"];
                id error = [responseObject objectForKey:@"error"];

                if (error) {
                    completion(operation, data, [NSError errorWithDomain:@"IGApi" code:100 userInfo:error]);
                }
                else if (data) {
                    completion(operation, responseObject, nil);
                }
                else {
                    completion(responseObject, responseObject, nil);
                }
            }                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                completion(operation, nil, error);
            }];
    [_session.client enqueueHTTPRequestOperation:op];

    return op;
}

@end
