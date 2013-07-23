//
// Created by yarry on 18.02.13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "OdnoklassnikiConnector+Photo.h"
#import "SPhotoData.h"
#import "MultiImage.h"
#import "SPhotoAlbumData.h"
#import "NSDate+Odnoklassniki.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"

@implementation OdnoklassnikiConnector (Photo)

- (SObject *)parsePhotos:(id)responce
{
    SObject *photos = [SObject objectCollectionWithHandler:self];

    for (NSDictionary *data in responce[@"photos"]) {

        SPhotoData *photo = (SPhotoData *) [self mediaObjectForId:[data[@"id"] stringValue] type:@"photo"];

        photo.title = data[@"text"];
        photo.commentsCount = @([data[@"comments_count"] intValue]);
        photo.likesCount = @([data[@"likes_count"] intValue]);
        photo.userLikes = @([data[@"liked_it"] intValue]);

        MultiImage *image = [[MultiImage alloc] init];

        if (data[@"pic50x50"]) {
            [image addImageURL:data[@"pic50x50"] forWitdh:50 height:50];
        }
        if (data[@"pic128x128"]) {
            [image addImageURL:data[@"pic128x128"] forWitdh:128 height:128];
        }
        if (data[@"pic190x190"]) {
            [image addImageURL:data[@"pic190x190"] forWitdh:190 height:190];
        }
        if (data[@"pic640x480"]) {
            [image addImageURL:data[@"pic640x480"] forWitdh:640 height:480];
        }
        if (data[@"pic1024X768"]) {
            [image addImageURL:data[@"pic1024X768"] forWitdh:1024 height:768];
        }

        photo.multiImage = image;

        [photos addSubObject:photo];
    }
    return photos;
}

- (SObject *)parseAlbums:(id)responce
{
    SObject *albums = [SObject objectCollectionWithHandler:self];

    if (0) {
        SPhotoAlbumData *allObjectsAlbum = [[SPhotoAlbumData alloc] initWithHandler:self];
        allObjectsAlbum.title = NSLocalizedString(@"All photos album title", @"All photos");
        allObjectsAlbum.sortGroup = @0;
        [albums addSubObject:allObjectsAlbum];
    }

    for (NSDictionary *data in responce[@"albums"]) {

        SPhotoAlbumData *album = [self parseAlbum:data];
        album.sortGroup = @1;
        [albums addSubObject:album];
    }
    return albums;
}

- (SPhotoAlbumData *)parseAlbum:(NSDictionary *)data
{
    SPhotoAlbumData *album = [[SPhotoAlbumData alloc] initWithHandler:self];

    album.objectId = [data[@"aid"] stringValue];
    album.title = data[@"title"];
    album.likesCount = @([data[@"like_count"] intValue]);
    album.userLikes = @([data[@"liked_it"] boolValue]);
    album.date = [NSDate dateWithOdnoklassnikiString:data[@"created"]];
    album.canUpload = @YES;
    return album;
}

- (SObject *)readPhotos:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.getPhotos" parameters:@{@"detectTotalCount" : @1} operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            [operation complete:[self parsePhotos:response]];
        }];
    }];
}

- (SObject *)readPhotosFromAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion
{
    if (!params.objectId) {
        return [self readPhotos:params completion:completion];
    }

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.getPhotos" parameters:@{@"detectTotalCount" : @1, @"aid" : params.objectId} operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            [operation complete:[self parsePhotos:response]];
        }];
    }];
}

- (SObject *)readPhotoAlbums:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"photos.getAlbums" parameters:@{} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            [operation complete:[self parseAlbums:response]];
        }];
    }];
}

- (SObject *)getDefaultPhotoAlbum:(SObject *)params completion:(SObjectCompletionBlock)completion
{
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
         completion:(SObjectCompletionBlock)completionn
{
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

        NSURLRequest *req =
                [self.client multipartFormRequestWithMethod:@"POST" path:uploadURL parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {

                    [formData appendPartWithFileData:params.sourceData name:@"pic1" fileName:@"pic1.jpg" mimeType:@"image/jpeg"];

                }];

        [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];

        AFHTTPRequestOperation *op =

                [AFJSONRequestOperation JSONRequestOperationWithRequest:req success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseObject) {

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

                }                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    completionn([SObject error:error]);
                }];
        [operation startSubOperation:op];
    }];
}

- (NSString *)dafaultPhotoAlbumTitle
{
    return self.defaultAlbumName;
}

- (SObject *)createPhotoAlbum:(SPhotoAlbumData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {
        [self simpleMethod:@"photos.createAlbum" parameters:@{@"title" : params.title, @"type" : @"public"} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SPhotoAlbumData *album = [params copyWithHandler:self];
            album.objectId = [response stringValue];
            [operation complete:album];
        }];
    }];
}

- (SObject *)addPhotoToAlbum:(SPhotoData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self uploadPhoto:params album:params.album.objectId operation:operation completion:^(SObject *result) {

            [operation complete:result];
        }];
    }];
}

- (SObject *)addPhoto:(SPhotoData *)srcParams completion:(SObjectCompletionBlock)completion
{
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