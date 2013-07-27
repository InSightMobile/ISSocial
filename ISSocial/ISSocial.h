//
// 

#import <Foundation/Foundation.h>
#import "AccessSocialConnector.h"
#import "CompositeConnector.h"

@class LoginManager;
@class CompositeConnector;


static NSString *const ISSocialLoggedInUpdatedNotification = @"ISSocialLoggendInUpdated";

@interface ISSocial : NSObject
- (void)loadConnectors;

+ (ISSocial *)defaultInstance;

@property(nonatomic, strong, readonly) CompositeConnector *rootConnectors;

@property(nonatomic, strong) NSMutableDictionary *connectorsByCode;

- (void)tryLoginWithCompletion:(void (^)())completion;

- (void)logoutWithCompletion:(void (^)())completion;

- (void)logoutConnector:(SocialConnector *)connector completion:(void (^)())completion;


- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(SocialConnector *connector, NSError *error))completion;

- (void)useConnectorForCode:(NSString *)connectorCode connector:(AccessSocialConnector *)connector;

- (void)useConnector:(AccessSocialConnector *)connector;

- (AccessSocialConnector *)connectorNamed:(NSString *)connectorName;

- (NSSet *)loggedInConnectors;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)configure;
@end