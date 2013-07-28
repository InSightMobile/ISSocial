//
// 



#import "FacebookConnector+Link.h"
#import "SLinkData.h"


@implementation FacebookConnector (Link)


- (SObject *)addLinkLike:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
    {
        if (link.userLikes.boolValue) {
            [operation complete:link];
            return;
        }

        if (!link.linkURL.length) {
            [operation completeWithFailure];
            return;
        }

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {

            NSDictionary *object = @{@"object" : link.linkURL};

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
            NSDictionary *object = @{@"object" : link.linkURL};

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