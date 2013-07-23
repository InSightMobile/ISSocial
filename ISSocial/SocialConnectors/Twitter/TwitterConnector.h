//
//  FacebookConnector.h
//  socials
//
//  Created by yar on 18.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "AccessSocialConnector.h"

@class ACAccount;

@interface TwitterConnector : AccessSocialConnector

+ (TwitterConnector *)instance;

@property(retain, nonatomic) SUserData *currentUserData;

@end
