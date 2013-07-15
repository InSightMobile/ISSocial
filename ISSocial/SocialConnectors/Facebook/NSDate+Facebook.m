//
//  NSDate+Facebook.m
//  socials
//
//  Created by yar on 30.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "NSDate+Facebook.h"

@implementation NSDate (Facebook)

+ (NSDate *)dateWithFacebookString:(id)data
{
    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[data doubleValue]];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01T21:35:43+0000
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    NSDate *date = [df dateFromString:data];
    return date;
}

+ (NSDate *)dateWithFacebookBirthdayString:(id)data
{
    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[data doubleValue]];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01T21:35:43+0000
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [df dateFromString:data];
    return date;
}

- (NSString *)facebookString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01T21:35:43+0000
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    NSString *dateStr = [df stringFromDate:self];
    return dateStr;
}


@end
