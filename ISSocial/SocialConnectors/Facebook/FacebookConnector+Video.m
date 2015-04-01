//
// Created by yarry on 04.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FacebookConnector+Video.h"
#import "SVideoData.h"
#import "FBRequest.h"
#import "MultiImage.h"
#import "NSDate+Facebook.h"
#import "NSString+TypeSafety.h"


@implementation FacebookConnector (Video)

- (SVideoData *)parseVideoResponse:(NSDictionary *)data {

    SVideoData *video = (SVideoData *) [self mediaObjectForId:[data[@"id"] stringValue] type:@"video"];

    video.multiImage = [[MultiImage alloc] initWithURL:data[@"picture"]];

    video.date = [NSDate dateWithFacebookString:data[@"created_time"]];

    video.playbackURL = [data[@"source"] URLValue];

    if (data[@"source_url"]) {
        video.playbackURL = [data[@"source_url"] URLValue];
        video.isDirectPlaybackURL = @YES;
    }

    return video;
}

- (SObject *)readVideo:(SObject *)params completion:(SObjectCompletionBlock)completion {

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"me/videos/uploaded" operation:operation processor:^(id response) {

            SObject *result = [SObject objectCollectionWithHandler:self];

            NSLog(@"response = %@", response);

            for (NSDictionary *info in response[@"data"]) {

                if ([info isKindOfClass:[NSDictionary class]]) {
                    SVideoData *photoData = [self parseVideoResponse:info];
                    [result addSubObject:photoData];
                }
            }
            [operation complete:result];
        }];
    }];
}

- (SObject *)addVideo:(SVideoData *)video completion:(SObjectCompletionBlock)completion {

    return [self operationWithObject:video completion:completion processor:^(SocialConnectorOperation *operation) {

        //NSInputStream * stream = [[NSInputStream alloc] initWithURL:video.videoURL];

        NSString *filename = [video.playbackURL path];

        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:filename];

        FBRequest *req = [FBRequest requestWithGraphPath:@"me/videos"
                                              parameters:@{@"video.mov" : data, @"contentType" : @"video/quicktime"}
                                              HTTPMethod:@"POST"];

        FBRequestConnection *connection = [[FBRequestConnection alloc] initWithTimeout:60];
        [connection addRequest:req completionHandler:^(FBRequestConnection *connection, id response, NSError *error) {

            NSLog(@"response = %@", response);

            [operation removeConnection:connection];

            if (error) {
                [operation completeWithError:error];
                return;
            }

            NSString *photoId = [response[@"id"] stringValue];


            [self simpleMethod:[NSString stringWithFormat:@"%@", photoId] operation:operation processor:^(id response) {

                NSLog(@"response = %@", response);

                SObject *result = [self parseVideoResponse:response[@"data"][0]];

                [operation complete:result];

            }];

        }];
        [connection start];
        [operation addConnection:connection];
    }];
}

- (SObject *)addVideoLike:(SVideoData *)feed completion:(SObjectCompletionBlock)completion {
    return [self addFeedLike:(id) feed completion:completion];
}

- (SObject *)removeVideoLike:(SVideoData *)feed completion:(SObjectCompletionBlock)completion {
    return [self removeFeedLike:(id) feed completion:completion];
}

- (SObject *)addVideoComment:(SVideoData *)comments completion:(SObjectCompletionBlock)completion {
    return [self addFeedComment:(id) comments completion:completion];
}

- (SObject *)readVideoComments:(SVideoData *)feed completion:(SObjectCompletionBlock)completion {
    return [self readFeedComments:(id) feed completion:completion];
}


@end