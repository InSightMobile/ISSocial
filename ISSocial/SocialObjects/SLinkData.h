//
// 



#import <Foundation/Foundation.h>
#import "SMediaObject.h"
#import "SCommentedObject.h"

@protocol SLinkData <SMediaObject, SCommentedObject>

@optional
@property(copy, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) NSString *linkURL;

@end

@interface SLinkData : SMediaObject <SLinkData>


@end