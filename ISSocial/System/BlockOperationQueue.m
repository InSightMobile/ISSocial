//
// Created by yar on 27.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BlockOperationQueue.h"

typedef void (^BlockOperationCompletionHandler)(NSError *);

@interface BlockOperationQueue ()
@property(copy) BlockOperationCompletionHandler completion;
@end

@implementation BlockOperationQueue
{
    //__strong BlockOperationQueue *_retained_self;
}

- (id)init
{
    self = [super init];
    if (self) {

        [self addObserver:self forKeyPath:@"operationCount" options:0 context:nil];

    }
    return self;
}

- (void)setCompletionHandler:(void (^)(NSError *errorOrNil))completion
{
    self.completion = completion;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"operationCount"]) {
        if (self.operationCount == 0) {
            // Do something here when your queue has completed
            if (_completion && !_error) {
                BlockOperationCompletionHandler op = [_completion copy];
                [self setCompletionHandler:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    op(nil);
                });
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}

- (void)cancelAllOperations
{
    BlockOperationCompletionHandler handler = [self.completion copy];
    //__autoreleasing id arself = self;
    [self setCompletionHandler:nil];
    [super cancelAllOperations];
    if (handler) {
        handler([NSError errorWithDomain:@"BlockOperationQueue" code:1 userInfo:nil]);
    }
}

- (void)failWithError:(NSError *)error
{
    self.error = error;
    [self cancelAllOperations];
    if (_completion) {
        _completion(error);
    }
}
@end