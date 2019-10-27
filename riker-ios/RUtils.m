//
//  RUtils.m
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RUtils.h"
@import HealthKit;
#import <CommonCrypto/CommonCrypto.h>
#import <DateTools/DateTools.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "NSDate+RAdditions.h"
#import "AppDelegate.h"
#import "RErrorDomainsAndCodes.h"
#import "PEUIUtils.h"
#import "RLogging.h"
#import "PEUtils.h"
#import "PELMModelSupport.h"
#import "RMovementVariant.h"
@import Firebase;
#import "PELMUser.h"
#import "RUserSettings.h"
#import "RCoordinatorDao.h"
#import "PELocalDao.h"
#import "RSet.h"
#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMovement.h"
#import "RChartStrengthRawData.h"
#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedLineChartDataEntry.h"
#import "RChartBodyRawData.h"
#import "RBodyMeasurementLog.h"
#import "RWatchUtils.h"
#import <sys/utsname.h>
#import "NSString+PEAdditions.h"
#import "RAppNotificationNames.h"
#import "RWorkout.h"
#import "RUIUtils.h"
#import "PEBaseController.h"
#import "RRawLineDataPointTuple.h"
#import "RPieSliceDataTuple.h"
#import "RRawLineDataPointsByDateTuple.h"
#import "RNormalizedTimeSeriesTuple.h"
@import Crashlytics;
#import "RPanelToolkit.h"
#import <Toast/UIView+Toast.h>
#import "UIWindow+RAdditions.h"

NSInteger  const LBS_ID = 0;
NSString * const LBS_NAME = @"lbs";

NSInteger  const KG_ID = 1;
NSString * const KG_NAME = @"kg";

NSInteger const  INCHES_ID = 0;
NSString * const INCHES_NAME = @"in";

NSString * const GENDER_MALE = @"male";
NSInteger const GENDER_MALE_VAL = 1;

NSString * const GENDER_FEMALE = @"female";
NSInteger const GENDER_FEMALE_VAL = 0;

NSInteger const  CM_ID = 1;
NSString * const CM_NAME = @"cm";

NSInteger const DEFAULT_MOVEMENT_ID = 0; // Bench press
NSInteger const DEFAULT_MOVEMENT_VARIANT_ID = 1; // Barbell

NSInteger const DEFAULT_WEIGHT_UNITS = 0; // 0=lb, 1=kg
NSInteger const DEFAULT_SIZE_UNITS = 0; // 0=in, 1=cm
NSInteger const DEFAULT_WEIGHT_INC_DEC_AMOUNT = 5;

NSInteger const ORIGINATION_DEVICE_ID_WEB = 1;
NSInteger const ORIGINATION_DEVICE_ID_PEBBLE = 2;
NSInteger const ORIGINATION_DEVICE_ID_IPHONE = 3;
NSInteger const ORIGINATION_DEVICE_ID_IPAD = 4;
NSInteger const ORIGINATION_DEVICE_ID_APPLE_WATCH = 5;
NSInteger const ORIGINATION_DEVICE_ID_ANDROID_WEAR = 6;
NSInteger const ORIGINATION_DEVICE_ID_ANDROID = 7;

NSString * const DATE_PATTERN     = @"MM/dd/yyyy";
NSString * const DATETIME_PATTERN = @"MM/dd/yyyy h:mm:ss a"; //@"MM/dd/yyyy HH:mm:ss";

NSInteger const UPPER_BODY_SEGMENT_ID = 0;
NSInteger const LOWER_BODY_SEGMENT_ID = 1;

NSInteger const SHOULDER_MG_ID = 0;
NSInteger const CHEST_MG_ID    = 2;
NSInteger const TRICEP_MG_ID   = 8;
NSInteger const CORE_MG_ID      = 3;
NSInteger const BACK_MG_ID     = 1;
NSInteger const CALVES_MG_ID   = 7;
NSInteger const BICEPS_MG_ID   = 9;
NSInteger const FOREARMS_MG_ID = 10;
NSInteger const GLUTES_MG_ID   = 11;
NSInteger const QUADRICEPS_MG_ID = 5;
NSInteger const HAMSTRINGS_MG_ID = 6;
NSInteger const HIP_ABDUCTORS_MG_ID = 12;
NSInteger const HIP_FLEXORS_MG_ID = 13;

NSInteger const LMID_KEY_FOR_SINGLE_VALUE_CONTAINER = 0;

NSString * const CHANGELOG_DETAIL_BODY_SEGMENT = @"CHANGELOG_DETAIL_BODY_SEGMENT";
NSString * const CHANGELOG_DETAIL_MUSCLE_GROUP = @"CHANGELOG_DETAIL_MUSCLE_GROUP";
NSString * const CHANGELOG_DETAIL_MUSCLE = @"CHANGELOG_DETAIL_MUSCLE";
NSString * const CHANGELOG_DETAIL_MUSCLE_ALIAS = @"CHANGELOG_DETAIL_MUSCLE_ALIAS";
NSString * const CHANGELOG_DETAIL_MOVEMENT = @"CHANGELOG_DETAIL_MOVEMENT";
NSString * const CHANGELOG_DETAIL_MOVEMENT_VARIANT = @"CHANGELOG_DETAIL_MOVEMENT_VARIANT";
NSString * const CHANGELOG_DETAIL_ORIGINATION_DEVICE = @"CHANGELOG_DETAIL_ORIGINATION_DEVICE";
NSString * const CHANGELOG_DETAIL_USER_ACCOUNT = @"CHANGELOG_DETAIL_USER_ACCOUNT";
NSString * const CHANGELOG_DETAIL_USER_SETTINGS = @"CHANGELOG_DETAIL_USER_SETTINGS";
NSString * const CHANGELOG_DETAIL_SET = @"CHANGELOG_DETAIL_SET";
NSString * const CHANGELOG_DETAIL_BML = @"CHANGELOG_DETAIL_BML";

NSString * const FIREBASE_USERPROP_GENDER_NAME = @"gender";
NSString * const FIREBASE_USERPROP_SIZE_UNITS_NAME = @"size_units";
NSString * const FIREBASE_USERPROP_WEIGHT_UNITS_NAME = @"weight_units";

CGFloat const PRIMARY_MUSCLE_PERCENTAGE = 0.80;

// Healthkit-related NSUserDefaults keys
NSString * const RHealthKitEnabledAtKey = @"Riker HealthKit enabled at";
NSString * const RHealthKitLastWorkoutEndDate = @"Riker HealthKt Last Workout End Date";
NSString * const RHealthKitWorkoutSaveDisabledAt = @"Riker HealthKit Workout Save Disabled At";
NSString * const RHealthKitLastBodyWeightEndDate = @"Riker HealthKt Last Body Weight End Date";
NSString * const RHealthKitBodyWeightSaveDisabledAt = @"Riker HealthKit Body Weight Save Disabled At";

@implementation RUtils

#pragma mark - Logout

+ (void)logoutWithController:(UIViewController *)controller
                    coordDao:(id<RCoordinatorDao>)coordDao
        watchSessionDelegate:(id<WCSessionDelegate>)watchSessionDelegate
  isFbLogoutFromNotification:(BOOL)isFbLogoutFromNotification
                 hudDelegate:(id<MBProgressHUDDelegate>)hudDelegate {
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:controller];
  __block MBProgressHUD *HUD;
  void (^postAuthTokenNoMatterWhat)(BOOL) = ^(BOOL deleteAll) {
    [FIRAnalytics setUserID:nil];
    [[Crashlytics sharedInstance] setUserIdentifier:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      [HUD hideAnimated:YES];
      [APP logout];
      [coordDao.userCoordinatorDao resetAsLocalUser:user
                                           deleteAll:deleteAll
                               userSettingsMtVersion:[coordDao userSettingsResMtVersion]
                                               error:[RUtils localSaveErrorHandlerMaker]()];
      NSString *msg;
      if (deleteAll) {
        [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:coordDao watchSessionDelegate:watchSessionDelegate];
        [RUtils clearHkBodyWeightEndDate];
        [RUtils clearHkWorkoutEndDate];
        [[NSNotificationCenter defaultCenter] postNotificationName:RAppDeleteAllDataNotification
                                                            object:nil
                                                          userInfo:nil];
        msg = @"You have been logged out successfully. Your account is no longer connected to this device and your Riker data has been removed.\n\nYou can still use the app.  Your data will simply be saved locally.";
      } else {
        msg = @"You have been logged out successfully. Your account is no longer connected to this device.\n\nYou can still use the app.  Your data will simply be saved locally.";
      }
      if (user.facebookUserId) {
        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logOut];
      }
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Logout successful."
                         alertDescription:[[NSAttributedString alloc] initWithString:msg]
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 [APP clearOpenSets];
                                 [[APP sets] removeAllObjects];
                                 enableUserInteraction(YES);
                                 if ([controller isKindOfClass:PEBaseController.class]) {
                                   [((PEBaseController *)controller) setScrollToTopOnRepaint:YES];
                                 }
                                 [controller viewDidAppear:YES];
                                 [[NSNotificationCenter defaultCenter] postNotificationName:ROfflineModeToggledOffNotification object:self];
                               });
                             }
                           relativeToView:controller.tabBarController.view];
    });
  };
  void (^doLogout)(BOOL) = ^(BOOL deleteAll) {
    PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
    HUD = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    HUD.tag = RHUD_TAG;
    enableUserInteraction(NO);
    if (hudDelegate) {
      HUD.delegate = hudDelegate;
    }
    HUD.label.text = @"Logging out...";
    // even if the logout fails, we don't care; we'll still
    // tell the user that logout was successful.  The server should have the smarts to eventually delete
    // the token from its database based on a set of rules anyway (e.g., natural expiration date, or,
    // invalidation after N-amount of inactivity, etc)
    [coordDao.userCoordinatorDao logoutUser:user
                                  deleteAll:deleteAll
                         remoteStoreBusyBlk:^(NSDate *retryAfter) { postAuthTokenNoMatterWhat(deleteAll); }
                          addlCompletionBlk:^{ postAuthTokenNoMatterWhat(deleteAll); }
                      localSaveErrorHandler:[RUtils localSaveErrorHandlerMaker]()];
  };
  NSInteger numUnsyncedEdits = [coordDao totalNumUnsyncedEntitiesForUser:user];
  void (^promptKeepRecords)(void) = ^{
    NSString *title;
    NSString *msg;
    if (isFbLogoutFromNotification) {
      title = @"Facebook logout detected.";
      msg = @"It looks like you have disconnected Riker from your Facebook account.  You will now be logged out of Riker.\n\nDo you want to keep your data records on your device, or have them removed?";
    } else {
      title = @"Keep your data on your device?";
      msg = @"Do you want to keep your data records on your device, or have them removed?";
    }
    [PEUIUtils showConfirmAlertWithTitle:title
                              titleImage:nil
                        alertDescription:AS(msg)
                     descLblHeightAdjust:0.0
                                topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                         okayButtonTitle:@"Keep my data."
                        okayButtonAction:^{ doLogout(NO); }
                         okayButtonStyle:JGActionSheetButtonStyleDefault
                       cancelButtonTitle:@"Remove my data from this device."
                      cancelButtonAction:^{ doLogout(YES); }
                        cancelButtonSyle:JGActionSheetButtonStyleRed
                          relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  };
  if (!isFbLogoutFromNotification && numUnsyncedEdits > 0) {
    [PEUIUtils showWarningConfirmAlertWithTitle:@"You have unsynced data."
                               alertDescription:[[NSAttributedString alloc] initWithString:@"You have unsynced data.  If you log out, they will be permanently deleted.\n\nAre you sure you want to do continue?"]
                            descLblHeightAdjust:0.0
                                       topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                okayButtonTitle:@"Yes.  Log me out."
                               okayButtonAction:^{ promptKeepRecords(); }
                              cancelButtonTitle:@"Cancel."
                             cancelButtonAction:^{ }
                                 relativeToView:controller.tabBarController.view];
  } else {
    NSInteger numSets = [coordDao numSetsForUser:user error:errorBlk];
    NSInteger numBmls = [coordDao numBmlsForUser:user error:errorBlk];
    if (numBmls + numSets > 0) {
      promptKeepRecords();
    } else {
      doLogout(YES);
    }
  }
}

#pragma mark - Account Creation

+ (void)handleAccountCreationOrContinueWithCoordDao:(id<RCoordinatorDao>)coordDao
                              enableUserInteraction:(REnableUserInteractionBlk)enableUserInteraction
                                         controller:(UIViewController *)controller
                               watchSessionDelegate:(id<WCSessionDelegate>)watchSessionDelegate
                                        hudDelegate:(id<MBProgressHUDDelegate>)hudDelegate
                                              email:(NSString *)email
                                           password:(NSString *)password
                                     facebookUserId:(NSString *)facebookUserId
                      preserveExistingLocalEntities:(NSNumber *)preserveExistingLocalEntities
              promptedPreserveExistingLocalEntities:(void(^)(BOOL))promptedPreserveExistingLocalEntities
                             onSuccessDialogDismiss:(void(^)(void))onSuccessDialogDismiss {
  PELMUser *user = (PELMUser *)[coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  [user setEmail:[email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
  [user setPassword:password];
  [user setFacebookUserId:facebookUserId];
  __block MBProgressHUD *HUD;
  void (^commonSuccessBlk)(PELMUser *) = ^(PELMUser *user) {
    [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:coordDao watchSessionDelegate:watchSessionDelegate];
    NSString *firSignUpMethod;
    if (facebookUserId) {
      firSignUpMethod = @"facebook";
    } else {
      firSignUpMethod = @"email";
    }
    [RUtils logEvent:kFIREventSignUp params:@{ kFIRParameterSignUpMethod: firSignUpMethod }];
  };
  void (^nonLocalSyncSuccessBlk)(PELMUser *, BOOL) = ^(PELMUser *user, BOOL isNewAccount) {
    commonSuccessBlk(user);
    dispatch_async(dispatch_get_main_queue(), ^{
      [HUD hideAnimated:YES];
      NSString *successMsg;
      if (isNewAccount) {
        successMsg = @"Your account has been created successfully.\n\nFrom this point on, any new sets and body logs that you create will be saved on your device and synced to your Riker account.\n\nAn account verification link has been emailed to you.";
      } else {
        successMsg = @"You have been logged in successfully.\n\nFrom this point on, any new sets and body logs that you create will be saved on your device and synced to your Riker account.";
      }
      [PEUIUtils showSuccessAlertWithMsgs:nil
                                    title:@"Success."
                         alertDescription:[[NSAttributedString alloc] initWithString:successMsg]
                      descLblHeightAdjust:0.0
                 additionalContentSection:[RPanelToolkit watchReminderAlertSectionRelativeToView:[PEUIUtils parentViewForAlertsForController:controller]]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               enableUserInteraction(YES);
                               NSString *notificationNameToPost;
                               if (isNewAccount) {
                                 notificationNameToPost = RAppAccountCreationNotification;
                               } else {
                                 notificationNameToPost = RAppLoginNotification;
                               }
                               [[NSNotificationCenter defaultCenter] postNotificationName:notificationNameToPost
                                                                                   object:nil
                                                                                 userInfo:nil];
                               onSuccessDialogDismiss();
                             }
                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
    });
  };
  ErrMsgsMaker errMsgsMaker = ^ NSArray * (NSInteger errCode) {
    return [RUtils computeSaveUsrErrMsgs:errCode];
  };
  void (^doAccountCreationOrContinue)(BOOL) = ^ (BOOL syncLocalEntities) {
    __block BOOL receivedAuthReqdErrorOnSyncAttempt = NO;
    void (^successBlk)(PELMUser *, BOOL) = nil;
    if (syncLocalEntities) {
      successBlk = ^(PELMUser *user, BOOL isNewAccount) {
        if (isNewAccount) {
          HUD.label.text = @"Account creation success!";
        } else {
          HUD.label.text = @"Login success!";
        }
        HUD.detailsLabel.text = @"Proceeding to sync your data records...";
        HUD.mode = MBProgressHUDModeDeterminate;
        __block NSInteger numEntitiesSynced = 0;
        __block NSInteger syncAttemptErrors = 0;
        __block float overallSyncProgress = 0.0;
        [coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                     entityNotFoundBlk:^(float progress) {
                                       [RUtils logEvent:@"entity_not_found_wh_create_account_syncing"];
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
                                      [RUtils logEvent:@"busy_wh_create_account_syncing"];
                                      syncAttemptErrors++;
                                      overallSyncProgress += progress;
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [HUD setProgress:overallSyncProgress];
                                      });
                                    }
                                    tempRemoteErrorBlk:^(float progress) {
                                      [RUtils logEvent:@"tmp_remote_err_wh_create_account_syncing"];
                                      syncAttemptErrors++;
                                      overallSyncProgress += progress;
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [HUD setProgress:overallSyncProgress];
                                      });
                                    }
                                        remoteErrorBlk:^(float progress, NSInteger errMask) {
                                          [RUtils logEvent:@"remote_err_wh_create_account_syncing"
                                                    params:[RUtils eventLogParamsWithErrMask:errMask]];
                                          syncAttemptErrors++;
                                          overallSyncProgress += progress;
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [HUD setProgress:overallSyncProgress];
                                          });
                                        }
                                       authRequiredBlk:^(float progress) {
                                         [RUtils logEvent:@"auth_reqd_wh_create_account_syncing"];
                                         syncAttemptErrors++;
                                         overallSyncProgress += progress;
                                         receivedAuthReqdErrorOnSyncAttempt = YES;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [HUD setProgress:overallSyncProgress];
                                         });
                                       }
                                          forbiddenBlk:^(float progress) {
                                            [RUtils logEvent:@"forbidden_wh_create_account_syncing"];
                                            syncAttemptErrors++;
                                            overallSyncProgress += progress;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              [HUD setProgress:overallSyncProgress];
                                            });
                                          }
                                               allDone:^ (NSInteger numImportedSetsNotSyncedDueToNotAllowed,
                                                          NSInteger numImportedSetsNotSyncedDueToMaxExceeded,
                                                          NSInteger numImportedBmlsNotSyncedDueToNotAllowed,
                                                          NSInteger numImportedBmlsNotSyncedDueToMaxExceeded) {
                                                 commonSuccessBlk(user);
                                                 if (syncAttemptErrors == 0) { // 100% no errors
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                     NSArray *notImportedAlertSections = [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                                                       numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                                                        numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                                                       numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                                                     controller:controller];
                                                     [HUD hideAnimated:YES];
                                                     if (numEntitiesSynced > 0) {
                                                       [RUtils logEvent:@"all_synced_wh_create_account_syncing"
                                                                 params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                       NSString *successTitle;
                                                       NSString *successMsg;
                                                       if (isNewAccount) {
                                                         successTitle = @"Account creation & sync\nsuccess.";
                                                         successMsg = @"Your account has been setup and your local edits have been synced.\n\nYour account is now connected to this device.  Any Riker data that you create and save will be synced to your account.";
                                                       } else {
                                                         successTitle = @"Login & sync success.";
                                                         successMsg = @"You have been logged in and your local edits have been synced.\n\nYour account is now connected to this device.  Any Riker data that you create and save will be synced to your account.";
                                                       }
                                                       [PEUIUtils showSuccessAlertWithTitle:successTitle
                                                                           alertDescription:[[NSAttributedString alloc] initWithString:successMsg]
                                                                        descLblHeightAdjust:0.0
                                                                  additionalContentSections:notImportedAlertSections
                                                                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                                buttonTitle:@"Okay."
                                                                               buttonAction:^{
                                                                                 enableUserInteraction(YES);
                                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:RAppAccountCreationNotification
                                                                                                                                     object:nil
                                                                                                                                   userInfo:nil];
                                                                                 [controller dismissViewControllerAnimated:YES completion:nil];
                                                                                 [APP refreshTabs];
                                                                               }
                                                                             relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                     } else {
                                                       // if no records synced, and we got no errors, then, the only possibility (I think, right?) is that
                                                       // the user had imported records to be synced, but they couldn't because the user is either not
                                                       // allowed (unverified email) or they've exceeded their import limit.
                                                       [RUtils logEvent:@"none_could_sync_wh_create_account_syncing"
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
                                                         [sheet dismissAnimated:YES];
                                                         [controller viewDidAppear:YES];
                                                       }];
                                                       [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
                                                     }
                                                   });
                                                 } else {
                                                   [RUtils logEvent:@"sync_errors_wh_create_account_syncing"
                                                             params:[RUtils eventLogParamsWithSyncAttemptErrors:syncAttemptErrors]];
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                     NSArray *notImportedAlertSections = [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                                                       numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                                                        numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                                                       numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                                                     controller:controller];
                                                     [HUD hideAnimated:YES];
                                                     NSString *title = @"Sync problems.";
                                                     NSString *message = @"There were some problems syncing all of your local edits.  You can try syncing them later.";
                                                     JGActionSheetSection *becameUnauthSection = nil;
                                                     if (receivedAuthReqdErrorOnSyncAttempt) {
                                                       NSAttributedString *attrBecameUnauthMessage =
                                                       [PEUIUtils attributedTextWithTemplate:@"This is awkward.  While syncing your local edits, the Riker server is asking for you to authenticate again.  To authenticate, tap the %@ button."
                                                                                textToAccent:@"Re-authenticate"
                                                                              accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                       becameUnauthSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                              title:@"Authentication Failure."
                                                                                                   alertDescription:attrBecameUnauthMessage
                                                                                                descLblHeightAdjust:0.0
                                                                                                     relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                     }
                                                     JGActionSheetSection *contentSection = [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                                                             title:title
                                                                                                                  alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                                                               descLblHeightAdjust:0.0
                                                                                                                    relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
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
                                                       enableUserInteraction(YES);
                                                       [sheet dismissAnimated:YES];
                                                       [controller dismissViewControllerAnimated:YES completion:nil];
                                                     }];
                                                     [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
                                                     [APP refreshTabs];
                                                   });
                                                 }
                                               }
                                                 error:^(NSError *err, int code, NSString *desc) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                     [RUtils localDatabaseErrorHudHandlerMaker](HUD, controller, [PEUIUtils parentViewForAlertsForController:controller])(err, code, desc);
                                                   });
                                                 }];
      };
    } else {
      successBlk = nonLocalSyncSuccessBlk;
    }
    HUD = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    HUD.tag = RHUD_TAG;
    enableUserInteraction(NO);
    HUD.delegate = hudDelegate;
    if (facebookUserId) {
      HUD.label.text = @"Setting up...";
    } else {
      HUD.label.text = @"Creating account...";
    }
    [coordDao.userCoordinatorDao establishRemoteAccountOrContinueForLocalUser:user
                                                preserveExistingLocalEntities:syncLocalEntities
                                                              remoteStoreBusy:[RUtils serverBusyHandlerMakerForUIWithButtonAction:^{enableUserInteraction(YES);}](HUD, controller, [PEUIUtils parentViewForAlertsForController:controller])
                                                            completionHandler:^(PELMUser *innerUser, BOOL isNewAccount, NSError *err) {
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                [RUtils synchUnitOfWorkHandlerMakerWithErrMsgsMaker:errMsgsMaker](HUD,
                                                                                                                                  ^(PELMUser *user) { successBlk(user, isNewAccount); },
                                                                                                                                  ^{ enableUserInteraction(YES); },
                                                                                                                                  controller,
                                                                                                                                  [PEUIUtils parentViewForAlertsForController:controller])(innerUser, err);
                                                                [APP setChangelogUpdatedAt:[innerUser updatedAt]];
                                                              });
                                                            }

                                                        localSaveErrorHandler:[RUtils localDatabaseErrorHudHandlerMaker](HUD, controller, [PEUIUtils parentViewForAlertsForController:controller])];
  };
  if (preserveExistingLocalEntities == nil) { // first time asked
    NSString *msg;
    NSString *syncEmButtonTitle;
    NSString *dontSyncButtonTitle;
    BOOL hasSyncable = NO;
    if ([coordDao numUnsyncedBmlsForUser:user] > 0 ||
        [coordDao numUnsyncedSetsForUser:user] > 0) {
      hasSyncable = YES;
      // we'll just assume they'll want their profile & settings synced too
      msg = @"You've edited some records locally. Would you like them to be synced to your account, or would you like them to be deleted?";
      syncEmButtonTitle = @"Yes.  Sync them to my account.";
      dontSyncButtonTitle = @"No.  Just delete them.";
    } else {
      RUserSettings *userSettings = [coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
      if (userSettings.editCount > 0) {
        hasSyncable = YES;
        msg = @"Would you like your Profile & Settings information to be synced to your account upon account creation?";
        syncEmButtonTitle = @"Yes.  Sync my Profile & Settings.";
        dontSyncButtonTitle = @"No.  I'll start fully anew.";
      }
    }
    if (hasSyncable) {
      JGActionSheetSection *contentSection = [PEUIUtils questionAlertSectionWithTitle:@"Local edits."
                                                                     alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                  descLblHeightAdjust:0.0
                                                                       relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
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
            promptedPreserveExistingLocalEntities(YES);
            doAccountCreationOrContinue(YES);
            break;
          case 1:  // delete them
            promptedPreserveExistingLocalEntities(NO);
            doAccountCreationOrContinue(NO);
            break;
        }
        [sheet dismissAnimated:YES];
      }];
      [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
    } else {
      promptedPreserveExistingLocalEntities(NO);
      doAccountCreationOrContinue(NO);
    }
  } else {
    doAccountCreationOrContinue([preserveExistingLocalEntities boolValue]);
  }
}

