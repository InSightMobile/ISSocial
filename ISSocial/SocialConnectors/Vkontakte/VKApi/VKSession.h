//
//  VKSession.h
//  socials
//
//  Created by yar on 20.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKRequest.h"

@class AFHTTPClient;
@class VKSession;

typedef enum
{
    VKSessionStateOpen,
    VKSessionStateClosedLoginFailed,
    VKSessionStateClosed

} VKSessionState;

typedef void (^VKSessionStateHandler)(VKSession *session,
        VKSessionState status,
        NSError *error);

@interface VKSession : NSObject
@property(nonatomic, strong) AFHTTPClient *client;


@property(nonatomic, strong, readonly) NSString *accessToken;
@property(nonatomic, copy, readonly) NSString *userId;

@property(nonatomic, copy) NSString *clientId;

@property(nonatomic) VKSessionState state;

+ (VKSession *)activeSession;

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions completionHandler:(VKSessionStateHandler)handler;

- (void)reopenSessionWithCompletionHandler:(VKSessionStateHandler)handler;

+ (VKRequestOperation *)uploadDataTo:(NSString *)uploadURL fromURL:(NSURL *)fileUrl name:(NSString *)name fileName:(NSString *)filename mime:(NSString *)mime handler:(VKRequestHandler)handler;

- (void)closeAndClearTokenInformation;

+ (void)sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData handler:(VKRequestHandler)handler;


@end
