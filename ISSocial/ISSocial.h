//
// 

#import <Foundation/Foundation.h>

@class CompositeConnector;
@class LoginManager;
@class SocialConnector;

@interface ISSocial : NSObject
+ (ISSocial *)defaultInstance;

@property (nonatomic, strong, readonly) CompositeConnector *rootConnectors;

- (void)tryLoginWithCompletion:(void (^)())completion;

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(NSError *error))completion;

- (SocialConnector *)connectorNamed:(NSString *)connectorName;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)configure;
@end