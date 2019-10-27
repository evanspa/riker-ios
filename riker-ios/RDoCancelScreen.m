//
//  RDoCancelScreen.m
//  riker-ios
//
//  Created by PEVANS on 1/15/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RDoCancelScreen.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/DateTools.h>
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
#import "PEProvideCurrentPasswordController.h"
@import Firebase;

@implementation RDoCancelScreen {
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
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Cancel Subscription"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _panelToolkit = panelToolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Helpers

- (void)disableUi {
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
}

- (void)enableUi {
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [RPanelToolkit breadcrumbPanelWithTemplateText:@"Synchronize Account \u2192 %@"
                                                           textToAccent:@"Cancel Subscription"
                                                         relativeToView:contentPanel];
  UILabel *titleLabel = [PEUIUtils labelWithKey:@"We're sorry to be losing you as a customer. So we can make Riker better, please let us know why you're cancelling:"
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor rikerAppBlack]
                            verticalTextPadding:5.0
                                     fitToWidth:contentPanel.frame.size.width - 18.0 - (iphoneXSafeInsetsSideVal * 2)];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  UIView *(^makeSeparator)(CGFloat, CGFloat, UIColor *) = ^(CGFloat widthOf, CGFloat height, UIColor *color) {
    UIView *separator = [PEUIUtils panelWithWidthOf:widthOf relativeToView:contentPanel fixedHeight:height];
    [PEUIUtils adjustWidthOfView:separator withValue:(-2 * iphoneXSafeInsetsSideVal)];
    [separator setBackgroundColor:color];
    return separator;
  };
  //UIView *sep1 = makeSeparator(1.0, 5.0, [UIColor cloudsColor]);
  UITextField *cancelReason = tfMaker(@"your reason for cancelling...");
  [PEUIUtils adjustWidthOfView:cancelReason withValue:(iphoneXSafeInsetsSideVal * -2)];
  [PEUIUtils setFrameHeight:[PEUIUtils heightForUserAccountTextfields] ofView:cancelReason];
  UIView *exportPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
  [PEUIUtils adjustWidthOfView:exportPanel withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [exportPanel setBackgroundColor:[UIColor cloudsColor]];
  CGFloat exportPanelHeight = 0.0;
  UIFontTextStyle smallFontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                 iphone6Width:UIFontTextStyleSubheadline
                                                             iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                         ipad:UIFontTextStyleBody];
  UIFontTextStyle smallerFontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                   iphone6Width:UIFontTextStyleSubheadline
                                                               iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                           ipad:UIFontTextStyleSubheadline];
  UIFontTextStyle smallestFontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                    iphone6Width:UIFontTextStyleCaption2
                                                                iphone6PlusWidth:UIFontTextStyleCaption2
                                                                            ipad:UIFontTextStyleSubheadline];
  NSString *yellowExclamationIconName = [PEUIUtils objIfiPhone5Width:@"yellow-exclamation-icon"
                                                        iphone6Width:@"yellow-exclamation-icon"
                                                    iphone6PlusWidth:@"yellow-exclamation-icon"
                                                                ipad:@"yellow-exclamation-med"];
  UIImageView *exportIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:yellowExclamationIconName]];
  UILabel *exportMsgLabel =
  [PEUIUtils labelWithKey:@"Once cancelled, your account data may be purged from our servers at anytime. It is recommended that you export your data."
                     font:[UIFont preferredFontForTextStyle:smallFontTextStyle]
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor rikerAppBlack]
      verticalTextPadding:3.0
               fitToWidth:exportPanel.frame.size.width - exportIcon.frame.size.width - 30.0];
  [PEUIUtils placeView:exportIcon atTopOf:exportPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:12.0 hpadding:10.0];
  [PEUIUtils placeView:exportMsgLabel toTheRightOf:exportIcon onto:exportPanel withAlignment:PEUIVerticalAlignmentTypeTop hpadding:10.0];
  [PEUIUtils adjustYOfView:exportMsgLabel withValue:-4];
  exportPanelHeight += exportMsgLabel.frame.size.height + 12.0;
  UIButton *exportBtn = [PEUIUtils buttonWithKey:@"Export My Data"
                                            font:[PEUIUtils actionCancelButtonFont]
                                 backgroundColor:[UIColor rikerAppBlackSemiClear]
                                       textColor:[UIColor whiteColor]
                    disabledStateBackgroundColor:nil
                          disabledStateTextColor:nil
                                 verticalPadding:[PEUIUtils actionCancelButtonVpadding]
                               horizontalPadding:[PEUIUtils actionCancelButtonHpadding]
                                    cornerRadius:5.0
                                          target:nil
                                          action:nil];
  [exportBtn bk_addEventHandler:^(id sender) {
    [_panelToolkit invokeExportWithController:self];
  } forControlEvents:UIControlEventTouchUpInside];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:9.0 ipad:13.0];
  [PEUIUtils placeView:exportBtn below:exportMsgLabel onto:exportPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:exportPanel vpadding:vpadding hpadding:10.0];
  exportPanelHeight += exportBtn.frame.size.height + vpadding;
  UILabel *exportReminderMsg =
  [PEUIUtils labelWithKey:@"If you decide later to re-enroll, or if you want to use Riker anonymously from one of the phone or tablet apps, you can import your data files."
                     font:[PEUIUtils italicFontForTextStyle:smallerFontTextStyle]
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor rikerAppBlack]
      verticalTextPadding:3.0
               fitToWidth:exportPanel.frame.size.width - 30.0];
  [PEUIUtils placeView:exportReminderMsg below:exportBtn onto:exportPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0];
  exportPanelHeight += exportReminderMsg.frame.size.height + vpadding + 6.0; // 6.0 for some bottom margin
  [PEUIUtils setFrameHeight:exportPanelHeight ofView:exportPanel];
  
  UIView *refundPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
  [PEUIUtils adjustWidthOfView:refundPanel withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [refundPanel setBackgroundColor:[UIColor cloudsColor]];
  NSMutableAttributedString *label1Str = [[NSMutableAttributedString alloc] init];
  UIFont *boldFont = [PEUIUtils boldFontForTextStyle:smallFontTextStyle];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  NSDate *now = [NSDate date];
  NSInteger daysSinceLastInvoice = [now daysFrom:user.lastInvoiceAt];
  CGFloat lastInvoiceAmountUsd = user.lastInvoiceAmount.integerValue / 100.0;
  [label1Str appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"It has been %@ since your last subscription payment of "
                                                             textToAccent:[NSString stringWithFormat:@"%ld day%@", (long)daysSinceLastInvoice, daysSinceLastInvoice > 1 || daysSinceLastInvoice == 0 ? @"s" : @""]
                                                           accentTextFont:boldFont]];
  [label1Str appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"$%@."
                                                             textToAccent:[NSString stringWithFormat:@"%.02f", lastInvoiceAmountUsd]
                                                           accentTextFont:boldFont]];
  UILabel *(^makeLabel)(NSAttributedString *, UIFont *) = ^(NSAttributedString *attrStr, UIFont *font) {
    return [PEUIUtils labelWithAttributeText:attrStr
                                        font:font
                    fontForHeightCalculation:boldFont
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor rikerAppBlack]
                         verticalTextPadding:3.0
                                  fitToWidth:contentPanel.frame.size.width - 30.0 - (iphoneXSafeInsetsSideVal * 2)];
  };
  UILabel *(^makeNormalLabel)(NSAttributedString *) = ^(NSAttributedString *attrStr) {
    return makeLabel(attrStr, [UIFont preferredFontForTextStyle:smallFontTextStyle]);
  };
  UILabel *(^makeItalicLabel)(NSAttributedString *) = ^(NSAttributedString *attrStr) {
    UIFont *font = [PEUIUtils italicFontForTextStyle:smallestFontTextStyle];
    return [PEUIUtils labelWithAttributeText:attrStr
                                        font:font
                    fontForHeightCalculation:font
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor rikerAppBlack]
                         verticalTextPadding:3.0
                                  fitToWidth:contentPanel.frame.size.width - 30.0 - (iphoneXSafeInsetsSideVal * 2)];
  };
  UILabel *refundLabel1 = makeNormalLabel(label1Str);
  NSMutableAttributedString *label2Str = [[NSMutableAttributedString alloc] init];
  [label2Str appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"As of this moment, you will be refunded %@ days worth of your last payment."
                                                             textToAccent:[NSString stringWithFormat:@"%ld", (long)365 - daysSinceLastInvoice]
                                                           accentTextFont:boldFont]];
  UILabel *refundLabel2 = makeNormalLabel(label2Str);
  NSMutableAttributedString *label3Str = [[NSMutableAttributedString alloc] init];
  CGFloat refundAmountUsd = (user.lastInvoiceAmount.integerValue - ((user.lastInvoiceAmount.integerValue / 365.0) * daysSinceLastInvoice)) / 100.0;
  [label3Str appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Estimated refund amount: $%@."
                                                             textToAccent:[NSString stringWithFormat:@"%.02f", refundAmountUsd]
                                                           accentTextFont:boldFont]];
  UILabel *refundLabel3 = makeNormalLabel(label3Str);
  UIView *sep3 = makeSeparator(0.975, 0.75, [UIColor rikerAppBlackSemiClear]);
  CGFloat userLastInvoiceAmountUsdPerDay = (user.lastInvoiceAmount.integerValue / 365.0) / 100.0;
  UILabel *refundLabel4 = makeItalicLabel([[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Cost per day = %.02f / 365 days in a year = $%.02f.", lastInvoiceAmountUsd, userLastInvoiceAmountUsdPerDay]]);
  UILabel *refundLabel5 = makeItalicLabel([[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Estimated refund amount = %.02f - %.02f * %ld days used = $%.02f.", lastInvoiceAmountUsd, userLastInvoiceAmountUsdPerDay, (long)daysSinceLastInvoice, refundAmountUsd]]);
  UILabel *refundLabel6 = makeItalicLabel([PEUIUtils attributedTextWithTemplate:@"Refunds typically take %@ to process."
                                                                   textToAccent:@"5-10 business days"
                                                                 accentTextFont:[PEUIUtils italicFontForTextStyle:smallestFontTextStyle]]);
  
  // place views on refund panel
  vpadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:9.0 ipad:13.0];
  [PEUIUtils placeView:refundLabel1 atTopOf:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:10.0];
  CGFloat refundPanelHeight = refundLabel1.frame.size.height + vpadding;
  [PEUIUtils placeView:refundLabel2 below:refundLabel1 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:10.0];
  refundPanelHeight += refundLabel2.frame.size.height + vpadding;
  [PEUIUtils placeView:refundLabel3 below:refundLabel2 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:10.0];
  refundPanelHeight += refundLabel3.frame.size.height + vpadding;
  [PEUIUtils placeView:sep3 below:refundLabel3 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:0.0];
  refundPanelHeight += sep3.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:9.0 ipad:13.0];
  [PEUIUtils placeView:refundLabel4 below:sep3 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:10.0];
  refundPanelHeight += refundLabel4.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:1.5 iphone6Width:2.0 iphone6PlusWidth:4.0 ipad:6.0];
  [PEUIUtils placeView:refundLabel5 below:refundLabel4 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:10.0];
  refundPanelHeight += refundLabel5.frame.size.height + vpadding;
  [PEUIUtils placeView:refundLabel6 below:refundLabel5 onto:refundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:refundPanel vpadding:vpadding hpadding:10.0];
  refundPanelHeight += refundLabel6.frame.size.height + vpadding;
  refundPanelHeight += 10.0; // some bottom padding
  [PEUIUtils setFrameHeight:refundPanelHeight ofView:refundPanel];
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
  UIButton *cancelSubscriptionBtn = [PEUIUtils buttonWithKey:@"Cancel\nSubscription"
                                                        font:[PEUIUtils actionButtonFont]
                                             backgroundColor:[UIColor alizarinColor]
                                                   textColor:[UIColor whiteColor]
                                disabledStateBackgroundColor:nil
                                      disabledStateTextColor:nil
                                             verticalPadding:[PEUIUtils actionButtonVpadding]
                                           horizontalPadding:[PEUIUtils actionButtonHpadding]
                                                cornerRadius:3.0
                                                      target:nil
                                                      action:nil];
  cancelSubscriptionBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
  [cancelSubscriptionBtn bk_addEventHandler:^(id sender) {
    UIViewController *promptCurrentPasswordController =
    [[PEProvideCurrentPasswordController alloc] initWithActionOnDone:^(NSString *providedPassword) {
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.tag = RHUD_TAG;
      [self disableUi];
      HUD.delegate = self;
      HUD.label.text = @"Cancelling subscription...";
      user.currentPassword = providedPassword;
      user.cancelSubscription = [NSNumber numberWithBool:YES];
      user.paidEnrollmentCancelledReason = cancelReason.text;      
      void (^commonDone)(void) = ^{
        [HUD hideAnimated:YES];
        [self enableUi];
        [APP refreshTabs];
      };
      [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncUserImmediate:user
                                                      notFoundOnServerBlk:nil
                                                           addlSuccessBlk:^{
                                                             [RUtils logEvent:@"cancel_subscription_success"];
                                                             [RUtils logEvent:kFIREventPurchaseRefund];
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                               commonDone();
                                                               [PEUIUtils showSuccessAlertWithTitle:@"Subscription Cancelled"
                                                                                   alertDescription:AS(@"Your Riker subscription has been cancelled.")
                                                                                descLblHeightAdjust:0.0
                                                                                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                        buttonTitle:@"Okay."
                                                                                       buttonAction:^{
                                                                                         [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
                                                                                         [[NSNotificationCenter defaultCenter] postNotificationName:RSubscriptionCancelledNotification
                                                                                                                                             object:nil
                                                                                                                                           userInfo:nil];
                                                                                       }
                                                                                     relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                             });
                                                           }
                                                   addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {
                                                     [RUtils logEvent:@"busy_wh_canc_subscription"];
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       commonDone();
                                                       [PEUIUtils showWaitAlertWithMsgs:nil
                                                                                  title:@"Busy with maintenance."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:@"\
                                                                                         The server is currently busy at the moment undergoing maintenance.\n\nYou can try cancelling your subscription later."]
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
                                                     [RUtils logEvent:@"tmp_remote_err_wh_canc_subscription"];
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       commonDone();
                                                       [PEUIUtils showErrorAlertWithMsgs:nil
                                                                                   title:@"Error."
                                                                        alertDescription:AS(@"We're sorry, but an unexpected error has occurred.  Please try this again later.")
                                                                     descLblHeightAdjust:0.0
                                                                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                             buttonTitle:@"Okay."
                                                                            buttonAction:^{
                                                                            }
                                                                          relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                     });
                                                   }
                                                       addlRemoteErrorBlk:^(NSInteger errMask) {
                                                         [RUtils logEvent:@"remote_err_wh_canc_subscription"
                                                                   params:[RUtils eventLogParamsWithErrMask:errMask]];
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                           commonDone();
                                                           [PEUIUtils showErrorAlertWithMsgs:[RUtils computeSaveUsrErrMsgs:errMask]
                                                                                       title:@"Error."
                                                                            alertDescription:AS(@"We're sorry, but an unexpected error has occurred.  Please try this again later.")
                                                                         descLblHeightAdjust:0.0
                                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                 buttonTitle:@"Okay."
                                                                                buttonAction:^{
                                                                                }
                                                                              relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                         });
                                                       }                                                          
                                                      addlAuthRequiredBlk:^{
                                                        [RUtils logEvent:@"auth_reqd_wh_canc_subscription"];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                          commonDone();
                                                          UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
                                                          NSAttributedString *attrBecameUnauthMessage =
                                                          [PEUIUtils attributedTextWithTemplate:@"While attempting to cancel your account, the server is asking for you to re-authenticate.\n\nTo re-authenticate, go to:\n\n%@."
                                                                                   textToAccent:@"Account \u2794 Re-authenticate"
                                                                                 accentTextFont:boldDescFont];
                                                          [PEUIUtils showWarningAlertWithMsgs:nil
                                                                                        title:@"Authentication Failure."
                                                                             alertDescription:attrBecameUnauthMessage
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
                                                        cancelAction:^{
                                                          [RUtils logEvent:@"cancel_subscription_cancelled"];
                                                        }
                                                           uitoolkit:_uitoolkit];
    [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:promptCurrentPasswordController
                                                                                 navigationBarHidden:NO]
                                              animated:YES
                                            completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  
  // place views onto panel
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += headingPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:titleLabel below:headingPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:20.0 hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += titleLabel.frame.size.height + 30.0;
  UIView *topView = titleLabel;
  vpadding = 20.0;
  [PEUIUtils placeView:cancelReason below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0 + iphoneXSafeInsetsSideVal];
  totalHeight += cancelReason.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:0.0 iphone6Width:0.0 iphone6PlusWidth:0.0 ipad:20.0];
  [PEUIUtils placeView:exportPanel below:cancelReason onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  totalHeight += exportPanel.frame.size.height + 0.0;
  [PEUIUtils placeView:refundPanel below:exportPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:15.0 hpadding:0.0];
  totalHeight += refundPanel.frame.size.height + 15.0;
  [PEUIUtils placeView:cancelBtn below:refundPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:15.0 hpadding:10.0 + iphoneXSafeInsetsSideVal];
  totalHeight += cancelBtn.frame.size.height + 15.0;
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:17.0 iphone6PlusWidth:19.0 ipad:25.0];
  [PEUIUtils placeView:cancelSubscriptionBtn below:cancelBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0 + iphoneXSafeInsetsSideVal];
  totalHeight += cancelSubscriptionBtn.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
}

@end
