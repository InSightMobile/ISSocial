//
// 



#import "WebLoginManager.h"
#import "WebLoginController.h"
#import "AsyncBlockOperation.h"


@interface WebLoginManager ()
@property(nonatomic, strong) NSOperationQueue *queue;
@end

@implementation WebLoginManager {

}


+ (WebLoginManager *)instance {
    static WebLoginManager *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }

    return self;
}

- (WebLoginController *)loadLoginController {
    return [[WebLoginController alloc] init];

    UIStoryboard *st = [[UIApplication sharedApplication].windows[0] rootViewController].storyboard;

    WebLoginController *controller = [st instantiateViewControllerWithIdentifier:@"webLogin"];

    return controller;
}

- (void)addLoginOperation:(AsyncBlockOperation *)operation {
    [self.queue addOperation:operation];
}
@end