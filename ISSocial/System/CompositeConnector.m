//
//  CompositeConnector.m
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "CompositeConnector.h"
#import "NSSet+ModificationAdditions.h"
#import "AsyncBlockOperation.h"
#import "BlockOperationQueue.h"
#import "AccessSocialConnector.h"

@interface CompositeConnector ()

@property(nonatomic, readwrite) NSSet *availableConnectors;
@property(nonatomic, strong) NSArray *specifications;
@property(nonatomic, readwrite) NSSet *activeConnectors;
@property(nonatomic, strong) CompositeConnector *superConnector;
@property(nonatomic, strong) NSSet *deactivatedConnectors;
@end

@implementation CompositeConnector

+ (CompositeConnector *)globalConnectors
{
    static CompositeConnector *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            _instance.restorationId = @"globalConnectors";
        }
    }
    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithRestorationId:(NSString *)restorationId {
    self = [super init];
    if (self) {
        self.restorationId = restorationId;
        [self commonInit];
    }
    return self;
}

+ (id)connectorWithRestorationId:(NSString *)restorationId {
    return [[self alloc] initWithRestorationId:restorationId];
}


- (id)initWithConnectorSpecifications:(NSArray *)specifications superConnector:(CompositeConnector *)superConnector restorationId:(NSString *)restorationId
{
    self = [super init];
    if (self) {
        self.superConnector = superConnector;
        self.specifications = specifications;
        self.restorationId = restorationId;
        [self commonInit];
    }
    return self;
}

- (id <CompositeConnectorDelegate>)delegate
{
    return _delegate;
}


- (id)initWithConnectorSpecifications:(NSArray *)specifications restorationId:(NSString *)restorationId
{
    return [self initWithConnectorSpecifications:specifications superConnector:[CompositeConnector globalConnectors] restorationId:restorationId];
}

- (id)initWithConnectorSpecifications:(NSArray *)specifications
{
    return [self initWithConnectorSpecifications:specifications superConnector:[CompositeConnector globalConnectors] restorationId:nil];
}

- (id)initWithSuperConnector:(CompositeConnector *)superConnector
{
    return [self initWithConnectorSpecifications:nil superConnector:superConnector restorationId:nil];
}

- (void)commonInit
{
    self.handleCache = NO;
    [self updateConnectors];
}

- (void)dealloc
{
    [self saveActiveStates];
    self.superConnector = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)connectorsDidChanged:(NSNotification *)nf
{
    if (nf.object == self) return;
    [self updateConnectors];
}

- (void)setSpecifications:(NSArray *)specifications
{
    _specifications = specifications;
    [self updateConnectors];
}

- (void)setConnectors:(NSArray *)connectors asActive:(BOOL)active
{
    NSSet *activeConnectors;
    if (active) {
        activeConnectors = [NSSet setWithArray:connectors];
    }
    else {
        activeConnectors = [NSSet set];
    }
    NSSet *aviableConnectors = [NSSet setWithArray:connectors];

    [self setAvailableConnectors:aviableConnectors
                activeConnectors:[self restoreActiveStates:activeConnectors aviableConnectors:aviableConnectors]];

}

- (void)addConnector:(SocialConnector *)connector asActive:(BOOL)active
{
    if(!_availableConnectors) {
        self.availableConnectors = [NSSet setWithObject:connector];
    }
    else if(![self.availableConnectors containsObject:connector]) {
        self.availableConnectors = [_availableConnectors setByAddingObject:connector];
    }
    if(active) {
        [self activateConnector:connector];
    }
    else {
        [self deactivateConnector:connector];
    }
}


- (void)setAvailableConnectors:(NSSet *)aviableConnectors activeConnectors:(NSSet *)activeConnectors
{
    self.availableConnectors = aviableConnectors;
    self.activeConnectors = activeConnectors;
}