#pragma mark - sync all

+ (void)syncAllWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
                    uiInteraction:(BOOL)uiInteraction
                       controller:(PEBaseController *)controller {
  PELMUser *user = (PELMUser *)[coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if ([APP doesUserHaveValidAuthToken] && ![user isBadAccount]) {
    MBProgressHUD *hud = nil;
    REnableUserInteractionBlk enableUserInteraction = nil;
    if (uiInteraction) {
      enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:controller];
      enableUserInteraction(NO);
      hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
      hud.tag = RHUD_TAG;
      hud.label.text = @"Uploading records...";
      hud.mode = MBProgressHUDModeDeterminate;
    }
    __block NSInteger numEntitiesSynced = 0;
    __block NSInteger syncAttemptErrors = 0;
    __block float overallSyncProgress = 0.0;
    __block NSNumber *gotErrMask = nil;
    __block BOOL gotServerBusy = NO;
    __block BOOL gotNotFoundError = NO;
    __block BOOL gotUnauthedError = NO;
    __block BOOL gotForbiddenError = NO;
    __block BOOL gotTempError = NO;
    [coordDao flushAllUnsyncedEditsToRemoteForUser:user
                                entityNotFoundBlk:^(float progress) {
                                  [RUtils logEvent:@"entity_not_found_wh_upload_all"];
                                  syncAttemptErrors++;
                                  gotNotFoundError = YES;
                                  overallSyncProgress += progress;
                                  if (hud) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                      [hud setProgress:overallSyncProgress];
                                    });
                                  }
                                }
                                       successBlk:^(float progress) {
                                         numEntitiesSynced++;
                                         overallSyncProgress += progress;
                                         if (hud) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                             [hud setProgress:overallSyncProgress];
                                           });
                                         }
                                       }
                               remoteStoreBusyBlk:^(float progress, NSDate *retryAfter) {
                                 [RUtils logEvent:@"busy_wh_upload_all"];
                                 syncAttemptErrors++;
                                 gotServerBusy = YES;
                                 overallSyncProgress += progress;
                                 if (hud) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     [hud setProgress:overallSyncProgress];
                                   });
                                 }
                               }
                               tempRemoteErrorBlk:^(float progress) {
                                 [RUtils logEvent:@"tmp_remote_err_wh_upload_all"];
                                 syncAttemptErrors++;
                                 gotTempError = YES;
                                 overallSyncProgress += progress;
                                 if (hud) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     [hud setProgress:overallSyncProgress];
                                   });
                                 }
                               }
                                   remoteErrorBlk:^(float progress, NSInteger errMask) {
                                     [RUtils logEvent:@"remote_error_wh_upload_all"
                                                         params:[RUtils eventLogParamsWithErrMask:errMask]];
                                     syncAttemptErrors++;
                                     gotErrMask = [NSNumber numberWithInteger:errMask];
                                     overallSyncProgress += progress;
                                     if (hud) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         [hud setProgress:overallSyncProgress];
                                       });
                                     }
                                   }
                                  authRequiredBlk:^(float progress) {
                                    [RUtils logEvent:@"auth_reqd_wh_upload_all"];
                                    overallSyncProgress += progress;
                                    gotUnauthedError = YES;
                                    if (hud) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [hud setProgress:overallSyncProgress];
                                      });
                                    }
                                  }
                                     forbiddenBlk:^(float progress) {
                                       [RUtils logEvent:@"forbidden_wh_upload_all"];
                                       overallSyncProgress += progress;
                                       gotForbiddenError = YES;
                                       if (hud) {
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           [hud setProgress:overallSyncProgress];
                                         });
                                       }
                                     }
                                            allDone:^(NSInteger numImportedSetsNotSyncedDueToNotAllowed,
                                                      NSInteger numImportedSetsNotSyncedDueToMaxExceeded,
                                                      NSInteger numImportedBmlsNotSyncedDueToNotAllowed,
                                                      NSInteger numImportedBmlsNotSyncedDueToMaxExceeded) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              NSArray *notImportedAlertSections = [RUIUtils couldNotSyncImportedRecordsAlertSectionsWith:numImportedSetsNotSyncedDueToNotAllowed
                                                                                                numImportedSetsNotSyncedDueToMaxExceeded:numImportedSetsNotSyncedDueToMaxExceeded
                                                                                                 numImportedBmlsNotSyncedDueToNotAllowed:numImportedBmlsNotSyncedDueToNotAllowed
                                                                                                numImportedBmlsNotSyncedDueToMaxExceeded:numImportedBmlsNotSyncedDueToMaxExceeded
                                                                                                                              controller:controller];
                                              [APP refreshTabs];
                                              if (syncAttemptErrors == 0 && !gotUnauthedError && !gotForbiddenError) { // 100% no errors
                                                if (hud) {
                                                  [hud hideAnimated:YES];
                                                }
                                                if (numEntitiesSynced > 0) {
                                                  [RUtils logEvent:@"all_synced_wh_upload_all"
                                                            params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                  NSString *successMsg;
                                                  if (numEntitiesSynced == 1) {
                                                    successMsg = @"Your record has been synced to your Riker account.";
                                                  } else {
                                                    successMsg = @"Your records have been synced to your Riker account.";
                                                  }
                                                  if (uiInteraction) {
                                                    [PEUIUtils showSuccessAlertWithMsgs:nil
                                                                                  title:@"Upload complete."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:successMsg]
                                                                    descLblHeightAdjust:0.0
                                                              additionalContentSections:notImportedAlertSections
                                                                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                            buttonTitle:@"Okay."
                                                                           buttonAction:^{
                                                                             enableUserInteraction(YES);
                                                                             [controller viewDidAppear:YES];
                                                                           }
                                                                         relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  } else {                                                    
                                                    [[[APP window] visibleViewController].view makeToast:successMsg];
                                                  }
                                                } else {
                                                  // if no records synced, and we got no errors, then, the only possibility (I think, right?) is that
                                                  // the user had imported records to be synced, but they couldn't because the user is either not
                                                  // allowed (unverified email) or they've exceeded their import limit.
                                                  [RUtils logEvent:@"none_could_sync_wh_upload_all"
                                                                      params:[RUtils eventLogParamsWithNumRecords:numEntitiesSynced]];
                                                  if (uiInteraction) {
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
                                                      [sheet dismissAnimated:YES];
                                                      [controller viewDidAppear:YES];
                                                    }];
                                                    [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
                                                  }
                                                }
                                              } else {
                                                if (syncAttemptErrors > 0) {
                                                  [RUtils logEvent:@"sync_errors_wh_upload_all"
                                                            params:[RUtils eventLogParamsWithSyncAttemptErrors:syncAttemptErrors]];
                                                }
                                                if (uiInteraction) {
                                                  [hud hideAnimated:YES];
                                                  NSMutableArray *sections = [NSMutableArray array];
                                                  JGActionSheetSection *(^successSection)(NSString *, NSString *) = ^JGActionSheetSection *(NSString *title, NSString *msg) {
                                                    return [PEUIUtils successAlertSectionWithTitle:title
                                                                                  alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                               descLblHeightAdjust:0.0
                                                                                    relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  };
                                                  JGActionSheetSection *(^errSection)(NSString *, NSString *) = ^JGActionSheetSection *(NSString *title, NSString *msg) {
                                                    return [PEUIUtils errorAlertSectionWithMsgs:nil
                                                                                          title:title
                                                                               alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                            descLblHeightAdjust:0.0
                                                                                 relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  };
                                                  JGActionSheetSection *(^waitSection)(NSString *) = ^JGActionSheetSection *(NSString *msg) {
                                                    return [PEUIUtils waitAlertSectionWithMsgs:nil
                                                                                         title:@"Busy with maintenance."
                                                                              alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                           descLblHeightAdjust:0.0
                                                                                relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  };
                                                  JGActionSheetSection *(^authErrSection)(NSString *) = ^JGActionSheetSection *(NSString *msg) {
                                                    return [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                            title:@"Authentication failure."
                                                                                 alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                              descLblHeightAdjust:0.0
                                                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  };
                                                  JGActionSheetSection *(^forbiddenErrSection)(NSString *) = ^JGActionSheetSection *(NSString *msg) {
                                                    return [PEUIUtils warningAlertSectionWithMsgs:nil
                                                                                            title:@"Not permitted."
                                                                                 alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                                              descLblHeightAdjust:0.0
                                                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                  };
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordNotFoundMsg = @"It would appear your record no longer exists and was probably deleted on a different device.\n\nDrill into its detail screen to delete it from this device.";
                                                  NSString *aRecordNotFoundMSg = @"At least one your records no longer exists on the server and was probably deleted on a different device.";
                                                  NSString *oneRecordNotFoundMsg = @"One of your records no longer exists on the server and was probably deleted on a different device.";
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordValidationErrMsg = @"There are problem(s) with your record.\n\nDrill into its detail screen to fix it.";
                                                  NSString *aRecordValidationErrMSg = @"At least one of your records has problem(s) with it.";
                                                  NSString *oneRecordValidationErrMsg = @"One of your records has problem(s) with it. Drill into its detail screen to fix it.";
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordWaitMsg = @"While attempting to sync your record, the Riker server reported that it is busy undergoing maintenance.  Try syncing it later.";
                                                  NSString *aRecordWaitMsg = @"While attempting to sync at least one your records, the Riker server reported it is busy undergoing maintenance.  Try syncing your edits later.";
                                                  NSString *oneRecordWaitMsg = @"While attempting to sync one of your records, the Riker server reported it is busy undergoing maintenance.  Try syncing it later.";
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordUnauthMsg = @"While attempting to sync your record, the Riker server has asked for you to re-authenticate.";
                                                  NSString *aRecordUnauthMsg = @"While attempting to sync at least one one your records, the Riker server has asked for you to re-authenticate.";
                                                  NSString *oneRecordUnauthMsg = @"While attempting to sync one of your records, the Riker server has asked for you to re-authenticate.";
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordForbiddenMsg = @"While attempting to sync your record, a 'not permitted' error was returned, indicating a problem with your account (expired trial or closed account subscription).";
                                                  NSString *aRecordForbiddenMsg = @"While attempting to sync at least one one your records, a 'not permitted' error was returned, indicating a problem with your account (expired trial or closed account subscription).";
                                                  NSString *oneRecordForbiddenMsg = @"While attempting to sync one of your records, a 'not permitted' error was returned, indicating a problem with your account (expired trial or closed account subscription).";
                                                  // ------------------------------------------------------------------------------------------
                                                  NSString *theRecordTempErrMsg = @"There was an error attempting to upload your record.  Try syncing it later.";
                                                  NSString *aRecordTempErrMsg = @"There was an error attempting to upload at least one of your records.  Try syncing them again later.";
                                                  NSString *oneRecordTempErrMsg = @"There was an error attempting to upload one of your records.  Try syncing it later.";
                                                  // ------------------------------------------------------------------------------------------
                                                  void (^aRecordError)(void) = ^{
                                                    if (gotNotFoundError) { [sections addObject:errSection(@"Record not found.", aRecordNotFoundMSg)]; }
                                                    if (gotErrMask) { [sections addObject:errSection(@"Validation error.", aRecordValidationErrMSg)]; }
                                                    if (gotServerBusy) { [sections addObject:waitSection(aRecordWaitMsg)]; }
                                                    if (gotUnauthedError) { [sections addObject:authErrSection(aRecordUnauthMsg)]; }
                                                    if (gotForbiddenError) { [sections addObject:forbiddenErrSection(aRecordForbiddenMsg)]; }
                                                    if (gotTempError) { [sections addObject:errSection(@"Temporary error.", aRecordTempErrMsg)]; }
                                                  };
                                                  void (^oneRecordError)(void) = ^{
                                                    if (gotNotFoundError) { [sections addObject:errSection(@"Record not found.", oneRecordNotFoundMsg)]; }
                                                    if (gotErrMask) { [sections addObject:errSection(@"Validation error.", oneRecordValidationErrMsg)]; }
                                                    if (gotServerBusy) { [sections addObject:waitSection(oneRecordWaitMsg)]; }
                                                    if (gotUnauthedError) { [sections addObject:authErrSection(oneRecordUnauthMsg)]; }
                                                    if (gotForbiddenError) { [sections addObject:forbiddenErrSection(oneRecordForbiddenMsg)]; }
                                                    if (gotTempError) { [sections addObject:errSection(@"Temporary error.", oneRecordTempErrMsg)]; }
                                                  };
                                                  if (numEntitiesSynced == 0) { // none synced
                                                    if (syncAttemptErrors == 1) { // only 1 entity to sync, and it err'd
                                                      if (gotNotFoundError) {
                                                        [sections addObject:errSection(@"Record not found.", theRecordNotFoundMsg)];
                                                      } else if (gotErrMask) {
                                                        [sections addObject:errSection(@"Validation error.", theRecordValidationErrMsg)];
                                                      } else if (gotServerBusy) {
                                                        [sections addObject:waitSection(theRecordWaitMsg)];
                                                      } else if (gotUnauthedError) {
                                                        [sections addObject:authErrSection(theRecordUnauthMsg)];
                                                      } else if (gotForbiddenError) {
                                                        [sections addObject:forbiddenErrSection(theRecordForbiddenMsg)];
                                                      } else { // got temp error
                                                        [sections addObject:errSection(@"Temporary error.", theRecordTempErrMsg)];
                                                      }
                                                    } else { // multiple entities to sync, and they ALL err'd
                                                      aRecordError();
                                                    }
                                                  } else if (numEntitiesSynced == 1) { // 1 entity successfully synced
                                                    if (syncAttemptErrors == 1) { // only 1 entity err'd
                                                      oneRecordError();
                                                    } else { // multiple entities err'd
                                                      aRecordError();
                                                    }
                                                    [sections addObject:successSection(@"1 record synced.", @"One of your records successfully synced.")];
                                                  } else { // multiple entities successfully synced
                                                    if (syncAttemptErrors == 1) { // only 1 entity err'd
                                                      oneRecordError();
                                                    } else { // multiple entities err'd
                                                      aRecordError();
                                                    }
                                                    [sections addObject:successSection(@"Some records synced.", @"Some of your records successfully synced.")];
                                                  }
                                                  [sections addObjectsFromArray:notImportedAlertSections];
                                                  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                                                        message:nil
                                                                                                                   buttonTitles:@[@"Okay."]
                                                                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
                                                  [sections addObject:buttonsSection];
                                                  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                                                  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                                                    enableUserInteraction(YES);
                                                    [sheet dismissAnimated:YES];
                                                    [controller viewDidAppear:YES];
                                                  }];
                                                  [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
                                                }
                                                }
                                            });
                                          }
                                            error:[RUtils localDatabaseErrorHudHandlerMaker](hud, controller, [PEUIUtils parentViewForAlertsForController:controller])];

  } else {
    UIFont* boldDescFont = uiInteraction ? [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]] : nil;
    NSAttributedString *attrMessage = nil;
    NSString *title = nil;
    if (![APP doesUserHaveValidAuthToken]) {
      [RUtils logEvent:@"cannot_upload_all_unauthenticated"];
      if (uiInteraction) {
        title = @"Not Authenticated.";
        attrMessage = [PEUIUtils attributedTextWithTemplate:@"You are not currently authenticated.\n\nTo re-authenticate, head over to:\n\n%@."
                                               textToAccent:@"Account \u2794 Re-authenticate"
                                             accentTextFont:boldDescFont];
      }
    } else {
      [RUtils logEvent:@"cannot_upload_all_not_permitted"];
      if (uiInteraction) {
        title = @"Operation not permitted.";
        attrMessage = [PEUIUtils attributedTextWithTemplate:@"This operation is not permitted because your account is currently in a bad state.\n\nThis is usually due to an expired trial account or a closed account subscription.  To address this, head over to:\n\n%@."
                                               textToAccent:@"Account \u2794 Status"
                                             accentTextFont:boldDescFont];
      }
    }
    if (uiInteraction) {
      [PEUIUtils showWarningAlertWithMsgs:nil
                                    title:title
                         alertDescription:attrMessage
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:^{}
                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
    }
  }
}

#pragma mark - Workout Helpers

+ (id)workoutForDescendingSets:(NSArray *)descendingSets
                    nearestBml:(RBodyMeasurementLog *)nearestBml
                  userSettings:(RUserSettings *)userSettings
              allMovementsDict:(NSDictionary *)allMovementsDict
           allMuscleGroupsDict:(NSDictionary *)allMuscleGroupsDict
                allMusclesDict:(NSDictionary *)allMusclesDict
                      forWatch:(BOOL)forWatch {
  NSDecimalNumber *bodyWeightLbs = [RUtils weightValueWithValue:nearestBml.bodyWeight
                                             currentWeightUomId:nearestBml.bodyWeightUom
                                              targetWeightUomId:@(LBS_ID)];
  RSet *firstSet = nil;
  RSet *lastSet = [descendingSets firstObject];;
  NSInteger numSets = descendingSets.count;
  if (numSets > 1) {
    firstSet = [descendingSets lastObject];
  }
  NSDate *startDate;
  NSDate *endDate = lastSet.loggedAt;
  if (firstSet) {
    startDate = [firstSet.loggedAt dateBySubtractingSeconds:30];
  } else {
    startDate = [lastSet.loggedAt dateBySubtractingSeconds:30];
  }
  NSInteger workoutDurationInSeconds = [startDate secondsEarlierThan:endDate];
  NSInteger numSetsToFailure = 0;
  BOOL computeImpactedMuscleGroups = allMovementsDict != nil;
  NSDecimalNumber *primaryMusclePercentage = nil;
  NSMutableDictionary *impactedMuscleGroups = nil;
  NSDecimalNumber *totalWorkoutWeightLifted = nil;
  void (^computeImpactedMuscleGroupsBlk)(NSArray *, NSDecimalNumber *) = nil;
  if (computeImpactedMuscleGroups) {
    primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
    impactedMuscleGroups = [NSMutableDictionary dictionary];
    totalWorkoutWeightLifted = [NSDecimalNumber zero];
    computeImpactedMuscleGroupsBlk = ^(NSArray *muscleIds, NSDecimalNumber *totalWeight) {
      NSMutableArray *muscleGroupIds = [NSMutableArray array];
      for (NSNumber *muscleId in muscleIds) {
        RMuscle *muscle = allMusclesDict[muscleId];
        [muscleGroupIds addObject:muscle.muscleGroupId];
      }
      if (muscleGroupIds.count > 0) {
        NSDecimalNumber *perMuscleGroupAmount = [totalWeight decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:muscleGroupIds.count]];
        for (NSNumber *muscleGroupId in muscleGroupIds) {
          NSDecimalNumber *totalMuscleGroupWeight = impactedMuscleGroups[muscleGroupId];
          if (!totalMuscleGroupWeight) {
            totalMuscleGroupWeight = [NSDecimalNumber zero];
          }
          totalMuscleGroupWeight = [totalMuscleGroupWeight decimalNumberByAdding:perMuscleGroupAmount];
          impactedMuscleGroups[muscleGroupId] = totalMuscleGroupWeight;
        }
      }
    };
  }
  for (RSet *set in descendingSets) {
    if (set.toFailure) {
      numSetsToFailure++;
    }
    if (computeImpactedMuscleGroups) {
      NSDecimalNumber *weight = [RUtils weightValueWithValue:set.weight currentWeightUomId:set.weightUom targetWeightUomId:userSettings.weightUom];
      NSInteger numRepsInt = set.numReps.integerValue;
      NSDecimalNumber *totalWeight = [weight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:numRepsInt]];
      totalWorkoutWeightLifted = [totalWorkoutWeightLifted decimalNumberByAdding:totalWeight];
      RMovement *movement = allMovementsDict[set.movementId];
      NSDecimalNumber *primaryMusclesTotalWeight;
      if (movement.secondaryMuscleIds.count > 0) {
        primaryMusclesTotalWeight = [totalWeight decimalNumberByMultiplyingBy:primaryMusclePercentage];
      } else {
        primaryMusclesTotalWeight = totalWeight;
      }
      NSDecimalNumber *secondaryMusclesTotalWeight = [totalWeight decimalNumberBySubtracting:primaryMusclesTotalWeight];
      computeImpactedMuscleGroupsBlk(movement.primaryMuscleIds, primaryMusclesTotalWeight);
      computeImpactedMuscleGroupsBlk(movement.secondaryMuscleIds, secondaryMusclesTotalWeight);
    }
  }
  NSMutableArray *muscleGroupTuples = nil;
  if (computeImpactedMuscleGroups) {
    muscleGroupTuples = [NSMutableArray arrayWithCapacity:impactedMuscleGroups.count];
    NSArray *muscleGroupIds = [impactedMuscleGroups allKeys];
    for (NSNumber *muscleGroupId in muscleGroupIds) {
      RMuscleGroup *muscleGroup = allMuscleGroupsDict[muscleGroupId];
      NSDecimalNumber *muscleGroupWeight = impactedMuscleGroups[muscleGroupId];
      NSDecimalNumber *percentageOfTotalWorkout = [muscleGroupWeight decimalNumberByDividingBy:totalWorkoutWeightLifted];
      [muscleGroupTuples addObject:@[muscleGroupId, percentageOfTotalWorkout, muscleGroup.name]];
    }
    [muscleGroupTuples sortUsingComparator:^NSComparisonResult(NSArray *muscleGroupTuple1, NSArray *muscleGroupTuple2) {
      NSDecimalNumber *percentageOfTotal1 = muscleGroupTuple1[1];
      NSDecimalNumber *percentageOfTotal2 = muscleGroupTuple2[1];
      return [percentageOfTotal2 compare:percentageOfTotal1]; // we want highest first
    }];
  }
  double toFailurePercentage = numSetsToFailure / (1.0 * numSets);
  BOOL vigorousWorkout = toFailurePercentage >= 0.75;
  NSDecimalNumber *caloriesBurned = [RUtils caloriesBurnedForBodyWeightLbs:bodyWeightLbs
                                                           workoutDuration:workoutDurationInSeconds
                                                                  vigorous:vigorousWorkout];
  DDLogDebug(@"Workout computed.  FirstSet date: [%@], lastSet date: [%@], nearest bml date and weight lbs: [%@, %@], vigorous? [%@], workout duration secs: [%ld], calories burned: [%@], numSetsToFailure: [%@], numSets: [%@], toFailurePercentage: [%f], vigorousWorkout: [%@]", firstSet.loggedAt, lastSet.loggedAt, nearestBml.loggedAt, bodyWeightLbs, [PEUtils yesNoFromBool:vigorousWorkout], (long)workoutDurationInSeconds, caloriesBurned, @(numSetsToFailure), @(numSets), toFailurePercentage, @(vigorousWorkout));
  if (forWatch) {
    NSMutableDictionary *workout = [NSMutableDictionary dictionaryWithCapacity:5];
    workout[@"start-date-unix-time"] = [startDate toUnixTime];
    workout[@"end-date-unix-time"] = [endDate toUnixTime];
    NSString *durationValStr = [NSString stringWithFormat:@"%.1f", workoutDurationInSeconds / 60.0];
    workout[@"duration-formatted"] = [NSString stringWithFormat:@"%@ minute%@", durationValStr, [durationValStr isEqualToString:@"1"] ? @"" : @"s"];
    if (caloriesBurned) {
      workout[@"calories-burned-formatted"] = [NSString stringWithFormat:@"%.1f kcal", caloriesBurned.floatValue];
    }
    workout[@"impacted-muscle-group-tuples"] = muscleGroupTuples;
    return workout;
  } else {
    RWorkout *workout = [[RWorkout alloc] init];
    workout.startDate = startDate;
    workout.endDate = endDate;
    workout.durationSeconds = workoutDurationInSeconds;
    workout.caloriesBurned = caloriesBurned;
    workout.impactedMuscleGroupTuples = muscleGroupTuples;
    return workout;
  }
}

