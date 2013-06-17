//
// 



#import <Foundation/Foundation.h>

@interface NSObject (PerformBlockInBackground)

+ (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;

- (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock;
@end