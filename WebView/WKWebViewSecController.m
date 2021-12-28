//
//  WKWebViewSecController.m
//  WebView
//
//  Created by xiaotian on 2021/8/4.
//

#import "WKWebViewSecController.h"
#import <WebKit/WebKit.h>

#define YYWK_BRIDGE_NAME @"YYWK"

@interface WKWebViewSecController () <WKScriptMessageHandler, WKScriptMessageHandlerWithReply, WKUIDelegate, WKNavigationDelegate, WKHTTPCookieStoreObserver>

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation WKWebViewSecController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"WKWebView-1";
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:YYWK_BRIDGE_NAME];
//    [userContentController addScriptMessageHandlerWithReply:self contentWorld:[WKContentWorld pageWorld] name:YYWK_BRIDGE_NAME];
    
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
            configuration.defaultWebpagePreferences.allowsContentJavaScript = YES;
        }else {
            configuration.preferences.javaScriptEnabled = YES;
        }
        [configuration.websiteDataStore.httpCookieStore addObserver:self];
        configuration;
    });
    
    WKWebView *webView = ({
        webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
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
    
//    NSString *url = @"https://tommygirl.cn";
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];

//    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
//    [self.webView loadFileURL:URL allowingReadAccessToURL:URL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView evaluateJavaScript:@"helloWorld('Are you kidding me?')" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%s : %@", __FUNCTION__, result);
    }];
}

- (void)close {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - cookie
- (void)copyNSHTTPCookieStorageToWKHTTPCookieStoreWithCompletionHandler:(void (^)(void))theCompletionHandler; {
    if (@available(iOS 11.0, *)) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
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
        NSLog(@"%s :[%@]", __FUNCTION__, cookies);

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

#pragma mark - WKScriptMessageHandlerWithReply
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message replyHandler:(void (^)(id _Nullable reply, NSString *_Nullable errorMessage))replyHandler {
    if ([message.body isEqual:@"Fulfill me with 42"])
        replyHandler(@42, nil);
    else
        replyHandler(nil, @"Unexpected message received");
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSLog(@"%s",__FUNCTION__);
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) { //校验服务端证书
        SecTrustRef secTrustRef = challenge.protectionSpace.serverTrust;
        if (secTrustRef != NULL) {
            SecTrustResultType result;
            OSErr er = SecTrustEvaluate(secTrustRef, &result);
            if (er != noErr){
                NSLog(@"error");
            }

            switch (result) {
                case kSecTrustResultProceed:
                    NSLog(@"kSecTrustResultProceed");
                    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
                    break;
                case kSecTrustResultUnspecified:
                    NSLog(@"kSecTrustResultUnspecified");
                    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:secTrustRef]);
                    break;
                case kSecTrustResultRecoverableTrustFailure:
                    NSLog(@"kSecTrustResultRecoverableTrustFailure");
                    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:secTrustRef]);
                    break;
                default:
                    break;
            }
        }
    }else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) { //发送客户端证书
        SecIdentityRef identity = NULL;
        SecTrustRef trust = NULL;
        NSString *p12 = [[NSBundle mainBundle] pathForResource:@"client"ofType:@"p12"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if(![fileManager fileExistsAtPath:p12]) {
            NSLog(@"client.p12: Not exist.");
        } else {
            NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
            if ([self extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data]) {
                SecCertificateRef certificate = NULL;
                SecIdentityCopyCertificate(identity, &certificate);
                const void*certs[] = {certificate};
                CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                NSURLSessionAuthChallengeDisposition disposition =NSURLSessionAuthChallengeUseCredential;
                completionHandler(disposition, credential);
            }
        }
    }else {
        NSLog(@"else");
    }
}

- (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    OSStatus securityError = errSecSuccess;
    //client certificate password
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:@"123456"
                                                                 forKey:(__bridge id)kSecImportExportPassphrase];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
    
    if(securityError == 0) {
        CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
        const void*tempIdentity =NULL;
        tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void*tempTrust =NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failed with error code %d",(int)securityError);
        return NO;
    }
    return YES;
}

