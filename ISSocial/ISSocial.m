//
// 



#import "ISSocial.h"
#import "CompositeConnector.h"
#import "LoginManager.h"
#import "AccessSocialConnector.h"


@interface ISSocial ()
@property(nonatomic, strong) LoginManager *loginManager;
@property (nonatomic, strong, readwrite) CompositeConnector *rootConnectors;
@end

@implementation ISSocial
{

}

- (id)init
{
    self = [super init];
    if (self) {

        self.rootConnectors = [CompositeConnector new];

        self.loginManager = [LoginManager new];
        self.loginManager.sourceConnectors = self.rootConnectors;
        self.loginManager.destinationConnectors = self.rootConnectors;
    }

    return self;
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
    [self.loginManager loginWithCompletion:completion];

}

- (void)loginWithConnectorName:(NSString *)connectorName completion:(void (^)(NSError *error))completion
{
    SocialConnector *connector = [self connectorNamed:connectorName];

    [self.rootConnectors addConnector:connector asActive:YES];
    [self.loginManager loginWithCompletion:^{
        completion(nil);
    }];
}

- (SocialConnector *)connectorNamed:(NSString *)connectorName
{
    Class connectorClass = NSClassFromString([NSString stringWithFormat:@"%@Connector", connectorName]);
    SocialConnector *connector = [connectorClass instance];
    return connector;
}


- (BOOL)handleOpenURL:(NSURL *)url
{
    for (AccessSocialConnector *connector in self.rootConnectors.availableConnectors) {
         if([connector handleOpenURL:url]) {
             return YES;
         }
    }
    return NO;
}

- (void)configure
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ISSocial" ofType:@"plist"];
    if(path) {
        NSDictionary*options = [NSDictionary dictionaryWithContentsOfFile:path];
        if(options) {
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