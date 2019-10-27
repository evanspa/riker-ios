//
//  PEWebViewScreen.m
//  riker-ios
//
//  Created by PEVANS on 9/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "PEWebViewScreen.h"
#import "PEUIUtils.h"
#import "UIColor+RAdditions.h"
#import "AppDelegate.h"
#import "RUtils.h"
@import Firebase;
#import <MBProgressHUD/MBProgressHUD.h>
#import "RUIUtils.h"

@implementation PEWebViewScreen {
  PEUIToolkit *_uitoolkit;
  MBProgressHUD *_hud;
  NSString *_loadingErrorMsg;
  NSString *_urlString;
}

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit
                  title:(NSString *)title
        loadingErrorMsg:(NSString *)loadingErrorMsg
              urlString:(NSString *)urlString {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:title];
  if (self) {
    _uitoolkit = uitoolkit;
    _loadingErrorMsg = loadingErrorMsg;
    _urlString = urlString;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

#pragma mark - Web View Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
  _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _hud.tag = RHUD_TAG;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [_hud hideAnimated:YES];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  [_hud hideAnimated:YES];
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"Oops"
                     alertDescription:AS(_loadingErrorMsg)
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay"
                         buttonAction:^{ [self.navigationController popViewControllerAnimated:YES]; }
                       relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  webView.delegate = self;
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:self.view];
  [PEUIUtils setFrameHeightOfView:webView ofHeight:1.0 relativeTo:contentPanel];
  [PEUIUtils setFrameWidthOfView:webView ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils placeView:webView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
  // start the request
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]];
  [webView loadRequest:requestObj];
  return @[contentPanel, @(YES), @(NO)];
}

@end
