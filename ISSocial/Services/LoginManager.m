//
//

#import <BlocksKit/NSObject+BlockObservation.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "LoginManager.h"
#import "CompositeConnector.h"
#import "AsyncBlockOperation.h"
#import "NetworkCheck.h"

typedef void (^BlockCompletionBlock)();

@interface LoginManager ()
@property(nonatomic) BOOL canceled;

@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) NSMutableArray *completions;
@end

@implementation LoginManager
{

}

+ (LoginManager *)instance
{
    static LoginManager *_instance = nil;
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
        self.resultConnector = [[CompositeConnector alloc] initWithConnectorSpecifications:nil];
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;

        self.completions = [NSMutableArray array];
        CompositeConnector *globalConnector = [CompositeConnector globalConnectors];

        [_queue addObserverForKeyPath:@"operationCount" task:^(id sender) {

            dispatch_async(dispatch_get_main_queue(), ^{
                if ([sender operationCount] == 0) {

                    [globalConnector activateConnectors:self.resultConnector.activeConnectors exclusive:YES];

                    if (!self.canceled) {
                        for (BlockCompletionBlock block in _completions) {
                            block();
                        }
                        [_completions removeAllObjects];
                    }
                    self.canceled = NO;
                }
            });
        }];
    }
    return self;
}

- (void)loginWithCompletion:(void (^)())completion
{
    [[NetworkCheck instance] checkConnectionWithCompletion:^(BOOL connected) {

        if(!connected) {
            [UIAlertView showAlertViewWithTitle:NSLocalizedString(@"No network access", @"No network access") message:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                completion();
            }];
            return;
        }

    self.canceled = NO;
    CompositeConnector *globalConnector = [CompositeConnector globalConnectors];

    [self.resultConnector setConnectors:globalConnector.sortedAvailableConnectors asActive:NO];
    [self.resultConnector deactivateAllConnectors];

    NSArray *connectors = globalConnector.sortedActiveConnectors;
    if (!connectors.count) {
        completion();
        return;
    }

    for (SocialConnector *connector in connectors) {
        if (connector.isLoggedIn) {
            [self.resultConnector activateConnector:connector];
        }
    }
    [self.completions addObject:[completion copy]];

    for (SocialConnector *connector in connectors) {
        AsyncBlockOperation *blockOperation = [AsyncBlockOperation operationWithBlock:^(AsyncBlockOperation *operation,
                AsyncBlockOperationCompletionBlock completionBlock) {

            if (!self.canceled && !connector.isLoggedIn) {
                [connector openSession:nil completion:^(SObject *result) {
                    if (!result.isFailed) {
                        [self.resultConnector activateConnector:connector];
                    }
                    else {
                        [self.resultConnector deactivateConnector:connector];
                    }
                    completionBlock(nil);
                }];
            }
            else {
                completionBlock(nil);
            }
        }];
        [_queue addOperation:blockOperation];
    }

    }];
}


- (void)cancelLogins
{
    [self.completions removeAllObjects];
    [_queue cancelAllOperations];
    [[CompositeConnector globalConnectors] activateConnectors:self.resultConnector.activeConnectors exclusive:YES];
    self.canceled = YES;
}
@end