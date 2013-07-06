//
// Created by yar on 30.12.12.
//



#import <Foundation/Foundation.h>

@class CompositeConnector;

@interface LoginManager : NSObject
+ (LoginManager *)instance;

@property(nonatomic, strong) CompositeConnector *destinationConnectors;
@property(nonatomic, strong) CompositeConnector *sourceConnectors;


- (void)loginWithCompletion:(void (^)())completion;



- (void)cancelLogins;

@property(nonatomic, strong) CompositeConnector *resultConnector;

@end