//
// 



#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SImagePreviewObject.h"
#import "SFeedEntry.h"
#import "SPhotoData.h"

@class SUserData;

@protocol SVideoData <SMultimediaObject>
@optional

@property(nonatomic, copy) NSString *videoFilename;
@property(nonatomic, strong) NSNumber *isDirectPlaybackURL;
@property(nonatomic, strong) NSString *videoId;

@end

@interface SVideoData : SImagePreviewObject <SVideoData>;


@end