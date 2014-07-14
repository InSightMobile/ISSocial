//
// 



#import "OdnoklassnikiConnector.h"
#import "OdnoklassnikiConnector+Users.h"
#import "SUserData.h"
#import "MultiImage.h"
#import "NSDate+ISSOdnoklassniki.h"
#import "NSString+TypeSafety.h"


@implementation OdnoklassnikiConnector (Users)
- (SUserData *)dataForUserId:(NSString *)userId
{
    return (SUserData *) [self mediaObjectForId:userId type:@"user"];
}

- (SObject *)parseUser:(id)response
{
    NSString *objectId = [response[@"uid"] stringValue];

    if (!objectId) {
        return nil;
    }

    SUserData *user = [self dataForUserId:objectId];

    user.userName = response[@"name"];
    user.firstName = response[@"first_name"];
    user.lastName = response[@"last_name"];
    user.birthday = [NSDate dateWithOdnoklassnikiBirthdayString:response[@"birthday"]];

    if([response[@"gender"] isKindOfClass:[NSString class]]) {
        NSString *genderString = response[@"gender"];

        if([genderString isEqualToString:@"male"]) {
            user.userGender = @(ISSMaleUserGender);
        }
        else if([genderString isEqualToString:@"female"]) {
            user.userGender = @(ISSFemaleUserGender);
        }
        else {
            user.userGender = @(ISSUnknownUserGender);
        }
    }

    if([response[@"location"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *location = response[@"location"];

        user.countryCode = location[@"countryCode"];
        user.cityName = location[@"city"];

    }

    MultiImage *image = [MultiImage new];

    [image addImageURL:[response[@"pic_1"] URLValue] quality:0.25];
    [image addImageURL:[response[@"pic_2"] URLValue] quality:0.5];
    [image addImageURL:[response[@"pic_3"] URLValue] quality:0.75];
    [image addImageURL:[response[@"pic_4"] URLValue] quality:1];

    if(!response[@"photo_id"]) {
        image.defaultImage = YES;
    }

    user.userPicture = image;
    return user;
}

- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"users.getLoggedInUser" parameters:@{} operation:operation processor:^(id response) {
            NSLog(@"response = %@", response);
            SObject *user = [self dataForUserId:response];

            [self updateUserData:@[user] operation:operation completion:^(SObject *result) {
                if(result.isSuccessful) {
                    self.currentUserData = result.subObjects[0];
                }
                [operation complete:user];
            }];
        }];
    }];
}

- (void)updateUserData:(NSArray *)usersData operation:(SocialConnectorOperation *)operation  completion:(SObjectCompletionBlock)completion
{
    if (!usersData.count) {
        completion(nil);
        return;
    }

    NSSet *userIds = [NSSet setWithArray:[usersData valueForKey:@"objectId"]];

    NSDictionary *parameters = @{
            @"uids" : [userIds.allObjects componentsJoinedByString:@","],
            @"fields" : @"uid,name,online,pic_1,pic_2,pic_3,pic_4,photo_id,first_name,last_name,birthday,gender,age,location"
    };

    SObject *result = [SObject objectCollectionWithHandler:self];

    [self simpleMethod:@"users.getInfo" parameters:parameters operation:operation processor:^(id users) {

        for (NSDictionary *user in users) {
            [result addSubObject:[self parseUser:user]];
        }
        completion(result);
    }];
}

- (SObject *)readUserFriendsOnline:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"friends.getOnline" parameters:@{} operation:operation processor:^(NSArray *response) {

            NSLog(@"response = %@", response);

            SObject *users = [SObject objectCollectionWithHandler:self];

            for (id user in response) {
                SUserData *userData = [self dataForUserId:[user stringValue]];
                userData.isOnline = @YES;
                [users addSubObject:userData];
            }
            [operation complete:users];
        }];
    }];
}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"friends.get" parameters:@{} operation:operation processor:^(NSArray *response) {

            NSLog(@"response = %@", response);

            SObject *users = [SObject objectCollectionWithHandler:self];

            for (id user in response) {
                SUserData *userData = [self dataForUserId:[user stringValue]];
                userData.isOnline = @NO;
                [users addSubObject:userData];
            }

            [self readUserFriendsOnline:operation.object completion:^(SObject *onlineResult) {

                [self updateUserData:users.subObjects operation:operation completion:^(SObject *result) {
                    [operation complete:result];
                }];
            }];
        }];
    }];
}

- (SObject *)readUserMutualFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self readUserFriends:params completion:completion];
}


@end