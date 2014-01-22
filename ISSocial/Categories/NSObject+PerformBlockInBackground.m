//
// 

#import "NSObject+PerformBlockInBackground.h"

@implementation NSObject (PerformBlockInBackground)

+ (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock
{
    dispatch_queue_t queue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        block();
        dispatch_async(queue, ^{
            completionBlock();
        });
    });
}

+ (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)interval
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        block();
    });
}

- (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock
{
    [self.class performBlockInBackground:block completion:completionBlock];
}

- (void)performBlock:(void (^)(id sender))block afterDelay:(NSTimeInterval)interval
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        block(self);
    });
}

@end

