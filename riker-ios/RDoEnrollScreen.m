//
//  RDoEnrollScreen.m
//  riker-ios
//
//  Created by PEVANS on 1/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RDoEnrollScreen.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/DateTools.h>
#import <StoreKit/StoreKit.h>
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
#import "REnrollSynchronizeScreen.h"
@import Firebase;

@implementation RDoEnrollScreen {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  SKProduct *_subscriptionProduct;
  MBProgressHUD *_hud;
  NSMutableDictionary *_toggles;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
           subscriptionProduct:(SKProduct *)subscriptionProduct {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Subscription Enroll"
                                    screenNameToLog:@"subscription_enroll_payment"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _panelToolkit = panelToolkit;
    _screenToolkit = screenToolkit;
    _subscriptionProduct = subscriptionProduct;
    _toggles = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [RPanelToolkit breadcrumbPanelWithTemplateText:@"Synchronize Account \u2192 %@"
                                                           textToAccent:@"Payment"
                                                         relativeToView:contentPanel];
  UIFont *boldTitleFont = [PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3];
  UILabel *titleLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Click the button below to complete your payment of %@.  This will complete your Riker subscription enrollment."
                                                                                   textToAccent:[RUtils formattedPriceOfProduct:_subscriptionProduct]
                                                                                 accentTextFont:boldTitleFont]
                                                     font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                 fontForHeightCalculation:boldTitleFont
                                          backgroundColor:[UIColor clearColor]
                                                textColor:[UIColor rikerAppBlack]
                                      verticalTextPadding:5.0
                                               fitToWidth:contentPanel.frame.size.width - 18.0];
  UILabel *subTitleLabel = [PEUIUtils labelWithKey:@"You will be able to manage your Riker subscription through your iTunes Subscriptions."
                                              font:[PEUIUtils italicFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                                                               iphone6Width:UIFontTextStyleCaption2
                                                                                                           iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                       ipad:UIFontTextStyleBody]]
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[UIColor rikerAppBlack]
                               verticalTextPadding:5.0
                                        fitToWidth:contentPanel.frame.size.width - 18.0];
  UIView *(^makeSeparator)(CGFloat, CGFloat, UIColor *) = ^(CGFloat widthOf, CGFloat height, UIColor *color) {
    UIView *separator = [PEUIUtils panelWithWidthOf:widthOf relativeToView:contentPanel fixedHeight:height];
    [separator setBackgroundColor:color];
    return separator;
  };
  UIView *sep1 = makeSeparator(0.95, 1.0, [UIColor cloudsColor]);
  UIButton *cancelBtn = [PEUIUtils buttonWithKey:@"Cancel"
                                            font:[PEUIUtils actionCancelButtonFont]
                                 backgroundColor:[UIColor rikerAppBlackSemiClear]
                                       textColor:[UIColor whiteColor]
                    disabledStateBackgroundColor:nil
                          disabledStateTextColor:nil
                                 verticalPadding:[PEUIUtils actionCancelButtonVpadding]
                               horizontalPadding:[PEUIUtils actionCancelButtonHpadding]
                                    cornerRadius:3.0
                                          target:nil
                                          action:nil];
  [cancelBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *makePaymentBtn = [PEUIUtils buttonWithKey:@"Make Payment"
                                                 font:[PEUIUtils actionButtonFont]
                                      backgroundColor:[UIColor turquoiseColor]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:[PEUIUtils actionButtonVpadding]
                                    horizontalPadding:[PEUIUtils actionButtonHpadding]
                                         cornerRadius:3.0
                                               target:nil
                                               action:nil];
  [makePaymentBtn bk_addEventHandler:^(id sender) {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.tag = RHUD_TAG;
    _hud.delegate = self;
    REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:self];
    enableUserInteraction(NO);
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:_subscriptionProduct];
    payment.quantity = 1;
    //payment.applicationUsername = [RUtils hashedValueForAccountName:user.email];
    SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
    [paymentQueue addTransactionObserver:self];
    [paymentQueue addPayment:payment];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *sep2 = makeSeparator(0.95, 1.0, [UIColor cloudsColor]);
  NSMutableAttributedString *iTunesSubscriptionInfo = [[NSMutableAttributedString alloc] init];
  [RUtils appendiTunesSubscriptionInfoToAttrString:iTunesSubscriptionInfo
                                    prependNewline:NO
                               subscriptionProduct:_subscriptionProduct
                                 spacingAttributes:[PEUIUtils paragraphBeforeSpacingAttrs]];
  NSArray *iTunesSubscriptionInfoArray =
  [PEUIUtils expandingInfoPanelWithContentData:@[@"Riker Subscription Info",
                                                 iTunesSubscriptionInfo,
                                                 [NSNull null],
                                                 ^{ [RUtils logExpandingInfoContentViewed:@""]; }]
                               additionalViews:nil
                             contentButtonFont:[RPanelToolkit contentInfoButtonFont]
                      contentButtonLabelStyler:nil
                                     textColor:[UIColor whiteColor]
                               backgroundColor:[UIColor rikerAppBlackSemiClear]
                              chevronImageName:@"white-down-chevron-small-icon"
                                  contentIndex:0
                                       toggles:_toggles
                 baseControllerDisplayPanelBlk:^UIView * { return [self displayPanel]; }
                         testForBelowViewsMove:nil
                                    belowViews:nil
                      indexOfFirstBelowViewBlk:nil
                       extraContentPanelHeight:15.0
                                relativeToView:contentPanel];
  UIButton *iTunesSubscriptionInfoButton = iTunesSubscriptionInfoArray[0];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.500 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [iTunesSubscriptionInfoButton sendActionsForControlEvents:UIControlEventTouchUpInside];
  });
  UIView *iTunesSubscriptionInfoPanel = iTunesSubscriptionInfoArray[1];
  
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
  [PEUIUtils placeView:subTitleLabel below:titleLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  totalHeight += subTitleLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:sep1 below:subTitleLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += sep1.frame.size.height + vpadding;
  [PEUIUtils placeView:cancelBtn below:sep1 onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0];
  totalHeight += cancelBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:makePaymentBtn below:cancelBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0];
  totalHeight += makePaymentBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:sep2 below:makePaymentBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += sep2.frame.size.height + vpadding;
  [PEUIUtils placeView:iTunesSubscriptionInfoButton below:sep2 onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += iTunesSubscriptionInfoButton.frame.size.height + vpadding;
  [PEUIUtils placeView:iTunesSubscriptionInfoPanel below:iTunesSubscriptionInfoButton onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  for (SKPaymentTransaction *transaction in transactions) {
    REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:self];
    switch (transaction.transactionState) {
      case SKPaymentTransactionStatePurchasing:
        [RUtils logEvent:@"iap_txn_status_purchasing"];
        _hud.label.text = @"Processing transaction...";
        NSLog(@"in RDoEnroll, SKPaymentTransactionStatePurchasing");
        break;
      case SKPaymentTransactionStateDeferred:
        [RUtils logEvent:@"iap_txn_status_deferred"];
        _hud.label.text = @"Still processing...";
        enableUserInteraction(YES);
        [queue finishTransaction:transaction];
        NSLog(@"in RDoEnroll, SKPaymentTransactionStateDeferred");
        break;
      case SKPaymentTransactionStateFailed:
        [queue finishTransaction:transaction];
        NSLog(@"in RDoEnroll, SKPaymentTransactionStateFailed, main thread?: %@", [PEUtils yesNoFromBool:[NSThread isMainThread]]);
        NSLog(@"in RDoEnroll, error: %@", transaction.error);
        [self handleFailureWithTransaction:transaction enableInteractionBlk:enableUserInteraction];
        break;
      case SKPaymentTransactionStateRestored:
        // this should never happen, right?
        [queue finishTransaction:transaction];
        NSLog(@"in RDoEnroll, SKPaymentTransactionStateRestored");
        [self handleRestoredWithTransaction:transaction enableInteractionBlk:enableUserInteraction];
        break;
      case SKPaymentTransactionStatePurchased:
        NSLog(@"in RDoEnroll, SKPaymentTransactionStatePurchased, main thread?: %@", [PEUtils yesNoFromBool:[NSThread isMainThread]]);
        [self handlePurchaseWithTransaction:transaction enableInteractionBlk:enableUserInteraction];
        break;
    }
  }
}

