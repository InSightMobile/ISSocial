//
//  NSDate+Facebook.h
//  socials
//
//  Created by yar on 30.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Facebook)

+ (NSDate *)dateWithFacebookString:(id)data;

+ (NSDate *)dateWithFacebookBirthdayString:(id)data;

- (NSString *)facebookString;

@end
