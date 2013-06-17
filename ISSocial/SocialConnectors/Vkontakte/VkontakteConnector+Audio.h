//
// 



#import <Foundation/Foundation.h>
#import "VkontakteConnector.h"

@interface VkontakteConnector (Audio)
- (SAudioData *)parseAudioResponse:(NSDictionary *)info;

- (SObject *)parseAudiosResponce:(id)response;
@end