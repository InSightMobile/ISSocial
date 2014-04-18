//
//  ODKSession.h
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    ODKSessionStateOpen,
    ODKSessionStateClosedLoginFailed,
    ODKSessionStateClosed

} ODKSessionState;

@class ODKSession;
@class Odnoklassniki;
@class OKSession;

typedef void (^ODKSessionStateHandler)(ODKSession *session,
        ODKSessionState status,
        NSError *error);


@interface ODKSession : NSObject


@property(nonatomic, strong) OKSession *session;

+ (ODKSession *)activeSession;

- (void)reopenSessionWithCompletionHandler:(ODKSessionStateHandler)handler;


+ (void)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appId appSecret:(NSString *)appSecret appKey:(NSString *)appKey completionHandler:(ODKSessionStateHandler)handler;

- (BOOL)isLoggedIn;

- (NSString *)accessToken;
@end
