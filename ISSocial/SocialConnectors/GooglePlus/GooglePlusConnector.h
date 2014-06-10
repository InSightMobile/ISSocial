//
//  GooglePlusConnector.h
//  socials
//
//  Created by yar on 12.01.13.
//  Copyright (c) 2013 Ярослав. All rights reserved.
//

#import "AccessSocialConnector.h"

@protocol GTLQueryProtocol;
@class GPSession;


@interface GooglePlusConnector : AccessSocialConnector

+ (GooglePlusConnector *)instance;

- (void)executeQuery:(id <GTLQueryProtocol>)query operation:(SocialConnectorOperation *)operation processor:(void (^)(id))handler;
@end