+ (NSArray *)workoutsTupleForDescendingSets:(NSArray *)descendingSets
                                       user:(PELMUser *)user
                               userSettings:(RUserSettings *)userSettings
                           allMovementsDict:(NSDictionary *)allMovementsDict
                        allMuscleGroupsDict:(NSDictionary *)allMuscleGroupsDict
                             allMusclesDict:(NSDictionary *)allMusclesDict
                                   forWatch:(BOOL)forWatch
                                   coordDao:(id<RLocalDao>)coordDao
                                      error:(PELMDaoErrorBlk)errorBlk {
  NSDate *previousSetLoggedAt = nil;
  NSInteger numSets = descendingSets.count;
  NSMutableArray *workouts = [NSMutableArray array];
  NSDate *latestSetLoggedAt = nil;
  if (numSets > 0) {
    latestSetLoggedAt = ((RSet *)[descendingSets firstObject]).loggedAt;
    NSMutableArray *setsForWorkout = [NSMutableArray array];
    for (NSInteger i = 0; i < numSets; i++) {
      RSet *set = descendingSets[i];
      NSDate *loggedAt = set.loggedAt;
      if (previousSetLoggedAt) {
        double secondsDouble = [previousSetLoggedAt secondsLaterThan:loggedAt];
        if (secondsDouble < SECONDS_IN_HOUR) {
          [setsForWorkout addObject:set];
          previousSetLoggedAt = loggedAt;
        } else {
          RBodyMeasurementLog *nearestBml = [coordDao nearestBmlWithNonNilBodyWeightToDate:previousSetLoggedAt user:user error:errorBlk];
          [workouts addObject:[RUtils workoutForDescendingSets:setsForWorkout
                                                    nearestBml:nearestBml
                                                  userSettings:userSettings
                                              allMovementsDict:allMovementsDict
                                           allMuscleGroupsDict:allMuscleGroupsDict
                                                allMusclesDict:allMusclesDict
                                                      forWatch:forWatch]];
          [setsForWorkout removeAllObjects];
          [setsForWorkout addObject:set]; // final set (because the sets are in descending order) of new workout
          previousSetLoggedAt = loggedAt;
        }
      } else {
        [setsForWorkout addObject:set];
        previousSetLoggedAt = loggedAt;
      }
    }
    NSDate *loggedAt = ((RSet *)[setsForWorkout lastObject]).loggedAt;
    RBodyMeasurementLog *nearestBml = [coordDao nearestBmlWithNonNilBodyWeightToDate:loggedAt user:user error:errorBlk];
    id workout = [RUtils workoutForDescendingSets:setsForWorkout
                                       nearestBml:nearestBml
                                     userSettings:userSettings
                                 allMovementsDict:allMovementsDict
                              allMuscleGroupsDict:allMuscleGroupsDict
                                   allMusclesDict:allMusclesDict
                                         forWatch:forWatch];
    [workouts addObject:workout];
  }
  return @[workouts, numSets > 0 ? latestSetLoggedAt : [NSNull null], @(numSets)];
}

#pragma mark - Apple Watch Helpers

+ (void)initiateAllDataToAppleWatchTransferWithCoordDao:(id<RCoordinatorDao>)coordDao
                                   watchSessionDelegate:(id<WCSessionDelegate>)watchSessionDelegate {
  WCSession *session = [WCSession defaultSession];
  if ([WCSession isSupported]) {
    if ([session activationState] == WCSessionActivationStateActivated) {
      [RUtils transferAllDataToAppleWatchInBgWithCoordDao:coordDao session:session];
    } else {
      if (session.reachable) {
        session.delegate = watchSessionDelegate;
        [session activateSession];
      }
    }
  }
}

+ (void)transferAllDataToAppleWatchInBgWithCoordDao:(id<RCoordinatorDao>)coordDao
                                            session:(WCSession *)session {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDictionary *allDataForAppleWatch = [RUtils allDataForAppleWatchWithCoordDao:coordDao];
    [session transferUserInfo:@{ RWATCHMSG_PAYLOAD_KEY: allDataForAppleWatch,
                                 RWATCHMSG_ACTION_KEY: @(RWatchMsgActionPushAllIPhoneData),
                                 RWATCHMSG_RAISE_NOTIFICATION_KEY: @(NO) }];
  });
}

+ (NSInteger)handleSaveNewBmlsFromWatchWithPayload:(NSArray *)bmlsPayload
                                          coordDao:(id<RCoordinatorDao>)coordDao
                                       healthStore:(HKHealthStore *)healthStore {
  NSInteger numSaved = 0;
  for (NSDictionary *bml in bmlsPayload) {
    NSString *uuid = bml[@"uuid"];
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    NSInteger numBmlsWithMatchingUuid = [coordDao numBmlsWithUuid:uuid error:errorBlk];
    if (numBmlsWithMatchingUuid == 0) { // dup check
      numSaved++;
      NSNumber *value = bml[@"value"];
      NSDecimalNumber *valueDecimal;
      if ([value isKindOfClass:[NSDecimalNumber class]]) {
        valueDecimal = (NSDecimalNumber *)value;
      } else {
        valueDecimal = [[NSDecimalNumber alloc] initWithFloat:value.floatValue];
      }
      RBodyMeasurementLog *newBml = [coordDao bmlWithBodyWeight:nil
                                                  bodyWeightUom:nil
                                                        armSize:nil
                                                       calfSize:nil
                                                      chestSize:nil
                                                        sizeUom:nil
                                                       neckSize:nil
                                                      waistSize:nil
                                                      thighSize:nil
                                                    forearmSize:nil
                                                       loggedAt:bml[@"logged-at"]
                                            originationDeviceId:@(ORIGINATION_DEVICE_ID_APPLE_WATCH)
                                                     importedAt:nil];
      newBml.uuid = uuid;
      PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
      RUserSettings *userSettings = [coordDao userSettingsForUser:user error:errorBlk];
      RBmlType bmlType = ((NSNumber *)bml[@"bml-type"]).integerValue;
      void (^setUomsForSizeBodyLog)(void) = ^{
        [newBml setSizeUom:bml[@"uom-id"]];
        [newBml setBodyWeightUom:[userSettings weightUom]];
      };
      switch (bmlType) {
        case RBmlTypeBodyWeight:
          [newBml setBodyWeight:valueDecimal];
          [newBml setBodyWeightUom:bml[@"uom-id"]];
          [newBml setSizeUom:[userSettings sizeUom]];
          break;
        case RBmlTypeArms:
          [newBml setArmSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeNeck:
          [newBml setNeckSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeWaist:
          [newBml setWaistSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeThighs:
          [newBml setThighSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeForearms:
          [newBml setForearmSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeChest:
          [newBml setChestSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeCalves:
          [newBml setCalfSize:valueDecimal];
          setUomsForSizeBodyLog();
          break;
        case RBmlTypeSeveral: // not applicable
          break;
      }
      [coordDao saveNewBml:newBml forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
      if (bmlType == RBmlTypeBodyWeight) {
        [RUtils saveHealthKitBmlsWithCompletion:nil noOpBlk:nil raiseNotificationOnError:YES coordDao:coordDao healthStore:healthStore];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:REntityAddedNotification
                                                            object:self
                                                          userInfo:@{@"entity": newBml}];
      });
    } else {
      // we've already saved this bml before (presumably from the watch), but the watch
      // re-sent it anyway...so we should ignore it
    }
  }
  if (numSaved > 0) {
    [RUtils logEvent:@"bmls_synced_from_apple_watch" params:@{@"num_bmls": @(numSaved)}];
  }
  return numSaved;
}

+ (NSInteger)handleSaveNewSetsFromWatchWithPayload:(NSArray *)setsPayload
                                          coordDao:(id<RCoordinatorDao>)coordDao {
  NSInteger numSaved = 0;
  for (NSDictionary *set in setsPayload) {
    NSString *uuid = set[@"uuid"];
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    NSInteger numSetsWithMatchingUuid = [coordDao numSetsWithUuid:uuid error:errorBlk];
    if (numSetsWithMatchingUuid == 0) { // dup check
      numSaved++;
      PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
      NSDate *loggedAt = set[@"logged-at"];
      NSNumber *weight = set[@"weight"];
      NSDecimalNumber *weightDecimal;
      if ([weight isKindOfClass:[NSDecimalNumber class]]) {
        weightDecimal = (NSDecimalNumber *)weight;
      } else {
        weightDecimal = [[NSDecimalNumber alloc] initWithInteger:weight.integerValue];
      }
      RSet *newSet = [coordDao setWithNumReps:set[@"reps"]
                                       weight:weightDecimal
                                    weightUom:set[@"weight-uom-id"]
                                    negatives:((NSNumber *)set[@"negatives"]).boolValue
                                    toFailure:((NSNumber *)set[@"to-failure"]).boolValue
                                     loggedAt:loggedAt
                                   ignoreTime:NO
                                   movementId:set[@"movement-id"]
                            movementVariantId:set[@"variant-id"]
                          originationDeviceId:@(ORIGINATION_DEVICE_ID_APPLE_WATCH)
                                   importedAt:nil
                              correlationGuid:nil];
      newSet.uuid = uuid;
      [coordDao saveNewSet:newSet forUser:user error:errorBlk];
      [RUtils logNewSetEventWithSet:newSet];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:REntityAddedNotification
                                                            object:self
                                                          userInfo:@{@"entity": newSet}];
      });
    } else {
      // we've already saved this set before (presumably from the watch), but the watch
      // re-sent it anyway...so we should ignore it
    }
  }
  if (numSaved > 0) {
    [RUtils logEvent:@"sets_synced_from_apple_watch" params:@{@"num_sets": @(numSaved)}];
  }
  return numSaved;
}

+ (NSMutableDictionary *)wrapPayload:(id)payload action:(RWatchMsgAction)action {
  return [[NSMutableDictionary alloc] initWithDictionary:@{ RWATCHMSG_ACTION_KEY: @(action),
                                                            RWATCHMSG_PAYLOAD_KEY: payload }];
}

+ (NSDictionary *)emptySuccessWatchResponse {
  return @{ RWATCHMSG_REPLY_RESULT_STATUS_KEY: @(RWatchReplyResultStatusSuccess) };
}

+ (NSDictionary *)allDataForAppleWatchWithCoordDao:(id<RLocalDao>)coordDao {
  NSMutableDictionary *payload = [NSMutableDictionary dictionary];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
  RUserSettings *userSettings = [coordDao userSettingsForUser:user error:errorBlk];
  NSDictionary *movementsAndSettings = [coordDao movementsAndSettingsForWatchWithUser:user
                                                                         userSettings:userSettings
                                                                                error:errorBlk];
  payload[@"movements-and-settings-container"] = movementsAndSettings;
  [payload addEntriesFromDictionary:[RUtils setsBmlsAndWorkoutsForAppleWatchWithUser:user
                                                                            coordDao:coordDao
                                                                        userSettings:userSettings
                                                                               error:errorBlk]];
  return payload;
}

+ (NSDictionary *)setsBmlsAndWorkoutsForAppleWatchWithUser:(PELMUser *)user
                                                  coordDao:(id<RLocalDao>)coordDao
                                              userSettings:(RUserSettings *)userSettings
                                                     error:(PELMDaoErrorBlk)errorBlk {
  NSArray *muscleGroups = [coordDao muscleGroupsWithError:errorBlk];
  NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:muscleGroups];
  NSArray *muscles = [coordDao musclesWithError:errorBlk];
  NSArray *movements = [coordDao movementsWithError:errorBlk];
  NSArray *sets = [coordDao descendingSetsForUser:user pageSize:100 error:errorBlk];
  NSDictionary *movementsDict = [RUtils dictFromMasterEntitiesArray:movements];
  NSArray *movementVariants = [coordDao movementVariantsWithError:errorBlk];
  NSArray *workoutsTuple = [RUtils workoutsTupleForDescendingSets:sets
                                                             user:user
                                                     userSettings:userSettings
                                                 allMovementsDict:movementsDict
                                              allMuscleGroupsDict:muscleGroupsDict
                                                   allMusclesDict:[RUtils dictFromMasterEntitiesArray:muscles]
                                                         forWatch:YES
                                                         coordDao:coordDao
                                                            error:errorBlk];
  NSMutableArray *workouts = workoutsTuple[0];
  if (workouts.count > 1) {
    // because we pulled back a fixed set of sets (100), we don't know if the last workout element
    // in workouts array really represents a "full" workout (because, the sets
    // that came back may have been cutoff mid-workout); and therefore, we simply
    // blow away the last workout in the array
    [workouts removeLastObject];
  }
  NSMutableArray *mutableSets = [NSMutableArray arrayWithArray:sets];
  while (mutableSets.count > MAX_RECENT_ENTITIES) {
      [mutableSets removeLastObject];
  }
  NSArray *bmls = [coordDao descendingBmlsForUser:user pageSize:MAX_RECENT_ENTITIES error:errorBlk];
  NSArray *appleWatchSets = [RUtils appleWatchSetsWithSets:mutableSets
                                          allMovementsDict:movementsDict
                                   allMovementVariantsDict:[RUtils dictFromMasterEntitiesArray:movementVariants]];
  NSArray *appleWatchBmls = [RUtils appleWatchBmlsWithBmls:bmls];
  return @{ @"workouts-container": @{ @"workouts": workouts },
            @"sets-container": @{ @"sets": appleWatchSets },
            @"bmls-container": @{ @"bmls": appleWatchBmls }};
}

+ (NSArray *)appleWatchBmlsWithBmls:(NSArray *)bmls {
  NSMutableArray *appleWatchBmls = [NSMutableArray arrayWithCapacity:bmls.count];
  for (RBodyMeasurementLog *bml in bmls) {
    NSMutableDictionary *bmlDict = [NSMutableDictionary dictionary];
    bmlDict[@"synced-to-iphone"] = @(YES);
    bmlDict[@"logged-at-unix-time"] = [bml.loggedAt toUnixTime];
    __block NSInteger numValsSet = 0;
    NSNumberFormatter *decimalFormatter = [RUtils weightNumberFormatter];
    if (bml.bodyWeight) {
      NSString *bodyWeightValueStr = [decimalFormatter stringFromNumber:bml.bodyWeight];
      bmlDict[@"body-weight"] = [NSMutableString stringWithFormat:@"Body weight: %@ %@", bodyWeightValueStr, [RUtils weightUnitNameForUomId:bml.bodyWeightUom]];
      bmlDict[@"bml-type"] = @"Body Weight";
      bmlDict[@"value"] = bodyWeightValueStr;
      numValsSet++;
    }
    void (^appendSize)(NSNumber *, NSString *, NSString *, NSString *) = ^(NSNumber *val, NSString *key, NSString *name, NSString *type) {
      if ([PEUtils isNotNil:val]) {
        NSString *valueStr = [decimalFormatter stringFromNumber:val];
        bmlDict[key] = [NSMutableString stringWithFormat:@"%@: %@ %@", name, valueStr, [RUtils sizeUnitNameForUomId:bml.sizeUom]];
        bmlDict[@"value"] = valueStr;
        bmlDict[@"bml-type"] = type;
        numValsSet++;
      }
    };
    appendSize(bml.armSize, @"arm-size", @"Arms", @"Arm Size");
    appendSize(bml.chestSize, @"chest-size", @"Chest", @"Chest Size");
    appendSize(bml.calfSize, @"calf-size", @"Calf", @"Calf Size");
    appendSize(bml.neckSize, @"neck-size", @"Neck", @"Neck Size");
    appendSize(bml.waistSize, @"waist-size", @"Waist", @"Waist Size");
    appendSize(bml.thighSize, @"thigh-size", @"Thigh", @"Thigh Size");
    appendSize(bml.forearmSize, @"forearm-size", @"Forearm", @"Forearm Size");
    if (numValsSet > 1) {
      bmlDict[@"bml-type"] = @"Multiple";
    }
    [appleWatchBmls addObject:bmlDict];
  }
  return appleWatchBmls;
}

+ (NSArray *)appleWatchSetsWithSets:(NSArray *)sets
                   allMovementsDict:(NSDictionary *)allMovementsDict
            allMovementVariantsDict:(NSDictionary *)allMovementVariantsDict {
  NSMutableArray *appleWatchSets = [NSMutableArray arrayWithCapacity:sets.count];
  for (RSet *set in sets) {
    RMovement *movement = allMovementsDict[set.movementId];
    NSString *movementVariantName = nil;
    if (set.movementVariantId) {
      RMovementVariant *movementVariant = allMovementVariantsDict[set.movementVariantId];
      movementVariantName = movementVariant.name;
    } else if (movement.isBodyLift) {
      movementVariantName = @"body lift";
    }
    NSMutableDictionary *setDict = [NSMutableDictionary dictionary];
    setDict[@"logged-at-unix-time"] = [set.loggedAt toUnixTime];
    setDict[@"movement"] = movement.canonicalName;
    setDict[@"synced-to-iphone"] = @(YES);
    if (movementVariantName) {
      setDict[@"movement-variant"] = movementVariantName;
    }
    setDict[@"reps-and-weight-desc"] = [NSString stringWithFormat:@"%@ rep%@ of %@ %@",
                                        set.numReps,
                                        set.numReps.integerValue > 1 ? @"s" : @"",
                                        set.weight,
                                        [RUtils weightUnitNameForUomId:set.weightUom]];
    setDict[@"to-failure-desc"] = [NSString stringWithFormat:@"To failure? %@", [PEUtils yesNoFromBool:set.toFailure].capitalizedString];
    setDict[@"negatives-desc"] = [NSString stringWithFormat:@"Negatives? %@", [PEUtils yesNoFromBool:set.negatives].capitalizedString];
    [appleWatchSets addObject:setDict];
  }
  return appleWatchSets;
}

#pragma mark - Healthkit Helpers

+ (void)appendHkSyncPromptAlertDesc:(NSMutableAttributedString *)syncPromptDesc
                      numSetsToSync:(NSInteger)numSetsToSync
                      numBmlsToSync:(NSInteger) numBodyWeightLogsToSync {
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  if (numSetsToSync > 0) {
    if (numBodyWeightLogsToSync > 0) { // both to sync
      [syncPromptDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"You have %@ and "
                                                                      textToAccent:numBodyWeightLogsToSync > 1 ? [NSString stringWithFormat:@"%@ body weight logs", [formatter stringFromNumber:@(numBodyWeightLogsToSync)]] : @"1 body weight log"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [syncPromptDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ that can be synced.  If you are currently in the middle of a workout, it is recommended you do not sync your workouts right now."
                                                                      textToAccent:numSetsToSync > 1 ? [NSString stringWithFormat:@"%@ sets", [formatter stringFromNumber:@(numSetsToSync)]] : @"1 set"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    } else { // only sets to sync
      [syncPromptDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"You have %@ that can be synced.  If you are currently in the middle of a workout, do not sync right now."
                                                                      textToAccent:numSetsToSync > 1 ? [NSString stringWithFormat:@"%@ sets", [formatter stringFromNumber:@(numSetsToSync)]] : @"1 set"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    }
    if ([WCSession isSupported] && [APP usedWatchAppAt] != nil) {
      [syncPromptDesc appendAttributedString:AS(@"\n\nAre you using Riker on your Apple Watch?  If so, make sure to sync all your sets from your watch to your iPhone before syncing to Apple Health.")];
    }
  } else if (numBodyWeightLogsToSync > 0) { // only bmls to sync
    [syncPromptDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"You have %%@ that can be synced.  Lets go ahead and sync %@ now.", numBodyWeightLogsToSync > 1 ? @"them" : @"it"]
                                                                    textToAccent:numBodyWeightLogsToSync > 1 ? [NSString stringWithFormat:@"%@ body weight logs", [formatter stringFromNumber:@(numBodyWeightLogsToSync)]] : @"1 body weight log"
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  }
}

+ (void)appendHkSuccessSetsSyncWithMsg:(NSMutableAttributedString *)msg
                       prependNewlines:(BOOL)prependNewlines
                               numSets:(NSInteger)numSets
                      numWorkoutsSaved:(NSInteger)numWorkoutsSaved
                      includeFutureMsg:(BOOL)includeFutureMsg {
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  if (prependNewlines) {
    [msg appendAttributedString:AS(@"\n\n")];
  }
  [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"Your %%@ %@ been organized into ", numSets > 1 ? @"have" : @"has"]
                                                       textToAccent:numSets > 1 ? [NSString stringWithFormat:@"%@ sets", [formatter stringFromNumber:@(numSets)]] : @"1 set"
                                                     accentTextFont:nil]];
  [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and synced to Apple Health successfully."
                                                       textToAccent:numWorkoutsSaved > 1 ? [NSString stringWithFormat:@"%@ workouts", [formatter stringFromNumber:@(numWorkoutsSaved)]] : @"1 workout"
                                                     accentTextFont:nil]];
  if (includeFutureMsg) {
    [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFuture sets can be grouped and synced as workouts to Apple Health using the %@ button."
                                                         textToAccent:[@"Sync Workouts" nonBreaking]
                                                       accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  }
}

+ (void)appendHkFailMsgWithType:(NSString *)type
                            msg:(NSMutableAttributedString *)msg
                prependNewlines:(BOOL)prependNewlines
             includePrivacyInfo:(BOOL)includePrivacyInfo
                          error:(NSError *)error {
  if (prependNewlines) {
    [msg appendAttributedString:AS(@"\n\n")];
  }
  switch (error.code) {
    case HKErrorAuthorizationDenied:
      [msg appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Riker is currently not allowed to sync your %@s to Apple Health.", type]]];
      if (includePrivacyInfo) {
        [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nYou can manage your Apple Health privacy settings from the %@ app."
                                                             textToAccent:@"Settings"
                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      }
      break;
    default:
      [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"There was an error attempting to sync your %@s to Apple Health.  Error message: %%@", type]
                                                           textToAccent:error.description
                                                         accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      break;
  }
}

+ (void)setsOnlyDoHkSyncIncludeFutureMsg:(BOOL)includeFutureMsg
                 successOkayButtonAction:(void(^)(void))successOkayButtonAction
                   errorOkayButtonAction:(void(^)(void))errorOkayButtonAction
                              controller:(PEBaseController *)controller
                                coordDao:(id<RCoordinatorDao>)coordDao
                             healthStore:(HKHealthStore *)healthStore
                           uiInteraction:(BOOL)uiInteraction {
  MBProgressHUD *hud = nil;
  if (uiInteraction) {
    hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    hud.tag = RHUD_TAG;
    hud.delegate = controller;
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [RUtils saveHealthKitWorkoutsWithCompletion:^(NSInteger numSets, NSInteger numWorkoutsSaved, BOOL setsSuccess, NSError *setsError) {
      NSMutableAttributedString *successDesc = nil;
      NSMutableAttributedString *totalFailureDesc = nil;
      if (setsSuccess) {
        if (uiInteraction) {
          successDesc = [[NSMutableAttributedString alloc] init];
          [RUtils appendHkSuccessSetsSyncWithMsg:successDesc
                                 prependNewlines:NO
                                         numSets:numSets
                                numWorkoutsSaved:numWorkoutsSaved
                                includeFutureMsg:includeFutureMsg];
          dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [PEUIUtils showSuccessAlertWithTitle:@"Success"
                                alertDescription:successDesc
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      successOkayButtonAction();
                                    }
                                  relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          });
        } else {
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[[APP window] visibleViewController].view makeToast:@"Synced to Apple Health"];
          });
          if (successOkayButtonAction) {
            successOkayButtonAction();
          }
        }
      } else {
        if (uiInteraction) {
          totalFailureDesc = [[NSMutableAttributedString alloc] init];
          [RUtils appendHkFailMsgWithType:@"workout" msg:totalFailureDesc prependNewlines:NO includePrivacyInfo:YES error:setsError];
          dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [PEUIUtils showErrorAlertWithMsgs:nil
                                        title:@"Error saving to Apple Health"
                             alertDescription:totalFailureDesc
                          descLblHeightAdjust:0.0
                    additionalContentSections:nil
                                     topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                   errorOkayButtonAction();
                                   [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                                 }
                               relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          });
        } else {
          [[[APP window] visibleViewController].view makeToast:@"Error syncing to Apple Health"];
          if (errorOkayButtonAction) {
            errorOkayButtonAction();
          }
        }
      }
    }
                   forceSyncAllComputedWorkouts:YES
                       raiseNotificationOnError:NO
                                       coordDao:coordDao
                                    healthStore:healthStore];
  });
}

