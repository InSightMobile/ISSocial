//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SUserData.h"
#import "SFeedEntry.h"

@protocol SNewsEntry <SFeedEntry>

@property(copy, nonatomic) NSString *newsType;

@end


@interface SNewsEntry : SObject <SNewsEntry>


@end