//
//  RSettingsController.m
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RSettingsController.h"
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
#import "PEChangelog.h"
#import "RAppNotificationNames.h"
#import "PELocalDao.h"
#import "RSplashController.h"
#import "RReauthenticateController.h"
#import "RAccountLoginController.h"
#import "RCreateAccountController.h"
#import "RUserSettings.h"
#import "RLegalScreen.h"
@import Firebase;
@import HealthKit;
#import "RGeneralInfoController.h"
#import "PEWebViewScreen.h"
#import "RAppleWatchController.h"

NSInteger const HEALTHKIT_PANEL_TAG = 300;

@implementation RSettingsController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RUserSettingsBlk _userSettingsBlk;
  RPanelToolkit *_panelToolkit;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Settings"];
  if (self) {
    _userSettingsBlk = userSettingsBlk;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
  }
  return self;
}

#pragma mark - Do Hard Repaint

- (void)doHardRepaint {
  [[self.view viewWithTag:HEALTHKIT_PANEL_TAG] removeFromSuperview];
  [self setNeedsRepaint:YES];
  [self viewDidAppear:YES];
}

#pragma mark - Handle Delete All Data Notification

- (void)deleteAllDataNotification:(NSNotification *)notification {
  [self doHardRepaint];
}

#pragma mark - Handle HealthKit sync notifications (received off main thread)

- (void)receivedHkNotification:(NSNotification *)notification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self doHardRepaint];
  });
}

#pragma mark - Preferred Content Size Changed Notification Handler

- (void)preferredContentSizeChanged:(NSNotification *)notification {
  [self doHardRepaint];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(deleteAllDataNotification:)
                             name:RAppDeleteAllDataNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(receivedHkNotification:)
                             name:RErrorSavingWorkoutsToHealthKitNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(receivedHkNotification:)
                             name:RErrorSavingBodyWeightToHealthKitNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(receivedHkNotification:)
                             name:RWorkoutsSavedToHealthKitNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(receivedHkNotification:)
                             name:RBodyWeightsSavedToHealthKitNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(preferredContentSizeChanged:)
                             name:UIContentSizeCategoryDidChangeNotification
                           object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [APP setUserSettingsOpenFromSettingsScreen:NO];
  // this is need if on the apple watch controller screen, the user taps the
  // 'push' button (assigning 'session' to the RAppleWatchController instance), and
  // then the user immediately taps the back button to come here...we need these
  // lines to ensure the wc session is assigned back to the app delegate
  WCSession *session = [WCSession defaultSession];
  session.delegate = APP; // assign back to our app delegate
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // I need this because if the user taps to view the splash screen, I
  // set the the nav-bar as hidden, so when the user comes back, I need to
  // make it re-appear
  [[self.navigationController navigationBar] setHidden:NO];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  if ([APP isUserLoggedIn]) {
    return [self makeDoesHaveAuthTokenContent];
  } else {
    return [self makeNotLoggedInContent];
  }
}

#pragma mark - Helpers

- (UIView *)messagePanelWithMessage:(NSString *)message
                          iconImage:(UIImage *)iconImage
                     relativeToView:(UIView *)relativeToView {
  CGFloat iconLeftPadding = 10.0;
  CGFloat paddingBetweenIconAndLabel = 3.0;
  CGFloat labelLeftPadding = 8.0;
  UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
  UILabel *messageLabel = [PEUIUtils labelWithKey:message
                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:(relativeToView.frame.size.width - (labelLeftPadding + iconImageView.frame.size.width + iconLeftPadding + paddingBetweenIconAndLabel))];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:labelLeftPadding];
  UIView *messagePanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                      relativeToView:relativeToView
                                         fixedHeight:messageLabelWithPad.frame.size.height];
  [PEUIUtils placeView:iconImageView
            inMiddleOf:messagePanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:iconLeftPadding];
  [PEUIUtils placeView:messageLabelWithPad
          toTheRightOf:iconImageView
                  onto:messagePanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:paddingBetweenIconAndLabel];
  return messagePanel;
}

