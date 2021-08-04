//
//  UIWebViewSecController.m
//  WebView
//
//  Created by xiaotian on 2021/8/4.
//

#import "UIWebViewSecController.h"

@interface UIWebViewSecController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation UIWebViewSecController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"UIWebView-1";
    
    NSString *url = @"https://myaccount.google.com/personal-info";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

@end
