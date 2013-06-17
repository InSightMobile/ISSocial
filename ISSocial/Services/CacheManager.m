//
// 



#import "CacheManager.h"
#import "SMessageThread.h"


@interface CacheManager ()
@property(nonatomic, strong) NSCache *memoryCache;
@end

@implementation CacheManager

+ (CacheManager *)instance
{
    static CacheManager *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.memoryCache = [[NSCache alloc] init];
        self.memoryCache.totalCostLimit = 1000;

        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)clearMemory
{
    NSLog(@"Clearing memory cache");
    [self.memoryCache removeAllObjects];
}

- (SObject *)cashedReadWithConnector:(SocialConnector *)connector
                           operation:(SEL)operation
                              params:(SObject *)params
                                 ttl:(float)ttl
                          completion:(CompletionBlock)completion
{
    // create key
    NSString *key =
            [NSString stringWithFormat:@"%@%@%@", connector.connectorCode, NSStringFromSelector(operation), [(id) params objectId]];
    SObject *cashedObject = nil;

    if (!params.noCache.boolValue) {
        cashedObject = [self.memoryCache objectForKey:key];
    }

    if (cashedObject) {
        completion(cashedObject);
        return cashedObject;
    }

    return [connector performSelector:operation withObject:params withObject:^(SObject *result) {
        if (result) {
            [self.memoryCache setObject:result forKey:key cost:result.subObjects.count + 1];
        }
        completion(result);
    }];
}


@end