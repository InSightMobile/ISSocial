//
// Created by yarry on 15.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface NSArray (Finding)
- (NSUInteger)indexOfObjectWithValueAtKeyPath:(NSString *)keyPath equalsTo:(id)value;

- (NSArray *)arrayByRemovingObjectAtIndex:(NSUInteger)index1;
@end