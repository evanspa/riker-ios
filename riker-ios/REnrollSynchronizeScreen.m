//
//  REnrollSynchronizeScreen.m
//  riker-ios
//
//  Created by PEVANS on 1/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "REnrollSynchronizeScreen.h"
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
#import "RDoEnrollScreen.h"
@import Firebase;

@implementation REnrollSynchronizeScreen {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  MBProgressHUD *_hud;
  SKProduct *_subscriptionProduct;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
           subscriptionProduct:(SKProduct *)subscriptionProduct
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Subscription Enroll"
                                    screenNameToLog:@"subscription_enroll_synchronize"];
  if (self) {
    _coordDao = coordDao;
    _subscriptionProduct = subscriptionProduct;
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
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [RPanelToolkit breadcrumbPanelWithTemplateText:@"%@ \u2192 Payment"
                                                           textToAccent:@"Synchronize Account"
                                                         relativeToView:contentPanel];  
  UILabel *titleLabel = [PEUIUtils labelWithKey:@"To begin, lets go ahead and synchronize your account."
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor rikerAppBlack]
                            verticalTextPadding:5.0
                                     fitToWidth:contentPanel.frame.size.width - 18.0];
  UIView *separator = [PEUIUtils panelWithWidthOf:0.95 relativeToView:contentPanel fixedHeight:2.0];
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
                              if ([PEUtils isNil:[user verifiedAt]] || ([user hasPaidAccount] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount])) {
                                return @"Okay.";
                              } else {
                                return @"Continue to payment step \u2192";
                              }
                            }
                       addlSuccessButtonAction:^{
                         PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
                         if ([user hasPaidAccount] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
                           [PEUIUtils showWarningAlertWithMsgs:nil
                                                         title:@"Already Enrolled"
                                              alertDescription:AS(@"You already have an active Riker subscription.\n\nIt looks like you enrolled from another device.")
                                           descLblHeightAdjust:0.0
                                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                   buttonTitle:@"Okay."
                                                  buttonAction:^{
                                                    [self cancel];
                                                  }
                                                relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                         } else if ([PEUtils isNil:[user verifiedAt]]) {
                           NSAttributedString *desc =
                           [PEUIUtils attributedTextWithTemplate:@"Your email address, %@, has not been verified.\n\nIn order to enroll in a Riker subscription, we need you to verify your email address by clicking the link in your welcome email."
                                                    textToAccent:user.email
                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                           [PEUIUtils showWarningAlertWithMsgs:nil
                                                         title:@"Email address not verified."
                                              alertDescription:desc
                                           descLblHeightAdjust:0.0
                                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                   buttonTitle:@"Okay."
                                                  buttonAction:^{ [self cancel]; }
                                               addlButtonTitle:@"Re-send verification email."
                                              addlButtonAction:^{
                                                [RUtils logEvent:@"resend_veri_email_enroll_sync"];
                                                [_panelToolkit invokeSendVerificationEmailWithController:self
                                                                                becameUnauthButtonAction:nil];
                                              }
                                               addlButtonStyle:JGActionSheetButtonStyleDefault
                                                relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                         } else {
                           [RUtils logEvent:kFIREventCheckoutProgress params:@{kFIRParameterCheckoutStep: @"1" }];
                           [self.navigationController pushViewController:[[RDoEnrollScreen alloc] initWithStoreCoordinator:_coordDao
                                                                                                                 uitoolkit:_uitoolkit
                                                                                                              panelToolkit:_panelToolkit
                                                                                                             screenToolkit:_screenToolkit
                                                                                                       subscriptionProduct:_subscriptionProduct] animated:YES];
                         }
                       }
                                    controller:self];
  } forControlEvents:UIControlEventTouchUpInside];
  // place views onto panel
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:8.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:34.0];
  [PEUIUtils placeView:titleLabel below:headingPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:4.0];
  totalHeight += titleLabel.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:17.0 iphone6PlusWidth:19.0 ipad:25.0];
  [PEUIUtils placeView:separator below:titleLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += separator.frame.size.height + vpadding;
  [PEUIUtils placeView:synchronizeBtn below:separator onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0];
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
  [RUtils logEvent:kFIREventBeginCheckout];
}

@end
