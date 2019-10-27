//
//  RAccountStatusDetailController.m
//  riker-ios
//
//  Created by PEVANS on 12/31/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RAccountStatusDetailController.h"
#import "RAppNotificationNames.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/DateTools.h>
#import "REnrollSynchronizeScreen.h"
#import "UIColor+RAdditions.h"
#import "PELMUser.h"
#import "PEUIUtils.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RPanelToolkit.h"
#import "PEUtils.h"
#import "RCoordinatorDao.h"
#import "PEUserCoordinatorDao.h"
#import "PELocalDao.h"
@import Firebase;
#import "RLogging.h"

@implementation RAccountStatusDetailController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  void(^_doneAction)(PELMUser *);
  NSMutableDictionary *_toggles;
  NSMutableArray *_allViews;
  MBProgressHUD *_hud;
  SKProduct *_subscriptionProduct;
  BOOL _presentEnrollStartScreenOnProductLoad;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                    doneAction:(void(^)(PELMUser *))doneAction {
  self = [super initWithRequireRepaintNotifications:@[RAppReauthReqdNotification,
                                                      RAppReauthNotification,
                                                      RChangelogDownloadedNotification,
                                                      RSubscriptionCancelledNotification]
                                         screenTitle:@"Riker Account Status"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _doneAction = doneAction;
    _toggles = [NSMutableDictionary dictionary];
    _allViews = [NSMutableArray array];
    _presentEnrollStartScreenOnProductLoad = NO;
  }
  return self;
}

#pragma mark - SKProductsRequestDelegate

- (void)handleInAppStoreProductFetchError {
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"In-App Store unavailable."
                     alertDescription:AS(@"Apple's In-App Store is currently unavailable.  Please try again later.")
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay"
                         buttonAction:^{
                           [self dismissViewControllerAnimated:YES completion:nil];
                         }
                       relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
  [_hud hideAnimated:NO]; // 'NO' here is on purpose
  if (response.products && response.products.count > 0) {
    _subscriptionProduct = response.products[0];
    if (_presentEnrollStartScreenOnProductLoad) {
      [self presentEnrollStartScreen];
      _presentEnrollStartScreenOnProductLoad = NO; // reset
    } else {
      [self setNeedsRepaint:YES];
      [self viewDidAppear:NO];
    }
  } else {
    [self handleInAppStoreProductFetchError];
  }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
  DDLogDebug(@"StoreKit request failed with error: %@", error);
  [_hud hideAnimated:YES];
  [self handleInAppStoreProductFetchError];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];  
  // we only need to fetch from the App Store the price information for a subset
  // of application states:
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodExpired]) {
    [self fetchEnrollPriceInfo]; // closed, expired trial status
  } else if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodAlmostExpired]) {
    [self fetchEnrollPriceInfo]; // almost expired trial status
  } else if ([user hasPaidAccount] && [user isPaymentPastDue] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    // payment past due status
  } else if ([user hasPaidAccount] &&
             ![user hasLapsedPaidAccount] &&
             ![user hasCancelledPaidAccount] &&
             [PEUtils isNotNil:[user validateAppStoreReceiptAt]]) {
    [self fetchEnrollPriceInfo]; // good standing and is iap subscription status (we need to fetch price to display in subscription-info expanding panel)
  } else if ([user hasPaidAccount] &&
             ![user hasLapsedPaidAccount] &&
             ![user hasCancelledPaidAccount]) {
    // good standing and has stripe (or Android Pay) subscription
  } else if ([user hasLapsedPaidAccount]) {
    [self fetchEnrollPriceInfo]; // closed, lapsed status
  } else if ([user hasCancelledPaidAccount]) {
    [self fetchEnrollPriceInfo]; // closed, cancelled status
  } else {
    [self fetchEnrollPriceInfo]; // active trial, or, good standing but non-iap purchase status
  }
}

- (void)fetchEnrollPriceInfo {
  _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  _hud.tag = RHUD_TAG;
  _hud.delegate = self;
  DDLogDebug(@"about to fetch price info of identifier: [%@]", [APP iapRikerSubscriptionProductIdentifier]);
  SKProductsRequest *productsRequest =
  [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[[APP iapRikerSubscriptionProductIdentifier]]]];
  productsRequest.delegate = self;
  [productsRequest start];
}

