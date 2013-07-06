//
// 

#import <Foundation/Foundation.h>

@class CompositeConnector;
@class LoginManager;

@interface ISSocial : NSObject
+ (ISSocial *)defaultInstance;

@property (nonatomic, strong, readonly) CompositeConnector *rootConnectors;

- (void)tryLoginWithCompletion:(void (^)())completion;

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(NSError *error))completion;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)configure;
@end