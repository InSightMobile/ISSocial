//
// 



#import <Foundation/Foundation.h>
#import "SocialConnector.h"

@interface CahedConnector : SocialConnector
- (id)initWithConnector:(SocialConnector *)connector;

+ (id)connectorWithConnector:(SocialConnector *)connector;


@end