- (void)viewDidAppear:(BOOL)animated {
  if ([self needsRepaint]) {
    [_toggles removeAllObjects];
  }
  [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  _doneAction([_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()]);
}

#pragma mark - Helpers

- (NSArray *)paymentPastDueContentPanelWithHeadingText:(NSString *)headingText
                                  mainLabelMessageText:(NSString *)mainLabelMessageText
                                   includeUpdateButton:(BOOL)includeUpdateButton
                             includeCancellationButton:(BOOL)includeCancellationButton {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [PEUIUtils thinHeadingPanelWithKey:headingText
                                            backgroundColor:[UIColor failedPaymentHeadingBgColor]
                                                  textColor:[UIColor failedPaymentHeadingTextColor]
                                             relativeToView:contentPanel];
  UIFont *headingLabelFont = [PEUIUtils objIfiPhone5Width:[UIFont preferredFontForTextStyle:UIFontTextStyleCallout]
                                             iphone6Width:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                         iphone6PlusWidth:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                                     ipad:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]];
  UILabel *headingLabel = [PEUIUtils labelWithKey:mainLabelMessageText
                                             font:headingLabelFont
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:15.0
                                       fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSArray *myPaymentInfoViews = [_panelToolkit myPaymentInfoExpandingInfoPanelForUser:user
                                                                  includeUpdateButton:includeUpdateButton
                                                            includeCancellationButton:includeCancellationButton
                                                                              toggles:_toggles
                                                                         contentIndex:1
                                                        baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                                                                           belowViews:@[]
                                                                           controller:self
                                                                       relativeToView:contentPanel
                                                                  subscriptionProduct:nil];
  UIView *myPaymentInfoContentBtn = myPaymentInfoViews[0];
  UIView *myPaymentInfoContentDescPanel = myPaymentInfoViews[1];
  NSArray *whyPaymentFailedViews = [RPanelToolkit whyPaymentFailedExpandingInfoPanelWithToggles:_toggles
                                                                                   contentIndex:0
                                                                  baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                                                                                     belowViews:myPaymentInfoViews
                                                                                 relativeToView:contentPanel];
  UIView *whyPaymentFailedContentBtn = whyPaymentFailedViews[0];
  UIView *whyPaymentFailedContentDescPanel = whyPaymentFailedViews[1];
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:headingLabel
                 below:headingPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:[PEUIUtils valueIfiPhone5Width:8.0
                                         iphone6Width:8.0
                                     iphone6PlusWidth:12.0
                                                 ipad:12.0]];
  totalHeight += headingLabel.frame.size.height + 10.0;
  [PEUIUtils placeView:whyPaymentFailedContentBtn
                 below:headingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:0.0];
  totalHeight += whyPaymentFailedContentBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:whyPaymentFailedContentDescPanel
                 below:whyPaymentFailedContentBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils placeView:myPaymentInfoContentBtn
                 below:whyPaymentFailedContentDescPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:0.0];
  totalHeight += myPaymentInfoContentBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:myPaymentInfoContentDescPanel
                 below:myPaymentInfoContentBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO), @(YES)];
}

