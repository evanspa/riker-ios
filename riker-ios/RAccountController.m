//
//  RAccountController.m
//  riker-ios
//
//  Created by PEVANS on 11/3/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RAccountController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "UIColor+RAdditions.h"
#import "RAppNotificationNames.h"
#import "PELMUser.h"
#import "PEUIUtils.h"
#import "PEUtils.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RPanelToolkit.h"
#import "RReauthenticateController.h"
#import "RAccountLoginController.h"
#import "RCreateAccountController.h"
#import "PESingleValueTableViewDataSourceDelegate.h"
#import "RPanelToolkit.h"
#import "RCoordinatorDao.h"
#import "PELocalDao.h"
#import "RUserSettings.h"
@import Firebase;
#import "RLogging.h"
@import Crashlytics;
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <AFNetworking/AFNetworking.h>

NSInteger const kAccountStatusPanelTag = 12;

@implementation RAccountController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  RUserSettingsBlk _userSettingsBlk;
  MBProgressHUD *_hud;
  SKProduct *_subscriptionProduct;
  NSNumber *_preserveExistingLocalEntities;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:@[RAppReauthReqdNotification,
                                                      RAppReauthNotification,
                                                      RChangelogDownloadedNotification]
                                        screenTitle:[APP isUserLoggedIn] ? @"Your Riker Account" : @"Log In or Create Trial Account"];
  if (self) {
    _coordDao = coordDao;
    _userSettingsBlk = userSettingsBlk;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  if ([APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken]) {
      NSArray *content = [self makeDoesHaveAuthTokenContent];
      UIView *contentPanel = content[0];
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_panelToolkit refreshEmailStatusPanelForUser:user
                                           panelTag:@(kAccountStatusPanelTag)
                               includeRefreshButton:YES
                                     relativeToView:contentPanel
                                      fontTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                         controller:self
                           becameUnauthButtonAction:nil];
      return content;
    } else {
      return [self makeDoesNotHaveAuthTokenContent];
    }
  } else {
    return [self makeNotLoggedInContent];
  }
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  BOOL isUserLoggedIn = [APP isUserLoggedIn:user];
  NSString *title = isUserLoggedIn ? @"Your Riker Account" : @"Log In or Create Trial Account";
  if (![title isEqualToString:[self screenTitle]]) { // we need to change the title
    [self setScreenTitle:title];
    UINavigationItem *navItem = [self navigationItem];
    [navItem setTitle:title];
    [RUtils logScreen:title fromController:self];
  }
  FBSDKAccessToken *fbAccessToken = [FBSDKAccessToken currentAccessToken];
  //if (!isUserLoggedIn && fbAccessToken) {
  if (![APP doesUserHaveValidAuthToken:user] && fbAccessToken) {
    // the user just signed-up using Facebook
    // show a spinner, and complete the account setup against Riker API
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.tag = RHUD_TAG;
    _hud.delegate = self;
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id,email"}]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                  NSDictionary *result, NSError *error) {
       dispatch_async(dispatch_get_main_queue(), ^{
         [_hud hideAnimated:YES];
         if (error) {
           [[Crashlytics sharedInstance] recordError:error];
         } else {
           NSString *email = result[@"email"];
           NSString *facebookUserId = result[@"id"];
           [RUtils handleAccountCreationOrContinueWithCoordDao:_coordDao
                                         enableUserInteraction:[self makeUserEnabledBlock]
                                                    controller:self
                                          watchSessionDelegate:self
                                                   hudDelegate:self
                                                         email:email
                                                      password:nil
                                                facebookUserId:facebookUserId
                                 preserveExistingLocalEntities:_preserveExistingLocalEntities
                         promptedPreserveExistingLocalEntities:^(BOOL preserve) {
                           _preserveExistingLocalEntities = [NSNumber numberWithBool:preserve];
                         }
                                        onSuccessDialogDismiss:^{ [self viewDidAppear:YES]; }];
         }
       });
     }];
  }
}

#pragma mark - Helpers

