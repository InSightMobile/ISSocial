//
// 



#import <Foundation/Foundation.h>
#import "SMediaObject.h"
#import "SCommentedObject.h"

@class SPhotoData;
@class SUserData;

@protocol SLinkData <SMediaObject, SCommentedObject>

@optional
@property(copy, nonatomic) NSDate *date;
@property(copy, nonatomic) NSURL *linkURL;
@property(copy, nonatomic) NSString *message;
@property(copy, nonatomic) NSString *title;
@property(nonatomic, strong) SPhotoData *photo;
@property(nonatomic, strong) SUserData *owner;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, strong) NSString *name;
@end

@interface SLinkData : SMediaObject <SLinkData>


@end