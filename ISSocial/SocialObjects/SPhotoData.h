//
//  SPhotoData.h
//  socials
//
//  Created by yar on 24.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SObject.h"
#import "SImagePreviewObject.h"
#import "SFeedEntry.h"

@class SUserData;
@class MultiImage;

@protocol SMultimediaObject <SMediaObject, SImagePreviewObject, SCommentedObject>

@property(nonatomic, strong) NSURL *playbackURL;
@property(copy, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *title;
@property(nonatomic, strong) SUserData *author;
@property(nonatomic, strong) SUserData *owner;
@property(strong, nonatomic) NSData *sourceData;
@property(strong, nonatomic) NSData *sourceURL;
@property(nonatomic, strong) UIImage *sourceImage;

@end

@protocol SPhotoData <SMultimediaObject>

@property(copy, nonatomic) NSURL *photoURL;


@property(strong, nonatomic) SObject *album;

@property(nonatomic, copy) NSString *photoId;

@end

@interface SPhotoData : SImagePreviewObject <SPhotoData>


@end
