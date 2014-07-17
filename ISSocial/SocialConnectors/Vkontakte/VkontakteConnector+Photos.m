//
//


#import "VkontakteConnector.h"
#import "VkontakteConnector+Photos.h"
#import "SPhotoData.h"
#import "SPhotoAlbumData.h"
#import "NSString+TypeSafety.h"
#import "VkontakteConnector+UserData.h"
#import "MultiImage.h"
#import "SCommentData.h"
#import "VkontakteConnector+Feed.h"
#import "SUserData.h"
#import "SPagingData.h"


static const int kPageSize = 20;

@implementation VkontakteConnector (Photos)

- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *method = @"photos.getAll";
        NSDictionary *parameters = @{@"photo_sizes" : @1, @"extended" : @1, @"count" : @(kPageSize)};

        [self readPhotosWithMethod:method parameters:parameters operation:operation];
    }];
}

- (void)readPhotosWithMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation
{
    [self simpleMethod:method parameters:parameters operation:operation processor:^(id response) {
        NSInteger totalCount = [response[@"count"] integerValue];
        NSArray *items = response[@"items"];
        SObject *photos = [self parsePhotos:items];

        if (photos.subObjects.count < totalCount) {
            SPagingData *pagingData = [SPagingData objectWithHandler:self];

            pagingData.method = method;
            pagingData.params = parameters;

            photos.pagingData = pagingData;
            photos.isPagable = @YES;
            photos.pagingSelector = @selector(pagePhotos:completion:);
        }

        [operation complete:photos];
    }];
}

- (SObject *)pagePhotos:(SPhotoData *)pagePhotos completion:(SObjectCompletionBlock)completion
{

    return [self operationWithObject:pagePhotos completion:completion processor:^(SocialConnectorOperation *operation) {

        SPagingData *pagingData = pagePhotos.pagingData;

        NSString *method = pagingData.method;
        NSMutableDictionary *parameters = [pagingData.params mutableCopy];
        parameters[@"offset"] = @(pagePhotos.subObjects.count);

        [self simpleMethod:method parameters:parameters
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            NSInteger totalCount = [response[@"count"] integerValue];
            NSArray *items = response[@"items"];

            SObject *photos = [self parsePhotos:items];
            photos.pagingSelector = @selector(pagePhotos:completion:);
            photos.pagingData = pagingData;

            SObject *object = [self addPagingData:photos to:pagePhotos];

            object.isPagable = @(object.subObjects.count < totalCount);

            [operation complete:object];
        }];
    }];
}


- (SObject *)parsePhotoCommentEntries:(NSArray *)response object:(SObject *)object paging:(SObject *)paging
{
    SObject *result = [self parsePagingResponce:response paging:paging processor:^(id data) {
        SCommentData *comment = [self parseCommentEntry:data];
        comment.commentedObject = object;
        return comment;
    }];
    [(id) result setCommentedObject:object];
    result.pagingSelector = @selector(pagePhotoComments:completion:);
    return result;
}

- (SObject *)pagePhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    SPhotoData *commentObject = (id) [(id) params commentedObject];

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.getComments" parameters:@{
                @"pid" : commentObject.photoId,
                @"owner_id" : commentObject.author.objectId,
                @"offset" : params.pagingData,
                @"count" : @(self.pageSize),
                @"sort" : @"desc"}
                 operation:operation processor:^(NSArray *response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parsePhotoCommentEntries:response object:params paging:nil];
            [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {
                [operation complete:[self addPagingData:result to:params]];
            }];
        }];
    }];
}


- (SObject *)readPhotoComments:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.getComments" parameters:@{
                @"pid" : params.photoId,
                @"owner_id" : params.author.objectId,
                @"sort" : @"desc",
        }        operation:operation processor:^(NSArray *response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parsePhotoCommentEntries:response object:params paging:nil];
            [self updateUserData:[result.subObjects valueForKey:@"author"] operation:operation completion:^(SObject *updateResult) {

                if (result.totalCount) {
                    params.commentsCount = result.totalCount;
                    [params fireUpdateNotification];
                }
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)parsePhotos:(NSArray *)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];
    for (NSDictionary *photoInfo in response) {

        if ([photoInfo isKindOfClass:[NSDictionary class]]) {
            SPhotoData *photoData = [self parsePhotoResponse:photoInfo];
            [result addSubObject:photoData];
        }
    }
    return result;
}


