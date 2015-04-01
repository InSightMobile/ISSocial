//
//  WebLoginController.h
//  socials
//
//  Created by Ярослав on 19.12.12.
//  Copyright (c) 2012 Ярослав. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WebLoginController;
@class SocialConnectorOperation;

typedef enum {

    WebLoginDoNotLoad,
    WebLoginLoadHidden,
    WebLoginLoadVisible,
} WebLoginLoadingTypes;

@protocol WebLoginControllerDelegate <NSObject>

- (void)webLogin:(WebLoginController *)webLogin didFinishPageLoad:(NSURLRequest *)request;

- (WebLoginLoadingTypes)webLogin:(WebLoginController *)controller loadingTypeForRequest:(NSURLRequest *)request;

- (void)webLoginDidCanceled:(WebLoginController *)controller;
@end

@interface WebLoginController : UIViewController <UIWebViewDelegate>

@property(weak, nonatomic) IBOutlet UIWebView *webView;

@property(weak, nonatomic) id <WebLoginControllerDelegate> delegate;

@property(nonatomic, strong) SocialConnectorOperation *operation;

+ (WebLoginController *)loginController;

- (void)presentWithRequest:(NSURLRequest *)request;

- (void)dismiss;

- (void)present;

- (IBAction)cancel:(id)sender;


@end