/*
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSLog(@"%s",__FUNCTION__);
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];

    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) // called 1st
    {
        NSString *certPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"p12"];
        NSString *certPass = @"123456";
        SecIdentityRef myIdentity = [self getClientCertificate:certPath password:certPass]; // definition will appear at the end

        SecCertificateRef certificateRef;
        SecIdentityCopyCertificate(myIdentity, &certificateRef);
        SecCertificateRef certs[1] = { certificateRef };
        CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certs, 1, NULL);

        NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity
                                                                 certificates:(__bridge NSArray *)myCerts
                                                                  persistence:NSURLCredentialPersistencePermanent];

        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else if([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) // called 2nd
    {
        SecTrustRef secTrustRef = challenge.protectionSpace.serverTrust;
        if (secTrustRef != NULL)
        {
            SecTrustResultType result;
            OSErr er = SecTrustEvaluate(secTrustRef, &result);
            if (er != noErr){
                NSLog(@"error");
            }

            switch ( result )
            {
                case kSecTrustResultProceed:
                    NSLog(@"kSecTrustResultProceed");
                    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
                    break;
                case kSecTrustResultUnspecified: // called 2nd
                    NSLog(@"kSecTrustResultUnspecified");
                    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:secTrustRef]);
                    break;
                case kSecTrustResultRecoverableTrustFailure:
                    NSLog(@"kSecTrustResultRecoverableTrustFailure");
                    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:secTrustRef]);
                    break;
                default:
                    break;
            }
        }
    } else {
        NSLog(@"else");
    }
}
*/

- (SecIdentityRef)getClientCertificate:(NSString *)path password:(NSString *)pass
{
    SecCertificateRef identityApp = nil;
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:path];
    CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
    CFStringRef password = (__bridge CFStringRef)pass;
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import(inPKCS12Data, options, &items);
    if (securityError == errSecSuccess) {
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        identityApp = (SecCertificateRef)CFDictionaryGetValue(identityDict, kSecImportItemCertChain);
    } else {
        // ERROR
    }
    return identityApp;
}

- (void)webView:(WKWebView *)webView authenticationChallenge:(NSURLAuthenticationChallenge *)challenge shouldAllowDeprecatedTLS:(void (^)(BOOL))decisionHandler {
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *a = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
        
    }];
    [alert addAction:a];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
        textField.placeholder = defaultText;
    }];
    [alert addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
    }])];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];

    [self presentViewController:alert animated:YES completion:NULL];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKWebView* v = [[WKWebView alloc] initWithFrame:webView.frame configuration:configuration];
    v.UIDelegate = webView.UIDelegate;
    v.navigationDelegate = webView.navigationDelegate;

    UIViewController* vc = [[UIViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    vc.view = v;
    [self.navigationController pushViewController:vc animated:YES];
    
    return v;
}

- (void)webViewDidClose:(WKWebView *)webView {
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"%s",__FUNCTION__);
}

- (void)webView:(WKWebView *)webView contextMenuWillPresentForElement:(WKContextMenuElementInfo *)elementInfo {
    NSLog(@"%s",__FUNCTION__);

}

- (void)webView:(WKWebView *)webView contextMenuForElement:(WKContextMenuElementInfo *)elementInfo willCommitWithAnimator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSLog(@"%s",__FUNCTION__);

}

- (void)webView:(WKWebView *)webView contextMenuConfigurationForElement:(WKContextMenuElementInfo *)elementInfo completionHandler:(void (^)(UIContextMenuConfiguration * _Nullable configuration))completionHandler  API_AVAILABLE(ios(13.0)){
    NSLog(@"%s",__FUNCTION__);

}

- (void)webView:(WKWebView *)webView contextMenuDidEndForElement:(WKContextMenuElementInfo *)elementInfo {
    NSLog(@"%s",__FUNCTION__);

}

- (void)webView:(WKWebView *)webView requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame type:(WKMediaCaptureType)type decisionHandler:(void (^)(WKPermissionDecision))decisionHandler {
    NSLog(@"%s",__FUNCTION__);

}

- (void)webView:(WKWebView *)webView requestDeviceOrientationAndMotionPermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame decisionHandler:(void (^)(WKPermissionDecision))decisionHandler {
    NSLog(@"%s",__FUNCTION__);

}

@end
