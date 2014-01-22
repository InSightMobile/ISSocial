//
// 



#import <Foundation/Foundation.h>

@interface NSObject (PerformBlockInBackground)

+ (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;

+ (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)interval;

- (void)performBlock:(void (^)(id sender))block afterDelay:(NSTimeInterval)interval;

- (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;
@end