- (void)setSuperConnector:(CompositeConnector *)superConnector
{
    if (_superConnector) {
        [_superConnector removeObserver:self forKeyPath:@"activeConnectors"];
    }
    _superConnector = superConnector;
    [_superConnector addObserver:self forKeyPath:@"activeConnectors" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        return;
    }
    if (object == _superConnector) {
        [self updateConnectors];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+ (NSMutableSet *)connectorsSupportingSpecification:(NSArray *)spec fromSet:(id <NSFastEnumeration, NSCopying, NSObject>)connectors
{
    NSMutableSet *candidateConnectors = [NSMutableSet set];

    if (!connectors) {
        return candidateConnectors;
    }

    for (SocialConnector *connector in connectors) {
        [candidateConnectors addObject:connector];
        for (NSString *specification in spec) {
            if (![connector meetsSpecification:specification]) {
                [candidateConnectors removeObject:connector];
                break;
            }
        }
    }
    return candidateConnectors;
}

- (void)updateConnectors
{
    NSMutableSet *candidateConnectors;

    if (_specifications.count) {
        candidateConnectors =
                [CompositeConnector connectorsSupportingSpecification:_specifications fromSet:_superConnector.activeConnectors];
    }
    else if(_superConnector){
        candidateConnectors = [[NSMutableSet setWithSet:_superConnector.activeConnectors] mutableCopy];
    }
    else {
        candidateConnectors = [[self restoreActiveStates:nil aviableConnectors:nil] mutableCopy];
    }

    if (!candidateConnectors) {
        candidateConnectors = [self restoreAvailableConnectors];
    }

    NSSet *connectors = [candidateConnectors setByMinusingSet:_deactivatedConnectors];
    self.activeConnectors = [self restoreActiveStates:connectors aviableConnectors:candidateConnectors];
    self.availableConnectors = candidateConnectors;

    self.defaultConnector = _superConnector.defaultConnector;
    return;
}

- (NSMutableSet *)restoreAvailableConnectors {
    if (self.restorationId) {

        NSArray *mod =
                [[NSUserDefaults standardUserDefaults] arrayForKey:[self.restorationId stringByAppendingString:@"v2"]];
        if (mod.count > 2) {

            NSArray *available = mod[2];

            NSMutableSet *availableConnectors = [NSMutableSet setWithCapacity:available.count];

            for (NSString *code in available) {

                Class <AccessSocialConnector> class = NSClassFromString(code);
                [availableConnectors addObject:[class instance]];
            }
            return availableConnectors;
        }
    }
    return nil;
}

- (void)activateConnector:(SocialConnector *)connector
{
    if (![_availableConnectors containsObject:connector]) return;

    if ([_deactivatedConnectors containsObject:connector]) {
        self.deactivatedConnectors = [_deactivatedConnectors setByRemovingObject:connector];
    }

    if (!_activeConnectors.count) {
        self.activeConnectors = [NSSet setWithObject:connector];
    }
    else {

        if(self.singleSelection) {
            self.activeConnectors = [NSSet setWithObject:connector];
        }
        else {
            self.activeConnectors = [_activeConnectors setByAddingObject:connector];
        }
    }
}

- (void)deactivateConnector:(SocialConnector *)connector
{
    if (!_deactivatedConnectors.count) {
        self.deactivatedConnectors = [NSSet setWithObject:connector];
    }
    else {
        self.deactivatedConnectors = [_deactivatedConnectors setByAddingObject:connector];
    }

    if ([_activeConnectors containsObject:connector]) {
        self.activeConnectors = [_activeConnectors setByRemovingObject:connector];
    }
}

- (BOOL)isConnectorActive:(SocialConnector *)connector
{
    return [_activeConnectors containsObject:connector];
}

- (void)activateConnectors:(id <NSFastEnumeration>)connectors
{
    for (SocialConnector *connector in connectors) {
        [self activateConnector:connector];
    }
}

- (void)activateConnectors:(NSSet *)connectors exclusive:(BOOL)exclusive
{
    if (exclusive) {
        [self deactivateConnectors:[self.availableConnectors setByMinusingSet:connectors]];
    }
    [self activateConnectors:connectors];
}

- (void)addAndActivateConnectors:(NSSet *)connectors exclusive:(BOOL)exclusive
{
    NSSet* connectorsToAdd = [connectors setByMinusingSet:self.availableConnectors];
    if(connectorsToAdd.count) {
        if (_availableConnectors) {
            self.availableConnectors = [_availableConnectors setByAddingObjectsFromSet:connectorsToAdd];
        }
        else {
            self.availableConnectors = connectorsToAdd;
        }
    }

    if (exclusive) {
        [self deactivateConnectors:[self.availableConnectors setByMinusingSet:connectors]];
    }
    [self activateConnectors:connectors];
}


- (void)activateAllConnectors
{
    [self activateConnectors:[_availableConnectors copy]];
}

- (void)deactivateConnectors:(id <NSFastEnumeration>)connectors
{
    for (SocialConnector *connector in connectors) {
        [self deactivateConnector:connector];
    }
}

- (SObject *)processOperation:(SEL)selector
                       params:(SObject *)params
                withProcessor:(CompositeConnectorProcessorBlock)processor
                   completion:(CompletionBlock)completion
{
    if (!_activeConnectors.count) {
        return [SObject failed:completion];
    }
    return [self processConnectors:_activeConnectors operation:selector params:params withProcessor:processor completion:completion];
}

- (SObject *)processConnector:(SocialConnector *)connector
                    operation:(SEL)operation
                       object:(SObject *)params
                   completion:(CompletionBlock)completion
{

    return [connector performSelector:operation withObject:params withObject:completion];
}

- (SObject *)processConnectors:(id <NSFastEnumeration>)connectors
                     operation:(SEL)selector
                        params:(SObject *)params
                 withProcessor:(CompositeConnectorProcessorBlock)processor
                    completion:(CompletionBlock)completion
{
    BlockOperationQueue *queue = [[BlockOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;

    SObject *result = [SObject objectCollectionWithHandler:self];
    SObject *operations = [SObject objectWithState:SObjectStateProcessing];

    for (SocialConnector *connector in connectors) {
        AsyncBlockOperation *op =
                [AsyncBlockOperation operationWithBlock:^(AsyncBlockOperation *operation, AsyncBlockOperationCompletionBlock completionBlock) {

                    SObject *result =
                            [self processConnector:connector operation:selector object:params completion:^(SObject *object) {
                                [result addSubObject:object];
                                if (processor) {
                                    processor(connector, object);
                                }
                                completionBlock(nil);
                            }];
                    if (result.isProcessing) {
                        [operations addSubObject:result];
                    }
                }];
        [queue addOperation:op];
    }
    [queue setCompletionHandler:^(NSError *error) {
        completion(result);
    }];

    return [SObject objectWithState:SObjectStateProcessing];
}

- (SObject *)processSocialConnectorProtocol:(SObject *)params completion:(CompletionBlock)completion operation:(SEL)selector
{
    __block SObject *componoundResult = [SObject objectCollectionWithHandler:self];

    SObject *result =
            [self processOperation:selector params:params withProcessor:^(SocialConnector *connector, SObject *result) {

                [componoundResult addSubObject:result];

                /*
                if (!result.isFailed) {
                    if (result.subObjects) {
                        [componoundResult addSubObjects:result.subObjects];
                    }
                    else {
                        [componoundResult addSubObject:result];
                    }
                }
                else {

                }
                */

            }           completion:^(SObject *result) {

                [componoundResult complete:completion];
                componoundResult = nil;
            }];
    return result;
}

- (void)selectDefaultConnector
{
    NSArray *array = [self.activeConnectors sortedArrayUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"connectorPriority" ascending:NO],
            [NSSortDescriptor sortDescriptorWithKey:@"connectorCode" ascending:YES]]];

    if (array.count) {
        self.defaultConnector = array[0];
    }
}

- (NSArray *)sortedConnectors:(NSSet *)connectors
{
    return [connectors sortedArrayUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"connectorDisplayPriority" ascending:NO],
            [NSSortDescriptor sortDescriptorWithKey:@"connectorCode" ascending:YES]]];
}

