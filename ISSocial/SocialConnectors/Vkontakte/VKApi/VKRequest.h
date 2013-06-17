//
//  VKRequest.h
//  socials
//
//  Created by yar on 20.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPClient;
@class AFHTTPRequestOperation;
@class VKSession;

static const int kVKMaxRequestsPerSeconds = 3;
typedef AFHTTPRequestOperation VKRequestOperation;

typedef void (^VKRequestHandler)(VKRequestOperation *connection,
        id result,
        NSError *error);

@interface VKRequest : NSObject

+ (VKRequest *)requestMethod:(NSString *)method parameters:(NSDictionary *)parameters;

+ (VKRequest *)requestWithURL:(NSString *)url parameters:(NSDictionary *)parameters;

- (VKRequestOperation *)startWithCompletionHandler:(VKRequestHandler)completion;
@end
