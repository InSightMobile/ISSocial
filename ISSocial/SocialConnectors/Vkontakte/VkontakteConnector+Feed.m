//
// Created by yar on 23.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <ReactiveCocoa/ReactiveCocoa/NSArray+RACSequenceAdditions.h>
#import <ReactiveCocoa/ReactiveCocoa/RACSequence.h>
//#import "ISSVKRequest.h"
#import "SUserData.h"
#import "SFeedEntry.h"
#import "VkontakteConnector.h"
#import "VkontakteConnector+Feed.h"
#import "VkontakteConnector+UserData.h"
#import "SCommentData.h"
#import "SPhotoData.h"
#import "NSArray+AsyncBlocks.h"
#import "VkontakteConnector+Photos.h"
#import "SAudioData.h"
#import "VkontakteConnector+Audio.h"
#import "SVideoData.h"
#import "NSString+StripHTML.h"
#import "VkontakteConnector+Video.h"
#import "RegexKitLite.h"
#import "ISSocial.h"
#import "ISSocial+Errors.h"
#import "SInvitation.h"

@implementation VkontakteConnector (Feed)


- (SObject *)addFeedComment:(SCommentData *)comment completion:(SObjectCompletionBlock)completion
{
    NSParameterAssert(comment.author.objectId);
    NSParameterAssert(comment.message);

    SFeedEntry *feed = [comment commentedObject];

    return [self operationWithObject:comment completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.addComment"
                parameters:@{@"post_id" : [feed postId], @"text" : comment.message}
                 operation:operation processor:^(id response) {

            //NSLog(@"response = %@", response);
            SCommentData *result = [comment copyWithHandler:self];
            result.objectId = response[@"cid"];

            feed.commentsCount = @(feed.commentsCount.intValue + 1);
            [feed fireUpdateNotification];

            [operation complete:result];
        }];
    }];
}

- (SObject *)removeFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.deleteLike"
                parameters:@{@"post_id" : [feed postId]}
                 operation:operation processor:^(id response) {

            SFeedEntry *result = feed;
            result.likesCount = response[@"likes"];
            result.userLikes = @NO;
            [result fireUpdateNotification];
            [operation complete:result];
        }];
    }];
}

- (SObject *)addFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.addLike"
                parameters:@{@"post_id" : [feed postId]}
                 operation:operation processor:^(id response) {

            SFeedEntry *result = feed;
            result.likesCount = response[@"likes"];
            result.userLikes = @YES;
            [result fireUpdateNotification];
            [operation complete:result];
        }];
    }];
}


- (SObject *)pageFeedComments:(SObject *)comments completion:(SObjectCompletionBlock)completion
{
    id commentObject = [(id) comments commentedObject];

    return [self operationWithObject:comments completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"wall.getComments" parameters:@{
                @"post_id" : [commentObject postId],
                @"owner_id" : [[commentObject owner] objectId],
                @"offset" : comments.pagingData,
                @"count" : @(self.pageSize),
                @"sort" : @"desc"}
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseCommentEntries:response object:commentObject paging:comments];
            [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {

                [operation complete:[self addPagingData:result to:comments]];
            }];
        }];
    }];
}