- (SObject *)addPhotoComment:(SCommentData *)params completion:(SObjectCompletionBlock)completion
{
    NSLog(@"params = %@", params);
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.createComment" parameters:@{
                @"pid" : [(SPhotoData *) params.commentedObject photoId],
                @"owner_id" : [(SPhotoData *) params.commentedObject author].objectId,
                @"message" : params.message}
                 operation:operation processor:^(id response) {

            //NSLog(@"response = %@", response);
            SCommentData *comment = [params copyWithHandler:self];

            SPhotoData *photo = comment.commentedObject;


            comment.objectId = [response stringValue];

            photo.commentsCount = @(photo.commentsCount.intValue + 1);
            [photo fireUpdateNotification];
            [operation complete:comment];
        }];
    }];
}

- (SObject *)addPhotoLike:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self addLike:params operation:operation type:@"photo" itemId:params.photoId owner:params.author];
    }];
}

- (SObject *)removePhotoLike:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self removeLike:params operation:operation type:@"photo" itemId:params.photoId owner:params.author];
    }];
}


- (SObject *)createPhotoAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.createAlbum" parameters:@{@"title" : params.title} operation:operation processor:^(NSArray *response) {

            NSDictionary *albumData = (id) response;
            SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
            album.objectId = albumData[@"aid"];
            album.title = albumData[@"title"];
            album.photoCount = @([albumData[@"size"] integerValue]);
            [operation complete:album];
        }];
    }];
}

- (SObject *)readPhotoAlbums:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.getAlbums" parameters:@{@"need_covers" : @1, @"need_system" : @1} operation:operation processor:^(NSDictionary *response) {


            NSArray *items = response[@"items"];

            SObject *albums = [SObject objectCollectionWithHandler:self];

            SPhotoAlbumData *allObjectsAlbum = [[SPhotoAlbumData alloc] initWithHandler:self];
            allObjectsAlbum.title = NSLocalizedString(@"ISSocial_AllPhotosAlbumTitle", @"All photos");
            allObjectsAlbum.sortGroup = @0;
            allObjectsAlbum.type = @"all";
            [albums addSubObject:allObjectsAlbum];

            for (NSDictionary *albumData in items) {

                NSString *objectId = [albumData[@"id"] stringValue];

                SPhotoAlbumData *album = [self mediaObjectForId:objectId type:@"album"];
                album.title = albumData[@"title"];
                album.sortGroup = @1;
                album.photoCount = @([albumData[@"size"] integerValue]);
                album.date = [NSDate dateWithTimeIntervalSince1970:[albumData[@"updated"] doubleValue]];
                album.totalCount = album.photoCount;
                album.canUpload = @YES;
                if (albumData[@"thumb_src"]) {
                    album.multiImage = [[MultiImage alloc] initWithURL:[albumData[@"thumb_src"] URLValue]];
                }
                album.imageID = [albumData[@"thumb_id"] stringValue];
                [albums addSubObject:album];

                album.isEmpty = @(album.photoCount.integerValue == 0);
            }
            [operation complete:albums];
        }];
    }];
}

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion
{
    if (!params.objectId) {
        return [self readPhotos:params completion:completion];
    }

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self readPhotosWithMethod:@"photos.get"
                        parameters:@{
                                @"album_id" : params.objectId,
                                @"owner_id" : self.userId,
                                @"photo_sizes" : @1,
                                @"extended" : @1,
                                @"count" : @(kPageSize),
                                @"rev" : @1}
                         operation:operation];

    }];
}


- (SObject *)getDefaultPhotoAlbum:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.getAlbums" operation:operation processor:^(NSArray *response) {

            //NSLog(@"response = %@", response);
            if ([response count]) {
                NSDictionary *albumData = [response objectAtIndex:0];
                SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
                album.objectId = albumData[@"id"];
                album.title = albumData[@"title"];
                album.photoCount = @([albumData[@"size"] integerValue]);
                [operation complete:album];
            }
            else { // create new album
                SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
                album.operation = operation;
                album.title = self.defaultAlbumName;
                [self createPhotoAlbum:album completion:operation.completion];
            }
        }];
    }];
}

