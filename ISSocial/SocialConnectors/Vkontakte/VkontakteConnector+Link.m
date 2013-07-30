//
// Created by Ярослав on 30.07.13.
// Copyright (c) 2013 Ярослав. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "VkontakteConnector+Link.h"
#import "SLinkData.h"


@implementation VkontakteConnector (Link)

- (SObject *)addLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        [self simpleMethod:@"likes.add" parameters:@{@"item_id" : link.linkURL.absoluteString, @"type" : @"sitepage"}
                 operation:operation processor:^(id response) {

            SLinkData *result = link;
            result.userLikes = @YES;
            result.likesCount = @([response[@"likes"] intValue]);
            [operation complete:result];
        }];
    }];
}

@end