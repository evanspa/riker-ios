//
//  RAccountLoginController.m
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RAccountLoginController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "PELMUser.h"
#import "RScreenToolkit.h"
#import "RUIUtils.h"
#import "RPanelToolkit.h"
#import "PEUtils.h"
#import "RErrorDomainsAndCodes.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "PEUIUtils.h"
#import "RAppNotificationNames.h"
#import "RLogging.h"
#import "PELocalDao.h"
#import "RUserSettings.h"
@import Firebase;
@import WatchConnectivity;

typedef NS_ENUM (NSInteger, RLoginTag) {
  RLoginTagEmail = 1,
  RloginTagPassword
};

@interface RAccountLoginController ()
@property (nonatomic) NSUInteger formStateMaskForSignIn;
@end

@implementation RAccountLoginController {
  id<RCoordinatorDao> _coordDao;
  UITextField *_emailTf;
  UITextField *_passwordTf;
  UIButton *_signInBtn;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  NSNumber *_preserveExistingLocalEntities;
  BOOL _receivedAuthReqdErrorOnSyncAttempt;
  RACDisposable *_disposable;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Account Log In"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(handleCancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Log In"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(handleSignIn)]];
  _preserveExistingLocalEntities = nil;
  [_passwordTf setDelegate:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_passwordTf resignFirstResponder];
  [self handleSignIn];
  return YES;
}

#pragma mark - GUI helpers

- (UIView *)parentViewForAlerts {
  return [PEUIUtils parentViewForAlertsForController:self];
}

