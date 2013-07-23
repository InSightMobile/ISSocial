//
// 

#import "VkontakteConnector+News.h"
#import "SUserData.h"
#import "SNewsEntry.h"
#import "VkontakteConnector+UserData.h"
#import "VkontakteConnector+Feed.h"
#import "VkontakteConnector+Photos.h"


@implementation VkontakteConnector (News)

- (SObject *)addNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.addLike"
                parameters:@{@"post_id" : [feed objectId],
                        @"owner_id" : feed.owner.objectId}
                 operation:operation processor:^(id response) {

            SNewsEntry *result = feed;
            result.likesCount = response[@"likes"];
            result.userLikes = @YES;
            [result fireUpdateNotification];
            [operation complete:result];
        }];
    }];
}

- (SObject *)removeNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:feed completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"wall.deleteLike"
                parameters:@{@"post_id" : [feed objectId],
                        @"owner_id" : feed.owner.objectId}
                 operation:operation processor:^(id response) {

            SNewsEntry *result = feed;
            result.likesCount = response[@"likes"];
            result.userLikes = @NO;
            [result fireUpdateNotification];
            [operation complete:result];
        }];
    }];
}

- (SObject *)pageNews:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *parameters = @{@"photo_sizes" : @1,
                @"filters" : @"post,photo",
                @"offset" : params.pagingData[0],
                @"from" : params.pagingData[1],
                @"count" : @(self.pageSize)
        };

        [self simpleMethod:@"newsfeed.get" parameters:parameters operation:operation processor:^(id response) {

            [self parseNewsEntries:response paging:params operation:operation completion:^(SObject *result) {
                [operation complete:[self addPagingData:result to:params]];
            }];
        }];
    }];
}

- (SObject *)readNews:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *parameters = @{@"photo_sizes" : @1, @"filters" : @"post,photo", @"count" : @(self.pageSize)};

        [self simpleMethod:@"newsfeed.get" parameters:parameters operation:operation processor:^(id response) {
            [self parseNewsEntries:response paging:nil operation:operation completion:^(SObject *result) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)searchNews:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSMutableDictionary *parameters =
                [@{@"photo_sizes" : @1, @"filters" : @"post,photo", @"count" : @(self.pageSize)} mutableCopy];

        parameters[@"q"] = params.searchString;

        [self simpleMethod:@"newsfeed.search" parameters:parameters operation:operation processor:^(id response) {
            [self parseNewsEntries:response paging:nil operation:operation completion:^(SObject *result) {
                [operation complete:result];
            }];
        }];
    }];
}


- (void)parseNewsEntries:(id)response paging:(SObject *)paging operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    //NSLog(@"news response = %@", response);

    SObject *result = [SObject objectCollectionWithHandler:self];
    NSMutableArray *attachements = [NSMutableArray array];

    int count = 0;

    if ([response isKindOfClass:[NSArray class]]) {
        for (id entry in response) {
            if ([entry isKindOfClass:[NSNumber class]]) {
                count = [entry intValue];
            }
            else {
                SNewsEntry *data = [self parseNews:entry];
                if (data.attachments.count) {
                    [attachements addObjectsFromArray:data.attachments];
                }
                [result addSubObject:data];
            }
        }

        result.pagingSelector = @selector(pageNews:completion:);

        [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *resa) {
            [self updateAttachments:attachements operation:operation completion:^(SObject *resu) {
                completion(result);
            }];
        }];
    }
    else {
        for (id entry in response[@"items"]) {

            SNewsEntry *data = [self parseNews:entry];
            if (data.attachments.count) {
                [attachements addObjectsFromArray:data.attachments];
            }
            [result addSubObject:data];
        }

        if (response[@"new_offset"] && response[@"new_from"]) {
            result.pagingData = @[response[@"new_offset"], response[@"new_from"]];
            result.isPagable = @(YES);
        }

        for (NSDictionary *profile in response[@"profiles"]) {
            [self parseUserData:profile];
        }

        for (NSDictionary *profile in response[@"groups"]) {
            [self parseUserData:profile];
        }

        result.pagingSelector = @selector(pageNews:completion:);

        [self updateAttachments:attachements operation:operation completion:^(SObject *res) {
            completion(result);
        }];
    }
}

- (SNewsEntry *)parseNews:(NSDictionary *)item
{
    NSString *objectId;
    NSString *postId;
    NSString *ownerId;
    if (item[@"post_id"]) {
        postId = [item[@"post_id"] stringValue];
    }
    if (item[@"id"]) {
        postId = [item[@"id"] stringValue];
    }

    if (item[@"owner_id"]) {
        ownerId = [item[@"owner_id"] stringValue];

        //
    }

    if (item[@"source_id"]) {
        ownerId = [item[@"source_id"] stringValue];
    }

    objectId = [NSString stringWithFormat:@"%@_%@", ownerId, postId];

    SNewsEntry *entry = (SNewsEntry *) [self mediaObjectForId:objectId type:@"post"];

    entry.newsType = item[@"type"];
    entry.message = [self processToText:item[@"text"]];
    entry.htmlMessage = [self processToHTML:item[@"text"]];
    entry.postId = postId;

    entry.author = [self dataForUserId:[item[@"source_id"] stringValue]];

    if (item[@"from_id"]) {
        entry.author = [self dataForUserId:[item[@"from_id"] stringValue]];
    }

    entry.owner = entry.author;
    if (item[@"owner_id"]) {
        entry.owner = [self dataForUserId:[item[@"owner_id"] stringValue]];
    }

    entry.date = [NSDate dateWithTimeIntervalSince1970:[item[@"date"] doubleValue]];

    entry.commentsCount = @([item[@"comments"][@"count"] intValue]);
    entry.canAddComment = @([item[@"comments"][@"can_post"] boolValue]);

    entry.likesCount = @([item[@"likes"][@"count"] intValue]);
    entry.canAddLike = @([item[@"likes"][@"can_like"] boolValue]);
    entry.userLikes = @([item[@"likes"][@"user_likes"] boolValue]);

    NSArray *attachments = item[@"attachments"];
    if (attachments) {
        entry.attachments = [self parseAttachments:attachments];
    }

    NSArray *photoData = item[@"photos"];
    if (photoData) {
        SObject *photos = [self parsePhotos:photoData];
        entry.attachments = photos.subObjects;
    }
    return entry;
}

- (SObject *)readNewsComments:(SNewsEntry *)params completion:(SObjectCompletionBlock)completion
{
    if ([params.newsType isEqualToString:@"post"]) {
        SFeedEntry *feedEntry = [SFeedEntry new];
        feedEntry.objectId = params.objectId;
        feedEntry.postId = params.postId;
        feedEntry.owner = params.owner;
        return [self readFeedComments:feedEntry completion:completion];
    }
    else {
        completion([SObject objectCollectionWithHandler:self]);
        return [SObject successful];
    }
}

- (SObject *)addNewsComment:(SCommentData *)comment completion:(SObjectCompletionBlock)completion
{
    return [self addFeedComment:comment completion:completion];
}

@end