#pragma mark - Handle Purchase

- (void)handleRestoredWithTransaction:(SKPaymentTransaction *)transaction
                 enableInteractionBlk:(REnableUserInteractionBlk)enableUserInteraction {
  [RUtils logEvent:@"iap_txn_status_restored"];
  [_hud hideAnimated:YES];
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"Already Subscribed"
                     alertDescription:[PEUIUtils attributedTextWithTemplate:@"It looks like you may already have an active Riker subscription.\n\nPlease contact us at: %@, and we'll try to fix your Riker account."
                                                               textToAccent:[APP rikerSupportEmail]
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:^{ enableUserInteraction(YES); }
                       relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

- (void)handleFailureWithTransaction:(SKPaymentTransaction *)transaction
                enableInteractionBlk:(REnableUserInteractionBlk)enableUserInteraction {
  [RUtils logEvent:@"iap_txn_status_failed"];
  [_hud hideAnimated:YES];
  NSAttributedString *desc;
  NSArray *msgs = nil;
  if ([PEUtils isNotNil:transaction.error.localizedDescription]) {
    desc = AS(@"There was an error while attempting to complete your subscription enrollment.  The message is:");
    msgs = @[transaction.error.localizedDescription];
  } else {
    desc = AS(@"There was an unknown error while attempting to complete your subscription enrollment.  Please try again later.");
  }
  [PEUIUtils showErrorAlertWithMsgs:msgs
                              title:@"Error"
                   alertDescription:desc
                descLblHeightAdjust:0.0
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay."
                       buttonAction:^{ enableUserInteraction(YES); }
                     relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

- (void)handlePurchaseWithTransaction:(SKPaymentTransaction *)transaction
                 enableInteractionBlk:(REnableUserInteractionBlk)enableUserInteraction {
  _hud.label.text = @"Finalizing...";
  [RUtils logEvent:@"iap_txn_status_purchased"];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];  
  NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
  user.appStoreReceiptDataBase64 = [receiptData base64EncodedStringWithOptions:0];
  DDLogInfo(@"appStoreReceiptDataBase64: %@", user.appStoreReceiptDataBase64);
  void (^commonDone)(void) = ^{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [_hud hideAnimated:YES];
    enableUserInteraction(YES);
    [APP refreshTabs];
  };
  [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncUserImmediate:user
                                                  notFoundOnServerBlk:nil
                                                       addlSuccessBlk:^{
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                           [RUtils logEvent:@"iap_enroll_subscription_success"];
                                                           commonDone();
                                                           [PEUIUtils showSuccessAlertWithTitle:@"Enrollment Complete"
                                                                               alertDescription:AS(@"Your Riker subscription has been created successfully.\n\nBe sure to synchronize your account on other devices you're logged in to.")
                                                                            descLblHeightAdjust:0.0
                                                                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                    buttonTitle:@"Okay."
                                                                                   buttonAction:^{
                                                                                     [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
                                                                                   }
                                                                                 relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                         });
                                                       }
                                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {
                                                 [RUtils logEvent:@"busy_wh_iap_enroll_subscription"];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   commonDone();
                                                   NSAttributedString *desc =
                                                   [PEUIUtils attributedTextWithTemplate:@"The server is currently busy at the moment undergoing maintenance.\n\nPlease contact us at %@ to complete your enrollment."
                                                                            textToAccent:[APP rikerSupportEmail]
                                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                   [PEUIUtils showWaitAlertWithMsgs:nil
                                                                              title:@"Busy with maintenance."
                                                                   alertDescription:desc
                                                                descLblHeightAdjust:0.0
                                                          additionalContentSections:nil
                                                                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                        buttonTitle:@"Okay."
                                                                       buttonAction:^{
                                                                       }
                                                                     relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                 });
                                               }
                                               addlTempRemoteErrorBlk:^{
                                                 [RUtils logEvent:@"tmp_remote_err_wh_iap_enroll_subscription"];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   commonDone();
                                                   NSAttributedString *desc =
                                                   [PEUIUtils attributedTextWithTemplate:@"We're sorry, but an unexpected error occurred.\n\nPlease contact us at %@ to complete your enrollment."
                                                                            textToAccent:[APP rikerSupportEmail]
                                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                   [PEUIUtils showErrorAlertWithMsgs:nil
                                                                               title:@"Error."
                                                                    alertDescription:desc
                                                                 descLblHeightAdjust:0.0
                                                                            topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                         buttonTitle:@"Okay."
                                                                        buttonAction:^{
                                                                        }
                                                                      relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                 });
                                               }
                                                   addlRemoteErrorBlk:^(NSInteger errMask) {
                                                     [RUtils logEvent:@"remote_err_wh_iap_enroll_subscription"
                                                               params:[RUtils eventLogParamsWithErrMask:errMask]];
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       commonDone();
                                                       NSAttributedString *desc =
                                                       [PEUIUtils attributedTextWithTemplate:@"We're sorry, but an unexpected error occurred.\n\nPlease contact us at %@ to complete your enrollment."
                                                                                textToAccent:[APP rikerSupportEmail]
                                                                              accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                       [PEUIUtils showErrorAlertWithMsgs:[RUtils computeSaveUsrErrMsgs:errMask]
                                                                                   title:@"Error."
                                                                        alertDescription:desc
                                                                     descLblHeightAdjust:0.0
                                                                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                             buttonTitle:@"Okay."
                                                                            buttonAction:^{
                                                                            }
                                                                          relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                     });
                                                   }                                                      
                                                  addlAuthRequiredBlk:^{
                                                    [RUtils logEvent:@"auth_reqd_wh_iap_enroll_subscription"];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                      commonDone();
                                                      UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
                                                      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
                                                      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"While attempting to complete your enrollment, the server is asking for you to re-authenticate.\n\nTo re-authenticate, go to:\n\n%@."
                                                                                                            textToAccent:@"Account \u2794 Re-authenticate"
                                                                                                          accentTextFont:boldDescFont]];
                                                      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Please contact us at %@ to complete your enrollment."
                                                                                                            textToAccent:[APP rikerSupportEmail]
                                                                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
                                                      [PEUIUtils showWarningAlertWithMsgs:nil
                                                                                    title:@"Authentication Failure."
                                                                         alertDescription:desc
                                                                      descLblHeightAdjust:0.0
                                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                              buttonTitle:@"Okay."
                                                                             buttonAction:^{
                                                                               [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                                                   object:nil
                                                                                                                                 userInfo:nil];
                                                                             }
                                                                           relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                    });
                                                  }
                                                                error:[RUtils localSaveErrorHandlerMaker]()];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];  
  [APP unlistenToPaymentTransactions];
}

@end
