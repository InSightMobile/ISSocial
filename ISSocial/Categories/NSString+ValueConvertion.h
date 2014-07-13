//
// 



#import <Foundation/Foundation.h>

@interface NSString (ValueConvertion)

- (NSString *)stringByDecodeFromPercentEscapes;

- (NSDictionary *)explodeURLQuery;
@end