+ (void)syncSetsToHealthkitWithSyncPromptDesc:(NSMutableAttributedString *)syncPromptDesc
                             includeFutureMsg:(BOOL)includeFutureMsg
                           noSetsToSyncAction:(void(^)(void))noSetsToSyncAction
                     displayNoSetsToSyncAlert:(BOOL)displayNoSetsToSyncAlert
                      successOkayButtonAction:(void(^)(void))successOkayButtonAction
                        errorOkayButtonAction:(void(^)(void))errorOkayButtonAction
                                 notNowAction:(void(^)(void))notNowAction
                                   controller:(PEBaseController *)controller
                                     coordDao:(id<RCoordinatorDao>)coordDao
                                  healthStore:(HKHealthStore *)healthStore
                                uiInteraction:(BOOL)uiInteraction {
  MBProgressHUD *hud = nil;
  if (uiInteraction) {
    hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    hud.tag = RHUD_TAG;
    hud.delegate = controller;
  }
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      void(^handleNoSetsToSync)(BOOL) = ^(BOOL setsButNotOldEnough) {
          if (uiInteraction) {
              if (displayNoSetsToSyncAlert) {
                  NSMutableAttributedString *noWorkoutsDesc = [[NSMutableAttributedString alloc] init];
                  NSString *alertTitle;
                  if (setsButNotOldEnough) {
                      alertTitle = @"Workout in-Progress?";
                      [noWorkoutsDesc appendAttributedString:AS(@"You have new sets but they are pretty new and so you might still be working out.\n\nWait a little while after your workout is done to sync them.")];
                  } else {
                      alertTitle = @"No Workouts to Sync";
                      [noWorkoutsDesc appendAttributedString:AS(@"You don't have any new workouts to sync to Apple Health.")];
                  }
                  if (includeFutureMsg) {
                      [noWorkoutsDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFuture sets can be grouped and synced as workouts periodically using the %@ button."
                                                                                      textToAccent:[@"Sync Workouts" nonBreaking]
                                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
                  }
                  UIView *alertParentView = [PEUIUtils parentViewForAlertsForController:controller];
                  [PEUIUtils showInfoAlertWithTitle:alertTitle
                                   alertDescription:noWorkoutsDesc
                                descLblHeightAdjust:0.0
                          additionalContentSections:@[[PEUIUtils infoAlertSectionWithTitle:@"Auto-Sync"
                                                                          alertDescription:AS(@"Just a heads-up: When opened, Riker will attempt to auto-sync your completed workouts to Apple Health.  Using the 'Sync Workouts' button is not strictly necessary.")
                                                                       descLblHeightAdjust:0.0
                                                                            relativeToView:alertParentView]]
                                           topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                        buttonTitle:@"Okay."
                                       buttonAction:noSetsToSyncAction
                                     relativeToView:alertParentView];
              } else {
                  if (noSetsToSyncAction) {
                      noSetsToSyncAction();
                  }
              }
          } else {
              if (noSetsToSyncAction) {
                  noSetsToSyncAction();
              }
          }
      };
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = [coordDao userWithError:errorBlk];
      NSDate *mostRecentSetDate = [coordDao mostRecentSetDateForUser:user error:errorBlk];
      if (mostRecentSetDate) {
          // only proceed further if the most recent set date is older than an hour
          NSDate *now = [NSDate date];
          double secondsDouble = [now secondsLaterThan:mostRecentSetDate];
          DDLogDebug(@"inside syncSetsToHealthkitWithSyncPromptDesc, it has been %f seconds since your last recorded set.", secondsDouble);
          if (secondsDouble >= SECONDS_IN_HOUR) {
              // the most recent set was logged over an hour ago, so we are okay to try
              // to group the sets into workouts and sync to Apple Health
              NSDate *lastWorkoutEndDate = [RUtils lastHkWorkoutEndDate];
              NSInteger numSetsToSync = 0;
              if (lastWorkoutEndDate) {
                  numSetsToSync = [coordDao numSetsForUser:user loggedSince:lastWorkoutEndDate error:errorBlk];
              } else {
                  numSetsToSync = [coordDao numSetsForUser:user error:errorBlk];
              }
              DDLogDebug(@"inside syncSetsToHealthkitWithSyncPromptDesc, you have %ld sets to sync to Apple Health", (long)numSetsToSync);
              dispatch_async(dispatch_get_main_queue(), ^{
                  [RUtils appendHkSyncPromptAlertDesc:syncPromptDesc numSetsToSync:numSetsToSync numBmlsToSync:0];
                  if (hud) {
                      [hud hideAnimated:YES];
                  }
                  if (numSetsToSync > 0) {
                      if (uiInteraction) {
                          [PEUIUtils showConfirmAlertWithTitle:@"Confirm sync to Apple Health"
                                                    titleImage:[UIImage imageNamed:@"info"]
                                              alertDescription:syncPromptDesc
                                           descLblHeightAdjust:0.0
                                                      topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                               okayButtonTitle:@"Sync now to Apple Health."
                                              okayButtonAction:^{
                                                  [RUtils setsOnlyDoHkSyncIncludeFutureMsg:includeFutureMsg
                                                                   successOkayButtonAction:successOkayButtonAction
                                                                     errorOkayButtonAction:errorOkayButtonAction
                                                                                controller:controller
                                                                                  coordDao:coordDao
                                                                               healthStore:healthStore
                                                                             uiInteraction:uiInteraction];
                                              }
                                               okayButtonStyle:JGActionSheetButtonStyleBlue
                                             cancelButtonTitle:@"Not now."
                                            cancelButtonAction:notNowAction
                                              cancelButtonSyle:JGActionSheetButtonStyleCancel
                                    secondaryCancelButtonTitle:@"Don't sync these.  Skip them."
                                   secondaryCancelButtonAction:^{
                                       NSArray *sets = [coordDao descendingSetsForUser:user pageSize:1 error:errorBlk];
                                       RSet *latestSet = [sets firstObject];
                                       if (latestSet) {
                                           [RUtils setLastHkWorkoutEndDate:latestSet.loggedAt];
                                           [[NSNotificationCenter defaultCenter] postNotificationName:RWorkoutsSavedToHealthKitNotification
                                                                                               object:nil];
                                       }
                                   }
                                     secondaryCancelButtonSyle:JGActionSheetButtonStyleCancel
                                                relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                      } else {
                          [RUtils setsOnlyDoHkSyncIncludeFutureMsg:includeFutureMsg
                                           successOkayButtonAction:successOkayButtonAction
                                             errorOkayButtonAction:errorOkayButtonAction
                                                        controller:controller
                                                          coordDao:coordDao
                                                       healthStore:healthStore
                                                     uiInteraction:uiInteraction];
                      }
                  } else {
                      handleNoSetsToSync(NO);
                  }
              });
          } else {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (hud) {
                [hud hideAnimated:YES];
              }
              handleNoSetsToSync(YES);
            });
          }
      } else {
          dispatch_async(dispatch_get_main_queue(), ^{
              [RUtils appendHkSyncPromptAlertDesc:syncPromptDesc numSetsToSync:0 numBmlsToSync:0];
              if (hud) {
                  [hud hideAnimated:YES];
              }
              handleNoSetsToSync(NO);
          });
      }
  });
}

+ (void)saveHealthKitWorkoutsWithCompletion:(void(^)(NSInteger, NSInteger, BOOL, NSError *))completion
               forceSyncAllComputedWorkouts:(BOOL)forceSyncAllComputedWorkouts
                   raiseNotificationOnError:(BOOL)raiseNotificationOnError
                                   coordDao:(id<RCoordinatorDao>)coordDao
                                healthStore:(HKHealthStore *)healthStore {
  if ([RUtils healthKitEnabledAt]) {
    NSDate *hkWorkoutSaveDisabledAt = [RUtils hkWorkoutSaveDisabledAt];
    if (!hkWorkoutSaveDisabledAt) {
      NSDate *since = [RUtils lastHkWorkoutEndDate];
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = (PELMUser *)[coordDao userWithError:errorBlk];
      NSArray *sets;
      if (since) {
        sets = [coordDao descendingSetsForUser:user since:since error:errorBlk];
      } else {
        sets = [coordDao descendingSetsForUser:user error:errorBlk];
      }
      NSArray *workoutsTuple = [RUtils workoutsTupleForDescendingSets:sets
                                                                 user:user
                                                         userSettings:nil
                                                     allMovementsDict:nil
                                                  allMuscleGroupsDict:nil
                                                       allMusclesDict:nil
                                                             forWatch:NO
                                                             coordDao:coordDao
                                                                error:errorBlk];
      NSArray *workouts = workoutsTuple[0];
      if (workouts.count > 0) {
        NSDate *lastSetLoggedAt = workoutsTuple[1];
        NSInteger numSets = ((NSNumber *)workoutsTuple[2]).integerValue;
        NSMutableArray *hkworkouts = [NSMutableArray arrayWithCapacity:workouts.count];
        for (RWorkout *workout in workouts) {
          [hkworkouts addObject:[RUtils hkworkoutFromWorkout:workout]];
        }
        NSInteger numWorkouts = hkworkouts.count;
        if (!forceSyncAllComputedWorkouts) {
          [hkworkouts removeLastObject]; // only sync the beginning workouts; the last workout could still be in-progress by the user
          DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, removed last hk workout from computed list - could still be in-progress.  Num workouts to sync: [%ld]", (long)numWorkouts);
        }
        DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, %ld HealthKit (hk) workouts computed.", (long)numWorkouts);
        [healthStore saveObjects:hkworkouts withCompletion:^(BOOL success, NSError * _Nullable error) {
          if (success) {
            DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, success saving %ld hk workouts.", (long)numWorkouts);
            [RUtils setLastHkWorkoutEndDate:lastSetLoggedAt];
            [RUtils clearHkWorkoutDisabledAt];
            [[NSNotificationCenter defaultCenter] postNotificationName:RWorkoutsSavedToHealthKitNotification
                                                                object:self
                                                              userInfo:nil];
          } else {
            if (error) {
              DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, error saving %ld hk workouts: %@.", (long)numWorkouts, error);
              switch (error.code) {
                case HKErrorAuthorizationDenied:
                  [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                  break;
              }
              if (raiseNotificationOnError) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RErrorSavingWorkoutsToHealthKitNotification
                                                                    object:self
                                                                  userInfo:@{@"error": error}];
              }
            }
          }
          if (completion) {
            completion(numSets, numWorkouts, success, error);
          }
        }];
      } else {
        DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, skipping save to Healthkit.  Computed workout count is 0.");
      }
    } else {
      DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, skipping save to HealthKit.  Saving workouts to HealthKit disabled at: [%@].", hkWorkoutSaveDisabledAt);
    }
  } else {
    DDLogDebug(@"Inside RUtils/saveHealthKitWorkouts, skipping save to HealthKit.  HealthKit integration currently not enabled.");
  }
}

+ (HKWorkout *)hkworkoutFromWorkout:(RWorkout *)workout {
  return [HKWorkout workoutWithActivityType:HKWorkoutActivityTypeTraditionalStrengthTraining
                                  startDate:workout.startDate
                                    endDate:workout.endDate
                                   duration:workout.durationSeconds
                          totalEnergyBurned:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:workout.caloriesBurned.doubleValue]
                              totalDistance:nil
                                   metadata:nil];
}

+ (NSDecimalNumber *)caloriesBurnedForBodyWeightLbs:(NSDecimalNumber *)bodyWeightLbs
                                    workoutDuration:(NSInteger)durationSeconds
                                           vigorous:(BOOL)vigorous {
  NSDecimalNumber *vigorousMultiplier;
  if (vigorous) {
    vigorousMultiplier = [[NSDecimalNumber alloc] initWithDouble:0.024];
  } else {
    vigorousMultiplier = [[NSDecimalNumber alloc] initWithDouble:0.012];
  }
  // why 30?  Because the Harvard study gave samples at 30lb intervals
  // http://www.health.harvard.edu/diet-and-weight-loss/calories-burned-in-30-minutes-of-leisure-and-routine-activities
  return [[[bodyWeightLbs decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:30]]
           decimalNumberByMultiplyingBy:vigorousMultiplier]
          decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:durationSeconds]];
}

+ (void)saveHealthKitBmlsWithCompletion:(void(^)(NSInteger, BOOL, NSError *))completion
                                noOpBlk:(void(^)(void))noOpBlk
               raiseNotificationOnError:(BOOL)raiseNotificationOnError
                               coordDao:(id<RCoordinatorDao>)coordDao
                            healthStore:(HKHealthStore *)healthStore {
  if ([self healthKitEnabledAt]) {
    NSDate *hkBodyWeightSaveDisabledAt = [self hkBodyWeightSaveDisabledAt];
    if (!hkBodyWeightSaveDisabledAt) {
      NSArray *bmls;
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = [coordDao userWithError:errorBlk];
      NSDate *since = [self lastHkBodyWeightEndDate];
      if (since) {
        bmls = [coordDao ascendingBmlsWithNonNilBodyWeightForUser:user loggedSince:since error:errorBlk];
        DDLogDebug(@"Inside RUtils/saveHealthKitBmls, num body weight bmls since: [%@]: [%ld]", since, (unsigned long)bmls.count);
      } else {
        bmls = [coordDao ascendingBmlsWithNonNilBodyWeightForUser:user error:errorBlk];
        DDLogDebug(@"Inside RUtils/saveHealthKitBmls, num all body weight bmls: [%ld]", (unsigned long)bmls.count);
      }
      if (bmls.count > 0) {
        NSMutableArray *hkBodyWeights = [NSMutableArray arrayWithCapacity:bmls.count];
        for (RBodyMeasurementLog *bml in bmls) {
          HKUnit *unit;
          NSDecimalNumber *multiplier;
          if (bml.bodyWeightUom.integerValue == LBS_ID) {
            unit = [HKUnit poundUnit];
            multiplier = [NSDecimalNumber one];
          } else {
            unit = [HKUnit gramUnit];
            multiplier = [[NSDecimalNumber alloc] initWithInteger:1000];
          }
          [hkBodyWeights addObject:[HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                   quantity:[HKQuantity quantityWithUnit:unit
                                                                                             doubleValue:[bml.bodyWeight decimalNumberByMultiplyingBy:multiplier].doubleValue]
                                                                  startDate:bml.loggedAt
                                                                    endDate:bml.loggedAt]];
        }
        RBodyMeasurementLog *lastBml = [bmls lastObject];
        NSDate *lastBmlLoggedAt = lastBml.loggedAt;
        [healthStore saveObjects:hkBodyWeights withCompletion:^(BOOL success, NSError * _Nullable error) {
          if (success) {
            DDLogDebug(@"Inside RUtils/saveHealthKitBmls, success saving [%ld] body weights to HealthKit.", (unsigned long)hkBodyWeights.count);
            [RUtils setLastHkBodyWeightEndDate:lastBmlLoggedAt];
            [RUtils clearHkBodyWeightDisabledAt];
            [[NSNotificationCenter defaultCenter] postNotificationName:RBodyWeightsSavedToHealthKitNotification
                                                                object:self
                                                              userInfo:nil];
          } else {
            DDLogDebug(@"Inside RUtils/saveHealthKitBmls, error saving [%ld] body weights to HealthKit: %@", (unsigned long)hkBodyWeights.count, error);
            if (error) {
              switch (error.code) {
                case HKErrorAuthorizationDenied:
                  [RUtils setHkBodyWeightSaveDisabledAt:[NSDate date]];
                  break;
              }
              if (raiseNotificationOnError) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RErrorSavingBodyWeightToHealthKitNotification
                                                                    object:self
                                                                  userInfo:@{@"error": error}];
              }
            }
          }
          if (completion) {
            completion(bmls.count, success, error);
          }
        }];
      } else {
        DDLogDebug(@"Inside RUtils/saveHealthKitBmls, no BMLs to sync.");
        if (noOpBlk) { noOpBlk(); }
      }
    } else {
      DDLogDebug(@"Inside RUtils/saveHealthKitBmls, skipping save to HealthKit.  Saving body weights to HealthKit disabled at: [%@].", hkBodyWeightSaveDisabledAt);
      if (noOpBlk) { noOpBlk(); }
    }
  } else {
    DDLogDebug(@"Inside RUtils/saveHealthKitBmls, skipping save to HealthKit.  HealthKit integration currently not enabled.");
    if (noOpBlk) { noOpBlk(); }
  }
}

+ (void)setLastHkWorkoutEndDate:(NSDate *)endDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:endDate forKey:RHealthKitLastWorkoutEndDate];
}

+ (NSDate *)lastHkWorkoutEndDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RHealthKitLastWorkoutEndDate];
}

+ (void)clearHkWorkoutEndDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:RHealthKitLastWorkoutEndDate];
}

+ (void)setHkWorkoutSaveDisabledAt:(NSDate *)deniedDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:deniedDate forKey:RHealthKitWorkoutSaveDisabledAt];
}

+ (NSDate *)hkWorkoutSaveDisabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RHealthKitWorkoutSaveDisabledAt];
}

+ (void)clearHkWorkoutDisabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:RHealthKitWorkoutSaveDisabledAt];
}

+ (void)setLastHkBodyWeightEndDate:(NSDate *)endDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:endDate forKey:RHealthKitLastBodyWeightEndDate];
}

+ (NSDate *)lastHkBodyWeightEndDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RHealthKitLastBodyWeightEndDate];
}

+ (void)clearHkBodyWeightEndDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:RHealthKitLastBodyWeightEndDate];
}

+ (void)setHkBodyWeightSaveDisabledAt:(NSDate *)deniedDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:deniedDate forKey:RHealthKitBodyWeightSaveDisabledAt];
}

+ (NSDate *)hkBodyWeightSaveDisabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RHealthKitBodyWeightSaveDisabledAt];
}

+ (void)clearHkBodyWeightDisabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:RHealthKitBodyWeightSaveDisabledAt];
}

+ (NSDate *)healthKitEnabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RHealthKitEnabledAtKey];
}

+ (void)setHealthKitEnabledAt:(NSDate *)enabledAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:enabledAt forKey:RHealthKitEnabledAtKey];
}

+ (void)disableHealthKit {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:RHealthKitEnabledAtKey];
}

#pragma mark - Weight Format Helpers

+ (NSNumberFormatter *)weightNumberFormatter {
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.numberStyle = NSNumberFormatterDecimalStyle;
  formatter.maximumFractionDigits = 1;
  formatter.roundingMode = NSNumberFormatterRoundHalfUp;
  return formatter;
}

+ (NSString *(^)(NSNumber *))weightFormatOrNilMaker {
  NSNumberFormatter *formatter = [RUtils weightNumberFormatter];
  return ^ NSString * (NSNumber *val) {
    return [PEUtils textForDecimal:(NSDecimalNumber *)val formatter:formatter textIfNil:@""];
  };
}

#pragma mark - Weight Lifted - Attributed Strings

+ (NSAttributedString *)weightLiftedMetricDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  [desc appendAttributedString:as(@"The %@ metric is the total amount of weight lifted for a set.  It is the number of reps multiplied by the weight used.",
                                  @"Weight Lifted")];
  [desc appendAttributedString:as(@"\n\nFor example, if you bench pressed 135 lbs for 10 reps, the %@ = 1,350 lbs.",
                                  @"weight lifted")];
  [desc appendAttributedString:AS(@"\n\nRiker uses this metric as an objective, quantative measure associated with your strength.  Several charts are provided for this metric.")];
  return desc;
}

+ (NSAttributedString *)aggregateWeightLiftedTimelineChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline charts illustrate your %@."
                                                        textToAccent:@"strength over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nAs you get stronger and are able to lift more weight, you should see the lines trending upwards over time.")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the total, aggregate weight lifted for that point in time.  If you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"total weight lifted")];
  [desc appendAttributedString:as(@"\n\nFor example, if your quadriceps lifted a grand total of 10,000 lbs over a contiguous 5-day period, and you have a filter set to aggregate %@, then the data point will display at 10,000 lbs.",
                                  @"by week")];
  return desc;
}

+ (NSAttributedString *)avgWeightLiftedTimelineChartsHelpDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"The average timeline charts illustrate your %@."
                                                        textToAccent:@"strength per set over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nAs you get stronger and are able to lift more weight, you should see the lines trending upwards over time.")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the average weight lifted per set for that point in time.  For example, if you did 3 sets of curls: \n(1) 10 reps of 95 lbs, \n(2) 8 reps of 90 lbs and \n(3) 8 reps of 80 lbs, your total weight lifted would be: 2,310 lbs.  Your average per set would be: 770 lbs.\n\nIf you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"average weight lifted per set")];
  return desc;
}

+ (NSAttributedString *)aggregateWeightLiftedPieChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These pie charts show %@.  There are charts to show how your strength is distributed across your muscle groups and movement variants."
                                                        textToAccent:@"where your strength is distributed"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nThey are helpful for shedding light on areas of your strength training that you may neglect or overwork.")];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFor example, if you don't do enough lower body training, that would show in the %@ pie chart.  The lower body slice would be disproportionately smaller than the upper body slice."
                                                        textToAccent:@"Total Weight Lifted - Body Segments"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  return desc;
}

+ (NSAttributedString *)weightLiftedDistributionTimelineChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline distribution charts illustrate %@."
                                                        textToAccent:@"where your strength is distributed over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nFor example, if over time you begin to neglect lower body training, you will see the lower body line trend downwards over time, and the upper body line trend upwards.")];
  return desc;
}

#pragma mark - Reps - Attributed Strings

+ (NSAttributedString *)repsMetricDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:as(@"The %@ metric is simply the number of reps done for a set (regardless of the weight used).",
                                  @"Reps")];
  [desc appendAttributedString:AS(@"\n\nSeveral charts are provided for this metric.")];
  return desc;
}

+ (NSAttributedString *)aggregateRepsLiftedPieChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These pie charts enable you to make comparisons with the %@ metric across time periods."
                                                        textToAccent:@"Reps"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nThey are helpful for spotting training inconsistencies.")];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFor example, if you tend to do very high rep sets for your shoulder movements, but then do very low-rep movements for all your chest movements, that would show in the %@ pie chart.  The shoulders slice would be disproportionately larger than the chest slice."
                                                        textToAccent:@"Total Reps - Muscle Groups"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  return desc;
}

+ (NSAttributedString *)aggregateRepsLiftedTimelineChartsHelpDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline charts illustrate your %@."
                                                        textToAccent:@"sum total rep count over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:as(@"\n\nIf you're a beginner, as you get stronger and your %@, you should see the lines trending upwards over time.  Or, if you normally prefer doing high-rep sets, but decide to change to start doing heavier weight with less reps, you should see the lines trending downwards over time.",
                                  @"stamina increases")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the sum total rep count for that point in time.  If you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"aggregate rep count")];
  [desc appendAttributedString:as(@"\n\nFor example, if your shoulders did a grand total of 175 reps over a contiguous 3-day period, and you have a filter set to aggregate %@, then the data point will display at 175 reps.",
                                  @"by week")];
  return desc;
}

+ (NSAttributedString *)avgRepsPerSetTimelineChartsHelpDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline charts illustrate your %@."
                                                        textToAccent:@"average rep count over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:as(@"\n\nIf you're a beginner, as you get stronger and your %@, you should see the lines trending upwards over time.  Or, if you normally prefer doing high-rep sets, but decide to change to start doing heavier weight with less reps, you should see the lines trending downwards over time.",
                                  @"stamina increases")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the sum total rep count for that point in time.  If you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"average rep count")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the average rep count per set for that point in time.  For example, if you did 3 sets of calf raises: \n(1) 10 reps of 295 lbs, \n(2) 8 reps of 275 lbs and \n(3) 8 reps of 265 lbs, your total rep count would be: 26.  Your average per set would be: 8.7.\n\nIf you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"average rep count per set")];
  return desc;
}

+ (NSAttributedString *)repsDistributionTimelineChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline distribution charts illustrate %@."
                                                        textToAccent:@"where your reps are distributed over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nIf over time you change your workout style in terms of the number of reps that you typically do, the plot lines will trend accordingly.  They will trend upwards if you increase your rep count over time; downwards if you decrease your rep count over time.")];
  return desc;
}

#pragma mark - Time Between Sets - Attributed Strings

