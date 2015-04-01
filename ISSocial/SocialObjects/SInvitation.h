//
//

#import <Foundation/Foundation.h>
#import "SObject.h"

@class SUserData;

@protocol SInvitation

@optional
@property(copy, nonatomic) NSString *message;
@property(nonatomic, strong) NSArray *attachments;
@property(nonatomic, strong) SUserData *user;

@end

@interface SInvitation : SObject <SInvitation>


@end