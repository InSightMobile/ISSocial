//
//  ODKSession.m
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "ODKSession.h"
#import "Odnoklassniki.h"
#import "NSObject+PerformBlockInBackground.h"

@interface ODKSession () <OKSessionDelegate>


@property(nonatomic, strong) Odnoklassniki *okAPI;
@property(nonatomic, copy) ODKSessionStateHandler sessionOpenHandler;
@property(nonatomic, copy) NSString *appId;
@property(nonatomic, copy) NSString *appSecret;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic, strong) NSArray *permissions;
@end

@implementation ODKSession

+ (ODKSession *)activeSession
{
    static ODKSession *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)okDidLogin
{
    if (_sessionOpenHandler) {
        _sessionOpenHandler(self, ODKSessionStateOpen, nil);
        self.sessionOpenHandler = nil;
    }
}

- (void)okDidExtendToken:(NSString *)accessToken
{
    [self okDidLogin];
}

- (void)okDidNotExtendToken:(NSError *)error
{
    NSLog(@"okDidNotLogin");
    if (_sessionOpenHandler) {
        _sessionOpenHandler(self, ODKSessionStateClosedLoginFailed, error);
        self.sessionOpenHandler = nil;
    }
}

- (void)okDidNotLogin:(BOOL)canceled
{
    NSLog(@"okDidNotLogin");
    if (_sessionOpenHandler) {
        _sessionOpenHandler(self, ODKSessionStateClosedLoginFailed, nil);
        self.sessionOpenHandler = nil;
    }
}

- (void)okDidLogout
{
    NSLog(@"okDidLogout");
    if (_sessionOpenHandler) {
        _sessionOpenHandler(self, ODKSessionStateClosed, nil);
        self.sessionOpenHandler = nil;
    }
}


- (void)okDidNotLoginWithError:(NSError *)error
{
    NSLog(@"error = %@", error);
    if (_sessionOpenHandler) {
        _sessionOpenHandler(self, ODKSessionStateClosedLoginFailed, error);
        self.sessionOpenHandler = nil;
    }
}

- (void)reopenSessionWithCompletionHandler:(ODKSessionStateHandler)handler
{
    [self openSessionWithCompletionHandler:handler];
}

- (void)openSessionWithCompletionHandler:(ODKSessionStateHandler)handler
{

    if (!self.permissions) {
        self.permissions = @[@"VALUABLE ACCESS", @"SET STATUS", @"PUBLISH TO STREAM", @"PHOTO CONTENT", @"MESSAGING"];
    }

    self.sessionOpenHandler = handler;

    if (self.session.accessToken) {
        [self.session refreshAuthToken];
        return;
    }
    else if ([OKSession openActiveSessionWithPermissions:self.permissions appId:self.appId appSecret:self.appSecret]) {
        self.session = [OKSession activeSession];
        self.session.delegate = self;
        self.session.appKey = self.appKey;
        [self.session refreshAuthToken];
    }
    else {
        self.session = [[OKSession alloc] initWithAppID:self.appId permissions:self.permissions appSecret:self.appSecret];
        self.session.delegate = self;
        self.session.appKey = self.appKey;
        [OKSession setActiveSession:self.session];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didActivated:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self.session authorizeWithOKAppAuth:YES safariAuth:YES];
    }
}

+ (void)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appId
                               appSecret:(NSString *)appSecret appKey:(NSString *)appKey
                       completionHandler:(ODKSessionStateHandler)handler
{
    ODKSession *session = [self activeSession];
    session.appId = appId;
    session.appSecret = appSecret;
    session.appKey = appKey;
    session.permissions = permissions;

    [session openSessionWithCompletionHandler:handler];
}

- (BOOL)isLoggedIn
{
    return self.session.accessToken != nil;
}

- (void)didActivated:(NSNotification *)notification
{
    if (self.sessionOpenHandler) {
        [self iss_performBlock:^(id sender) {
            if (self.sessionOpenHandler) {
                self.sessionOpenHandler(self, ODKSessionStateClosed, nil);
                self.sessionOpenHandler = nil;
            }
        }           afterDelay:1.0];

    }
}

- (NSString *) accessToken
{
    return self.session.accessToken;
}

@end
