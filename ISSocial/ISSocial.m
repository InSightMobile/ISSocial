//
// 



#import "ISSocial.h"
#import "LoginManager.h"
#import "NSArray+AsyncBlocks.h"


@interface ISSocial ()
@property(nonatomic, strong) LoginManager *loginManager;
@property(nonatomic, strong, readwrite) CompositeConnector *rootConnectors;
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

    self.loginManager = [LoginManager new];
    self.loginManager.sourceConnectors = self.rootConnectors;
    self.loginManager.destinationConnectors = self.rootConnectors;
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
        [self.rootConnectors setConnectors:self.loggedInConnectors.allObjects asActive:YES];
        completion();
    }];
}

- (void)logoutWithCompletion:(void (^)())completion {

    [self.rootConnectors.activeConnectors.allObjects asyncEach:^(id object, ISArrayAsyncEachResultBlock next) {

        [object closeSession:nil completion:^(SObject *result) {
            [self.rootConnectors deactivateConnector:object];
        }];

    } comletition:^(NSError *errorOrNil) {

        completion();
    }];
}

- (void)logoutConnector:(SocialConnector *)connector completion:(void (^)())completion {
    [connector closeSession:nil completion:^(SObject *result) {
        [self.rootConnectors deactivateConnector:connector];
        completion();
    }];
}

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(SocialConnector *connector, NSError *error))completion
{
    SocialConnector *connector = [self connectorNamed:connectorName];

    [self.rootConnectors addConnector:connector asActive:YES];
    [self.loginManager loginWithCompletion:^{
        completion(connector,nil);
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
    for (AccessSocialConnector *connector in     self.rootConnectors.availableConnectors) {

        if (connector.isLoggedIn) {
            [set addObject:connector];
        }
    }
    return set;
}


- (BOOL)handleOpenURL:(NSURL *)url
{
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
        if ([connector handleOpenURL:url]) {
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
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        AccessSocialConnector *connector = (AccessSocialConnector *) [self connectorNamed:key];
        [connector setupSettings:obj];
    }];
}

@end