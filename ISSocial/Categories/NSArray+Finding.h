//
//


#import <Foundation/Foundation.h>

@interface NSArray (Finding)
- (NSUInteger)indexOfObjectWithValueAtKeyPath:(NSString *)keyPath equalsTo:(id)value;

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)index;

- (NSArray *)arrayByRemovingObject:(id)object;
@end