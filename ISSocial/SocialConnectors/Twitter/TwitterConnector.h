//
//

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "AccessSocialConnector.h"

@class ACAccount;

@interface TwitterConnector : AccessSocialConnector

+ (TwitterConnector *)instance;

@property(retain, nonatomic) SUserData *currentUserData;

@end
