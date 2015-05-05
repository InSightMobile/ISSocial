//
// 



#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@interface VkontakteConnector (Video)
- (SObject *)parseVideosResponce:(id)response;

- (SVideoData *)parseVideoResponse:(NSDictionary *)info;

- (void)readLikes:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;

- (void)addLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;

- (void)removeLike:(SVideoData *)params operation:(SocialConnectorOperation *)operation type:(NSString *)type itemId:(NSString *)itemId owner:(SUserData *)owner;

@end