//
//

#import "LoginManager.h"
#import "CompositeConnector.h"
#import "AsyncBlockOperation.h"
#import "NetworkCheck.h"
#import "BlockOperationQueue.h"
#import "NSArray+AsyncBlocks.h"

typedef void (^BlockCompletionBlock)();

@interface LoginManager ()
@property(nonatomic) BOOL canceled;

@property(nonatomic, strong) BlockOperationQueue *queue;
@property(nonatomic, strong) NSMutableArray *completions;
@end

@implementation LoginManager
{

}

+ (LoginManager *)instance
{
    static LoginManager *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^
    {
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.resultConnector = [[CompositeConnector alloc] initWithConnectorSpecifications:nil];
        self.queue = [[BlockOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;

        self.completions = [NSMutableArray array];
        CompositeConnector *globalConnector = self.destinationConnectors;
    }
    return self;
}

- (CompositeConnector *)destinationConnectors
{
    if (_destinationConnectors) {
        return _destinationConnectors;
    }
    return [CompositeConnector globalConnectors];
}

- (void)loginWithCompletion:(void (^)())completion
{
    [self loginWithParams:nil completion:completion];
}

- (void)loginWithParams:(SObject *)options completion:(void (^)())completion
{
    __weak LoginManager *wself = self;
    
    [[NetworkCheck instance] checkConnectionWithCompletion:^(BOOL connected)
    {
        if (!connected) {
            if (options[kAllowUserUIKey] && ![options[kAllowUserUIKey] boolValue]) {

                //[UIAlertView showAlertViewWithTitle:NSLocalizedString(@"No network access", @"No network access") message:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                //{
                    completion();
                //}];
            }
            else {
                completion();
            }
            return;
        }

        self.canceled = NO;
        CompositeConnector *globalConnector = self.sourceConnectors;

        [self.resultConnector setConnectors:globalConnector.sortedAvailableConnectors asActive:NO];
        [self.resultConnector deactivateAllConnectors];

        NSArray *connectors = globalConnector.sortedActiveConnectors;
        if (!connectors.count) {
            completion();
            return;
        }

        NSMutableArray *targetConnectors = [NSMutableArray new];

        for (SocialConnector *connector in connectors) {
            if (connector.isLoggedIn) {
                [self.resultConnector activateConnector:connector];
            }
            else {
                [targetConnectors addObject:connector];
            }
        }

        if (targetConnectors.count == 0) {
            [self applyChanges];
            completion();
            return;
        }
        [self.completions addObject:[completion copy]];

        for (SocialConnector *connector in targetConnectors) {
            AsyncBlockOperation
                    *blockOperation = [AsyncBlockOperation operationWithBlock:^(AsyncBlockOperation *operation,
                    AsyncBlockOperationCompletionBlock completionBlock)
            {

                if (!self.canceled && !connector.isLoggedIn) {
                    [connector openSession:options completion:^(SObject *result)
                    {
                        if (result.isSuccessful) {
                            [self.resultConnector activateConnector:connector];
                        }
                        else {
                            [self handleLoginError:connector result:result];
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

        [wself.queue setCompletionHandler:^(NSError *error)
        {
            [wself applyChanges];

            if (!self.canceled) {
                for (BlockCompletionBlock block in _completions) {
                    block();
                }
                [_completions removeAllObjects];
            }
            self.canceled = NO;
        }];

    }];
}

- (void)handleLoginError:(SocialConnector *)connector result:(SObject *)result
{
    if (self.loginHandler) {
        self.loginHandler(connector, result.error);
    }
}

- (void)applyChanges
{
    for (CompositeConnector *connector in _destinationConnectors) {
        [connector addAndActivateConnectors:self.resultConnector.activeConnectors exclusive:YES];
    }
}

- (CompositeConnector *)sourceConnectors
{
    if (_sourceConnectors) {
        return _sourceConnectors;
    }
    return [CompositeConnector globalConnectors];
}


- (void)cancelLogins
{
    [self.completions removeAllObjects];
    [_queue cancelAllOperations];
    [[CompositeConnector globalConnectors] activateConnectors:self.resultConnector.activeConnectors exclusive:YES];
    self.canceled = YES;
}

- (void)logoutAllWithCompletion:(void (^)())completion
{
    [self.sourceConnectors.availableConnectors asyncEach:^(id object, ISArrayAsyncEachResultBlock next)
    {
        SocialConnector *connector = object;

        if (connector.isLoggedIn) {
            [connector closeSession:nil completion:^(SObject *result)
            {
                next(nil);
            }];
        }
        else {
            next(nil);
        }
    }                                        comletition:^(NSError *errorOrNil)
    {
        [self.resultConnector deactivateAllConnectors];
        [self applyChanges];
        completion();
    }];

}

- (void)logoutConnector:(SocialConnector *)connector withCompletion:(void (^)())completion
{
    if (connector.isLoggedIn) {
        [connector closeSession:nil completion:^(SObject *result)
        {
            [self.resultConnector deactivateConnector:connector];
            [self applyChanges];
            completion();
        }];
    }
    else {
        [self.resultConnector deactivateConnector:connector];
        [self applyChanges];
        completion();
    }
}


@end