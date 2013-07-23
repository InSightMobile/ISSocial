//
//  WebLoginController.m
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//


#import <BlocksKit/NSObject+BlocksKit.h>
#import "WebLoginController.h"
#import "WebLoginManager.h"
#import "AsyncBlockOperation.h"

@interface WebLoginController ()
@property(nonatomic, copy) AsyncBlockOperationCompletionBlock completionBlock;
@property(nonatomic) BOOL dissmissed;
@property(nonatomic, strong) NSError *error;
@end

@implementation WebLoginController
{
    BOOL _dissmissing;
    BOOL _appeared;
    BOOL _disappeared;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _disappeared = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _disappeared = YES;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

+ (WebLoginController *)loginController
{
    return [[WebLoginManager instance] loadLoginController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
}

- (void)presentWithRequest:(NSURLRequest *)request
{
    AsyncBlockOperation *operation =
            [AsyncBlockOperation operationWithBlock:^(AsyncBlockOperation *operation, AsyncBlockOperationCompletionBlock completionBlock) {

                [self present];
                [self view]; // load view first
                [_webView loadRequest:request];
                self.completionBlock = completionBlock;
            }];
    [[WebLoginManager instance] addLoginOperation:operation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    _appeared = NO;
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    _disappeared = YES;
    [super viewDidDisappear:animated];

    [self performBlock:^(id sender){
        self.completionBlock(self.error);
        self.completionBlock = nil;
    } afterDelay:0.1];
}

- (void)viewWillAppear:(BOOL)animated
{
    _disappeared = NO;
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    _disappeared = NO;
    if (_dissmissing) {
        [self performBlock:^(id sender){
            _appeared = YES;
            [self dismiss];
        } afterDelay:0.1];
    }
    else {
        _appeared = YES;
    }
    [super viewDidAppear:animated];
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_delegate respondsToSelector:@selector(webLogin:didFinishPageLoad:)]) {
        [self.delegate webLogin:self didFinishPageLoad:webView.request];
    }
    [self display];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    WebLoginLoadingTypes type;
    if ([_delegate respondsToSelector:@selector(webLogin:loadingTypeForRequest:)]) {
        type = [self.delegate webLogin:self loadingTypeForRequest:request];
    }
    else type = WebLoginLoadVisible;

    if (type == WebLoginDoNotLoad) return NO;

    if (WebLoginLoadVisible) {

    }
    else {


    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{

}

- (void)webViewDidStartLoad:(UIWebView *)webView
{

}

- (void)dismiss
{
    if (self.view.superview) {
        [self.view removeFromSuperview];
        self.completionBlock(self.error);
        self.completionBlock = nil;
    }
}

- (void)display
{
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 1;
    }];
}

- (void)presentWithSuperview:(UIView *)superview
{
    CGRect frame = superview.bounds;
    frame.origin.y = 20;
    frame.size.height -= 20;

    self.view.frame = frame;
    [superview addSubview:self.view];
    self.view.alpha = 0;
}

- (void)present
{
    if (!self.view.superview) {
        [self presentWithSuperview:[[self topMostController] view]];
    }
}

- (IBAction)cancel:(id)sender
{
    [self dismiss];
    if ([_delegate respondsToSelector:@selector(webLoginDidCanceled:)]) {
        [self.delegate webLoginDidCanceled:self];
    }
}
@end
