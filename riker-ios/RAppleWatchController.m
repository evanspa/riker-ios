//
//  RAppleWatchController.m
//  Riker
//
//  Created by PEVANS on 10/24/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RAppleWatchController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "RLocalDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "RPanelToolkit.h"
#import "PELMUser.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RLogging.h"
#import "RUIUtils.h"
#import "PEUtils.h"
#import "RAppNotificationNames.h"
#import "PELocalDao.h"
#import "RUserSettings.h"
@import Firebase;
#import "RWatchUtils.h"

@implementation RAppleWatchController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  MBProgressHUD *_hud;
  NSTimer *_timeoutTimer;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Apple Watch"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
  }
  return self;
}

#pragma mark - Timeout Handler

- (void)timeoutHandler:(NSTimer *)timer {
  WCSession *session = [WCSession defaultSession];
  session.delegate = APP; // assign back to our app delegate
  [timer invalidate];
  dispatch_async(dispatch_get_main_queue(), ^{
    [_hud hideAnimated:YES];
    [PEUIUtils showInfoAlertWithTitle:@"Apple Watch not Reachable?"
                     alertDescription:AS(@"Did not get acknowledgement from your Watch in a timely manner.  Make sure your Watch is in range and try again.\n\nOr, open Riker on your Watch and check if your data actually made it there.")
                  descLblHeightAdjust:0.0
            additionalContentSections:nil
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay"
                         buttonAction:^{}
                       relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
  });
}

#pragma mark - Helpers

- (void)showWatchConnectionWithError:(NSError *)error {
  NSString *errorMessage = nil;
  if (error) {
    errorMessage = error.localizedDescription;
  }
  NSString *title;
  NSAttributedString *desc;
  if (errorMessage) {
    title = @"Problem Connecting";
    NSMutableAttributedString *mutableDesc = [[NSMutableAttributedString alloc] init];
    [mutableDesc appendAttributedString:AS(@"There was a problem attempting to connect to your Apple Watch.  The error message is:")];
    [mutableDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n%@"
                                                                 textToAccent:errorMessage
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                                                        attrs:[PEUIUtils paragraphBeforeSpacingAttrs]]];
    desc = mutableDesc;
  } else {
    title = @"Watch Not Reachable";
    desc = AS(@"Your Apple Watch does not appear to be reachable at the moment.");
  }
  [PEUIUtils showErrorAlertWithMsgs:nil
                              title:title
                   alertDescription:desc
                descLblHeightAdjust:0.0
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay"
                       buttonAction:^{}
                     relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
          error:(nullable NSError *)error {
  if (activationState == WCSessionActivationStateActivated) {
    if (session.isReachable) {
      [self transferDataToAppleWatchWithSession:session];
    } else {
      session.delegate = APP; // reassign back to app delegate
      [_hud hideAnimated:YES];
      [self showWatchConnectionWithError:error];
    }
  } else {
    session.delegate = APP; // reassign back to app delegate
    [_hud hideAnimated:YES];
    [self showWatchConnectionWithError:error];
  }
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  // it's very unlikely this callback would ever get called.  The only way it can
  // get called is if immediately after tapping the 'push' button, they tap
  // to sync local bmls or sets from their Apple Watch.
  [APP session:session didReceiveUserInfo:userInfo];
}

- (void)session:(WCSession * __nonnull)session
didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer
          error:(nullable NSError *)error {
  [_timeoutTimer invalidate];
  session.delegate = APP; // assign back to our app delegate
  dispatch_async(dispatch_get_main_queue(), ^{
    [_hud hideAnimated:YES];
    if (error) {
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Oops"
                       alertDescription:AS(@"There was a problem communicating with your Apple Watch.\n\nMake sure it is reachable and try again.")
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay"
                           buttonAction:nil
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    } else {
      [PEUIUtils showSuccessAlertWithTitle:@"Pushed to Apple Watch"
                          alertDescription:AS(@"Your latest movements, settings, workouts, sets and body logs have been synchronized to Riker on your Apple Watch.")
                       descLblHeightAdjust:0.0
                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                               buttonTitle:@"Okay"
                              buttonAction:^{}
                            relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    }
  });
}

#pragma mark - Transfer Data to Apple Watch

- (void)transferDataToAppleWatchWithSession:(WCSession *)session {
  _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                   target:self
                                                 selector:@selector(timeoutHandler:)
                                                 userInfo:nil
                                                  repeats:NO];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDictionary *allDataForAppleWatch = [RUtils allDataForAppleWatchWithCoordDao:_coordDao];
    [session transferUserInfo:@{ RWATCHMSG_PAYLOAD_KEY: allDataForAppleWatch,
                                 RWATCHMSG_ACTION_KEY: @(RWatchMsgActionPushAllIPhoneData),
                                 RWATCHMSG_RAISE_NOTIFICATION_KEY: @(YES) }];
  });
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat headingHpadding = 15.0 + iphoneXSafeInsetsSideVal;
  NSMutableAttributedString *headerText = [[NSMutableAttributedString alloc] init];
  NSDictionary *spacingAttrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  UIFont *boldFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]];
  [headerText appendAttributedString:AS(@"From here you can keep your Riker data synchronized between your iPhone and Apple Watch.")];
  [headerText appendAttributedString:ASA(@"\nNormally, Riker on Apple Watch will automatically stay synced with Riker on iPhone.  Use the button below to manually sync-down the latest movements and other data from your iPhone if needed.", spacingAttrs)];  
  [headerText appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nSets and body logs saved from the Riker Apple Watch app are stored locally to the watch and %@."
                                                              textToAccent:@"need to be synced from the Riker watch app"
                                                            accentTextFont:boldFont
                                                                     attrs:spacingAttrs]];  
  UILabel *headingLabel = [PEUIUtils labelWithAttributeText:headerText
                                                       font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                   fontForHeightCalculation:boldFont
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlack]
                                        verticalTextPadding:0.0
                                                 fitToWidth:contentPanel.frame.size.width - (headingHpadding * 2)];
  CGFloat labelLeftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UIButton *pushBtn = [_uitoolkit systemButtonMaker](@"Push to Apple Watch", nil, nil);
  [PEUIUtils setFrameWidthOfView:pushBtn ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
  [pushBtn bk_addEventHandler:^(id sender) {
    WCSession *session = [WCSession defaultSession];
    if ([session activationState] == WCSessionActivationStateActivated) {
      _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _hud.tag = RHUD_TAG;
      session.delegate = self;
      [self transferDataToAppleWatchWithSession:session];
    } else {
      if (session.reachable) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.tag = RHUD_TAG;
        session.delegate = self;
        [session activateSession];
      } else {
        [self showWatchConnectionWithError:nil];
      }
    }
  } forControlEvents:UIControlEventTouchUpInside];
  CGFloat msgLabelFitToWidth = contentPanel.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2);
  UIView *pushMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Push your latest movements, settings, workouts, sets and body logs to your Apple Watch."
                                                                   font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                        backgroundColor:[UIColor clearColor]
                                                              textColor:[UIColor darkGrayColor]
                                                    verticalTextPadding:3.0
                                                             fitToWidth:msgLabelFitToWidth]
                                        padding:labelLeftPadding];
  UIView *pushPanel =  [PEUIUtils panelWithColumnOfViews:@[pushBtn, pushMsgPanel]
                             verticalPaddingBetweenViews:4.0
                                          viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  // place views
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingLabel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:headingHpadding];
  totalHeight += headingLabel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = 20.0;
  [PEUIUtils placeView:pushPanel
                 below:headingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += pushPanel.frame.size.height + vpadding;
  // set height of contentPanel
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

@end
