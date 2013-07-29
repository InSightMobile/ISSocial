//
// 



#import "FacebookConnector+Link.h"
#import "SLinkData.h"
#import "SUserData.h"
#import "SPhotoData.h"


@implementation FacebookConnector (Link)

- (SObject *)publishLink:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        NSString *userId = @"me";
        if (link.owner) {
            userId = link.owner.objectId;
        }

        [self checkAuthorizationFor:@[@"publish_actions"] operation:operation processor:^(id res)
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];

            params[@"link"] = link.linkURL.absoluteString;

            if (link.message.length) {
                params[@"message"] = link.message;
            }

            if (link.name.length) {
                params[@"name"] = link.name;
            }

            if (link.title.length) {
                params[@"caption"] = link.title;
            }

            if (link.desc.length) {
                params[@"description"] = link.desc;
            }

            if (link.photo.photoURL) {
                params[@"picture"] = [link.photo.photoURL absoluteString];
            }

            [self simplePost:[NSString stringWithFormat:@"%@/feed", userId] object:params operation:operation processor:^(id result)
            {
                if(result[@"id"]) {
                    [operation complete:[SObject successful]];
                }
                else {
                    [operation completeWithFailure];
                }

            }];
        }];
    }];    
}


- (SObject *)addLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        if (link.userLikes.boolValue) {
            [operation complete:link];
            return;
        }

        if (!link.linkURL.absoluteString.length) {
            [operation completeWithFailure];
            return;
        }

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {

            NSDictionary *object = @{@"object" : link.linkURL.absoluteString};

            [self simpleMethod:@"POST" path:@"me/og.likes" params:object
                        object:nil operation:operation processor:^(id response)
            {
                NSLog(@"response = %@", response);

                SLinkData *result = [link copyWithHandler:self];
                result.objectId = [response[@"id"] stringValue];
                result.userLikes = @YES;
                result.likesCount = @(result.likesCount.intValue + 1);

                [result fireUpdateNotification];

                [operation complete:result];
            }];

        }];
    }];
}

- (SObject *)removeLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        if (link.userLikes.boolValue) {
            [operation complete:link];
            return;
        }

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {
            NSDictionary *object = @{@"object" : link.linkURL.absoluteString};

            [self simpleMethod:@"DELETE" path:@"me/og.likes" params:object
                        object:nil operation:operation processor:^(id response)
            {
                NSLog(@"response = %@", response);

                SLinkData *result = [link copyWithHandler:self];
                result.userLikes = @YES;
                result.likesCount = @(result.likesCount.intValue + 1);

                [result fireUpdateNotification];

                [operation complete:result];
            }];

        }];
    }];
}


@end