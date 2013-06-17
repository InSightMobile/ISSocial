//
//

@class SObject;
@class SocialConnector;

typedef void (^SocialConnectorCompletionBlock)(SObject *object);

@interface SocialConnectorOperation : NSOperation

@property(copy, nonatomic) SocialConnectorCompletionBlock completionHandler;
@property(copy, nonatomic) SocialConnectorCompletionBlock completion;
@property(nonatomic) BOOL completed;

- (void)cancel;

- (void)complete:(SObject *)object;

- (void)update:(SObject *)object;

- (id)initWithHandler:(SocialConnector *)connector parent:(SocialConnectorOperation *)parent;

- (void)completeWithFailure;

@property(readonly, nonatomic, strong) SObject *object;

@property(nonatomic, strong, readonly) SocialConnectorOperation *parentOperation;

- (void)completeWithError:(NSError *)error;

- (void)addConnection:(id)connection;

- (void)removeConnection:(id)connection;

- (void)startSubOperation:(NSOperation *)operation;

- (void)addSubOperation:(NSOperation *)operation;

@property(readonly, nonatomic) BOOL isFinished;

- (void)removeSubOperation:(NSOperation *)operation;

@property(readonly, nonatomic) BOOL isCanceled;
@property(readonly, nonatomic) BOOL isExecuting;

@end

