//
// 



#import "OdnoklassnikiConnector.h"
#import "OdnoklassnikiConnector+Users.h"
#import "SUserData.h"
#import "MultiImage.h"


@implementation OdnoklassnikiConnector (Users)
- (SUserData *)dataForUserId:(NSString *)userId
{
    return (SUserData *) [self mediaObjectForId:userId type:@"user"];
}

- (SObject *)parseUser:(id)responce
{
    NSString *objectId = [responce[@"uid"] stringValue];

    if (!objectId) {
        return nil;
    }

    SUserData *user = [self dataForUserId:objectId];

    user.userName = responce[@"name"];

    MultiImage *image = [MultiImage new];

    [image addImageURL:responce[@"pic_1"] quality:0.25];
    [image addImageURL:responce[@"pic_2"] quality:0.5];
    [image addImageURL:responce[@"pic_3"] quality:0.75];
    [image addImageURL:responce[@"pic_4"] quality:1];

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
            @"fields" : @"uid,name,online,pic_1,pic_2,pic_3,pic_4"
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
@end