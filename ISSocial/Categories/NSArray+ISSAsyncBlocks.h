//
//  NSArray+AsyncBlocks.h
//  ISSocial
//
//  Created by  on 07.06.12.
//

#import <Foundation/Foundation.h>

typedef void (^ISArrayAsyncEachResultBlock)(NSError *errorOrNil);

typedef void (^ISArrayAsyncEachCompletitionBlock)(NSError *errorOrNil);

typedef void (^ISArrayAsyncEachBlock)(id object, ISArrayAsyncEachResultBlock next);


@interface NSArray (ISAsyncBlocks)

- (void)asyncEach:(ISArrayAsyncEachBlock)operation
      comletition:(ISArrayAsyncEachCompletitionBlock)completition;

- (void)asyncEach:(ISArrayAsyncEachBlock)operation comletition:(ISArrayAsyncEachCompletitionBlock)completion concurent:(NSInteger)concurrent;
@end

@interface NSSet (ISAsyncBlocks)

- (void)asyncEach:(ISArrayAsyncEachBlock)operation
      comletition:(ISArrayAsyncEachCompletitionBlock)completition;

@end