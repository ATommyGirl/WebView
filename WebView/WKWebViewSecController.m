//
//  WKWebViewSecController.m
//  WebView
//
//  Created by xiaotian on 2021/8/4.
//

#import "WKWebViewSecController.h"
#import <WebKit/WebKit.h>

#define YYWK_BRIDGE_NAME @"YYWK"

@interface WKWebViewSecController () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, WKHTTPCookieStoreObserver>

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation WKWebViewSecController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"WKWebView-1";
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:YYWK_BRIDGE_NAME];
    
    WKWebViewConfiguration *configuration = ({
        configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = userContentController;
        //configuration.processPool = [[YYWKHost sharedHost] sharedProcessPool];
        configuration.processPool = [[WKProcessPool alloc] init];
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
        [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
        if (@available(iOS 10.0, *)) {
            [configuration setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
        }
        if (@available(iOS 14.0, *)) {
            //configuration.defaultWebpagePreferences.allowsContentJavaScript = YES;
        }else {
            configuration.preferences.javaScriptEnabled = YES;
        }
        [configuration.websiteDataStore.httpCookieStore addObserver:self];
        // IF use MX-auth, open this line to add headers.
        //[configuration yy_RegisterURLProtocol:[CQWKURLProtocol class]];
        configuration;
    });
    
    WKWebView *webView = ({
        webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        webView.scrollView.bounces = NO;
        webView.UIDelegate = self;
        webView.navigationDelegate = self;
        webView.backgroundColor = [UIColor whiteColor];
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        webView;
    });
    self.webView = webView;
    [self.view addSubview:webView];
    
    NSString *url = @"https://myaccount.google.com/personal-info";
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView reload];
}

- (void)close {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - cookie
- (void)copyNSHTTPCookieStorageToWKHTTPCookieStoreWithCompletionHandler:(void (^)(void))theCompletionHandler; {
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStroe = self.webView.configuration.websiteDataStore.httpCookieStore;
        if (cookies.count == 0) {
            !theCompletionHandler ?: theCompletionHandler();
            return;
        }
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStroe setCookie:cookie completionHandler:^{
                if ([[cookies lastObject] isEqual:cookie]) {
                    !theCompletionHandler ?: theCompletionHandler();
                    return;
                }
            }];
        }
    } else {
        // Fallback on earlier versions
        !theCompletionHandler ?: theCompletionHandler();
    }
}

/*
- (WKWebView *)getCookieWebview {
    WKUserContentController *userContentController = [WKUserContentController new];
    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    webViewConfig.userContentController = userContentController;
    webViewConfig.processPool = [[YYWKHost sharedHost] sharedProcessPool];
    NSArray<NSHTTPCookie *> *oldCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    [oldCookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *setCookie = [NSString stringWithFormat:@"document.cookie='%@=%@';", obj.name, obj.value];
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:setCookie injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:cookieScript];
    }];

    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webViewConfig];
    webview.navigationDelegate = self;
    webview.UIDelegate = self;

    return webview;
}
 */

#pragma mark - WKHTTPCookieStoreObserver
- (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore {
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name caseInsensitiveCompare:YYWK_BRIDGE_NAME] == NSOrderedSame) {
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didStartProvisionalNavigation");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailProvisionalNavigation:%@", error);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailNavigation: %@", error);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"didFinishNavigation");
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"didReceiveServerRedirectForProvisionalNavigation");
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *a = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alert addAction:a];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:defaultText?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];

    [self presentViewController:alert animated:YES completion:NULL];
}


@end
