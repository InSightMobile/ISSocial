//
//  ODKRequest.h
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ODKRequest;

typedef void (^ODKRequestHandler)(ODKRequest *connection,
        id result,
        NSError *error);

@interface ODKRequest : NSObject

+ (ODKRequest *)requestMethod:(NSString *)method parameters:(NSDictionary *)parameters;

- (NSURLConnection *)startWithCompletionHandler:(ODKRequestHandler)completion;

- (void)cancel;

@end