- (SPhotoData *)parsePhotoResponse:(NSDictionary *)response
{
    NSString *objectId;
    NSString *photoId;

    if (response[@"pid"]) {
        photoId = [response[@"pid"] stringValue];
    }

    if (response[@"id"]) {
        photoId = [response[@"id"] stringValue];
        objectId = photoId;
    }

    if (response[@"pid"] && response[@"owner_id"]) {
        objectId = [NSString stringWithFormat:@"%@_%@", response[@"owner_id"], response[@"pid"]];
    }

    //NSLog(@"response = %@", response);
    SPhotoData *data = (SPhotoData *) [self mediaObjectForId:objectId type:@"photo"];

    data.photoId = photoId;

    SPhotoAlbumData *photoAlbum = [self mediaObjectForId:[response[@"aid"] stringValue] type:@"album"];
    data.album = photoAlbum;

    data.author = [self dataForUserId:[response[@"owner_id"] stringValue]];
    data.owner = data.author;

    data.title = response[@"text"];

    MultiImage *images = [MultiImage new];

    if (response[@"comments"]) {
        data.commentsCount = @([response[@"comments"][@"count"] intValue]);
        data.canAddComment = @([response[@"comments"][@"can_post"] boolValue]);
    }
    else {
        data.canAddComment = @YES;
    }

    if (response[@"likes"]) {
        data.likesCount = @([response[@"likes"][@"count"] intValue]);
        data.canAddLike = @([response[@"likes"][@"can_like"] boolValue]);
        data.userLikes = @([response[@"likes"][@"user_likes"] boolValue]);
    }
    else {
        data.canAddLike = @YES;
    }

    if (response[@"sizes"]) {
        for (NSDictionary *image in response[@"sizes"]) {
            int width = [image[@"width"] intValue];
            int height = [image[@"height"] intValue];
            NSURL *url = [image[@"src"] URLValue];
            if (url) {
                [images addImageURL:url forWitdh:width height:height];
            }
        }
    }
    else {
        [images setBaseQuality:1.0
                      forWitdh:[response[@"width"] intValue]
                        height:[response[@"height"] intValue]];

        [images addImageURL:[response[@"src_small"] URLValue] forSize:75];
        [images addImageURL:[response[@"src"] URLValue] forSize:130];
        [images addImageURL:[response[@"src_big"] URLValue] quality:0.25];
        [images addImageURL:[response[@"src_xbig"] URLValue] quality:0.5];
        [images addImageURL:[response[@"src_xxbig"] URLValue] quality:1];
    }

    if (images.count) {
        data.multiImage = images;
        data.previewURL = images.previewURL;
        data.photoURL = images.previewURL;
    }
    else {

    }

    data.canDelete = @([data.owner.objectId isEqualToString:self.currentUserData.objectId]);
    data.deletionSelector = @selector(removePhoto:completion:);

    return data;
}

- (SObject *)removePhoto:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.delete" parameters:@{
                @"pid" : params.photoId,
                @"oid" : params.author.objectId}
                 operation:operation processor:^(id responce) {

            NSLog(@"o = %@", responce);

            if ([responce intValue] == 1) {

                params.deleted = @YES;
                [params fireUpdateNotification];
                [operation complete:params];
            }
            else {
                [operation completeWithFailure];
            }
        }];
    }];
}

- (SObject *)readPhotoLikes:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self readLikes:params operation:operation type:@"photo" itemId:params.photoId owner:params.author];
    }];
}


- (void)uploadPhoto:(SPhotoData *)params
              album:(NSString *)album
          operation:(SocialConnectorOperation *)operation
         completion:(SObjectCompletionBlock)completionn
{
    NSString *uploadServer, *saveMethod;
    NSDictionary *parameters;

    if ([album isEqualToString:kWallAlbum]) {
        uploadServer = @"photos.getWallUploadServer";
        saveMethod = @"photos.saveWallPhoto";
        parameters = nil;
    }

    else if ([album isEqualToString:kMessageAlbum]) {
        uploadServer = @"photos.getMessagesUploadServer";
        saveMethod = @"photos.saveMessagesPhoto";
        parameters = nil;

    }
    else if (album) {
        uploadServer = @"photos.getUploadServer";
        saveMethod = @"photos.save";
        parameters = @{@"aid" : album};
    }
    else {
        uploadServer = @"photos.getWallUploadServer";
        saveMethod = @"photos.saveWallPhoto";
        parameters = nil;
    }
    [self uploadPhoto:params uploadServer:uploadServer saveMethod:saveMethod operation:operation completion:completionn];
}

- (void)uploadMessagePhoto:(SPhotoData *)params
                 operation:(SocialConnectorOperation *)operation
                completion:(SObjectCompletionBlock)completionn
{
    NSString *uploadServer, *saveMethod;

    uploadServer = @"photos.getMessagesUploadServer";
    saveMethod = @"photos.saveMessagesPhoto";
    [self uploadPhoto:params uploadServer:uploadServer saveMethod:saveMethod operation:operation completion:completionn];
}

