//
//

#import "CahedConnector.h"


@implementation CahedConnector {
    SocialConnector *_connector;
}

- (id)initWithConnector:(SocialConnector *)connector {
    self = [super init];
    if (self) {
        _connector = connector;
    }
    return self;
}

+ (id)connectorWithConnector:(SocialConnector *)connector {
    return [[self alloc] initWithConnector:connector];
}


- (SObject *)processSocialConnectorProtocol:(SObject *)params completion:(SObjectCompletionBlock)completion operation:(SEL)selector {
    return [_connector readCached:selector params:params completion:completion];
}

@end