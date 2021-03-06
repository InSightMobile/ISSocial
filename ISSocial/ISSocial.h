//
// 

#import <Foundation/Foundation.h>
#import "AccessSocialConnector.h"
#import "CompositeConnector.h"
#import "SUserData.h"


@class ISSocialLoginManager;
@class CompositeConnector;


extern NSString *const ISSocialLoggedInUpdatedNotification;

extern NSString *const ISSocialConnectorIdFacebook;
extern NSString *const ISSocialConnectorIdVkontakte;
extern NSString *const ISSocialConnectorIdGooglePlus;
extern NSString *const ISSocialConnectorIdTwitter;
extern NSString *const ISSocialConnectorIdOdnoklassniki;

@interface ISSocial : NSObject
- (void)loadConnectors;

+ (ISSocial *)defaultInstance;

@property(nonatomic, strong, readonly) CompositeConnector *rootConnectors;

+ (BOOL)hasConnectorNamed:(NSString *)name;

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

- (NSArray *)connectorsMeetSpecifications:(NSArray *)specifications;

- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation;

- (void)configure;

- (void)handleDidBecomeActive;

- (void)closeAllSessionsAndClearCredentials:(void (^)(NSError *))pFunction;
@end