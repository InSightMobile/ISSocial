//
// Created by Ярослав on 24.04.13.
// Copyright (c) 2013 ‚Äì√ò‚Äî√Ñ‚Äì√¶‚Äî√Ö‚Äì¬™‚Äì‚àû‚Äì‚â§. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class AFHTTPClient;


@interface NetworkCheck : NSObject
@property(nonatomic, strong) AFHTTPClient *client;

+ (NetworkCheck *)instance;

- (void)checkConnectionWithCompletion:(void (^)(BOOL))completion;
@end