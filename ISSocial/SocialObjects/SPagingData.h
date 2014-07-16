//
//

#import <Foundation/Foundation.h>
#import "SObject.h"


@protocol SPagingData <SObject>
@optional

@property(nonatomic, strong) NSString *method;
@property(nonatomic, strong) NSDictionary *params;
@property(nonatomic, strong) NSString *anchor;
@property(nonatomic, strong) NSNumber *offset;

@end

@interface SPagingData : SObject<SPagingData>
@end