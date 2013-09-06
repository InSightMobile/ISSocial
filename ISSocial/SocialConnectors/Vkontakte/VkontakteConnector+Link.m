//
// Created by Ярослав on 30.07.13.
// Copyright (c) 2013 Ярослав. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "VkontakteConnector+Link.h"
#import "SLinkData.h"
#import "SUserData.h"


@implementation VkontakteConnector (Link)

- (SObject *)addLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        id pageId = link.objectId;

        //pageId = link.linkURL.absoluteString;

        [self simpleMethod:@"likes.add" parameters:@{@"item_id" : pageId, @"page_url" : link.linkURL.absoluteString, @"type" : @"sitepage"}
                 operation:operation processor:^(id response)
        {

            SLinkData *result = link;
            result.userLikes = @YES;
            result.likesCount = @([response[@"likes"] intValue]);
            [operation complete:result];
        }];
    }];
}

- (SObject *)publishLink:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        NSString *userId = nil;
        if (link.owner && link.owner.objectId != self.currentUserData.objectId) {
            userId = link.owner.objectId;
        }

        NSMutableDictionary *params = [NSMutableDictionary dictionary];

        if (link.linkURL) {
            params[@"attachments"] = link.linkURL.absoluteString;
        }

        if (userId) {

        }

        [self simpleMethod:@"wall.post" parameters:params operation:operation processor:^(id result)
        {
            if (result[@"post_id"]) {
                [operation complete:[SObject successful]];
            }
            else {
                [operation completeWithFailure];
            }

        }];
    }];
}

@end