//
// 



#import <Foundation/Foundation.h>
#import "SObject.h"

@protocol SMediaObject <SObject>
@optional
@property(copy, nonatomic) NSString *mediaType;

@end

@interface SMediaObject : SObject <SMediaObject>
@end