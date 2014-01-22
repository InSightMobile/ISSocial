//
// 

#import "SAudioData.h"
#import "VkontakteConnector.h"
#import "VkontakteConnector+Audio.h"
#import "VkontakteConnector+UserData.h"
#import "SUserData.h"
#import "ISSVKSession.h"

@implementation VkontakteConnector (Audio)

- (SAudioData *)parseAudioResponse:(NSDictionary *)info
{
    SUserData *owner = [self dataForUserId:[info[@"owner_id"] stringValue]];
    NSString *aid = [info[@"aid"] stringValue];
    NSString *objectId = [NSString stringWithFormat:@"%@_%@", owner.objectId, aid];

    SAudioData *audio = (SAudioData *) [self mediaObjectForId:objectId type:@"audio"];

    audio.title = info[@"title"];
    audio.artist = info[@"artist"];
    audio.audioId = aid;

    if (info[@"performer"]) {
        audio.artist = info[@"performer"];
    }

    audio.duration = @([info[@"duration"] doubleValue]);
    audio.owner = [self dataForUserId:[info[@"owner_id"] stringValue]];

    audio.url = [NSURL URLWithString:info[@"url"]];

    return audio;
}

- (SObject *)readAudio:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"audio.get" parameters:@{@"uid" : self.userId} operation:operation processor:^(id response) {

            SObject *result = [self parseAudiosResponce:response];

            [operation complete:result];
        }];
    }];
}

- (SObject *)searchAudio:(SObject *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"audio.search"
                parameters:@{
                        @"uid" : self.userId,
                        @"q" : params.searchString,
                        @"auto_complete" : @YES,
                        @"sort" : @2}
                 operation:operation processor:^(id response) {

            SObject *result = [self parseAudiosResponce:response];
            [operation complete:result];
        }];
    }];
}

- (SObject *)parseAudiosResponce:(id)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];
    NSLog(@"response = %@", response);

    for (NSDictionary *info in response) {

        if ([info isKindOfClass:[NSDictionary class]]) {
            SAudioData *audioData = [self parseAudioResponse:info];
            [result addSubObject:audioData];
        }
    }
    return result;
}

- (SObject *)addAudio:(SAudioData *)params completion:(SObjectCompletionBlock)completion
{
    NSLog(@"add audio = %@", params);

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"audio.getUploadServer" parameters:nil operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            VKRequestOperation *op =
                    [ISSVKSession uploadDataTo:response[@"upload_url"] fromURL:params.url name:@"file" fileName:params.fileName mime:nil handler:^(VKRequestOperation *connection, id result, NSError *error)
                    {

                        if (error) {
                            [operation completeWithError:error];
                            return;
                        }

                        NSLog(@"result = %@", result);

                        NSMutableDictionary *parameters =
                                [@{@"server" : result[@"server"], @"audio" : result[@"audio"], @"hash" : result[@"hash"]} mutableCopy];

                        if (params.artist) {
                            parameters[@"artist"] = params.artist;
                        }

                        if (params.title) {
                            parameters[@"title"] = params.title;
                        }

                        [self simpleMethod:@"audio.save" parameters:parameters operation:operation processor:^(id response)
                        {
                            NSLog(@"response = %@", response);
                            SAudioData *audio = [self parseAudioResponse:response];
                            [operation complete:audio];
                        }];
                    }];
            [operation addSubOperation:op];
        }];
    }];
}

@end