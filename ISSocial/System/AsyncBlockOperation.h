//
//  AsyncBlockOperation.h
//  socials
//
//  Created by yar on 29.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AsyncBlockOperation;

typedef void (^AsyncBlockOperationCompletionBlock)(NSError *errorOrNil);

typedef void
(^AsyncBlockOperationBlock)(AsyncBlockOperation *operation, AsyncBlockOperationCompletionBlock completionBlock);

@interface AsyncBlockOperation : NSOperation

@property(copy, nonatomic) NSMutableArray *blocks;

+ (AsyncBlockOperation *)operationWithBlock:(AsyncBlockOperationBlock)block;

+ (AsyncBlockOperation *)operationWithBlock:(AsyncBlockOperationBlock)block comletion:(AsyncBlockOperationCompletionBlock)completion;

- (void)addBlock:(AsyncBlockOperationBlock)pFunction;

@end