- (void)presentEnrollStartScreen {
  REnrollSynchronizeScreen *enrollStartScreen =
  [[REnrollSynchronizeScreen alloc] initWithStoreCoordinator:_coordDao
                                         subscriptionProduct:_subscriptionProduct
                                                   uitoolkit:_uitoolkit
                                                panelToolkit:_panelToolkit
                                               screenToolkit:_screenToolkit];
  [self presentViewController:[PEUIUtils navigationControllerWithController:enrollStartScreen
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (NSArray *)continuingWithRikerOptionsContentPanelWithHeadingText:(NSString *)headingText
                                                  mainLabelMessage:(NSAttributedString *)mainLabelMessage
                                                        attributes:(NSDictionary *)attributes
                                                          reenroll:(BOOL)reenroll
                                            headingBackgroundColor:(UIColor *)headingBackgroundColor
                                                  headingTextColor:(UIColor *)headingTextColor {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [PEUIUtils thinHeadingPanelWithKey:headingText
                                            backgroundColor:headingBackgroundColor
                                                  textColor:headingTextColor
                                             relativeToView:contentPanel];
  UIFontTextStyle headingLabelFontTextStyle = [PEUIUtils objIfiPhone5Width:UIFontTextStyleCallout
                                                              iphone6Width:UIFontTextStyleTitle3
                                                          iphone6PlusWidth:UIFontTextStyleTitle3
                                                                      ipad:UIFontTextStyleTitle3];
  UIFont *boldHeadingFont = [PEUIUtils boldFontForTextStyle:headingLabelFontTextStyle];
  UILabel *headingLabel = [PEUIUtils labelWithAttributeText:mainLabelMessage
                                                       font:[UIFont preferredFontForTextStyle:headingLabelFontTextStyle]
                                   fontForHeightCalculation:boldHeadingFont
                                       additionalAttributes:attributes
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlack]
                                        verticalTextPadding:15.0
                                                 fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIButton *learnMoreBtn = [PEUIUtils buttonWithKey:@"Learn more about the\nbenefits of a Riker account"
                                               font:[RPanelToolkit contentInfoButtonFont]
                                    backgroundColor:[UIColor whiteColor]
                                          textColor:[UIColor rikerAppBlack]
                       disabledStateBackgroundColor:nil
                             disabledStateTextColor:nil
                                    verticalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:30.0]
                                  horizontalPadding:10.0
                                       cornerRadius:0.0
                                             target:nil
                                             action:nil];
  [PEUIUtils styleViewForIpad:learnMoreBtn];
  [PEUIUtils setFrameWidthOfView:learnMoreBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:learnMoreBtn];
  NSString *infoIconName = [PEUIUtils objIfiPhone5Width:@"info-icon" iphone6Width:@"info-icon" iphone6PlusWidth:@"info-icon" ipad:@"info"];
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:infoIconName]]
            inMiddleOf:learnMoreBtn
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [learnMoreBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newRikerAccountBenefitsScreenMaker]()
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  
  UIButton *enrollBtn = [PEUIUtils buttonWithKey:reenroll ? @"Re-enroll Now" : @"Enroll Now"
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
  [enrollBtn bk_addEventHandler:^(id sender) {
    if ([PEUtils isNotNil:_subscriptionProduct]) {
      [self presentEnrollStartScreen];
    } else {
      _presentEnrollStartScreenOnProductLoad = YES;
      _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _hud.tag = RHUD_TAG;
      _hud.delegate = self;
      SKProductsRequest *productsRequest =
      [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[[APP iapRikerSubscriptionProductIdentifier]]]];
      productsRequest.delegate = self;
      [productsRequest start];
    }
  } forControlEvents:UIControlEventTouchUpInside];
  NSArray *useRikerAppExclusivelyViews =
  [RPanelToolkit useRikerAppExclusivelyExpandingInfoPanelWithTitle:@"2.  Just use the app"
                                                           toggles:_toggles
                                                      contentIndex:1
                                     baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                                                        belowViews:@[enrollBtn, learnMoreBtn]
                                                    relativeToView:contentPanel];
  UIView *useRikerAppExclusivelyContentBtn = useRikerAppExclusivelyViews[0];
  UIView *useRikerAppExclusivelyContentDescPanel = useRikerAppExclusivelyViews[1];
  NSMutableArray *belowViews = [NSMutableArray arrayWithArray:useRikerAppExclusivelyViews];
  [belowViews addObject:learnMoreBtn];
  [belowViews addObject:enrollBtn];
  NSArray *enrollInSubscriptionViews =
  [RPanelToolkit enrollInSubscriptionExpandingInfoPanelWithTitle:[NSString stringWithFormat:@"1.  %@ in a subscription", reenroll ? @"Re-enroll" : @"Enroll"]
                                                        reenroll:reenroll
                                             subscriptionProduct:_subscriptionProduct
                                                         toggles:_toggles
                                                    contentIndex:0
                                   baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                                                      belowViews:belowViews
                                                  relativeToView:contentPanel];
  UIView *enrollInSubscriptionContentBtn = enrollInSubscriptionViews[0];
  UIView *enrollInSubscriptionContentDescPanel = enrollInSubscriptionViews[1];
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:14.0 ipad:20.0];
  [PEUIUtils placeView:headingLabel
                 below:headingPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:[PEUIUtils valueIfiPhone5Width:8.0
                                         iphone6Width:8.0
                                     iphone6PlusWidth:12.0
                                                 ipad:12.0] + iphoneXSafeInsetsSideVal];
  totalHeight += headingLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:enrollInSubscriptionContentBtn
                 below:headingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += enrollInSubscriptionContentBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:enrollInSubscriptionContentDescPanel
                 below:enrollInSubscriptionContentBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils placeView:useRikerAppExclusivelyContentBtn
                 below:enrollInSubscriptionContentDescPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += useRikerAppExclusivelyContentBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:useRikerAppExclusivelyContentDescPanel
                 below:useRikerAppExclusivelyContentBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:17.0 iphone6PlusWidth:19.0 ipad:30.0];
  [PEUIUtils placeView:enrollBtn
                 below:useRikerAppExclusivelyContentDescPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += enrollBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:learnMoreBtn
                 below:enrollBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += learnMoreBtn.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO), @(YES)];
}

