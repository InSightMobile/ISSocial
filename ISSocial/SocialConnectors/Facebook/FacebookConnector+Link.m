//
// 



#import "FacebookConnector+Link.h"
#import "SLinkData.h"
#import "SUserData.h"
#import "SPhotoData.h"
#import "FBDialogs.h"
#import "FBDialogsParams+Internal.h"
#import "FBDialogsData+Internal.h"
#import "FBWebDialogs.h"


@implementation FacebookConnector (Link)

- (SObject *)publishLinkWithDialog:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:link completion:completion processor:^(SocialConnectorOperation *operation)
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

        NSString *userId = @"me";
        if (link.owner) {
            userId = link.owner.objectId;
            params[@"to"] = userId;
        }

        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {

                                                      NSLog(@"result = %d", resultURL);
                                                      if(error) {
                                                          [operation completeWithError:error];
                                                      }
                                                      else if(result == FBWebDialogResultDialogCompleted){

                                                          if([resultURL.query hasPrefix:@"post_id"]) {
                                                              [operation complete:[SObject successful]];
                                                          }
                                                          else {
                                                              [operation complete:[SObject failed]];
                                                          }
                                                      }
                                                      else {
                                                          [operation complete:[SObject failed]];
                                                      }
                                                  }];
    }];

 /*       [FBWebDialogs ]

        FBAppCall *call = nil;
        NSString *version = [params appBridgeVersion];
        if (version) {
            FBDialogsData *dialogData = [[[FBDialogsData alloc] initWithMethod:@"share"
                                                                     arguments:[params dictionaryMethodArgs]]
                    autorelease];
            dialogData.clientState = clientState;

            call = [[[FBAppCall alloc] init] autorelease];
            call.dialogData = dialogData;

            [[FBAppBridge sharedInstance] dispatchDialogAppCall:call
                                                        version:version
                                                        session:nil
                                              completionHandler:^(FBAppCall *call) {
                                                  if (handler) {
                                                      handler(call, call.dialogData.results, call.error);
                                                  }
                                              }];
        }
        [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsPresentShareDialog
                           valueToSum:nil
                           parameters:@{ FBAppEventParameterDialogOutcome : call ?
                                   FBAppEventsDialogOutcomeValue_Completed :
                                   FBAppEventsDialogOutcomeValue_Failed }
                              session:nil];

        return call;



        FBShareDialogParams *params = [FBShareDialogParams new];



        [FBDialogs presentShareDialogWithLink:link.message
                                         name:link.name
                                      caption:link.title
                                  description:link.desc
                                      picture:link.photo.photoURL
                                  clientState:@{}
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error)
                                      {
                                          if(error) {
                                              [operation completeWithError:<#(NSError *)error#>];
                                          }
                                          else {
                                              [operation complete:[SObject successful]];
                                          }
                                      }];
    }];*/
}

- (SObject *)publishLink:(SLinkData *)link completion:(SObjectCompletionBlock)completion
{
    if (link.owner && ![link.owner.objectId isEqual:self.currentUserData.objectId]) {
        return [self publishLinkWithDialog:link completion:completion];
    }

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
                if (result[@"id"]) {
                    [operation complete:[SObject successful]];
                }
                else {
                    [operation completeWithFailure];
                }

            }];
        }];
    }];
}

- (SObject *)readLinkLikes:(SLinkData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {
        if (params.userLikes.boolValue) {
            [operation complete:params];
            return;
        }

        if (!params.linkURL.absoluteString.length) {
            [operation completeWithFailure];
            return;
        }

        NSString *const query =
                [NSString stringWithFormat:@"SELECT user_id FROM url_like WHERE user_id = %@ AND url = '%@';", self.currentUserData.objectId, params.linkURL.absoluteString];

        SLinkData *link = [params copyWithHandler:self];

        [self simpleQuery:query operation:operation processor:^(id o)
        {
            NSLog(@"o = %@", o);

            if ([o[@"data"] count]) {
                link.userLikes = @YES;
            }
            else {
                link.userLikes = @NO;
            }

            [self simpleQuery:[NSString stringWithFormat:@"select like_count from link_stat WHERE url ='%@';", params.linkURL.absoluteString] operation:operation processor:^(id result)
            {
                NSLog(@"o = %@", result);

                if ([result[@"data"] count]) {
                    NSNumber *count = result[@"data"][0][@"like_count"];
                    if (count) {
                        link.likesCount = count;
                    }
                }

                [operation complete:link];
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