+ (NSAttributedString *)timeBetweenSetsMetricDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:as(@"The %@ metric is the amount of rest time spent between sets of the same movement and variant.",
                                  @"Time Between Sets")];
  [desc appendAttributedString:AS(@"\n\nFor example, if you do 3 sets of machine shoulder press, this metric captures your rest time between sets 1 and 2, and sets 2 and 3.")];
  [desc appendAttributedString:AS(@"\n\nTime spent between sets when switching to a new movement or variant is not counted.")];
  [desc appendAttributedString:AS(@"\n\nSeveral charts are provided for this metric.")];
  return desc;
}

+ (NSAttributedString *)aggregateTimeBetweenSetsSameMovPieChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These pie charts enable you to make comparisons with the %@ metric across time periods."
                                                        textToAccent:@"Total Time Spent Between Sets"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nThey are helpful for spotting training inconsistencies.")];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFor example, if you tend to take long rest periods between chest movement sets, but then have very short rest periods between back movement sets, that would show in the %@ pie chart.  The chest slice would be disproportionately larger than the back slice."
                                                        textToAccent:@"Total Time Spent Between Sets - Muscle Groups"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  return desc;
}

+ (NSAttributedString *)aggregateTimeBetweenSetsTimelineChartsHelpDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline charts illustrate your %@."
                                                        textToAccent:@"rest time spent between sets over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the total time spent between sets for that point in time.  If you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"total time spent between sets")];
  [desc appendAttributedString:as(@"\n\nFor example, if you spent a grand total of 20 minutes resting between sets of deadlifts over a contiguous 3-day period, and you have a filter set to aggregate %@, then the data point will display at 20 minutes.",
                                  @"by week")];
  return desc;
}

+ (NSAttributedString *)avgTimeBetweenSetsPerSetTimelineChartsHelpDesc {
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline charts illustrate your %@."
                                                        textToAccent:@"average rest time spent between sets over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nIf you change your workout style over time in terms of how long of a rest you take between sets, the data lines will trend accordingly.")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the average time between sets for that point in time.  If you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"average time spent between sets")];
  [desc appendAttributedString:as(@"\n\nEach point on a line represents the average time spent between sets for that point in time.  For example, if you did 3 sets of Arnold presses, and between sets (1) and (2) you rested for 45 seconds, and between sets (2) and (3) you rested for 54 seconds, your total time between sets would be: 99 seconds.  Your average per set would be: 49.5 seconds.\n\nIf you have a filter set to aggregate by week, month, etc., points represent the %@ over the selected time period.",
                                  @"average time spent between sets")];
  return desc;
}

+ (NSAttributedString *)timeBetweenSetsSameMovLiftedDistributionTimelineChartsHelpDesc {
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"These timeline distribution charts illustrate %@."
                                                        textToAccent:@"where your time spent between sets is distributed over time"
                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [desc appendAttributedString:AS(@"\n\nFor example, if over time you increase your rest time between sets for upper body training, or shorten your rest time for lower body training, you will see the upper body line trend upwards over time, and the upper body line trend downwards.")];
  return desc;
}

#pragma mark - Chart Helpers

+ (NSString *(^)(RMuscleGroup *))makeAbbrevMgBlk {
  return ^(RMuscleGroup *mg) {
    return [PEUtils isNotNil:mg.abbrevName] ? mg.abbrevName : mg.name;
  };
}

+ (void (^)(NSMutableDictionary *, NSString *))makeSingleEntityTimeSeriesBlk {
  return ^(NSMutableDictionary *dict, NSString *name) {
    NSNumber *lmIdKey = @(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER);
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = [[RRawLineDataPointsByDateTuple alloc] init];
    rawLineDataPointsByDateTuple.dataPointsByDate = [NSMutableDictionary dictionary];
    rawLineDataPointsByDateTuple.name = name;
    rawLineDataPointsByDateTuple.localMasterIdentifier = lmIdKey;
    dict[lmIdKey] = rawLineDataPointsByDateTuple;
  };
}

+ (void(^)(NSMutableDictionary *, RBodySegment *))makeInitBsPieSliceBlk {
  return ^(NSMutableDictionary *dict, RBodySegment *bs) {
    RPieSliceDataTuple *pieSliceTuple = [[RPieSliceDataTuple alloc] init];
    pieSliceTuple.value = [NSDecimalNumber zero];
    pieSliceTuple.name = bs.name;
    pieSliceTuple.localMasterIdentifier = bs.localMasterIdentifier;
    dict[bs.localMasterIdentifier] = pieSliceTuple;
  };
}

+ (void (^)(NSMutableDictionary *, RBodySegment *))makeInitBsTimeSeriesBlk {
  return ^(NSMutableDictionary *dict, RBodySegment *bs) {
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = [[RRawLineDataPointsByDateTuple alloc] init];
    rawLineDataPointsByDateTuple.dataPointsByDate = [NSMutableDictionary dictionary];
    rawLineDataPointsByDateTuple.name = bs.name;
    rawLineDataPointsByDateTuple.localMasterIdentifier = bs.localMasterIdentifier;
    dict[bs.localMasterIdentifier] = rawLineDataPointsByDateTuple;
  };
}

+ (void(^)(NSMutableDictionary *, RMuscleGroup *))makeInitMgPieSliceBlkWithAbbrevMgBlk:(NSString *(^)(RMuscleGroup *))abbrevMg {
  return ^(NSMutableDictionary *dict, RMuscleGroup *mg) {
    RPieSliceDataTuple *pieSliceTuple = [[RPieSliceDataTuple alloc] init];
    pieSliceTuple.value = [NSDecimalNumber zero];
    pieSliceTuple.name = abbrevMg(mg);
    pieSliceTuple.localMasterIdentifier = mg.localMasterIdentifier;
    dict[mg.localMasterIdentifier] = pieSliceTuple;
  };
}

+ (void(^)(NSMutableDictionary *, RMuscleGroup *))makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:(NSString *(^)(RMuscleGroup *))abbrevMg {
  return ^(NSMutableDictionary *dict, RMuscleGroup *mg) {
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = [[RRawLineDataPointsByDateTuple alloc] init];
    rawLineDataPointsByDateTuple.dataPointsByDate = [NSMutableDictionary dictionary];
    rawLineDataPointsByDateTuple.name = abbrevMg(mg);
    rawLineDataPointsByDateTuple.localMasterIdentifier = mg.localMasterIdentifier;
    dict[mg.localMasterIdentifier] = rawLineDataPointsByDateTuple;
  };
}

+ (NSString *(^)(RMuscle *))makeAbbrevMuscleBlk {
  return ^(RMuscle *m) {
    return [PEUtils isNotNil:m.abbrevCanonicalName] ? m.abbrevCanonicalName : m.canonicalName;
  };
}

+ (void (^)(NSMutableDictionary *, RMuscle *))makeInitMuscleTimeSeriesBlkWithAbbrevMuscleBlk:(NSString *(^)(RMuscle *))abbrevMuscle {
  return ^(NSMutableDictionary *dict, RMuscle *muscle) {
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = [[RRawLineDataPointsByDateTuple alloc] init];
    rawLineDataPointsByDateTuple.dataPointsByDate = [NSMutableDictionary dictionary];
    rawLineDataPointsByDateTuple.name = abbrevMuscle(muscle);
    rawLineDataPointsByDateTuple.localMasterIdentifier = muscle.localMasterIdentifier;
    dict[muscle.localMasterIdentifier] = rawLineDataPointsByDateTuple;
  };
}

+ (void (^)(NSMutableDictionary *, RMuscle *))makeInitMusclePieSliceBlkWithAbbrevMuscleBlk:(NSString *(^)(RMuscle *))abbrevMuscle {
  return ^(NSMutableDictionary *dict, RMuscle *muscle) {
    RPieSliceDataTuple *pieSliceTuple = [[RPieSliceDataTuple alloc] init];
    pieSliceTuple.value = [NSDecimalNumber zero];
    pieSliceTuple.name = abbrevMuscle(muscle);
    pieSliceTuple.localMasterIdentifier = muscle.localMasterIdentifier;
    dict[muscle.localMasterIdentifier] = pieSliceTuple;
  };
}

+ (NSString *(^)(RMovementVariant *))makeAbbrevMvBlk {
  return ^(RMovementVariant *mv) {
    return [PEUtils isNotNil:mv.abbrevName] ? mv.abbrevName : mv.name;
  };
}

+ (void (^)(NSMutableDictionary *, RMovementVariant *))makeInitMvPieSliceBlkWithAbbrevMvBlk:(NSString *(^)(RMovementVariant *))abbrevMv {
  return ^(NSMutableDictionary *dict, RMovementVariant *mv) {
    RPieSliceDataTuple *pieSliceTuple = [[RPieSliceDataTuple alloc] init];
    pieSliceTuple.value = [NSDecimalNumber zero];
    pieSliceTuple.name = abbrevMv(mv);
    pieSliceTuple.localMasterIdentifier = mv.localMasterIdentifier;
    dict[mv.localMasterIdentifier] = pieSliceTuple;
  };
}

+ (void (^)(NSMutableDictionary *, RMovementVariant *))makeInitMvTimeSeriesBlkWithAbbrevMvBlk:(NSString *(^)(RMovementVariant *))abbrevMv {
  return ^(NSMutableDictionary *dict, RMovementVariant *mv) {
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = [[RRawLineDataPointsByDateTuple alloc] init];
    rawLineDataPointsByDateTuple.dataPointsByDate = [NSMutableDictionary dictionary];
    rawLineDataPointsByDateTuple.name = abbrevMv(mv);
    rawLineDataPointsByDateTuple.localMasterIdentifier = mv.localMasterIdentifier;
    dict[mv.localMasterIdentifier] = rawLineDataPointsByDateTuple;
  };
}

+ (void(^)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *))makeAddToBlk {
  return
  ^(NSDictionary *valsByLmIdDict, NSNumber *entityKey, NSDecimalNumber *valueToAdd, NSDate *loggedAt) {
    if (valueToAdd) { // short-circuit if nil (this would only occur for BMLs; not Sets)
      id chartDataTuple = valsByLmIdDict[entityKey];
      if (chartDataTuple) {
        if (loggedAt) { // if loggedAt is provided, then chartDataTuple is assumed to be for a line chart
          RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = chartDataTuple;
          NSMutableDictionary *dataPointsByDate = rawLineDataPointsByDateTuple.dataPointsByDate;
          RRawLineDataPointTuple *rawDataPointTuple = dataPointsByDate[loggedAt];
          if (rawDataPointTuple) {
            rawDataPointTuple.sum = [rawDataPointTuple.sum decimalNumberByAdding:valueToAdd];
            rawDataPointTuple.count++;
          } else {
            rawDataPointTuple = [[RRawLineDataPointTuple alloc] init];
            rawDataPointTuple.sum = valueToAdd;
            rawDataPointTuple.percentage = [NSDecimalNumber zero];
            rawDataPointTuple.count = 1;
            dataPointsByDate[loggedAt] = rawDataPointTuple;
          }
        } else { // assumed to be pie-chart style aggregate data
          RPieSliceDataTuple *pieSliceDataTuple = chartDataTuple;
          pieSliceDataTuple.value = [pieSliceDataTuple.value decimalNumberByAdding:valueToAdd];
        }
      }
    }
  };
}

+ (void (^)(NSMutableDictionary *, NSDate *))makeHolePluggerCalcPercentages:(BOOL)calcPercentages
                                                               calcAverages:(BOOL)calcAverages {
  return ^(NSMutableDictionary *dict, NSDate *loggedAt) {
    NSArray *localMasterIdentifiers = [dict allKeys];
    NSMutableArray *dataPointsByDateDicts = [NSMutableArray array];
    // collect all the time series dicts
    for (NSNumber *localMasterIdentifier in localMasterIdentifiers) {
      RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = dict[localMasterIdentifier];
      NSMutableDictionary *dataPointsByDate = rawLineDataPointsByDateTuple.dataPointsByDate;
      [dataPointsByDateDicts addObject:dataPointsByDate];
    }
    // fill empty holes with "zeros" and calculate total val
    NSDecimalNumber *totalVal = [NSDecimalNumber zero];
    for (NSMutableDictionary *dataPointsByDate in dataPointsByDateDicts) {
      RRawLineDataPointTuple *rawDataPointTuple = dataPointsByDate[loggedAt];
      if (rawDataPointTuple) {
        NSDecimalNumber *val = rawDataPointTuple.sum;
        totalVal = [totalVal decimalNumberByAdding:val];
      } else {
        rawDataPointTuple = [[RRawLineDataPointTuple alloc] init];
        rawDataPointTuple.sum = [NSDecimalNumber zero];
        rawDataPointTuple.percentage = [NSDecimalNumber zero];
        rawDataPointTuple.count = 0;
        rawDataPointTuple.avg = [NSDecimalNumber zero];
        dataPointsByDate[loggedAt] = rawDataPointTuple;
      }
    }
    // 2nd pass to fill percentages and average values
    if (calcPercentages || calcAverages) {
      if (!([totalVal compare:[NSDecimalNumber zero]] == NSOrderedSame)) {
        for (NSMutableDictionary *dataPointsByDate in dataPointsByDateDicts) {
          RRawLineDataPointTuple *rawDataPointTuple = dataPointsByDate[loggedAt];
          NSDecimalNumber *value = rawDataPointTuple.sum;
          if (calcPercentages) {
            rawDataPointTuple.percentage = [value decimalNumberByDividingBy:totalVal];
          }
          if (calcAverages) {
            NSInteger count = rawDataPointTuple.count;
            if (count > 0) {
              rawDataPointTuple.avg = [value decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:count]];
            }
          }
        }
      }
    }
  };
}

+ (BOOL)doesSet:(RSet *)set1 haveSameMovementVariantAsSet:(RSet *)set2 {
  if (set1.movementVariantId == nil && set2.movementVariantId == nil) {
    return YES;
  }
  if (set1.movementVariantId) {
    if (set2.movementVariantId) {
      return [set1.movementVariantId isEqualToNumber:set2.movementVariantId];
    }
  }
  return NO;
}

+ (NSString *)dictKeyForMovementId:(NSNumber *)movementId movementVariantId:(NSNumber *)movementVariantId {
  return [NSString stringWithFormat:@"%@-%@", movementId, movementVariantId];
}

+ (NSString *)globalChartIdWithCategory:(RChartConfigCategory)category user:(PELMUser *)user {
  return [NSString stringWithFormat:@"global-%ld-user-%@", (long)category, user.localMasterIdentifier];
}

+ (RChartStrengthRawData *)chartStrengthRawDataForUser:(PELMUser *)user
                                          userSettings:(RUserSettings *)userSettings
                                          bodySegments:(NSArray *)bodySegments
                                      bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                          muscleGroups:(NSArray *)muscleGroups
                                      muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                               muscles:(NSArray *)muscles
                                           musclesDict:(NSDictionary *)musclesDict
                                             movements:(NSArray *)movements
                                         movementsDict:(NSDictionary *)movementsDict
                                      movementVariants:(NSArray *)movementVariants
                                  movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                  sets:(NSArray *)sets
                                             fetchMode:(RChartDataFetchMode)fetchMode
                                       calcPercentages:(BOOL)calcPercentages
                                          calcAverages:(BOOL)calcAverages {
  switch (fetchMode) {
    case RChartDataFetchModeAllCrossSection: // not used (is here to avoid warning)
      return nil;
    case RChartDataFetchModeWeightLiftedCrossSection:
      return [RUtils weightLiftedChartRawDataCrossSectionForUserSettings:userSettings
                                                            muscleGroups:muscleGroups
                                                        muscleGroupsDict:muscleGroupsDict
                                                             musclesDict:musclesDict
                                                           movementsDict:movementsDict
                                                                    sets:sets
                                                         calcPercentages:calcPercentages
                                                            calcAverages:calcAverages];
    case RChartDataFetchModeRepsCrossSection:
      return [RUtils repsChartRawDataCrossSectionForMuscleGroups:muscleGroups
                                                muscleGroupsDict:muscleGroupsDict
                                                     musclesDict:musclesDict
                                                   movementsDict:movementsDict
                                                            sets:sets
                                                 calcPercentages:calcPercentages
                                                    calcAverages:calcAverages];
    case RChartDataFetchModeTimeBetweenSetsCrossSection:
      return [RUtils timeBetweenSetsChartRawDataCrossSectionForMuscleGroups:muscleGroups
                                                           muscleGroupsDict:muscleGroupsDict
                                                                musclesDict:musclesDict
                                                              movementsDict:movementsDict
                                                                       sets:sets
                                                            calcPercentages:calcPercentages
                                                               calcAverages:calcAverages];
    case RChartDataFetchModeWeightLiftedLine:
      return [RUtils doWeightLiftedLineChartStrengthRawDataForUser:user
                                                      userSettings:userSettings
                                                      bodySegments:bodySegments
                                                  bodySegmentsDict:bodySegmentsDict
                                                      muscleGroups:muscleGroups
                                                  muscleGroupsDict:muscleGroupsDict
                                                           muscles:muscles
                                                       musclesDict:musclesDict
                                                         movements:movements
                                                     movementsDict:movementsDict
                                                  movementVariants:movementVariants
                                              movementVariantsDict:movementVariantsDict
                                                              sets:sets
                                                   calcPercentages:calcPercentages
                                                      calcAverages:calcAverages];
    case RChartDataFetchModeWeightLiftedDist:
      return [RUtils doTotalWeightLiftedDistChartStrengthRawDataForUser:user
                                                           userSettings:userSettings
                                                           bodySegments:bodySegments
                                                       bodySegmentsDict:bodySegmentsDict
                                                           muscleGroups:muscleGroups
                                                       muscleGroupsDict:muscleGroupsDict
                                                                muscles:muscles
                                                            musclesDict:musclesDict
                                                              movements:movements
                                                          movementsDict:movementsDict
                                                       movementVariants:movementVariants
                                                   movementVariantsDict:movementVariantsDict
                                                                   sets:sets];
    case RChartDataFetchModeRepsLine:
      return [RUtils doRepsLineChartStrengthRawDataForUser:user
                                              userSettings:userSettings
                                              bodySegments:bodySegments
                                          bodySegmentsDict:bodySegmentsDict
                                              muscleGroups:muscleGroups
                                          muscleGroupsDict:muscleGroupsDict
                                                   muscles:muscles
                                               musclesDict:musclesDict
                                                 movements:movements
                                             movementsDict:movementsDict
                                          movementVariants:movementVariants
                                      movementVariantsDict:movementVariantsDict
                                                      sets:sets
                                           calcPercentages:calcPercentages
                                              calcAverages:calcAverages];
    case RChartDataFetchModeRepsDist:
      return [RUtils doRepsDistChartStrengthRawDataForUser:user
                                              userSettings:userSettings
                                              bodySegments:bodySegments
                                          bodySegmentsDict:bodySegmentsDict
                                              muscleGroups:muscleGroups
                                          muscleGroupsDict:muscleGroupsDict
                                                   muscles:muscles
                                               musclesDict:musclesDict
                                                 movements:movements
                                             movementsDict:movementsDict
                                          movementVariants:movementVariants
                                      movementVariantsDict:movementVariantsDict
                                                      sets:sets];
    case RChartDataFetchModeTimeBetweenSetsLine:
      return [RUtils doTimeBetweenLineChartStrengthRawDataForUser:user
                                                     userSettings:userSettings
                                                     bodySegments:bodySegments
                                                 bodySegmentsDict:bodySegmentsDict
                                                     muscleGroups:muscleGroups
                                                 muscleGroupsDict:muscleGroupsDict
                                                          muscles:muscles
                                                      musclesDict:musclesDict
                                                        movements:movements
                                                    movementsDict:movementsDict
                                                 movementVariants:movementVariants
                                             movementVariantsDict:movementVariantsDict
                                                             sets:sets
                                                  calcPercentages:calcPercentages
                                                     calcAverages:calcAverages];
    case RChartDataFetchModeTimeBetweenSetsDist:
      return [RUtils doTimeBetweenDistChartStrengthRawDataForUser:user
                                                     userSettings:userSettings
                                                     bodySegments:bodySegments
                                                 bodySegmentsDict:bodySegmentsDict
                                                     muscleGroups:muscleGroups
                                                 muscleGroupsDict:muscleGroupsDict
                                                          muscles:muscles
                                                      musclesDict:musclesDict
                                                        movements:movements
                                                    movementsDict:movementsDict
                                                 movementVariants:movementVariants
                                             movementVariantsDict:movementVariantsDict
                                                             sets:sets];
  }
  return nil;
}

