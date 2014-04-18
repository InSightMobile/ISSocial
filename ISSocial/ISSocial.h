//
// 

#import <Foundation/Foundation.h>
#import "AccessSocialConnector.h"
#import "CompositeConnector.h"

@class ISSocialLoginManager;
@class CompositeConnector;


static NSString *const ISSocialLoggedInUpdatedNotification = @"ISSocialLoggendInUpdated";

static NSString *const ISSocialConnectorIdFacebook = @"Facebook";
static NSString *const ISSocialConnectorIdVkontakte = @"Vkontakte";
static NSString *const ISSocialConnectorIdTwitter = @"Twitter";
static NSString *const ISSocialConnectorIdOdnoklassniki = @"Odnoklassniki";

@interface ISSocial : NSObject
- (void)loadConnectors;

+ (ISSocial *)defaultInstance;

@property(nonatomic, strong, readonly) CompositeConnector *rootConnectors;

@property(nonatomic, strong) NSMutableDictionary *connectorsByCode;

- (void)tryLoginWithCompletion:(void (^)())completion;

- (void)tryLoginWithUserUI:(BOOL)userUI completion:(void (^)())completion;

- (void)logoutWithCompletion:(void (^)())completion;

- (void)logoutConnector:(SocialConnector *)connector completion:(void (^)())completion;


- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(SocialConnector *connector, NSError *error))completion;

- (void)useConnectorForCode:(NSString *)connectorCode connector:(AccessSocialConnector *)connector;

- (void)useConnector:(AccessSocialConnector *)connector;

- (AccessSocialConnector *)connectorNamed:(NSString *)connectorName;

- (NSSet *)loggedInConnectors;

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString*)sourceApplication;

- (void)configure;

- (void)handleDidBecomeActive;
@end