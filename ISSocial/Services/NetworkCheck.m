//
// Created by Ярослав on 24.04.13.
// Copyright (c) 2013 ‚Äì√ò‚Äî√Ñ‚Äì√¶‚Äî√Ö‚Äì¬™‚Äì‚àû‚Äì‚â§. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "SystemConfiguration/SystemConfiguration.h"
#import "AFNetworking/AFHTTPClient.h"
#import "NetworkCheck.h"



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
        self.client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://vk.com"]];
    }

    return self;
}


+ (BOOL) connectionAviable
{
    return [[self instance] connectionAviable];
}

- (BOOL)connectionAviable {
    return [_client networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable;
}

- (void)checkConnectionWithCompletion:(void (^)(BOOL aviable))completion {

    if([_client networkReachabilityStatus] == AFNetworkReachabilityStatusUnknown) {

        [_client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {

            completion(status != AFNetworkReachabilityStatusNotReachable);

            [self.client setReachabilityStatusChangeBlock:nil];
        }];

    }
    else {
        completion([_client networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable);
    }
}

@end