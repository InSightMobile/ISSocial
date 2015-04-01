//
// 

#import "SocialConnector.h"
#import "ISSocial+Errors.h"

@interface SocialConnectorOperation ()
@property(nonatomic, strong) SocialConnector *handler;
@property(readwrite, nonatomic, strong) SObject *object;

@property(readwrite, nonatomic) BOOL isFinished;
@property(readwrite, nonatomic) BOOL isCanceled;
@property(readwrite, nonatomic) BOOL isExecuting;
@end

@implementation SocialConnectorOperation {
    NSMutableSet *_connections;
}


- (id)init {
    self = [super init];
    if (self) {
        _connections = [NSMutableSet set];
    }

    return self;
}


- (void)start {
    if (_isCanceled) {
        return;
    }

    if (!_isExecuting) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)cancel {
    if (_isExecuting) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = NO;
        [self didChangeValueForKey:@"isExecuting"];
    }

    if (!_isCanceled) {
        [self willChangeValueForKey:@"_isCanceled"];
        _isCanceled = YES;
        [self didChangeValueForKey:@"_isCanceled"];
    }

    [self cancelConnections];


}

- (void)cancelConnections {
    for (id connection in [_connections copy]) {
        if ([connection respondsToSelector:@selector(cancel)]) {
            [connection cancel];
        }
    }
    [_connections removeAllObjects];
}

- (void)complete:(SObject *)object {
    if (_isCanceled) {
        return;
    }

    self.completed = YES;

    if (_completionHandler) {
        _completionHandler(object);
    }

    if (_isExecuting) {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = NO;
        [self didChangeValueForKey:@"isExecuting"];
    }
    if (!_isFinished) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (void)update:(SObject *)object {
    if (_completionHandler)
        _completionHandler(object);
}


- (id)initWithHandler:(SocialConnector *)connector parent:(SocialConnectorOperation *)parent {
    self = [super init];
    if (self) {
        self.handler = connector;
        _object = [[SObject alloc] initWithHandler:_handler state:SObjectStateProcessing];
        _object.operation = self;
        _parentOperation = parent;
        _connections = [NSMutableSet set];
        [_parentOperation addSubOperation:self];
    }
    return self;
}

- (void)completeWithFailure {
    [self complete:[SObject error:[ISSocial errorWithError:nil]]];
}

- (SObject *)object {
    if (_object) return _object;

    SObject *obj = [[SObject alloc] initWithHandler:_handler];
    obj.operation = self;
    return obj;
}

- (void)completeWithError:(NSError *)error {
    [self complete:[SObject error:[ISSocial errorWithError:error]]];
}

- (void)addConnection:(id)connection {
    [_connections addObject:connection];
}

- (void)removeConnection:(id)connection {
    [_connections removeObject:connection];
}

- (void)startSubOperation:(NSOperation *)operation {
    [operation start];
    [self addSubOperation:operation];
}

- (void)addSubOperation:(NSOperation *)operation {
    [self addConnection:operation];
}

- (void)removeSubOperation:(NSOperation *)operation {
    [self removeConnection:operation];
}
@end