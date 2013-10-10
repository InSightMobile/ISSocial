//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "SUserData.h"
#import "SFeedEntry.h"
#import "FacebookSDK.h"
#import "FacebookConnector.h"
#import "FacebookConnector+Feed.h"
#import "NSDate+Facebook.h"
#import "FacebookConnector+UserData.h"
#import "FacebookConnector+Photos.h"
#import "SCommentData.h"
#import "SNewsEntry.h"
#import "FacebookConnector+Video.h"
#import "SImagePreviewObject.h"
#import "MultiImage.h"
#import "SVideoData.h"
#import "NSArray+AsyncBlocks.h"
#import "NSString+StripHTML.h"
#import "NSString+TypeSafety.h"
#import "SLinkData.h"

@implementation FacebookConnector (Feed)

- (NSArray *)parseAttachment:(NSDictionary *)attachment
{
    if (!attachment.count) {
            return nil;
    }
    NSLog(@"attachments = %@", attachment);
    NSArray *media = attachment[@"media"];

    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *mediaItem in media) {

        if (mediaItem[@"photo"]) {
            SPhotoData *photo = [self parsePhoto:mediaItem[@"photo"]];
            if (mediaItem[@"src"]) {
                if (!photo.multiImage) {
                    photo.multiImage = [MultiImage new];
                }
                [photo.multiImage addImageURL:[mediaItem[@"src"] URLValue] quality:1];
                if (photo) {
                    [result addObject:photo];
                }
            }
        }
        if (mediaItem[@"video"]) {
            SVideoData *video = [self parseVideoResponse:mediaItem[@"video"]];
            if (video) {

                video.multiImage = [[MultiImage alloc] initWithURL:mediaItem[@"src"]];

                [result addObject:video];
            }
        }
    }
    return result.count ? result : nil;
}

- (SFeedEntry *)parseFeed:(NSDictionary *)feedInfo
{
    NSString *objectId = [feedInfo[@"post_id"] stringValue];

    NSLog(@"feedInfo = %@", feedInfo);
    SFeedEntry *entry = (SFeedEntry *) [self mediaObjectForId:objectId type:@"post"];

    entry.message = feedInfo[@"message"];
    entry.date = [NSDate dateWithFacebookString:feedInfo[@"created_time"]];

    if (feedInfo[@"actor_id"]) {
        entry.author = [self dataForUserId:[feedInfo[@"actor_id"] stringValue]];
    }

    if (feedInfo[@"from"]) {
        entry.author = [self parseUserData:feedInfo[@"from"]];
    }
    else if (!entry.author) {
        entry.author = self.currentUserData;
    }

    entry.attachments = [self parseAttachment:feedInfo[@"attachment"]];

    entry.commentsCount = feedInfo[@"comments"][@"count"];
    entry.canAddComment = feedInfo[@"comments"][@"can_post"];

    entry.likesCount = feedInfo[@"likes"][@"count"];
    entry.userLikes = feedInfo[@"likes"][@"user_likes"];
    entry.canAddLike = feedInfo[@"likes"][@"can_like"];

    // ignore empty messages
    if (entry.message.length == 0 && entry.attachments.count == 0) {
        return nil;
    }

    entry.canDelete = @([entry.author.objectId isEqualToString:self.currentUserData.objectId]);


    entry.deletionSelector = @selector(removeFeedEntry:completion:);
    return entry;
}

- (SObject *)parseFeedData:(NSArray *)data
{
// parse result & create sub array
    SObject *objectResult = [[SObject alloc] initWithHandler:self];
    for (NSDictionary *feed in data) {
        SFeedEntry *entry = [self parseFeed:feed];
        [objectResult addSubObject:entry];
    }
    objectResult.pagingData = @([[objectResult.subObjects.lastObject date] timeIntervalSince1970]);
    objectResult.isPagable = @YES;

    return objectResult;
}

