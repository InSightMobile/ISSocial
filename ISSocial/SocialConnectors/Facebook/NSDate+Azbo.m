//
// 



#import "NSDate+Azbo.h"


@implementation NSDate (Azbo)
+ (NSDate *)dateWithAzboFlyerDate:(NSString *)strDate
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"dd.MM.yyyy";

    return [formatter dateFromString:strDate];
}
@end