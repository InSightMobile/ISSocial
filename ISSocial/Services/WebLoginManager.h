//
// 

#import <Foundation/Foundation.h>

@class WebLoginController;
@class AsyncBlockOperation;


@interface WebLoginManager : NSObject
+ (WebLoginManager *)instance;

- (WebLoginController *)loadLoginController;

- (void)addLoginOperation:(AsyncBlockOperation *)operation;
@end