//
// 



#import "ISSocial.h"
#import "ISSocialLoginManager.h"
#import "NSArray+ISSAsyncBlocks.h"


@interface ISSocial ()
@property(nonatomic, strong) ISSocialLoginManager *loginManager;
@property(nonatomic, strong, readwrite) CompositeConnector *rootConnectors;
@property(nonatomic, strong) CompositeConnector *currentConnectors;
@end

@implementation ISSocial {

}

- (id)init {
    self = [super init];
    if (self) {

    }

    return self;
}

- (void)loadConnectors {
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.currentConnectors) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ISSocialLoggedInUpdatedNotification object:self]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


+ (ISSocial *)defaultInstance {
    static ISSocial *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (void)tryLoginWithCompletion:(void (^)())completion {
    [self loadConnectors];
    [self.loginManager loginWithCompletion:^{
        completion();
    }];
}

+ (BOOL)hasConnectorNamed:(NSString *)name {
    Class connectorClass = NSClassFromString([NSString stringWithFormat:@"%@Connector", name]);

    return [connectorClass isSubclassOfClass:[AccessSocialConnector class]];
}

- (void)tryLoginWithUserUI:(BOOL)userUI completion:(void (^)())completion {
    [self loadConnectors];
    SObject *params = [SObject new];
    params[kAllowUserUIKey] = @(userUI);
    [self.loginManager loginWithParams:params connector:nil completion:^{
        completion();
    }];
}

- (void)logoutWithCompletion:(void (^)())completion {

    [self.loginManager logoutAllWithCompletion:^{
        completion();
    }];
}

- (void)logoutConnector:(SocialConnector *)connector completion:(void (^)())completion {
    [self.loginManager logoutConnector:connector withCompletion:^{
        completion();
    }];
}

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(SocialConnector *connector, NSError *error))completion {
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

- (void)useConnectorForCode:(NSString *)connectorCode connector:(AccessSocialConnector *)connector __attribute__((nonnull)) {
    if (!self.connectorsByCode) {
        self.connectorsByCode = [NSMutableDictionary new];
    }

    _connectorsByCode[connectorCode] = connector;
}

- (void)useConnector:(AccessSocialConnector *)connector {
    [self useConnectorForCode:connector.connectorCode connector:connector];
}

- (void)useConnectorsNamed:(NSArray *)names {
    for (NSString *name in names) {
        [self useConnectorNamed:name];
    }
}

- (void)useConnectorNamed:(NSString *)name {
    [self useConnector:[self connectorNamed:name]];
}


- (AccessSocialConnector *)connectorNamed:(NSString *)connectorName {
    Class connectorClass = NSClassFromString([NSString stringWithFormat:@"%@Connector", connectorName]);

    if (!self.connectorsByCode) {
        self.connectorsByCode = [NSMutableDictionary new];
    }

    if (!_connectorsByCode[connectorName]) {

        if (!connectorClass) {
            return nil;
        }

        _connectorsByCode[connectorName] = (id) [[connectorClass alloc] init];
    }
    return _connectorsByCode[connectorName];
}

- (NSSet *)loggedInConnectors {
    NSMutableSet *set = [NSMutableSet set];
    for (AccessSocialConnector *connector in self.currentConnectors.availableConnectors) {

        if (connector.isLoggedIn) {
            [set addObject:connector];
        }
    }
    return set;
}

- (NSArray *)connectorsMeetSpecifications:(NSArray *)specifications {
    NSMutableArray *selection = [NSMutableArray new];

    NSMutableSet *set = [NSMutableSet set];
    for (AccessSocialConnector *connector in self.connectorsByCode.allValues) {

        if ([connector meetsSpecifications:specifications]) {
            [selection addObject:connector];
        }
    }
    return [selection sortedArrayUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"connectorPriority" ascending:NO],
            [NSSortDescriptor sortDescriptorWithKey:@"connectorCode" ascending:YES]]];
}


- (BOOL)handleOpenURL:(NSURL *)url fromApplication:(NSString *)sourceApplication annotation:(id)annotation {
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
        if ([connector handleOpenURL:url fromApplication:sourceApplication annotation:annotation]) {
            return YES;
        }
    }
    return NO;
}

- (void)configure {
    [self loadConnectors];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ISSocial" ofType:@"plist"];
    if (path) {
        NSDictionary *options = [NSDictionary dictionaryWithContentsOfFile:path];
        if (options) {
            [self configureWithOptions:options];
        }
    }
}

- (void)configureWithOptions:(NSDictionary *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        AccessSocialConnector *connector = [self connectorNamed:key];
        [connector setupSettings:obj];
    }];
}

- (void)handleDidBecomeActive {
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
        [connector handleDidBecomeActive];
    }
}

- (void)closeAllSessionsAndClearCredentials:(void (^)(NSError *))completion {
    NSArray *connectors = self.rootConnectors.availableConnectors.allObjects;

    [connectors asyncEach:^(AccessSocialConnector *connector, ISArrayAsyncEachResultBlock next) {

        [connector closeSessionAndClearCredentials:[SObject new] completion:^(SObject *result) {
            next(result.error);
        }];
    }         comletition:^(NSError *errorOrNil) {
        completion(errorOrNil);
    }];
}

@end