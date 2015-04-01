//
// Created by yarry on 18.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <AFNetworking/AFURLRequestSerialization.h>
#import "OdnoklassnikiConnector+Photo.h"
#import "SPhotoData.h"
#import "MultiImage.h"
#import "SPhotoAlbumData.h"
#import "NSDate+Odnoklassniki.h"
#import "NSString+TypeSafety.h"
#import "SPagingData.h"
#import "SReadAlbumsParameters.h"
#import "NSArray+ISSAsyncBlocks.h"

static const int kPhotoPageSize = 20;

@implementation OdnoklassnikiConnector (Photo)

- (SObject *)parsePhotos:(NSDictionary *)responce forMethod:(NSString *)method params:(NSDictionary *)params {
    SObject *photos = [SObject objectCollectionWithHandler:self];

    for (NSDictionary *data in responce[@"photos"]) {

        SPhotoData *photo = (SPhotoData *) [self mediaObjectForId:[data[@"id"] stringValue] type:@"photo"];

        photo.title = data[@"text"];
        photo.commentsCount = @([data[@"comments_count"] intValue]);
        photo.likesCount = @([data[@"likes_count"] intValue]);
        photo.userLikes = @([data[@"liked_it"] intValue]);

        MultiImage *image = [[MultiImage alloc] init];

        if (data[@"pic50x50"]) {
            [image addImageURL:[data[@"pic50x50"] URLValue] forWitdh:50 height:50];
        }
        if (data[@"pic128x128"]) {
            [image addImageURL:[data[@"pic128x128"] URLValue] forWitdh:128 height:128];
        }
        if (data[@"pic190x190"]) {
            [image addImageURL:[data[@"pic190x190"] URLValue] forWitdh:190 height:190];
        }
        if (data[@"pic640x480"]) {
            [image addImageURL:[data[@"pic640x480"] URLValue] forWitdh:640 height:480];
        }
        if (data[@"pic1024X768"]) {
            [image addImageURL:[data[@"pic1024X768"] URLValue] forWitdh:1024 height:768];
        }

        photo.multiImage = image;

        [photos addSubObject:photo];
    }

    if ([responce[@"hasMore"] boolValue]) {

        SPagingData *pagingData = [SPagingData objectWithHandler:self];
        pagingData.method = method;
        pagingData.params = params ?: @{};
        pagingData.anchor = responce[@"anchor"];

        photos.pagingData = pagingData;
        photos.pagingSelector = @selector(pagePhotos:completion:);
        photos.isPagable = @YES;
    }

    return photos;
}

- (SObject *)pagePhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        SPagingData *pagingData = params.pagingData;
        NSMutableDictionary *parameters = [pagingData.params mutableCopy];
        parameters[@"anchor"] = pagingData.anchor;
        parameters[@"direction"] = @"forward";

        [self simpleMethod:pagingData.method parameters:parameters operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            SObject *photos = [self parsePhotos:response forMethod:pagingData.method params:pagingData.params];

            [operation complete:[self addPagingData:photos to:params]];
        }];
    }];
}

- (void)parseAlbums:(id)responce params:(SReadAlbumsParameters *)params operation:(SocialConnectorOperation *)operation {
    SObject *albums = [SObject objectCollectionWithHandler:self];

    if (params.loadAllPhotosMetaAlbum.boolValue) {
        SPhotoAlbumData *allObjectsAlbum = [[SPhotoAlbumData alloc] initWithHandler:self];
        allObjectsAlbum.title = [[NSBundle mainBundle] localizedStringForKey:@"ISSocial_AllPhotosAlbumTitle" value:@"All photos" table:nil];
        allObjectsAlbum.sortGroup = @0;
        [albums addSubObject:allObjectsAlbum];
    }

    for (NSDictionary *data in responce[@"albums"]) {

        SPhotoAlbumData *album = [self parseAlbum:data];
        album.sortGroup = @1;
        [albums addSubObject:album];
    }

    if (params.loadImage.boolValue) {

        [albums.subObjects asyncEach:^(SPhotoAlbumData *album, ISArrayAsyncEachResultBlock next) {

            dispatch_async(dispatch_get_main_queue(), ^{

                [self simpleMethod:@"photos.getPhotos" parameters:@{@"aid" : album.objectId, @"count" : @1} operation:operation processor:^(id response) {
                    NSLog(@"response = %@", response);

                    NSArray *photos = [self parsePhotos:response forMethod:nil params:nil].subObjects;
                    if (photos.count) {
                        SPhotoData *photo = photos[0];
                        album.multiImage = photo.multiImage;
                    }
                    next(nil);
                }];


            });

        }                comletition:^(NSError *errorOrNil) {

            [operation complete:albums];

        }                  concurent:4];
    }
    else {
        [operation complete:albums];
    }
}

