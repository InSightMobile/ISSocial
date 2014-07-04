//
//

#import <Foundation/Foundation.h>
#import "SObject.h"

@class SPhotoData;


@protocol SShareItem

@optional
@property(copy, nonatomic) NSString *text;
@property(copy, nonatomic) SPhotoData *photo;
@property(nonatomic, strong) NSArray *attachments;

@end

@interface SShareItem : SObject <SShareItem>
@end