- (CGFloat)headingLabelVpadding {
  return [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:14.0 iphone6PlusWidth:18.0 ipad:22.0];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodExpired]) {
    return [self closedExpiredTrialContentPanel];
  } else if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodAlmostExpired]) {
    return [self almostExpiredTrialContentPanel];
  } else if ([user hasPaidAccount] && [user isPaymentPastDue] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    return [self paymentPastDueContentPanel];
  } else if ([user hasPaidAccount] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    return [self goodStandingContentPanel];
  } else if ([user hasLapsedPaidAccount]) {
    return [self closedPaymentPastDueContentPanel];
  } else if ([user hasCancelledPaidAccount]) {
    return [self closedCancelledContentPanel];
  } else {
    return [self activeTrialContentPanel];
  }
}

#pragma mark - Content Panels

- (NSArray *)almostExpiredTrialContentPanel {
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSInteger daysUntil = [user.trialEndsAt daysFrom:[NSDate date]];
  NSMutableAttributedString *attrHeading = [[NSMutableAttributedString alloc] init];
  [attrHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your trial account expires in %@.  "
                                                               textToAccent:[NSString stringWithFormat:@"%@ day%@", @(daysUntil), daysUntil > 1 ? @"s" : @""]
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils objIfiPhone5Width:UIFontTextStyleCallout
                                                                                                                            iphone6Width:UIFontTextStyleTitle3
                                                                                                                        iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                                    ipad:UIFontTextStyleTitle3]]]];
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  [attrHeading appendAttributedString:ASA(@"\nAfter the trial period, you'll have 2 choices for continuing with Riker:", attrs)];
  return [self continuingWithRikerOptionsContentPanelWithHeadingText:@"Trial Almost Expired"
                                                    mainLabelMessage:attrHeading
                                                          attributes:attrs
                                                            reenroll:NO
                                              headingBackgroundColor:[UIColor trialAlmostExpiredHeadingBgColor]
                                                    headingTextColor:[UIColor trialAlmostExpiredHeadingTextColor]];
}

- (NSArray *)paymentPastDueContentPanel {
  return [self paymentPastDueContentPanelWithHeadingText:@"Payment Past Due"
                                    mainLabelMessageText:@"Your last automatic subscription payment-attempt failed.\n\nPlease update your payment information as soon as possible to prevent cancellation of your account."
                                     includeUpdateButton:YES
                               includeCancellationButton:YES];
}

- (NSArray *)goodStandingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [PEUIUtils thinHeadingPanelWithKey:@"Riker Subscription"
                                            backgroundColor:[UIColor goodStandingHeadingBgColor]
                                                  textColor:[UIColor goodStandingHeadingTextColor]
                                             relativeToView:contentPanel];
  UIFont *headingLabelFont = [PEUIUtils objIfiPhone5Width:[UIFont preferredFontForTextStyle:UIFontTextStyleCallout]
                                             iphone6Width:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                         iphone6PlusWidth:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                                     ipad:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]];
  UILabel *headingLabel = [PEUIUtils labelWithKey:@"Your Riker account is in good standing."
                                             font:headingLabelFont
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:15.0
                                       fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSArray *myPaymentInfoViews = [_panelToolkit myPaymentInfoExpandingInfoPanelForUser:user
                                                                  includeUpdateButton:YES
                                                            includeCancellationButton:YES
                                                                              toggles:_toggles
                                                                         contentIndex:1
                                                        baseControllerDisplayPanelBlk:^UIView * { return [self displayPanel]; }
                                                                           belowViews:@[]
                                                                           controller:self
                                                                       relativeToView:contentPanel
                                                                  subscriptionProduct:_subscriptionProduct];
  UIView *myPaymentInfoContentBtn = myPaymentInfoViews[0];
  UIView *myPaymentInfoContentDescPanel = myPaymentInfoViews[1];
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = [self headingLabelVpadding];
  [PEUIUtils placeView:headingLabel
                 below:headingPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:[PEUIUtils valueIfiPhone5Width:8.0
                                         iphone6Width:8.0
                                     iphone6PlusWidth:12.0
                                                 ipad:12.0] + iphoneXSafeInsetsSideVal];
  totalHeight += headingLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:myPaymentInfoContentBtn
                 below:headingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += myPaymentInfoContentBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:myPaymentInfoContentDescPanel
                 below:myPaymentInfoContentBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO), @(YES)];
}