- (UIButton *)makeExportButton {
  UIButton *exportBtn = [_uitoolkit systemButtonMaker](@"Export", nil, nil);
  [PEUIUtils setFrameWidthOfView:exportBtn ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
  [exportBtn bk_addEventHandler:^(id sender) {
    [RUtils logEvent:@"export_all_clicked"];
    [_panelToolkit invokeExportWithController:self];
  } forControlEvents:UIControlEventTouchUpInside];
  return exportBtn;
}

- (UIView *)appleWatchPanelRelativeToView:(UIView *)relativeToView {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSMutableAttributedString *attrMessage;
  attrMessage = [[NSMutableAttributedString alloc] initWithString:@"Keep your Riker data synchronized between your iPhone and Apple Watch."];
  UIFont *fontForHeightCalculation = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UIView *msgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                            fontForHeightCalculation:fontForHeightCalculation
                                                      relativeToView:relativeToView];
  UIButton *btn = buttonMaker(@"Apple Watch", nil, nil);
  [[btn layer] setCornerRadius:0.0];
  [btn bk_addEventHandler:^(id sender) {
    UIViewController *appleWatchScreen = [_screenToolkit newAppleWatchScreenMaker]();
    [self.navigationController pushViewController:appleWatchScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:btn ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils addDisclosureIndicatorToButton:btn];
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"orig-device-apple-watch"]]
            inMiddleOf:btn
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0 + [PEUIUtils iphoneXSafeInsetsSide]];
  return [PEUIUtils panelWithColumnOfViews:@[btn, msgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
 }

- (UIView *)generalInfoButtonAndMsgRelativeToView:(UIView *)relativeToView {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSMutableAttributedString *attrMessage =
  [[NSMutableAttributedString  alloc] initWithString:@"Learn about the movements available in Riker, how Riker calculates your strength and more."];
  UIFont *fontForHeightCalculation = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UIView *generalInfoMsgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                                       fontForHeightCalculation:fontForHeightCalculation
                                                                 relativeToView:relativeToView];
  UIButton *generalInfoBtn = buttonMaker(@"General Info", nil, nil);
  [[generalInfoBtn layer] setCornerRadius:0.0];
  [generalInfoBtn bk_addEventHandler:^(id sender) {
    UIViewController *generalInfoScreen = [_screenToolkit newGeneralInfoScreenMaker]();
    [self.navigationController pushViewController:generalInfoScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:generalInfoBtn ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils addDisclosureIndicatorToButton:generalInfoBtn];
  return [PEUIUtils panelWithColumnOfViews:@[generalInfoBtn, generalInfoMsgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

- (NSArray *)profileAndSettingsButtonAndMsgRelativeToView:(UIView *)relativeToView
                                           isUserLoggedIn:(BOOL)isUserLoggedIn {
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSMutableAttributedString *attrMessage = [[NSMutableAttributedString  alloc] initWithString:@"From here you can view and edit various defaults (e.g., weight units)."];
  UIFont *fontForHeightCalculation = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  RUserSettings *userSettings = _userSettingsBlk(user);
  BOOL syncNeeded = [PEUtils isNotNil:userSettings.globalIdentifier] &&
  !userSettings.synced &&
  isUserLoggedIn &&
  [PEUtils isNil:userSettings.syncErrMask];
  if (syncNeeded) {
    NSString *text = @"Sync needed.";
    [attrMessage appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"  %@"
                                                                 textToAccent:text
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                              accentTextColor:[UIColor bootstrapPrimary]]];
    fontForHeightCalculation = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  }
  UIView *profileSettingsMsgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                                           fontForHeightCalculation:fontForHeightCalculation
                                                                     relativeToView:relativeToView];
  UIButton *profileSettingsBtn = buttonMaker(@"Profile and Settings", nil, nil);
  [[profileSettingsBtn layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:profileSettingsBtn ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils addDisclosureIndicatorToButton:profileSettingsBtn];
  [profileSettingsBtn bk_addEventHandler:^(id sender) {
    if ([APP userSettingsOpenFromUnsyncedEditsScreen]) {
      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
      [desc appendAttributedString:[[NSAttributedString alloc] initWithString:@"It looks like you've already got your Profile and Settings open from the "]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ tab.\n\nHead over to the "
                                                            textToAccent:@"Records"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ tab to get to your unsynced Profile and Settings."
                                                            textToAccent:@"Records"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [PEUIUtils showWarningAlertWithMsgs:nil
                                    title:@"Profile and Settings already open."
                         alertDescription:desc
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay"
                             buttonAction:^{}
                           relativeToView:self.tabBarController.view];
    } else {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
      [APP setUserSettingsOpenFromSettingsScreen:YES];
      [PEUIUtils displayController:[_screenToolkit newUserSettingsDetailScreenMakerWithSettings:userSettings]()
                    fromController:self
                          animated:YES];
    }
  } forControlEvents:UIControlEventTouchUpInside];
  return @[profileSettingsBtn, profileSettingsMsgPanel];
}

#pragma mark - Device Rotation

- (void)willRepaintDueToRotate {
  UIView *healthKitPanel = [self.view viewWithTag:HEALTHKIT_PANEL_TAG];
  if (healthKitPanel) {
    [healthKitPanel removeFromSuperview];
  }
}


#pragma mark - Panel Makers

- (UIView *)healthkitPanelRelativeToView:(UIView *)contentPanel {
  UIView *healthKitPanel = nil;
  if ([HKHealthStore isHealthDataAvailable]) {
    healthKitPanel =  [self.view viewWithTag:HEALTHKIT_PANEL_TAG];
    if (!healthKitPanel) {
      healthKitPanel = [_panelToolkit healthKitSwitchPanelWithController:self
                                                                     tag:HEALTHKIT_PANEL_TAG
                                                          relativeToView:contentPanel];
      [healthKitPanel setTag:HEALTHKIT_PANEL_TAG];
    }
  }
  return healthKitPanel;
}
- (UIView *)makeSplashScreenPanelFitSubtitleToWidth:(CGFloat)fitSubtitleToWidth {
  CGFloat labelLeftPadding = 8.0;
  UIButton *viewSplashScreenBtn = [_uitoolkit systemButtonMaker](@"Splash Screen", nil, nil);
  [PEUIUtils setFrameWidthOfView:viewSplashScreenBtn ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *viewSplashScreenMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Riker's splash screen (in case you missed it before)."
                                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                    backgroundColor:[UIColor clearColor]
                                                                          textColor:[UIColor darkGrayColor]
                                                                verticalTextPadding:3.0
                                                                         fitToWidth:fitSubtitleToWidth - (iphoneXSafeInsetsSideVal * 2)]
                                                    padding:labelLeftPadding + iphoneXSafeInsetsSideVal];
  [viewSplashScreenBtn bk_addEventHandler:^(id sender) {
    RSplashController *splashController =
      [[RSplashController alloc] initWithStoreCoordinator:_coordDao
                                                uitoolkit:_uitoolkit
                                            screenToolkit:_screenToolkit
                                                againMode:YES];
    [self presentViewController:[PEUIUtils navigationControllerWithController:splashController
                                                          navigationBarHidden:NO]
                       animated:YES
                     completion:^{}];    
  } forControlEvents:UIControlEventTouchUpInside];
  return [PEUIUtils panelWithColumnOfViews:@[viewSplashScreenBtn, viewSplashScreenMsgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

- (UIView *)makeBuildNameAndVersionNumberPanel {
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *version = infoDictionary[@"CFBundleShortVersionString"];
  NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *view = [PEUIUtils labelValuePanelWithCellHeight:50.0
                                              labelString:@"Riker Version"
                                           labelTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                           labelTextColor:[UIColor blackColor]
                                        labelLeftHPadding:8.0 + iphoneXSafeInsetsSideVal
                                              valueString:[NSString stringWithFormat:@"%@  build: %@", version, build]
                                           valueTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                           valueTextColor:[UIColor rikerAppBlack]
                                       valueRightHPadding:8.0 + iphoneXSafeInsetsSideVal
                                            valueLabelTag:nil
                           minPaddingBetweenLabelAndValue:10.0
                                                 rowWidth:[PEUIUtils widthOfForContent] * self.view.frame.size.width];
  [view setBackgroundColor:[UIColor whiteColor]];
  return view;
}

- (UIView *)makeAppStorePanelFitSubtitleToWidth:(CGFloat)fitSubtitleToWidth {
  CGFloat labelLeftPadding = 8.0;
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIButton *button = [_uitoolkit systemButtonMaker](@"Review Riker in the App Store", nil, nil);
  [PEUIUtils setFrameWidthOfView:button ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Tell others about your experience with Riker.  Leave us a review in the App Store."
                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:fitSubtitleToWidth - (iphoneXSafeInsetsSideVal * 2)]
                                    padding:labelLeftPadding + iphoneXSafeInsetsSideVal];
  [button bk_addEventHandler:^(id sender) {
    [RUtils logEvent:@"write_review"];
    NSString * theUrl = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@?action=write-review&mt=8", RIKER_ITUNES_APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:theUrl]
                                       options:@{}
                             completionHandler:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  return [PEUIUtils panelWithColumnOfViews:@[button, msgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

- (UIView *)makeSharePanelFitSubtitleToWidth:(CGFloat)fitSubtitleToWidth {
  CGFloat labelLeftPadding = 8.0;
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIButton *button = [_uitoolkit systemButtonMaker](@"Share Riker", nil, nil);
  [PEUIUtils setFrameWidthOfView:button ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
  UIView *msgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Enjoying Riker?  Share it with your friends."
                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:3.0
                                                         fitToWidth:fitSubtitleToWidth - (iphoneXSafeInsetsSideVal * 2)]
                                    padding:labelLeftPadding + iphoneXSafeInsetsSideVal];
  [button bk_addEventHandler:^(id sender) {
    [RUtils logEvent:kFIREventShare];
    NSString *textToShare = @"Try Riker for tracking your reps in the gym!";
    NSArray *objectsToShare = @[textToShare, [NSURL URLWithString:[APP rikerHomeUrl]]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    activityVC.excludedActivityTypes = excludeActivities;
    // https://stackoverflow.com/a/25644145/1034895
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
      activityVC.popoverPresentationController.sourceView = self.view;
    }
    [self presentViewController:activityVC animated:YES completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  return [PEUIUtils panelWithColumnOfViews:@[button, msgPanel]  
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

- (NSArray *)makeDoesHaveAuthTokenContent {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *offlineDesc = [[NSMutableAttributedString alloc] initWithString:@"Don't get bogged down by a slow internet connection!  Offline mode prevents syncing for an ultra fast experience.  "];
  NSAttributedString *offlineDescPart2 = [PEUIUtils attributedTextWithTemplate:@"Later, at your convenience you can bulk-sync your edits to your account from the %@ screen."
                                                                  textToAccent:@"Records"
                                                                accentTextFont:boldDescFont];
  [offlineDesc appendAttributedString:offlineDescPart2];
  UILabel *offlineModeDescLabel = [PEUIUtils labelWithAttributeText:offlineDesc
                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                           fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor darkGrayColor]
                                                verticalTextPadding:0.0
                                                         fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIView *offlineModeSwitchPanel = [_panelToolkit offlineModeSwitchPanelRelativeToView:contentPanel displayIcon:YES];
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  UIView *changelogPanel = [_panelToolkit changeLogPanelWithParentView:contentPanel
                                                            controller:self
                                                                  user:user
                                                       userSettingsBlk:_userSettingsBlk
                                             actionIfChangesDownloaded:^{
                                               [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
                                             }];
  NSArray *profileAndSettingsBtnAndMsg = [self profileAndSettingsButtonAndMsgRelativeToView:contentPanel
                                                                             isUserLoggedIn:YES];
  UIButton *profileSettingsBtn = profileAndSettingsBtnAndMsg[0];
  UIView *profileSettingsMsgPanel = profileAndSettingsBtnAndMsg[1];
  UIView *healthKitPanel = [self healthkitPanelRelativeToView:contentPanel];
  UIView *appleWatchPanel = nil;
  if ([WCSession isSupported]) {
    appleWatchPanel = [self appleWatchPanelRelativeToView:contentPanel];
  }
  UIView *generalInfoPanel = [self generalInfoButtonAndMsgRelativeToView:contentPanel];
  // place the views on the contentPanel
  [PEUIUtils placeView:profileSettingsBtn atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:[RUIUtils contentPanelTopPadding] hpadding:0.0];
  CGFloat totalHeight = profileSettingsBtn.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:profileSettingsMsgPanel below:profileSettingsBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
  totalHeight += profileSettingsMsgPanel.frame.size.height + 4.0;
  [PEUIUtils placeView:offlineModeSwitchPanel below:profileSettingsMsgPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
  totalHeight += offlineModeSwitchPanel.frame.size.height + 25.0;
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:4
                                       iphone6Width:6
                                   iphone6PlusWidth:6
                                               ipad:6];
  [PEUIUtils placeView:offlineModeDescLabel below:offlineModeSwitchPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += offlineModeDescLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:changelogPanel below:offlineModeDescLabel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:changelogPanel vpadding:20.0 hpadding:0.0];
  totalHeight += changelogPanel.frame.size.height + 20.0;
  UIView *topView = changelogPanel;
  if (healthKitPanel) {
    [PEUIUtils placeView:healthKitPanel below:changelogPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
    totalHeight += healthKitPanel.frame.size.height + 25.0;
    topView = healthKitPanel;
  }
  if (appleWatchPanel) {
    [PEUIUtils placeView:appleWatchPanel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += appleWatchPanel.frame.size.height + 20.0;
    topView = appleWatchPanel;
  }
  [PEUIUtils placeView:generalInfoPanel
                 below:topView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  totalHeight += generalInfoPanel.frame.size.height + 20.0;
  UIButton *exportBtn = [self makeExportButton];
  [PEUIUtils placeView:exportBtn below:generalInfoPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
  totalHeight += exportBtn.frame.size.height + 25.0;
  UILabel *exportMsgLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"From here you can export your Riker data to files which you can then download from iTunes to your computer.\n\nTip: Before exporting, use the %@ button above to ensure this device has your latest Riker data."
                                                                                       textToAccent:@"Synchronize Account"
                                                                                     accentTextFont:boldDescFont]
                                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                     fontForHeightCalculation:boldDescFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:contentPanel.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
  [PEUIUtils placeView:exportMsgLabel below:exportBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:4.0 hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += exportMsgLabel.frame.size.height + 4.0;
  UIView *appStorePanel = [self makeAppStorePanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:appStorePanel
                 below:exportMsgLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0.0];
  totalHeight += appStorePanel.frame.size.height + 20.0;
  UIView *sharePanel = [self makeSharePanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:sharePanel
                 below:appStorePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0.0];
  totalHeight += sharePanel.frame.size.height + 20.0;
  UIView *splashScreenPanel = [self makeSplashScreenPanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:splashScreenPanel below:sharePanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:20.0 hpadding:0.0];
  totalHeight += splashScreenPanel.frame.size.height + 20.0;
  UIView *buildInfoPanel = [self makeBuildNameAndVersionNumberPanel];
  [PEUIUtils placeView:buildInfoPanel below:splashScreenPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:20.0 hpadding:0.0];
  totalHeight += buildInfoPanel.frame.size.height + 20.0;
  
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(YES)];
}

- (NSArray *)makeNotLoggedInContent {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                      relativeToView:self.view
                                         fixedHeight:0.0];
  NSArray *profileAndSettingsBtnAndMsg = [self profileAndSettingsButtonAndMsgRelativeToView:contentPanel
                                                                             isUserLoggedIn:NO];
  UIButton *profileSettingsBtn = profileAndSettingsBtnAndMsg[0];
  UIView *profileSettingsMsgPanel = profileAndSettingsBtnAndMsg[1];
  UIView *healthKitPanel = [self healthkitPanelRelativeToView:contentPanel];
  UIView *appleWatchPanel = nil;
  if ([WCSession isSupported]) {
    appleWatchPanel = [self appleWatchPanelRelativeToView:contentPanel];
  }
  UIView *generalInfoPanel = [self generalInfoButtonAndMsgRelativeToView:contentPanel];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSString *message = @"This action will permanently delete your Riker sets, body logs and settings from this device.";
  UIView *deleteMessagePanel = [PEUIUtils leftPaddingMessageWithAttributedText:[[NSAttributedString alloc] initWithString:message]
                                                      fontForHeightCalculation:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                relativeToView:contentPanel];
  UIButton *deleteAllDataBtn = buttonMaker(@"Delete all data", self, @selector(clearAllData));
  [deleteAllDataBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red-exclamation-icon"]] inMiddleOf:deleteAllDataBtn withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameWidthOfView:deleteAllDataBtn ofWidth:1.0 relativeTo:contentPanel];
  // place views onto panel
  [PEUIUtils placeView:profileSettingsBtn
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = profileSettingsBtn.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:profileSettingsMsgPanel
                 below:profileSettingsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += profileSettingsMsgPanel.frame.size.height + 4.0;
  UIView *topView = profileSettingsMsgPanel;
  if (healthKitPanel) {
    [PEUIUtils placeView:healthKitPanel
                   below:profileSettingsMsgPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += healthKitPanel.frame.size.height + 20.0;
    topView = healthKitPanel;
  }
  if (appleWatchPanel) {
    [PEUIUtils placeView:appleWatchPanel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += appleWatchPanel.frame.size.height + 20.0;
    topView = appleWatchPanel;
  }
  [PEUIUtils placeView:generalInfoPanel
                 below:topView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  totalHeight += generalInfoPanel.frame.size.height + 20.0;  
  UIButton *exportBtn = [self makeExportButton];
  [PEUIUtils placeView:exportBtn
                 below:generalInfoPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  totalHeight += exportBtn.frame.size.height + 20.0;
  UILabel *exportMsgLabel = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:@"From here you can export your Riker data to files which you can then download from iTunes to your computer."]
                                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor darkGrayColor]
                                          verticalTextPadding:3.0
                                                   fitToWidth:contentPanel.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
  [PEUIUtils placeView:exportMsgLabel
                 below:exportBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:4.0
              hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += exportMsgLabel.frame.size.height + 4.0;
  [PEUIUtils placeView:deleteAllDataBtn
                 below:exportMsgLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0];
  totalHeight += deleteAllDataBtn.frame.size.height + 20.0;
  [PEUIUtils placeView:deleteMessagePanel
                 below:deleteAllDataBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += deleteMessagePanel.frame.size.height + 4.0;
  UIView *appStorePanel = [self makeAppStorePanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:appStorePanel
                 below:deleteMessagePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0.0];
  totalHeight += appStorePanel.frame.size.height + 20.0;
  UIView *sharePanel = [self makeSharePanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:sharePanel
                 below:appStorePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0.0];
  totalHeight += sharePanel.frame.size.height + 20.0;
  UIView *splashScreenPanel = [self makeSplashScreenPanelFitSubtitleToWidth:(contentPanel.frame.size.width - 15.0)];
  [PEUIUtils placeView:splashScreenPanel
                 below:sharePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:0.0];
  totalHeight += splashScreenPanel.frame.size.height + 20.0;
  UIView *buildInfoPanel = [self makeBuildNameAndVersionNumberPanel];
  [PEUIUtils placeView:buildInfoPanel below:splashScreenPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:20.0 hpadding:0.0];
  totalHeight += buildInfoPanel.frame.size.height + 20.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(YES)];
}

#pragma mark - Clear All Data

- (void)clearAllData {
  NSString *msg = @"This will permanently delete your Riker data from this device and cannot be undone.";
  JGActionSheetSection *contentSection = [PEUIUtils dangerAlertSectionWithTitle:@"Are you absolutely sure?"
                                                                alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                            descLblHeightAdjust:0.0
                                                                  relativeToView:self.tabBarController.view];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[@"No.  Cancel.", @"Yes.  Delete my data."]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
  JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch ([indexPath row]) {
      case 0: // cancel
        [sheet dismissAnimated:YES];
        break;
      case 1: // delete
        [sheet dismissAnimated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
        hud.tag = RHUD_TAG;
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
          [_coordDao.userCoordinatorDao resetAsLocalUser:user
                                               deleteAll:YES
                                   userSettingsMtVersion:[_coordDao userSettingsResMtVersion]
                                                   error:[RUtils localSaveErrorHandlerMaker]()];
          [RUtils clearHkWorkoutEndDate];
          [RUtils clearHkBodyWeightEndDate];
          [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
          dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [PEUIUtils showSuccessAlertWithTitle:@"Data deleted."
                                alertDescription:AS(@"Your Riker sets, body logs and settings have been deleted successfully.")
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      [RUtils logEvent:@"deleted_all_local_data"];
                                      // delaying posting the event by 50ms helps to eliminate annoying delay
                                      // experienced when dismissing this success-alert
                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.050 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                        [[NSNotificationCenter defaultCenter] postNotificationName:RAppDeleteAllDataNotification
                                                                                            object:nil
                                                                                          userInfo:nil];
                                      });
                                    }
                                  relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          });
        });
        break;
    };}];
  [sheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
}

#pragma mark - Re-authenticate screen

- (void)presentReauthenticateScreen {
  UIViewController *reauthController =
  [[RReauthenticateController alloc] initWithStoreCoordinator:_coordDao
                                                    uitoolkit:_uitoolkit
                                                screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:reauthController
                                         animated:YES];
}

#pragma mark - Present Log In screen

- (void)presentLoginScreen {
  UIViewController *loginController =
  [[RAccountLoginController alloc] initWithStoreCoordinator:_coordDao
                                                  uitoolkit:_uitoolkit
                                              screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:loginController
                                         animated:YES];
}

#pragma mark - Present Account Creation screen

- (void)presentSetupRemoteAccountScreen {
  UIViewController *createAccountController =
  [[RCreateAccountController alloc] initWithStoreCoordinator:_coordDao
                                                   uitoolkit:_uitoolkit
                                               screenToolkit:_screenToolkit];
  [[self navigationController] pushViewController:createAccountController
                                         animated:YES];
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

@end
