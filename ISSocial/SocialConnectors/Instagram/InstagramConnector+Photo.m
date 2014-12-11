//
// 

#import "InstagramConnector.h"
#import "InstagramConnector+Photo.h"
#import "SFeedEntry.h"
#import "SUserData.h"
#import "SPhotoData.h"
#import "MultiImage.h"
#import "SCommentData.h"
#import "NSString+TypeSafety.h"
#import "SPagingData.h"

@implementation InstagramConnector (Photo)

- (SObject *)readFrom:(NSString *)from params:(SObject *)params paging:(SObject *)paging pageSelector:(SEL)selector completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        NSDictionary *options = nil;
        if (paging) {
            if (!paging.pagingData) {
                [operation complete:[paging copyWithHandler:self]];
                return;
            }
            options = @{@"max_id" : params.pagingData, @"count" : @(self.pageSize)};
        }
        else {
            options = @{@"count" : @(self.pageSize)};
        }

        [self simpleRequest:@"GET" path:from parameters:options operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            SObject *result = [self parseFeedEntries:response];
            result.pagingSelector = selector;
            if (paging) {
                result = [self addPagingData:result to:paging];
            }
            [operation complete:result];
        }];
    }];
}

- (SObject *)parseFeedEntries:(id)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];

    for (NSDictionary *feed in response[@"data"]) {
        [result addSubObject:[self parseFeed:feed]];
    }

    if (result.subObjects.count) {
        result.pagingData = response[@"pagination"][@"next_max_id"];
        result.isPagable = @(result.pagingData != nil);
    }
    return result;
}

- (SObject *)readNews:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self readFrom:@"users/self/feed" params:params paging:nil pageSelector:@selector(pageNews:completion:) completion:completion];
}

- (SObject *)pageNews:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self readFrom:@"users/self/feed" params:params paging:params pageSelector:@selector(pageNews:completion:) completion:completion];
}

- (SObject *)readFeed:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self readFrom:@"users/self/media/recent" params:params paging:nil pageSelector:@selector(pageFeed:completion:) completion:completion];
}

- (SObject *)pageFeed:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self readFrom:@"users/self/media/recent" params:params paging:params pageSelector:@selector(pageFeed:completion:) completion:completion];
}

- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *options = @{@"count" : @(self.pageSize)};

        [self simpleRequest:@"GET" path:@"users/self/media/recent" parameters:options operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *feed in response[@"data"]) {

                [result addSubObject:[self parsePhoto:feed]];
            }

            if (result.subObjects.count) {
                result.pagingData = response[@"pagination"][@"next_max_id"];
                result.isPagable = @(result.pagingData != nil);
            }


            [operation complete:result];

        }];
    }];
}

- (SObject *)parseComment:(NSDictionary *)entry
{

    SCommentData *comment = [[SCommentData alloc] initWithHandler:self];
    NSLog(@"entry = %@", entry);

    comment.message = entry[@"text"];
    comment.objectId = entry[@"id"];
    comment.date = [NSDate dateWithTimeIntervalSince1970:[entry[@"created_time"] doubleValue]];
    id from = entry[@"from"];
    if (from && from != [NSNull null]) {

        SUserData *user = [self dataForUserId:from[@"id"]];
        user.userName = from[@"full_name"];
        user.userPicture = [[MultiImage alloc] initWithURL:[from[@"profile_picture"] URLValue]];

        comment.author = user;
    }
    return comment;
}

- (SObject *)addPhotoComment:(SCommentData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleRequest:@"POST" path:[NSString stringWithFormat:@"media/%@/comments", [params.commentedObject objectId]] parameters:@{@"text" : params.message}
                  operation:operation processor:^(id response) {

            id <SCommentedObject> object = params.commentedObject;

            NSLog(@"response = %@", response);

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *feed in response) {

                [result addSubObject:[self parseComment:feed]];
            }

            object.commentsCount = @(object.commentsCount.intValue + 1);
            [object fireUpdateNotification];

            [operation complete:result];

        }];
    }];
}

- (SObject *)addPhotoLike:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleRequest:@"POST" path:[NSString stringWithFormat:@"media/%@/likes", [params objectId]] parameters:nil operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SPhotoData *result = params;
            result.userLikes = @(YES);
            result.likesCount = @(result.likesCount.intValue + 1);

            [result fireUpdateNotification];
            [operation complete:result];

        }];
    }];
}

- (SObject *)removePhotoLike:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleRequest:@"DELETE" path:[NSString stringWithFormat:@"media/%@/likes", [params objectId]] parameters:nil operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SPhotoData *result = params;
            result.userLikes = @(NO);
            result.likesCount = @(result.likesCount.intValue - 1);

            [result fireUpdateNotification];
            [operation complete:result];

        }];
    }];
}

- (SObject *)addFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self addPhotoLike:(id) feed completion:completion];
}

