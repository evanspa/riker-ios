//
//  RReauthenticateController.m
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RReauthenticateController.h"
#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import "RCoordinatorDao.h"
#import "PELMUser.h"
#import "PEUIToolkit.h"
#import "PEUIUtils.h"
#import "RErrorDomainsAndCodes.h"
#import "RUIUtils.h"
#import "RUtils.h"
#import "RAppNotificationNames.h"
#import "RPanelToolkit.h"
#import "AppDelegate.h"
#import "PELocalDao.h"
@import Firebase;

@interface RReauthenticateController ()
@property (nonatomic) NSInteger formStateMaskForLightLogin;
@end

@implementation RReauthenticateController {
  id<RCoordinatorDao> _coordDao;
  UITextField *_passwordTf;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RACDisposable *_disposable;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Re-authenticate"];
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
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleLightLogin)]];
  [_passwordTf becomeFirstResponder];
  [_passwordTf setDelegate:self];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0;
  UILabel *messageLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Enter your password and hit %@ to re-authenticate."
                                                                                     textToAccent:@"Done"
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                       font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                   fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:(contentPanel.frame.size.width - 15.0)];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]];
  CGFloat commonTfHeight = [PEUIUtils heightForUserAccountTextfields];
  _passwordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_passwordTf setSecureTextEntry:YES];
  if (@available(iOS 11.0, *)) {
    [_passwordTf setTextContentType:UITextContentTypePassword];
  }
  [_passwordTf setFont:font];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_passwordTf];
  [_passwordTf setReturnKeyType:UIReturnKeyDone];
  [_disposable dispose];
  RACSignal *signal = [RACSignal combineLatest:@[_passwordTf.rac_textSignal]
                                        reduce:^(NSString *password) {
                                          NSUInteger reauthErrMask = 0;
                                          if ([password length] == 0) {
                                            reauthErrMask = reauthErrMask | RSignInPasswordNotProvided | RSignInAnyIssues;
                                          }
                                          return @(reauthErrMask);
                                        }];
  _disposable = [signal setKeyPath:@"formStateMaskForLightLogin" onObject:self nilValue:nil];

  // place views
  [PEUIUtils placeView:_passwordTf
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = _passwordTf.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:messageLabelWithPad
                 below:_passwordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messageLabelWithPad.frame.size.height + 4.0;
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  UIView *forgotPasswordBtn = [RPanelToolkit forgotPasswordButtonForUser:user coordinatorDao:_coordDao uitoolkit:_uitoolkit controller:self];
  [PEUIUtils placeView:forgotPasswordBtn
                 below:messageLabelWithPad
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:leftPadding];
  totalHeight += forgotPasswordBtn.frame.size.height + 20.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_passwordTf resignFirstResponder];
  [self handleLightLogin];
  return YES;
}

#pragma mark - Login event handling

