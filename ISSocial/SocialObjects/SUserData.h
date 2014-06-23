//
//  SUserData.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SObject.h"
#import "SMediaObject.h"

/// User gender
typedef NS_ENUM(NSInteger, ISSUserGender) {

    /// User gender is unknown
            ISSUnknownUserGender = 0,

    /// User id female
            ISSFemaleUserGender = 1,

    /// User is male
            ISSMaleUserGender = 2,
};


@class MultiImage;

@protocol SUserData <SMediaObject>
@optional
@property(copy, nonatomic) NSString *firstName;
@property(copy, nonatomic) NSString *lastName;
@property(copy, nonatomic) NSString *userName;
@property(copy, nonatomic) NSString *userEmail;
@property(copy, nonatomic) NSNumber *userGender;
@property(copy, nonatomic) MultiImage *userPicture;
@property(copy, nonatomic) NSString *cityName;
@property(copy, nonatomic) NSString *userLocation;
@property(copy, nonatomic) NSString *countryName;
@property(copy, nonatomic) NSString *countryCode;

@property(nonatomic, strong) NSNumber *isOnline;
@property(nonatomic, strong) NSDate *birthday;


@property(nonatomic, strong) NSNumber *vkontakteCityId;
@property(nonatomic, strong) NSNumber *vkontakteCountryId;

@end

@interface SUserData : SObject <SUserData>


@end
