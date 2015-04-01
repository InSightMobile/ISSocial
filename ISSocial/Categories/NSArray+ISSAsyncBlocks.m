//
//  NSArray+AsyncBlocks.m
//

#import "ReactiveCocoa/ReactiveCocoa.h"
#import "NSArray+ISSAsyncBlocks.h"
#import "AsyncBlockOperation.h"


@implementation NSArray (ISSAsyncBlocks)

- (void)nextStep:(NSUInteger)index
           error:(NSError *)errorOrNil
       operation:(ISArrayAsyncEachBlock)operation
     comletition:(ISArrayAsyncEachCompletitionBlock)completition {
    if (errorOrNil) {
        if (completition) completition(errorOrNil);
        return;
    }

    if (index >= self.count) {
        //moveNext = FALSE;
        if (completition) completition(nil);
        return;
    }

    __block BOOL isSync = YES;
    __block BOOL moveNext;
    while (true) {
        moveNext = NO;
        isSync = YES;
        operation([self objectAtIndex:index], ^(NSError *err) {
            if (!err && isSync) {
                moveNext = YES;
            }
            else {
                [self nextStep:index + 1 error:err operation:operation comletition:completition];
            }
        });
        isSync = NO;
        if (!moveNext)return;

        index++;
        if (index >= self.count) {
            if (completition) completition(nil);
            return;
        }
    }
}

- (void)asyncEach:(ISArrayAsyncEachBlock)operation comletition:(ISArrayAsyncEachCompletitionBlock)completition {
    if (self.count == 0) {
        completition(nil);
        return;
    }
    NSArray *array = [self copy];
    [array nextStep:0 error:nil operation:operation comletition:completition];
}

- (void)asyncEach:(ISArrayAsyncEachBlock)operation
      comletition:(ISArrayAsyncEachCompletitionBlock)completion
        concurent:(NSInteger)concurrent {
    if (self.count == 0) {
        completion(nil);
        return;
    }

    if (concurrent < 2) {
        NSArray *array = [self copy];
        [array nextStep:0 error:nil operation:operation comletition:completion];
        return;
    }

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = concurrent ? concurrent : 1;

    for (id object in [self copy]) {
        AsyncBlockOperation *op =
                [AsyncBlockOperation operationWithBlock:^(AsyncBlockOperation *op, AsyncBlockOperationCompletionBlock completionBlock) {
                    operation(object, completionBlock);
                }];
        [queue addOperation:op];
    }

    __weak NSOperationQueue *weakQueue = queue;

    __block RACDisposable *disposable;
    disposable = [RACObserve(queue, operationCount) subscribeNext:^(id x) {
        if (weakQueue.operationCount == 0) {
            completion(nil);
            [disposable dispose];
        }
    }];
}

@end

@implementation NSSet (ISAsyncBlocks)

- (void)asyncEach:(ISArrayAsyncEachBlock)operation comletition:(ISArrayAsyncEachCompletitionBlock)completition {
    [[self allObjects] asyncEach:operation comletition:completition];
}


@end
