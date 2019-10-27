//
//  RDoUpdatePaymentMethodScreen.m
//  riker-ios
//
//  Created by PEVANS on 1/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RDoUpdatePaymentMethodScreen.h"
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
@import Firebase;

@implementation RDoUpdatePaymentMethodScreen {
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
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Update Payment Method"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _panelToolkit = panelToolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIView *headingPanel = [RPanelToolkit breadcrumbPanelWithTemplateText:@"Synchronize Account \u2192 %@"
                                                           textToAccent:@"Update Payment Method"
                                                         relativeToView:contentPanel];
  
  UILabel *titleLabel = [PEUIUtils labelWithKey:@"Click the button below to update your payment method."
                                           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor rikerAppBlack]
                            verticalTextPadding:5.0
                                     fitToWidth:contentPanel.frame.size.width - 18.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIView *(^makeSeparator)(CGFloat, CGFloat, UIColor *) = ^(CGFloat widthOf, CGFloat height, UIColor *color) {
    UIView *separator = [PEUIUtils panelWithWidthOf:widthOf relativeToView:contentPanel fixedHeight:height];
    [PEUIUtils adjustWidthOfView:separator withValue:(-2 * iphoneXSafeInsetsSideVal)];
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
  UIButton *updatePaymentMethodBtn = [PEUIUtils buttonWithKey:@"Update\nPayment Method"
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
  updatePaymentMethodBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
  [updatePaymentMethodBtn bk_addEventHandler:^(id sender) {
    //PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    STPTheme *theme = [STPTheme defaultTheme];
    theme.primaryForegroundColor = [UIColor rikerAppBlack];
    STPAddCardViewController *addCardViewController =
    [[STPAddCardViewController alloc] initWithConfiguration:[STPPaymentConfiguration sharedConfiguration]
                                                      theme:theme];
    addCardViewController.delegate = self;
    //addCardViewController.prefilledInformation.email = user.email;
    [self presentViewController:[PEUIUtils navigationControllerWithController:addCardViewController
                                                          navigationBarHidden:NO]
                       animated:YES
                     completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *updateBtnDisclaimerLabel = [PEUIUtils labelWithKey:@"This will bring you to Stripe's payment update form."
                                                         font:[PEUIUtils italicFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2 iphone6Width:UIFontTextStyleCaption2 iphone6PlusWidth:UIFontTextStyleSubheadline ipad:UIFontTextStyleBody]]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor rikerAppBlack]
                                          verticalTextPadding:5.0
                                                   fitToWidth:contentPanel.frame.size.width - 18.0];
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
  [PEUIUtils placeView:sep1 below:titleLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += sep1.frame.size.height + vpadding;
  [PEUIUtils placeView:cancelBtn below:sep1 onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0 + iphoneXSafeInsetsSideVal];
  totalHeight += cancelBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:updatePaymentMethodBtn below:cancelBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:10.0 + iphoneXSafeInsetsSideVal];
  totalHeight += updatePaymentMethodBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:updateBtnDisclaimerLabel below:updatePaymentMethodBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:3.0 hpadding:0.0];
  totalHeight += updateBtnDisclaimerLabel.frame.size.height + 3.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
}

#pragma mark - STPAddCardViewControllerDelegate

- (void)addCardViewControllerDidCancel:(STPAddCardViewController *)addCardViewController {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addCardViewController:(STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
  [addCardViewController dismissViewControllerAnimated:YES completion:^{
    if (token) {
      REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:self];
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.tag = RHUD_TAG;
      enableUserInteraction(NO);
      HUD.delegate = self;
      HUD.label.text = @"Updating payment method...";
      PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      user.stripeToken = token;      
      void (^commonDone)(void) = ^{
        [HUD hideAnimated:YES];
        enableUserInteraction(YES);
        [APP refreshTabs];
      };
      [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncStripeTokenImmediate:user
                                                             notFoundOnServerBlk:nil
                                                                  addlSuccessBlk:^{
                                                                    [RUtils logEvent:@"update_paymnt_methd_success"];
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                      commonDone();
                                                                      [PEUIUtils showSuccessAlertWithTitle:@"Payment method updated"
                                                                                          alertDescription:AS(@"Your payment method has been updated.")
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
                                                            [RUtils logEvent:@"busy_wh_updating_paymnt_methd"];
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                              commonDone();
                                                              [PEUIUtils showWaitAlertWithMsgs:nil
                                                                                         title:@"Busy with maintenance."
                                                                              alertDescription:[[NSAttributedString alloc] initWithString:@"The server is currently busy at the moment undergoing maintenance.\n\nYou can try updating your payment method later."]
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
                                                            [RUtils logEvent:@"tmp_remote_err_wh_updating_paymnt_methd"];
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
                                                                [RUtils logEvent:@"remote_err_wh_updating_paymnt_methd"
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
                                                               [RUtils logEvent:@"auth_reqd_wh_updating_paymnt_methd"];
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                 commonDone();
                                                                 UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
                                                                 NSAttributedString *attrBecameUnauthMessage =
                                                                 [PEUIUtils attributedTextWithTemplate:@"While attempting to update your payment method, the server is asking for you to re-authenticate.\n\nTo re-authenticate, go to:\n\n%@."
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
    } else {
      [RUtils logEvent:@"stripe_tkn_nil_wh_updating_paymnt_methd"];
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Error."
                       alertDescription:AS(@"We're sorry, but an unexpected error has occurred.  Please try this again later.")
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{
                           }
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    }
  }];
}

@end
