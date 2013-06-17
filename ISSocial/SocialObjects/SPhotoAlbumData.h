//
//  SPhotoAlbumData.h
//  socials
//
//  Created by yar on 24.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SMediaObject.h"
#import "SFeedEntry.h"

@protocol SPhotoAlbumData <SMediaObject, SCommentedObject>

@property(nonatomic, copy) NSString *objectId;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSNumber *photoAlbumSize;

@property(nonatomic, copy) NSString *photoAlbumDescription;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSNumber *canUpload;
@property(nonatomic, strong) NSString *type;
@end

@interface SPhotoAlbumData : SObject <SPhotoAlbumData>


@end
