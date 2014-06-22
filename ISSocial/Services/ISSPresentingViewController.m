//
// 



#import "ISSPresentingViewController.h"

@interface ISSPresentingViewController ()

@end

@implementation ISSPresentingViewController
{

}

- (UIViewController *)topMostController
{
    UIViewController *topController = [[[UIApplication sharedApplication] keyWindow] rootViewController];

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    if (topController == self) return nil;

    return topController;
}

- (void)present
{
    if (!self.view.superview) {
        [self presentFromWithController:[self topMostController] superview:[[self topMostController] view]];
    }
}

+ (ISSPresentingViewController *)presentingController
{
    return [ISSPresentingViewController instance];
}

+ (ISSPresentingViewController *)instance
{
    static ISSPresentingViewController *_instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (void)presentFromWithController:(UIViewController *)controller superview:(UIView *)superview
{
    [controller addChildViewController:self];

    CGRect frame = superview.bounds;
    frame.origin.y = 20;
    frame.size.height -= 20;

    self.view.frame = frame;
    [superview addSubview:self.view];
    self.view.alpha = 1;

    [self didMoveToParentViewController:controller];
}


- (void)presentController:(UIViewController *)controller
{
    [self present];

    [self addChildViewController:controller];
    controller.view.frame = self.view.bounds;
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (void)dismissController:(UIViewController *)controller
{
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}
@end