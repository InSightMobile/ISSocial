//
//

#import "FacebookConnector+Photos.h"
#import "SPhotoData.h"
#import "SPhotoAlbumData.h"
#import "NSDate+Facebook.h"
#import "NSString+TypeSafety.h"
#import "FacebookConnector+UserData.h"
#import "MultiImage.h"
#import "SCommentData.h"
#import "NSArray+ISSAsyncBlocks.h"
#import "SReadAlbumsParameters.h"
#import "SPagingData.h"


static NSString *const kAlbumCoverPhotoKey = @"fb_cover_photo";

static const int kPageSize = 20;

@implementation FacebookConnector (Photos)

- (SObject *)parsePhoto:(id)data {
    NSLog(@"data = %@", data);

    NSString *objectId = [data[@"id"] stringValue];

    if (data[@"object_id"]) {
        objectId = [data[@"object_id"] stringValue];
    }

    if (data[@"fbid"]) {
        objectId = [data[@"fbid"] stringValue];
    }

    if (data[@"pid"]) {
        objectId = [data[@"pid"] stringValue];
    }

    SPhotoData *result = (SPhotoData *) [self mediaObjectForId:objectId type:@"photo"];

    NSString *userId = [data[@"owner"] stringValue];

    if (data[@"from"]) {
        userId = [data[@"from"] stringValue];
    }

    if (userId) {
        result.author = [self dataForUserId:userId];
    }

    result.date = [NSDate dateWithFacebookString:data[@"updated_time"]];

    if (data[@"modified"]) {
        result.date = [NSDate dateWithTimeIntervalSince1970:[data[@"modified"] doubleValue]];
    }


    MultiImage *images = [MultiImage new];

    if (data[@"images"]) {
        for (NSDictionary *image in data[@"images"]) {
            int width = [image[@"width"] intValue];
            int height = [image[@"height"] intValue];
            NSURL *url = [image[@"src"] URLValue];
            if (image[@"source"]) {
                url = [image[@"source"] URLValue];
            }

            if (url) {
                [images addImageURL:url forWitdh:width height:height];
            }
        }
    }
    else {
        [images addImageURL:[data[@"picture"] URLValue] quality:1];
    }

    if (images.count) {
        result.multiImage = images;
        //result.preiewURL = images.previewURL;
        //result.photoURL = images.previewURL;
    }

    return result;
}

- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self readAllPhotos:params completion:completion];
}

- (SObject *)readUploadedPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"me/photos/uploaded" operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SObject *result = [[SObject alloc] initWithHandler:self];

            for (id photoData in response[@"data"]) {
                [result addSubObject:[self parsePhoto:photoData]];
            }
            [operation complete:result];
        }];
    }];
}

- (SObject *)readAllPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        SObject *result = [SObject objectCollectionWithHandler:self];

        [self readPhotoAlbums:operation.object completion:^(SObject *albums) {

            if (!albums.isSuccessful) {
                [operation complete:albums];
                return;
            }

            NSArray *albumObjects = albums.subObjects;

            [albumObjects asyncEach:^(SPhotoAlbumData *albumData, ISArrayAsyncEachResultBlock next) {

                [self readPhotosFromAlbum:albumData completion:^(SObject *photos) {

                    if (!albums.isSuccessful) {
                        next(albums.error);
                        return;
                    }

                    [result addSubObjects:photos.subObjects];
                    next(nil);
                }];

            }           comletition:^(NSError *errorOrNil) {

                if (errorOrNil) {
                    [operation completeWithError:errorOrNil];
                }
                else {
                    [operation complete:result];
                }

            }];
        }];
    }];
}

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion {
    if (!params.objectId) {
        return [self readUploadedPhotos:params completion:completion];
    }

    NSString *method = [NSString stringWithFormat:@"%@/photos", params.objectId];
    NSDictionary *parameters = @{@"limit" : [@(kPageSize) stringValue]};

    return [self fetchDataWithPath:method parameters:parameters params:params completion:completion processor:^(NSDictionary *response, SocialConnectorOperation *operation) {

        NSLog(@"response = %@", response);
        SObject *result = [[SObject alloc] initWithHandler:self];

        for (id photoData in response[@"data"]) {
            [result addSubObject:[self parsePhoto:photoData]];
        }

        [operation complete:result];

    }];
}

- (SObject *)parsePhotosWithResponse:(NSDictionary *)response method:(NSString *)method parameters:(NSDictionary *)parameters {
    SObject *result = [[SObject alloc] initWithHandler:self];

    for (id photoData in response[@"data"]) {
        [result addSubObject:[self parsePhoto:photoData]];
    }

    SPagingData *paging = [SPagingData objectWithHandler:self];
    paging.anchor = response[@"paging"][@"cursors"][@"after"];
    paging.method = method;
    paging.params = parameters;

    result.pagingObject = paging;
    result.isPagable = @(response[@"paging"][@"next"] != nil);
    result.pagingSelector = @selector(pagePhotos:completion:);
    return result;
}

