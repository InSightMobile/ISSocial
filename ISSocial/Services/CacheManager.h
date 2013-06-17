//
// 



#import <Foundation/Foundation.h>
#import "SocialConnector.h"


@interface CacheManager : NSObject
+ (CacheManager *)instance;

- (SObject *)cashedReadWithConnector:(SocialConnector *)connector
                           operation:(SEL)operation
                              params:(SObject *)params
                                 ttl:(float)ttl
                          completion:(CompletionBlock)completion;

@end