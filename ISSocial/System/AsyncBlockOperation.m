//
//  AsyncBlockOperation.m
//  socials
//
//  Created by yar on 29.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "AsyncBlockOperation.h"
#import "NSArray+AsyncBlocks.h"

@interface AsyncBlockOperation ()
@property(assign) BOOL isConcurrent;
@property(assign) BOOL isFinished;
@property(assign) BOOL isCancelled;
@property(assign) BOOL isExecuting;

@property(copy) AsyncBlockOperationCompletionBlock operationCompletionBlock;

@property(nonatomic, copy) AsyncBlockOperationBlock block;
@end

@implementation AsyncBlockOperation

- (void)processingComplete:(NSError *)errorOrNil
{
    if (self.operationCompletionBlock)
        self.operationCompletionBlock(errorOrNil);

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];

    _isExecuting = NO;
    _isFinished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];

    if (_block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _block(self, ^(NSError *errorOrNil) {
                [self processingComplete:errorOrNil];
            });
        });
        return;
    }

    [_blocks asyncEach:^(id object, ISArrayAsyncEachResultBlock next) {

        AsyncBlockOperationBlock block = object;

        dispatch_async(dispatch_get_main_queue(), ^{
            block(self, next);
        });

    }      comletition:^(NSError *errorOrNil) {
        [self processingComplete:errorOrNil];
    }];
}

+ (AsyncBlockOperation *)operationWithBlock:(AsyncBlockOperationBlock)block
{
    return [self operationWithBlock:block comletion:nil];
}

+ (AsyncBlockOperation *)operationWithBlock:(AsyncBlockOperationBlock)block comletion:(AsyncBlockOperationCompletionBlock)completion;
{
    AsyncBlockOperation *op = [AsyncBlockOperation new];
    op.block = block;
    //[op addBlock:block];
    op.operationCompletionBlock = completion;
    return op;
}

- (void)addBlock:(AsyncBlockOperationBlock)pFunction
{
    if (!_blocks) {
        _blocks = [NSMutableArray arrayWithCapacity:1];
    }
    [_blocks addObject:[pFunction copy]];
}

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

@end