- (SPhotoAlbumData *)parseAlbum:(NSDictionary *)data {
    SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];

    album.objectId = [data[@"aid"] stringValue];
    album.title = data[@"title"];
    album.likesCount = @([data[@"like_count"] intValue]);
    album.userLikes = @([data[@"liked_it"] boolValue]);
    album.date = [NSDate dateWithOdnoklassnikiString:data[@"created"]];
    album.canUpload = @YES;
    album.photoCount = data[@"photos_count"];
    album.isEmpty = @(album.photoCount.integerValue == 0);

    return album;
}

- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self loadPhotoWithMethod:@"photos.getPhotos" parameters:nil operation:operation];
    }];
}

- (void)loadPhotoWithMethod:(NSString *)method parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation {
    NSMutableDictionary *params = parameters ? [parameters mutableCopy] : [NSMutableDictionary dictionaryWithCapacity:1];
    params[@"detectTotalCount"] = @1;

    [self simpleMethod:method parameters:params operation:operation processor:^(id response) {
        NSLog(@"response = %@", response);
        [operation complete:[self parsePhotos:response forMethod:method params:parameters]];
    }];
}

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion {
    if (!params.objectId) {
        return [self readPhotos:params completion:completion];
    }

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self loadPhotoWithMethod:@"photos.getPhotos" parameters:@{@"aid" : params.objectId} operation:operation];
    }];
}

- (SObject *)readPhotoAlbums:(SReadAlbumsParameters *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSDictionary *parameters = @{@"fields" : @"album.aid,album.title,album.description,album.created,album.type,album.types,album.type_change_enabled,album.comments_count,album.photos_count,photo.id,photo.pic50x50,photo.pic128x128,photo.pic640x480"};

        [self simpleMethod:@"photos.getAlbums" parameters:parameters operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            [self parseAlbums:response params:params operation:operation];
        }];
    }];
}

- (SObject *)getDefaultPhotoAlbum:(SObject *)params completion:(SObjectCompletionBlock)completion {
    if (self.defaultAlbum) {
        completion(self.defaultAlbum);
        return self.defaultAlbum;
    }

    if (self.defaultAlbumId) {
        self.defaultAlbum = [SPhotoAlbumData objectWithHandler:self];
        self.defaultAlbum.title = self.dafaultPhotoAlbumTitle;
        self.defaultAlbum.objectId = self.defaultAlbumId;
        completion(self.defaultAlbum);
        return self.defaultAlbum;
    }

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.getAlbums" parameters:nil operation:operation processor:^(id responce) {

            for (NSDictionary *data in responce[@"albums"]) {
                SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];

                if ([data[@"title"] isEqualToString:self.dafaultPhotoAlbumTitle]) {
                    self.defaultAlbum = [self parseAlbum:data];
                    self.defaultAlbumId = self.defaultAlbum.objectId;
                }
            }
            if (!self.defaultAlbumId) {
                SPhotoAlbumData *album = [SPhotoAlbumData objectWithHandler:self];
                album.title = self.dafaultPhotoAlbumTitle;
                album.operation = operation;
                [self createPhotoAlbum:album completion:^(SObject *object) {
                    if (!object.isFailed) {
                        self.defaultAlbum = (SPhotoAlbumData *) object;
                        self.defaultAlbumId = self.defaultAlbum.objectId;
                    }
                    [operation complete:object];
                }];
            }
        }];
    }];
}