- (void)handleLightLogin {
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:self];
  [[self view] endEditing:YES];
  if (!([self formStateMaskForLightLogin] & RSignInAnyIssues)) {
    __block MBProgressHUD *HUD;
    void (^nonLocalSyncSuccessBlk)(void) = ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hideAnimated:YES];
        NSString *msg = @"You're authenticated again.";
        [PEUIUtils showSuccessAlertWithMsgs:nil
                                      title:@"Success."
                           alertDescription:[[NSAttributedString alloc] initWithString:msg]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 enableUserInteraction(YES);
                                 [[self navigationController] popViewControllerAnimated:YES];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthNotification object:nil userInfo:nil];
                               }
                             relativeToView:self.tabBarController.view];
      });
    };
    ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
      return [RUtils computeSignInErrMsgs:errCode];
    };
    void (^doLightLogin)(BOOL) = ^(BOOL syncLocalEntities) {
      void (^successBlk)(void) = nil;
      if (syncLocalEntities) {
        successBlk = ^{
          dispatch_async(dispatch_get_main_queue(), ^{
            HUD.label.text = @"Proceeding to sync data data records...";
            HUD.mode = MBProgressHUDModeDeterminate;
            __block NSInteger numEntitiesSynced = 0;
            __block BOOL receivedUnauthedError = NO;
            __block NSInteger syncAttemptErrors = 0;
            __block float overallSyncProgress = 0.0;
            PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
            [_coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                          entityNotFoundBlk:^(float progress) {
                                            [RUtils logEvent:@"entity_not_found_wh_reauth_syncing"];
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              syncAttemptErrors++;
                                              overallSyncProgress += progress;
                                              [HUD setProgress:overallSyncProgress];
                                            });
                                          }
                                                 successBlk:^(float progress) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                     numEntitiesSynced++;
                                                     overallSyncProgress += progress;
                                                     [HUD setProgress:overallSyncProgress];
                                                   });
                                                 }
                                         remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                           [RUtils logEvent:@"busy_wh_reauth_syncing"];
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                             syncAttemptErrors++;
                                             overallSyncProgress += progress;
                                             [HUD setProgress:overallSyncProgress];
                                           });
                                         }
                                         tempRemoteErrorBlk:^(float progress) {
                                           [RUtils logEvent:@"tmp_remote_err_wh_reauth_syncing"];
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                             syncAttemptErrors++;
                                             overallSyncProgress += progress;
                                             [HUD setProgress:overallSyncProgress];
                                           });
                                         }
                                             remoteErrorBlk:^(float progress, NSInteger errMask) {
                                               [RUtils logEvent:@"remote_err_wh_reauth_syncing"
                                                                   params:[RUtils eventLogParamsWithErrMask:errMask]];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 syncAttemptErrors++;
                                                 overallSyncProgress += progress;
                                                 [HUD setProgress:overallSyncProgress];
                                               });
                                             }                                               
                                            authRequiredBlk:^(float progress) {
                                              [RUtils logEvent:@"auth_reqd_wh_reauth_syncing"];
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                overallSyncProgress += progress;
                                                receivedUnauthedError = YES;
                                                [HUD setProgress:overallSyncProgress];
                                              });
                                            }
                                               forbiddenBlk:^(float progress) {
                                                 [RUtils logEvent:@"forbidden_wh_reauth_syncing"];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   overallSyncProgress += progress;
                                                   receivedUnauthedError = YES;
                                                   [HUD setProgress:overallSyncProgress];
                                                 });
                                               }
                                                    allDone:^(NSInteger numImportedSetsNotSyncedDueToNotAllowed,
                                                              NSInteger numImportedSetsNotSyncedDueToMaxExceeded,
                                                              NSInteger numImportedBmlsNotSyncedDueToNotAllowed,
                                                              NSInteger numImportedBmlsNotSyncedDueToMaxExceeded) {
                                                      //[RUtils analyticsInitializeUserWithCoordDao:_coordDao];
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        NSArray *notImportedAlertSections = [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                                                          numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                                                           numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                                                          numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                                                        controller:self];
                                                        [APP refreshTabs];
                                                        if (syncAttemptErrors == 0 && !receivedUnauthedError) { // 100% no errors
                                                          [HUD hideAnimated:YES];
                                                          NSString *desc;
                                                          if (numEntitiesSynced > 0) {
                                                            if (notImportedAlertSections.count > 0) {
                                                              [RUtils logEvent:@"some_synced_wh_reauth_syncing" params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                              desc = @"You have become authenticated again, but not all of your unsynced records could be synced to your account.  See below for details.";
                                                            } else {
                                                              [RUtils logEvent:@"all_synced_wh_reauth_syncing" params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                              desc = @"You have become authenticated again and your records have been synced to your account.";
                                                            }
                                                          } else if (notImportedAlertSections.count > 0) {
                                                            [RUtils logEvent:@"none_could_sync_wh_reauth_syncing" params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                            desc = @"You have become authenticated again, but your unsynced records could not be synced to your account.  See below for details.";
                                                          } else {
                                                            desc = @"You have become authenticated again.";
                                                          }
                                                          [PEUIUtils showSuccessAlertWithMsgs:nil
                                                                                        title:@"Authentication Success."
                                                                             alertDescription:[[NSAttributedString alloc] initWithString:desc]
                                                                          descLblHeightAdjust:0.0
                                                                    additionalContentSections:notImportedAlertSections
                                                                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                  buttonTitle:@"Okay."
                                                                                 buttonAction:^{
                                                                                   enableUserInteraction(YES);
                                                                                   [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthNotification object:nil userInfo:nil];
                                                                                   [[self navigationController] popViewControllerAnimated:YES];
                                                                                 }
                                                                               relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                        } else {
                                                          [HUD hideAnimated:YES];
                                                          NSString *title = @"Sync problems.";
                                                          NSString *message = @"Although you became authenticated, there were some problems syncing all your local edits.";
                                                          NSMutableArray *sections = [NSMutableArray array];
                                                          JGActionSheetSection *becameUnauthSection = nil;
                                                          if (receivedUnauthedError) {
                                                            [RUtils logEvent:@"auth_reqd_wh_reauth"];
                                                            NSAttributedString *attrBecameUnauthMessage =
                                                            [PEUIUtils attributedTextWithTemplate:@"This is awkward.  While syncing your local edits, the  Riker server is asking for you to \
authenticate again.  To authenticate, tap the %@ button."
                                                                                     textToAccent:@"Re-authenticate"
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                            becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                   title:@"Authentication Failure."
                                                                                                        alertDescription:attrBecameUnauthMessage
                                                                                                     descLblHeightAdjust:0.0
                                                                                                          relativeToView:self.tabBarController.view];
                                                          }
                                                          JGActionSheetSection *successSection = [PEUIUtils successAlertSectionWithMsgs:nil
                                                                                                                                  title:@"Authentication Success."
                                                                                                                       alertDescription:[[NSAttributedString alloc] initWithString:@"You have become authenticated again."]
                                                                                                                    descLblHeightAdjust:0.0
                                                                                                                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                                          JGActionSheetSection *warningSection = nil;
                                                          if (syncAttemptErrors > 0) {
                                                            [RUtils logEvent:@"sync_errors_wh_reauth_syncing"
                                                                                params:[RUtils eventLogParamsWithSyncAttemptErrors:syncAttemptErrors]];
                                                            warningSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                              title:title
                                                                                                   alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                descLblHeightAdjust:0.0
                                                                                                     relativeToView:self.tabBarController.view];
                                                          }
                                                          JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                                message:nil
                                                                                                                           buttonTitles:@[@"Okay."]
                                                                                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                                                          if (!receivedUnauthedError) {                                                            
                                                            [sections addObject:successSection];
                                                          }
                                                          if (warningSection) {
                                                            [sections addObject:warningSection];
                                                          }
                                                          if (becameUnauthSection) {
                                                            [sections addObject:becameUnauthSection];
                                                          }
                                                          [sections addObjectsFromArray:notImportedAlertSections];
                                                          [sections addObject:buttonsSection];
                                                          JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                          //[RUtils analyticsInitializeUserWithCoordDao:_coordDao];
                                                          [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                            enableUserInteraction(YES);
                                                            [sheet dismissAnimated:YES];
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthNotification object:nil userInfo:nil];
                                                            [[self navigationController] popViewControllerAnimated:YES];
                                                          }];
                                                          [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
                                                        }
                                                      });
                                                    }
                                                      error:[RUtils localDatabaseErrorHudHandlerMaker](HUD, self, self.tabBarController.view)];
          });
        };
      } else {
        successBlk = nonLocalSyncSuccessBlk;
      }
      HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.tag = RHUD_TAG;
      enableUserInteraction(NO);
      HUD.delegate = self;
      HUD.label.text = @"Re-authenticating...";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao.userCoordinatorDao lightLoginForUser:user
                                             password:[_passwordTf text]
                                      remoteStoreBusy:[RUtils serverBusyHandlerMakerForUIWithButtonAction:^{enableUserInteraction(YES);}](HUD, self, self.tabBarController.view)
                                    completionHandler:^(NSError *err) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        if (err) {
                                          enableUserInteraction(YES);
                                        }
                                        [RUtils loginHandlerWithErrMsgsMaker:errMsgsMaker](HUD,
                                                                                           successBlk,
                                                                                           ^{ enableUserInteraction(YES); },
                                                                                           self,
                                                                                           self.tabBarController.view)(err);
                                      });
                                    }
                                localSaveErrorHandler:[RUtils localDatabaseErrorHudHandlerMaker](HUD, self, self.tabBarController.view)];
    };
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    doLightLogin([_coordDao doesUserHaveAnyUnsyncedEntities:user] || [_coordDao isUserSettingsUnsynced:user]);
  } else {
    NSArray *errMsgs = [RUtils computeSaveUsrErrMsgs:_formStateMaskForLightLogin];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:self.tabBarController.view];
  }
}

@end
