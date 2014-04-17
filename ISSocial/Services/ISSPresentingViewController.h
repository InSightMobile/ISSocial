//
// 



#import <Foundation/Foundation.h>


@interface ISSPresentingViewController : UIViewController
+ (ISSPresentingViewController *)presentingController;

- (void)presentController:(UIViewController *)controller;
@end