- (SObject *)pagePhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    SPagingData *paging = params.pagingObject;
    NSMutableDictionary *parameters = [paging.params mutableCopy];

    parameters[@"after"] = paging.anchor;

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *method = paging.method;
        [self simpleMethod:method params:parameters operation:operation processor:^(NSDictionary *response) {

            NSLog(@"response = %@", response);
            SObject *result = [self parsePhotosWithResponse:response method:method parameters:nil];

            [operation complete:[self addPagingData:result to:params]];
        }];
    }];


}

/*
- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(CompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:[NSString stringWithFormat:@"%@/photos", params.objectId] operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SObject *result = [[SObject alloc] initWithHandler:self];

            for (id photoData in response[@"data"]) {
                [result addSubObject:[self parsePhoto:photoData]];
            }
            [operation complete:result];
        }];
    }];
}
*/

/*
- (SObject *)readPhotoComments:(SPhotoData *)params completion:(CompletionBlock)completion
{

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:[NSString stringWithFormat:@"%@/comments", params.objectId] operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseComments:response forObject:params];
            [operation complete:result];
        }];
    }];
}

- (SObject *)addPhotoComment:(SCommentData *)comment completion:(CompletionBlock)completion
{
    NSLog(@"comment = %@", comment);

    return [self operationWithObject:comment completion:completion processor:^(SocialConnectorOperation *operation) {

        [self checkAuthorizationFor:@[@"publish_stream"] operation:operation processor:^(id res) {

            [self simplePost:[NSString stringWithFormat:@"%@/comments", [comment.commentedObject objectId]]
                      object:@{@"message" : comment.message}
                   operation:operation processor:^(id response) {

                NSLog(@"response = %@", response);

                SCommentData *result = [comment copyWithHandler:self];
                result.objectId = response[@"id"];
                [operation complete:result];
            }];
        }];
    }];
}
*/

- (SObject *)createPhotoAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self checkAuthorizationFor:@[@"publish_actions"] operation:operation processor:^(id obj) {

            NSString *title = params.title;
            NSString *desc = params.title;

            [self simpleMethod:@"GET" path:@"me/albums" params:nil object:@{@"name" : title, @"message" : desc} operation:operation processor:^(NSArray *response) {

                NSLog(@"response = %@", response);
                NSDictionary *albumData = (id) response;
                SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
                album.objectId = albumData[@"id"];
                album.title = albumData[@"name"];
                album.photoAlbumDescription = albumData[@"description"];

                [operation complete:album];
            }];
        }];
    }];
}

- (void)readWallAlbumWithOperation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion {
    if (self.wallAlbum) {
        completion(self.wallAlbum);
        return;
    }

    [self simpleMethod:@"me/albums" operation:operation processor:^(NSDictionary *response) {

        NSLog(@"response = %@", response);
        NSArray *data = response[@"data"];

        SObject *albums = [SObject objectCollectionWithHandler:self];
        for (NSDictionary *albumData in data) {

            SPhotoAlbumData *album = [self parseAlbumData:albumData];

            if ([albumData[@"type"] isEqualToString:@"wall"]) {
                [albums addSubObject:album];
            }
        }
        if (albums.subObjects.count) {
            self.wallAlbum = albums.subObjects[0];
            completion(self.wallAlbum);
        }
        else {
            completion([SObject failed]);
        }
    }];
}

- (SPhotoAlbumData *)parseAlbumData:(NSDictionary *)albumData {
    SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
    album.objectId = albumData[@"id"];
    album.title = albumData[@"name"];
    album.sortGroup = @1;
    album.photoAlbumDescription = albumData[@"description"];
    album.photoCount = albumData[@"count"];
    album.canUpload = albumData[@"can_upload"];
    album.type = albumData[@"type"];
    album.imageID = [albumData[@"cover_photo"] stringValue];

    album.isEmpty = @(album.photoCount.integerValue == 0);

    return album;
}


- (SObject *)readPhotoAlbums:(SReadAlbumsParameters *)params
                  completion:
                          (SObjectCompletionBlock)completion {
    NSString *fields = @"id,name,description,count,can_upload,type,cover_photo";

    return [self fetchDataWithPath:@"me/albums" parameters:@{@"fields" : fields} params:params completion:completion processor:^(NSDictionary *response, SocialConnectorOperation *operation) {


        NSLog(@"response = %@", response);
        NSArray *data = response[@"data"];

        SObject *albums = [SObject objectCollectionWithHandler:self];

        SPhotoAlbumData *allObjectsAlbum = [[SPhotoAlbumData alloc] initWithHandler:self];
        allObjectsAlbum.title = NSLocalizedString(@"ISSocial_AllPhotosAlbumTitle", @"All photos");
        allObjectsAlbum.sortGroup = @0;
        [albums addSubObject:allObjectsAlbum];
        allObjectsAlbum.type = @"all";

        for (NSDictionary *albumData in data) {

            SPhotoAlbumData *album = [self parseAlbumData:albumData];

            if (![albumData[@"type"] isEqualToString:@"wall"]) {
                [albums addSubObject:album];
            }
        }

        if (params.loadImage.boolValue) {

            [albums.subObjects asyncEach:^(SPhotoAlbumData *album, ISArrayAsyncEachResultBlock next) {
                dispatch_async(dispatch_get_main_queue(), ^{

                    NSObject *coverPhoto = album.imageID;
                    if (coverPhoto) {
                        [self simpleMethod:[NSString stringWithFormat:@"%@/", coverPhoto]
                                 operation:operation processor:^(id response) {
                                    NSLog(@"response = %@", response);

                                    SPhotoData *photo = [self parsePhoto:response];
                                    album.multiImage = photo.multiImage;
                                    next(nil);
                                }];
                    }
                    else {
                        next(nil);
                    }

                });

            }                comletition:^(NSError *errorOrNil) {

                [operation complete:albums];

            }                  concurent:4];
        }
        else {
            [operation complete:albums];
        }

        [operation complete:albums];
    }];
}

