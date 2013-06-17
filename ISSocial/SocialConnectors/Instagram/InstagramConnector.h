//
// 



#import <Foundation/Foundation.h>
#import "AccessSocialConnector.h"


@interface InstagramConnector : AccessSocialConnector
+ (InstagramConnector *)instance;

@property(nonatomic) BOOL loggedIn;

- (void)simpleRequest:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;


- (SUserData *)dataForUserId:(NSString *)userId;

@end