- (NSArray *)closedExpiredTrialContentPanel {
  NSMutableAttributedString *attrHeading = [[NSMutableAttributedString alloc] init];
  [attrHeading appendAttributedString:AS(@"Your 90-day trial has expired.")];
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  [attrHeading appendAttributedString:ASA(@"\nYou have 2 choices for continuing with Riker:", attrs)];
  return [self continuingWithRikerOptionsContentPanelWithHeadingText:@"Trial Expired"
                                                    mainLabelMessage:attrHeading
                                                          attributes:attrs
                                                            reenroll:NO
                                              headingBackgroundColor:[UIColor cancelledAccountHeadingBgColor]
                                                    headingTextColor:[UIColor cancelledAccountHeadingTextColor]];
}

- (NSArray *)closedPaymentPastDueContentPanel {
  return [self paymentPastDueContentPanelWithHeadingText:@"Payment Past Due - Account Closed"
                                    mainLabelMessageText:@"Your last and final automatic subscription-payment attempt failed.  Several attempts were made.\n\nPlease update your payment information to re-activate your account."
                                     includeUpdateButton:YES
                               includeCancellationButton:NO];
}

- (NSArray *)closedCancelledContentPanel {
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSMutableAttributedString *attrHeading = [[NSMutableAttributedString alloc] init];
  if ([PEUtils isNotNil:user.validateAppStoreReceiptAt]) {
    [attrHeading appendAttributedString:AS(@"Your account is currently closed.  It was cancelled from your iTunes account.")];
  } else {
    [attrHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your account is currently closed. You cancelled it on: %@."
                                                                 textToAccent:[PEUtils stringFromDate:user.paidEnrollmentCancelledAt withPattern:DATE_PATTERN]
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils objIfiPhone5Width:UIFontTextStyleCallout
                                                                                                                              iphone6Width:UIFontTextStyleTitle3
                                                                                                                          iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                                      ipad:UIFontTextStyleTitle3]]]];
  }
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  [attrHeading appendAttributedString:ASA(@"\nYou have 2 choices for continuing with Riker:", attrs)];
  return [self continuingWithRikerOptionsContentPanelWithHeadingText:@"Account Closed"
                                                    mainLabelMessage:attrHeading
                                                          attributes:attrs
                                                            reenroll:YES
                                              headingBackgroundColor:[UIColor cancelledAccountHeadingBgColor]
                                                    headingTextColor:[UIColor cancelledAccountHeadingTextColor]];
}

- (NSArray *)activeTrialContentPanel {
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSInteger daysUntil = [user.trialEndsAt daysFrom:[NSDate date]];
  if (daysUntil > 90) {
    daysUntil = 90;
  }
  NSMutableAttributedString *attrHeading = [[NSMutableAttributedString alloc] init];
  [attrHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your 90-day trial account expires in %@.  "
                                                               textToAccent:[NSString stringWithFormat:@"%@ day%@", @(daysUntil), daysUntil > 1 ? @"s" : @""]
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils objIfiPhone5Width:UIFontTextStyleCallout
                                                                                                                            iphone6Width:UIFontTextStyleTitle3
                                                                                                                        iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                                    ipad:UIFontTextStyleTitle3]]]];
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  [attrHeading appendAttributedString:ASA(@"\nAfter the trial period, you'll have 2 choices for continuing with Riker:", attrs)];
  return [self continuingWithRikerOptionsContentPanelWithHeadingText:@"Trial Account"
                                                    mainLabelMessage:attrHeading
                                                          attributes:attrs
                                                            reenroll:NO
                                              headingBackgroundColor:[UIColor bootstrapPrimary]
                                                    headingTextColor:[UIColor whiteColor]];
}

@end
