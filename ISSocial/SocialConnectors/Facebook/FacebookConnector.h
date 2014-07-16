//
//

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "AccessSocialConnector.h"

@class XMPPStream;
@class SUserData;
@class SPhotoAlbumData;

typedef void (^PagingProcessor)(id, SocialConnectorOperation *);

@interface FacebookConnector : AccessSocialConnector

@property(nonatomic, strong) XMPPStream *xmppStream;
@property(nonatomic) NSInteger xmppStreamStatus;

+ (FacebookConnector *)instance;

- (void)simpleMethod:(NSString *)method operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)method params:(NSDictionary *)params operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethodWithURL:(NSString *)urlString operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simplePost:(NSString *)method object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleMethod:(NSString *)httpMethod path:(NSString *)path params:(NSDictionary *)params object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleQuery:(NSString *)query operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)simpleRequest:(NSString *)method path:(NSString *)path object:(NSDictionary *)object operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)checkAuthorizationFor:(NSArray *)permissions operation:(SocialConnectorOperation *)operation processor:(void (^)(id))processor;

- (void)authorizeWithPublishPermissions:(NSArray *)permissions completion:(SObjectCompletionBlock)completion;


- (SObject *)fetchDataWithPath:(NSString *)path parameters:(NSDictionary *)parameters params:(SObject *)params completion:(SObjectCompletionBlock)completion processor:(PagingProcessor)processor;

- (SObject *)operationWithObject:(SObject *)object;

@property(retain, nonatomic) SUserData *currentUserData;


@property(nonatomic, strong) NSMutableArray *messageReceivers;
@property(nonatomic, strong) SPhotoAlbumData *wallAlbum;
@end
