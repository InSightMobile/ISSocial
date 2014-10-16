//
//


#import "NSArray+Finding.h"
#import "NSObject+ISAppearance.h"


@implementation NSArray (Finding)

- (NSUInteger)indexOfObjectWithValueAtKeyPath:(NSString *)keyPath equalsTo:(id)value
{
    return [self indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj valueForKeyPath:keyPath] isEqual:value];
    }];
}

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)index
{
    NSMutableArray *mutableArray = [self mutableCopy];
    [mutableArray removeObjectAtIndex:index];
    return [mutableArray copy];
}

- (NSArray *)arrayByRemovingObject:(id)object
{
    NSUInteger index = [self indexOfObject:object];
    if(index != NSNotFound) {
        return [self arrayByRemovingObjectAtIndex:index];
    }
    return self;
}

@end