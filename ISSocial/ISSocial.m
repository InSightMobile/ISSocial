//
// 



#import "ISSocial.h"
#import "ISSocialLoginManager.h"


@interface ISSocial ()
@property(nonatomic, strong) ISSocialLoginManager *loginManager;
@property(nonatomic, strong, readwrite) CompositeConnector *rootConnectors;
@property(nonatomic, strong) CompositeConnector *currentConnectors;
@end

@implementation ISSocial
{

}

- (id)init
{
    self = [super init];
    if (self) {

    }

    return self;
}

- (void)loadConnectors
{
    if (self.rootConnectors) {
        return;
    }
    self.rootConnectors = [[CompositeConnector alloc] initWithRestorationId:@"root"];
    self.currentConnectors =
            [[CompositeConnector alloc] initWithConnectorSpecifications:nil superConnector:self.rootConnectors
                                                          restorationId:nil options:
                    CompositeConnectorUseAviableConnectors | CompositeConnectorDefaultDeactivated];

    self.loginManager = [ISSocialLoginManager new];
    self.loginManager.sourceConnectors = self.rootConnectors;
    self.loginManager.destinationConnectors = @[self.currentConnectors, self.rootConnectors];

    [self.currentConnectors addObserver:self forKeyPath:@"activeConnectors" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.currentConnectors) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ISSocialLoggedInUpdatedNotification object:self]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


+ (ISSocial *)defaultInstance
{
    static ISSocial *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (void)tryLoginWithCompletion:(void (^)())completion
{
    [self loadConnectors];
    [self.loginManager loginWithCompletion:^{
        completion();
    }];
}

- (void)tryLoginWithUserUI:(BOOL)userUI completion:(void (^)())completion
{
    [self loadConnectors];
    SObject *params = [SObject new];
    params[kAllowUserUIKey] = @(userUI);
    [self.loginManager loginWithParams:params connector:nil completion:^{
        completion();
    }];
}

- (void)logoutWithCompletion:(void (^)())completion
{

    [self.loginManager logoutAllWithCompletion:^ {
        completion();
    }];
}

- (void)logoutConnector:(SocialConnector *)connector completion:(void (^)())completion
{
    [self.loginManager logoutConnector:connector withCompletion:^ {
        completion();
    }];
}

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(SocialConnector *connector, NSError *error))completion
{
    SocialConnector *connector = [self connectorNamed:connectorName];

    [self.rootConnectors addConnector:connector asActive:YES];

    if (connector.isLoggedIn) {
        completion(connector, nil);
        return;
    }

    __block NSError *connectionError = nil;

    [self.loginManager setLoginHandler:^(SocialConnector *connector, NSError *error) {
        if ([connector.connectorCode isEqualToString:connectorName]) {
            connectionError = error;
        }
    }];

    [self.loginManager loginWithParams:nil connector:connector completion:^() {
        self.loginManager.loginHandler = nil;
        completion(connector, connectionError);
    }];
}

- (void)useConnectorForCode:(NSString *)connectorCode connector:(AccessSocialConnector *)connector
{
    if (!self.connectorsByCode) {
        self.connectorsByCode = [NSMutableDictionary new];
    }

    _connectorsByCode[connectorCode] = connector;
}

- (void)useConnector:(AccessSocialConnector *)connector
{
    [self useConnectorForCode:connector.connectorCode connector:connector];
}


- (AccessSocialConnector *)connectorNamed:(NSString *)connectorName
{
    Class connectorClass = NSClassFromString([NSString stringWithFormat:@"%@Connector", connectorName]);

    if (!self.connectorsByCode) {
        self.connectorsByCode = [NSMutableDictionary new];
    }

    if (!_connectorsByCode[connectorName]) {
        _connectorsByCode[connectorName] = [[connectorClass alloc] init];
    }
    return _connectorsByCode[connectorName];
}

- (NSSet *)loggedInConnectors
{
    NSMutableSet *set = [NSMutableSet set];
    for (AccessSocialConnector *connector in self.currentConnectors.availableConnectors) {

        if (connector.isLoggedIn) {
            [set addObject:connector];
        }
    }
    return set;
}


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication
{
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
        if ([connector handleOpenURL:url fromApplication:sourceApplication]) {
            return YES;
        }
    }
    return NO;
}

- (void)configure
{
    [self loadConnectors];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ISSocial" ofType:@"plist"];
    if (path) {
        NSDictionary *options = [NSDictionary dictionaryWithContentsOfFile:path];
        if (options) {
            [self configureWithOptions:options];
        }
    }
}

- (void)configureWithOptions:(NSDictionary *)dictionary
{
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
            {
                AccessSocialConnector *connector = (AccessSocialConnector *) [self connectorNamed:key];
                [connector setupSettings:obj];
            }];
}

- (void)handleDidBecomeActive
{
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
        [connector handleDidBecomeActive];
    }
}
@end