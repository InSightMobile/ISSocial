//
// Created by yar on 30.12.12.
//



#import <Foundation/Foundation.h>

@class CompositeConnector;
@class SocialConnector;

@interface LoginManager : NSObject
+ (LoginManager *)instance;

@property(nonatomic, copy) NSArray *destinationConnectors;
@property(nonatomic, strong) CompositeConnector *sourceConnectors;


- (void)loginWithCompletion:(void (^)())completion;

- (void)cancelLogins;

@property(nonatomic, strong) CompositeConnector *resultConnector;

- (void)logoutAllWithCompletion:(void (^)())pFunction;

- (void)logoutConnector:(SocialConnector *)connector withCompletion:(void (^)())completion;
@end