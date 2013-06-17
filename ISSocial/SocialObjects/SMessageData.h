//
// 



#import <Foundation/Foundation.h>
#import "SObject.h"

@class SUserData;
@class SMessageThread;

@protocol SMessageData <SObject>
@optional
@property(nonatomic, strong) NSString *message;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) SUserData *messageCompanion;
@property(nonatomic, strong) NSNumber *isOutgoing;
@property(nonatomic, strong) NSArray *attachments;
@property(nonatomic, strong) SMessageThread *thread;
@property(nonatomic, strong) SUserData *messageAuthor;
@property(nonatomic, strong) NSNumber *isUnread;
@end


@interface SMessageData : SObject <SMessageData>


@end