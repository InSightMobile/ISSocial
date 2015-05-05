//
// 



#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@interface VkontakteConnector (Pull)

- (void)addPullReceiver:(SObject *)reseiverOperation forArea:(NSString *)area;
- (void)startPull;
@end