- (void)uploadPhoto:(SPhotoData *)params uploadServer:(NSString *)uploadServer saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn
{

    NSMutableDictionary *uploadParams = [NSMutableDictionary new];
    if (params.owner) {
        uploadParams[@"uid"] = params.owner.objectId;
    }
    if (params.title.length) {
        uploadParams[@"text"] = params.title;
    }

    VKRequest *request = [VKRequest requestWithMethod:uploadServer andParameters:uploadParams andHttpMethod:@"GET"];

    [self simpleMethod:uploadServer operation:operation processor:^(NSDictionary *response) {

        NSLog(@"response = %@", response);

        [self uploadPhoto:params toURL:response[@"upload_url"] saveMethod:saveMethod operation:operation completion:completionn];
    }];

}

- (void)uploadPhoto:(SPhotoData *)params toURL:(NSString *)URL saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completionn
{

    if (!params.sourceData) {
        if (params.sourceImage) {
            params.sourceData = UIImageJPEGRepresentation(params.sourceImage, 0.5);
        }
    }

    VKUploadImage *photo = [VKUploadImage objectWithData:params.sourceData andParams:[VKImageParameters jpegImageWithQuality:0.5]];

    VKRequest *reqest = [VKRequest photoRequestWithPostUrl:URL withPhotos:@[photo]];

    [self executeRequest:reqest operation:operation processor:^(NSDictionary *result) {

        NSLog(@" result = %@", result);

        [self savePhoto:params saveMethod:saveMethod operation:operation uploadResult:result completion:completionn];

    }            retries:0];
}

- (void)savePhoto:(SPhotoData *)params saveMethod:(NSString *)saveMethod operation:(SocialConnectorOperation *)operation
     uploadResult:(id)uploadResult completion:(SObjectCompletionBlock)completionn
{
    NSMutableDictionary *saveParams = [NSMutableDictionary dictionaryWithDictionary:uploadResult];
    if (params.owner) {
        saveParams[@"uid"] = params.owner.objectId;
    }
    if (params.title.length) {
        saveParams[@"text"] = params.title;
    }

    [self simpleMethod:saveMethod parameters:saveParams operation:operation processor:^(NSArray *response) {
        NSLog(@"response = %@", response);
        NSDictionary *photoData = response[0];
        SPhotoData *photo = [self parsePhotoResponse:photoData];
        completionn(photo);

    }];
}

- (SObject *)addPhotoToAlbum:(SPhotoData *)params completion:(SObjectCompletionBlock)completionn
{
    return [self addPhotoWithParams:params completion:completionn];
}

- (SObject *)addPhoto:(SPhotoData *)srcParams completion:(SObjectCompletionBlock)completionn
{
    SPhotoData *params = [srcParams copy];
    params.album = nil;

    return [self addPhotoWithParams:params completion:completionn];
}

- (SObject *)addPhotoWithParams:(SPhotoData *)params completion:(SObjectCompletionBlock)completionn
{
    return [self operationWithObject:params completion:completionn processor:^(SocialConnectorOperation *operation) {

        SObject *photoAlbum = params.album;
        if (!photoAlbum) {
            photoAlbum = [(id) self.connectorState album];
            if (!photoAlbum) {
                [self getDefaultPhotoAlbum:operation.object completion:^(SObject *result) {

                    if (result.isFailed) {
                        [operation complete:result];
                        return;
                    }
                    SPhotoData *obj = [params copyWithHandler:self];
                    obj.album = result;
                    obj.operation = operation;
                    [self addPhotoWithParams:obj completion:operation.completion];
                }];
                return;
            }
            SPhotoData *obj = [params copyWithHandler:self];
            obj.album = photoAlbum;
            obj.operation = operation;
            [self addPhotoWithParams:obj completion:operation.completion];
        }

        [self uploadPhoto:params album:photoAlbum[@"objectId"] operation:operation completion:^(SObject *result) {

            if (result.isFailed) {
                [operation completeWithError:result.error];
            }
            else {
                [operation complete:result];
            }

        }];
    }];
}

- (SObject *)publishPhoto:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{

    SFeedEntry *entry = [[SFeedEntry alloc] init];
    entry.message = params.title;
    entry.attachments = @[params];
    entry.owner = params.owner;
    entry[kNoResultObjectKey] = @YES;

    return [self postToFeed:entry completion:^(SObject *result)
            {

                completion(result);

            }];


    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self uploadPhoto:params album:kWallAlbum operation:operation completion:^(SObject *result)
                {
                    if (result.isFailed) {
                        [operation completeWithError:result.error];
                    }
                    else {
                        [operation complete:result];
                    }

                }];
    }];
}


@end