//
// Created by Ярослав on 23.07.13.
// Copyright (c) 2013 Ярослав. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSDate+Vkontakte.h"


@implementation NSDate (Vkontakte)


+ (NSDate *)dateWithVkontakteBirthdayString:(id)data {
    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[data doubleValue]];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01T21:35:43+0000
    [df setDateFormat:@"dd.MM.yyyy"];
    NSDate *date = [df dateFromString:data];
    if (!date) {
        return [self dateWithVkontakteBirthdayNoYearString:data];
    }
    return date;
}

+ (NSDate *)dateWithVkontakteBirthdayNoYearString:(id)data {
    if ([data isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[data doubleValue]];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2010-12-01T21:35:43+0000
    [df setDateFormat:@"dd.MM"];
    NSDate *date = [df dateFromString:data];
    return date;
}

@end