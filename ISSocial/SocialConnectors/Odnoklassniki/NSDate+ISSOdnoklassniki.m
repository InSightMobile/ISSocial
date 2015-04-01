//
// 



#import "NSDate+ISSOdnoklassniki.h"


@implementation NSDate (ISSOdnoklassniki)

+ (NSDate *)dateWithOdnoklassnikiBirthdayString:(NSString *)dateString {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [df dateFromString:dateString];
    return date;
}

@end