- (NSArray *)sortedActiveConnectors
{
    return [self sortedConnectors:self.activeConnectors];
}

- (NSArray *)sortedAvailableConnectors
{
    return [self sortedConnectors:self.availableConnectors];
}

- (SUserData *)currentUserData
{
    return _defaultConnector.currentUserData;
}

- (void)saveActiveStates
{
    if (self.restorationId) {

        NSMutableArray *availableConnectorsClasses = [NSMutableArray arrayWithCapacity:_availableConnectors.count];
        for (SocialConnector *connector in _availableConnectors) {
            [availableConnectorsClasses addObject:NSStringFromClass(connector.class)];
        }

        NSArray *mod = @[
                [[_activeConnectors valueForKey:@"connectorCode"] allObjects] ? : @[],
                [[_deactivatedConnectors valueForKey:@"connectorCode"] allObjects] ? : @[],
                availableConnectorsClasses,
        ];

        [[NSUserDefaults standardUserDefaults] setObject:mod forKey:[self.restorationId stringByAppendingString:@"v2"]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSSet *)restoreActiveStates:(NSSet *)baseConnectors aviableConnectors:(NSSet *)aviable
{
    if (self.restorationId) {

        if (!aviable) {
            aviable = self.availableConnectors;
        }

        NSArray *mod =
                [[NSUserDefaults standardUserDefaults] arrayForKey:[self.restorationId stringByAppendingString:@"v2"]];

        NSArray *activated = mod[0];
        NSArray *deactivated = mod[1];
        NSSet *activatedConnectors;
        NSSet *deactivatedConnectors;

        if (activated) {
            NSSet *activeCodes = [NSSet setWithArray:activated];
            activatedConnectors = [aviable objectsPassingTest:^BOOL(SocialConnector *obj, BOOL *stop) {
                return [activeCodes containsObject:obj.connectorCode];
            }];
        }
        if (deactivated) {
            NSSet *activeCodes = [NSSet setWithArray:deactivated];
            deactivatedConnectors = [aviable objectsPassingTest:^BOOL(SocialConnector *obj, BOOL *stop) {
                return [activeCodes containsObject:obj.connectorCode];
            }];
        }
        NSSet *connectors;
        self.deactivatedConnectors = deactivatedConnectors;
        if(baseConnectors) {
            connectors = [baseConnectors setByUnioningSet:activatedConnectors];
        }
        else {
            connectors = activatedConnectors;
        }
        return [connectors setByMinusingSet:deactivatedConnectors];
    }
    return baseConnectors;
}

- (void)setActiveConnectors:(NSSet *)activeConnectors
{
    if (![_activeConnectors isEqualToSet:activeConnectors]) {
        _activeConnectors = activeConnectors;
        [self saveActiveStates];
    }
}

- (void)setAvailableConnectors:(NSSet *)availableConnectors
{
    if (![_availableConnectors isEqualToSet:availableConnectors]) {
        _availableConnectors = availableConnectors;
        if (_activeConnectors) {
            self.activeConnectors = [_activeConnectors setByIntersectingSet:_availableConnectors];
        }
        else {
            self.activeConnectors = _availableConnectors;
        }
    }
}

- (void)setSingleSelection:(BOOL)singleSelection {
    _singleSelection = singleSelection;
    if(self.activeConnectors.count > 1) {
        self.activeConnectors = [NSSet setWithObject: [self.sortedActiveConnectors objectAtIndex:0]];
    }
}


- (void)deactivateAllConnectors
{
    [self deactivateConnectors:[self.availableConnectors copy]];
}
@end
