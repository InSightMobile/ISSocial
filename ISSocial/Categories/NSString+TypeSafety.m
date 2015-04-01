//
// 



#import "NSString+TypeSafety.h"


@implementation NSString (TypeSafety)
- (NSString *)stringValue {
    return [self copy];
}

- (NSURL *)URLValue {
    return [NSURL URLWithString:self];
}
@end