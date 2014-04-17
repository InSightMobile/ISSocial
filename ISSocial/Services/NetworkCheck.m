//
//


#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "NetworkCheck.h"


@interface NetworkCheck ()
@property(nonatomic, strong) AFNetworkReachabilityManager *manager;
@end

@implementation NetworkCheck {

}

+ (NetworkCheck *)instance {
    static NetworkCheck *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {

        self.manager = [AFNetworkReachabilityManager managerForDomain:@"vk.com"];
        [_manager startMonitoring];
    }

    return self;
}


+ (BOOL) connectionAviable
{
    return [[self instance] connectionAviable];
}

- (BOOL)connectionAviable {
    return [_manager networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable;
}

- (void)checkConnectionWithCompletion:(void (^)(BOOL aviable))completion {

    __weak NetworkCheck* wself = self;
    
    if([_manager networkReachabilityStatus] == AFNetworkReachabilityStatusUnknown) {

        [_manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {

            completion(status != AFNetworkReachabilityStatusNotReachable);

            [wself.manager setReachabilityStatusChangeBlock:nil];
        }];

    }
    else {
        completion([_manager networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable);
    }
}

@end