//
// Created by yar on 19.12.12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>

@class SObject;
@class SCommentData;
@class VkontakteConnector;
@class SocialConnectorOperation;
@class SocialConnector;
@class SPagingData;

static NSString *const kSObjectDidUpdated = @"SObjectDidUpdated";
typedef enum {

    SObjectStateSuccess = 0,
    SObjectStateFailed,
    SObjectStateUnsupported,
    SObjectStateProcessing,
    SObjectStateProcessingDelayed,
} SObjectState;

typedef void (^SObjectCompletionBlock)(SObject *result);


@protocol SObject <NSCopying, NSCoding, NSObject>
@property(nonatomic) SEL pagingSelector;
@property(nonatomic, readonly) SObjectState state;

@property(strong, nonatomic) NSMutableDictionary *data;
@property(nonatomic, strong) NSMutableArray *subObjects;
@property(strong, nonatomic) SocialConnector *handler;
@property(strong, nonatomic) NSError *error;
@property(strong, nonatomic) SocialConnectorOperation *operation;

@property(weak, nonatomic) NSMutableDictionary *referencingDictionary;
@property(nonatomic) SEL deletionSelector;

- (void)fireUpdateNotification;

@optional

@property(strong, nonatomic) SPagingData *pagingObject;
@property(strong, nonatomic) id pagingData;
@property(nonatomic, strong) NSNumber *isPagable;
@property(nonatomic, strong) NSNumber *noCache;
@property(strong, nonatomic) NSString *objectId;
@property(nonatomic, strong) NSNumber *deleted;

@property(strong, nonatomic) NSString *searchString;
@property(strong, nonatomic) NSNumber *sortGroup;

@property(nonatomic, strong) NSNumber *canDelete;
@property(strong, nonatomic) NSNumber *totalCount;
@property(strong, nonatomic) NSNumber *isTemporary;

@end

@interface SObject : NSObject <SObject>

@property(nonatomic, readonly) NSUInteger count;

@property(strong, nonatomic) NSMutableDictionary *data;
@property(nonatomic, strong) NSMutableArray *subObjects;
@property(strong, nonatomic) SocialConnector *handler;

@property(strong, nonatomic) NSError *error;
@property(strong, nonatomic) SocialConnectorOperation *operation;

@property(nonatomic, readonly) SObjectState state;
@property(nonatomic) SEL pagingSelector;
@property(nonatomic) SEL deletionSelector;

@property(weak, nonatomic) NSMutableDictionary *referencingDictionary;

@property(strong, nonatomic) NSString *objectId;

@property(strong, nonatomic) NSNumber *isTemporary;

- (BOOL)isFailed;

- (BOOL)isSuccessful;

- (BOOL)isProcessing;

+ (SObject *)successful:(SObjectCompletionBlock)completion;

+ (SObject *)failed:(SObjectCompletionBlock)completion;


+ (SObject *)error:(NSError *)error completion:(SObjectCompletionBlock)completion;

+ (SObject *)objectCollectionWithHandler:(id)handler;

+ (id)object;

- (id)initWithHandler:(id)handler;

- (id)initWithHandler:(SocialConnector *)handler state:(SObjectState)state;

+ (id)objectWithHandler:(SocialConnector *)handler state:(SObjectState)state;


+ (id)objectWithHandler:(SocialConnector *)handler;

+ (SObject *)successful;

+ (SObject *)failed;

+ (SObject *)error:(NSError *)error;

- (void)addSubObject:(SObject *)subObject;

+ (id)objectWithState:(SObjectState)state;

- (void)complete:(SObjectCompletionBlock)completion;

- (id)objectForKeyedSubscript:(id)key;

- (void)setObject:(id)object forKeyedSubscript:(id)key;


- (id)objectForKey:(id)key;

- (NSArray *)allKeys;

- (void)addSubObjects:(NSArray *)array;

//- (NSString *)description;

//- (NSString *)debugDescription;

- (void)cancelOperation;

- (id)copyWithHandler:(id)handler;

- (SObject *)loadNextPageWithCompletion:(SObjectCompletionBlock)completion;

- (BOOL)isDeletable;

- (SObject *)deleteObject:(SObjectCompletionBlock)completion;


- (NSMutableArray *)combinedSubobjectsSortedBy:(NSString *)key ascending:(BOOL)ascending;

- (void)combinedLoadNextPageWithCompletion:(void (^)(SObject *))pFunction;

- (void)fireUpdateNotification;

@end