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
@property(copy, nonatomic) NSString *userFirstName;
@property(copy, nonatomic) NSString *userLastName;
@property(copy, nonatomic) NSString *userName;
@property(copy, nonatomic) NSString *userEmail;
@property(copy, nonatomic) NSNumber *userGender;
@property(copy, nonatomic) MultiImage *userPicture;
@property(nonatomic, strong) NSNumber *isOnline;
@property(nonatomic, strong) NSDate *birthday;

@end

@interface SUserData : SObject <SUserData>


@end
