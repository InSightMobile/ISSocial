//
// 



#import <Foundation/Foundation.h>
#import <ISSocial/SObject.h>
#import "FacebookConnector.h"

@interface FacebookConnector (Photos)
- (SObject *)parsePhoto:(id)data;

- (void)readWallAlbumWithOperation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion;

- (SObject *)getDefaultPhotoAlbum:(SObject *)params completion:(SObjectCompletionBlock)completion;

- (void)uploadPhoto:(SPhotoData *)photo toPath:(NSString *)path operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion;
@end