- (UIView *)logoutPaddedMessageRelativeToView:(UIView *)relativeToView {
  NSString *logoutMsg = @"Logging out will disconnect this device from your account.";
  return [PEUIUtils leftPaddingMessageWithText:logoutMsg relativeToView:relativeToView];
}

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
  UIView *messagePanel = [PEUIUtils panelWithWidthOf:1.0
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

- (FBSDKLoginButton *)facebookLoginButton {
  FBSDKLoginButton *facebookLoginButton = [[FBSDKLoginButton alloc] init];
  facebookLoginButton.readPermissions = @[@"email"];
  [facebookLoginButton.titleLabel setFont:[PEUIUtils actionButtonFont]];
  return facebookLoginButton;
}

#pragma mark - Content Makers

- (NSArray *)makeDoesHaveAuthTokenContent {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSMutableAttributedString *attrMessage = [[NSMutableAttributedString alloc] init];
  UIFont *boldSubheadlineFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  [attrMessage appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@.  From here you can view and edit your account details."
                                                               textToAccent:@"You are currently logged in"
                                                             accentTextFont:boldSubheadlineFont
                                                            accentTextColor:[UIColor greenSeaColor]]];  
  UIView *accountSettingsMsgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                                           fontForHeightCalculation:boldSubheadlineFont
                                                                     relativeToView:contentPanel];
  UIButton *accountSettingsBtn = buttonMaker(@"Account Details", nil, nil);
  [PEUIUtils setFrameWidthOfView:accountSettingsBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:accountSettingsBtn];
  [accountSettingsBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils displayController:[_screenToolkit newUserAccountDetailScreenMaker]() fromController:self animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *emailVerifiedPanel = [_panelToolkit emailStatusPanelForUser:user
                                                             panelTag:@(kAccountStatusPanelTag)
                                                 includeRefreshButton:YES
                                                       relativeToView:contentPanel
                                                        fontTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                                           controller:self
                                             becameUnauthButtonAction:nil];
  [emailVerifiedPanel setBackgroundColor:[UIColor whiteColor]];
  UIView *accountStatus = [_panelToolkit accountStatusPanelForUser:user relativeToView:contentPanel controller:self];  
  UIView *changelogPanel = [_panelToolkit changeLogPanelWithParentView:contentPanel
                                                            controller:self
                                                                  user:user
                                                       userSettingsBlk:_userSettingsBlk
                                             actionIfChangesDownloaded:^{
                                               [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
                                               [self viewDidAppear:YES];
                                             }];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessageRelativeToView:contentPanel];
  UIButton *logoutBtn = buttonMaker(@"Log out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:contentPanel];
  UIView *logoutAllOtherMsgLabelWithPad = [PEUIUtils leftPaddingMessageWithText:@"Did you leave yourself logged in on a public computer or on another device that isn't yours?  Need a way to log out everywhere except this device?  We got you covered." relativeToView:contentPanel];
  UIButton *logoutAllOtherBtn = buttonMaker(@"Log out other sessions", self, @selector(logoutAllOther));
  [logoutAllOtherBtn setTitleColor:[UIColor carrotColor] forState:UIControlStateNormal];
  [PEUIUtils setFrameWidthOfView:logoutAllOtherBtn ofWidth:1.0 relativeTo:contentPanel];
  // place views onto panel
  [PEUIUtils placeView:accountSettingsBtn
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = accountSettingsBtn.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:accountSettingsMsgPanel
                 below:accountSettingsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += accountSettingsMsgPanel.frame.size.height + 4.0;
  [PEUIUtils placeView:accountStatus
                 below:accountSettingsMsgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:25.0
              hpadding:0.0];
  totalHeight += accountStatus.frame.size.height + 25.0;
  [PEUIUtils placeView:changelogPanel
                 below:accountStatus
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:25.0
              hpadding:0.0];
  totalHeight += changelogPanel.frame.size.height + 25.0;
  [PEUIUtils placeView:emailVerifiedPanel
                 below:changelogPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:25.0
              hpadding:0.0];
  totalHeight += emailVerifiedPanel.frame.size.height + 25.0;
  [PEUIUtils placeView:logoutBtn
                 below:emailVerifiedPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:25.0
              hpadding:0.0];
  totalHeight += logoutBtn.frame.size.height + 25.0;
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += logoutMsgLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils placeView:logoutAllOtherBtn
                 below:logoutMsgLabelWithPad
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:25.0
              hpadding:0.0];
  totalHeight += logoutAllOtherBtn.frame.size.height + 25.0;
  [PEUIUtils placeView:logoutAllOtherMsgLabelWithPad
                 below:logoutAllOtherBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += logoutAllOtherMsgLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

- (NSArray *)makeDoesNotHaveAuthTokenContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  CGFloat leftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UIView *msgPanel =  [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"For security reasons, we need you to re-authenticate against your account."
                                                                font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                     backgroundColor:[UIColor clearColor]
                                                           textColor:[UIColor darkGrayColor]
                                                 verticalTextPadding:3.0
                                                          fitToWidth:contentPanel.frame.size.width - (leftPadding + 3.0)]
                                     padding:leftPadding];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSString *passwordReauthMessageTxt = @"Re-authenticate using your password.";
  UIView *passwordReauthMsgPanel = [PEUIUtils leftPaddingMessageWithText:passwordReauthMessageTxt relativeToView:contentPanel];
  UIButton *passwordReauthButton = buttonMaker(@"Re-authenticate with Password", nil, nil);
  [PEUIUtils setFrameWidthOfView:passwordReauthButton ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:passwordReauthButton];
  [passwordReauthButton bk_addEventHandler:^(id sender) {
    [self presentReauthenticateScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *orLabel = [PEUIUtils labelWithAttributeText:AS(@"-- OR --")
                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:contentPanel.frame.size.width];
  FBSDKLoginButton *facebookLoginButton = [self facebookLoginButton];
  [PEUIUtils setFrameWidthOfView:facebookLoginButton ofWidth:0.90 relativeTo:contentPanel];
  [PEUIUtils setFrameHeightOfView:facebookLoginButton ofHeight:1.65 relativeTo:facebookLoginButton];
  UIView *logoutMsgLabelWithPad = [self logoutPaddedMessageRelativeToView:contentPanel];
  UIButton *logoutBtn = buttonMaker(@"Log out", self, @selector(logout));
  [logoutBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [PEUIUtils setFrameWidthOfView:logoutBtn ofWidth:1.0 relativeTo:contentPanel];
  UIView *exclamationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  exclamationView.layer.cornerRadius = 10;
  exclamationView.backgroundColor = [UIColor redColor];
  [PEUIUtils placeView:[PEUIUtils labelWithKey:@"!"
                                          font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                               backgroundColor:[UIColor clearColor]
                                     textColor:[UIColor whiteColor]
                           verticalTextPadding:0.0]
            inMiddleOf:exclamationView
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  [PEUIUtils placeView:exclamationView
            inMiddleOf:passwordReauthButton
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];  
  // place views onto panel
  [PEUIUtils placeView:msgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0];
  CGFloat totalHeight = msgPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:passwordReauthButton
                 below:msgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += passwordReauthButton.frame.size.height + 10.0;
  [PEUIUtils placeView:passwordReauthMsgPanel
                 below:passwordReauthButton
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += passwordReauthMsgPanel.frame.size.height + 4.0;
  [PEUIUtils placeView:orLabel
                 below:passwordReauthMsgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:15.0
              hpadding:0.0];
  totalHeight += orLabel.frame.size.height + 15.0;
  [PEUIUtils placeView:facebookLoginButton
                 below:orLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:15.0
              hpadding:0.0];
  totalHeight += facebookLoginButton.frame.size.height + 15.0;
  [PEUIUtils placeView:logoutBtn
                 below:facebookLoginButton
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:65.0
              hpadding:0.0];
  totalHeight += logoutBtn.frame.size.height + 65.0;
  [PEUIUtils placeView:logoutMsgLabelWithPad
                 below:logoutBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += logoutMsgLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

- (NSArray *)makeNotLoggedInContent {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  UIButton *loginBtn = [PEUIUtils buttonWithKey:@"Log in with email"
                                           font:[PEUIUtils actionButtonFont]
                                backgroundColor:[UIColor turquoiseColor]
                                      textColor:[UIColor whiteColor]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:[PEUIUtils actionButtonVpadding]
                              horizontalPadding:[PEUIUtils actionButtonHpadding]
                                   cornerRadius:5.0
                                         target:nil
                                         action:nil];
  [PEUIUtils setFrameWidthOfView:loginBtn
                         ofWidth:[PEUIUtils valueIfiPhone5Width:0.85 iphone6Width:0.85 iphone6PlusWidth:0.70 ipad:0.65]
                      relativeTo:contentPanel];
  [loginBtn bk_addEventHandler:^(id sender) {
    [self presentLoginScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *loginCardPanel = [PEUIUtils panelWithWidthOf:0.925 relativeToView:contentPanel fixedHeight:0.0];
  [loginCardPanel setBackgroundColor:[UIColor whiteColor]];
  [PEUIUtils cardifyView:loginCardPanel];
  NSString *msgText = @"Already have a Riker account using email and a password?  Log in here.";
  UILabel *loginMsgLbl = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:msgText]
                                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                           backgroundColor:[UIColor clearColor]
                                                 textColor:[UIColor darkGrayColor]
                                       verticalTextPadding:3.0
                                                fitToWidth:loginBtn.frame.size.width];
  
  UIView *signUpCardPanel = [PEUIUtils panelWithWidthOf:0.925 relativeToView:contentPanel fixedHeight:0.0];
  [signUpCardPanel setBackgroundColor:[UIColor whiteColor]];
  [PEUIUtils cardifyView:signUpCardPanel];
  FBSDKLoginButton *facebookLoginButton = [self facebookLoginButton];
  [PEUIUtils setFrameWidthOfView:facebookLoginButton
                         ofWidth:[PEUIUtils valueIfiPhone5Width:0.85 iphone6Width:0.85 iphone6PlusWidth:0.70 ipad:0.65]
                      relativeTo:contentPanel];
  [PEUIUtils setFrameHeightOfView:facebookLoginButton ofHeight:1.65 relativeTo:facebookLoginButton];
  UILabel *orLabel = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:@"or"]
                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:signUpCardPanel.frame.size.width];
  UIButton *createAccountBtn = [PEUIUtils buttonWithKey:@"Sign up with email"
                                                   font:[PEUIUtils actionButtonFont]
                                        backgroundColor:[UIColor bootstrapPrimary]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:[PEUIUtils actionButtonVpadding]
                                      horizontalPadding:[PEUIUtils actionButtonHpadding]
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
  [PEUIUtils setFrameWidthOfView:createAccountBtn
                         ofWidth:[PEUIUtils valueIfiPhone5Width:0.85 iphone6Width:0.85 iphone6PlusWidth:0.70 ipad:0.65]
                      relativeTo:contentPanel];
  [createAccountBtn bk_addEventHandler:^(id sender) {
    [self presentSetupRemoteAccountScreen];
  } forControlEvents:UIControlEventTouchUpInside];
  msgText = @"Creating a Riker account will enable your records to be saved to the Riker server so you can access them from all your devices, including the web.  Sign up now for a free 90-day trial.";
  UILabel *createAcctMsgLbl = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:msgText]
                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:createAccountBtn.frame.size.width];
  CGFloat learnButtonVpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:20.0 iphone6PlusWidth:22.5 ipad:30.0];
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:34.0];
  UIButton *learnMoreBtn = [PEUIUtils buttonWithKey:@"Riker account benefits"
                                               font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                    backgroundColor:[UIColor whiteColor]
                                          textColor:[UIColor rikerAppBlack]
                       disabledStateBackgroundColor:nil
                             disabledStateTextColor:nil
                                    verticalPadding:learnButtonVpadding
                                  horizontalPadding:10.0
                                       cornerRadius:0.0
                                             target:nil
                                             action:nil];
  [PEUIUtils styleViewForIpad:learnMoreBtn];
  [learnMoreBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newRikerAccountBenefitsScreenMaker]()
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:learnMoreBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:learnMoreBtn];
  UIButton *afterTrialChoicesBtn = [PEUIUtils buttonWithKey:@"What happens after\nthe 90-day trial?"
                                                       font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                              font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                            backgroundColor:[UIColor whiteColor]
                                                  textColor:[UIColor rikerAppBlack]
                               disabledStateBackgroundColor:nil
                                     disabledStateTextColor:nil
                                            verticalPadding:learnButtonVpadding
                                          horizontalPadding:10.0
                                               cornerRadius:0.0
                                                     target:nil
                                                     action:nil];
  [PEUIUtils styleViewForIpad:afterTrialChoicesBtn];
  [afterTrialChoicesBtn bk_addEventHandler:^(id sender) {
    if ([PEUtils isNotNil:_subscriptionProduct]) {
      [[self navigationController] pushViewController:[_screenToolkit newAfterTrialOptionsPeriodScreenMakerWithSubscriptionProduct:_subscriptionProduct]()
                                             animated:YES];
    } else {
      _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      _hud.tag = RHUD_TAG;
      _hud.delegate = self;
      NSLog(@"about to fetch price info of identifier: [%@]", [APP iapRikerSubscriptionProductIdentifier]);
      SKProductsRequest *productsRequest =
      [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[[APP iapRikerSubscriptionProductIdentifier]]]];
      productsRequest.delegate = self;
      [productsRequest start];
    }
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:afterTrialChoicesBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:afterTrialChoicesBtn];  
  UIButton *useWithoutAccountBtn = [PEUIUtils buttonWithKey:@"Can I use Riker without\ncreating an account?"
                                                       font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                              font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                            backgroundColor:[UIColor whiteColor]
                                                  textColor:[UIColor rikerAppBlack]
                               disabledStateBackgroundColor:nil
                                     disabledStateTextColor:nil
                                            verticalPadding:learnButtonVpadding
                                          horizontalPadding:10.0
                                               cornerRadius:0.0
                                                     target:nil
                                                     action:nil];
  [PEUIUtils styleViewForIpad:useWithoutAccountBtn];
  [useWithoutAccountBtn bk_addEventHandler:^(id sender) {
    [[self navigationController] pushViewController:[_screenToolkit newUseRikerWithoutAccountScreenMaker]()
                                           animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:useWithoutAccountBtn ofWidth:1.0 relativeTo:contentPanel];
  [PEUIUtils addDisclosureIndicatorToButton:useWithoutAccountBtn];
  
  // place views onto panel
  CGFloat topPaddingMultiplier = 1.0;
  CGFloat topPadding = [RUIUtils contentPanelTopPadding] * topPaddingMultiplier;
  CGFloat vpadding = 16.0;
  [PEUIUtils placeView:loginBtn
               atTopOf:loginCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding + 4.0
              hpadding:0.0];
  CGFloat cardPanelHeight = loginBtn.frame.size.height + vpadding + 4.0;
  [PEUIUtils placeView:loginMsgLbl
                 below:loginBtn
                  onto:loginCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:8.0
              hpadding:0.0];
  cardPanelHeight += loginMsgLbl.frame.size.height + 8.0;
  cardPanelHeight += vpadding; // bottom margin
  [PEUIUtils setFrameHeight:cardPanelHeight ofView:loginCardPanel];
  
  vpadding = 16.0;
  [PEUIUtils placeView:facebookLoginButton
               atTopOf:signUpCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding + 4.0
              hpadding:0.0];
  cardPanelHeight = facebookLoginButton.frame.size.height + vpadding + 4.0;
  vpadding = 8.0;
  [PEUIUtils placeView:orLabel
                 below:facebookLoginButton
                  onto:signUpCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  cardPanelHeight += orLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:createAccountBtn
                 below:orLabel
                  onto:signUpCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  cardPanelHeight += createAccountBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:createAcctMsgLbl
                 below:createAccountBtn
                  onto:signUpCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:0.0];
  cardPanelHeight += createAcctMsgLbl.frame.size.height + vpadding;
  vpadding = 16.0;
  cardPanelHeight += vpadding; // bottom margin
  [PEUIUtils setFrameHeight:cardPanelHeight ofView:signUpCardPanel];
    
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:signUpCardPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:topPadding
              hpadding:0.0];
  totalHeight += signUpCardPanel.frame.size.height + topPadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:20.0 iphone6PlusWidth:25.0 ipad:30.0];
  [PEUIUtils placeView:loginCardPanel
                 below:signUpCardPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += loginCardPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:learnMoreBtn
                 below:loginCardPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += learnMoreBtn.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:10.0 iphone6PlusWidth:15.0 ipad:20.0];
  [PEUIUtils placeView:afterTrialChoicesBtn
                 below:learnMoreBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += afterTrialChoicesBtn.frame.size.height + vpadding;
  [PEUIUtils placeView:useWithoutAccountBtn
                 below:afterTrialChoicesBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += useWithoutAccountBtn.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(YES)];
}

#pragma mark - SKProductsRequestDelegate

- (void)handleInAppStoreProductFetchError {
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"In-App Store Unavailable."
                     alertDescription:AS(@"Pricing information could not be fetched because Apple's In-App Store is currently unavailable.\n\nPlease try again later.")
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
    [[self navigationController] pushViewController:[_screenToolkit newAfterTrialOptionsPeriodScreenMakerWithSubscriptionProduct:_subscriptionProduct]()
                                           animated:YES];
  } else {
    [self handleInAppStoreProductFetchError];
  }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
  if (error) {
    DDLogDebug(@"StoreKit request failed with error: %@", error);
    [[Crashlytics sharedInstance] recordError:error];
  }
  [_hud hideAnimated:YES];
  [self handleInAppStoreProductFetchError];
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
  [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:loginController
                                                                               navigationBarHidden:NO]
                                            animated:YES
                                          completion:nil];
}

#pragma mark - Present Account Creation screen

- (void)presentSetupRemoteAccountScreen {
  UIViewController *createAccountController =
  [[RCreateAccountController alloc] initWithStoreCoordinator:_coordDao
                                                   uitoolkit:_uitoolkit
                                               screenToolkit:_screenToolkit];
  [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:createAccountController
                                                                               navigationBarHidden:NO]
                                            animated:YES
                                          completion:nil];
}

#pragma mark - Logout

- (void)logout {
  [RUtils logoutWithController:self coordDao:_coordDao watchSessionDelegate:self isFbLogoutFromNotification:NO hudDelegate:self];
}

#pragma mark - Log Out All Other

- (void)logoutAllOther {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:self];
  __block MBProgressHUD *HUD;
  void (^successBlk)(void) = ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [HUD hideAnimated:YES];
      NSString *msg = @"Your other sessions have been logged out.";
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Success."
                         alertDescription:[[NSAttributedString alloc] initWithString:msg]
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 enableUserInteraction(YES);
                                 [self viewDidAppear:YES];
                               });
                             }
                           relativeToView:self.tabBarController.view];
    });
  };
  HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  HUD.tag = RHUD_TAG;
  enableUserInteraction(NO);
  HUD.delegate = self;
  HUD.label.text = @"Logging out all other sessions...";
  [_coordDao.userCoordinatorDao logoutAllOtherForUser:user
                                           successBlk:successBlk
                                   remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [HUD hideAnimated:YES afterDelay:0.0];
                                       [PEUIUtils showWaitAlertWithMsgs:nil
                                                                  title:@"Busy with maintenance."
                                                       alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try this again later."]
                                                    descLblHeightAdjust:0.0
                                              additionalContentSections:nil
                                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                            buttonTitle:@"Okay."
                                                           buttonAction:^{
                                                             enableUserInteraction(YES);
                                                           }
                                                         relativeToView:self.tabBarController.view];
                                     });
                                   }
                                   tempRemoteErrorBlk:^{
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [HUD hideAnimated:YES afterDelay:0.0];
                                       [PEUIUtils showErrorAlertWithMsgs:nil
                                                                   title:@"Something went wrong."
                                                        alertDescription:[[NSAttributedString alloc] initWithString:@"\
Oops.  Something went wrong in attempting to log out your other sessions."]
                                                     descLblHeightAdjust:0.0
                                                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                             buttonTitle:@"Okay."
                                                            buttonAction:^{ enableUserInteraction(YES); }
                                                          relativeToView:self.tabBarController.view];
                                     });
                                   }
                                  addlAuthRequiredBlk:^{
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      [HUD hideAnimated:YES afterDelay:0.0];
                                      [PEUIUtils showErrorAlertWithMsgs:nil
                                                                  title:@"Oops."
                                                       alertDescription:[PEUIUtils attributedTextWithTemplate:@"Sorry, but in attempting to log out your other sessions, it appears you're not currently authenticated on this device.  To re-authenticate, go to:\n\n%@.\n\nThen come back here and try this again."
                                                                                                 textToAccent:@"Account \u2794 Re-authenticate"
                                                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                    descLblHeightAdjust:0.0
                                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                            buttonTitle:@"Okay."
                                                           buttonAction:^{
                                                             enableUserInteraction(YES);
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                                 object:nil
                                                                                                               userInfo:nil];
                                                             [APP refreshTabs];
                                                             [self setNeedsRepaint:YES];
                                                             [self viewDidAppear:YES];
                                                           }
                                                         relativeToView:self.tabBarController.view];
                                    });
                                  }];
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
