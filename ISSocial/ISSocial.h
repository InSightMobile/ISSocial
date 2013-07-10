//
// 

#import <Foundation/Foundation.h>

@class CompositeConnector;
@class LoginManager;
@class SocialConnector;
@class AccessSocialConnector;

@interface ISSocial : NSObject
+ (ISSocial *)defaultInstance;

@property (nonatomic, strong, readonly) CompositeConnector *rootConnectors;

@property(nonatomic, strong) NSMutableDictionary *connectorsByCode;

- (void)tryLoginWithCompletion:(void (^)())completion;

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(NSError *error))completion;

- (void)useConnectorForCode:(NSString *)connectorCode connector:(AccessSocialConnector *)connector;

- (void)useConnector:(AccessSocialConnector *)connector;

- (AccessSocialConnector *)connectorNamed:(NSString *)connectorName;

- (NSSet *)loggedInConnectors;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)configure;
@end