- (SObject *)removeFeedLike:(SFeedEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self removePhotoLike:(id) feed completion:completion];
}

- (SObject *)addNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self addPhotoLike:(id) feed completion:completion];
}

- (SObject *)removeNewsLike:(SNewsEntry *)feed completion:(SObjectCompletionBlock)completion
{
    return [self removePhotoLike:(id) feed completion:completion];
}

- (SObject *)readPhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *options = @{@"count" : @(self.pageSize)};

        [self simpleRequest:@"GET" path:[NSString stringWithFormat:@"media/%@/comments", params.objectId] parameters:options operation:operation processor:^(id response) {

            SObject *result = [self parseComments:response];
            result.pagingObject = params;

            result.pagingSelector = @selector(pagePhotoComments:completion:);

            [operation complete:result];
        }];
    }];
}

- (SObject *)pagePhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        if (!params.pagingData) {
            [operation complete:[params copyWithHandler:self]];
            return;
        }
        NSDictionary *options = @{@"min_id" : params.pagingData, @"count" : @(self.pageSize)};

        [self simpleRequest:@"GET" path:[NSString stringWithFormat:@"media/%@/comments", params.pagingObject.objectId] parameters:options operation:operation processor:^(id response) {

            SObject *result = [self parseComments:response];

            [operation complete:[self addPagingData:result to:params]];
        }];
    }];
}

- (SObject *)parseComments:(id)response
{
    NSLog(@"response = %@", response);

    SObject *result = [SObject objectCollectionWithHandler:self];

    for (NSDictionary *feed in response[@"data"]) {

        [result addSubObject:[self parseComment:feed]];
    }

    if (response[@"pagination"][@"next_max_id"]) {
        result.pagingData = response[@"pagination"][@"next_max_id"];
        result.isPagable = @YES;
    }
    return result;
}

- (SObject *)readFeedComments:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self readPhotoComments:(id) params completion:completion];
}

- (SObject *)readNewsComments:(SNewsEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self readPhotoComments:(id) params completion:completion];
}

- (SObject *)addFeedComment:(SFeedEntry *)params completion:(SObjectCompletionBlock)completion
{
    return [self addPhotoComment:(id) params completion:completion];
}

- (SFeedEntry *)parseFeed:(NSDictionary *)data
{
    SFeedEntry *feed = [[SFeedEntry alloc] initWithHandler:self];
    SPhotoData *photo = [self parsePhoto:data];

    feed.message = photo.title;
    feed.attachments = @[photo];

    feed.date = photo.date;
    feed.objectId = photo.objectId;
    feed.author = photo.author;
    feed.userLikes = photo.userLikes;
    feed.likesCount = photo.likesCount;
    feed.canAddLike = photo.canAddLike;
    feed.commentsCount = photo.commentsCount;
    feed.canAddComment = photo.canAddComment;

    return feed;
}

- (SPhotoData *)parsePhoto:(NSDictionary *)data
{
    SPhotoData *photo = (SPhotoData *) [self mediaObjectForId:data[@"id"] type:@"photo"];

    id caption = data[@"caption"];
    if (caption && caption != [NSNull null]) {
        photo.title = data[@"caption"][@"text"];
    }

    photo.date = [NSDate dateWithTimeIntervalSince1970:[data[@"created_time"] doubleValue]];


    NSDictionary *imgData = data[@"images"];

    MultiImage *images = [MultiImage new];

    [images setBaseQuality:1 forWitdh:612 height:612];

    [self addImage:imgData[@"thumbnail"] toImages:images qulity:0.2];

    [self addImage:imgData[@"low_resolution"] toImages:images qulity:0.5];

    [self addImage:imgData[@"standard_resolution"] toImages:images qulity:1];

    photo.multiImage = images;

    photo.author = [self parseUser:data[@"user"]];

    photo.likesCount = data[@"likes"][@"count"];
    photo.userLikes = @([data[@"user_has_liked"] boolValue]);
    photo.canAddLike = @YES;

    photo.commentsCount = data[@"comments"][@"count"];
    photo.canAddComment = @NO;

    return photo;
}

- (void)addImage:(NSDictionary *)img toImages:(MultiImage *)images qulity:(float)quality
{
    if([img isKindOfClass:[NSDictionary class]]) {
        [images addImageURL:img[@"url"]
                   forWitdh:[img[@"width"] intValue]
                     height:[img[@"height"] intValue]];
    }
    else if([img isKindOfClass:[NSString class]]) {
        [images addImageURL:[(NSString *)img URLValue] quality:quality];
    }
}

- (SUserData *)parseUser:(NSDictionary *)userData
{
    SUserData *user = [[SUserData alloc] initWithHandler:self];

    MultiImage *image = [MultiImage new];

    [image addImageURL:[NSURL URLWithString:userData[@"profile_picture"]] quality:1];
    user.userPicture = image;

    user.userName = userData[@"username"];
    user.objectId = userData[@"id"];
    return user;
}
@end