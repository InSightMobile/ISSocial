//
// Created by yarry on 04.03.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SMessageData.h"

@protocol SMessageThread <SObject>
@optional

@property(nonatomic, strong) NSString *objectId;
@property(nonatomic, strong) SMessageData *lastMessage;
@property(nonatomic, strong) SObject *messages;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) SUserData *messageCompanion;

@end

@interface SMessageThread : SObject <SMessageThread>



@end