+ (RChartStrengthRawData *)weightLiftedChartRawDataCrossSectionForUserSettings:(RUserSettings *)userSettings
                                                                  muscleGroups:(NSArray *)muscleGroups
                                                              muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                   musclesDict:(NSDictionary *)musclesDict
                                                                 movementsDict:(NSDictionary *)movementsDict
                                                                          sets:(NSArray *)sets
                                                               calcPercentages:(BOOL)calcPercentages
                                                                  calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData crossSectionChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.weightLiftedByMuscleGroup, muscleGroup);
    initMgTimeSeriesDict(cd.weightByMuscleGroupTimeSeries, muscleGroup);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    NSDecimalNumber *weight = [RUtils weightValueWithValue:set.weight currentWeightUomId:set.weightUom targetWeightUomId:userSettings.weightUom];
    NSInteger numRepsInt = set.numReps.integerValue;
    NSDecimalNumber *totalWeight = [weight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:numRepsInt]];
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *primaryMusclesTotalWeight;
    if (secondaryMuscleIdsCount > 0) {
      primaryMusclesTotalWeight = [totalWeight decimalNumberByMultiplyingBy:primaryMusclePercentage];
    } else {
      primaryMusclesTotalWeight = totalWeight;
    }
    NSDecimalNumber *secondaryMusclesTotalWeight = [totalWeight decimalNumberBySubtracting:primaryMusclesTotalWeight];
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleWeight = [primaryMusclesTotalWeight decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleWeight = nil;
    if (secondaryMuscleIdsCount > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIdsCount];
      perSecondaryMuscleWeight = [secondaryMusclesTotalWeight decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyWeight)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *weightToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      addTo(cd.weightLiftedByMuscleGroup, muscleGroup.localMasterIdentifier, weightToAdd, nil);
      addTo(cd.weightByMuscleGroupTimeSeries, muscleGroup.localMasterIdentifier, weightToAdd, loggedAt);
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyWeight(primaryMuscleId, perPrimaryMuscleWeight);
    }
    if (perSecondaryMuscleWeight) {
      for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
        tallyWeight(secondaryMuscleId, perSecondaryMuscleWeight);
      }
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'weight' entity-dict containers
    plugHolesAndCalcPercentages(cd.weightByMuscleGroupTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartStrengthRawData *)repsChartRawDataCrossSectionForMuscleGroups:(NSArray *)muscleGroups
                                                      muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                           musclesDict:(NSDictionary *)musclesDict
                                                         movementsDict:(NSDictionary *)movementsDict
                                                                  sets:(NSArray *)sets
                                                       calcPercentages:(BOOL)calcPercentages
                                                          calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData crossSectionChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.totalRepsByMuscleGroup, muscleGroup);
    initMgTimeSeriesDict(cd.repsByMuscleGroupTimeSeries, muscleGroup);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    NSInteger numRepsInt = set.numReps.integerValue;
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *numReps = [[NSDecimalNumber alloc] initWithInteger:numRepsInt];
    NSDecimalNumber *primaryMusclesTotalReps = [numReps decimalNumberByMultiplyingBy:primaryMusclePercentage];
    NSDecimalNumber *secondaryMusclesTotalReps = [numReps decimalNumberBySubtracting:primaryMusclesTotalReps];
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleReps = [primaryMusclesTotalReps decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleReps = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      perSecondaryMuscleReps = [secondaryMusclesTotalReps decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyReps)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *repsToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      addTo(cd.totalRepsByMuscleGroup, muscleGroup.localMasterIdentifier, repsToAdd, nil);
      addTo(cd.repsByMuscleGroupTimeSeries, muscleGroup.localMasterIdentifier, repsToAdd, loggedAt);
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyReps(primaryMuscleId, perPrimaryMuscleReps);
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      tallyReps(secondaryMuscleId, perSecondaryMuscleReps);
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'reps' entity-dict containers
    plugHolesAndCalcPercentages(cd.repsByMuscleGroupTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartStrengthRawData *)timeBetweenSetsChartRawDataCrossSectionForMuscleGroups:(NSArray *)muscleGroups
                                                                 muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                      musclesDict:(NSDictionary *)musclesDict
                                                                    movementsDict:(NSDictionary *)movementsDict
                                                                             sets:(NSArray *)sets
                                                                  calcPercentages:(BOOL)calcPercentages
                                                                     calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData crossSectionChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.totalTimeBetweenSetsSameMovByMuscleGroup, muscleGroup);
    initMgTimeSeriesDict(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries, muscleGroup);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    NSDecimalNumber *timeBetweenSetsSameMov = nil;
    RSet *set = sets[i];
    RSet *nextSet = nil;
    if (i + 1 < numSets) {
      nextSet = sets[i + 1];
    }
    NSDate *loggedAt = set.loggedAt;
    if (nextSet) {
      NSDate *nextLoggedAt = nextSet.loggedAt;
      double secondsDouble = [loggedAt secondsEarlierThan:nextLoggedAt];
      if (secondsDouble < SECONDS_IN_HOUR && // don't count contiguous sets from different workouts
          secondsDouble > 0 && // if the diff is zero, then, well, something is fishy/wrong
          !set.ignoreTime && !nextSet.ignoreTime) { // obviously, right?
        NSDecimalNumber *seconds = [[NSDecimalNumber alloc] initWithDouble:secondsDouble];
        if ([set.movementId isEqualToNumber:nextSet.movementId]) { // we're within the same movement
          if ([RUtils doesSet:set haveSameMovementVariantAsSet:nextSet]) { // and the same variant
            timeBetweenSetsSameMov = seconds;
          } else { // we'll consider this a mov-transition too
            // do nothing for now...maybe add functionality in future release
          }
        } else { // we'll consider this a mov-transition
          // do nothing for now...maybe add functionality in future release
        }
      }
    }
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *primaryMusclesTimeBetweenSets = nil;
    NSDecimalNumber *secondaryMusclesTimeBetweenSets = nil;
    if (timeBetweenSetsSameMov) {
      if (secondaryMuscleIdsCount > 0) {
        primaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberByMultiplyingBy:primaryMusclePercentage];
      } else {
        primaryMusclesTimeBetweenSets = timeBetweenSetsSameMov;
      }
      secondaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberBySubtracting:primaryMusclesTimeBetweenSets];
    }
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleTimeBetweenSets = nil;
    if (primaryMusclesTimeBetweenSets) {
      perPrimaryMuscleTimeBetweenSets = [primaryMusclesTimeBetweenSets decimalNumberByDividingBy:primaryMusclesCount];
    }
    NSDecimalNumber *perSecondaryMuscleTimeBetweenSets = nil;
    if (secondaryMuscleIdsCount > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIdsCount];
      if (secondaryMusclesTimeBetweenSets) {
        perSecondaryMuscleTimeBetweenSets = [secondaryMusclesTimeBetweenSets decimalNumberByDividingBy:secondaryMusclesCount];
      }
    }
    void (^tallyTimeBetweenSets)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *timeToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      addTo(cd.totalTimeBetweenSetsSameMovByMuscleGroup, muscleGroup.localMasterIdentifier, timeToAdd, nil);
      addTo(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries, muscleGroup.localMasterIdentifier, timeToAdd, loggedAt);
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      if (perPrimaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(primaryMuscleId, perPrimaryMuscleTimeBetweenSets);
      }
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      if (perSecondaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(secondaryMuscleId, perSecondaryMuscleTimeBetweenSets);
      }
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'time between sets' entity-dict containers
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartStrengthRawData *)doTimeBetweenDistChartStrengthRawDataForUser:(PELMUser *)user
                                                           userSettings:(RUserSettings *)userSettings
                                                           bodySegments:(NSArray *)bodySegments
                                                       bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                                           muscleGroups:(NSArray *)muscleGroups
                                                       muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                muscles:(NSArray *)muscles
                                                            musclesDict:(NSDictionary *)musclesDict
                                                              movements:(NSArray *)movements
                                                          movementsDict:(NSDictionary *)movementsDict
                                                       movementVariants:(NSArray *)movementVariants
                                                   movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                                   sets:(NSArray *)sets {
  RChartStrengthRawData *cd = [RChartStrengthRawData timeBetweenDistChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initBsDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsPieSliceBlk];
  for (RBodySegment *bodySegment in bodySegments) {
    initBsDict(cd.totalTimeBetweenSetsSameMovByBodySegment, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.totalTimeBetweenSetsSameMovByMuscleGroup, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgDict(cd.totalTimeBetweenSetsSameMovByUpperBodySegment, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgDict(cd.totalTimeBetweenSetsSameMovByLowerBodySegment, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMusclePieSliceBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleDict(cd.totalTimeBetweenSetsSameMovByShoulderMg, muscle);
        break;
      case BACK_MG_ID:
        initMuscleDict(cd.totalTimeBetweenSetsSameMovByBackMg, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleDict(cd.totalTimeBetweenSetsSameMovByTricepsMg, muscle);
        break;
      case CORE_MG_ID:
        initMuscleDict(cd.totalTimeBetweenSetsSameMovByAbsMg, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleDict(cd.totalTimeBetweenSetsSameMovByChestMg, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvPieSliceBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize time-between-sets pie chart data
    initMvDict(cd.totalTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalUpperBodyTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalLowerBodyTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalShoulderTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalBackTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalTricepsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalBicepsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalForearmsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalAbsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalChestTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalHamstringsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalQuadsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalCalfsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalGlutesTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalHipAbductorsTimeBetweenSetsSameMovByMovementVariant, variant);
    initMvDict(cd.totalHipFlexorsTimeBetweenSetsSameMovByMovementVariant, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    NSDecimalNumber *timeBetweenSetsSameMov = nil;
    RSet *set = sets[i];
    RSet *nextSet = nil;
    if (i + 1 < numSets) {
      nextSet = sets[i + 1];
    }
    NSDate *loggedAt = set.loggedAt;
    if (nextSet) {
      NSDate *nextLoggedAt = nextSet.loggedAt;
      double secondsDouble = [loggedAt secondsEarlierThan:nextLoggedAt];
      if (secondsDouble < SECONDS_IN_HOUR && // don't count contiguous sets from different workouts
          secondsDouble > 0 && // if the diff is zero, then, well, something is fishy/wrong
          !set.ignoreTime && !nextSet.ignoreTime) { // obviously, right?
        NSDecimalNumber *seconds = [[NSDecimalNumber alloc] initWithDouble:secondsDouble];
        if ([set.movementId isEqualToNumber:nextSet.movementId]) { // we're within the same movement
          if ([RUtils doesSet:set haveSameMovementVariantAsSet:nextSet]) { // and the same variant
            timeBetweenSetsSameMov = seconds;
          } else { // we'll consider this a mov-transition too
            // do nothing for now...maybe add functionality in future release
          }
        } else { // we'll consider this a mov-transition
          // do nothing for now...maybe add functionality in future release
        }
      }
    }
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    NSDecimalNumber *primaryMusclesTimeBetweenSets = nil;
    NSDecimalNumber *secondaryMusclesTimeBetweenSets = nil;
    if (timeBetweenSetsSameMov) {
      if (secondaryMuscleIdsCount > 0) {
        primaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberByMultiplyingBy:primaryMusclePercentage];
      } else {
        primaryMusclesTimeBetweenSets = timeBetweenSetsSameMov;
      }
      secondaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberBySubtracting:primaryMusclesTimeBetweenSets];
      addTo(cd.totalTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeBetweenSetsSameMov, nil);
    }

    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleTimeBetweenSets = nil;
    if (primaryMusclesTimeBetweenSets) {
      perPrimaryMuscleTimeBetweenSets = [primaryMusclesTimeBetweenSets decimalNumberByDividingBy:primaryMusclesCount];
    }
    NSDecimalNumber *perSecondaryMuscleTimeBetweenSets = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      if (secondaryMusclesTimeBetweenSets) {
        perSecondaryMuscleTimeBetweenSets = [secondaryMusclesTimeBetweenSets decimalNumberByDividingBy:secondaryMusclesCount];
      }
    }
    void (^tallyTimeBetweenSets)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *timeToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.totalTimeBetweenSetsSameMovByChestMg,          muscle.localMasterIdentifier,      timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByTricepsMg,        muscle.localMasterIdentifier,      timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByAbsMg,            muscle.localMasterIdentifier,      timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByBackMg,           muscle.localMasterIdentifier,      timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByShoulderMg,       muscle.localMasterIdentifier,      timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByMuscleGroup,      muscleGroup.localMasterIdentifier, timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByBodySegment,      bodySegment.localMasterIdentifier, timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByUpperBodySegment, muscleGroup.localMasterIdentifier, timeToAdd, nil);
      addTo(cd.totalTimeBetweenSetsSameMovByLowerBodySegment, muscleGroup.localMasterIdentifier, timeToAdd, nil);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.totalUpperBodyTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.totalLowerBodyTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.totalShoulderTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case BACK_MG_ID:
          addTo(cd.totalBackTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case TRICEP_MG_ID:
          addTo(cd.totalTricepsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case BICEPS_MG_ID:
          addTo(cd.totalBicepsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.totalForearmsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case CORE_MG_ID:
          addTo(cd.totalAbsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case CHEST_MG_ID:
          addTo(cd.totalChestTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.totalHamstringsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.totalQuadsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case CALVES_MG_ID:
          addTo(cd.totalCalfsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case GLUTES_MG_ID:
          addTo(cd.totalGlutesTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.totalHipAbductorsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.totalHipFlexorsTimeBetweenSetsSameMovByMovementVariant, variant.localMasterIdentifier, timeToAdd, nil);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      if (perPrimaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(primaryMuscleId, perPrimaryMuscleTimeBetweenSets);
      }
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      if (perSecondaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(secondaryMuscleId, perSecondaryMuscleTimeBetweenSets);
      }
    }
  }
  return cd;
}

+ (RChartStrengthRawData *)doTimeBetweenLineChartStrengthRawDataForUser:(PELMUser *)user
                                                           userSettings:(RUserSettings *)userSettings
                                                           bodySegments:(NSArray *)bodySegments
                                                       bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                                           muscleGroups:(NSArray *)muscleGroups
                                                       muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                muscles:(NSArray *)muscles
                                                            musclesDict:(NSDictionary *)musclesDict
                                                              movements:(NSArray *)movements
                                                          movementsDict:(NSDictionary *)movementsDict
                                                       movementVariants:(NSArray *)movementVariants
                                                   movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                                   sets:(NSArray *)sets
                                                        calcPercentages:(BOOL)calcPercentages
                                                           calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData timeBetweenLineChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initSingleEntityTimeSeriesDict)(NSMutableDictionary *, NSString *) = [RUtils makeSingleEntityTimeSeriesBlk];
  void (^initBsTimeSeriesDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsTimeSeriesBlk];
  initSingleEntityTimeSeriesDict(cd.timeBetweenSetsSameMovTimeSeries, @"Total Time Spent Between Sets");
  for (RBodySegment *bodySegment in bodySegments) {
    initBsTimeSeriesDict(cd.timeBetweenSetsSameMovByBodySegmentTimeSeries, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgTimeSeriesDict(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.timeBetweenSetsSameMovByUpperBodySegmentTimeSeries, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.timeBetweenSetsSameMovByLowerBodySegmentTimeSeries, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleTimeSeriesDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMuscleTimeSeriesBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByShoulderMgTimeSeries, muscle);
        break;
      case BACK_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByBackMgTimeSeries, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByTricepsMgTimeSeries, muscle);
        break;
      case BICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByBicepsMgTimeSeries, muscle);
        break;
      case FOREARMS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByForearmsMgTimeSeries, muscle);
        break;
      case CORE_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByAbsMgTimeSeries, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByChestMgTimeSeries, muscle);
        break;
      case HAMSTRINGS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByHamstringsMgTimeSeries, muscle);
        break;
      case QUADRICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByQuadsMgTimeSeries, muscle);
        break;
      case CALVES_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByCalfsMgTimeSeries, muscle);
        break;
      case GLUTES_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByGlutesMgTimeSeries, muscle);
        break;
      case HIP_ABDUCTORS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByHipAbductorsMgTimeSeries, muscle);
        break;
      case HIP_FLEXORS_MG_ID:
        initMuscleTimeSeriesDict(cd.timeBetweenSetsSameMovByHipFlexorsMgTimeSeries, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvTimeSeriesDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvTimeSeriesBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize time-between-sets timeline data
    initMvTimeSeriesDict(cd.timeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.backTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.absTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.chestTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    NSDecimalNumber *timeBetweenSetsSameMov = nil;
    RSet *set = sets[i];
    RSet *nextSet = nil;
    if (i + 1 < numSets) {
      nextSet = sets[i + 1];
    }
    NSDate *loggedAt = set.loggedAt;
    if (nextSet) {
      NSDate *nextLoggedAt = nextSet.loggedAt;
      double secondsDouble = [loggedAt secondsEarlierThan:nextLoggedAt];
      if (secondsDouble < SECONDS_IN_HOUR && // don't count contiguous sets from different workouts
          secondsDouble > 0 && // if the diff is zero, then, well, something is fishy/wrong
          !set.ignoreTime && !nextSet.ignoreTime) { // obviously, right?
        NSDecimalNumber *seconds = [[NSDecimalNumber alloc] initWithDouble:secondsDouble];
        if ([set.movementId isEqualToNumber:nextSet.movementId]) { // we're within the same movement
          if ([RUtils doesSet:set haveSameMovementVariantAsSet:nextSet]) { // and the same variant
            timeBetweenSetsSameMov = seconds;
          } else { // we'll consider this a mov-transition too
            // do nothing for now...maybe add functionality in future release
          }
        } else { // we'll consider this a mov-transition
          // do nothing for now...maybe add functionality in future release
        }
      }
    }
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    NSDecimalNumber *primaryMusclesTimeBetweenSets = nil;
    NSDecimalNumber *secondaryMusclesTimeBetweenSets = nil;
    if (timeBetweenSetsSameMov) {
      if (secondaryMuscleIdsCount > 0) {
        primaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberByMultiplyingBy:primaryMusclePercentage];
      } else {
        primaryMusclesTimeBetweenSets = timeBetweenSetsSameMov;
      }
      secondaryMusclesTimeBetweenSets = [timeBetweenSetsSameMov decimalNumberBySubtracting:primaryMusclesTimeBetweenSets];
      addTo(cd.timeBetweenSetsSameMovTimeSeries, @(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER), timeBetweenSetsSameMov, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeBetweenSetsSameMov, loggedAt);
    }
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleTimeBetweenSets = nil;
    if (primaryMusclesTimeBetweenSets) {
      perPrimaryMuscleTimeBetweenSets = [primaryMusclesTimeBetweenSets decimalNumberByDividingBy:primaryMusclesCount];
    }
    NSDecimalNumber *perSecondaryMuscleTimeBetweenSets = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      if (secondaryMusclesTimeBetweenSets) {
        perSecondaryMuscleTimeBetweenSets = [secondaryMusclesTimeBetweenSets decimalNumberByDividingBy:secondaryMusclesCount];
      }
    }
    void (^tallyTimeBetweenSets)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *timeToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.timeBetweenSetsSameMovByChestMgTimeSeries,          muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByTricepsMgTimeSeries,        muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByBicepsMgTimeSeries,         muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByForearmsMgTimeSeries,       muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByAbsMgTimeSeries,            muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByHamstringsMgTimeSeries,     muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByQuadsMgTimeSeries,          muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByCalfsMgTimeSeries,          muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByGlutesMgTimeSeries,         muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByHipAbductorsMgTimeSeries,   muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByHipFlexorsMgTimeSeries,     muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByBackMgTimeSeries,           muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByShoulderMgTimeSeries,       muscle.localMasterIdentifier,      timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries,      muscleGroup.localMasterIdentifier, timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByBodySegmentTimeSeries,      bodySegment.localMasterIdentifier, timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByUpperBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, timeToAdd, loggedAt);
      addTo(cd.timeBetweenSetsSameMovByLowerBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, timeToAdd, loggedAt);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case BACK_MG_ID:
          addTo(cd.backTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case TRICEP_MG_ID:
          addTo(cd.tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case BICEPS_MG_ID:
          addTo(cd.bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case CORE_MG_ID:
          addTo(cd.absTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case CHEST_MG_ID:
          addTo(cd.chestTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case CALVES_MG_ID:
          addTo(cd.calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case GLUTES_MG_ID:
          addTo(cd.glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, variant.localMasterIdentifier, timeToAdd, loggedAt);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      if (perPrimaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(primaryMuscleId, perPrimaryMuscleTimeBetweenSets);
      }
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      if (perSecondaryMuscleTimeBetweenSets) {
        tallyTimeBetweenSets(secondaryMuscleId, perSecondaryMuscleTimeBetweenSets);
      }
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'time between sets' entity-dict containers
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByMuscleGroupTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByUpperBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByLowerBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByShoulderMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByBackMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByAbsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByHamstringsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByQuadsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByCalfsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByGlutesMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByHipAbductorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByHipFlexorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByChestMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByTricepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByForearmsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.timeBetweenSetsSameMovByBicepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.backTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.absTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.chestTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartStrengthRawData *)doRepsDistChartStrengthRawDataForUser:(PELMUser *)user
                                                    userSettings:(RUserSettings *)userSettings
                                                    bodySegments:(NSArray *)bodySegments
                                                bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                                    muscleGroups:(NSArray *)muscleGroups
                                                muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                         muscles:(NSArray *)muscles
                                                     musclesDict:(NSDictionary *)musclesDict
                                                       movements:(NSArray *)movements
                                                   movementsDict:(NSDictionary *)movementsDict
                                                movementVariants:(NSArray *)movementVariants
                                            movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                            sets:(NSArray *)sets {
  RChartStrengthRawData *cd = [RChartStrengthRawData repsDistChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initSingleEntityTimeSeriesDict)(NSMutableDictionary *, NSString *) = [RUtils makeSingleEntityTimeSeriesBlk];
  void (^initBsDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsPieSliceBlk];
  initSingleEntityTimeSeriesDict(cd.repsTimeSeries, @"Total Reps");
  for (RBodySegment *bodySegment in bodySegments) {
    initBsDict(cd.totalRepsByBodySegment, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.totalRepsByMuscleGroup, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgDict(cd.totalRepsByUpperBodySegment, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgDict(cd.totalRepsByLowerBodySegment, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMusclePieSliceBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleDict(cd.totalRepsByShoulderMg, muscle);
        break;
      case BACK_MG_ID:
        initMuscleDict(cd.totalRepsByBackMg, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleDict(cd.totalRepsByTricepsMg, muscle);
        break;
      case CORE_MG_ID:
        initMuscleDict(cd.totalRepsByAbsMg, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleDict(cd.totalRepsByChestMg, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvPieSliceBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize reps pie chart data
    initMvDict(cd.totalRepsByMovementVariant, variant);
    initMvDict(cd.totalUpperBodyRepsByMovementVariant, variant);
    initMvDict(cd.totalLowerBodyRepsByMovementVariant, variant);
    initMvDict(cd.totalShoulderRepsByMovementVariant, variant);
    initMvDict(cd.totalBackRepsByMovementVariant, variant);
    initMvDict(cd.totalTricepsRepsByMovementVariant, variant);
    initMvDict(cd.totalBicepsRepsByMovementVariant, variant);
    initMvDict(cd.totalForearmsRepsByMovementVariant, variant);
    initMvDict(cd.totalAbsRepsByMovementVariant, variant);
    initMvDict(cd.totalChestRepsByMovementVariant, variant);
    initMvDict(cd.totalHamstringsRepsByMovementVariant, variant);
    initMvDict(cd.totalQuadsRepsByMovementVariant, variant);
    initMvDict(cd.totalCalfsRepsByMovementVariant, variant);
    initMvDict(cd.totalGlutesRepsByMovementVariant, variant);
    initMvDict(cd.totalHipAbductorsRepsByMovementVariant, variant);
    initMvDict(cd.totalHipFlexorsRepsByMovementVariant, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    NSInteger numRepsInt = set.numReps.integerValue;
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *numReps = [[NSDecimalNumber alloc] initWithInteger:numRepsInt];
    NSDecimalNumber *primaryMusclesTotalReps = [numReps decimalNumberByMultiplyingBy:primaryMusclePercentage];
    NSDecimalNumber *secondaryMusclesTotalReps = [numReps decimalNumberBySubtracting:primaryMusclesTotalReps];
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    addTo(cd.totalRepsByMovementVariant, variant.localMasterIdentifier, numReps, nil);
    addTo(cd.repsByMovementVariantTimeSeries, variant.localMasterIdentifier, numReps, loggedAt);
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleReps = [primaryMusclesTotalReps decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleReps = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      perSecondaryMuscleReps = [secondaryMusclesTotalReps decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyReps)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *repsToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.totalRepsByChestMg,          muscle.localMasterIdentifier,      repsToAdd, nil);
      addTo(cd.totalRepsByTricepsMg,        muscle.localMasterIdentifier,      repsToAdd, nil);
      addTo(cd.totalRepsByAbsMg,            muscle.localMasterIdentifier,      repsToAdd, nil);
      addTo(cd.totalRepsByBackMg,           muscle.localMasterIdentifier,      repsToAdd, nil);
      addTo(cd.totalRepsByShoulderMg,       muscle.localMasterIdentifier,      repsToAdd, nil);
      addTo(cd.totalRepsByMuscleGroup,      muscleGroup.localMasterIdentifier, repsToAdd, nil);
      addTo(cd.totalRepsByBodySegment,      bodySegment.localMasterIdentifier, repsToAdd, nil);
      addTo(cd.totalRepsByUpperBodySegment, muscleGroup.localMasterIdentifier, repsToAdd, nil);
      addTo(cd.totalRepsByLowerBodySegment, muscleGroup.localMasterIdentifier, repsToAdd, nil);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.totalUpperBodyRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.totalLowerBodyRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.totalShoulderRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case BACK_MG_ID:
          addTo(cd.totalBackRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case TRICEP_MG_ID:
          addTo(cd.totalTricepsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case BICEPS_MG_ID:
          addTo(cd.totalBicepsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.totalForearmsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case CORE_MG_ID:
          addTo(cd.totalAbsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case CHEST_MG_ID:
          addTo(cd.totalChestRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.totalHamstringsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.totalQuadsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case CALVES_MG_ID:
          addTo(cd.totalCalfsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case GLUTES_MG_ID:
          addTo(cd.totalGlutesRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.totalHipAbductorsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.totalHipFlexorsRepsByMovementVariant, variant.localMasterIdentifier, repsToAdd, nil);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyReps(primaryMuscleId, perPrimaryMuscleReps);
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      tallyReps(secondaryMuscleId, perSecondaryMuscleReps);
    }
  }
  return cd;
}

+ (RChartStrengthRawData *)doRepsLineChartStrengthRawDataForUser:(PELMUser *)user
                                              userSettings:(RUserSettings *)userSettings
                                              bodySegments:(NSArray *)bodySegments
                                          bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                              muscleGroups:(NSArray *)muscleGroups
                                          muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                   muscles:(NSArray *)muscles
                                               musclesDict:(NSDictionary *)musclesDict
                                                 movements:(NSArray *)movements
                                             movementsDict:(NSDictionary *)movementsDict
                                          movementVariants:(NSArray *)movementVariants
                                      movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                      sets:(NSArray *)sets
                                                 calcPercentages:(BOOL)calcPercentages
                                                    calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData repsLineChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initSingleEntityTimeSeriesDict)(NSMutableDictionary *, NSString *) = [RUtils makeSingleEntityTimeSeriesBlk];
  void (^initBsTimeSeriesDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsTimeSeriesBlk];
  initSingleEntityTimeSeriesDict(cd.repsTimeSeries, @"Total Reps");
  for (RBodySegment *bodySegment in bodySegments) {
    initBsTimeSeriesDict(cd.repsByBodySegmentTimeSeries, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgTimeSeriesDict(cd.repsByMuscleGroupTimeSeries, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.repsByUpperBodySegmentTimeSeries, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.repsByLowerBodySegmentTimeSeries, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleTimeSeriesDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMuscleTimeSeriesBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByShoulderMgTimeSeries, muscle);
        break;
      case BACK_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByBackMgTimeSeries, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByTricepsMgTimeSeries, muscle);
        break;
      case BICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByBicepsMgTimeSeries, muscle);
        break;
      case FOREARMS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByForearmsMgTimeSeries, muscle);
        break;
      case CORE_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByAbsMgTimeSeries, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByChestMgTimeSeries, muscle);
        break;
      case HAMSTRINGS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByHamstringsMgTimeSeries, muscle);
        break;
      case QUADRICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByQuadsMgTimeSeries, muscle);
        break;
      case CALVES_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByCalfsMgTimeSeries, muscle);
        break;
      case GLUTES_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByGlutesMgTimeSeries, muscle);
        break;
      case HIP_ABDUCTORS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByHipAbductorsMgTimeSeries, muscle);
        break;
      case HIP_FLEXORS_MG_ID:
        initMuscleTimeSeriesDict(cd.repsByHipFlexorsMgTimeSeries, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvTimeSeriesDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvTimeSeriesBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize reps timeline data
    initMvTimeSeriesDict(cd.repsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.upperBodyRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.lowerBodyRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.shoulderRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.backRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.tricepsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.bicepsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.forearmsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.absRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.chestRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hamstringsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.quadsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.calfsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.glutesRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipAbductorsRepsByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipFlexorsRepsByMovementVariantTimeSeries, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    NSInteger numRepsInt = set.numReps.integerValue;
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *numReps = [[NSDecimalNumber alloc] initWithInteger:numRepsInt];
    NSDecimalNumber *primaryMusclesTotalReps = [numReps decimalNumberByMultiplyingBy:primaryMusclePercentage];
    NSDecimalNumber *secondaryMusclesTotalReps = [numReps decimalNumberBySubtracting:primaryMusclesTotalReps];
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    addTo(cd.repsTimeSeries, @(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER), numReps, loggedAt);
    addTo(cd.repsByMovementVariantTimeSeries, variant.localMasterIdentifier, numReps, loggedAt);
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleReps = [primaryMusclesTotalReps decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleReps = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      perSecondaryMuscleReps = [secondaryMusclesTotalReps decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyReps)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *repsToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.repsByTricepsMgTimeSeries,        muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByBicepsMgTimeSeries,         muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByForearmsMgTimeSeries,       muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByAbsMgTimeSeries,            muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByHamstringsMgTimeSeries,     muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByQuadsMgTimeSeries,          muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByCalfsMgTimeSeries,          muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByGlutesMgTimeSeries,         muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByHipAbductorsMgTimeSeries,   muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByHipFlexorsMgTimeSeries,     muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByBackMgTimeSeries,           muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByChestMgTimeSeries,          muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByShoulderMgTimeSeries,       muscle.localMasterIdentifier,      repsToAdd, loggedAt);
      addTo(cd.repsByMuscleGroupTimeSeries,      muscleGroup.localMasterIdentifier, repsToAdd, loggedAt);
      addTo(cd.repsByBodySegmentTimeSeries,      bodySegment.localMasterIdentifier, repsToAdd, loggedAt);
      addTo(cd.repsByUpperBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, repsToAdd, loggedAt);
      addTo(cd.repsByLowerBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, repsToAdd, loggedAt);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.upperBodyRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.lowerBodyRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.shoulderRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case BACK_MG_ID:
          addTo(cd.backRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case TRICEP_MG_ID:
          addTo(cd.tricepsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case BICEPS_MG_ID:
          addTo(cd.bicepsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.forearmsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case CORE_MG_ID:
          addTo(cd.absRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case CHEST_MG_ID:
          addTo(cd.chestRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.hamstringsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.quadsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case CALVES_MG_ID:
          addTo(cd.calfsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case GLUTES_MG_ID:
          addTo(cd.glutesRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.hipAbductorsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.hipFlexorsRepsByMovementVariantTimeSeries, variant.localMasterIdentifier, repsToAdd, loggedAt);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyReps(primaryMuscleId, perPrimaryMuscleReps);
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      tallyReps(secondaryMuscleId, perSecondaryMuscleReps);
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'reps' entity-dict containers
    plugHolesAndCalcPercentages(cd.repsTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByMuscleGroupTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByUpperBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByLowerBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByShoulderMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByBackMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByAbsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByHamstringsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByQuadsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByCalfsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByGlutesMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByHipAbductorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByHipFlexorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByChestMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByTricepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByBicepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.repsByForearmsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.upperBodyRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.lowerBodyRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.shoulderRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.backRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.tricepsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.bicepsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.forearmsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.absRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.chestRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hamstringsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.quadsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.calfsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.glutesRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipAbductorsRepsByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipFlexorsRepsByMovementVariantTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartStrengthRawData *)doTotalWeightLiftedDistChartStrengthRawDataForUser:(PELMUser *)user
                                                                 userSettings:(RUserSettings *)userSettings
                                                                 bodySegments:(NSArray *)bodySegments
                                                             bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                                                 muscleGroups:(NSArray *)muscleGroups
                                                             muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                      muscles:(NSArray *)muscles
                                                                  musclesDict:(NSDictionary *)musclesDict
                                                                    movements:(NSArray *)movements
                                                                movementsDict:(NSDictionary *)movementsDict
                                                             movementVariants:(NSArray *)movementVariants
                                                         movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                                         sets:(NSArray *)sets {
  RChartStrengthRawData *cd = [RChartStrengthRawData totalWeightLiftedDistChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initBsDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsPieSliceBlk];
  for (RBodySegment *bodySegment in bodySegments) {
    initBsDict(cd.weightLiftedByBodySegment, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgPieSliceBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgDict(cd.weightLiftedByMuscleGroup, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgDict(cd.weightLiftedByUpperBodySegment, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgDict(cd.weightLiftedByLowerBodySegment, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMusclePieSliceBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleDict(cd.weightLiftedByShoulderMg, muscle);
        break;
      case BACK_MG_ID:
        initMuscleDict(cd.weightLiftedByBackMg, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleDict(cd.weightLiftedByTricepsMg, muscle);
        break;
      case CORE_MG_ID:
        initMuscleDict(cd.weightLiftedByAbsMg, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleDict(cd.weightLiftedByChestMg, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvPieSliceBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize weight pie chart data
    initMvDict(cd.weightLiftedByMovementVariant, variant);
    initMvDict(cd.upperBodyWeightLiftedByMovementVariant, variant);
    initMvDict(cd.lowerBodyWeightLiftedByMovementVariant, variant);
    initMvDict(cd.hamstringsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.quadsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.calfsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.glutesWeightLiftedByMovementVariant, variant);
    initMvDict(cd.hipAbductorsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.hipFlexorsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.shoulderWeightLiftedByMovementVariant, variant);
    initMvDict(cd.backWeightLiftedByMovementVariant, variant);
    initMvDict(cd.tricepsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.forearmsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.bicepsWeightLiftedByMovementVariant, variant);
    initMvDict(cd.absWeightLiftedByMovementVariant, variant);
    initMvDict(cd.chestWeightLiftedByMovementVariant, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDecimalNumber *weight = [RUtils weightValueWithValue:set.weight currentWeightUomId:set.weightUom targetWeightUomId:userSettings.weightUom];
    NSInteger numRepsInt = set.numReps.integerValue;
    NSDecimalNumber *totalWeight = [weight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:numRepsInt]];
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *primaryMusclesTotalWeight;
    if (secondaryMuscleIdsCount > 0) {
      primaryMusclesTotalWeight = [totalWeight decimalNumberByMultiplyingBy:primaryMusclePercentage];
    } else {
      primaryMusclesTotalWeight = totalWeight;
    }
    NSDecimalNumber *secondaryMusclesTotalWeight = [totalWeight decimalNumberBySubtracting:primaryMusclesTotalWeight];
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    addTo(cd.weightLiftedByMovementVariant, variant.localMasterIdentifier, totalWeight, nil);
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleWeight = [primaryMusclesTotalWeight decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleWeight = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      perSecondaryMuscleWeight = [secondaryMusclesTotalWeight decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyWeight)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *weightToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.weightLiftedByChestMg,          muscle.localMasterIdentifier,      weightToAdd, nil);
      addTo(cd.weightLiftedByTricepsMg,        muscle.localMasterIdentifier,      weightToAdd, nil);
      addTo(cd.weightLiftedByAbsMg,            muscle.localMasterIdentifier,      weightToAdd, nil);
      addTo(cd.weightLiftedByBackMg,           muscle.localMasterIdentifier,      weightToAdd, nil);
      addTo(cd.weightLiftedByShoulderMg,       muscle.localMasterIdentifier,      weightToAdd, nil);
      addTo(cd.weightLiftedByMuscleGroup,      muscleGroup.localMasterIdentifier, weightToAdd, nil);
      addTo(cd.weightLiftedByBodySegment,      bodySegment.localMasterIdentifier, weightToAdd, nil);
      addTo(cd.weightLiftedByUpperBodySegment, muscleGroup.localMasterIdentifier, weightToAdd, nil);
      addTo(cd.weightLiftedByLowerBodySegment, muscleGroup.localMasterIdentifier, weightToAdd, nil);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.upperBodyWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.lowerBodyWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.shoulderWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case BACK_MG_ID:
          addTo(cd.backWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case TRICEP_MG_ID:
          addTo(cd.tricepsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case BICEPS_MG_ID:
          addTo(cd.bicepsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.forearmsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case CORE_MG_ID:
          addTo(cd.absWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case CHEST_MG_ID:
          addTo(cd.chestWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.hamstringsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.quadsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case CALVES_MG_ID:
          addTo(cd.calfsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case GLUTES_MG_ID:
          addTo(cd.glutesWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.hipAbductorsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.hipFlexorsWeightLiftedByMovementVariant, variant.localMasterIdentifier, weightToAdd, nil);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyWeight(primaryMuscleId, perPrimaryMuscleWeight);
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      tallyWeight(secondaryMuscleId, perSecondaryMuscleWeight);
    }
  }
  return cd;
}

+ (RChartStrengthRawData *)doWeightLiftedLineChartStrengthRawDataForUser:(PELMUser *)user
                                                            userSettings:(RUserSettings *)userSettings
                                                            bodySegments:(NSArray *)bodySegments
                                                        bodySegmentsDict:(NSDictionary *)bodySegmentsDict
                                                            muscleGroups:(NSArray *)muscleGroups
                                                        muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                                                                 muscles:(NSArray *)muscles
                                                             musclesDict:(NSDictionary *)musclesDict
                                                               movements:(NSArray *)movements
                                                           movementsDict:(NSDictionary *)movementsDict
                                                        movementVariants:(NSArray *)movementVariants
                                                    movementVariantsDict:(NSDictionary *)movementVariantsDict
                                                                    sets:(NSArray *)sets
                                                         calcPercentages:(BOOL)calcPercentages
                                                            calcAverages:(BOOL)calcAverages {
  RChartStrengthRawData *cd = [RChartStrengthRawData weightLiftedLineChartRawData];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  cd.startDate = firstSet.loggedAt;
  cd.endDate = lastSet.loggedAt;
  void (^initSingleEntityTimeSeriesDict)(NSMutableDictionary *, NSString *) = [RUtils makeSingleEntityTimeSeriesBlk];
  void (^initBsTimeSeriesDict)(NSMutableDictionary *, RBodySegment *) = [RUtils makeInitBsTimeSeriesBlk];
  initSingleEntityTimeSeriesDict(cd.weightTimeSeries, @"Total Weight");
  for (RBodySegment *bodySegment in bodySegments) {
    initBsTimeSeriesDict(cd.weightByBodySegmentTimeSeries, bodySegment);
  }
  NSString *(^abbrevMg)(RMuscleGroup *) = [self makeAbbrevMgBlk];
  void (^initMgTimeSeriesDict)(NSMutableDictionary *, RMuscleGroup *) = [self makeInitMgTimeSeriesDictBlkWithAbbrevMgBlk:abbrevMg];
  for (RMuscleGroup *muscleGroup in muscleGroups) {
    initMgTimeSeriesDict(cd.weightByMuscleGroupTimeSeries, muscleGroup);
    NSInteger bodySegmentId = muscleGroup.bodySegmentId.integerValue;
    switch (bodySegmentId) {
      case UPPER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.weightByUpperBodySegmentTimeSeries, muscleGroup);
        break;
      case LOWER_BODY_SEGMENT_ID:
        initMgTimeSeriesDict(cd.weightByLowerBodySegmentTimeSeries, muscleGroup);
        break;
    }
  }
  NSString *(^abbrevMuscle)(RMuscle *) = [RUtils makeAbbrevMuscleBlk];
  void (^initMuscleTimeSeriesDict)(NSMutableDictionary *, RMuscle *) = [RUtils makeInitMuscleTimeSeriesBlkWithAbbrevMuscleBlk:abbrevMuscle];
  for (RMuscle *muscle in muscles) {
    NSInteger mgId = muscle.muscleGroupId.integerValue;
    switch (mgId) {
      case SHOULDER_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByShoulderMgTimeSeries, muscle);
        break;
      case BACK_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByBackMgTimeSeries, muscle);
        break;
      case TRICEP_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByTricepsMgTimeSeries, muscle);
        break;
      case BICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByBicepsMgTimeSeries, muscle);
        break;
      case FOREARMS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByForearmsMgTimeSeries, muscle);
        break;
      case CORE_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByAbsMgTimeSeries, muscle);
        break;
      case CHEST_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByChestMgTimeSeries, muscle);
        break;
      case HAMSTRINGS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByHamstringsMgTimeSeries, muscle);
        break;
      case QUADRICEPS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByQuadsMgTimeSeries, muscle);
        break;
      case CALVES_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByCalfsMgTimeSeries, muscle);
        break;
      case GLUTES_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByGlutesMgTimeSeries, muscle);
        break;
      case HIP_ABDUCTORS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByHipAbductorsMgTimeSeries, muscle);
        break;
      case HIP_FLEXORS_MG_ID:
        initMuscleTimeSeriesDict(cd.weightByHipFlexorsMgTimeSeries, muscle);
        break;
    }
  }
  NSString *(^abbrevMv)(RMovementVariant *) = [RUtils makeAbbrevMvBlk];
  void (^initMvTimeSeriesDict)(NSMutableDictionary *, RMovementVariant *) = [RUtils makeInitMvTimeSeriesBlkWithAbbrevMvBlk:abbrevMv];
  for (RMovementVariant *variant in movementVariants) {
    // initialize weight timeline data
    initMvTimeSeriesDict(cd.weightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.upperBodyWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.lowerBodyWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.shoulderWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.tricepsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.bicepsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.forearmsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.chestWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.backWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.absWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hamstringsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.quadsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.calfsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.glutesWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipAbductorsWeightByMovementVariantTimeSeries, variant);
    initMvTimeSeriesDict(cd.hipFlexorsWeightByMovementVariantTimeSeries, variant);
  }
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSDecimalNumber *primaryMusclePercentage = [[NSDecimalNumber alloc] initWithFloat:PRIMARY_MUSCLE_PERCENTAGE];
  NSInteger numSets = sets.count;
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    NSDecimalNumber *weight = [RUtils weightValueWithValue:set.weight currentWeightUomId:set.weightUom targetWeightUomId:userSettings.weightUom];
    NSInteger numRepsInt = set.numReps.integerValue;
    NSDecimalNumber *totalWeight = [weight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:numRepsInt]];
    RMovement *movement = movementsDict[set.movementId];
    NSArray *primaryMuscleIds = movement.primaryMuscleIds;
    NSArray *secondaryMuscleIds = movement.secondaryMuscleIds;
    NSInteger secondaryMuscleIdsCount = 0;
    if (secondaryMuscleIds) {
      secondaryMuscleIdsCount = secondaryMuscleIds.count;
    }
    NSDecimalNumber *primaryMusclesTotalWeight;
    if (secondaryMuscleIdsCount > 0) {
      primaryMusclesTotalWeight = [totalWeight decimalNumberByMultiplyingBy:primaryMusclePercentage];
    } else {
      primaryMusclesTotalWeight = totalWeight;
    }
    NSDecimalNumber *secondaryMusclesTotalWeight = [totalWeight decimalNumberBySubtracting:primaryMusclesTotalWeight];
    RMovementVariant *variant = movementVariantsDict[set.movementVariantId];
    if ([PEUtils isNil:variant] && movement.isBodyLift) {
      variant = movementVariantsDict[@(BODY_MOVEMENT_VARIANT_ID)];
    }
    addTo(cd.weightTimeSeries, @(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER), totalWeight, loggedAt);
    addTo(cd.weightByMovementVariantTimeSeries, variant.localMasterIdentifier, totalWeight, loggedAt);
    NSDecimalNumber *primaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:primaryMuscleIds.count];
    NSDecimalNumber *perPrimaryMuscleWeight = [primaryMusclesTotalWeight decimalNumberByDividingBy:primaryMusclesCount];
    NSDecimalNumber *perSecondaryMuscleWeight = nil;
    if (secondaryMuscleIds.count > 0) {
      NSDecimalNumber *secondaryMusclesCount = [[NSDecimalNumber alloc] initWithInteger:secondaryMuscleIds.count];
      perSecondaryMuscleWeight = [secondaryMusclesTotalWeight decimalNumberByDividingBy:secondaryMusclesCount];
    }
    void (^tallyWeight)(NSNumber *, NSDecimalNumber *) = ^(NSNumber *muscleId, NSDecimalNumber *weightToAdd) {
      RMuscle *muscle = musclesDict[muscleId];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
      RBodySegment *bodySegment = bodySegmentsDict[muscleGroup.bodySegmentId];
      addTo(cd.weightByTricepsMgTimeSeries,        muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByBicepsMgTimeSeries,         muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByForearmsMgTimeSeries,       muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByHamstringsMgTimeSeries,     muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByQuadsMgTimeSeries,          muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByCalfsMgTimeSeries,          muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByGlutesMgTimeSeries,         muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByHipAbductorsMgTimeSeries,   muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByHipFlexorsMgTimeSeries,     muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByAbsMgTimeSeries,            muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByBackMgTimeSeries,           muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByChestMgTimeSeries,          muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByShoulderMgTimeSeries,       muscle.localMasterIdentifier,      weightToAdd, loggedAt);
      addTo(cd.weightByMuscleGroupTimeSeries,      muscleGroup.localMasterIdentifier, weightToAdd, loggedAt);
      addTo(cd.weightByBodySegmentTimeSeries,      bodySegment.localMasterIdentifier, weightToAdd, loggedAt);
      addTo(cd.weightByUpperBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, weightToAdd, loggedAt);
      addTo(cd.weightByLowerBodySegmentTimeSeries, muscleGroup.localMasterIdentifier, weightToAdd, loggedAt);
      NSInteger bodySegmentId = bodySegment.localMasterIdentifier.integerValue;
      switch (bodySegmentId) {
        case UPPER_BODY_SEGMENT_ID:
          addTo(cd.upperBodyWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case LOWER_BODY_SEGMENT_ID:
          addTo(cd.lowerBodyWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
      }
      NSInteger mgId = muscleGroup.localMasterIdentifier.integerValue;
      switch (mgId) {
        case SHOULDER_MG_ID:
          addTo(cd.shoulderWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case BACK_MG_ID:
          addTo(cd.backWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case TRICEP_MG_ID:
          addTo(cd.tricepsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case BICEPS_MG_ID:
          addTo(cd.bicepsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case FOREARMS_MG_ID:
          addTo(cd.forearmsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case CORE_MG_ID:
          addTo(cd.absWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case CHEST_MG_ID:
          addTo(cd.chestWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case HAMSTRINGS_MG_ID:
          addTo(cd.hamstringsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case QUADRICEPS_MG_ID:
          addTo(cd.quadsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case CALVES_MG_ID:
          addTo(cd.calfsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case GLUTES_MG_ID:
          addTo(cd.glutesWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case HIP_ABDUCTORS_MG_ID:
          addTo(cd.hipAbductorsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
        case HIP_FLEXORS_MG_ID:
          addTo(cd.hipFlexorsWeightByMovementVariantTimeSeries, variant.localMasterIdentifier, weightToAdd, loggedAt);
          break;
      }
    };
    for (NSNumber *primaryMuscleId in primaryMuscleIds) {
      tallyWeight(primaryMuscleId, perPrimaryMuscleWeight);
    }
    for (NSNumber *secondaryMuscleId in secondaryMuscleIds) {
      tallyWeight(secondaryMuscleId, perSecondaryMuscleWeight);
    }
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) =
  [RUtils makeHolePluggerCalcPercentages:calcPercentages calcAverages:calcAverages];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numSets; i++) {
    RSet *set = sets[i];
    NSDate *loggedAt = set.loggedAt;
    // plug holes in 'weight' entity-dict containers
    plugHolesAndCalcPercentages(cd.weightTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByMuscleGroupTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByUpperBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByLowerBodySegmentTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByShoulderMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByBackMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByAbsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByChestMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByTricepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByBicepsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByForearmsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByHamstringsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByQuadsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByCalfsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByGlutesMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByHipAbductorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.weightByHipFlexorsMgTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.upperBodyWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.lowerBodyWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.shoulderWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.backWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.tricepsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.bicepsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.forearmsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.absWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.chestWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hamstringsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.quadsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.calfsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.glutesWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipAbductorsWeightByMovementVariantTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.hipFlexorsWeightByMovementVariantTimeSeries, loggedAt);
  }
  return cd;
}

+ (RChartBodyRawData *)chartBodyDataForUser:(PELMUser *)user
                               userSettings:(RUserSettings *)userSettings
                                       bmls:(NSArray *)bmls {
  RChartBodyRawData *cd = [RChartBodyRawData chartRawData];
  RBodyMeasurementLog *firstBml = [bmls firstObject];
  RBodyMeasurementLog *lastBml = [bmls lastObject];
  cd.startDate = firstBml.loggedAt;
  cd.endDate = lastBml.loggedAt;
  NSNumber *lmidKeyForSingleValContainer = @(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER);
  void (^initSingleEntityTimeSeriesDict)(NSMutableDictionary *, NSString *) = [RUtils makeSingleEntityTimeSeriesBlk];
  initSingleEntityTimeSeriesDict(cd.bodyWeightTimeSeries, @"Body Weight");
  initSingleEntityTimeSeriesDict(cd.armSizeTimeSeries, @"Arm Size");
  initSingleEntityTimeSeriesDict(cd.chestSizeTimeSeries, @"Chest Size");
  initSingleEntityTimeSeriesDict(cd.calfSizeTimeSeries, @"Calf Size");
  initSingleEntityTimeSeriesDict(cd.thighSizeTimeSeries, @"Thigh Size");
  initSingleEntityTimeSeriesDict(cd.forearmSizeTimeSeries, @"Forearm Size");
  initSingleEntityTimeSeriesDict(cd.waistSizeTimeSeries, @"Waist Size");
  initSingleEntityTimeSeriesDict(cd.neckSizeTimeSeries, @"Neck Size");
  void(^addTo)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *) = [RUtils makeAddToBlk];
  NSInteger numBmls = bmls.count;
  for (NSInteger i = 0; i < numBmls; i++) {
    RBodyMeasurementLog *bml = bmls[i];
    NSDate *loggedAt = bml.loggedAt;
    void (^addToSize)(NSMutableDictionary *, NSDecimalNumber *) = ^(NSMutableDictionary *timeSeries, NSDecimalNumber *valueToAdd) {
      addTo(timeSeries,
            lmidKeyForSingleValContainer,
            [RUtils sizeValueWithValue:valueToAdd currentSizeUomId:bml.sizeUom targetSizeUomId:userSettings.sizeUom],
            loggedAt);
    };
    addTo(cd.bodyWeightTimeSeries,
          lmidKeyForSingleValContainer,
          [RUtils weightValueWithValue:bml.bodyWeight
                    currentWeightUomId:bml.bodyWeightUom
                     targetWeightUomId:userSettings.weightUom],
          loggedAt);
    addToSize(cd.armSizeTimeSeries, bml.armSize);
    addToSize(cd.chestSizeTimeSeries, bml.chestSize);
    addToSize(cd.calfSizeTimeSeries, bml.calfSize);
    addToSize(cd.thighSizeTimeSeries, bml.thighSize);
    addToSize(cd.forearmSizeTimeSeries, bml.forearmSize);
    addToSize(cd.waistSizeTimeSeries, bml.waistSize);
    addToSize(cd.neckSizeTimeSeries, bml.neckSize);
  }
  //////////////////////////////////////////////////////////////////////////////
  // Hole plugger for time series data
  //////////////////////////////////////////////////////////////////////////////
  void (^plugHolesAndCalcPercentages)(NSMutableDictionary *, NSDate *) = [RUtils makeHolePluggerCalcPercentages:NO calcAverages:YES];
  // 2nd pass through sets to fill holes in time series dictionaries
  for (NSInteger i = 0; i < numBmls; i++) {
    RBodyMeasurementLog *bml = bmls[i];
    NSDate *loggedAt = bml.loggedAt;
    // plug holes in entity-dict containers
    plugHolesAndCalcPercentages(cd.bodyWeightTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.armSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.chestSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.calfSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.thighSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.forearmSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.waistSizeTimeSeries, loggedAt);
    plugHolesAndCalcPercentages(cd.neckSizeTimeSeries, loggedAt);
  }
  return cd;
}

+ (RNormalizedTimeSeriesTupleCollection *)normalizeUsingGroupIntervalInDays:(NSInteger)groupSizeInDays
                                                                  firstDate:(NSDate *)firstDate
                                                                   lastDate:(NSDate *)lastDate
                                                           withRawContainer:(NSDictionary *)rawContainer
                                                          calculateAverages:(BOOL)calculateAverages
                                                     calculateDistributions:(BOOL)calculateDistributions
                                                                    logging:(BOOL)logging {
  if (!firstDate) {
    return nil;
  }
  RNormalizedTimeSeriesTupleCollection *dataEntries = [RNormalizedTimeSeriesTupleCollection dataEntries];
  NSArray *localMasterIdentifiers = [rawContainer allKeys];
  NSMutableArray *rawDataPointsByDateDicts = [NSMutableArray array];
  NSMutableArray *lmidNormalizedTimeSeriesPairs = [NSMutableArray array];
  // collect the time series dicts and initialize the new averaged-by-day container
  for (NSNumber *localMasterIdentifier in localMasterIdentifiers) {
    RRawLineDataPointsByDateTuple *rawLineDataPointsByDateTuple = rawContainer[localMasterIdentifier];
    NSMutableDictionary *rawDataPointsByDate = rawLineDataPointsByDateTuple.dataPointsByDate;
    [rawDataPointsByDateDicts addObject:rawDataPointsByDate];
    NSMutableArray *normalizedTimeSeries = [NSMutableArray array];
    RNormalizedTimeSeriesTuple *normalizedTimeSeriesTuple = [[RNormalizedTimeSeriesTuple alloc] init];
    normalizedTimeSeriesTuple.normalizedTimeSeries = normalizedTimeSeries;
    normalizedTimeSeriesTuple.name = rawLineDataPointsByDateTuple.name;
    normalizedTimeSeriesTuple.localMasterIdentifier = rawLineDataPointsByDateTuple.localMasterIdentifier;
    [dataEntries setNormalizedTimeSeriesTuple:normalizedTimeSeriesTuple
                     forLocalMasterIdentifier:localMasterIdentifier];
    [lmidNormalizedTimeSeriesPairs addObject:@[localMasterIdentifier, normalizedTimeSeries]];
  }
  NSInteger numRawDataPointsByDateDicts = rawDataPointsByDateDicts.count;
  if (numRawDataPointsByDateDicts > 0) {
    NSMutableDictionary *rawDataPointsByDate = rawDataPointsByDateDicts[0];
    NSArray *dates = [rawDataPointsByDate allKeys];
    NSDate *firstDateInclusive = [PEUtils dateWithoutTimeFromDate:firstDate];
    NSDate *lastDateInclusive = [[PEUtils dateWithoutTimeFromDate:lastDate] dateByAddingTimeInterval:1];
    NSInteger numDaysBetweenDateEdges = [lastDateInclusive daysFrom:firstDateInclusive];
    NSInteger numIntervals = ceil(numDaysBetweenDateEdges / groupSizeInDays) + 1;

    NSMutableDictionary *groupIndexTotals = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < numRawDataPointsByDateDicts; i++) {
      rawDataPointsByDate = rawDataPointsByDateDicts[i];
      NSArray *lmidNormalizedTimeSeriesPair = lmidNormalizedTimeSeriesPairs[i];
      NSMutableArray *normalizedTimeSeries = lmidNormalizedTimeSeriesPair[1];
      for (NSInteger j = 0; j < numIntervals; j++) {
        NSInteger daysForNextGroup = j * groupSizeInDays;
        NSDate *group = [firstDateInclusive dateByAddingDays:daysForNextGroup];
        RNormalizedLineChartDataEntry *dataEntry = [RNormalizedLineChartDataEntry dataEntry];
        dataEntry.date = group;
        [normalizedTimeSeries addObject:dataEntry];
      }
      for (NSDate *date in dates) {
        NSInteger daysSinceFirstDate = [date daysFrom:firstDateInclusive];
        NSInteger groupIndex = floor(daysSinceFirstDate / groupSizeInDays);
        NSNumber *groupIndexNumber = @(groupIndex);

        RRawLineDataPointTuple *rawDataPointTuple = rawDataPointsByDate[date];
        NSDecimalNumber *aggregateSum = rawDataPointTuple.sum;
        RNormalizedLineChartDataEntry *dataEntry = normalizedTimeSeries[groupIndex];
        dataEntry.groupIndex = groupIndexNumber;
        if (![aggregateSum isEqualToNumber:[NSDecimalNumber zero]]) {
          [dataEntry addToAggregateSummedValue:aggregateSum];
          [dataEntry incrementCount];
          NSDecimalNumber *groupIndexTotal = groupIndexTotals[groupIndexNumber];
          if (!groupIndexTotal) {
            groupIndexTotal = [NSDecimalNumber zero];
          }
          groupIndexTotal = [groupIndexTotal decimalNumberByAdding:aggregateSum];
          groupIndexTotals[groupIndexNumber] = groupIndexTotal;
          if ([dataEntry.aggregateSummedValue compare:dataEntries.maxAggregateSummedValue] == NSOrderedDescending) {
            dataEntries.maxAggregateSummedValue = dataEntry.aggregateSummedValue;
          }
        }
      }
    }
    // 2nd pass to calculate averages / percentages
    if (calculateAverages || calculateDistributions) {
      for (NSInteger i = 0; i < numRawDataPointsByDateDicts; i++) {
        NSArray *localMasterIdentifierTimeSeriesPair = lmidNormalizedTimeSeriesPairs[i];
        NSMutableArray *avgByGroupTimeSeries = localMasterIdentifierTimeSeriesPair[1];
        for (RNormalizedLineChartDataEntry *dataEntry in avgByGroupTimeSeries) {
          if (dataEntry.count > 0) {
            if (calculateAverages) {
              [dataEntry calculateAvgAggregateValue];
              NSDecimalNumber *avgAggregateVal = dataEntry.avgAggregateValue;
              if ([avgAggregateVal compare:dataEntries.maxAvgAggregateValue] == NSOrderedDescending) {
                dataEntries.maxAvgAggregateValue = avgAggregateVal;
              }
            }
            if (calculateDistributions) {
              [dataEntry calculateDistributionWithGroupIndexTotals:groupIndexTotals];
              NSDecimalNumber *distributionValue = dataEntry.distribution;
              if ([distributionValue compare:dataEntries.maxDistributionValue] == NSOrderedDescending) {
                dataEntries.maxDistributionValue = distributionValue;
              }
            }
          }
        }
      }
    }
  }
  return dataEntries;
}

#pragma mark - Analytics Helpers

+ (void)logScreen:(NSString *)screenTitle fromController:(UIViewController *)controller {
  DDLogDebug(@"inside RUtils/logScreen, screenTitle: [%@], controller class: [%@]", screenTitle, NSStringFromClass(controller.class));
  [FIRAnalytics setScreenName:[[screenTitle lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]
                  screenClass:nil];
}

+ (void)logEvent:(NSString *)event {
  [RUtils logEvent:event params:nil];
}

+ (void)logEvent:(NSString *)event params:(NSDictionary *)params {
  [FIRAnalytics logEventWithName:event parameters:params];
  [FBSDKAppEvents logEvent:event parameters:params];
}

+ (void)logNewSetEventWithSet:(RSet *)newSet {
  [RUtils logEvent:kFIREventPostScore params:@{kFIRParameterScore : [RUtils weightValueWithValue:[newSet.weight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:newSet.numReps.integerValue]]
                                                                              currentWeightUomId:newSet.weightUom
                                                                               targetWeightUomId:@(LBS_ID)]}];
}

+ (void)logExpandingInfoContentViewed:(NSString *)contentName {
  [RUtils logEvent:kFIREventViewItem
            params:@{kFIRParameterItemName: [contentName stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                     kFIRParameterContentType: @"expanding_info_section"}];
}

+ (void)logHelpInfoPopupContentViewed:(NSString *)contentName {
  [RUtils logEvent:kFIREventViewItem
            params:@{kFIRParameterItemName: [contentName stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                     kFIRParameterContentType: @"help_info_popup"}];
}

+ (NSMutableDictionary *)eventLogParamsWithParamName:(NSString *)paramName value:(NSInteger)value {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
  params[paramName] = @(value);
  return params;
}

+ (NSMutableDictionary *)eventLogParamsWithNumRecords:(NSInteger)numRecords {
  return [RUtils eventLogParamsWithParamName:@"num_records" value:numRecords];
}

+ (NSMutableDictionary *)eventLogParamsWithErrMask:(NSInteger)errMask {
  return [RUtils eventLogParamsWithParamName:@"err_mask" value:errMask];
}

+ (NSMutableDictionary *)eventLogParamsWithSyncAttemptErrors:(NSInteger)syncAttemptErrors {
  return [RUtils eventLogParamsWithParamName:@"sync_attempt_errors" value:syncAttemptErrors];
}

#pragma mark - General Helpers

+ (void)appendiTunesSubscriptionInfoToAttrString:(NSMutableAttributedString *)subscriptionInfo
                                  prependNewline:(BOOL)prependNewline
                             subscriptionProduct:(SKProduct *)subscriptionProduct
                               spacingAttributes:(NSDictionary *)spacingAttrs {
  if (prependNewline) {
    [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 The length of a Riker subscription is 1 year.", spacingAttrs)];
  } else {
    [subscriptionInfo appendAttributedString:AS(@"\u00b7 The length of a Riker subscription is 1 year.")];
  }
  [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 A Riker subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.", spacingAttrs)];
  [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 Your iTunes account will be charged for renewal within 24-hours prior to the end of the current period.", spacingAttrs)];
  if (subscriptionProduct) { // would be nil if iTunes couldn't be contacted (e.g., if no internet connection)
    [subscriptionInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\u00b7 The renewal price is %@."
                                                                 templateTextColor:nil
                                                                  templateTextFont:nil
                                                                      textToAccent:[RUtils formattedPriceOfProduct:subscriptionProduct]
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                   accentTextColor:nil
                                                      additionalTemplateAttributes:spacingAttrs]];
  }
  [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 A Riker subscription may be managed and auto-renewal may be turned off by going to your iTunes Account Settings after purchase.", spacingAttrs)];
  [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 A Riker subscription can be managed through your iTunes account.", spacingAttrs)];
  [subscriptionInfo appendAttributedString:ASA(@"\n\u00b7 Payment will be charged to your iTunes Account at confirmation of purchase.", spacingAttrs)];
  [subscriptionInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nRiker's Terms of Service:\n%@"
                                                               templateTextColor:nil
                                                                templateTextFont:nil
                                                                    textToAccent:[APP rikerTermsOfServiceUrl]
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                 accentTextColor:nil
                                                    additionalTemplateAttributes:spacingAttrs]];
  [subscriptionInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nRiker's Privacy Policy:\n%@"
                                                               templateTextColor:nil
                                                                templateTextFont:nil
                                                                    textToAccent:[APP rikerPrivacyPolicyUrl]
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                                 accentTextColor:nil
                                                    additionalTemplateAttributes:spacingAttrs]];
}

+ (NSString *)formattedPriceOfProduct:(SKProduct *)product {
  // https://developer.apple.com/documentation/storekit/skproduct/1506094-price?language=objc
  // see 'Discussion' of developer page...provides the following code for
  // formatting the product price properly
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
  [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [numberFormatter setLocale:product.priceLocale];
  return [numberFormatter stringFromNumber:product.price];
}

+ (AsMaker)asMakerWithFontTextStyle:(UIFontTextStyle)fontTextStyle {
  return ^NSAttributedString *(NSString *template, NSString *highlight) {
    return [PEUIUtils attributedTextWithTemplate:template
                                    textToAccent:highlight
                                  accentTextFont:[PEUIUtils boldFontForTextStyle:fontTextStyle]];
  };
}

+ (void)contactRikerSupport {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [APP rikerSupportEmail]]]
                                     options:@{}
                           completionHandler:nil];
}

+ (NSString *)truncatedText:(NSString *)text maxLength:(NSInteger)maxLength {
  if ([text length] > maxLength) {
    return [[text substringToIndex:maxLength] stringByAppendingString:@"..."];
  }
  return text;
}

+ (NSString *)weightUnitNameForUomId:(NSNumber *)uomId {
  if (uomId.integerValue == LBS_ID) {
    return LBS_NAME;
  }
  return KG_NAME;
}

+ (NSString *)sizeUnitNameForUomId:(NSNumber *)uomId {
  if (uomId.integerValue == INCHES_ID) {
    return INCHES_NAME;
  }
  return CM_NAME;
}

+ (NSString *)genderNameForGenderVal:(NSNumber *)genderVal {
  if ([PEUtils isNotNil:genderVal]) {
    if (genderVal.integerValue == GENDER_MALE_VAL) {
      return GENDER_MALE;
    }
    return GENDER_FEMALE;
  }
  return nil;
}

+ (NSDecimalNumber *)weightValueWithValue:(NSDecimalNumber *)value
                       currentWeightUomId:(NSNumber *)currentWeightUomId
                        targetWeightUomId:(NSNumber *)targetWeightUomId {
  if (![PEUtils isNil:value]) {
    if ([currentWeightUomId isEqualToNumber:targetWeightUomId]) {
      return value;
    } else {
      if (currentWeightUomId.integerValue == LBS_ID) {
        return [value decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithFloat:0.453592]]; //[NSNumber numberWithInteger:lroundf(value.floatValue * 0.453592)];
      } else {
        return [value decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithFloat:2.20462]]; //[NSNumber numberWithInteger:lroundf(value.floatValue * 2.20462)];
      }
    }
  }
  return nil;
}

+ (NSDecimalNumber *)sizeValueWithValue:(NSDecimalNumber *)value
                       currentSizeUomId:(NSNumber *)currentSizeUomId
                        targetSizeUomId:(NSNumber *)targetSizeUomId {
  if (![PEUtils isNil:value]) {
    if ([currentSizeUomId isEqualToNumber:targetSizeUomId]) {
      return value;
    } else {
      if (currentSizeUomId.integerValue == INCHES_ID) {
        return [value decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithFloat:2.54]];
      } else {
        return [value decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithFloat:0.393701]];
      }
    }
  }
  return nil;
}

+ (NSDictionary *)dictFromMasterEntitiesArray:(NSArray *)masterEntities {
  NSMutableDictionary *entitiesDict =
  [NSMutableDictionary dictionaryWithCapacity:masterEntities.count];
  for (PELMModelSupport *entity in masterEntities) {
    entitiesDict[entity.localMasterIdentifier] = entity;
  }
  return entitiesDict;
}

+ (NSArray *)computeErrMessagesWithErrMask:(NSUInteger)errMask
                               errMessages:(NSArray *)errMessages {
  NSMutableArray *computedErrMsgs = [NSMutableArray array];
  for (NSArray *errMsg in errMessages) {
    NSNumber *errTypeNumber = errMsg[0];
    NSUInteger errType = [errTypeNumber unsignedIntegerValue];
    NSString *localizedErrKey = errMsg[1];
    if (errMask & errType) {
      [computedErrMsgs addObject:LS(localizedErrKey)];
    }
  }
  return computedErrMsgs;
}

+ (NSString *)deviceName {
  struct utsname systemInfo;
  uname(&systemInfo);
  return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL)is32bitIphone {
  // https://stackoverflow.com/a/11197770/1034895
  NSString *deviceName = [RUtils deviceName];
  return [deviceName hasPrefix:@"iPhone3,"] || // iPhone 4 (GSM and CDMA/Verizon/Sprint)
  [deviceName hasPrefix:@"iPhone4,"] || // iPhone 4
  [deviceName isEqualToString:@"iPhone5,1"] || // iPhone 5
  [deviceName isEqualToString:@"iPhone5,2"] || // iPhone 5
  [deviceName isEqualToString:@"iPhone5,3"] || // iPhone 5c
  [deviceName isEqualToString:@"iPhone5,4"] || // iPhone 5c
  [deviceName hasPrefix:@"iPad1,"] || // iPad 1
  [deviceName hasPrefix:@"iPad2,"] || // iPad 2 & iPad Mini
  [deviceName hasPrefix:@"iPad3,"] || // iPad 3 & 4 (the iPad Air is the first 64-bit iPad)
  [deviceName hasPrefix:@"iPod1,"] || // iPod touch
  [deviceName hasPrefix:@"iPod2,"] || // iPod touch 2nd gen
  [deviceName hasPrefix:@"iPod3,"] || // iPod touch 3rd gen
  [deviceName hasPrefix:@"iPod4,"] || // iPod touch 4th gen
  [deviceName hasPrefix:@"iPod5,"];   // iPod touch 5th gen (only the 6th gen is 64-bit)
}

#pragma mark - User Helpers

// https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW3
+ (NSString *)hashedValueForAccountName:(NSString*)userAccountName {
  const int HASH_SIZE = 32;
  unsigned char hashedChars[HASH_SIZE];
  const char *accountName = [userAccountName UTF8String];
  size_t accountNameLen = strlen(accountName);
  CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
  // Convert the array of bytes into a string showing its hex representation.
  NSMutableString *userAccountHash = [[NSMutableString alloc] init];
  for (int i = 0; i < HASH_SIZE; i++) {
    // Add a dash every four bytes, for readability.
    if (i != 0 && i % 4 == 0) {
      [userAccountHash appendString:@"-"];
    }
    [userAccountHash appendFormat:@"%02x", hashedChars[i]];
  }
  return userAccountHash;
}

+ (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask {
  return [RUtils computeErrMessagesWithErrMask:signInErrMask
                                   errMessages:[APP signInErrMessages]];
}

+ (NSArray *)computeSaveUsrErrMsgs:(NSInteger)saveUsrErrMask {
  return [RUtils computeErrMessagesWithErrMask:saveUsrErrMask
                                   errMessages:[APP saveUserErrMessages]];
}

#pragma mark - Body Measurement Log Helpers

+ (NSArray *)computeBmlErrMsgs:(NSInteger)bmlErrMask {
  return [RUtils computeErrMessagesWithErrMask:bmlErrMask
                                   errMessages:[APP saveBmlErrMessages]];
}

#pragma mark - Set Helpers

+ (NSArray *)computeSetErrMsgs:(NSInteger)setErrMask {
  return [RUtils computeErrMessagesWithErrMask:setErrMask
                                   errMessages:[APP saveSetErrMessages]];
}

+ (NSArray *)filterMovementVariants:(NSArray *)movementVariants
                          usingMask:(NSInteger)variantMask {
  NSMutableArray *variants = [NSMutableArray array];
  for (RMovementVariant *movementVariant in movementVariants) {
    if (variantMask & movementVariant.localMasterIdentifier.integerValue) {
      [variants addObject:movementVariant];
    }
  }
  return variants;
}

#pragma mark - Various Error Handler Helpers

+ (ServerBusyHandlerMaker)serverBusyHandlerMakerForUIWithButtonAction:(void(^)(void))buttonAction {
  return ^(MBProgressHUD *HUD, UIViewController *controller, UIView *relativeToView) {
    return (^(NSDate *retryAfter) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [HUD hideAnimated:YES];
        [PEUIUtils showWaitAlertWithMsgs:nil
                                   title:@"Server undergoing maintenance."
                        alertDescription:[[NSAttributedString alloc] initWithString:@"\
We apologize, but the server is currently busy undergoing maintenance.  Please re-try your request shortly."]
                     descLblHeightAdjust:0.0
               additionalContentSections:nil
                                topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                             buttonTitle:@"Okay."
                            buttonAction:buttonAction
                          relativeToView:relativeToView];
      });
    });
  };
}

+ (SynchUnitOfWorkHandlerMakerZeroArg)loginHandlerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void(^successBlock)(void), void(^notAuthedAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
    return (^(NSError *error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          NSString *errorDomain = [error domain];
          NSInteger errorCode = [error code];
          NSArray *errMsgs;
          if ([errorDomain isEqualToString:RConnFaultedErrorDomain]) {
            NSString *localizedErrMsgKey =
            [errorDomain stringByAppendingFormat:@".%ld", (long)errorCode];
            errMsgs = @[NSLocalizedString(localizedErrMsgKey, nil)];
          } else if ([errorDomain isEqualToString:RUserFaultedErrorDomain]) {
            errMsgs = errMsgsMaker(errorCode);
          } else {
            errMsgs = @[[error localizedDescription]];
          }
          NSString *message;
          if ([errMsgs count] > 1) {
            message = @"Messages from the server:";
          } else {
            message = @"Message from the server:";
          }
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Authentication failure."
                           alertDescription:[[NSAttributedString alloc] initWithString:message]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:notAuthedAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock();
      }
    });
  };
}

+ (SynchUnitOfWorkHandlerMaker)synchUnitOfWorkHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void (^successBlock)(PELMUser *), void(^errAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
    return (^(PELMUser *newUser, NSError *error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          NSString *errorDomain = [error domain];
          NSInteger errorCode = [error code];
          NSArray *errMsgs;
          if ([errorDomain isEqualToString:RConnFaultedErrorDomain]) {
            NSString *localizedErrMsgKey =
            [errorDomain stringByAppendingFormat:@".%ld", (long)errorCode];
            errMsgs = @[NSLocalizedString(localizedErrMsgKey, nil)];
          } else if ([errorDomain isEqualToString:RUserFaultedErrorDomain]) {
            errMsgs = errMsgsMaker(errorCode);
          } else {
            errMsgs = @[[error localizedDescription]];
          }
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Oops."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  The details are as\nfollows:"]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:errAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock(newUser);
      }
    });
  };
}

+ (SynchUnitOfWorkHandlerMakerZeroArg)synchUnitOfWorkZeroArgHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker {
  return ^(MBProgressHUD *hud, void(^successBlock)(void), void(^errAlertAction)(void), UIViewController *controller, UIView *relativeToView) {
    return (^(NSError *error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          NSString *errorDomain = [error domain];
          NSInteger errorCode = [error code];
          NSArray *errMsgs;
          if ([errorDomain isEqualToString:RConnFaultedErrorDomain]) {
            NSString *localizedErrMsgKey =
            [errorDomain stringByAppendingFormat:@".%ld", (long)errorCode];
            errMsgs = @[NSLocalizedString(localizedErrMsgKey, nil)];
          } else if ([errorDomain isEqualToString:RUserFaultedErrorDomain]) {
            errMsgs = errMsgsMaker(errorCode);
          } else {
            errMsgs = @[[error localizedDescription]];
          }
          [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                      title:@"Oops."
                           alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred.  The details are as follows:"]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                buttonTitle:@"Okay."
                               buttonAction:errAlertAction
                             relativeToView:relativeToView];
        });
      } else {
        successBlock();
      }
    });
  };
}

+ (LocalDatabaseErrorHandlerMakerWithHUD)localDatabaseErrorHudHandlerMaker {
  return ^(MBProgressHUD *hud, UIViewController *controller, UIView *relativeToView) {
    return (^(NSError *error, int code, NSString *msg) {
      [[Crashlytics sharedInstance] recordError:error];
      [hud hideAnimated:YES];
      [PEUIUtils showErrorAlertWithMsgs:@[[error localizedDescription]]
                                  title:@"This is awkward."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"An error has occurred attempting to talk\n\
to the local database.  The details are:"]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:relativeToView];
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localSaveErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      [[Crashlytics sharedInstance] recordError:error];
      DDLogError(@"There was a problem saving data to the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localFetchErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      [[Crashlytics sharedInstance] recordError:error];
      DDLogError(@"There was a problem fetching data from the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localErrorHandlerForBackgroundProcessingMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      [[Crashlytics sharedInstance] recordError:error];
      DDLogError(@"There was a local database problem encountered while performing background processing.  Error message: %@", [error localizedDescription]);
    });
  };
}

+ (LocalDatabaseErrorHandlerMaker)localDatabaseCreationErrorHandlerMaker {
  return ^{
    return (^(NSError *error, int code, NSString *msg) {
      [[Crashlytics sharedInstance] recordError:error];
      DDLogError(@"There was a problem attempting to create the local database.  Error message: %@", [error localizedDescription]);
    });
  };
}

@end
