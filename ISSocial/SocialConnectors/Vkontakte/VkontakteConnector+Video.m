//
// 

#import "SPhotoData.h"
#import "VkontakteConnector.h"
#import "VkontakteConnector+Video.h"
#import "SVideoData.h"
#import "VKSession.h"
#import "MultiImage.h"
#import "NSString+TypeSafety.h"
#import "SUserData.h"
#import "VkontakteConnector+UserData.h"
#import "SCommentData.h"
#import "VkontakteConnector+Feed.h"


@implementation VkontakteConnector (Video)

- (SVideoData *)parseVideoResponse:(NSDictionary *)info
{
    NSLog(@"info = %@", info);

    SUserData *owner = [self dataForUserId:[info[@"owner_id"] stringValue]];
    NSString *vid = [info[@"vid"] stringValue];
    NSString *objectId = [NSString stringWithFormat:@"%@_%@", owner.objectId, vid];

    SVideoData *video = (SVideoData *) [self mediaObjectForId:objectId type:@"video"];

    video.previewURL = [NSURL URLWithString:info[@"image"]];
    video.date = [NSDate dateWithTimeIntervalSince1970:[info[@"date"] doubleValue]];
    video.title = info[@"title"];
    video.playbackURL = [info[@"player"] URLValue];
    video.videoId = vid;
    video.author = owner;

    MultiImage *image = [MultiImage new];

    //image — url изображения-обложки ролика с размером 160x120px;
    //image_medium — url изображения-обложки ролика с размером 320x240px;

    [image addImageURL:[info[@"image"] URLValue] forWitdh:160 height:120];
    [image addImageURL:[info[@"image_medium"] URLValue] forWitdh:320 height:240];

    //[image addImageURL:[info[@"image_big"] URLValue] quality:1];
    //[image addImageURL:[info[@"image_small"] URLValue] quality:0.25];

    video.multiImage = image;

    video.commentsCount = @([info[@"comments"] intValue]);
    video.canAddComment = @YES;
    video.canAddLike = @YES;

    return video;
}

- (SObject *)addVideo:(SVideoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"video.save" parameters:nil operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            [VKSession uploadDataTo:response[@"upload_url"] fromURL:params.playbackURL name:@"video_file" fileName:@"video.mov" mime:nil handler:^(VKRequestOperation *connection, id result, NSError *error) {

                if (error) {
                    [operation completeWithError:error];
                    return;
                }

                NSLog(@"result = %@", result);

                NSString *videoId = response[@"vid"];

                [self simpleMethod:@"video.get" parameters:@{@"videos" : videoId} operation:operation processor:^(id response) {

                    NSLog(@"response = %@", response);

                    if (![response count]) {
                        // video not yet created
                        SVideoData *data = [[SVideoData alloc] initWithHandler:self];
                        data.objectId = videoId;

                        [operation complete:data];
                        return;
                    }

                    SVideoData *video = [self parseVideoResponse:response[0]];
                    [operation complete:video];
                }];
            }];
        }];
    }];
}

- (SObject *)readVideo:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"video.get" parameters:@{@"uid" : self.userId, @"photo_sizes" : @1, @"extended" : @1} operation:operation processor:^(id response) {

            SObject *result = [self parseVideosResponce:response];

            [operation complete:result];
        }];
    }];
}

- (SObject *)parseVideosResponce:(id)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];

    NSLog(@"response = %@", response);

    for (NSDictionary *info in response) {

        if ([info isKindOfClass:[NSDictionary class]]) {
            SVideoData *photoData = [self parseVideoResponse:info];
            [result addSubObject:photoData];
        }
    }
    return result;
}

- (SObject *)addVideoComment:(SCommentData *)params completion:(SObjectCompletionBlock)completion
{
    NSLog(@"params = %@", params);
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"video.createComment" parameters:@{
                @"vid" : [(SVideoData *) params.commentedObject videoId],
                @"owner_id" : [(SVideoData *) params.commentedObject author].objectId,
                @"message" : params.message}
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SVideoData *video = (SVideoData *) params.commentedObject;

            SCommentData *comment = [params copyWithHandler:self];
            comment.objectId = [response stringValue];
            video.commentsCount = @(video.commentsCount.intValue + 1);
            [video fireUpdateNotification];

            [operation complete:comment];
        }];
    }];
}

- (SObject *)readVideoLikes:(SVideoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self readLikes:params operation:operation type:@"video" itemId:params.videoId owner:params.author];
    }];
}

- (void)readLikes:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner
{
    [self simpleMethod:@"likes.getList" parameters:@{@"item_id" : itemId, @"type" : type, @"owner_id" : owner.objectId}
             operation:operation processor:^(id response) {

        NSLog(@"response = %@", response);

        SVideoData *result = params;

        result.canAddLike = @YES;
        result.likesCount = @([response[@"count"] intValue]);

        result.userLikes = @YES;

        [self simpleMethod:@"likes.isLiked" parameters:@{@"item_id" : itemId, @"type" : type, @"owner_id" : owner.objectId}
                 operation:operation processor:^(id response) {

            result.userLikes = @([response intValue]);

            [result fireUpdateNotification];
            [operation complete:result];
        }];
    }];
}

- (SObject *)addVideoLike:(SVideoData *)params completion:(SObjectCompletionBlock)completion
{
    NSLog(@"params = %@", params);
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self addLike:params operation:operation type:@"video" itemId:params.videoId owner:params.author];
    }];
}

- (SObject *)removeVideoLike:(SVideoData *)params completion:(SObjectCompletionBlock)completion
{
    NSLog(@"params = %@", params);
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self removeLike:params operation:operation type:@"video" itemId:params.videoId owner:params.author];
    }];
}

- (void)addLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner
{
    [self simpleMethod:@"likes.add" parameters:@{@"item_id" : itemId, @"type" : type, @"owner_id" : owner.objectId}
             operation:operation processor:^(id response) {

        SVideoData *result = params;
        result.userLikes = @YES;
        result.likesCount = @([response[@"likes"] intValue]);
        [result fireUpdateNotification];
        [operation complete:result];
    }];
}


- (void)removeLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner
{
    [self simpleMethod:@"likes.delete" parameters:@{@"item_id" : itemId, @"type" : type, @"owner_id" : owner.objectId}
             operation:operation processor:^(id response) {
        SVideoData *result = params;
        result.userLikes = @NO;
        result.likesCount = @([response[@"likes"] intValue]);
        [result fireUpdateNotification];
        [operation complete:result];
    }];
}

- (SObject *)readVideoComments:(SVideoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"video.getComments" parameters:@{@"vid" : params.videoId, @"owner_id" : params.author.objectId} operation:operation processor:^(NSArray *response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseCommentEntries:response object:params paging:nil];

            if (result.totalCount) {
                params.commentsCount = result.totalCount;
                [params fireUpdateNotification];
            }

            [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:result];
            }];
        }];
    }];
}


@end