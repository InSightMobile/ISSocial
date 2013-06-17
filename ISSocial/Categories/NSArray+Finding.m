//
// Created by yarry on 15.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSArray+Finding.h"


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

@end