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

- (void)performBlockInBackground:(void (^)())block completion:(void (^)())completionBlock
{
    [self.class performBlockInBackground:block completion:completionBlock];
}

@end

