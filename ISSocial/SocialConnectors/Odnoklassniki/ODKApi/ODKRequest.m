//
//  ODKRequest.m
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "ODKRequest.h"
#import "Odnoklassniki.h"
#import "ODKSession.h"

@interface ODKRequest () <OKRequestDelegate>
@property(nonatomic, copy) NSString *method;
@property(nonatomic, strong) NSMutableDictionary *parameters;
@property(nonatomic, copy) NSString *httpMethod;
@property(nonatomic, strong) OKRequest *request;
@property(nonatomic, copy) ODKRequestHandler completion;
@end

@implementation ODKRequest
{
    __strong id _selfRetain;
}

+ (ODKRequest *)requestMethod:(NSString *)method parameters:(NSDictionary *)parameters
{
    ODKRequest *req = [[self alloc] init];

    req.method = method;
    req.parameters = [parameters mutableCopy];
    req.httpMethod = @"POST";

    return req;
}

- (void)request:(OKRequest *)request didLoad:(id)result
{
    if (_completion) {
        _completion(self, result, nil);
        self.completion = nil;
    }
    _selfRetain = nil;
}

- (void)request:(OKRequest *)request didFailWithError:(NSError *)error
{
    if(error.code == 102) {
        [[ODKSession activeSession] reopenSessionWithCompletionHandler:^(ODKSession *session, ODKSessionState status, NSError *error) {
            if(error) {
                _completion(self, nil, error);
                self.completion = nil;
            }
            else {
                [self.request load];
            }
        }];
        return;
    }

    if (_completion) {
        _completion(self, nil, error);
        self.completion = nil;
    }
    _selfRetain = nil;
}

- (NSURLConnection *)startWithCompletionHandler:(ODKRequestHandler)completion
{
    self.completion = completion;
    self.request = [OKRequest getRequestWithParams:_parameters httpMethod:_httpMethod delegate:self apiMethod:_method];

    _selfRetain = self;
    [_request load];
    return _request.connection;
}

- (void)cancel
{
    [_request.connection cancel];
}


@end
