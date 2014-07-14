//
// Created by yarry on 09.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FacebookConnector+UserData.h"
#import "SUserData.h"
#import "FBRequest.h"
#import "NSString+TypeSafety.h"
#import "MultiImage.h"
#import "NSDate+Facebook.h"

static NSMutableDictionary *_usersById;

@implementation FacebookConnector (UserData)

- (SObject *)readUserData:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        bool myself = NO;
        NSString *userId = params.objectId;
        if (userId.length == 0) {
            userId = @"me";
            myself = YES;
        }

        NSString *fields = @"picture,first_name,last_name,birthday,email,gender,location";

        [self simpleMethod:userId params:@{@"fields" : fields} operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SUserData *userData = [self parseUserData:response];

            if (myself) {
                self.currentUserData = userData;
            }

            [operation complete:userData];
        }];

    }];
}


- (SObject *)readUserFriendRequests:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        [self simpleMethod:@"me/friendrequests/" operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [SObject objectCollectionWithHandler:self];

            for (NSDictionary *request in response[@"date"]) {

                SUserData *user = [self dataForUserId:[request[@"from"] stringValue]];
                [result addSubObject:user];
            }

            [self updateUserData:result.subObjects operation:operation completion:^(SObject *result) {
                [operation complete:result];
            }];
        }];
    }];
}

- (SObject *)readUserFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self operationWithObject:params completion:completion processor:^(SocialConnectorOperation *operation) {

        NSString *fql =
                @"SELECT uid,name, online_presence,birthday_date FROM user WHERE uid IN (SELECT uid2 FROM friend where uid1 = me())";

        [self simpleQuery:fql operation:operation processor:^(id response) {

            NSLog(@"response = %@", response);

            SObject *result = [self parseUsers:response[@"data"]];

            [operation complete:result];
        }];

    }];
}

- (SUserData *)dataForUserId:(NSString *)userId name:(NSString *)name
{
    if (!userId) {
        return nil;
    }

    SUserData *data = (SUserData *) [self mediaObjectForId:userId type:@"user"];

    if (!data.userPicture) {
        MultiImage *image = [MultiImage new];
        [image addImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/picture", FBGraphBasePath, userId]] quality:1];
        [image setImageWightHeightURLFormat:[NSString stringWithFormat:@"%@/%@/picture?width=%%d&height=%%d", FBGraphBasePath, userId]];
        data.userPicture = image;
    }

    if (name) {
        data.userName = name;
    }
    return data;
}

- (SUserData *)dataForUserId:(NSString *)userId
{
    return [self dataForUserId:userId name:nil];
}

- (void)updateUserData:(NSArray *)usersData operation:(SocialConnectorOperation *)operation completion:(SObjectCompletionBlock)completion
{
    if (!usersData.count) {
        completion(nil);
        return;
    }
    NSSet *userIds = [NSSet setWithArray:[usersData valueForKey:@"objectId"]];

    [self simpleQuery:[NSString stringWithFormat:@"select name,id FROM profile WHERE id in (%@)", [userIds.allObjects componentsJoinedByString:@","]]
            operation:operation processor:^(id response) {

        NSLog(@"response = %@", response);

        SObject *users = [self parseUsers:response[@"data"]];

        completion(users);
    }];
}

- (SObject *)parseUsers:(NSArray *)usersData
{
    SObject *users = [SObject objectCollectionWithHandler:self];

    for (NSDictionary *userData in usersData) {

        SUserData *data = [self parseUserData:userData];
        [users addSubObject:data];
    }
    return users;
}

- (SUserData *)parseUserData:(NSDictionary *)userData
{
    NSString *objectId = [userData[@"id"] stringValue];
    if (userData[@"uid"]) {
        objectId = [userData[@"uid"] stringValue];
    }

    SUserData *data = [self dataForUserId:objectId name:userData[@"name"]];

    data.firstName = userData[@"first_name"];
    data.lastName = userData[@"last_name"];

    if ([userData[@"online_presence"] isKindOfClass:[NSString class]]) {
        data.isOnline = @(![userData[@"online_presence"] isEqualToString:@"offline"]);
    }

    if ([userData[@"birthday_date"] isKindOfClass:[NSString class]]) {
        data.birthday = [NSDate dateWithFacebookBirthdayString:userData[@"birthday_date"]];
    }

    if ([userData[@"birthday"] isKindOfClass:[NSString class]]) {
        data.birthday = [NSDate dateWithFacebookBirthdayString:userData[@"birthday"]];
    }

    if ([userData[@"email"] isKindOfClass:[NSString class]]) {
        data.userEmail = userData[@"email"];
    }

    if ([userData[@"gender"] isKindOfClass:[NSString class]]) {
        NSString *facebookGender = userData[@"gender"];

        if ([facebookGender isEqualToString:@"male"]) {
            data.userGender = @(ISSMaleUserGender);
        }
        else if ([facebookGender isEqualToString:@"female"]) {
            data.userGender = @(ISSFemaleUserGender);
        }
        else {
            data.userGender = @(ISSUnknownUserGender);
        }
    }

    NSString *locationID = nil;

    if ([userData[@"location"] isKindOfClass:[NSDictionary class]]) {
        NSString *locationName = userData[@"location"][@"name"];

        data.userLocation = locationName;
        locationID = userData[@"location"][@"id"];

        if (locationName.length > 0) {

            NSArray *parts = [locationName componentsSeparatedByString:@", "];
            data.cityName = parts[0];
            data.countryName = parts[1];
        }

    }

    if ([userData[@"picture"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *pictureData = userData[@"picture"][@"data"];

        BOOL isDefault = [pictureData[@"is_silhouette"] boolValue];
        NSString *url = pictureData[@"url"];

        MultiImage *image = [MultiImage new];

        [image addImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/picture", FBGraphBasePath, objectId]] quality:1];
        [image setImageWightHeightURLFormat:[NSString stringWithFormat:@"%@/%@/picture?width=%%d&height=%%d", FBGraphBasePath, objectId]];
        data.userPicture = image;

        image.defaultImage = isDefault;

        data.userPicture = image;
    }

    return data;
}

- (SObject *)readUserMutualFriends:(SUserData *)params completion:(SObjectCompletionBlock)completion
{
    return [self readUserFriends:params completion:completion];
}



@end