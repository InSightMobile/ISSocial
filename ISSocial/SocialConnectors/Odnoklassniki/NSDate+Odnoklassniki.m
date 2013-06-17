//
// 



#import "NSDate+Odnoklassniki.h"


@implementation NSDate (Odnoklassniki)

+ (NSDate *)dateWithOdnoklassnikiString:(id)data
{
    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[data doubleValue]];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01 21:35:43
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:data];
    return date;
}
@end