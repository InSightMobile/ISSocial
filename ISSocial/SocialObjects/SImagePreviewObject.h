//
// 

#import <Foundation/Foundation.h>
#import "SObject.h"
#import "SMediaObject.h"

@class MultiImage;

@protocol SImagePreviewObject <SMediaObject>
@optional
@property(copy, nonatomic) NSURL *previewURL;
@property(copy, nonatomic) UIImage *previewImage;
@property(nonatomic) MultiImage *multiImage;

@end

@interface SImagePreviewObject : SMediaObject <SImagePreviewObject>

@end