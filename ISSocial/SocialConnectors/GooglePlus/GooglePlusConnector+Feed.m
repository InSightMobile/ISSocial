//
// 

#import "SCommentData.h"
#import "GTLPlusComment.h"
#import "GTLPlusCommentFeed.h"
#import "SPhotoData.h"
#import "GTLPlusActivity.h"
#import "GTLPlusActivityFeed.h"
#import "NSString+TypeSafety.h"
#import "MultiImage.h"
#import "SUserData.h"
#import "GTLPlusConstants.h"
#import "GTMLogger.h"
#import "GTLService.h"
#import "GTLQueryPlus.h"
#import "GooglePlusConnector.h"
#import "GooglePlusConnector+Feed.h"


@implementation GooglePlusConnector (Feed)
- (SObject *)readFeedComments:(SFeedEntry *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        GTLQueryPlus *query =
                [GTLQueryPlus queryForCommentsListWithActivityId:params.objectId];

        [self executeQuery:query operation:operation processor:^(GTLPlusCommentFeed *commentsFeed) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (GTLPlusComment *comment in commentsFeed.items) {
                SCommentData *commentData = [[SCommentData alloc] initWithHandler:self];

                NSLog(@"activity.JSONString = %@", comment.JSON);

                commentData.objectId = comment.identifier;
                commentData.commentedObject = params;
                commentData.date = comment.updated.date;
                commentData.message = comment.object.content;

                SUserData *actor = [SUserData objectWithHandler:self];

                actor.userName = comment.actor.displayName;
                actor.userPicture = [[MultiImage alloc] initWithURL:comment.actor.image.url.URLValue];
                actor.objectId = comment.actor.identifier;
                commentData.author = actor;

                [result addSubObject:commentData];
            }

            [operation complete:result];
        }];
    }];
}

- (SObject *)readFeed:(SObject *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        GTLQueryPlus *query =
                [GTLQueryPlus queryForActivitiesListWithUserId:@"me"
                                                    collection:kGTLPlusCollectionPublic];

        [self executeQuery:query operation:operation processor:^(GTLPlusActivityFeed *activityFeed) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (GTLPlusActivity *activity in activityFeed.items) {
                SFeedEntry *feed = [[SFeedEntry alloc] initWithHandler:self];

                NSLog(@"activity.JSONString = %@", activity.JSON);

                feed.objectId = activity.identifier;
                feed.date = activity.updated.date;
                feed.message = activity.object.content;

                feed.commentsCount = activity.object.replies.totalItems;
                feed.likesCount = activity.object.plusoners.totalItems;

                if (activity.object.attachments.count) {

                    NSMutableArray
                            *attachemnts = [NSMutableArray arrayWithCapacity:activity.object.attachments.count];

                    for (GTLPlusActivityObjectAttachmentsItem *attachment in activity.object.attachments) {

                        SPhotoData *photo = [SPhotoData objectWithHandler:self];

                        photo.mediaType = @"photo";

                        MultiImage *image = [MultiImage new];

                        [image addImageURL:attachment.image.url.URLValue
                                  forWitdh:attachment.image.width.unsignedIntegerValue
                                    height:attachment.image.height.unsignedIntegerValue];

                        [image addImageURL:attachment.fullImage.url.URLValue
                                  forWitdh:attachment.fullImage.width.unsignedIntegerValue
                                    height:attachment.fullImage.height.unsignedIntegerValue];


                        photo.multiImage = image;
                        //photo.photoDescription = attachment.content;

                        [attachemnts addObject:photo];
                    }

                    feed.attachments = attachemnts;

                }

                SUserData *actor = [SUserData objectWithHandler:self];

                actor.userName = activity.actor.displayName;
                actor.userPicture = [[MultiImage alloc] initWithURL:activity.actor.image.url.URLValue];
                actor.objectId = activity.actor.identifier;
                feed.author = actor;

                [result addSubObject:feed];
            }

            [operation complete:result];
        }];
    }];
}
@end