- (SObject *)pageNews:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        NSString *const query =
                [NSString stringWithFormat:@"select message,attachment,actor_id,target_id,source_id,created_time,post_id,likes,comments "
                                                   @"FROM stream WHERE filter_key in (SELECT filter_key FROM stream_filter WHERE uid = me() AND type = 'newsfeed') "
                                                   @"AND is_hidden = 0 AND created_time < %@ AND (type=46 OR type=237) LIMIT %d", params.pagingData, self.pageSize];

        [self simpleQuery:query
                operation:operation processor:^(id result)
        {

            SObject *feed = [self parseFeedData:result[@"data"]];
            feed.isPagable = @([result[@"data"] count] == self.pageSize);

            [self updateUserData:[feed.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *result)
            {
                [operation complete:[self addPagingData:feed to:params]];
            }];
        }];
    }];
}

- (SObject *)readNews:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        NSString *const query =
                [NSString stringWithFormat:@"select message,attachment,actor_id,target_id,source_id,created_time,post_id,likes,comments "
                                                   @"FROM stream WHERE filter_key in (SELECT filter_key FROM stream_filter WHERE uid = me() AND type = 'newsfeed') "
                                                   @"AND is_hidden = 0 AND (type=46 OR type=237) LIMIT %d", self.pageSize];

        [self simpleQuery:query
                operation:operation processor:^(id result)
        {

            SObject *feed = [self parseFeedData:result[@"data"]];
            feed.pagingSelector = @selector(pageNews:completion:);
            feed.isPagable = @([result[@"data"] count] == self.pageSize);

            [self updateUserData:[feed.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *result)
            {
                [operation complete:feed];
            }];
        }];
    }];
}

- (SObject *)pageFeed:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        NSString *const query =
                [NSString stringWithFormat:@"select message,attachment,actor_id,source_id,created_time,post_id,likes,comments "
                                                   @"from stream WHERE source_id = me() AND (type=46 OR type=237) AND created_time < %@ AND (type=46 OR type=237) LIMIT %d", params.pagingData, self.pageSize];

        [self simpleQuery:query
                operation:operation processor:^(id result)
        {

            SObject *feed = [self parseFeedData:result[@"data"]];

            feed.isPagable = @([result[@"data"] count] == self.pageSize);

            [self updateUserData:[feed.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *result)
            {
                [operation complete:[self addPagingData:feed to:params]];
            }];
        }];
    }];
}

- (SObject *)readFeed:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        NSString *const query =
                [NSString stringWithFormat:@"select type,message,attachment,actor_id,source_id,created_time,post_id,likes,comments "
                                                   @"from stream WHERE source_id = me() AND is_hidden=0 AND (type=46 OR type=237) LIMIT %d", self.pageSize];

        [self simpleQuery:query
                operation:operation processor:^(id result)
        {

            NSLog(@"result = %@", result);

            SObject *feed = [self parseFeedData:result[@"data"]];
            feed.pagingSelector = @selector(pageFeed:completion:);

            feed.isPagable = @([result[@"data"] count] == self.pageSize);

            [self updateUserData:[feed.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *result)
            {

                if (feed.isPagable && feed.subObjects.count < self.pageSize) {
                    [self pageFeed:feed completion:completion];
                }
                else {
                    [operation complete:feed];
                }
            }];

        }];
    }];
}

- (SObject *)removeFeedEntry:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        [self simpleMethod:@"DELETE" path:params.objectId params:nil object:nil operation:operation processor:^(id response)
        {

            NSLog(@"response = %@", response);

            BOOL ok = [response[@"FACEBOOK_NON_JSON_RESULT"] boolValue];

            if (ok) {
                params.deleted = @YES;
                [params fireUpdateNotification];
                [operation complete:[SObject successful]];
            }
            else {
                [operation completeWithFailure];
            }

        }];

    }];
}

