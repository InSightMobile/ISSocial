//
//  SFeedEntry.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SObject.h"
#import "SMediaObject.h"
#include "SCommentedObject.h"

@class SUserData;


@protocol SFeedEntry <SMediaObject, SCommentedObject>

@optional
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) NSString *htmlMessage;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) SUserData *author;
@property(nonatomic, strong) NSArray *attachments;
@property(nonatomic, strong) SUserData *owner;
@property(nonatomic, copy) NSString *postId;


@end

@interface SFeedEntry : SObject <SFeedEntry>


@end