- (SObject *)getDefaultPhotoAlbum:(SObject *)params
                       completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"me/albums" operation:operation processor:^(NSDictionary *response) {

            NSLog(@"response = %@", response);
            NSArray *data = response[@"data"];
            if (data.count) {
                for (NSDictionary *albumData in data) {
                    SPhotoAlbumData *album = [self parseAlbumData:albumData];
                    if (album.canUpload.boolValue) {
                        if ([album.title isEqualToString:self.defaultAlbumName]) {
                            [operation complete:album];
                            return;
                        }
                        if ([album.title isEqualToString:[NSString stringWithFormat:@"%@ Photos", self.defaultAlbumName]]) {
                            [operation complete:album];
                            return;
                        }
                    }
                }
            }
            SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];
            album.title = self.defaultAlbumName;
            [self createPhotoAlbum:album completion:completion];
        }];
    }];
}

- (SObject *)addPhotoToAlbum:(SPhotoData *)params
                  completion:
                          (SObjectCompletionBlock)completionn {
    return [self addPhotoWithParams:params completion:completionn];
}

- (SObject *)addPhoto:(SPhotoData *)srcParams
           completion:
                   (SObjectCompletionBlock)completion {
    SPhotoData *params = [srcParams copy];
    params.album = nil;

    return [self addPhotoWithParams:params completion:completion];
}

- (SObject *)addPhotoWithParams:(SPhotoData *)params
                     completion:
                             (SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        SPhotoAlbumData *photoAlbum = params.album;
        if (!photoAlbum) {
            photoAlbum = [(id) self.connectorState album];
            if (!photoAlbum) {
                [self getDefaultPhotoAlbum:operation.object completion:^(SObject *result) {

                    if (result.isFailed) {
                        [operation complete:result];
                        return;
                    }

                    SPhotoData *obj = [params copy];
                    obj.album = result;
                    obj.operation = operation;
                    [self addPhotoWithParams:obj completion:completion];
                }];
                return;
            }
            SPhotoData *obj = [params copy];
            obj.album = photoAlbum;
            obj.operation = operation;
            [self addPhotoWithParams:obj completion:completion];
            return;
        }

        NSString *path = [NSString stringWithFormat:@"%@/photos", photoAlbum.objectId];
        [self uploadPhoto:params toPath:path operation:operation completion:^(SObject *result) {
            [operation complete:result];
        }];
    }];
}

- (void)uploadPhoto:(SPhotoData *)photo
             toPath:(NSString *)path
          operation:(SocialConnectorOperation *)operation
         completion:(SObjectCompletionBlock)completion {

    [self checkAuthorizationFor:@[@"publish_actions"] operation:operation processor:^(id obj) {
        NSMutableDictionary *params = [NSMutableDictionary new];

        params[@"source"] = photo.sourceImage;
        if (photo.title.length) {
            params[@"message"] = photo.title;
        }
        [self requestWithGraphPath:path parameters:params HTTPMethod:@"POST" operation:operation processor:^(id response) {
            NSString *photoId = response[@"id"];
            [self simpleMethod:photoId operation:operation processor:^(id response) {
                NSLog(@"response = %@", response);
                SObject *result = [self parsePhoto:response];
                completion(result);
            }];
        }];
    }];
}

- (SObject *)addPhotoLike:(SPhotoData *)feed
               completion:
                       (SObjectCompletionBlock)completion {
    return [self addFeedLike:(id) feed completion:completion];
}

- (SObject *)removePhotoLike:(SPhotoData *)feed
                  completion:
                          (SObjectCompletionBlock)completion {
    return [self removeFeedLike:(id) feed completion:completion];
}

- (SObject *)addPhotoComment:(SPhotoData *)comments
                  completion:
                          (SObjectCompletionBlock)completion {
    return [self addFeedComment:(id) comments completion:completion];
}

- (SObject *)readPhotoComments:(SPhotoData *)feed
                    completion:
                            (SObjectCompletionBlock)completion {
    return [self readFeedComments:(id) feed completion:completion];
}


@end