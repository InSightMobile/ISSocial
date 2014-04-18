//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "VkontakteConnector+UserData.h"
#import "SUserData.h"
#import "MultiImage.h"
#import "NSString+TypeSafety.h"
#import "NSDate+Facebook.h"
#import "NSDate+Vkontakte.h"

@implementation VkontakteConnector (UserData)

- (void)updateUserData:(NSArray *)usersData operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    if (!usersData.count) {
        completion(nil);
        return;
    }
    NSSet *userIds = [NSSet setWithArray:[usersData valueForKey:@"objectId"]];
    [self updateCountryCodesWithOperation:operation completion:^(SObject *result) {
        [self simpleMethod:@"users.get" parameters:@{@"uids" : [userIds.allObjects componentsJoinedByString:@","],
                @"fields" : @"uid,first_name,last_name,photo,bdate,city,country,sex,screen_name"}
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseUsersData:response];

            [result complete:completion];
        }];
    }];
}

- (void)updateCountryCodesWithOperation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    NSArray *countryArray = [NSLocale ISOCountryCodes];
    if(self.countryCodesById) {
        completion([SObject successful]);
        return;
    }
    self.countryCodesById = [NSMutableDictionary dictionaryWithCapacity:countryArray.count];

    [self simpleMethod:@"database.getCountries" parameters:@{@"count":@(countryArray.count), @"code" : [countryArray componentsJoinedByString:@","]}
             operation:operation processor:^(NSDictionary * response) {

        NSArray *countryCodes = response[@"items"];

        for (int i = 0; i < countryCodes.count; i++) {
            self.countryCodesById[countryCodes[i][@"id"]] = countryArray[i];
        }

        completion([SObject successful]);
    }];
}

- (SObject *)parseUserData:(NSDictionary *)userInfo
{
    NSString *userId = userInfo[@"uid"];

    if (userInfo[@"gid"]) {
        userId = [NSString stringWithFormat:@"-%@", userInfo[@"gid"]];
    }

    SUserData *userData = [self dataForUserId:[userId stringValue]];

    userData.firstName = userInfo[@"first_name"];
    userData.lastName = userInfo[@"last_name"];

    userData.userName = [NSString stringWithFormat:@"%@ %@", userInfo[@"first_name"], userInfo[@"last_name"]];

    if (userInfo[@"name"]) {
        userData.userName = userInfo[@"name"];
    }

    if (userInfo[@"bdate"]) {
        NSString *bdate = userInfo[@"bdate"];
        userData.birthday = [NSDate dateWithVkontakteBirthdayString:bdate];
    }

    if (userInfo[@"sex"]) {
        // matches internal structure
        userData.userGender = userInfo[@"sex"];
    }

    if (userInfo[@"city"]) {
        userData.vkontakteCityId =  userInfo[@"city"][@"id"];

        userData.cityName = userInfo[@"city"][@"title"];
    }

    if (userInfo[@"country"]) {
        NSNumber *countryId = userInfo[@"country"][@"id"];
        userData.vkontakteCountryId =  countryId;
        userData.countryCode = self.countryCodesById[countryId];
        userData.countryName = userInfo[@"country"][@"title"];
    }

    MultiImage *image = [MultiImage new];
    [image addImageURL:[userInfo[@"photo"] URLValue] quality:1];

    userData.userPicture = image;

    return userData;
}

- (SObject *)parseUsersData:(id)response
{
    SObject *result = [SObject objectCollectionWithHandler:self];
    for (NSDictionary *userInfo in response) {
        if ([userInfo isKindOfClass:[NSDictionary class]]) {
            [result addSubObject:[self parseUserData:userInfo]];
        }
    }
    return result;
}

- (void)updateOnlineStatus:(SUserData *)params
                     users:(NSArray *)users
                 operation:(SocialConnectorOperation *)operation
                completion:(SObjectCompletionBlock)completion
{
    NSString *userId = params.objectId;
    if (!userId) {
            userId = self.userId;
    }

    [self simpleMethod:@"friends.getOnline" parameters:@{@"uid" : userId, @"online_mobile" : @YES}
             operation:operation processor:^(id response) {

        NSLog(@"response = %@", response);

        SObject *result = [SObject objectCollectionWithHandler:self];

        for (SUserData *user in users) {
            user.isOnline = @NO;
        }

        if ([response isKindOfClass:[NSDictionary class]]) {

            for (id uid in response[@"online"]) {
                SUserData *userData = [self dataForUserId:[uid stringValue]];
                userData.isOnline = @YES;
                [result addSubObject:userData];
            }

            for (id uid in response[@"online_mobile"]) {
                SUserData *userData = [self dataForUserId:[uid stringValue]];
                [result addSubObject:userData];
                userData.isOnline = @YES;
            }
        }
        else if ([response isKindOfClass:[NSArray class]]) {
            for (id uid in response) {
                SUserData *userData = [self dataForUserId:[uid stringValue]];
                [result addSubObject:userData];
                userData.isOnline = @YES;
            }
        }

        completion(result);
    }];
}

- (SObject *)readUserFriendsOnline:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self updateOnlineStatus:params users:nil operation:operation completion:^(SObject *result) {
            [operation complete:result];
        }];
    }];
}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;
        if (!userId) {
                    userId = self.userId;
        }

        [self simpleMethod:@"friends.get" parameters:@{@"uid" : userId, @"fields" : @"uid,first_name,last_name,photo,bdate"}
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);
            SObject *result = [self parseUsersData:response];

            [self updateOnlineStatus:params users:result.subObjects operation:operation completion:^(SObject *onlineResult) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)acceptUserFriendRequest:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;

        [self simpleMethod:@"friends.add" parameters:@{@"uid" : userId}
                 operation:operation processor:^(id response) {

            SUserData *user = [self dataForUserId:userId];
            [operation complete:user];
        }];
    }];
}

- (SObject *)rejectUserFriendRequest:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;

        [self simpleMethod:@"friends.delete" parameters:@{@"uid" : userId}
                 operation:operation processor:^(id response) {

            SUserData *user = [self dataForUserId:userId];
            [operation complete:user];
        }];
    }];
}

- (SObject *)readUserFriendRequests:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;
        if (!userId) {
                    userId = self.userId;
        }

        [self simpleMethod:@"friends.getRequests" parameters:@{
                @"uid" : userId,
                @"photo_sizes" : @1,
                @"fields" : @"uid,first_name,last_name,photo"}
                 operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [SObject objectCollectionWithHandler:self];
            for (NSNumber *userInfo in response) {
                SUserData *userData = [self dataForUserId:[userInfo stringValue]];
                [result addSubObject:userData];
            }

            [self updateUserData:result.subObjects operation:operation completion:^(SObject *result) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion
{

    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *userId = params.objectId;
        if (!userId) {
                    userId = self.userId;
        }

        if (!userId.length) {
            [operation completeWithFailure];
            return;
        }

        [self simpleMethod:@"users.get" parameters:@{@"uids" : userId, @"fields" : @"uid,first_name,last_name,photo"}
                 operation:operation processor:^(id response) {

            SObject *result = [self parseUsersData:response];

            if (!result.subObjects.count) {
                            [operation completeWithFailure];
                        }
            else {
                            [operation complete:result.subObjects[0]];
            }

        }];

    }];
}

- (SUserData *)dataForUserId:(NSString *)userId
{
    return (SUserData *) [self mediaObjectForId:userId type:@"users"];
}


@end