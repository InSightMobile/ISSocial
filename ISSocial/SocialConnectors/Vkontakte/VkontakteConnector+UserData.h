//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <ISSocial/SObject.h>
#import "VkontakteConnector.h"

@class SUserData;

@interface VkontakteConnector (UserData)
- (void)updateUserData:(NSArray *)userData fields:(NSArray *)fields operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion;


- (SObject *)parseUsersData:(id)response;
- (SObject *)parseUserData:(NSDictionary *)userInfo;

- (SUserData *)dataForUserId:(NSString *)userId;

- (NSArray *)profileFields;
@end