- (void)handleSupportEmailClicked {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [APP rikerSupportEmail]]]
                                     options:@{}
                           completionHandler:nil];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  CGFloat leftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UILabel *signInMsgLabel = [PEUIUtils labelWithKey:@"From here you can log into your \
Riker account, connecting this device to it.  Your Riker data will be downloaded to this device."
                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  UIView *signInMsgPanel = [PEUIUtils leftPadView:signInMsgLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]];
  CGFloat commonTfHeight = [PEUIUtils heightForUserAccountTextfields];
  _emailTf = tfMaker(@"unauth.start.signin.emailtf.pht");
  [_emailTf setTag:RLoginTagEmail];
  [_emailTf setKeyboardType:UIKeyboardTypeEmailAddress];
  [_emailTf setFont:font];
  [_emailTf setTextContentType:UITextContentTypeEmailAddress];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_emailTf];
  _passwordTf = tfMaker(@"unauth.start.signin.pwdtf.pht");
  [_passwordTf setSecureTextEntry:YES];
  if (@available(iOS 11.0, *)) {
    [_emailTf setTextContentType:UITextContentTypeUsername];
    [_passwordTf setTextContentType:UITextContentTypePassword];
  }
  [_passwordTf setReturnKeyType:UIReturnKeyGo];
  [_passwordTf setTag:RloginTagPassword];
  [_passwordTf setFont:font];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_passwordTf];
  if (existingContentPanel) {
    [_emailTf setText:[(UITextField *)[existingContentPanel viewWithTag:RLoginTagEmail] text]];
    [_passwordTf setText:[(UITextField *)[existingContentPanel viewWithTag:RloginTagPassword] text]];
  }
  UILabel *instructionLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Enter your credentials and tap %@."
                                                                                         textToAccent:@"Log In"
                                                                                       accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  [PEUIUtils setFrameWidthOfView:instructionLabel ofWidth:1.05 relativeTo:instructionLabel];
  UIView *instructionPanel = [PEUIUtils leftPadView:instructionLabel padding:leftPadding];
  UIView *forgotPwdBtn = [RPanelToolkit forgotPasswordButtonForUser:nil coordinatorDao:_coordDao uitoolkit:_uitoolkit controller:self];
  UILabel *havingTroubleLabel = [PEUIUtils labelWithAttributeText:AS(@"Having trouble logging in?  Drop us a line at:")
                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor darkGrayColor]
                                              verticalTextPadding:3.0
                                                       fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  UIButton *rikerSupportEmailLabel = [PEUIUtils buttonWithKey:[APP rikerSupportEmail]
                                                         font:[RUIUtils rikerSupportEmailFont]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor bootstrapPrimary]
                                 disabledStateBackgroundColor:[UIColor clearColor]
                                       disabledStateTextColor:[UIColor clearColor]
                                              verticalPadding:3.0
                                            horizontalPadding:0.0
                                                 cornerRadius:0.0
                                                       target:nil
                                                       action:nil];
  [rikerSupportEmailLabel bk_addEventHandler:^(id sender) {
    [RUtils contactRikerSupport];
  } forControlEvents:UIControlEventTouchUpInside];

  // place views
  [PEUIUtils placeView:signInMsgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = signInMsgPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:_emailTf
                 below:signInMsgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0.0];
  totalHeight += _emailTf.frame.size.height + 7.0;
  [PEUIUtils placeView:_passwordTf
                 below:_emailTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:0.0];
  totalHeight += _passwordTf.frame.size.height + 5.0;
  [PEUIUtils placeView:instructionPanel
                 below:_passwordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += instructionPanel.frame.size.height + 4.0;
  [PEUIUtils placeView:forgotPwdBtn
                 below:instructionPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:leftPadding];
  totalHeight += forgotPwdBtn.frame.size.height + 20.0;
  [PEUIUtils placeView:havingTroubleLabel
                 below:forgotPwdBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:leftPadding];
  totalHeight += havingTroubleLabel.frame.size.height + 20.0;
  [PEUIUtils placeView:rikerSupportEmailLabel
                 below:havingTroubleLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:4.0
              hpadding:leftPadding];
  totalHeight += rikerSupportEmailLabel.frame.size.height + 4.0;
   [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];

  [_disposable dispose];
  RACSignal *signal = [RACSignal combineLatest:@[_emailTf.rac_textSignal,
                                                 _passwordTf.rac_textSignal]
                                        reduce:^(NSString *email,
                                                 NSString *password) {
                                          NSString *trimmedEmail = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                          NSUInteger signInErrMask = 0;
                                          if ([trimmedEmail length] == 0) {
                                            signInErrMask = RSignInEmailNotProvided | RSignInAnyIssues;
                                          } else if (![PEUtils validateEmailWithString:trimmedEmail]) {
                                            signInErrMask = signInErrMask | RSignInInvalidEmail | RSignInAnyIssues;
                                          }
                                          if ([password length] == 0) {
                                            signInErrMask = signInErrMask | RSignInPasswordNotProvided | RSignInAnyIssues;
                                          }
                                          return @(signInErrMask);
                                        }];
  _disposable = [signal setKeyPath:@"formStateMaskForSignIn" onObject:self nilValue:nil];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Login event handling

- (void)handleCancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSignIn {
  REnableUserInteractionBlk enableUserInteraction = [self makeUserEnabledBlock];
  [[self view] endEditing:YES];
  if (!([self formStateMaskForSignIn] & RSignInAnyIssues)) {
    __block MBProgressHUD *HUD;
    void (^commonSuccessBlk)(void) = ^{
      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];      
      [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
      [RUtils logEvent:kFIREventLogin];
    };
    void (^nonLocalSyncSuccessBlk)(void) = ^{
      commonSuccessBlk();
      [HUD hideAnimated:YES];
      [PEUIUtils showSuccessAlertWithTitle:@"Login success."
                          alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in.\n\nYour Riker account is now connected to this device.  \
Any Riker data that you create and save will be synced to your account."]
                       descLblHeightAdjust:0.0
                  additionalContentSection:[RPanelToolkit watchReminderAlertSectionRelativeToView:[self parentViewForAlerts]]
                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                               buttonTitle:@"Okay."
                              buttonAction:^{
                                enableUserInteraction(YES);
                                [[NSNotificationCenter defaultCenter] postNotificationName:RAppLoginNotification
                                                                                    object:nil
                                                                                  userInfo:nil];
                                [self dismissViewControllerAnimated:YES completion:nil];
                              }
                            relativeToView:[self parentViewForAlerts]];
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [RUtils computeSignInErrMsgs:errCode];
    };
    void (^doLogin)(BOOL) = ^ (BOOL syncLocalEntities) {
      _receivedAuthReqdErrorOnSyncAttempt = NO;
      void (^successBlk)(void) = nil;
      if (syncLocalEntities) {
        successBlk = ^{
          HUD.label.text = @"You're now logged in.";
          HUD.detailsLabel.text = @"Proceeding to sync data records...";
          HUD.mode = MBProgressHUDModeDeterminate;
          __block NSInteger numEntitiesSynced = 0;
          __block NSInteger syncAttemptErrors = 0;
          __block float overallSyncProgress = 0.0;
          PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
          [_coordDao checkLocalEntityGlobalIdsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
          commonSuccessBlk();
          [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                        entityNotFoundBlk:^(float progress) {
                                          [RUtils logEvent:@"entity_not_found_wh_login_syncing"];
                                          syncAttemptErrors++;
                                          overallSyncProgress += progress;
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [HUD setProgress:overallSyncProgress];
                                          });
                                        }
                                               successBlk:^(float progress) {
                                                 numEntitiesSynced++;
                                                 overallSyncProgress += progress;
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   [HUD setProgress:overallSyncProgress];
                                                 });
                                               }
                                       remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                         [RUtils logEvent:@"busy_wh_login_syncing"];
                                         syncAttemptErrors++;
                                         overallSyncProgress += progress;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [HUD setProgress:overallSyncProgress];
                                         });
                                       }
                                       tempRemoteErrorBlk:^(float progress) {
                                         [RUtils logEvent:@"tmp_remote_err_wh_login_syncing"];
                                         syncAttemptErrors++;
                                         overallSyncProgress += progress;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [HUD setProgress:overallSyncProgress];
                                         });
                                       }
                                           remoteErrorBlk:^(float progress, NSInteger errMask) {
                                             [RUtils logEvent:@"remote_err_wh_login_syncing"
                                                       params:[RUtils eventLogParamsWithErrMask:errMask]];
                                             syncAttemptErrors++;
                                             overallSyncProgress += progress;
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                               [HUD setProgress:overallSyncProgress];
                                             });
                                           }                                              
                                          authRequiredBlk:^(float progress) {
                                            [RUtils logEvent:@"auth_reqd_wh_login_syncing"];
                                            syncAttemptErrors++;
                                            overallSyncProgress += progress;
                                            _receivedAuthReqdErrorOnSyncAttempt = YES;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [HUD setProgress:overallSyncProgress];
                                            });
                                          }
                                             forbiddenBlk:^(float progress) {
                                               [RUtils logEvent:@"forbidden_wh_login_syncing"];
                                               syncAttemptErrors++;
                                               overallSyncProgress += progress;
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [HUD setProgress:overallSyncProgress];
                                               });
                                             }
                                                  allDone:^(NSInteger numImportedSetsNotSyncedDueToNotAllowed,
                                                            NSInteger numImportedSetsNotSyncedDueToMaxExceeded,
                                                            NSInteger numImportedBmlsNotSyncedDueToNotAllowed,
                                                            NSInteger numImportedBmlsNotSyncedDueToMaxExceeded) {
                                                    if (syncAttemptErrors == 0) {
                                                      // 100% sync success
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSMutableArray *notImportedAlertSections =
                                                        [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                      numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                       numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                      numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                    controller:self];
                                                        [HUD hideAnimated:YES];
                                                        if (numEntitiesSynced > 0) {
                                                          [RUtils logEvent:@"all_synced_wh_login_syncing"
                                                                              params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                          JGActionSheetSection *watchInfoSection = [RPanelToolkit watchReminderAlertSectionRelativeToView:[self parentViewForAlerts]];
                                                          if (watchInfoSection) {
                                                            [notImportedAlertSections addObject:watchInfoSection];
                                                          }
                                                          //[RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
                                                          [PEUIUtils showSuccessAlertWithTitle:@"Login & sync success."
                                                                              alertDescription:[[NSAttributedString alloc] initWithString:@"\
You have been successfully logged in and your local edits have been synced.\n\nYour account is now connected to \
this device.  Any Riker data that you create and save will be synced to your account."]
                                                                           descLblHeightAdjust:0.0
                                                                     additionalContentSections:notImportedAlertSections
                                                                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                   buttonTitle:@"Okay."
                                                                                  buttonAction:^{
                                                                                    enableUserInteraction(YES);
                                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:RAppLoginNotification
                                                                                                                                        object:nil
                                                                                                                                      userInfo:nil];
                                                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                                                    [APP refreshTabs];
                                                                                  }
                                                                                relativeToView:[self parentViewForAlerts]];
                                                        } else {
                                                          // if no records synced, and we got no errors, then, the only possibility (I think, right?) is that
                                                          // the user had imported records to be synced, but they couldn't because the user is either not
                                                          // allowed (unverified email) or they've exceeded their import limit.
                                                          [RUtils logEvent:@"none_could_sync_wh_login_syncing"
                                                                              params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                          NSMutableArray *sections = [NSMutableArray array];
                                                          [sections addObjectsFromArray:notImportedAlertSections];
                                                          JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                                message:nil
                                                                                                                           buttonTitles:@[@"Okay."]
                                                                                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                                                          [sections addObject:buttonsSection];
                                                          JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                          [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                            enableUserInteraction(YES);
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:RAppLoginNotification
                                                                                                                object:nil
                                                                                                              userInfo:nil];
                                                            [self dismissViewControllerAnimated:YES completion:nil];
                                                            [APP refreshTabs];
                                                          }];
                                                          [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
                                                        }
                                                      });
                                                    } else {
                                                      [RUtils logEvent:@"sync_errors_wh_login_syncing"
                                                                          params:[RUtils eventLogParamsWithSyncAttemptErrors:syncAttemptErrors]];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSArray *notImportedAlertSections = [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                                                          numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                                                           numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                                                          numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                                                        controller:self];
                                                        [HUD hideAnimated:YES];
                                                        NSString *title = @"Sync problems.";
                                                        NSString *message = @"There were some problems syncing all of your local edits.  You can try syncing them later.";
                                                        JGActionSheetSection *becameUnauthSection = nil;
                                                        if (_receivedAuthReqdErrorOnSyncAttempt) {
                                                          NSAttributedString *attrBecameUnauthMessage =
                                                          [PEUIUtils attributedTextWithTemplate:@"This is awkward.  While syncing your local \
edits, the Riker server is asking for you to authenticate again.  To authenticate, tap the %@ button."
                                                                                   textToAccent:@"Re-authenticate"
                                                                                 accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                          becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                 title:@"Authentication Failure."
                                                                                                      alertDescription:attrBecameUnauthMessage
                                                                                                   descLblHeightAdjust:0.0
                                                                                                        relativeToView:[self parentViewForAlerts]];
                                                        }
                                                        JGActionSheetSection *contentSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                                title:title
                                                                                                                     alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                                  descLblHeightAdjust:0.0
                                                                                                                       relativeToView:[self parentViewForAlerts]];
                                                        JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                              message:nil
                                                                                                                         buttonTitles:@[@"Okay."]
                                                                                                                          buttonStyle:JGActionSheetButtonStyleDefault];
                                                        JGActionSheet *alertSheet;
                                                        NSMutableArray *sections = [NSMutableArray array];
                                                        [sections addObject:contentSection];
                                                        if (becameUnauthSection) {
                                                          [sections addObject:becameUnauthSection];
                                                        }
                                                        [sections addObjectsFromArray:notImportedAlertSections];
                                                        [sections addObject:buttonsSection];
                                                        alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                        [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                          [sheet dismissAnimated:YES];
                                                          enableUserInteraction(YES);
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:RAppLoginNotification
                                                                                                              object:nil
                                                                                                            userInfo:nil];
                                                          //[[self navigationController] popViewControllerAnimated:YES];
                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                        }];
                                                        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                                                        [alertSheet showInView:[self parentViewForAlerts] animated:YES];
                                                        [APP refreshTabs];
                                                      });
                                                    }
                                                  }
                                                    error:^(NSError *err, int code, NSString *desc) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        [RUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])(err, code, desc);
                                                      });
                                                    }];
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.delegate = self;
      HUD.tag = RHUD_TAG;
      HUD.label.text = @"Logging in...";
      enableUserInteraction(NO);
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao.userCoordinatorDao loginWithEmail:[[_emailTf text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                          password:[_passwordTf text]
                      andLinkRemoteUserToLocalUser:user
                     preserveExistingLocalEntities:syncLocalEntities
                                   remoteStoreBusy:^(NSDate *retryAfter) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [HUD hideAnimated:YES];
                                       [PEUIUtils showWaitAlertWithMsgs:nil
                                                                  title:@"Server undergoing maintenance."
                                                       alertDescription:[[NSAttributedString alloc] initWithString:@"We apologize, but the Riker server is currently \
busy undergoing maintenance.  Please try logging in a little later."]
                                                    descLblHeightAdjust:0.0
                                              additionalContentSections:nil
                                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                            buttonTitle:@"Okay."
                                                           buttonAction:^{
                                                             enableUserInteraction(YES);
                                                           }
                                                         relativeToView:[self parentViewForAlerts]];
                                     });
                                   }
                                 completionHandler:^(PELMUser *user, NSError *err) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     [RUtils loginHandlerWithErrMsgsMaker:errMsgsMaker](HUD,
                                                                                        successBlk,
                                                                                        ^{ enableUserInteraction(YES); },
                                                                                        self,
                                                                                        [self parentViewForAlerts])(err);
                                     if (user) {
                                       NSDate *mostRecentUpdatedAt =
                                       [_coordDao mostRecentMasterUpdateForUser:user
                                                                          error:[RUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])];
                                       DDLogDebug(@"in RAccountLoginController/handleSignIn, login success, mostRecentUpdatedAt: [%@](%@)", mostRecentUpdatedAt, [PEUtils millisecondsFromDate:mostRecentUpdatedAt]);
                                       if (mostRecentUpdatedAt) {
                                         [APP setChangelogUpdatedAt:mostRecentUpdatedAt];
                                       }
                                     }
                                   });
                                 }
                             localSaveErrorHandler:[RUtils localDatabaseErrorHudHandlerMaker](HUD, self, [self parentViewForAlerts])];
    };
    if (_preserveExistingLocalEntities == nil) { // first time asked
      NSString *msg;
      NSString *syncEmButtonTitle;
      NSString *dontSyncButtonTitle;
      BOOL hasSyncable = NO;
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      if ([_coordDao numUnsyncedBmlsForUser:user] > 0 ||
          [_coordDao numUnsyncedSetsForUser:user] > 0) {
        hasSyncable = YES;
        // we'll just assume they'll want their profile & settings synced too
        msg = @"You've edited some records locally. Would you like them to be synced to your \
account upon logging in, or would you like them to be deleted?";
        syncEmButtonTitle = @"Yes.  Sync them to my account.";
        dontSyncButtonTitle = @"No.  Just delete them.";
      }    
      if (hasSyncable) {
        JGActionSheetSection *contentSection = [PEUIUtils questionAlertSectionWithTitle:@"Local edits."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                    descLblHeightAdjust:0.0
                                                                         relativeToView:[self parentViewForAlerts]];
        JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                              message:nil
                                                                         buttonTitles:@[syncEmButtonTitle,
                                                                                        dontSyncButtonTitle]
                                                                          buttonStyle:JGActionSheetButtonStyleDefault];
        [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
        JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
        [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
          switch ([indexPath row]) {
            case 0:  // sync them
              _preserveExistingLocalEntities = [NSNumber numberWithBool:YES];
              doLogin(YES);
              break;
            case 1:  // delete them
              _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
              doLogin(NO);
              break;
          }
          [sheet dismissAnimated:YES];
        }];
        [alertSheet showInView:[self parentViewForAlerts] animated:YES];
      } else {
        _preserveExistingLocalEntities = [NSNumber numberWithBool:NO];
        doLogin(NO);
      }
    } else {
      doLogin([_preserveExistingLocalEntities boolValue]);
    }
  } else {
    NSArray *errMsgs = [RUtils computeSignInErrMsgs:_formStateMaskForSignIn];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:[self parentViewForAlerts]];
  }
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
