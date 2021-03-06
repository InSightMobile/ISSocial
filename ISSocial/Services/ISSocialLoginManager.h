//
// Created by yar on 30.12.12.
//



#import <Foundation/Foundation.h>

@class CompositeConnector;
@class SocialConnector;
@class SObject;

@interface ISSocialLoginManager : NSObject
+ (ISSocialLoginManager *)instance;

@property(nonatomic, copy) NSArray *destinationConnectors;
@property(nonatomic, strong) CompositeConnector *sourceConnectors;


- (void)loginWithCompletion:(void (^)())completion;

- (void)cancelLogins;

@property(nonatomic, strong) CompositeConnector *resultConnector;

@property(nonatomic, copy) void (^loginHandler)(SocialConnector *, NSError *);

- (void)logoutAllWithCompletion:(void (^)())pFunction;

- (void)logoutConnector:(SocialConnector *)connector withCompletion:(void (^)())completion;

- (void)loginWithParams:(SObject *)params connector:(SocialConnector *)connector completion:(void (^)())completion;
@end