- (void)uploadPhoto:(SPhotoData *)params
              album:(NSString *)album
          operation:(SocialConnectorOperation *)operation
         completion:(SObjectCompletionBlock)completionn {
    NSDictionary *parameters;
    if (album) {
        parameters = @{@"aid" : album};
    }
    else {
        parameters = @{@"aid" : @"application"};
    }

    if (!params.sourceData) {
        if (params.sourceImage) {
            params.sourceData = UIImageJPEGRepresentation(params.sourceImage, 0.5);
        }
    }

    [self simpleMethod:@"photosV2.getUploadUrl" parameters:parameters operation:operation processor:^(id response) {

        NSLog(@"response = %@", response);

        if ([response[@"photo_ids"] count] == 0) {
            completionn([SObject failed]);
            return;
        }

        NSString *photoId = response[@"photo_ids"][0];
        NSString *uploadURL = response[@"upload_url"];


        AFHTTPRequestOperation *op = [self.client POST:uploadURL
                                            parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                    [formData appendPartWithFileData:params.sourceData name:@"pic1" fileName:@"pic1.jpg" mimeType:@"image/jpeg"];
                }
                                               success:
                                                       ^(AFHTTPRequestOperation *op, id responseObject) {

                                                           NSLog(@"responseObject = %@", responseObject);

                                                           //NSString *data = [[NSString alloc] initWithBytes:[responseObject bytes] length:[responseObject length] encoding:NSUTF8StringEncoding];
                                                           if ([responseObject[@"photos"] count] == 0) {
                                                               completionn([SObject failed]);
                                                               return;
                                                           }
                                                           NSString *token = responseObject[@"photos"][photoId][@"token"];

                                                           if (!token) {
                                                               completionn([SObject failed]);
                                                               return;
                                                           }

                                                           [self simpleMethod:@"photosV2.commit" parameters:@{@"photo_id" : photoId, @"token" : token} operation:operation processor:^(id response) {

                                                               NSLog(@"responseObject = %@", response);
                                                               SPhotoData *result = [params copyWithHandler:self];

                                                               if ([responseObject[@"photos"] count] == 0) {
                                                                   completionn([SObject failed]);
                                                                   return;
                                                               }

                                                               completionn(result);
                                                           }];

                                                       }
                                               failure:
                                                       ^(AFHTTPRequestOperation *op, NSError *error) {
                                                           completionn([SObject error:error]);
                                                       }];
    }];
}

- (NSString *)dafaultPhotoAlbumTitle {
    return self.defaultAlbumName;
}

- (SObject *)createPhotoAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.createAlbum" parameters:@{@"title" : params.title, @"type" : @"public"} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SPhotoAlbumData *album = [params copyWithHandler:self];
            album.objectId = [response stringValue];
            [operation complete:album];
        }];
    }];
}

- (SObject *)addPhotoToAlbum:(SPhotoData *)params completion:(SObjectCompletionBlock)completion {
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self uploadPhoto:params album:params.album.objectId operation:operation completion:^(SObject *result) {

            [operation complete:result];
        }];
    }];
}

- (SObject *)addPhoto:(SPhotoData *)srcParams completion:(SObjectCompletionBlock)completion {
    SPhotoData *params = [srcParams copy];
    params.album = nil;

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        if (!params.album) {
            [self getDefaultPhotoAlbum:operation.object completion:^(SObject *result) {
                if (!result.isFailed) {
                    params.album = result;
                    [self addPhotoToAlbum:params completion:^(SObject *object) {
                        [operation complete:object];
                    }];
                }
            }];
        }
        else {
            [self uploadPhoto:params album:nil operation:operation completion:^(SObject *result) {

                [operation complete:result];
            }];
        }
    }];
}

@end