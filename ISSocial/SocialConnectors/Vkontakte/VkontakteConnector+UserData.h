//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@class SUserData;

@interface VkontakteConnector (UserData)
- (void)updateUserData:(NSArray *)userData operation:(SocialConnectorOperation *)operation completion:(CompletionBlock)completion;


- (SObject *)parseUsersData:(id)response;


- (SUserData *)dataForUserId:(NSString *)userId;
@end