- (SObject *)postToFeed:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    SFeedEntry *feed = [params copy];

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {
        [self checkAuthorizationFor:@[@"publish_stream", @"photo_upload"] operation:operation processor:^(id res)
        {

            if (feed.attachments.count) {

                NSMutableArray *photos = [NSMutableArray array];

                [feed.attachments asyncEach:^(id object, ISArrayAsyncEachResultBlock next)
                {

                    if ([[object mediaType] isEqualToString:@"photo"]) {

                        SPhotoData *photoData = object;
                        if (photoData.sourceImage) {
                            [self readWallAlbumWithOperation:operation completion:^(SObject *result)
                            {

                                NSString *destination = result.objectId && !result.isFailed ? result.objectId : @"me";

                                NSString *path = [NSString stringWithFormat:@"%@/photos", destination];

                                [self uploadPhoto:feed.attachments[0] toPath:path operation:operation completion:^(SObject *result)
                                {
                                    [photos addObject:result];
                                    next(nil);
                                }];
                            }];
                        }
                        else {
                            next(nil);
                        }
                    }
                    else {
                        next(nil);
                    }

                }               comletition:^(NSError *errorOrNil)
                {

                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    if (feed.message.length) {
                        params[@"message"] = feed.message;
                    }
                    if (photos.count) {
                        params[@"object_attachment"] = [photos[0] objectId];
                    }

                    [self simplePost:@"me/feed" object:params operation:operation processor:^(id result)
                    {

                        [[FBRequest requestForGraphPath:result[@"id"]] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
                        {

                            if (error) {
                                [operation completeWithError:error];
                                return;
                            }

                            [operation complete:[self parseFeed:result]];
                        }];
                    }];

                }];
            }
            else {
                [self simplePost:@"me/feed" object:@{@"message" : feed.message} operation:operation processor:^(id result)
                {

                    [[FBRequest requestForGraphPath:result[@"id"]] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
                    {

                        if (error) {
                            [operation completeWithError:error];
                            return;
                        }

                        [operation complete:[self parseFeed:result]];
                    }];
                }];
            }

        }];

    }];
}


- (SCommentData *)parseCommentEntry:(NSDictionary *)entryData
{
    SCommentData *entry = [[SCommentData alloc] initWithHandler:self];

    entry.message = [entryData[@"message"] stripHtml];
    entry.date = [NSDate dateWithFacebookString:entryData[@"created_time"]];
    entry.author = [self dataForUserId:[entryData[@"from"][@"id"] stringValue]];
    entry.objectId = [entryData[@"id"] stringValue];

    return entry;
}


- (SObject *)addFeedComment:(SCommentData *)comment completion:(SObjectCompletionBlock)completion
{
    //NSParameterAssert(comment.author.objectId);
    NSParameterAssert(comment.message);
    NSParameterAssert([comment.commentedObject objectId]);

    return [self operationWithObject:comment completion:completion processor:^(SocialConnectorOperation *operation)
    {

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {

            [self simplePost:[NSString stringWithFormat:@"%@/comments", [comment.commentedObject objectId]]
                      object:@{@"message" : comment.message}
                   operation:operation processor:^(id response)
            {

                NSLog(@"response = %@", response);

                SCommentData *result = [comment copyWithHandler:self];
                result.objectId = response[@"id"];

                result.commentedObject.commentsCount = @(result.commentedObject.commentsCount.intValue + 1);

                [result.commentedObject fireUpdateNotification];
                [operation complete:result];
            }];

        }];
    }];
}

- (SObject *)addNewsLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    [self addFeedLike:feed completion:completion];
}

- (SObject *)removeNewsLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    [self removeFeedLike:feed completion:completion];
}

- (SObject *)addNewsComment:(SCommentData *)comments completion:(SObjectCompletionBlock)completion
{
    return [self addFeedComment:(id) comments completion:completion];
}

- (SObject *)readNewsComments:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self readFeedComments:(id) feed completion:completion];
}

