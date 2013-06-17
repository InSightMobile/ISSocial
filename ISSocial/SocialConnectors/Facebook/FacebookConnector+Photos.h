//
// 



#import <Foundation/Foundation.h>
#import "FacebookConnector.h"

@interface FacebookConnector (Photos)
- (SObject *)parsePhoto:(id)data;

- (void)readWallAlbumWithOperation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completion;

- (void)uploadPhoto:(SPhotoData *)photo toPath:(NSString *)path operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completion;
@end