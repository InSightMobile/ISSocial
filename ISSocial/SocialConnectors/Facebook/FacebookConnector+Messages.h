//
// 

#import <Foundation/Foundation.h>
#import "FacebookConnector.h"
#import "XMPPStream.h"

@interface FacebookConnector (Messages) <XMPPStreamDelegate>
- (void)xmppConnect;
@end