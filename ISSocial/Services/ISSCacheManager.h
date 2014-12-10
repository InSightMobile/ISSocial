//
// 



#import <Foundation/Foundation.h>
#import "SocialConnector.h"


@interface ISSCacheManager : NSObject
+ (ISSCacheManager *)instance;

- (SObject *)cashedReadWithConnector:(SocialConnector *)connector
                           operation:(SEL)operation
                              params:(SObject *)params
                                 ttl:(float)ttl
                          completion:(SObjectCompletionBlock)completion;

@end