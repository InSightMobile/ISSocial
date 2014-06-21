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

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.accessToken = [coder decodeObjectForKey:@"self.accessToken"];
        self.accessTokenSecret = [coder decodeObjectForKey:@"self.accessTokenSecret"];
        self.userId = [coder decodeObjectForKey:@"self.userId"];
        self.provider = [coder decodeObjectForKey:@"self.provider"];

        NSString *handlerName = [coder decodeObjectForKey:@"self.handler"];
        _handler = handlerName.length ? [[ISSocial defaultInstance] connectorNamed:handlerName] : nil;
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.accessToken forKey:@"self.accessToken"];
    [coder encodeObject:self.accessTokenSecret forKey:@"self.accessTokenSecret"];
    [coder encodeObject:self.userId forKey:@"self.userId"];
    [coder encodeObject:self.provider forKey:@"self.provider"];
    [coder encodeObject:_handler.connectorName forKey:@"self.handler"];
}

@end