- (SObject *)readFeedComments:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    SFeedEntry *feedObject = [feed copyWithHandler:self];

    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {
        NSDictionary *const parameters =
                @{@"post_id" : feed.postId,
                        @"owner_id" : feed.owner.objectId,
                        @"sort" : @"desc",
                        @"count" : @(self.pageSize)};

        [self simpleMethod:@"wall.getComments" parameters:parameters operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseCommentEntries:response object:feed paging:nil];
            [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)parsePagingResponce:(id)response paging:(SObject *)paging processor:(SObject * (^)(id responce))processor
{
    SObject *result = [[SObject alloc] initWithHandler:self];

    int count = 0;
    for (id entry in response) {

        if ([entry isKindOfClass:[NSNumber class]]) {
            count = [entry intValue];
        }
        else {
            SObject *object = processor(entry);
            if (object) {
                [result addSubObject:object];
            }
        }
    }

    if (!paging) {
        result.totalCount = @(count);
    }

    int totalCount = result.subObjects.count;
    if (paging) {
        totalCount += [paging.pagingData intValue];
    }

    if (count > totalCount) {
        result.isPagable = @YES;
    }
    result.pagingData = @(totalCount);

    return result;
}

- (SObject *)parseFeedEntries:(id)response paging:(SObject *)paging operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    NSMutableArray *attachments = [NSMutableArray array];
    SObject *result = [self parsePagingResponce:response paging:paging processor:^(id responce) {
        SFeedEntry *entry = [self parseFeedEntry:responce];
        if (entry.attachments.count) {
            [attachments addObjectsFromArray:entry.attachments];
        }
        return entry;
    }];
    result.pagingSelector = @selector(pageFeed:completion:);

    [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {
        [self updateAttachments:attachments operation:operation completion:^(SObject *res) {
            completion(result);
        }];
    }];
    return nil;
}

- (SObject *)readFeed:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.get" parameters:@{@"photo_sizes" : @1, @"count" : @(self.pageSize)} operation:operation processor:^(id response) {

            [self parseFeedEntries:response paging:nil operation:operation completion:^(SObject *result) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)pageFeed:(SObject *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *const parameters = @{
                @"photo_sizes" : @1,
                @"offset" : feed.pagingData,
                @"count" : @(self.pageSize)};

        [self simpleMethod:@"wall.get" parameters:parameters
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            [self parseFeedEntries:response paging:feed operation:operation completion:^(SObject *result) {
                [operation complete:[self addPagingData:result to:feed]];
            }];
        }];
    }];
}


- (NSArray *)parseAttachments:(NSArray *)attachmentsResponse
{
    NSMutableArray *attach = [NSMutableArray arrayWithCapacity:attachmentsResponse.count];
    for (NSDictionary *attachment in attachmentsResponse) {

        NSDictionary *photoResponse = attachment[@"photo"];
        if (photoResponse) {
            SPhotoData *photo = [self parsePhotoResponse:photoResponse];
            if (photo) [attach addObject:photo];
        }
        NSDictionary *audioResponse = attachment[@"audio"];
        if (audioResponse) {
            SAudioData *audio = [self parseAudioResponse:audioResponse];
            if (audio) [attach addObject:audio];
        }
        NSDictionary *videoResponse = attachment[@"video"];
        if (videoResponse) {
            SVideoData *video = [self parseVideoResponse:videoResponse];
            if (video) [attach addObject:video];
        }
    }
    if (attach.count)
        return attach;
    else
        return nil;
}

- (void)updateAttachments:(NSArray *)attachments operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    NSMutableArray *audio = [NSMutableArray array];
    NSMutableArray *video = [NSMutableArray array];

    for (id <SMediaObject> attachment in attachments) {
        if ([attachment.mediaType isEqualToString:@"audio"]) {
            [audio addObject:attachment];
        }
        else if ([attachment.mediaType isEqualToString:@"video"]) {
            [video addObject:attachment];
        }
    }

    __block int pending = 1;
    if (audio.count) {
        pending++;

        NSDictionary *params = @{@"audios" : [[audio valueForKey:@"objectId"] componentsJoinedByString:@","]};

        [self simpleMethod:@"audio.getById" parameters:params operation:operation processor:^(id o) {

            SObject *results = [self parseAudiosResponce:o];

            pending--;
            if (pending == 0) {
                completion([SObject successful]);
            }
        }];
    }

    if (video.count) {
        pending++;

        NSDictionary *params = @{@"videos" : [[video valueForKey:@"objectId"] componentsJoinedByString:@","]};

        [self simpleMethod:@"video.get" parameters:params operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *results = [self parseVideosResponce:response];

            pending--;
            if (pending == 0) {
                completion([SObject successful]);
            }
        }];
    }

    pending--;
    if (pending == 0) {
        completion([SObject successful]);
    }
}

