//
// Created by yarry on 15.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SFeedEntry.h"

@class SUserData;
@class SFeedEntry;

@protocol SCommentData <SMediaObject>

@optional
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, strong) SUserData *author;
@property(nonatomic, strong) id <SCommentedObject> commentedObject;
@property(nonatomic, copy) NSString *htmlMessage;

@end


@interface SCommentData : SObject <SCommentData>

@end