- (SObject *)addFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation)
    {

        if (feed.userLikes.boolValue) {
            [operation complete:feed];
            return;
        }

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {

            [self simplePost:[NSString stringWithFormat:@"%@/likes", [feed objectId]]
                      object:nil operation:operation processor:^(id response)
            {

                NSLog(@"response = %@", response);

                SFeedEntry *result = feed;
                result.userLikes = @YES;
                result.likesCount = @(result.likesCount.intValue + 1);

                [result fireUpdateNotification];

                [operation complete:result];
            }];

        }];
    }];
}

- (SObject *)removeFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{

    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation)
    {

        if (!feed.userLikes.boolValue) {
            [operation complete:feed];
            return;
        }

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res)
        {

            [self simpleRequest:@"DELETE" path:[NSString stringWithFormat:@"%@/likes", [feed objectId]]
                         object:nil operation:operation processor:^(id response)
            {

                NSLog(@"response = %@", response);

                SFeedEntry *result = feed;
                result.userLikes = @NO;
                result.likesCount = @(result.likesCount.intValue - 1);

                [result fireUpdateNotification];

                [operation complete:result];
            }];

        }];
    }];
}

- (SObject *)readFeedComments:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    SFeedEntry *feedObject = feed;

    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation)
    {
        [self simpleMethod:[NSString stringWithFormat:@"%@/comments", feed.objectId]
                    params:@{@"limit" : [@(self.pageSize) stringValue]}
                 operation:operation processor:^(id response)
        {

            NSLog(@"response = %@", response);

            SObject *result = [self parseComments:response forObject:feedObject];

            [operation complete:result];

            /*[self updateUserData:[result.subObjects valueForKey:@"author"] completion:^(SObject *updateResult) {

                [operation complete:result];

            }]; */
        }];
    }];
}

- (SObject *)readCommentsPage:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation)
    {

        if (!params.pagingData) {
            [operation completeWithFailure];
            return;
        }

        [self simpleMethodWithURL:params.pagingData operation:operation processor:^(id result)
        {
            SObject *object = [self parseComments:result forObject:[(id) params commentedObject]];
            SObject *currentData = [params copyWithHandler:self];
            [currentData.subObjects addObjectsFromArray:object.subObjects];
            currentData.pagingData = object.pagingData;
            currentData.isPagable = object.isPagable;
            [operation complete:currentData];
        }];
    }];
}


- (SObject *)parseComments:(id)response forObject:(SObject *)object
{
    SObject *result = [SObject objectCollectionWithHandler:self];

    int count = 0;
    for (id entry in response[@"data"]) {

        if ([entry isKindOfClass:[NSDictionary class]]) {

            SCommentData *feedEntry = [self parseCommentEntry:entry];
            feedEntry.commentedObject = object;

            [result addSubObject:feedEntry];
        }
        else {
            count = [entry intValue];
        }
    }

    [(id) result setCommentedObject:object];

    if (response[@"paging"] && response[@"paging"][@"next"]) {
        result.pagingData = response[@"paging"][@"next"];
        result.pagingSelector = @selector(readCommentsPage:completion:);
        result.isPagable = @YES;
    }

    return result;
}

- (SObject *)publishPhoto:(SPhotoData *)photo completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:photo completion:completion processor:^(SocialConnectorOperation *operation)
    {
        NSString *userId = @"me";
        if(photo.owner) {
            userId = photo.owner.objectId;
        }

        [self checkAuthorizationFor:@[@"publish_actions",@"publish_stream"] operation:operation processor:^(id res)
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            if (photo.title.length) {
                params[@"message"] = photo.title;
            }
            if (photo.photoURL) {
                params[@"url"] = [photo.photoURL absoluteString];
            }

            [self simplePost:[NSString stringWithFormat:@"%@/photos",userId] object:params operation:operation processor:^(id result)
            {
                [operation complete:[SObject successful]];
            }];
        }];
    }];
}




@end