- (NSString *)processToText:(NSString *)source
{
    NSString *str = [source stripHtml];
    str = [str stringByReplacingOccurrencesOfRegex:@"\\[[a-z]+[0-9]+\\|([^\\]]+)\\]" withString:@"$1"];
    return str;
}

- (NSString *)processToHTML:(NSString *)source
{
    NSString *str = source;
    str = [str stringByReplacingOccurrencesOfRegex:@"\\[[a-z]+[0-9]+\\|([^\\]]+)\\]" withString:@"$1"];
    return str;
}

- (SFeedEntry *)parseFeedEntry:(NSDictionary *)entryData
{
    NSString *objectId = [entryData[@"id"] stringValue];

    SFeedEntry *entry = (id) [self mediaObjectForId:objectId type:@"post"];

    entry.postId = objectId;
    entry.message = [self processToText:entryData[@"text"]];
    entry.htmlMessage = [self processToHTML:entryData[@"text"]];

    entry.date = [NSDate dateWithTimeIntervalSince1970:[entryData[@"date"] doubleValue]];

    entry.author = [self dataForUserId:[entryData[@"from_id"] stringValue]];
    entry.owner = [self dataForUserId:self.userId];
    entry.attachments = [self parseAttachments:entryData[@"attachments"]];
    entry.commentsCount = @([entryData[@"comments"][@"count"] intValue]);
    entry.canAddComment = @([entryData[@"comments"][@"can_post"] boolValue]);

    entry.likesCount = @([entryData[@"likes"][@"count"] intValue]);
    entry.canAddLike = @([entryData[@"likes"][@"can_like"] boolValue]);
    entry.userLikes = @([entryData[@"likes"][@"user_likes"] boolValue]);

    entry.canDelete = @YES;
    entry.deletionSelector = @selector(removeFeedEntry:completion:);

    return entry;
}

- (SObject *)removeFeedEntry:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"wall.delete" parameters:@{@"post_id" : params.objectId} operation:operation processor:^(id response) {

            if ([response isKindOfClass:[NSNumber class]]) {
                if ([response intValue] == 1) {

                    params.deleted = @YES;
                    [params fireUpdateNotification];
                    [operation complete:[SObject successful]];
                    return;
                }
            }
            [operation complete:[SObject failed]];
        }];
    }];
}

- (SObject *)parseCommentEntries:(NSArray *)response object:(SObject *)object paging:(SObject *)paging
{
    SObject *result = [self parsePagingResponce:response paging:paging processor:^(id data) {
        SCommentData *comment = [self parseCommentEntry:data];
        comment.commentedObject = object;
        return comment;
    }];
    [(id) result setCommentedObject:object];
    result.pagingSelector = @selector(pageFeedComments:completion:);
    return result;
}

- (SCommentData *)parseCommentEntry:(NSDictionary *)entryData
{
    SCommentData *entry = [[SCommentData alloc] initWithHandler:self];

    entry.message = [self processToText:entryData[@"text"]];
    entry.htmlMessage = [self processToHTML:entryData[@"text"]];

    entry.date = [NSDate dateWithTimeIntervalSince1970:[entryData[@"date"] doubleValue]];
    entry.author = [self dataForUserId:[entryData[@"from_id"] stringValue]];
    entry.objectId = [entryData[@"cid"] stringValue];

    if (entryData[@"message"]) {
        entry.message = [entryData[@"message"] stripHtml];
    }
    return entry;
}

