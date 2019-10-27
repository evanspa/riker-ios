//
//  RUpdatePaymentMethodSynchronizeScreen.m
//  riker-ios
//
//  Created by PEVANS on 1/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RUpdatePaymentMethodSynchronizeScreen.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "RCoordinatorDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "RUtils.h"
#import "PELocalDao.h"
#import "PELMUser.h"
#import "RPanelToolkit.h"
#import "RUIUtils.h"
#import "UIColor+RAdditions.h"
#import "AppDelegate.h"
#import "RLogging.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "PEUtils.h"
#import "RChangeLog.h"
#import "RAppNotificationNames.h"
#import "RDoUpdatePaymentMethodScreen.h"
@import Firebase;

@implementation RUpdatePaymentMethodSynchronizeScreen {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Update Payment Method"
                                    screenNameToLog:@"update_payment_method_synchronize"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _panelToolkit = panelToolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Cancel handler

- (void)cancel {
  [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [RPanelToolkit breadcrumbPanelWithTemplateText:@"%@ \u2192 Update Payment Method"
                                                           textToAccent:@"Synchronize Account"
                                                         relativeToView:contentPanel];
  
  UILabel *titleLabel = [PEUIUtils labelWithKey:@"To begin, lets go ahead and synchronize your account."
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor rikerAppBlack]
                            verticalTextPadding:5.0
                                     fitToWidth:contentPanel.frame.size.width - 18.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIView *separator = [PEUIUtils panelWithWidthOf:0.95 relativeToView:contentPanel fixedHeight:2.0];
  [PEUIUtils adjustWidthOfView:separator withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [separator setBackgroundColor:[UIColor cloudsColor]];
  UIButton *synchronizeBtn = [PEUIUtils buttonWithKey:@"Synchronize Account"
                                                 font:[PEUIUtils actionButtonFont]
                                      backgroundColor:[UIColor bootstrapPrimary]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:[PEUIUtils actionButtonVpadding]
                                    horizontalPadding:[PEUIUtils actionButtonHpadding]
                                         cornerRadius:3.0
                                               target:nil
                                               action:nil];
  [synchronizeBtn bk_addEventHandler:^(id sender) {
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    [_panelToolkit invokeChangelogFetchForUser:user
                               userSettingsBlk:^(PELMUser *user) { return [_coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()]; }
                     actionIfChangesDownloaded:^{
                       [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
                     }
                            successButtonTitle:^(PELMUser *user) {
                              return @"Continue to update payment method \u2192";
                            }
                       addlSuccessButtonAction:^{
                         [self.navigationController pushViewController:[[RDoUpdatePaymentMethodScreen alloc] initWithStoreCoordinator:_coordDao uitoolkit:_uitoolkit panelToolkit:_panelToolkit screenToolkit:_screenToolkit] animated:YES];
                       }
                                    controller:self];
  } forControlEvents:UIControlEventTouchUpInside];
  // place views onto panel
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:34.0];
  [PEUIUtils placeView:titleLabel below:headingPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += titleLabel.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:17.0 iphone6PlusWidth:19.0 ipad:25.0];
  [PEUIUtils placeView:separator below:titleLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += separator.frame.size.height + vpadding;
  [PEUIUtils placeView:synchronizeBtn below:separator onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0 + iphoneXSafeInsetsSideVal];
  totalHeight += synchronizeBtn.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
          error:(nullable NSError *)error {
  session.delegate = APP; // re-assign back to app delegate
  if (activationState == WCSessionActivationStateActivated) {
    [RUtils transferAllDataToAppleWatchInBgWithCoordDao:_coordDao session:session];
  }
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  // it's very unlikely this callback would ever get called.  The only way it can
  // get called is if immediately after tapping the 'push' button, they tap
  // to sync local bmls or sets from their Apple Watch.
  [APP session:session didReceiveUserInfo:userInfo];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]];
}

@end
