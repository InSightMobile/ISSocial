//
// 



#import "ISSAuthorisationInfo.h"
#import "TwitterConnector.h"
#import "ISSocial.h"

@interface ISSAuthorisationInfo ()

@end

@implementation ISSAuthorisationInfo
{

    SocialConnector *_handler;
}

- (void)setHandler:(SocialConnector *)handler
{
    _handler = handler;
    self.provider = handler.connectorCode;
}

- (SocialConnector *)handler
{
    if(!_handler && _provider) {
        _handler = [[ISSocial defaultInstance] connectorNamed:_provider];
    }
    return _handler;
}


@end