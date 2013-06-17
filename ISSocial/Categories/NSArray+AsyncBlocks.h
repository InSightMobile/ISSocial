//
//  NSArray+AsyncBlocks.h
//  AZBOTravelGuide
//
//  Created by  on 07.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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