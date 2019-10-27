//
//  RLegalScreen.m
//  riker-ios
//
//  Created by PEVANS on 2/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RLegalScreen.h"
#import "PEUIUtils.h"
#import "RUIUtils.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"
#import "AppDelegate.h"
#import "RUtils.h"
@import Firebase;
#import "PEWebViewScreen.h"

@implementation RLegalScreen {
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
}

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit
          screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Legal"];
  if (self) {
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  UIButton *(^makeButton)(NSString *, NSString *) = ^UIButton * (NSString *title, NSString *url) {
    UIButton *btn = [_uitoolkit systemButtonMaker](title, nil, nil);
    [PEUIUtils setFrameWidthOfView:btn ofWidth:1.0 relativeTo:contentPanel];
    [PEUIUtils addDisclosureIndicatorToButton:btn];
    [btn bk_addEventHandler:^(id sender) {
      PEWebViewScreen *webViewController =
      [[PEWebViewScreen alloc] initWithUitoolkit:_uitoolkit
                                           title:title
                                 loadingErrorMsg:[NSString stringWithFormat:@"Sorry, but there was a problem loading the %@ content.  Please try again later.", title]
                                       urlString:url];
      [self.navigationController pushViewController:webViewController animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    return btn;
  };
  UIButton *tosBtn = makeButton(@"Terms of Service", [APP rikerTermsOfServiceBareNavUrl]);
  UIButton *privacyBtn = makeButton(@"Privacy Policy", [APP rikerPrivacyPolicyBareNavUrl]);
  UIButton *securityBtn = makeButton(@"Security Policy", [APP rikerSecurityPolicyBareNavUrl]);
  // place views
  CGFloat buttonVpadding = [PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:25.0 iphone6PlusWidth:30.0 ipad:40.0];
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:tosBtn
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += tosBtn.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:privacyBtn below:tosBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:buttonVpadding hpadding:0.0];
  totalHeight += privacyBtn.frame.size.height + buttonVpadding;
  [PEUIUtils placeView:securityBtn below:privacyBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:buttonVpadding hpadding:0.0];
  totalHeight += securityBtn.frame.size.height + buttonVpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

@end
