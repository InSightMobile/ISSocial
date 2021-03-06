//
//  CompositeConnector.h
//  socials
//
//  Created by yar on 23.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import "SocialConnector.h"
#import "ISSocial.h"

typedef enum {

    CompositeConnectorUseActiveConnectors = 0,
    CompositeConnectorUseAviableConnectors = 1,
    CompositeConnectorDefaultActivated = 0,
    CompositeConnectorDefaultDeactivated = 2,

} CompositeConnectorOptions;

static NSString *const AviableConnectorsDidChangedNotification = @"AviableConnectorsChanged";

typedef void (^CompositeConnectorProcessorBlock)(SocialConnector *connector, SObject *result);

@protocol CompositeConnectorDelegate <NSObject>


@end

@interface CompositeConnector : SocialConnector


+ (CompositeConnector *)globalConnectors;

- (id)initWithConnectorSpecifications:(NSArray *)specifications superConnector:(CompositeConnector *)superConnector restorationId:(NSString *)restorationId options:(CompositeConnectorOptions)options;

+ (CompositeConnector *)instance;


+ (NSMutableSet *)connectorsSupportingSpecification:(NSArray *)spec fromSet:(id <NSFastEnumeration, NSCopying>)connectors;

@property(nonatomic, weak) id <CompositeConnectorDelegate> delegate;
@property(nonatomic, strong) SocialConnector *defaultConnector;

@property(nonatomic, readonly) NSSet *availableConnectors;
@property(nonatomic, readonly) NSSet *activeConnectors;


@property(nonatomic, readonly) NSArray *sortedActiveConnectors;
@property(nonatomic, readonly) NSArray *sortedAvailableConnectors;

@property(nonatomic, copy) NSString *restorationId;

@property(nonatomic) BOOL singleSelection;

- (id)initWithConnectorSpecifications:(NSArray *)specifications restorationId:(NSString *)restorationId;

- (id)initWithConnectorSpecifications:(NSArray *)specifications;

- (id)initWithSuperConnector:(CompositeConnector *)superConnector;

- (id)initWithRestorationId:(NSString *)restorationId;

+ (id)connectorWithRestorationId:(NSString *)restorationId;


- (void)setConnectors:(NSArray *)connectors asActive:(BOOL)active;

- (void)addConnector:(SocialConnector *)connector;

- (void)addConnector:(SocialConnector *)connector asActive:(BOOL)active;

- (void)activateConnector:(SocialConnector *)connector;

- (void)deactivateConnector:(SocialConnector *)connector;

- (BOOL)isConnectorActive:(SocialConnector *)connector;

- (void)activateConnectors:(id <NSFastEnumeration>)connectors;

- (void)activateConnectors:(id <NSFastEnumeration>)connectors exclusive:(BOOL)exclusive;

- (void)addAndActivateConnectors:(NSSet *)connectors exclusive:(BOOL)exclusive;

- (void)activateAllConnectors;

- (void)deactivateConnectors:(id <NSFastEnumeration>)connectors;

- (SObject *)processOperation:(SEL)selector params:(SObject *)params withProcessor:(CompositeConnectorProcessorBlock)processor completion:(SObjectCompletionBlock)completion;

- (SObject *)processConnectors:(id <NSFastEnumeration>)connectors operation:(SEL)selector params:(SObject *)params withProcessor:(CompositeConnectorProcessorBlock)processor completion:(SObjectCompletionBlock)completion;

- (void)selectDefaultConnector;

- (void)saveActiveStates;

- (void)deactivateAllConnectors;
@end