- (void)uploadAttachments:(NSArray *)attachments owner:(SUserData *)owner destination:(NSString *)destination operation:(SocialConnectorOperation *)operation completion:(void (^)(NSArray *))completion
{
    if (!attachments.count) {
        completion(nil);
        return;
    }
    // load attachments if needed
    NSMutableArray *uploadedObjects = [NSMutableArray arrayWithCapacity:1];

    if (attachments.count) {
        // upload photos
        [attachments asyncEach:^(SPhotoData *atatchment, ISArrayAsyncEachResultBlock next) {
            SPhotoData *object = [atatchment copy];
            object.operation = operation;

            if(owner) {
                object.owner = owner;
            }

            if ([object.mediaType isEqualToString:@"photo"]) {
                [self uploadPhoto:object album:destination operation:operation completion:^(SObject *result) {

                    if (result.isFailed) {
                        NSError *error = result.error;
                        if (!error) error = [NSError errorWithDomain:@"VKApi" code:100 userInfo:nil];
                        next(error);
                    }
                    else {
                        [uploadedObjects addObject:result];
                        next(nil);
                    }
                }];
            }
            else if ([object.mediaType isEqualToString:@"video"]) {

                [self addVideo:(id) object completion:^(SObject *result) {

                    if (result.isFailed) {
                        NSError *error = result.error;
                        if (!error) error = [NSError errorWithDomain:@"VKApi" code:100 userInfo:nil];
                        next(error);
                    }
                    else {
                        [uploadedObjects addObject:result];
                        next(nil);
                    }
                }];
            }
            else if ([object.mediaType isEqualToString:@"audio"]) {
                [self addAudio:(id) object completion:^(SObject *result) {
                    if (result.isFailed) {
                        NSError *error = result.error;
                        if (!error) error = [NSError errorWithDomain:@"VKApi" code:100 userInfo:nil];
                        next(error);
                    }
                    else {
                        [uploadedObjects addObject:result];
                        next(nil);
                    }
                }];
            }
            else {
                next(nil);
            }

        }          comletition:^(NSError *errorOrNil) {
            if (errorOrNil)
                [operation completeWithError:errorOrNil];
            else {
                completion(uploadedObjects);
                return;
            }
        }];
        return;
    }
    completion(uploadedObjects);
}

- (SObject *)sendInvitation:(SInvitation *)params completion:(SObjectCompletionBlock)completion
{
    SFeedEntry* feed = [SFeedEntry new];
    feed.message = params.message;
    feed.owner = params.user;

    return [self postToFeed:feed completion:completion];
}

- (SObject *)postToFeed:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self uploadAttachments:params.attachments owner:params.owner destination:kWallAlbum operation:operation completion:^(NSArray *attachments)
        {

            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

            if (params.message.length) {
                parameters[@"message"] = params.message;
            }

            NSLog(@"params = %@", params);

            NSString *ownerId = self.userId;
            if (params.owner) {
                ownerId = params.owner.objectId;
                parameters[@"owner_id"] = params.owner.objectId;
            }

            if (attachments.count) {
                NSString *attach = [[[(NSArray *) attachments rac_sequence] map:^id(id <SMultimediaObject> obj)
                {
                    return [NSString stringWithFormat:@"%@%@", obj.mediaType, obj.objectId];
                }].array componentsJoinedByString:@","];

                parameters[@"attachments"] = attach;
            }

            [self simpleMethod:@"wall.post" parameters:parameters operation:operation processor:^(id response){

                if([params[kNoResultObjectKey] boolValue]) {
                    [operation complete:[SObject successful]];
                    return;
                }

                NSString *localPostId = response[@"post_id"];
                NSString *postId = [NSString stringWithFormat:@"%@_%@", ownerId, response[@"post_id"]];

                [self simpleMethod:@"wall.getById" parameters:@{@"posts" : postId} operation:operation processor:^(id response){
                    SFeedEntry *feedEntry = nil;

                    for (id entry in response) {
                        if ([entry isKindOfClass:[NSDictionary class]]) {
                            feedEntry = [self parseFeedEntry:entry];
                            break;
                        }
                    }
                    if (feedEntry)
                        [operation complete:feedEntry];
                    else if(localPostId.length){
                        [operation complete:[SObject successful]];
                    }
                    else {
                        [operation completeWithFailure];
                    }

                }];

            }];
        }];
    }];
}




@end