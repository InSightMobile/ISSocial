//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "FacebookConnector.h"

@class SUserData;

@interface FacebookConnector (UserData)

- (SUserData *)dataForUserId:(NSString *)userId name:(NSString *)name;

- (SUserData *)dataForUserId:(NSString *)userId;

- (SUserData *)parseUserData:(id)userInfo;

- (void)updateUserData:(NSArray *)usersData operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion;
@end