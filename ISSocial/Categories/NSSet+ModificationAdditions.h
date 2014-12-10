//
//  NSSet+ModificationAdditions.h
//  ISSocial
//
//  Created by yar on 29.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSet (ModificationAdditions)

- (NSSet *)setByUnioningSet:(NSSet *)aSet;

- (NSSet *)setByMinusingSet:(NSSet *)aSet;

- (NSSet *)setByIntersectingSet:(NSSet *)aSet;

- (NSSet *)setByComplementingIntersectionWithSet:(NSSet *)aSet;

- (NSSet *)setByAddingObject:(id)anObject;

- (NSSet *)setByAddingObjectsFromArray:(NSArray *)anArray;

- (NSSet *)setByRemovingObject:(id)anObject;

// NOTE: results set contains instance of NSNull if result of performing selector with some object is nil
//- (NSSet *)resultsOfMakeObjectsPerformSelector:(SEL)aSelector;
//- (NSSet *)resultsOfMakeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject;
@end
