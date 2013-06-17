//
// 

#import <Foundation/Foundation.h>

#import "SObject.h"
#import "SPhotoData.h"

@class SUserData;

@protocol SAudioData <SMultimediaObject>
@optional

@property(nonatomic, copy) NSString *fileName;
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) NSURL *ipodURL;
@property(nonatomic, strong) NSString *artist;
@property(nonatomic, strong) NSNumber *duration;
@property(nonatomic, strong) SUserData *owner;
@property(nonatomic, strong) NSString *audioId;

@end

@interface SAudioData : SObject <SAudioData>

@end