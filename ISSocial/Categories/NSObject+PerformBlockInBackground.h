//
// 



#import <Foundation/Foundation.h>

@interface NSObject (PerformBlockInBackground)

+ (void)iss_performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;

+ (void)iss_performBlock:(void (^)())block afterDelay:(NSTimeInterval)interval;

- (void)iss_performBlock:(void (^)(id sender))block afterDelay:(NSTimeInterval)interval;

- (void)iss_performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;
@end