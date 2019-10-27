//
//  RPanelToolkit.m
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RPanelToolkit.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <DateTools/DateTools.h>
#import "JGActionSheet.h"
#import "UIColor+RAdditions.h"
#import "AppDelegate.h"
#import "RCoordinatorDao.h"
#import "PEUtils.h"
#import "PEUIUtils.h"
#import "RChangeLog.h"
#import "PELMUser.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "RLogging.h"
#import "PELocalDao.h"
#import "RForgotPasswordController.h"
#import "RAppNotificationNames.h"
#import "RBodyMeasurementLog.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "RSet.h"
#import "PESingleValueTableViewDataSourceDelegate.h"
#import "ROriginationDevice.h"
#import "RUserSettings.h"
#import "RAccountController.h"
#import "RAccountStatusDetailController.h"
#import "RCancelAccountSynchronizeScreen.h"
#import "RUpdatePaymentMethodSynchronizeScreen.h"
#import "RUserSettings.h"
@import Firebase;
@import HealthKit;
#import "RWatchUtils.h"
@import WatchConnectivity;
#import "NSString+PEAdditions.h"

NSString * const USE_RIKER_EXCLUSIVELY_TEXT = @"100% of Riker's features are available in the free phone and tablet apps.  Without an account subscription, the app will store all of your data locally to your device.  The risk is if you lose your device, or you accidentally uninstall Riker, you would lose all your data (unless you back it up).  Without a subscription, there is no Riker web access.\n\nThat said, Riker's export / import functionality can be used to manually backup your data, or transfer it to another device.";
NSString * const USE_RIKER_WITHOUT_ACCOUNT_TEXT = @"Yes.  100% of Riker's features are available in the free phone and tablet apps.  Without an account subscription, the app will store all of your data locally to your device.  The risk is if you lose your device, or you accidentally uninstall Riker, you would lose all your data (unless you back it up).  Without a subscription, there is no Riker web access.\n\nThat said, Riker's export / import functionality can be used to manually backup your data, or transfer it to another device.";

@implementation RPanelToolkit {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  PELMDaoErrorBlk _errorBlk;
  NSMutableArray *_tableViewDataSources;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
               screenToolkit:(RScreenToolkit *)screenToolkit
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _errorBlk = errorBlk;
    _tableViewDataSources = [NSMutableArray array];
  }
  return self;
}

#pragma mark - Export Helpers

- (void)invokeExportWithController:(UIViewController *)controller {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  NSDate *now = [NSDate date];
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
  hud.tag = RHUD_TAG;
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    NSString *setsFileName = [NSString stringWithFormat:@"riker-sets-%@.csv", [dateFormatter stringFromDate:now]];
    NSString *bmlsFileName = [NSString stringWithFormat:@"riker-body-logs-%@.csv", [dateFormatter stringFromDate:now]];
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    [_coordDao exportWithPathToSetsFile:[docsDir stringByAppendingPathComponent:setsFileName]
                bodyMeasurementLogsFile:[docsDir stringByAppendingPathComponent:bmlsFileName]
                                   user:user
                                  error:[RUtils localFetchErrorHandlerMaker]()];
    dispatch_async(dispatch_get_main_queue(), ^{
      [MBProgressHUD hideHUDForView:controller.view animated:YES];
      NSMutableAttributedString *instructions = [[NSMutableAttributedString alloc] init];
      [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"To download these files to your computer, connect your device to %@, click on your device, navigate to "
                                                                    textToAccent:@"iTunes"
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and scroll down to the "
                                                                    textToAccent:@"Apps"
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ section.  You'll see Riker listed.  Click on Riker and you'll be able to see and download your data files."
                                                                    textToAccent:@"File Sharing"
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [PEUIUtils showSuccessAlertWithMsgs:@[setsFileName, bmlsFileName]
                                    title:@"Export Complete."
                         alertDescription:[[NSAttributedString alloc] initWithString:@"Your Riker data has been exported to the following CSV files."]
                      descLblHeightAdjust:0.0
                additionalContentSections:@[[PEUIUtils infoAlertSectionWithTitle:@"Tip"
                                                                alertDescription:instructions
                                                             descLblHeightAdjust:0.0
                                                                  relativeToView:[PEUIUtils parentViewForAlertsForController:controller]],
                                            [PEUIUtils infoAlertSectionWithTitle:@"Share"
                                                                alertDescription:AS(@"The next screen will give you the option to share / save your CSV files to an external location.")
                                                             descLblHeightAdjust:0.0
                                                                  relativeToView:[PEUIUtils parentViewForAlertsForController:controller]]]
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:^{
                               [PEUIUtils showConfirmAlertWithTitle:@"Share?"
                                                         titleImage:nil
                                                   alertDescription:AS(@"Would you like to share your CSV files?  You can email them, AirDrop them or save them to an external location.")
                                                descLblHeightAdjust:0.0
                                                           topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                    okayButtonTitle:@"Share"
                                                   okayButtonAction:^{
                                                     UIActivityViewController *activityViewController =
                                                     [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:setsFileName]],
                                                                                                               [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:bmlsFileName]]]
                                                                                       applicationActivities:nil];
                                                     [controller.navigationController presentViewController:activityViewController
                                                                                                   animated:YES
                                                                                                 completion:nil];
                                                   }
                                                    okayButtonStyle:JGActionSheetButtonStyleBlue
                                                  cancelButtonTitle:@"Cancel"
                                                 cancelButtonAction:^{
                                                   
                                                 }
                                                   cancelButtonSyle:JGActionSheetButtonStyleCancel
                                                     relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                             }
                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
    });
  });
}

#pragma mark - Change Log Panel

- (void)invokeChangelogFetchForUser:(PELMUser *)user
                    userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
          actionIfChangesDownloaded:(void(^)(void))actionIfChangesDownloaded
                 successButtonTitle:(NSString *(^)(PELMUser *))successButtonTitle
            addlSuccessButtonAction:(void(^)(void))addlSuccessButtonAction
                         controller:(UIViewController *)controller {
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:controller];
  UIView *parentViewForAlerts = [PEUIUtils parentViewForAlertsForController:controller];
  if ([APP doesUserHaveValidAuthToken]) {
    MBProgressHUD *changelogHud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    changelogHud.delegate = (id<MBProgressHUDDelegate>)controller;
    changelogHud.tag = RHUD_TAG;
    DDLogDebug(@"proceeding to download changelog, ifModifiedSince: [%@]", [PEUtils millisecondsFromDate:[APP changelogUpdatedAt]]);
    changelogHud.label.text = @"Synchronizing with server...";
    enableUserInteraction(NO);
    void (^displayUnexpectedErrorAlert)(void) = ^{
      [PEUIUtils showErrorAlertWithMsgs:nil
                                  title:@"Error."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"We're sorry, but an unexpected error has occurred.  Please try this again later."]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                            buttonTitle:@"Okay."
                           buttonAction:^{
                             enableUserInteraction(YES);
                           }
                         relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
    };
    [_coordDao.userCoordinatorDao fetchChangelogForUser:user
                                        ifModifiedSince:[APP changelogUpdatedAt]
                                    notFoundOnServerBlk:^{
                                      [RUtils logEvent:@"not_found_wh_synchronizing"];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [changelogHud hideAnimated:YES];
                                        displayUnexpectedErrorAlert();
                                      });
                                    }
                                             successBlk:^(RChangeLog *changelog) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [changelogHud hideAnimated:YES];
                                                 void (^displayAlreadySynchronizedAlert)(void) = ^{
                                                   [RUtils logEvent:@"already_synchronized"];
                                                   [PEUIUtils showSuccessAlertWithTitle:@"Already synchronized."
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:@"Your device is already fully synchronized with your account."]
                                                                    descLblHeightAdjust:0.0
                                                                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                            buttonTitle:successButtonTitle(user)
                                                                           buttonAction:^{
                                                                             enableUserInteraction(YES);
                                                                             [APP refreshTabs]; // new maintenance-related info may have come back on user object
                                                                             if (addlSuccessButtonAction) {
                                                                               addlSuccessButtonAction();
                                                                             }
                                                                           }
                                                                         relativeToView:parentViewForAlerts];
                                                 };
                                                 if (changelog) {
                                                   [APP setChangelogUpdatedAt:changelog.updatedAt];                                                   
                                                   NSArray *report = [_coordDao saveChangelog:changelog
                                                                                      forUser:user
                                                                              userSettingsBlk:userSettingsBlk
                                                                                        error:[RUtils localSaveErrorHandlerMaker]()];
                                                   [_coordDao logFirebaseUserProperties];
                                                   NSInteger numTotalDeletes = [report[0] integerValue];
                                                   NSInteger numTotalUpdates = [report[1] integerValue];
                                                   NSInteger numTotalInserts = [report[2] integerValue];
                                                   if ((numTotalDeletes + numTotalUpdates + numTotalInserts) > 0) {
                                                     [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                                     NSDictionary *detailsDict = (NSDictionary *)report[3];
                                                     // ref data
                                                     NSArray *bodySegmentReport = detailsDict[CHANGELOG_DETAIL_BODY_SEGMENT];
                                                     NSArray *muscleGroupReport = detailsDict[CHANGELOG_DETAIL_MUSCLE_GROUP];
                                                     NSArray *muscleReport = detailsDict[CHANGELOG_DETAIL_MUSCLE];
                                                     NSArray *muscleAliasReport = detailsDict[CHANGELOG_DETAIL_MUSCLE_ALIAS];
                                                     NSArray *movementReport = detailsDict[CHANGELOG_DETAIL_MOVEMENT];
                                                     NSArray *movementVariant = detailsDict[CHANGELOG_DETAIL_MOVEMENT_VARIANT];
                                                     NSArray *originationDevice = detailsDict[CHANGELOG_DETAIL_ORIGINATION_DEVICE];
                                                     // user data
                                                     NSArray *userAccountReport = detailsDict[CHANGELOG_DETAIL_USER_ACCOUNT];
                                                     NSArray *userSettingsReport = detailsDict[CHANGELOG_DETAIL_USER_SETTINGS];
                                                     NSArray *setReport = detailsDict[CHANGELOG_DETAIL_SET];
                                                     NSArray *bmlReport = detailsDict[CHANGELOG_DETAIL_BML];
                                                     NSInteger (^toInteger)(NSArray *, NSInteger) = ^NSInteger(NSArray *report, NSInteger index) {
                                                       NSNumber *val = report[index];
                                                       return [val integerValue];
                                                     };
                                                     NSInteger (^updates)(NSArray *) = ^NSInteger(NSArray *report) {
                                                       return toInteger(report, 1);
                                                     };
                                                     NSInteger (^deletes)(NSArray *) = ^NSInteger(NSArray *report) {
                                                       return toInteger(report, 0);
                                                     };
                                                     NSInteger (^inserts)(NSArray *) = ^NSInteger(NSArray *report) {
                                                       return toInteger(report, 2);
                                                     };
                                                     NSMutableArray *alertSections = [NSMutableArray array];
                                                     NSMutableArray *syncMsgs = [NSMutableArray array];
                                                     if (updates(userAccountReport) > 0) {
                                                       [syncMsgs addObject:@"My Account updated"];
                                                       [RUtils logEvent:@"synchronized_account"];
                                                     }
                                                     if (updates(userSettingsReport) > 0) {
                                                       [syncMsgs addObject:@"Profile & Settings updated"];
                                                       [RUtils logEvent:@"synchronized_settings"];                                                       
                                                     }
                                                     NSString *(^pluralizedMsg)(NSInteger, NSString *, NSString *) = ^NSString *(NSInteger count, NSString *type, NSString *op) {
                                                       NSNumberFormatter *formatter = [NSNumberFormatter new];
                                                       [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                                       return [NSString stringWithFormat:@"%@ %@%@ %@", [formatter stringFromNumber:@(count)], type, count == 1 ? @"" : @"s", op];
                                                     };
                                                     void(^addMsg)(NSInteger, NSString *, NSString *) = ^(NSInteger count, NSString *type, NSString *op) {
                                                       if (count > 0) {
                                                         [syncMsgs addObject:pluralizedMsg(count, type, op)];
                                                       }
                                                     };
                                                     NSString *setLbl = @"set";
                                                     NSString *bmlLbl = @"body log";
                                                     addMsg(inserts(setReport), setLbl, @"added");
                                                     addMsg(updates(setReport), setLbl, @"updated");
                                                     addMsg(deletes(setReport), setLbl, @"deleted");
                                                     addMsg(inserts(bmlReport), bmlLbl, @"added");
                                                     addMsg(updates(bmlReport), bmlLbl, @"updated");
                                                     addMsg(deletes(bmlReport), bmlLbl, @"deleted");
                                                     if (syncMsgs.count > 0) {
                                                       JGActionSheetSection *section =
                                                       [PEUIUtils successAlertSectionWithMsgs:syncMsgs
                                                                                        title:@"Synchronized."
                                                                             alertDescription:[[NSAttributedString alloc] initWithString:@"Your account is now synchronized.  Here's what synced:"]
                                                                          descLblHeightAdjust:0.0
                                                                               relativeToView:parentViewForAlerts];
                                                       [alertSections addObject:section];
                                                     }
                                                     NSInteger totalNumChanges = inserts(setReport) + updates(setReport) + deletes(setReport);
                                                     if (totalNumChanges > 0) {
                                                       [RUtils logEvent:@"synchronized_sets" params:@{@"num_changes" : @(totalNumChanges)}];
                                                     }
                                                     totalNumChanges = inserts(bmlReport) + updates(bmlReport) + deletes(bmlReport);
                                                     if (totalNumChanges > 0) {
                                                       [RUtils logEvent:@"synchronized_bmls" params:@{@"num_changes" : @(totalNumChanges)}];
                                                     }
                                                     NSInteger numMovementsAdded = inserts(movementReport);
                                                     if (numMovementsAdded > 0) {
                                                       [RUtils logEvent:@"synchronized_movements_added"];
                                                       NSString *desc;
                                                       if (syncMsgs.count > 0) {
                                                         desc = @"In addition to synchronizing your account, new movement data was downloaded:";
                                                       } else {
                                                         desc = @"New movement data downloaded:";
                                                       }
                                                       JGActionSheetSection *section =
                                                       [PEUIUtils infoAlertSectionWithMsgs:@[pluralizedMsg(numMovementsAdded, @"movement", @"added")]
                                                                                     title:@"Movements added"
                                                                          alertDescription:[[NSAttributedString alloc] initWithString:desc]
                                                                       descLblHeightAdjust:0.0
                                                                            relativeToView:parentViewForAlerts];
                                                       [alertSections addObject:section];
                                                     }                                                     
                                                     BOOL(^hasEdits)(NSArray *) = ^BOOL(NSArray *report) {
                                                       return updates(report) > 0 || inserts(report) > 0 || deletes(report) > 0;
                                                     };
                                                     BOOL(^hasStrictUpdates)(NSArray *) = ^BOOL(NSArray *report) {
                                                       return updates(report) > 0;
                                                     };
                                                     if (hasEdits(bodySegmentReport) ||
                                                         hasEdits(muscleGroupReport) ||
                                                         hasEdits(muscleReport) ||
                                                         hasEdits(muscleAliasReport) ||
                                                         hasStrictUpdates(movementReport) ||
                                                         hasEdits(movementVariant) ||
                                                         hasEdits(originationDevice)) {
                                                       [RUtils logEvent:@"synchronized_internal_updates"];
                                                       NSString *desc;
                                                       if (syncMsgs.count > 0 || numMovementsAdded > 0) {
                                                         desc = @"Some internal Riker updates were downloaded as well.";
                                                       } else {
                                                         desc = @"Internal Riker updates were downloaded.";
                                                       }
                                                       JGActionSheetSection *section =
                                                       [PEUIUtils infoAlertSectionWithTitle:@"Internal updates"
                                                                           alertDescription:[[NSAttributedString alloc] initWithString:desc]
                                                                        descLblHeightAdjust:0.0
                                                                             relativeToView:parentViewForAlerts];
                                                       [alertSections addObject:section];
                                                       JGActionSheetSection *watchInfoSection =
                                                       [RPanelToolkit watchReminderAlertSectionRelativeToView:parentViewForAlerts];
                                                       if (watchInfoSection) {
                                                         [alertSections addObject:watchInfoSection];
                                                       }
                                                     }
                                                     //[RUtils analyticsInitializeUserWithCoordDao:_coordDao];
                                                     [PEUIUtils showAlertWithButtonTitle:successButtonTitle(user)
                                                                                topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                            buttonAction:^{
                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:RChangelogDownloadedNotification
                                                                                                                                  object:nil
                                                                                                                                userInfo:nil];
                                                                              if (actionIfChangesDownloaded) {
                                                                                actionIfChangesDownloaded();
                                                                              }
                                                                              enableUserInteraction(YES);
                                                                              [APP resetUserInterface];
                                                                              if (addlSuccessButtonAction) {
                                                                                addlSuccessButtonAction();
                                                                              }
                                                                            }
                                                                         addlButtonTitle:nil
                                                                        addlButtonAction:nil
                                                                         addlButtonStyle:0
                                                                          relativeToView:parentViewForAlerts
                                                                         contentSections:alertSections];
                                                   } else {
                                                     displayAlreadySynchronizedAlert();
                                                   }
                                                 } else {
                                                   displayAlreadySynchronizedAlert();
                                                 }
                                               });
                                             }
                                     remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                        [RUtils logEvent:@"busy_wh_synchronizing"];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         [changelogHud hideAnimated:YES];
                                         [PEUIUtils showWaitAlertWithMsgs:nil
                                                                    title:@"Server undergoing maintenance."
                                                         alertDescription:[[NSAttributedString alloc] initWithString:@"The server is currently busy at the moment undergoing maintenance. Please try this again later."]
                                                      descLblHeightAdjust:0.0
                                                additionalContentSections:nil
                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                              buttonTitle:@"Okay."
                                                             buttonAction:^{
                                                               enableUserInteraction(YES);
                                                             }
                                                           relativeToView:parentViewForAlerts];
                                       });
                                     }
                                     tempRemoteErrorBlk:^{
                                        [RUtils logEvent:@"tmp_remote_err_wh_synchronizing"];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         [changelogHud hideAnimated:YES];
                                         displayUnexpectedErrorAlert();
                                       });
                                     }
                                    addlAuthRequiredBlk:^{
                                       [RUtils logEvent:@"auth_reqd_wh_synchronizing"];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [changelogHud hideAnimated:YES];
                                        [APP refreshTabs];                                        
                                        NSAttributedString *attrBecameUnauthMessage =
                                        [PEUIUtils attributedTextWithTemplate:@"Well this is awkward.  While syncing your account, the server is asking for you to re-authenticate.\n\nTo re-authenticate, go to:\n\n%@."
                                                                 textToAccent:@"Account \u2794 Re-authenticate"
                                                               accentTextFont:boldDescFont];
                                        [PEUIUtils showWarningAlertWithMsgs:nil
                                                                      title:@"Authentication Failure."
                                                           alertDescription:attrBecameUnauthMessage
                                                        descLblHeightAdjust:0.0
                                                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                buttonTitle:@"Okay."
                                                               buttonAction:^{
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                                     object:nil
                                                                                                                   userInfo:nil];
                                                                 enableUserInteraction(YES);
                                                                 [APP refreshTabs];
                                                                 [controller viewDidAppear:YES];
                                                               }
                                                             relativeToView:parentViewForAlerts];
                                      });
                                    }];
  } else {
    [RUtils logEvent:@"cannot_synchronize_unauthenticated"];
    NSAttributedString *attrBecameUnauthMessage =
    [PEUIUtils attributedTextWithTemplate:@"You are not currently authenticated.\n\nTo re-authenticate, go to:\n\n%@."
                             textToAccent:@"Account \u2794 Re-authenticate"
                           accentTextFont:boldDescFont];
    [PEUIUtils showWarningAlertWithMsgs:nil
                                  title:@"Not Authenticated."
                       alertDescription:attrBecameUnauthMessage
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                            buttonTitle:@"Okay."
                           buttonAction:^{
                             enableUserInteraction(YES);
                             [APP refreshTabs];
                             [controller viewDidAppear:YES];
                           }
                         relativeToView:parentViewForAlerts];
  }
}

- (UIView *)changeLogPanelWithParentView:(UIView *)contentPanel
                              controller:(UIViewController *)controller
                                    user:(PELMUser *)user
                         userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
               actionIfChangesDownloaded:(void(^)(void))actionIfChangesDownloaded {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *changelogPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.0 relativeToView:contentPanel];
  UIView *changelogMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"\
Keeps your device synchronized with your account in case you've made edits \
and deletions on other devices."
                                                                        font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                             backgroundColor:[UIColor clearColor]
                                                                   textColor:[UIColor darkGrayColor]
                                                         verticalTextPadding:3.0
                                                                  fitToWidth:contentPanel.frame.size.width - (8.0 * 2) - (iphoneXSafeInsetsSideVal * 2)]
                                             padding:8.0 + iphoneXSafeInsetsSideVal];
  UIButton *changelogBtn = [_uitoolkit systemButtonMaker](@"Synchronize Account", nil, nil);
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download-icon"]]
            inMiddleOf:changelogBtn
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:[PEUIUtils valueIfiPhone5Width:18
                                         iphone6Width:18
                                     iphone6PlusWidth:20
                                                 ipad:20] + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameWidthOfView:changelogBtn ofWidth:1.0 relativeTo:contentPanel];  
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:changelogBtn atTopOf:changelogPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  totalHeight += changelogBtn.frame.size.height;
  [PEUIUtils placeView:changelogMsgPanel below:changelogBtn onto:changelogPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
  totalHeight += changelogMsgPanel.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:changelogPanel];
  [changelogBtn bk_addEventHandler:^(id sender) {
    [RUtils logEvent:@"synchronize_clicked"];
    [self invokeChangelogFetchForUser:user
                      userSettingsBlk:userSettingsBlk
            actionIfChangesDownloaded:actionIfChangesDownloaded
                   successButtonTitle:^(PELMUser *user) { return @"Okay."; }
              addlSuccessButtonAction:nil
                           controller:controller];
  } forControlEvents:UIControlEventTouchUpInside];
  return changelogPanel;
}

#pragma mark - Helpers

+ (CGFloat)rowDataCellHeightWithFontTextStyle:(UIFontTextStyle)fontTextStyle
                                    uitoolkit:(PEUIToolkit *)uitoolkit {
  return ([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:fontTextStyle]].height +
          uitoolkit.verticalPaddingForButtons +
          [PEUIUtils valueIfiPhone5Width:7.0
                            iphone6Width:7.0
                        iphone6PlusWidth:3.5 // smaller than iphone 6 because iphone 6 gets smaller 'subheadline' font
                                    ipad:5.0]);
}

- (UIView *)tablePanelWithRowData:(NSArray *)rowData
                        uitoolkit:(PEUIToolkit *)uitoolkit
                    fontTextStyle:(UIFontTextStyle)fontTextStyle
                       parentView:(UIView *)parentView {
  return [self tablePanelWithRowData:rowData
                      valueTextStyle:fontTextStyle
                           uitoolkit:uitoolkit
                          parentView:parentView];
}

- (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   valueTextStyle:(UIFontTextStyle)valueTextStyle
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *view = [PEUIUtils tablePanelWithRowData:rowData
                                   withCellHeight:[RPanelToolkit rowDataCellHeightWithFontTextStyle:valueTextStyle uitoolkit:_uitoolkit]
                                labelLeftHPadding:[PEUIUtils valueIfiPhone5Width:15
                                                                    iphone6Width:16
                                                                iphone6PlusWidth:20
                                                                            ipad:20] + iphoneXSafeInsetsSideVal
                               valueRightHPadding:[PEUIUtils valueIfiPhone5Width:14
                                                                    iphone6Width:14
                                                                iphone6PlusWidth:20
                                                                            ipad:20] + (iphoneXSafeInsetsSideVal * 2)
                                   labelTextStyle:valueTextStyle
                                   valueTextStyle:valueTextStyle
                                   labelTextColor:[UIColor blackColor]
                                   valueTextColor:[UIColor grayColor]
                   minPaddingBetweenLabelAndValue:10.0
                                includeTopDivider:NO
                             includeBottomDivider:NO
                             includeInnerDividers:NO
                          innerDividerWidthFactor:0.95
                                   dividerPadding:3.5
                          rowPanelBackgroundColor:[UIColor whiteColor]
                             panelBackgroundColor:[uitoolkit colorForWindows]
                                     dividerColor:nil
                             footerAttributedText:nil
                   footerFontForHeightCalculation:nil
                            footerVerticalPadding:0.0
                                         rowWidth:parentView.frame.size.width
                                         maxWidth:parentView.frame.size.width
                                   relativeToView:parentView];  
  return view;
}

- (UITableView *)makeTableViewWithTag:(NSInteger)tag
                            numFields:(NSInteger)numFields
              dataSourceDelegateMaker:(id(^)(UITableView *))dataSourceDelegateMaker
                       relativeToView:(UIView *)relativeToView
                 parentViewController:(UIViewController *)parentViewController {
  UITableView *tableView = [PEUIUtils makeTableViewWithTag:@(tag)
                                                 numFields:numFields
                                   dataSourceDelegateMaker:dataSourceDelegateMaker
                                            relativeToView:relativeToView
                                      parentViewController:parentViewController];
  [_tableViewDataSources addObject:tableView.dataSource];
  return tableView;
}

- (void)makeSwitchWithTag:(NSInteger)switchTag
                 panelTag:(NSInteger)panelTag
                labelText:(NSString *)labelText
                labelFont:(UIFont *)labelFont
              panelHeight:(CGFloat)panelHeight
               parentView:(UIView *)parentView
               components:(NSMutableDictionary *)components {
  UISwitch *switchView = (UISwitch *)[parentView viewWithTag:switchTag];
  UIView *switchPanel = (UIView *)[parentView viewWithTag:panelTag];
  if (!switchView) {
    CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
    switchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [switchView setTag:switchTag];
    switchPanel = [PEUIUtils panelWithWidthOf:1.0
                               relativeToView:parentView
                                  fixedHeight:panelHeight];
    [switchPanel setTag:panelTag];
    [switchPanel setBackgroundColor:[UIColor whiteColor]];
    UILabel *switchLabel = [PEUIUtils labelWithKey:labelText
                                              font:labelFont
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[_uitoolkit colorForTableCellTitles]
                               verticalTextPadding:3.0];
    [PEUIUtils placeView:switchLabel
              inMiddleOf:switchPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:[_uitoolkit leftViewPaddingForTextfields] + iphoneXSafeInsetsSideVal];
    [PEUIUtils placeView:switchView
              inMiddleOf:switchPanel
           withAlignment:PEUIHorizontalAlignmentTypeRight
                hpadding:15.0 + iphoneXSafeInsetsSideVal];
    [PEUIUtils styleViewForIpad:switchPanel];
  }
  components[@(switchTag)] = switchView;
  components[@(panelTag)] = switchPanel;
}

- (UIView *)importedAtPanelWithImportedAt:(NSDate *)importedAt
                               entityType:(NSString *)entityType
                               parentView:(UIView *)parentView {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0
                               relativeToView:parentView
                                  fixedHeight:[PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
                   _uitoolkit.verticalPaddingForButtons + [PEUIUtils valueIfiPhone5Width:1.5
                                                                            iphone6Width:1.5
                                                                        iphone6PlusWidth:5.0
                                                                                    ipad:5.0]];
  [panel setBackgroundColor:[UIColor whiteColor]];
  [PEUIUtils placeView:[PEUIUtils labelWithKey:@"Imported"
                                          font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                               backgroundColor:[UIColor clearColor]
                                     textColor:[UIColor blackColor]
                           verticalTextPadding:3.0]
            inMiddleOf:panel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:[PEUIUtils valueIfiPhone5Width:17
                                         iphone6Width:18
                                     iphone6PlusWidth:22
                                                 ipad:22]];
  UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imported-small-icon"]];
  [PEUIUtils placeView:icon inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:20.0];
  [PEUIUtils placeView:[PEUIUtils labelWithKey:[PEUtils stringFromDate:importedAt withPattern:DATETIME_PATTERN]
                                          font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                           iphone6Width:UIFontTextStyleCaption1
                                                                                                       iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                   ipad:UIFontTextStyleSubheadline]]
                               backgroundColor:[UIColor clearColor]
                                     textColor:[UIColor grayColor]
                           verticalTextPadding:3.0]
           toTheLeftOf:icon
                  onto:panel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:10.0];
  UILabel *msgLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"This %@ record was created as part of an import.", entityType]
                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor darkGrayColor]
                          verticalTextPadding:3.0
                                   fitToWidth:parentView.frame.size.width - 15.0];
  UIView *containerPanel = [PEUIUtils panelWithWidthOf:1.0
                                        relativeToView:parentView
                                           fixedHeight:panel.frame.size.height + msgLabel.frame.size.height + 4.0];
  [PEUIUtils placeView:panel atTopOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  [PEUIUtils placeView:msgLabel
                 below:panel
                  onto:containerPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:containerPanel
              vpadding:4.0
              hpadding:8.0];
  return containerPanel;
}

- (UIView *)originationDevicePanelWithOriginationDevice:(ROriginationDevice *)originationDevice
                                             parentView:(UIView *)parentView {
  UIImageView *origDeviceImageView = [RUIUtils imageViewForOriginationDevice:originationDevice];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *originationPanel =
  [PEUIUtils labelValuePanelWithCellHeight:([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]].height + _uitoolkit.verticalPaddingForButtons + origDeviceImageView.frame.size.height)
                               labelString:@"Origination device"
                            labelTextStyle:[PEUIUtils subheadlineFontTextStyle]
                            labelTextColor:[UIColor blackColor]
                         labelLeftHPadding:[PEUIUtils valueIfiPhone5Width:15.0
                                                             iphone6Width:15.0
                                                         iphone6PlusWidth:20.0
                                                                     ipad:20.0] + iphoneXSafeInsetsSideVal
                             iconImageView:origDeviceImageView
                               valueString:originationDevice.name
                            valueTextStyle:UIFontTextStyleCaption2
                            valueTextColor:[UIColor grayColor]
                        valueRightHPadding:[PEUIUtils valueIfiPhone5Width:15.0
                                                             iphone6Width:15.0
                                                         iphone6PlusWidth:15.0
                                                                     ipad:15.0] + (iphoneXSafeInsetsSideVal * 2)
                             valueLabelTag:nil
             minPaddingBetweenLabelAndIcon:10.0
                                  rowWidth:parentView.frame.size.width
                            relativeToView:parentView];
  [originationPanel setBackgroundColor:[UIColor whiteColor]];
  UILabel *msgLabel = [PEUIUtils labelWithKey:@"The device used to create this record."
                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor darkGrayColor]
                          verticalTextPadding:3.0
                                   fitToWidth:parentView.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIView *containerPanel = [PEUIUtils panelWithWidthOf:1.0
                                        relativeToView:parentView
                                           fixedHeight:originationPanel.frame.size.height + msgLabel.frame.size.height + 4.0];
  [PEUIUtils placeView:originationPanel atTopOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  [PEUIUtils placeView:msgLabel
                 below:originationPanel
                  onto:containerPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:containerPanel
              vpadding:4.0
              hpadding:8.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils styleViewForIpad:originationPanel];
  return containerPanel;
}

- (id)valueAtTableTag:(NSInteger)tableTag
         orBlockIfNil:(id(^)(void))blkIfNil
           parentView:(UIView *)parentView {
  PESingleValueTableViewDataSourceDelegate *ds =
  (PESingleValueTableViewDataSourceDelegate *)[(UITableView *)[parentView viewWithTag:tableTag] dataSource];
  if (ds) {
    return [ds pickedValue];
  } else {
    return blkIfNil();
  }
}

+ (UIFont *)contentInfoButtonFont {
  return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:36.0]
                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                                                            iphone6Width:UIFontTextStyleBody
                                                                                                        iphone6PlusWidth:UIFontTextStyleBody
                                                                                                                    ipad:UIFontTextStyleTitle3]]];
}

- (UIView *)loggedInCrudToolbarHelpPanelWithWidth:(CGFloat)panelWidth {
  UIView *panel = [PEUIUtils panelWithFixedWidth:panelWidth fixedHeight:0.0];
  CGFloat totalHeight = 0.0;
  UIView *(^icon)(NSString *, CGFloat) = ^(NSString *iconName, CGFloat topPadding) {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
    UIView *view = [PEUIUtils panelWithWidthOf:1.0 relativeToView:imageView fixedHeight:imageView.frame.size.height + topPadding];
    [PEUIUtils placeView:imageView atBottomOf:view withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    return view;
  };
  UILabel *(^label)(NSString *, CGFloat) = ^(NSString *text, CGFloat fitToWidth) {
    UILabel *lbl = [PEUIUtils labelWithKey:text
                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor blackColor]
                       verticalTextPadding:5.0
                                fitToWidth:fitToWidth];
    return lbl;
  };
  UIView *deleteIcon = icon(@"delete-icon", 8.0);
  CGFloat iconWidth = deleteIcon.frame.size.width;
  CGFloat labelWidth = panelWidth - 5.0 - iconWidth - 15.0 - 15.0;
  
  // make views
  UIView *deletePanel = [PEUIUtils panelWithRowOfViews:@[deleteIcon, label(@"Deletes this record.", labelWidth)]
                         horizontalPaddingBetweenViews:15.0
                                        viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  UIView *downloadPanel = [PEUIUtils panelWithRowOfViews:@[icon(@"download-icon", 10.0), label(@"Downloads the latest version of this record (in case you've edited it from another device).", labelWidth)]
                           horizontalPaddingBetweenViews:15.0
                                          viewsAlignment:PEUIVerticalAlignmentTypeTop];
  UIView *uploadPanel = [PEUIUtils panelWithRowOfViews:@[icon(@"upload-icon", 8.0), label(@"Syncs this record to your account if you've made local edits.", labelWidth)]
                         horizontalPaddingBetweenViews:15.0
                                        viewsAlignment:PEUIVerticalAlignmentTypeTop];
  
  // place views
  [PEUIUtils placeView:deletePanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:5.0];
  totalHeight += deletePanel.frame.size.height + 10.0;
  [PEUIUtils placeView:downloadPanel below:deletePanel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:15.0 hpadding:0.0];
  totalHeight += downloadPanel.frame.size.height + 15.0;
  [PEUIUtils placeView:uploadPanel below:downloadPanel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:15.0 hpadding:0.0];
  totalHeight += uploadPanel.frame.size.height + 15.0;
  
  totalHeight += 15.0; // some bottom margin
  [PEUIUtils setFrameHeight:totalHeight ofView:panel];
  return panel;
}

- (UIView *)healthKitSwitchPanelWithController:(PEBaseController *)controller
                                           tag:(NSInteger)tag
                                relativeToView:(UIView *)relativeToView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UISwitch *healthKitSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  UISwitch *hkWorkoutsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  UISwitch *hkBodyWeightSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  BOOL healthKitIntegrationEnabled = [PEUtils isNotNil:[RUtils healthKitEnabledAt]];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  [healthKitSwitch setOn:healthKitIntegrationEnabled];
  [hkWorkoutsSwitch setUserInteractionEnabled:healthKitIntegrationEnabled];
  [hkBodyWeightSwitch setUserInteractionEnabled:healthKitIntegrationEnabled];
  if (healthKitIntegrationEnabled) {
    [hkWorkoutsSwitch setOn:[PEUtils isNil:[RUtils hkWorkoutSaveDisabledAt]]];
    [hkBodyWeightSwitch setOn:[PEUtils isNil:[RUtils hkBodyWeightSaveDisabledAt]]];
  } else {
    [hkWorkoutsSwitch setOn:NO];
    [hkBodyWeightSwitch setOn:NO];
    [hkWorkoutsSwitch setThumbTintColor:[UIColor silverColor]];
    [hkBodyWeightSwitch setThumbTintColor:[UIColor silverColor]];
  }
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  [desc appendAttributedString:AS(@"Sync your workout and body weight information to Apple's Health app.")];
  UILabel *healthKitLabel = [PEUIUtils labelWithKey:@"Apple Health"
                                               font:[_uitoolkit fontForButtonsBlk]()
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor blackColor]
                                verticalTextPadding:3.0];
  UILabel *workoutsLabel = [PEUIUtils labelWithKey:@"Workouts"
                                              font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:38.0]
                                                                                         font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[UIColor blackColor]
                               verticalTextPadding:3.0];
  UILabel *bodyWeightLabel = [PEUIUtils labelWithKey:@"Body weight"
                                                font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:38.0]
                                                                                           font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor blackColor]
                                 verticalTextPadding:3.0];
  UIView *healthKitDescription = [PEUIUtils leftPaddingMessageWithAttributedText:desc relativeToView:relativeToView];
  UIButton *learnMoreButton = [PEUIUtils buttonWithKey:@"Learn more about Apple Health\nintegration."
                                                  font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:21.0 iphone6Width:26.0 iphone6PlusWidth:26.0 ipad:32.0]
                                                                                             font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor bootstrapPrimary]
                          disabledStateBackgroundColor:[UIColor clearColor]
                                disabledStateTextColor:[UIColor clearColor]
                                       verticalPadding:5.0
                                     horizontalPadding:0.0
                                          cornerRadius:0.0
                                                target:nil
                                                action:nil];
  learnMoreButton.titleLabel.textAlignment = NSTextAlignmentLeft;
  [learnMoreButton bk_addEventHandler:^(id sender) {
    NSMutableAttributedString *learnMore = [[NSMutableAttributedString alloc] init];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Riker will save your sets into Apple's Health app as %@."
                                                               textToAccent:@"workouts"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nA workout in Apple's Health app has an Activity Type and a Calorie count.  Riker will save workouts in Apple Health with an activity type of %@."
                                                               textToAccent:@"Traditional Strength Training"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [learnMore appendAttributedString:AS(@"\n\nRiker will automatically determine your workouts based on the timestamps of your sets.")];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nCalories burned is not straightforward to calculate.  Riker computes your calories burned based on a study performed by %@.  In the study, calories-burned was computed for different body weights and workout duration, along with an activity type.  Two of those activity types are: "
                                                               textToAccent:@"Harvard Medical School"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n(1) %@ and "
                                                               textToAccent:@"Weight Lifting: general"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n(2) %@.  "
                                                               textToAccent:@"Weight Lifting: vigorous"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [learnMore appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nRiker will use the formula for vigorous if at least 50%% of your sets for the workout are marked as %@."
                                                               textToAccent:@"To Failure"
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    UIView *harvardStudyAlertContentView = [self alertSectionContentViewRelativeToView:relativeToView];
    UIButton *linkToStudyButton = [PEUIUtils buttonWithKey:@"Open Harvard Medical\nSchool Calories Burned Study"
                                                      font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                           backgroundColor:[UIColor clearColor]
                                                 textColor:[UIColor bootstrapPrimary]
                              disabledStateBackgroundColor:[UIColor clearColor]
                                    disabledStateTextColor:[UIColor clearColor]
                                           verticalPadding:5.0
                                         horizontalPadding:0.0
                                              cornerRadius:0.0
                                                    target:nil
                                                    action:nil];
    linkToStudyButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [linkToStudyButton bk_addEventHandler:^(id sender) {
      [RUtils logEvent:@"viewed_harvard_calorie_study"];
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.health.harvard.edu/newsweek/Calories-burned-in-30-minutes-of-leisure-and-routine-activities.htm"]
                                         options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @(NO)}
                               completionHandler:^(BOOL success) { NSLog(@"opened url? %@", [PEUtils yesNoFromBool:success]); }];
    } forControlEvents:UIControlEventTouchUpInside];
    CGFloat totalHeightHarvardStudyAlertContentView = 0.0;
    CGFloat vpadding = 10.0;
    [PEUIUtils placeView:linkToStudyButton atTopOf:harvardStudyAlertContentView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:6.0];
    totalHeightHarvardStudyAlertContentView += linkToStudyButton.frame.size.height + vpadding;
    totalHeightHarvardStudyAlertContentView += vpadding; // bottom margin
    [PEUIUtils setFrameHeight:totalHeightHarvardStudyAlertContentView ofView:harvardStudyAlertContentView];
    JGActionSheetSection *harvardStudyAlertSection = [JGActionSheetSection sectionWithTitle:nil message:nil contentView:harvardStudyAlertContentView];
    [PEUIUtils showInfoAlertWithTitle:@"Apple Health Integration"
                     alertDescription:learnMore
                  descLblHeightAdjust:0.0
            additionalContentSections:@[harvardStudyAlertSection]
                             topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                          buttonTitle:@"Okay."
                         buttonAction:^{}
                       relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  } forControlEvents:UIControlEventTouchUpInside];
  
  UIView *healthKitSwitchPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  CGFloat totalHeightHealthKitSwitchPanel = 0.0;
  [healthKitSwitchPanel setBackgroundColor:[UIColor whiteColor]];
  CGFloat vpadding = 8.0;
  [PEUIUtils placeView:healthKitLabel atTopOf:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils placeView:healthKitSwitch atTopOf:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:vpadding hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameY:[PEUIUtils YForHeight:healthKitLabel.frame.size.height withAlignment:PEUIVerticalAlignmentTypeMiddle relativeToView:healthKitSwitch vpadding:0.0]
                ofView:healthKitLabel];
  totalHeightHealthKitSwitchPanel += healthKitSwitch.frame.size.height + vpadding;
  UIView *separator = [PEUIUtils panelWithWidthOf:1.0 relativeToView:healthKitSwitchPanel fixedHeight:1.5];
  [separator setBackgroundColor:[UIColor cloudsColor]];
  [PEUIUtils placeView:separator below:healthKitSwitch onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:healthKitSwitchPanel vpadding:vpadding hpadding:0.0];
  totalHeightHealthKitSwitchPanel += separator.frame.size.height + vpadding;
  [PEUIUtils placeView:workoutsLabel below:separator onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:20.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils placeView:hkWorkoutsSwitch below:separator onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:vpadding hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameY:[PEUIUtils YForHeight:workoutsLabel.frame.size.height withAlignment:PEUIVerticalAlignmentTypeMiddle relativeToView:hkWorkoutsSwitch vpadding:0.0]
                ofView:workoutsLabel];
  totalHeightHealthKitSwitchPanel += (hkWorkoutsSwitch.frame.size.height > workoutsLabel.frame.size.height ? hkWorkoutsSwitch.frame.size.height : workoutsLabel.frame.size.height) + vpadding;
  NSDate *lastWorkoutEndDate = [RUtils lastHkWorkoutEndDate];
  UILabel *workoutsDetailLabel;
  vpadding = 2.0;
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:38.0];
  if (lastWorkoutEndDate) {
    workoutsDetailLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"All sets logged up to %@ are processed."
                                                                                     textToAccent:[PEUtils stringFromDate:lastWorkoutEndDate withPattern:DATETIME_PATTERN]
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils captionFontTextStyle]]]
                                                       font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlack]
                                        verticalTextPadding:1.5
                                                 fitToWidth:healthKitSwitchPanel.frame.size.width - (workoutsLabel.frame.origin.x + hkWorkoutsSwitch.frame.size.width + 15.0) - (iphoneXSafeInsetsSideVal * 2)];
  } else {
    workoutsDetailLabel = [PEUIUtils labelWithAttributeText:AS(@"No sets synced to Apple Health yet.")
                                                       font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlack]
                                        verticalTextPadding:1.5
                                                 fitToWidth:healthKitSwitchPanel.frame.size.width - (workoutsLabel.frame.origin.x + hkWorkoutsSwitch.frame.size.width + 15.0) - (iphoneXSafeInsetsSideVal * 2)];
  }
  UIButton *syncWorkoutsButton = [PEUIUtils buttonWithKey:@"Sync Workouts"
                                                     font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:32.0]
                                                                                            font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]]
                                          backgroundColor:[UIColor rikerAppBlackSemiClear]
                                                textColor:[UIColor whiteColor]
                             disabledStateBackgroundColor:[UIColor rikerAppBlackReallyClear]
                                   disabledStateTextColor:nil
                                          verticalPadding:[PEUIUtils valueIfiPhone5Width:18.0 iphone6Width:20.0 iphone6PlusWidth:24.0 ipad:28.0]
                                        horizontalPadding:[PEUIUtils valueIfiPhone5Width:38.0 iphone6Width:42.0 iphone6PlusWidth:46.0 ipad:50.0]
                                             cornerRadius:5.0
                                                   target:nil
                                                   action:nil];
  [syncWorkoutsButton setEnabled:hkWorkoutsSwitch.on];
  [PEUIUtils placeView:workoutsDetailLabel below:workoutsLabel onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  totalHeightHealthKitSwitchPanel += workoutsDetailLabel.frame.size.height + vpadding;
  vpadding = 10.0;
  [PEUIUtils placeView:syncWorkoutsButton below:workoutsDetailLabel onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  totalHeightHealthKitSwitchPanel += syncWorkoutsButton.frame.size.height + vpadding;
  vpadding = 8.0;
  [PEUIUtils placeView:bodyWeightLabel below:syncWorkoutsButton onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  [PEUIUtils placeView:hkBodyWeightSwitch below:syncWorkoutsButton onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight alignmentRelativeToView:healthKitSwitchPanel vpadding:vpadding hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameY:[PEUIUtils YForHeight:bodyWeightLabel.frame.size.height withAlignment:PEUIVerticalAlignmentTypeMiddle relativeToView:hkBodyWeightSwitch vpadding:0.0]
                ofView:bodyWeightLabel];
  totalHeightHealthKitSwitchPanel += (hkBodyWeightSwitch.frame.size.height > bodyWeightLabel.frame.size.height ? hkBodyWeightSwitch.frame.size.height : bodyWeightLabel.frame.size.height) + vpadding;
  NSDate *lastBodyWeightEndDate = [RUtils lastHkBodyWeightEndDate];
  UILabel *bodyWeightDetailLabel;
  vpadding = 2.0;
  if (lastBodyWeightEndDate) {
    bodyWeightDetailLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"All body weights logged up to %@ are synced to Apple Health."
                                                                                       textToAccent:[PEUtils stringFromDate:lastBodyWeightEndDate withPattern:DATE_PATTERN]
                                                                                     accentTextFont:[PEUIUtils boldFontWithMaxAllowedPointSize:maxAllowedPointSize font:[PEUIUtils boldFontForTextStyle:[PEUIUtils captionFontTextStyle]]]]
                                                         font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]]]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor rikerAppBlack]
                                          verticalTextPadding:1.5
                                                   fitToWidth:healthKitSwitchPanel.frame.size.width - (bodyWeightLabel.frame.origin.x + hkBodyWeightSwitch.frame.size.width + 15.0) - (iphoneXSafeInsetsSideVal * 2)];
  } else {
    bodyWeightDetailLabel = [PEUIUtils labelWithAttributeText:AS(@"No body weight logs synced to Apple Health yet.")
                                                         font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]]]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor rikerAppBlack]
                                          verticalTextPadding:1.5
                                                   fitToWidth:healthKitSwitchPanel.frame.size.width - (bodyWeightLabel.frame.origin.x + hkBodyWeightSwitch.frame.size.width + 15.0) - (iphoneXSafeInsetsSideVal * 2)];
  }
  [PEUIUtils placeView:bodyWeightDetailLabel below:bodyWeightLabel onto:healthKitSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  totalHeightHealthKitSwitchPanel += bodyWeightDetailLabel.frame.size.height + vpadding;
  totalHeightHealthKitSwitchPanel += vpadding; // bottom margin
  [PEUIUtils setFrameHeight:totalHeightHealthKitSwitchPanel ofView:healthKitSwitchPanel];
  [PEUIUtils styleViewForIpad:healthKitSwitchPanel];
  // place views
  CGFloat totalHeight = 0.0;
  vpadding = 0.0;
  UIView *healthKitPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [PEUIUtils placeView:healthKitSwitchPanel atTopOf:healthKitPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += healthKitSwitchPanel.frame.size.height + vpadding;
  vpadding = 4.0;
  [PEUIUtils placeView:healthKitDescription below:healthKitSwitchPanel onto:healthKitPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:healthKitPanel vpadding:4.0 hpadding:0.0];
  totalHeight += healthKitDescription.frame.size.height + vpadding;
  vpadding = 1.0;
  [PEUIUtils placeView:learnMoreButton below:healthKitDescription onto:healthKitPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += learnMoreButton.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:healthKitPanel];
  
  // event handling
  void (^hardReload)(void) = ^{
    UIView *healthKitPanel = [controller.view viewWithTag:tag];
    [healthKitPanel removeFromSuperview];
    [((PEBaseController *)controller) setNeedsRepaint:YES];
    [controller viewDidAppear:YES];
  };
  NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  void (^appendSuccessBmlsSync)(NSMutableAttributedString *, NSInteger) = ^(NSMutableAttributedString *msg, NSInteger numBmls) {
    [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"Your %%@ %@ been synced to Apple Health successfully.\n\nFuture body weight logs will be synced to Apple Health as you create them automatically.", numBmls > 1 ? @"have" : @"has"]
                                                         textToAccent:numBmls > 1 ? [NSString stringWithFormat:@"%@ body weight logs", [numberFormatter stringFromNumber:@(numBmls)]] : @"1 body weight log"
                                                       accentTextFont:nil]];
  };
  void (^appendSuccessSetsSync)(NSMutableAttributedString *, BOOL, NSInteger, NSInteger, BOOL) = ^(NSMutableAttributedString *msg, BOOL prependNewlines, NSInteger numSets, NSInteger numWorkoutsSaved, BOOL includeFutureMsg) {
    if (prependNewlines) {
      [msg appendAttributedString:AS(@"\n\n")];
    }
    [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"Your %%@ %@ been organized into ", numSets > 1 ? @"have" : @"has"]
                                                         textToAccent:numSets > 1 ? [NSString stringWithFormat:@"%@ sets", [numberFormatter stringFromNumber:@(numSets)]] : @"1 set"
                                                       accentTextFont:nil]];
    [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and synced to Apple Health successfully."
                                                         textToAccent:numWorkoutsSaved > 1 ? [NSString stringWithFormat:@"%@ workouts", [numberFormatter stringFromNumber:@(numWorkoutsSaved)]] : @"1 workout"
                                                       accentTextFont:nil]];
    if (includeFutureMsg) {
      [msg appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFuture sets can be grouped and synced as workouts to Apple Health using the %@ button."
                                                           textToAccent:[@"Sync Workouts" nonBreaking]
                                                         accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    }
  };
  NSAttributedString *(^makeSyncPromptDesc)(NSInteger, NSInteger) = ^NSAttributedString *(NSInteger numSetsToSync, NSInteger numBodyWeightLogsToSync) {
    NSMutableAttributedString *syncPromptDesc = [[NSMutableAttributedString alloc] init];
    [RUtils appendHkSyncPromptAlertDesc:syncPromptDesc numSetsToSync:numSetsToSync numBmlsToSync:numBodyWeightLogsToSync];
    return syncPromptDesc;
  };
  // executes on main thread
  void (^bmlsOnlyDoSync)(void) = ^{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    hud.tag = RHUD_TAG;
    hud.delegate = controller;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [RUtils saveHealthKitBmlsWithCompletion:^(NSInteger numBmls, BOOL bmlsSuccess, NSError *bmlsError) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          NSMutableAttributedString *successDesc = nil;
          NSMutableAttributedString *totalFailureDesc = nil;
          if (bmlsSuccess) { // only bmls synced; sets failed
            successDesc = [[NSMutableAttributedString alloc] init];
            appendSuccessBmlsSync(successDesc, numBmls);
            [PEUIUtils showSuccessAlertWithTitle:@"Success"
                                alertDescription:successDesc
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{ hardReload(); }
                                  relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          } else {
            totalFailureDesc = [[NSMutableAttributedString alloc] init];
            [RUtils appendHkFailMsgWithType:@"body weight log"
                                        msg:totalFailureDesc
                            prependNewlines:NO
                         includePrivacyInfo:YES
                                      error:bmlsError];
            [PEUIUtils showErrorAlertWithMsgs:nil
                                        title:@"Error saving to Apple Health"
                             alertDescription:totalFailureDesc
                          descLblHeightAdjust:0.0
                    additionalContentSections:nil
                                     topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                   [hkBodyWeightSwitch setOn:NO animated:YES];
                                   [RUtils setHkBodyWeightSaveDisabledAt:[NSDate date]];
                                   if (!hkWorkoutsSwitch.on) {
                                     [hkWorkoutsSwitch setUserInteractionEnabled:NO];
                                     [hkBodyWeightSwitch setUserInteractionEnabled:NO];
                                     [healthKitSwitch setOn:NO animated:YES];
                                     [syncWorkoutsButton setEnabled:YES];
                                     [hkWorkoutsSwitch setThumbTintColor:[UIColor silverColor]];
                                     [hkBodyWeightSwitch setThumbTintColor:[UIColor silverColor]];
                                   }
                                 }
                               relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          }
        });
      }
                                      noOpBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ [hud hideAnimated:YES]; }); }
                     raiseNotificationOnError:NO
                                     coordDao:_coordDao
                                  healthStore:[[HKHealthStore alloc] init]];
    });
  };
  void (^syncSets)(BOOL) = ^(BOOL includeFutureMsg) {
    [RUtils syncSetsToHealthkitWithSyncPromptDesc:[[NSMutableAttributedString alloc] init]
                                 includeFutureMsg:includeFutureMsg
                               noSetsToSyncAction:nil
                         displayNoSetsToSyncAlert:YES
                          successOkayButtonAction:^{ hardReload(); }
                            errorOkayButtonAction:^{
                              [hkWorkoutsSwitch setOn:NO animated:YES];
                              [syncWorkoutsButton setEnabled:NO];
                              [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                            }
                                     notNowAction:nil
                                       controller:controller
                                         coordDao:_coordDao
                                      healthStore:[[HKHealthStore alloc] init]
                                    uiInteraction:YES];
  };
  [[NSNotificationCenter defaultCenter] addObserverForName:RWorkoutsSavedToHealthKitNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                    hardReload();
                                                  });
                                                }];
  [[NSNotificationCenter defaultCenter] addObserverForName:RErrorSavingWorkoutsToHealthKitNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification * _Nonnull note) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                    [hkWorkoutsSwitch setOn:NO animated:YES];
                                                    [syncWorkoutsButton setEnabled:NO];
                                                    [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                                                  });
                                                }];
  [hkWorkoutsSwitch bk_addEventHandler:^(id sender) {
    if (hkWorkoutsSwitch.on) {
      [RUtils logEvent:@"reenable_healthkit_workouts"];
      [syncWorkoutsButton setEnabled:YES];
      [RUtils clearHkWorkoutDisabledAt];
      syncSets(YES);
    } else {
      [RUtils logEvent:@"disable_healthkit_workouts"];
      NSDate *now = [NSDate date];
      [syncWorkoutsButton setEnabled:NO];
      [RUtils setHkWorkoutSaveDisabledAt:now];
      if (!hkBodyWeightSwitch.on) {
        [hkWorkoutsSwitch setUserInteractionEnabled:NO];
        [hkBodyWeightSwitch setUserInteractionEnabled:NO];
        [healthKitSwitch setOn:NO animated:YES];
        [hkWorkoutsSwitch setThumbTintColor:[UIColor silverColor]];
        [hkBodyWeightSwitch setThumbTintColor:[UIColor silverColor]];
      }
    }
  } forControlEvents:UIControlEventTouchUpInside];
  [syncWorkoutsButton bk_addEventHandler:^(id sender) {
    syncSets(NO);
  } forControlEvents:UIControlEventTouchUpInside];
  [hkBodyWeightSwitch bk_addEventHandler:^(id sender) {
    if (hkBodyWeightSwitch.on) {
      [RUtils logEvent:@"reenable_healthkit_body_weight"];
      [RUtils clearHkBodyWeightDisabledAt];
      PELMUser *user = [_coordDao userWithError:errorBlk];
      NSDate *lastBodyWeightEndDate = [RUtils lastHkBodyWeightEndDate];
      NSInteger numBmlsToSync = 0;
      if (lastBodyWeightEndDate) {
        numBmlsToSync = [_coordDao numBmlsWithNonNilBodyWeightForUser:user loggedSince:lastBodyWeightEndDate error:errorBlk];
      } else {
        numBmlsToSync = [_coordDao numBmlsWithNonNilBodyWeightForUser:user error:errorBlk];
      }
      NSAttributedString *syncPromptDesc = makeSyncPromptDesc(0, numBmlsToSync);
      if (syncPromptDesc.length > 0) {
        [PEUIUtils showInfoAlertWithTitle:@"Sync to Apple Health"
                         alertDescription:syncPromptDesc
                      descLblHeightAdjust:0.0
                additionalContentSections:nil
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:^{ bmlsOnlyDoSync(); }
                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
      } else {
        [PEUIUtils showInfoAlertWithTitle:@"No Body Weight Logs to Sync"
                         alertDescription:AS(@"You don't currently have any body weight logs to sync to Apple Health.\n\nFuture body weight logs will be synced as you create them automatically.")
                      descLblHeightAdjust:0.0
                additionalContentSections:nil
                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                              buttonTitle:@"Okay."
                             buttonAction:nil
                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
      }
    } else {
      [RUtils logEvent:@"disable_healthkit_body_weight"];
      NSDate *now = [NSDate date];
      [RUtils setHkBodyWeightSaveDisabledAt:now];
      if (!hkWorkoutsSwitch.on) {
        [hkWorkoutsSwitch setUserInteractionEnabled:NO];
        [hkBodyWeightSwitch setUserInteractionEnabled:NO];
        [healthKitSwitch setOn:NO animated:YES];
        [hkWorkoutsSwitch setThumbTintColor:[UIColor silverColor]];
        [hkBodyWeightSwitch setThumbTintColor:[UIColor silverColor]];
        [syncWorkoutsButton setEnabled:YES];
      }
    }
  } forControlEvents:UIControlEventTouchUpInside];
  void (^turnOffAll)(void) = ^{
    NSDate *now = [NSDate date];
    [healthKitSwitch setOn:NO animated:YES];
    [hkWorkoutsSwitch setOn:NO animated:YES];
    [syncWorkoutsButton setEnabled:NO];
    [RUtils setHkWorkoutSaveDisabledAt:now];
    [hkWorkoutsSwitch setUserInteractionEnabled:NO];
    [hkWorkoutsSwitch setThumbTintColor:[UIColor silverColor]];
    [hkBodyWeightSwitch setOn:NO animated:YES];
    [RUtils setHkBodyWeightSaveDisabledAt:now];
    [hkBodyWeightSwitch setUserInteractionEnabled:NO];
    [hkBodyWeightSwitch setThumbTintColor:[UIColor silverColor]];
  };
  [healthKitSwitch bk_addEventHandler:^(id sender) {
    if (healthKitSwitch.on) {
      [syncWorkoutsButton setEnabled:YES];
      [hkWorkoutsSwitch setOn:YES animated:YES];
      [hkBodyWeightSwitch setOn:YES animated:YES];
      [hkWorkoutsSwitch setThumbTintColor:nil];
      [hkBodyWeightSwitch setThumbTintColor:nil];
      // executes in background thread
      void (^requestHkAuthorization)(PELMUser *, MBProgressHUD *) = ^(PELMUser *user, MBProgressHUD *hud) {
        NSDate *lastWorkoutEndDate = [RUtils lastHkWorkoutEndDate];
        NSDate *lastBodyWeightEndDate = [RUtils lastHkBodyWeightEndDate];
        // executes on the main thread
        void (^promptBothSync)(NSInteger, NSInteger) = ^(NSInteger numSetsToSync, NSInteger numBodyWeightLogsToSync) {
          BOOL asConfirmAlert = NO;
          NSAttributedString *syncPromptDesc = makeSyncPromptDesc(numSetsToSync, numBodyWeightLogsToSync);
          if (syncPromptDesc.length > 0) {
            if (numSetsToSync > 0) {
              asConfirmAlert = YES;
            }
            if (asConfirmAlert) { // has sets to sync to HK, so, offer as confirm to sync sets now; no matter what though, if there are bmls to sync, then sync them now.
              [PEUIUtils showConfirmAlertWithTitle:@"Sync now to Apple Health?"
                                        titleImage:[UIImage imageNamed:@"info"]
                                  alertDescription:syncPromptDesc
                               descLblHeightAdjust:0.0
                                          topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                   okayButtonTitle:@"Sync now to Apple Health"
                                  okayButtonAction:^{
                                    __block NSMutableAttributedString *successDesc = nil;
                                    __block NSMutableAttributedString *partialSuccessDesc = nil;
                                    __block NSMutableAttributedString *totalFailureDesc = nil;
                                    __block void (^successAlertDismissAction)(void) = nil;
                                    __block void (^partialFailureDismissAction)(void) = nil;
                                    __block void (^totalFailureDismissAction)(void) = nil;
                                    void (^displayResult)(void) = ^{
                                      if (successDesc) {
                                        [PEUIUtils showSuccessAlertWithTitle:@"Success"
                                                            alertDescription:successDesc
                                                         descLblHeightAdjust:0.0
                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                 buttonTitle:@"Okay."
                                                                buttonAction:successAlertDismissAction
                                                              relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                      } else if (partialSuccessDesc) {
                                        [PEUIUtils showWarningAlertWithMsgs:nil
                                                                      title:@"Almost Right"
                                                           alertDescription:partialSuccessDesc
                                                        descLblHeightAdjust:0.0
                                                                   topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                buttonTitle:@"Okay."
                                                               buttonAction:partialFailureDismissAction
                                                             relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                      } else { // total failure
                                        [PEUIUtils showErrorAlertWithMsgs:nil
                                                                    title:@"Error saving to Apple Health"
                                                         alertDescription:totalFailureDesc
                                                      descLblHeightAdjust:0.0
                                                additionalContentSections:nil
                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                              buttonTitle:@"Okay."
                                                             buttonAction:totalFailureDismissAction
                                                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                      }
                                    };
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
                                    hud.tag = RHUD_TAG;
                                    hud.delegate = controller;
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      [RUtils saveHealthKitWorkoutsWithCompletion:^(NSInteger numSets, NSInteger numWorkoutsSaved, BOOL setsSuccess, NSError *setsError) {
                                        if (numBodyWeightLogsToSync > 0) {
                                            [RUtils saveHealthKitBmlsWithCompletion:^(NSInteger numBmls, BOOL bmlsSuccess, NSError *bmlsError) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                [hud hideAnimated:YES];
                                                if (setsSuccess) {
                                                  if (bmlsSuccess) { // both all synced; no failures
                                                    successDesc = [[NSMutableAttributedString alloc] init];
                                                    appendSuccessBmlsSync(successDesc, numBmls);
                                                    appendSuccessSetsSync(successDesc, YES, numSets, numWorkoutsSaved, YES);
                                                    successAlertDismissAction = ^{ hardReload(); };
                                                  } else { // only sets synced; bmls failed
                                                    partialSuccessDesc = [[NSMutableAttributedString alloc] init];
                                                    appendSuccessSetsSync(partialSuccessDesc, NO, numSets, numWorkoutsSaved, YES);
                                                    [RUtils appendHkFailMsgWithType:@"body weight log"
                                                                                msg:partialSuccessDesc
                                                                    prependNewlines:YES
                                                                 includePrivacyInfo:YES
                                                                              error:bmlsError];
                                                    partialFailureDismissAction = ^{
                                                      [hkBodyWeightSwitch setOn:NO animated:YES];
                                                      [RUtils setHkBodyWeightSaveDisabledAt:[NSDate date]];
                                                      // slight delay so user can perceive switches updating
                                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                        hardReload();
                                                      });
                                                    };
                                                  }
                                                } else if (bmlsSuccess) { // only bmls synced; sets failed
                                                  partialSuccessDesc = [[NSMutableAttributedString alloc] init];
                                                  appendSuccessBmlsSync(partialSuccessDesc, numBmls);
                                                  [RUtils appendHkFailMsgWithType:@"workout"
                                                                              msg:partialSuccessDesc
                                                                  prependNewlines:YES
                                                               includePrivacyInfo:YES
                                                                            error:setsError];
                                                  partialFailureDismissAction = ^{
                                                    [hkWorkoutsSwitch setOn:NO animated:YES];
                                                    [syncWorkoutsButton setEnabled:YES];
                                                    [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                                                    // slight delay so user can perceive switch turning off
                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                      hardReload();
                                                    });
                                                  };
                                                } else { // none synced; both failed
                                                  totalFailureDesc = [[NSMutableAttributedString alloc] init];
                                                  [RUtils appendHkFailMsgWithType:@"workout" msg:totalFailureDesc prependNewlines:NO includePrivacyInfo:YES error:setsError];
                                                  [RUtils appendHkFailMsgWithType:@"body weight log" msg:totalFailureDesc prependNewlines:YES includePrivacyInfo:NO error:bmlsError];
                                                  totalFailureDismissAction = ^{ turnOffAll(); };
                                                }
                                                displayResult();
                                              });
                                            }
                                                                            noOpBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ [hud hideAnimated:YES]; }); }
                                                           raiseNotificationOnError:NO
                                                                           coordDao:_coordDao
                                                                        healthStore:[[HKHealthStore alloc] init]];
                                        } else {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [hud hideAnimated:YES];
                                            if (setsSuccess) { // only sets to sync; no failures
                                              successDesc = [[NSMutableAttributedString alloc] init];
                                              appendSuccessSetsSync(successDesc, NO, numSets, numWorkoutsSaved, YES);
                                              successAlertDismissAction = ^{ hardReload(); };
                                            } else { // sets failed to sync
                                              totalFailureDesc = [[NSMutableAttributedString alloc] init];
                                              [RUtils appendHkFailMsgWithType:@"workout" msg:totalFailureDesc prependNewlines:NO includePrivacyInfo:YES error:setsError];
                                              totalFailureDismissAction = ^{
                                                [syncWorkoutsButton setEnabled:NO];
                                                [hkWorkoutsSwitch setOn:NO animated:YES];
                                                [RUtils setHkWorkoutSaveDisabledAt:[NSDate date]];
                                              };
                                            }
                                            displayResult();
                                          });
                                        }
                                      }
                                                     forceSyncAllComputedWorkouts:YES
                                                         raiseNotificationOnError:NO
                                                                         coordDao:_coordDao
                                                                      healthStore:[[HKHealthStore alloc] init]];
                                      
                                    });
                                  }
                                   okayButtonStyle:JGActionSheetButtonStyleBlue
                                 cancelButtonTitle:numBodyWeightLogsToSync > 0 ? [NSString stringWithFormat:@"Just sync my body weight log%@.", numBodyWeightLogsToSync > 1 ? @"s" : @""] : @"Not now."
                                cancelButtonAction:^{
                                  if (numBodyWeightLogsToSync) {
                                    bmlsOnlyDoSync();
                                  }
                                }
                                  cancelButtonSyle:JGActionSheetButtonStyleCancel
                        secondaryCancelButtonTitle:@"Don't sync these sets.  Skip them."
                       secondaryCancelButtonAction:^{
                         NSArray *sets = [_coordDao descendingSetsForUser:user pageSize:1 error:errorBlk];
                         RSet *latestSet = [sets firstObject];
                         if (latestSet) {
                           [RUtils setLastHkWorkoutEndDate:latestSet.loggedAt];
                           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             hardReload();
                           });
                         }
                       }
                         secondaryCancelButtonSyle:JGActionSheetButtonStyleCancel
                                    relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
            } else { // only bmls to sync to HK, so, don't offer as confirm, just offer as info alert and just do it.
              [PEUIUtils showInfoAlertWithTitle:@"Sync to Apple Health"
                               alertDescription:syncPromptDesc
                            descLblHeightAdjust:0.0
                      additionalContentSections:nil
                                       topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                    buttonTitle:@"Okay."
                                   buttonAction:^{ bmlsOnlyDoSync(); }
                                 relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
            }
          } else { // nothing to sync
            NSMutableAttributedString *alertDesc = [[NSMutableAttributedString alloc] init];
            [alertDesc appendAttributedString:AS(@"You don't have any new workouts or body weight logs to sync to Apple Health.\n\nFuture body weight logs will be synced as you create them automatically.")];
            [alertDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nFuture sets can be grouped and synced as workouts to Apple Health using the %@ button."
                                                                 textToAccent:[@"Sync Workouts" nonBreaking]
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
            [PEUIUtils showInfoAlertWithTitle:@"Nothing to Sync"
                             alertDescription:alertDesc
                          descLblHeightAdjust:0.0
                    additionalContentSections:nil
                                     topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                  buttonTitle:@"Okay."
                                 buttonAction:nil
                               relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          }
        };
        HKHealthStore *store = [[HKHealthStore alloc] init];
        [store requestAuthorizationToShareTypes:[NSSet setWithObjects:[HKObjectType workoutType],
                                                 [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                                                 nil]
                                      readTypes:nil
                                     completion:^(BOOL success, NSError * _Nullable error) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         DDLogDebug(@"HealthKit authorization request, success: [%@], error: [%@]", [PEUtils yesNoFromBool:success], error);
                                         if (success) {
                                           [healthKitSwitch setOn:YES];
                                           [RUtils setHealthKitEnabledAt:[NSDate date]];
                                           [RUtils clearHkWorkoutDisabledAt];
                                           [hkWorkoutsSwitch setUserInteractionEnabled:YES];
                                           [RUtils clearHkBodyWeightDisabledAt];
                                           [hkBodyWeightSwitch setUserInteractionEnabled:YES];
                                           [syncWorkoutsButton setEnabled:YES];
                                           NSInteger numSetsToSync = 0;
                                           if (lastWorkoutEndDate) {
                                             numSetsToSync = [_coordDao numSetsForUser:user loggedSince:lastWorkoutEndDate error:errorBlk];
                                           } else {
                                             numSetsToSync = [_coordDao numSetsForUser:user error:errorBlk];
                                           }
                                           NSInteger numBmlsToSync = 0;
                                           if (lastBodyWeightEndDate) {
                                             numBmlsToSync = [_coordDao numBmlsWithNonNilBodyWeightForUser:user loggedSince:lastBodyWeightEndDate error:errorBlk];
                                           } else {
                                             numBmlsToSync = [_coordDao numBmlsWithNonNilBodyWeightForUser:user error:errorBlk];
                                           }
                                           [hud hideAnimated:YES];
                                           promptBothSync(numSetsToSync, numBmlsToSync);
                                         } else {
                                           [hud hideAnimated:YES];
                                           turnOffAll();
                                         }
                                       });
                                     }];
      };
      
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
      hud.tag = RHUD_TAG;
      hud.delegate = controller;
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [RUtils logEvent:@"enable_healthkit"];
        PELMUser *user = [_coordDao userWithError:errorBlk];
        RBodyMeasurementLog *bml = [_coordDao mostRecentBmlWithNonNilWeightForUser:user error:errorBlk];
        if (bml) {
          requestHkAuthorization(user, hud);
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [PEUIUtils showWarningAlertWithMsgs:nil
                                          title:@"No Body Weight Logs"
                               alertDescription:AS(@"In order to calculate the calories burned in your workouts, we need to know your body weight.")
                            descLblHeightAdjust:0.0
                                       topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                    buttonTitle:@"Not right now."
                                   buttonAction:^{
                                     MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
                                     hud.tag = RHUD_TAG;
                                     hud.delegate = controller;
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       requestHkAuthorization(user, hud);
                                     });
                                   }
                                addlButtonTitle:@"Create Body Weight Log"
                               addlButtonAction:^{
                                 UIViewController *enterBodyWeightScreen =
                                 [_screenToolkit newBodyWeightInputScreenMakerWithDismissedBlk:^{
                                   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
                                   hud.tag = RHUD_TAG;
                                   hud.delegate = controller;
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                     requestHkAuthorization(user, hud);
                                   });
                                 }]();
                                 [controller presentViewController:[PEUIUtils navigationControllerWithController:enterBodyWeightScreen
                                                                                             navigationBarHidden:NO]
                                                          animated:YES
                                                        completion:nil];
                               }
                                addlButtonStyle:JGActionSheetButtonStyleBlue
                                 relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          });
        }
      });
    } else {
      [RUtils logEvent:@"disable_healthkit"];
      [RUtils disableHealthKit];
      turnOffAll();
    }
  } forControlEvents:UIControlEventTouchUpInside];
  // finally, return panel
  return healthKitPanel;
}

- (UIView *)offlineModeSwitchPanelRelativeToView:(UIView *)relativeToView
                                     displayIcon:(BOOL)displayIcon {
  return [self offlineModeSwitchPanelWithText:@"Offline Mode"
                                         font:[_uitoolkit fontForButtonsBlk]()
                                  displayIcon:displayIcon
                               relativeToView:relativeToView];
}

- (UIView *)offlineModeSwitchPanelWithText:(NSString *)text
                                      font:(UIFont *)font
                               displayIcon:(BOOL)displayIcon
                            relativeToView:(UIView *)relativeToView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UISwitch *offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [offlineModeSwitch setOn:[APP offlineMode]];
  [offlineModeSwitch bk_addEventHandler:^(id sender) {
    [APP setOfflineMode:offlineModeSwitch.on];
    if (offlineModeSwitch.on) {
      [[NSNotificationCenter defaultCenter] postNotificationName:ROfflineModeToggledOnNotification object:self];
      [RUtils logEvent:@"enable_offline_mode"];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:ROfflineModeToggledOffNotification object:self];
      [RUtils logEvent:@"disable_offline_mode"];
    }
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *offlineModeLabel = [PEUIUtils labelWithKey:text
                                                 font:font
                                      backgroundColor:[UIColor clearColor]
                                            textColor:[UIColor blackColor]
                                  verticalTextPadding:3.0];
  UIView *offlineModeSwitchPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:(offlineModeLabel.frame.size.height + [_uitoolkit verticalPaddingForButtons])];
  [offlineModeSwitchPanel setBackgroundColor:[UIColor whiteColor]];
  if (displayIcon) {
    UIImageView *offlineModeIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"offline-med-small"]];
    [PEUIUtils placeView:offlineModeIcon inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0 + iphoneXSafeInsetsSideVal];
    [PEUIUtils placeView:offlineModeLabel toTheRightOf:offlineModeIcon onto:offlineModeSwitchPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  } else {
    [PEUIUtils placeView:offlineModeLabel inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0 + iphoneXSafeInsetsSideVal];
  }
  [PEUIUtils placeView:offlineModeSwitch inMiddleOf:offlineModeSwitchPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils styleViewForIpad:offlineModeSwitchPanel];
  return offlineModeSwitchPanel;
}

#pragma mark - Alert Helpers

- (UIView *)alertSectionContentViewRelativeToView:(UIView *)relativeToView {
  return [PEUIUtils panelWithFixedWidth:0.905 * [PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]
                            fixedHeight:0.0];
}

- (JGActionSheetSection *)goOfflineAlertSectionRelativeToView:(UIView *)relativeToView {
  if ([APP offlineMode]) { // already in offline mode!
    return nil;
  }
  UIView *contentView = [self alertSectionContentViewRelativeToView:relativeToView];
  UIView *topPanel;
  CGFloat topViewHeight;
  UIFont* boldBodyFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                   iphone6Width:UIFontTextStyleBody
                                                                               iphone6PlusWidth:UIFontTextStyleBody
                                                                                           ipad:UIFontTextStyleTitle3]];
  UILabel *(^makeTitleLabel)(CGFloat) = ^ UILabel * (CGFloat widthToFit) {
    return [PEUIUtils labelWithKey:@"Use offline mode?"
                              font:boldBodyFont
                   backgroundColor:[UIColor clearColor]
                         textColor:[UIColor blackColor]
               verticalTextPadding:0.0
                        fitToWidth:widthToFit];
  };
  UIImage *titleImage = [UIImage imageNamed:[PEUIUtils objIfiPhone5Width:@"offline-med-small"
                                                            iphone6Width:@"offline-med-small"
                                                        iphone6PlusWidth:@"offline-med-small"
                                                                    ipad:@"offline"]];
  CGFloat leftPaddingForTitleImg = 2.0;
  CGFloat paddingBetweenTitleImgAndLabel = 8.0;
  UIImageView *titleImageView = [[UIImageView alloc] initWithImage:titleImage];
  UILabel *titleLbl = makeTitleLabel(contentView.frame.size.width - titleImageView.frame.size.width - leftPaddingForTitleImg - paddingBetweenTitleImgAndLabel);
  topViewHeight = (titleImageView.frame.size.height > titleLbl.frame.size.height
                   ? titleImageView.frame.size.height : titleLbl.frame.size.height);
  topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
  [PEUIUtils placeView:titleImageView
            inMiddleOf:topPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:leftPaddingForTitleImg];
  [PEUIUtils placeView:titleLbl
          toTheRightOf:titleImageView
                  onto:topPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:paddingBetweenTitleImgAndLabel];
  UIFont* boldSubheadlineFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UILabel *descriptionLbl = [PEUIUtils labelWithAttributeText:[[NSAttributedString alloc] initWithString:@"Don't get bogged down by a poor internet connection or outage!  Go offline to prevent syncing for an ultra fast experience."]
                                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                     fontForHeightCalculation:boldSubheadlineFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0
                                                   fitToWidth:contentView.frame.size.width - 5.0];
  UIButton *learnMoreBtn = [PEUIUtils buttonWithKey:@"Learn more..."
                                               font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor bootstrapPrimary]
                       disabledStateBackgroundColor:[UIColor clearColor]
                             disabledStateTextColor:[UIColor clearColor]
                                    verticalPadding:3.0
                                  horizontalPadding:0.0
                                       cornerRadius:0.0
                                             target:nil
                                             action:nil];
  [learnMoreBtn bk_addEventHandler:^(id sender) {
    NSMutableAttributedString *offlineDesc = [[NSMutableAttributedString alloc] initWithString:@"\
Offline mode prevents syncing for an ultra fast experience.  As you create new sets and body logs, they are saved locally to your device instantaneously.  They are not yet synced to your account.\n\n"];
    [offlineDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Later, at your convenience you can bulk-sync your edits to your account from the %@ screen."
                                                                 textToAccent:@"Records"
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [PEUIUtils showInfoAlertWithTitle:@"Offline Mode"
                     alertDescription:offlineDesc
                  descLblHeightAdjust:0.0
            additionalContentSections:nil
                             topInset:0.0
                          buttonTitle:@"Okay."
                         buttonAction:^{}
                       relativeToView:relativeToView];
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *switchView = [self offlineModeSwitchPanelWithText:@"offline Mode"
                                                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                displayIcon:NO
                                             relativeToView:contentView];
  [switchView setBackgroundColor:[UIColor cloudsColor]];
  CGFloat topPanelVpadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:3.0 iphone6PlusWidth:4.0 ipad:8.0];
  CGFloat panelsVpadding = 0.0;
  CGFloat contentViewHeight = topViewHeight +
  switchView.frame.size.height +
  descriptionLbl.frame.size.height +
  learnMoreBtn.frame.size.height;
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:6.0 iphone6PlusWidth:8.0 ipad:12.0];
  CGFloat descriptionVpadding = 13.0;
  contentViewHeight += topPanelVpadding + descriptionVpadding + (vpadding * 2) + panelsVpadding;
  // now add a little bit more height so there's some nice bottom-padding; we'll have more
  // padding for when we have no messages panel-column.
  contentViewHeight += 10.0;
  CGFloat hpadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:3.0 iphone6PlusWidth:3.5 ipad:6.0];
  [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
  [PEUIUtils placeView:topPanel
               atTopOf:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:topPanelVpadding
              hpadding:hpadding];
  [PEUIUtils placeView:descriptionLbl
                 below:topPanel
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentView
              vpadding:descriptionVpadding
              hpadding:hpadding];
  [PEUIUtils placeView:learnMoreBtn
                 below:descriptionLbl
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentView
              vpadding:vpadding
              hpadding:hpadding];
  [PEUIUtils placeView:switchView
                 below:learnMoreBtn
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentView
              vpadding:vpadding
              hpadding:hpadding];
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:contentView];
}

+ (JGActionSheetSection *)watchReminderAlertSectionRelativeToView:(UIView *)relativeToView {
  JGActionSheetSection *watchInfoSection = nil;
  if ([WCSession isSupported]) {
    watchInfoSection = [PEUIUtils infoAlertSectionWithTitle:@"Riker on Apple Watch"
                                           alertDescription:AS(@"If you're using the Riker Apple Watch app, you may need to re-load the movements and settings from the watch app Settings screen.")
                                        descLblHeightAdjust:0.0
                                             relativeToView:relativeToView];
  }
  return watchInfoSection;
}

#pragma mark - User Account Panel

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMakerWithAccountStatusLabelTag:(NSInteger)accountStatusLabelTag
                                                       becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction
                                                                  fontTextStyle:(UIFontTextStyle)fontTextStyle {
  return ^ UIView * (PEAddViewEditController *parentViewController, id nilParent, PELMUser *user) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] andHeightOf:1.0 relativeToView:parentView];
    NSString *passwordStr = user.hasPassword ? @"*****************" : @"";
    UIView *userAccountDataPanel = [self tablePanelWithRowData:@[@[@"Email", [PEUtils emptyIfNil:[user email]]],
                                                                 @[@"Password", passwordStr]]
                                                     uitoolkit:_uitoolkit
                                                 fontTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                                    parentView:contentPanel];
    UIView *accountStatusPanel = [self emailStatusPanelForUser:user
                                                      panelTag:@(accountStatusLabelTag)
                                          includeRefreshButton:NO
                                                relativeToView:contentPanel
                                                 fontTextStyle:fontTextStyle
                                                    controller:parentViewController
                                      becameUnauthButtonAction:becameUnauthButtonAction];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:userAccountDataPanel
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:25
                hpadding:0];
    totalHeight += userAccountDataPanel.frame.size.height + 25;
    [PEUIUtils placeView:accountStatusPanel
                   below:userAccountDataPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    totalHeight += accountStatusPanel.frame.size.height + 15.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEEntityPanelMakerBlk)userAccountFormPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                           andHeightOf:1.0
                                        relativeToView:parentView];
    UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
    CGFloat desiredCommonHeight = [PEUIUtils heightForUserAccountTextfields];
    UITextField *emailTf = tfMaker(@"E-mail", PELMUserTagEmail);
    [emailTf setFont:font];
    [emailTf setKeyboardType:UIKeyboardTypeEmailAddress];
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:emailTf];
    UITextField *passwordTf = tfMaker(@"Password", PELMUserTagPassword);
    [passwordTf setFont:font];
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:passwordTf];
    [passwordTf setSecureTextEntry:YES];
    UITextField *confirmPasswordTf = tfMaker(@"Confirm password", PELMUserTagConfirmPassword);
    [confirmPasswordTf setSecureTextEntry:YES];
    [confirmPasswordTf setFont:font];
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:confirmPasswordTf];
    UILabel *passwordMsg = [PEUIUtils labelWithKey:@"If you don't want to change your password, leave the password field blank."
                                              font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[UIColor darkGrayColor]
                               verticalTextPadding:3.0
                                        fitToWidth:contentPanel.frame.size.width - 23.0];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:emailTf
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:25
                hpadding:0];
    totalHeight += emailTf.frame.size.height + 25;
    [PEUIUtils placeView:passwordTf
                   below:emailTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += passwordTf.frame.size.height + 5.0;
    [PEUIUtils placeView:confirmPasswordTf
                   below:passwordTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    totalHeight += confirmPasswordTf.frame.size.height + 5.0;
    [PEUIUtils placeView:passwordMsg
                   below:confirmPasswordTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:8.0];
    totalHeight += passwordMsg.frame.size.height + 4.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)userFormPanelToUserBinder {
  return ^ void (UIView *panel, PELMUser *userAccount) {
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setEmail:)
       fromTextfieldWithTag:PELMUserTagEmail
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setPassword:)
       fromTextfieldWithTag:PELMUserTagPassword
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setConfirmPassword:)
       fromTextfieldWithTag:PELMUserTagConfirmPassword
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)userToUserPanelBinder {
  return ^ void (PELMUser *userAccount, UIView *panel) {
    /*[PEUIUtils bindToTextControlWithTag:PELMUserTagName
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(name)];*/
    [PEUIUtils bindToTextControlWithTag:PELMUserTagEmail
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(email)];
    [PEUIUtils bindToTextControlWithTag:PELMUserTagPassword
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(password)];
    [PEUIUtils bindToTextControlWithTag:PELMUserTagConfirmPassword
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(confirmPassword)];
  };
}

- (PEEnableDisablePanelBlk)userFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    /*[PEUIUtils enableControlWithTag:PELMUserTagName
                           fromView:panel
                             enable:enable];*/
    [PEUIUtils enableControlWithTag:PELMUserTagEmail
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:PELMUserTagPassword
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:PELMUserTagConfirmPassword
                           fromView:panel
                             enable:enable];
  };
}

+ (NSArray *)emailStatusTextForUser:(PELMUser *)user {
  if (![PEUtils isNil:[user verifiedAt]]) {
    //return @[@"verified", [UIColor greenSeaColor]];
    return @[@"yes", [UIColor greenSeaColor]];
  } else {
    //return @[@"not verified", [UIColor sunflowerColor]];
    return @[@"no", [UIColor sunflowerColor]];
  }
}

- (void)invokeSendVerificationEmailWithController:(UIViewController *)controller
                         becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction {
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:controller];
  if ([APP doesUserHaveValidAuthToken]) {
    MBProgressHUD *sendVerificationEmailHud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    sendVerificationEmailHud.tag = RHUD_TAG;
    enableUserInteraction(NO);
    sendVerificationEmailHud.label.text = @"Sending verification email...";
    [_coordDao.userCoordinatorDao resendVerificationEmailForUser:user
                                             remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                               [RUtils logEvent:@"busy_wh_resending_veri_email"];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [sendVerificationEmailHud hideAnimated:YES afterDelay:0.0];
                                                 [PEUIUtils showWaitAlertWithMsgs:nil
                                                                            title:@"Busy with maintenance."
                                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try re-sending the verification email later."]
                                                              descLblHeightAdjust:0.0
                                                        additionalContentSections:nil
                                                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                      buttonTitle:@"Okay."
                                                                     buttonAction:^{ enableUserInteraction(YES); }
                                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                               });
                                             }
                                                     successBlk:^{
                                                       [RUtils logEvent:@"success_resending_veri_email"];
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                         [sendVerificationEmailHud hideAnimated:YES afterDelay:0.0];
                                                         NSAttributedString *attrMessage =
                                                         [PEUIUtils attributedTextWithTemplate:@"The verification email was sent to you at: %@."
                                                                                  textToAccent:[user email]
                                                                                accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                         [PEUIUtils showSuccessAlertWithTitle:@"Verification e-mail sent."
                                                                             alertDescription:attrMessage
                                                                          descLblHeightAdjust:0.0
                                                                                     topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                                  buttonTitle:@"Okay."
                                                                                 buttonAction:^{ enableUserInteraction(YES); }
                                                                               relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                       });
                                                     }
                                            addlAuthRequiredBlk:^{
                                              [RUtils logEvent:@"auth_reqd_wh_resending_veri_email"];
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                [sendVerificationEmailHud hideAnimated:YES afterDelay:0.0];
                                                [PEUIUtils showErrorAlertWithMsgs:@[@"Authentication required."]
                                                                            title:@"Something went wrong."
                                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"Oops.  There was a problem attempting to send you a verification email."]
                                                              descLblHeightAdjust:0.0                                                 
                                                        additionalContentSections:@[[PEUIUtils becameUnauthenticatedSectionRelativeToView:controller.view]]
                                                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                      buttonTitle:@"Okay."
                                                                     buttonAction:^{
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                                           object:nil
                                                                                                                         userInfo:nil];
                                                                       enableUserInteraction(YES);
                                                                       if ([controller isKindOfClass:[PEBaseController class]]) {
                                                                         ((PEBaseController *)controller).needsRepaint = YES;
                                                                       }
                                                                       [controller viewDidAppear:YES];
                                                                       if (becameUnauthButtonAction) {
                                                                         becameUnauthButtonAction(controller);
                                                                       }
                                                                     }
                                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                              });
                                            }
                                                       errorBlk:^{
                                                         [RUtils logEvent:@"error_wh_resending_veri_email"];
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                           [sendVerificationEmailHud hideAnimated:YES afterDelay:0.0];
                                                           [PEUIUtils showErrorAlertWithMsgs:nil
                                                                                       title:@"Something went wrong."
                                                                            alertDescription:[[NSAttributedString alloc] initWithString:@"Oops.  Something went wrong in attempting to send you a verification email.  Please try this again a little later."]
                                                                         descLblHeightAdjust:0.0
                                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                                 buttonTitle:@"Okay."
                                                                                buttonAction:^{ enableUserInteraction(YES); }
                                                                              relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                                         });
                                                       }];
  } else {
    UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    NSAttributedString *attrBecameUnauthMessage =
    [PEUIUtils attributedTextWithTemplate:@"You are not currently authenticated.\n\nTo re-authenticate, go to:\n\n%@."
                             textToAccent:@"Account \u2794 Re-authenticate"
                           accentTextFont:boldDescFont];
    [PEUIUtils showWarningAlertWithMsgs:nil
                                  title:@"Not Authenticated."
                       alertDescription:attrBecameUnauthMessage
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                            buttonTitle:@"Okay."
                           buttonAction:^{
                             [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                 object:nil
                                                                               userInfo:nil];
                             enableUserInteraction(YES);
                             [APP refreshTabs];
                             [controller viewDidAppear:YES];
                             if (becameUnauthButtonAction) {
                               becameUnauthButtonAction(controller);
                             }
                           }
                         relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  }
}

- (UIView *)emailStatusPanelForUser:(PELMUser *)user
                           panelTag:(NSNumber *)panelTag
               includeRefreshButton:(BOOL)includeRefreshButton
                     relativeToView:(UIView *)relativeToView
                      fontTextStyle:(UIFontTextStyle)fontTextStyle
                         controller:(UIViewController *)controller
           becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  REnableUserInteractionBlk enableUserInteraction = [RUIUtils makeUserEnabledBlockForController:controller];
  NSArray *accountStatusText = [RPanelToolkit emailStatusTextForUser:user];
  UIView *statusPanel = [PEUIUtils labelValuePanelWithCellHeight:([PEUIUtils sizeOfText:@"Wy" withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3]].height + _uitoolkit.verticalPaddingForButtons + 5.0)
                                                     labelString:@"Email Verified?"
                                                  labelTextStyle:fontTextStyle
                                                  labelTextColor:[UIColor blackColor]
                                               labelLeftHPadding:[PEUIUtils valueIfiPhone5Width:15
                                                                                   iphone6Width:16
                                                                               iphone6PlusWidth:20
                                                                                           ipad:20] + iphoneXSafeInsetsSideVal
                                                     valueString:accountStatusText[0]
                                                  valueTextStyle:fontTextStyle
                                                  valueTextColor:accountStatusText[1]
                                              valueRightHPadding:[PEUIUtils valueIfiPhone5Width:18
                                                                                   iphone6Width:18
                                                                               iphone6PlusWidth:20
                                                                                           ipad:22] + iphoneXSafeInsetsSideVal
                                                   valueLabelTag:nil
                                  minPaddingBetweenLabelAndValue:10.0
                                                        rowWidth:(1.0 * relativeToView.frame.size.width)];
  [statusPanel setBackgroundColor:[UIColor whiteColor]];
  [PEUIUtils styleViewForIpad:statusPanel];
  CGFloat heightOfPanel = statusPanel.frame.size.height;
  UIView *panel;
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:36.0];
  if ([PEUtils isNil:[user verifiedAt]]) {
    UIButton * (^makeSendEmailBtn)(void) = ^ UIButton * {
      UIButton *sendEmailBtn = [PEUIUtils buttonWithKey:@"re-send verification email"
                                                   font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                          font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                        backgroundColor:[UIColor rikerAppBlackSemiClear]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:14.0
                                      horizontalPadding:20.0
                                           cornerRadius:5.0
                                                 target:nil
                                                 action:nil];
      [sendEmailBtn bk_addEventHandler:^(id sender) {
        [RUtils logEvent:@"resend_veri_email_account"];
        [self invokeSendVerificationEmailWithController:controller
                               becameUnauthButtonAction:becameUnauthButtonAction];
      } forControlEvents:UIControlEventTouchUpInside];
      return sendEmailBtn;
    };
    panel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:80];
    [panel setBackgroundColor:[UIColor clearColor]];
    UIView *buttonsView = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:30];
    [buttonsView setBackgroundColor:[UIColor clearColor]];
    if (includeRefreshButton) {
      UIButton *refreshBtn = [PEUIUtils buttonWithKey:@"refresh"
                                                 font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                        font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                      backgroundColor:[UIColor rikerAppBlackSemiClear]
                                            textColor:[UIColor whiteColor]
                         disabledStateBackgroundColor:nil
                               disabledStateTextColor:nil
                                      verticalPadding:14.0
                                    horizontalPadding:20.0
                                         cornerRadius:5.0
                                               target:nil
                                               action:nil];
      [refreshBtn bk_addEventHandler:^(id sender) {
        __block BOOL receivedAuthReqdErrorOnDownloadAttempt = NO;
        NSMutableArray *successMsgsForRefresh = [NSMutableArray array];
        NSMutableArray *errsForRefresh = [NSMutableArray array];
        // The meaning of the elements of the arrays found within errsForRefresh:
        //
        // errsForRefresh[*][0]: Error title (string)
        // errsForRefresh[*][1]: Is error user-fixable (bool)
        // errsForRefresh[*][2]: An NSArray of sub-error messages (strings)
        // errsForRefresh[*][3]: Is error type server-busy? (bool)
        // errsForRefresh[*][4]: Is entity not found (bool)
        //
        MBProgressHUD *refreshHud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
        refreshHud.tag = RHUD_TAG;
        enableUserInteraction(NO);
        refreshHud.label.text = [NSString stringWithFormat:@"Refreshing account status..."];
        void(^refreshDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([errsForRefresh count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              [refreshHud hideAnimated:YES afterDelay:0.0];
              id downloadedUser = successMsgsForRefresh[0][1];
              void (^stillNotVerifiedAlert)(void) = ^{
                [PEUIUtils showInfoAlertWithTitle:@"Still not verified."
                                 alertDescription:[PEUIUtils attributedTextWithTemplate:@"Your account is still not verified.  Use the %@ button to have a new account verification link emailed to you."
                                                                           textToAccent:@"re-send verification email"
                                                                         accentTextFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                              descLblHeightAdjust:0.0
                        additionalContentSections:nil
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
              };
              if ([downloadedUser isEqual:[NSNull null]]) { // user account not modified
                stillNotVerifiedAlert();
              } else { // user account modified
                [user setUpdatedAt:[downloadedUser updatedAt]];
                [user overwriteDomainProperties:downloadedUser];
                [_coordDao saveMasterUser:user error:[RUtils localSaveErrorHandlerMaker]()];
                if ([PEUtils isNil:[user verifiedAt]]) {  // user account modified, but still not verified
                  stillNotVerifiedAlert();
                } else {  // user account verified
                  [PEUIUtils showSuccessAlertWithTitle:@"Account verified."
                                      alertDescription:[[NSAttributedString alloc] initWithString:@"Thank you.  Your account is now verified."]
                                   descLblHeightAdjust:0.0
                                              topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                           buttonTitle:@"Okay."
                                          buttonAction:^{
                                            enableUserInteraction(YES);
                                            [self refreshEmailStatusPanelForUser:user
                                                                        panelTag:panelTag
                                                            includeRefreshButton:includeRefreshButton
                                                                  relativeToView:relativeToView
                                                                   fontTextStyle:fontTextStyle
                                                                      controller:controller
                                                        becameUnauthButtonAction:becameUnauthButtonAction];
                                          }
                                        relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                }
              }
            });
          } else { // error(s)
            dispatch_async(dispatch_get_main_queue(), ^{
              [refreshHud hideAnimated:YES afterDelay:0.0];
              if ([errsForRefresh[0][3] boolValue]) { // server busy
                [PEUIUtils showWaitAlertWithMsgs:nil
                                           title:@"Busy with maintenance."
                                alertDescription:[[NSAttributedString alloc] initWithString:@"The server is currently busy at the moment \
undergoing maintenance.\n\nWe apologize for the inconvenience.  Please try refreshing later."]
                             descLblHeightAdjust:0.0
                       additionalContentSections:nil
                                        topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{ enableUserInteraction(YES); }
                                  relativeToView:controller.tabBarController.view];
              } else if ([errsForRefresh[0][4] boolValue]) { // not found
                NSString *fetchErrMsg = @"Oops.  Something appears to be wrong with your account.  Try logging off and logging back in.";
                [PEUIUtils showErrorAlertWithMsgs:nil
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                              descLblHeightAdjust:0.0
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{ enableUserInteraction(YES); }
                                   relativeToView:controller.tabBarController.view];
                
              } else { // any other error type
                JGActionSheetSection *addlSection = nil;
                NSString *fetchErrMsg;
                if (receivedAuthReqdErrorOnDownloadAttempt) {
                  fetchErrMsg = @"Oops.  There was a problem attempting to refresh.";
                  addlSection = [PEUIUtils becameUnauthenticatedSectionRelativeToView:controller.view];
                } else {
                  fetchErrMsg = @"Oops.  There was a problem attempting to refresh.  Try it again a little later.";
                }
                [PEUIUtils showErrorAlertWithMsgs:errsForRefresh[0][2]
                                            title:@"Something went wrong."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                              descLblHeightAdjust:0.0
                        additionalContentSections:addlSection != nil ? @[addlSection] : nil
                                         topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                           object:nil
                                                                                         userInfo:nil];
                                       enableUserInteraction(YES);
                                       if (receivedAuthReqdErrorOnDownloadAttempt) {
                                         [controller viewDidAppear:YES];
                                         if (becameUnauthButtonAction) {
                                           becameUnauthButtonAction(controller);
                                         }
                                       }
                                     }
                                   relativeToView:controller.tabBarController.view];
              }
            });
          }
        };
        void(^refreshNotFoundBlk)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[[NSString stringWithFormat:@"Not found."]],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:YES]]];
          refreshDone(mainMsgTitle);
        };
        void (^refreshSuccessBlk)(NSString *, NSString *, id) = ^(NSString *mainMsgTitle, NSString *recordTitle, id downloadedEntity) {
          if (downloadedEntity == nil) { // server responded with 304
            downloadedEntity = [NSNull null];
          }
          [successMsgsForRefresh addObject:@[[NSString stringWithFormat:@"%@ downloaded.", recordTitle],
                                                    downloadedEntity]];
          refreshDone(mainMsgTitle);
        };
        void(^refreshRetryAfterBlk)(NSString *, NSString *, NSDate *) = ^(NSString *mainMsgTitle, NSString *recordTitle, NSDate *retryAfter) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[[NSString stringWithFormat:@"Server undergoing maintenance.  Please try again later."]],
                                             [NSNumber numberWithBool:YES],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
        };
        void (^refreshServerTempError)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[@"Temporary server error."],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
        };
        void(^refreshAuthReqdBlk)(NSString *, NSString *) = ^(NSString *mainMsgTitle, NSString *recordTitle) {
          receivedAuthReqdErrorOnDownloadAttempt = YES;
          [errsForRefresh addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                             [NSNumber numberWithBool:NO],
                                             @[@"Authentication required."],
                                             [NSNumber numberWithBool:NO],
                                             [NSNumber numberWithBool:NO]]];
          refreshDone(mainMsgTitle);
          [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                              object:nil
                                                            userInfo:nil];
        };
        NSString *mainMsgFragment = @"refreshing email verification status";
        NSString *recordTitle = @"Email verifiation status";
        [_coordDao.userCoordinatorDao fetchUser:user
                                ifModifiedSince:[user updatedAt]
                            notFoundOnServerBlk:^{refreshNotFoundBlk(mainMsgFragment, recordTitle);}
                                     successBlk:^(PELMUser *fetchedUser) {refreshSuccessBlk(mainMsgFragment, recordTitle, fetchedUser);}
                             remoteStoreBusyBlk:^(NSDate *retryAfter){refreshRetryAfterBlk(mainMsgFragment, recordTitle, retryAfter);}
                             tempRemoteErrorBlk:^{refreshServerTempError(mainMsgFragment, recordTitle);}
                            addlAuthRequiredBlk:^{
                              refreshAuthReqdBlk(mainMsgFragment, recordTitle);
                              dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                    object:nil
                                                                                  userInfo:nil];
                              });
                            }];
      } forControlEvents:UIControlEventTouchUpInside];
      UIButton *resendEmailBtn = makeSendEmailBtn();
      if ((refreshBtn.frame.size.width + 10.0 + resendEmailBtn.frame.size.width) > panel.frame.size.width) {
        [PEUIUtils setFrameHeight:((refreshBtn.frame.size.height * 2) + 3.0) ofView:buttonsView];
        [PEUIUtils placeView:refreshBtn atTopOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:8.0 + iphoneXSafeInsetsSideVal];
        [PEUIUtils placeView:resendEmailBtn below:refreshBtn onto:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:3.0 hpadding:0.0];
      } else {
        [PEUIUtils setFrameHeight:refreshBtn.frame.size.height ofView:buttonsView];
        [PEUIUtils placeView:refreshBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0 + iphoneXSafeInsetsSideVal];
        [PEUIUtils placeView:resendEmailBtn toTheRightOf:refreshBtn onto:buttonsView withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
      }
    } else {
      UIButton *resendEmailBtn = makeSendEmailBtn();
      [PEUIUtils setFrameHeight:resendEmailBtn.frame.size.height ofView:buttonsView];
      [PEUIUtils placeView:resendEmailBtn inMiddleOf:buttonsView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0 + iphoneXSafeInsetsSideVal];
    }
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:buttonsView below:statusPanel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:8.0 hpadding:0.0];
    heightOfPanel += buttonsView.frame.size.height + 8.0;
  } else {
    panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:statusPanel];
    UILabel *statusVerifiedMsg = [PEUIUtils labelWithKey:@"Your email address is verified."
                                                    font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                         backgroundColor:[UIColor clearColor]
                                               textColor:[UIColor darkGrayColor]
                                     verticalTextPadding:3.0
                                              fitToWidth:panel.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
    [PEUIUtils placeView:statusPanel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [PEUIUtils placeView:statusVerifiedMsg
                   below:statusPanel
                    onto:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:panel
                vpadding:4.0
                hpadding:8.0 + iphoneXSafeInsetsSideVal];
    heightOfPanel += statusVerifiedMsg.frame.size.height + 4.0;
  }
  [panel setTag:[panelTag integerValue]];
  [PEUIUtils setFrameHeight:heightOfPanel ofView:panel];
  return panel;
}

- (void)refreshEmailStatusPanelForUser:(PELMUser *)user
                              panelTag:(NSNumber *)panelTag
                  includeRefreshButton:(BOOL)includeRefreshButton
                        relativeToView:(UIView *)relativeToView
                         fontTextStyle:(UIFontTextStyle)fontTextStyle
                            controller:(UIViewController *)controller
              becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction {
  UIView *accountStatusPanel = [relativeToView viewWithTag:[panelTag integerValue]];
  UIView *superView = accountStatusPanel.superview;
  [accountStatusPanel removeFromSuperview];
  UIView *newStatusPanel = [self emailStatusPanelForUser:user
                                                panelTag:panelTag
                                    includeRefreshButton:includeRefreshButton
                                          relativeToView:superView
                                           fontTextStyle:fontTextStyle
                                              controller:controller
                                becameUnauthButtonAction:becameUnauthButtonAction];
  newStatusPanel.frame = accountStatusPanel.frame;
  [superView addSubview:newStatusPanel];
}

+ (UIButton *)forgotPasswordButtonForUser:(PELMUser *)user
                           coordinatorDao:(id<RCoordinatorDao>)coordDao
                                uitoolkit:(PEUIToolkit *)uitoolkit
                               controller:(UIViewController *)controller {
  UIButton *forgotPasswordBtn = [PEUIUtils buttonWithKey:@"Forgot password?"
                                                    font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:32.0 iphone6Width:34.0 iphone6PlusWidth:34.0 ipad:38.0]
                                                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                         backgroundColor:[UIColor rikerAppBlackSemiClear]
                                               textColor:[UIColor whiteColor]
                            disabledStateBackgroundColor:nil
                                  disabledStateTextColor:nil
                                         verticalPadding:[PEUIUtils valueIfiPhone5Width:14.0 iphone6Width:14.0 iphone6PlusWidth:18.0 ipad:26.0]
                                       horizontalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:20.0 iphone6PlusWidth:24.0 ipad:30.0]
                                            cornerRadius:5.0
                                                  target:nil
                                                  action:nil];
  [forgotPasswordBtn bk_addEventHandler:^(id sender) {
    [controller presentViewController:[PEUIUtils navigationControllerWithController:[[RForgotPasswordController alloc] initWithStoreCoordinator:coordDao user:user uitoolkit:uitoolkit]
                                                                navigationBarHidden:NO]
                             animated:YES
                           completion:^{}];
  } forControlEvents:UIControlEventTouchUpInside];
  return forgotPasswordBtn;
}

+ (NSArray *)accountStatusTextForUser:(PELMUser *)user {
  UIFont *fontForLongText = [PEUIUtils objIfiPhone5Width:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                            iphone6Width:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                        iphone6PlusWidth:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                    ipad:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]];
  if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodExpired]) {
    return @[@"Closed - expired trial", [UIColor redColor], fontForLongText];
  } else if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodAlmostExpired]) {
    return @[@"Almost expired trial", [UIColor carrotColor], fontForLongText];
  } else if ([user hasPaidAccount] && [user isPaymentPastDue] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    return @[@"Payment past due", [UIColor carrotColor], fontForLongText];
  } else if ([user hasPaidAccount] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    return @[@"Good standing", [UIColor greenSeaColor]];
  } else if ([user hasLapsedPaidAccount]) {
    return @[@"Closed - payment past due", [UIColor redColor], fontForLongText];
  } else if ([user hasCancelledPaidAccount]) {
    return @[@"Closed - cancelled", [UIColor redColor]];
  } else {
    return @[@"Active trial", [UIColor bootstrapPrimary]];
  }
}

- (UIView *)accountStatusPanelForUser:(PELMUser *)user
                       relativeToView:(UIView *)relativeToView
                           controller:(UIViewController *)controller {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  CGFloat totalHeight = 0.0;
  UITableView *accountTypeTableView =
  [PEUIUtils makeTableViewWithTag:nil
                        numFields:1
          dataSourceDelegateMaker:^(UITableView *tableView) {
            return
            [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:controller
                                                                  pickerScreenMaker:^(NSString *title, PELMUser *user, void(^doneAction)(PELMUser *)) {
                                                                    return [[RAccountStatusDetailController alloc] initWithStoreCoordinator:_coordDao uitoolkit:_uitoolkit screenToolkit:_screenToolkit panelToolkit:self doneAction:doneAction];
                                                                  }
                                                                  pickerScreenTitle:@"Account Status"
                                                                         fieldLabel:@"Status"
                                                                fieldValueFormatter:^(PELMUser *user) {
                                                                  return [RPanelToolkit accountStatusTextForUser:user];                                                                  
                                                                }
                                                                              value:user
                                                                  valuePickedAction:^(PELMUser *user) {
                                                                    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                  }
                                                         displayDisclosureIndicator:YES
                                                                          labelFont:[UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]]
                                                                          valueFont:[UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]]
                                                                       leftIconName:^NSString * {
                                                                         if ([user isBadAccount]) {
                                                                           return @"red-exclamation-icon";
                                                                         } else if ([user isPaymentPastDue] || (![user paidEnrollmentEstablishedAt] && [user isTrialPeriodAlmostExpired])) {
                                                                           return @"orange-exclamation-icon";
                                                                         }
                                                                         return nil;
                                                                       }
                                                                     relativeToView:relativeToView];
          }
                   relativeToView:relativeToView
             parentViewController:controller];
  [_tableViewDataSources addObject:accountTypeTableView.dataSource];
  NSAttributedString *attrMessage;
  UIFont *msgFont = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodExpired]) {
    attrMessage = AS(@"Your trial account is expired.");
  } else if (![user hasPaidAccount] && [user hasTrialAccount] && [user isTrialPeriodAlmostExpired]) {
    NSInteger daysUntil = [user.trialEndsAt daysFrom:[NSDate date]];
    msgFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    attrMessage = [PEUIUtils attributedTextWithTemplate:@"Your trial account expires in %@."
                                           textToAccent:[NSString stringWithFormat:@"%@ day%@", @(daysUntil), daysUntil > 1 ? @"s" : @""]
                                         accentTextFont:msgFont
                                        accentTextColor:[UIColor carrotColor]];
  } else if ([user hasPaidAccount] && [user isPaymentPastDue] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    attrMessage = AS(@"Your last automatic subscription payment-attempt failed.");
  } else if ([user hasPaidAccount] && ![user hasLapsedPaidAccount] && ![user hasCancelledPaidAccount]) {
    attrMessage = AS(@"Your paid subscription account is in good standing.");
  } else if ([user hasLapsedPaidAccount]) {
    attrMessage = AS(@"Your last (and final) automatic subscription payment-attempt failed.");
  } else if ([user hasCancelledPaidAccount]) {
    msgFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    if ([PEUtils isNotNil:user.validateAppStoreReceiptAt]) {
      attrMessage = AS(@"Your account is currently closed.  It was cancelled from your iTunes account.");
    } else {
      attrMessage = [PEUIUtils attributedTextWithTemplate:@"Your account is currently closed.  You cancelled it on %@."
                                             textToAccent:[PEUtils stringFromDate:user.paidEnrollmentCancelledAt withPattern:DATE_PATTERN]
                                           accentTextFont:msgFont
                                          accentTextColor:[UIColor blackColor]];
    }
  } else {
    NSInteger daysUntil = [user.trialEndsAt daysFrom:[NSDate date]];
    if (daysUntil > 90) {
      daysUntil = 90;
    }
    msgFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    attrMessage = [PEUIUtils attributedTextWithTemplate:@"Your trial account expires in %@."
                                           textToAccent:[NSString stringWithFormat:@"%@ days", @(daysUntil)]
                                         accentTextFont:msgFont
                                        accentTextColor:[UIColor bootstrapPrimary]];
  }
  UIView *accountTypeMsgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                                       fontForHeightCalculation:msgFont
                                                                 relativeToView:relativeToView];
  
  // place views
  [PEUIUtils placeView:accountTypeTableView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  totalHeight += accountTypeTableView.frame.size.height;
  [PEUIUtils placeView:accountTypeMsgPanel
                 below:accountTypeTableView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[PEUIUtils valueIfiPhone5Width:0.0
                                         iphone6Width:0.0
                                     iphone6PlusWidth:2.0
                                                 ipad:2.0]
              hpadding:0.0];
  totalHeight += accountTypeMsgPanel.frame.size.height + 0.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return contentPanel;
}

+ (NSArray *)whyPaymentFailedExpandingInfoPanelWithToggles:(NSMutableDictionary *)toggles
                                              contentIndex:(NSInteger)contentIndex
                             baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                belowViews:(NSArray *)belowViews
                                            relativeToView:(UIView *)relativeToView {
  NSString *infoIconName = [PEUIUtils objIfiPhone5Width:@"info-icon" iphone6Width:@"info-icon" iphone6PlusWidth:@"info-icon" ipad:@"info"];
  return [PEUIUtils expandingInfoPanelWithContentData:@[@"Why did my payment fail?",
                                                        AS(@"This could be due to a change in your card number or your card expiring, cancellation of your credit card, or the bank not recognizing the payment and taking action to prevent it."),
                                                        infoIconName,
                                                        ^{ [RUtils logExpandingInfoContentViewed:@"why_my_payment_failed"]; }]
                                      additionalViews:nil
                                    contentButtonFont:[RPanelToolkit contentInfoButtonFont]
                             contentButtonLabelStyler:nil
                                            textColor:[UIColor rikerAppBlack]
                                      backgroundColor:[UIColor whiteColor]
                                     chevronImageName:@"gray-down-chevron-small-icon"
                                         contentIndex:contentIndex
                                              toggles:toggles
                        baseControllerDisplayPanelBlk:baseControllerDisplayPanelBlk
                                testForBelowViewsMove:nil
                                           belowViews:belowViews
                             indexOfFirstBelowViewBlk:nil
                              extraContentPanelHeight:0.0
                                       relativeToView:relativeToView];
}

- (NSArray *)myPaymentInfoExpandingInfoPanelForUser:(PELMUser *)user
                                includeUpdateButton:(BOOL)includeUpdateButton
                          includeCancellationButton:(BOOL)includeCancellationButton
                                            toggles:(NSMutableDictionary *)toggles
                                       contentIndex:(NSInteger)contentIndex
                      baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                         belowViews:(NSArray *)belowViews
                                         controller:(UIViewController *)controller
                                     relativeToView:(UIView *)relativeToView
                                subscriptionProduct:(SKProduct *)subscriptionProduct {
  NSMutableAttributedString *paymentInfo = [[NSMutableAttributedString alloc] init];
  NSDictionary *spacingAttrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  UIFont *boldFont = [PEUIUtils boldFontForTextStyle:UIFontTextStyleBody];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  if (user.hasPaidIapAccount) {
    [paymentInfo appendAttributedString:AS(@"You can manage your Riker subscription and payment information from your iTunes account.")];
    [paymentInfo appendAttributedString:ASA(@"\nAdditional info:", [PEUIUtils attrsWithPpBeforeSpacing:[PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:16.0 ipad:22.0]])];
    [RUtils appendiTunesSubscriptionInfoToAttrString:paymentInfo
                                      prependNewline:YES
                                 subscriptionProduct:subscriptionProduct
                                   spacingAttributes:spacingAttrs];
  } else {
    [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your last payment of %@"
                                                                 textToAccent:[NSString stringWithFormat:@"$%.02f", user.lastInvoiceAmount.integerValue / 100.0]
                                                               accentTextFont:boldFont]];
    [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@" was made on %@."
                                                                 textToAccent:[PEUtils stringFromDate:user.lastInvoiceAt withPattern:DATE_PATTERN]
                                                               accentTextFont:boldFont]];
    if (user.isPaymentPastDue) {
      [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nYour lapsed payment was due on %@."
                                                              templateTextColor:nil
                                                               templateTextFont:nil
                                                                   textToAccent:[PEUtils stringFromDate:user.nextInvoiceAt withPattern:DATE_PATTERN]
                                                                 accentTextFont:boldFont
                                                                accentTextColor:nil
                                                   additionalTemplateAttributes:spacingAttrs]];
    } else {
      [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nYour next payment will automatically occur on %@."
                                                              templateTextColor:nil
                                                               templateTextFont:nil
                                                                   textToAccent:[PEUtils stringFromDate:user.nextInvoiceAt withPattern:DATE_PATTERN]
                                                                 accentTextFont:boldFont
                                                                accentTextColor:nil
                                                   additionalTemplateAttributes:spacingAttrs]];
    }
    [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nPayment method: %@"
                                                            templateTextColor:nil
                                                             templateTextFont:nil
                                                                 textToAccent:[NSString stringWithFormat:@"%@ ****%@, expiration: %02ld/%@", user.currentCardBrand, user.currentCardLast4, (long)user.currentCardExpMonth.integerValue, user.currentCardExpYear]
                                                               accentTextFont:boldFont
                                                              accentTextColor:nil
                                                 additionalTemplateAttributes:spacingAttrs]];
  }
  NSMutableArray *additionalViews = [[NSMutableArray alloc] init];
  if (includeUpdateButton) {
    if (!user.hasPaidIapAccount) {
      UIButton *updatePaymentMethod = [PEUIUtils buttonWithKey:@"Update\nPayment Method"
                                                          font:[PEUIUtils actionButtonFont]
                                               backgroundColor:[UIColor bootstrapPrimary]
                                                     textColor:[UIColor whiteColor]
                                  disabledStateBackgroundColor:nil
                                        disabledStateTextColor:nil
                                               verticalPadding:[PEUIUtils actionButtonVpadding]
                                             horizontalPadding:[PEUIUtils actionButtonHpadding]
                                                  cornerRadius:3.0
                                                        target:nil
                                                        action:nil];
      updatePaymentMethod.titleLabel.textAlignment = NSTextAlignmentLeft;
      [updatePaymentMethod bk_addEventHandler:^(id sender) {
        RUpdatePaymentMethodSynchronizeScreen *updatePaymentMethodStartScreen =
        [[RUpdatePaymentMethodSynchronizeScreen alloc] initWithStoreCoordinator:_coordDao
                                                                      uitoolkit:_uitoolkit
                                                                   panelToolkit:self
                                                                  screenToolkit:_screenToolkit];
        [controller presentViewController:[PEUIUtils navigationControllerWithController:updatePaymentMethodStartScreen
                                                                    navigationBarHidden:NO]
                                 animated:YES
                               completion:nil];
      } forControlEvents:UIControlEventTouchUpInside];
      //UIView *separator = [PEUIUtils panelWithWidthOf:0.90 relativeToView:relativeToView fixedHeight:3.0];
      UIView *separator = [PEUIUtils panelWithFixedWidth:relativeToView.frame.size.width - ([PEUIUtils expandingInfoPanelHPadding] * 2.0) - (iphoneXSafeInsetsSideVal * 2)
                                             fixedHeight:3.0];
      [separator setBackgroundColor:[UIColor cloudsColor]];
      [additionalViews addObject:updatePaymentMethod];
      if (![user hasPaidIapAccount] && includeCancellationButton) {
        [additionalViews addObject:separator];
      }
    }
    if (![user hasPaidIapAccount] && includeCancellationButton) {
      NSMutableString *cancelMsg = [[NSMutableString alloc] init];
      [cancelMsg appendString:@"You're free to cancel your Riker subscription at anytime.  "];
      [cancelMsg appendString:@"If you cancel your subscription, you will be refunded a pro-rated amount."];
      UILabel *cancelSubscriptionMsgLbl = [PEUIUtils labelWithKey:cancelMsg
                                                    font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                         backgroundColor:[UIColor clearColor]
                                               textColor:[UIColor rikerAppBlack]
                                     verticalTextPadding:5.0
                                              fitToWidth:(relativeToView.frame.size.width - 28.0 - (iphoneXSafeInsetsSideVal * 2))];
      [additionalViews addObject:cancelSubscriptionMsgLbl];
      UIButton *cancelSubscriptionBtn = [PEUIUtils buttonWithKey:@"Cancel\nSubscription"
                                                            font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                 backgroundColor:[UIColor alizarinColor]
                                                       textColor:[UIColor whiteColor]
                                    disabledStateBackgroundColor:nil
                                          disabledStateTextColor:nil
                                                 verticalPadding:20.0
                                               horizontalPadding:30.0
                                                    cornerRadius:3.0
                                                          target:nil
                                                          action:nil];
      cancelSubscriptionBtn.titleLabel.textAlignment = NSTextAlignmentLeft;
      [cancelSubscriptionBtn bk_addEventHandler:^(id sender) {
        RCancelAccountSynchronizeScreen *cancelStartScreen =
        [[RCancelAccountSynchronizeScreen alloc] initWithStoreCoordinator:_coordDao
                                                                uitoolkit:_uitoolkit
                                                             panelToolkit:self
                                                            screenToolkit:_screenToolkit];
        [controller presentViewController:[PEUIUtils navigationControllerWithController:cancelStartScreen
                                                                    navigationBarHidden:NO]
                                 animated:YES
                               completion:nil];
      } forControlEvents:UIControlEventTouchUpInside];
      [additionalViews addObject:cancelSubscriptionBtn];
    }
  }
  return [PEUIUtils expandingInfoPanelWithContentData:@[@"My Payment Information",
                                                        paymentInfo,
                                                        @"info-icon",
                                                        ^{ [RUtils logExpandingInfoContentViewed:@"my_payment_info"]; }]
                                      additionalViews:additionalViews
                                    contentButtonFont:[RPanelToolkit contentInfoButtonFont]
                             contentButtonLabelStyler:nil
                                            textColor:[UIColor rikerAppBlack]
                                      backgroundColor:[UIColor whiteColor]
                                     chevronImageName:@"gray-down-chevron-small-icon"
                                         contentIndex:contentIndex
                                              toggles:toggles
                        baseControllerDisplayPanelBlk:baseControllerDisplayPanelBlk
                                testForBelowViewsMove:nil
                                           belowViews:belowViews
                             indexOfFirstBelowViewBlk:nil
                              extraContentPanelHeight:[PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:26.0 iphone6PlusWidth:30.0 ipad:36.0]
                                       relativeToView:relativeToView];
}

+ (NSArray *)enrollInSubscriptionExpandingInfoPanelWithTitle:(NSString *)title
                                                    reenroll:(BOOL)reenroll
                                         subscriptionProduct:(SKProduct *)subscriptionProduct
                                                     toggles:(NSMutableDictionary *)toggles
                                                contentIndex:(NSInteger)contentIndex
                               baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                  belowViews:(NSArray *)belowViews
                                              relativeToView:(UIView *)relativeToView {
  NSMutableAttributedString *paymentInfo = [[NSMutableAttributedString alloc] init];
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  NSString *enrollMessage;
  NSString *logEvent;
  if (reenroll) {
    enrollMessage = @"Re-enroll in a Riker subscription and enjoy the benefits of having a Riker account.";
    logEvent = @"reenroll_enjoy_benefits";
  } else {
    enrollMessage = @"Enroll in a Riker subscription and continue to enjoy the benefits of having a Riker account.";
    logEvent = @"enroll_enjoy_benefits";
  }
  [paymentInfo appendAttributedString:AS(enrollMessage)];
  if ([PEUtils isNotNil:subscriptionProduct]) {
    [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nThe cost is %@ per year."
                                                            templateTextColor:nil
                                                             templateTextFont:nil
                                                                 textToAccent:[RUtils formattedPriceOfProduct:subscriptionProduct]
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]
                                                              accentTextColor:nil
                                                 additionalTemplateAttributes:attrs]];
    [paymentInfo appendAttributedString:ASA(@"\nAdditional info:", [PEUIUtils attrsWithPpBeforeSpacing:[PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:16.0 ipad:22.0]])];
    [RUtils appendiTunesSubscriptionInfoToAttrString:paymentInfo
                                      prependNewline:YES
                                 subscriptionProduct:subscriptionProduct
                                   spacingAttributes:[PEUIUtils paragraphBeforeSpacingAttrs]];
  } else {
    [paymentInfo appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nThe cost information could not be loaded at this time.  Please try back again later."
                                                            templateTextColor:nil
                                                             templateTextFont:[PEUIUtils italicFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                 textToAccent:@""
                                                               accentTextFont:nil
                                                              accentTextColor:nil
                                                 additionalTemplateAttributes:attrs]];
  }
  return [PEUIUtils expandingInfoPanelWithContentData:@[title,
                                                        paymentInfo,
                                                        [NSNull null],
                                                        ^{ [RUtils logExpandingInfoContentViewed:logEvent]; }]
                                      additionalViews:nil
                                    contentButtonFont:[RPanelToolkit contentInfoButtonFont]
                             contentButtonLabelStyler:nil
                                            textColor:[UIColor rikerAppBlack]
                                      backgroundColor:[UIColor whiteColor]
                                     chevronImageName:@"gray-down-chevron-small-icon"
                                         contentIndex:contentIndex
                                              toggles:toggles
                        baseControllerDisplayPanelBlk:baseControllerDisplayPanelBlk
                                testForBelowViewsMove:nil
                                           belowViews:belowViews
                             indexOfFirstBelowViewBlk:nil
                              extraContentPanelHeight:20.0
                                       relativeToView:relativeToView];
}

+ (NSArray *)useRikerAppExclusivelyExpandingInfoPanelWithTitle:(NSString *)title
                                                       toggles:(NSMutableDictionary *)toggles
                                                  contentIndex:(NSInteger)contentIndex
                                 baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                    belowViews:(NSArray *)belowViews
                                                relativeToView:(UIView *)relativeToView {
  NSMutableAttributedString *paymentInfo = [[NSMutableAttributedString alloc] init];
  [paymentInfo appendAttributedString:AS(USE_RIKER_EXCLUSIVELY_TEXT)];
  return [PEUIUtils expandingInfoPanelWithContentData:@[title,
                                                        paymentInfo,
                                                        [NSNull null],
                                                        ^{ [RUtils logExpandingInfoContentViewed:@"just_use_app_option"]; }]
                                      additionalViews:nil
                                    contentButtonFont:[RPanelToolkit contentInfoButtonFont]
                             contentButtonLabelStyler:nil
                                            textColor:[UIColor rikerAppBlack]
                                      backgroundColor:[UIColor whiteColor]
                                     chevronImageName:@"gray-down-chevron-small-icon"
                                         contentIndex:contentIndex
                                              toggles:toggles
                        baseControllerDisplayPanelBlk:baseControllerDisplayPanelBlk
                                testForBelowViewsMove:nil
                                           belowViews:belowViews
                             indexOfFirstBelowViewBlk:nil
                              extraContentPanelHeight:0.0
                                       relativeToView:relativeToView];
}

+ (UIView *)upcomingMaintenanceNavbarPanelForUser:(PELMUser *)user
                                   relativeToView:(UIView *)relativeToView
                                       controller:(UIViewController *)controller
                              navBannerRemovedBlk:(void(^)(CGFloat))navBannerRemovedBlk {
  UIView *bannerPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [bannerPanel setBackgroundColor:[UIColor upcomingMaintenanceBannerBgColor]];
  UILabel *header = [PEUIUtils labelWithKey:@"Upcoming Maintenance"
                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                            backgroundColor:[UIColor clearColor]
                                  textColor:[UIColor whiteColor]
                        verticalTextPadding:3.0];
  UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yellow-exclamation-icon"]];
  UIView *headerPanel = [PEUIUtils panelWithRowOfViews:@[icon, header]
                         horizontalPaddingBetweenViews:10.0
                                        viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  [headerPanel setBackgroundColor:[UIColor clearColor]];
  NSMutableAttributedString *subHeading = [[NSMutableAttributedString alloc] init];
  [subHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Scheduled for: %@.\n"
                                                              textToAccent:[PEUtils stringFromDate:user.maintenanceStartsAt withPattern:DATETIME_PATTERN]
                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]]];
  [subHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Estimated duration: %@ min."
                                                              textToAccent:[user.maintenanceDuration description]
                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]]];
  UILabel *subHeadingLabel = [PEUIUtils labelWithAttributeText:subHeading
                                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]
                                      fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:[UIColor whiteColor]
                                           verticalTextPadding:3.0];
  [subHeadingLabel setTextAlignment:NSTextAlignmentCenter];
  
  UIButton *aboutButton = [PEUIUtils buttonWithKey:@"About"
                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                   backgroundColor:[UIColor cloudsColor]
                                         textColor:[UIColor rikerAppBlack]
                      disabledStateBackgroundColor:nil
                            disabledStateTextColor:nil
                                   verticalPadding:5.0
                                 horizontalPadding:15.0
                                      cornerRadius:2.0
                                            target:nil
                                            action:nil];
  UIButton *okayGotItButton = [PEUIUtils buttonWithKey:@"Okay, got it"
                                                  font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                       backgroundColor:[UIColor cloudsColor]
                                             textColor:[UIColor rikerAppBlack]
                          disabledStateBackgroundColor:nil
                                disabledStateTextColor:nil
                                       verticalPadding:5.0
                                     horizontalPadding:15.0
                                          cornerRadius:2.0
                                                target:nil
                                                action:nil];
  UIView *buttonsPanel = [PEUIUtils panelWithRowOfViews:@[aboutButton, okayGotItButton]
                          horizontalPaddingBetweenViews:10.0
                                         viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  UIView *bannerContentPanel = [PEUIUtils panelWithColumnOfViews:@[headerPanel, subHeadingLabel, buttonsPanel]
                                     verticalPaddingBetweenViews:5.0
                                                  viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  [PEUIUtils setFrameHeight:bannerContentPanel.frame.size.height + 18.0 ofView:bannerPanel];
  [PEUIUtils placeView:bannerContentPanel inMiddleOf:bannerPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  [aboutButton bk_addEventHandler:^(id sender) {
    NSMutableAttributedString *alertDescription = [[NSMutableAttributedString alloc] init];
    [alertDescription appendAttributedString:AS(@"Periodically, the Riker servers need maintenance performed. During these outages the Riker servers are unavailable to receive your real-time data updates.")];
    [alertDescription appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nDuring an outage, %@ can be used to store your sets and logs locally, and later you can bulk sync them to your account."
                                                                      textToAccent:@"Offline Mode"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [PEUIUtils showInfoAlertWithTitle:@"Maintenance Outages"
                     alertDescription:alertDescription
                  descLblHeightAdjust:0.0
            additionalContentSections:nil
                             topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                          buttonTitle:@"Okay"
                         buttonAction:^{}
                       relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  } forControlEvents:UIControlEventTouchUpInside];
  [okayGotItButton bk_addEventHandler:^(id sender) {
    CGFloat bannerPanelHeight = bannerPanel.frame.size.height;
    [UIView animateWithDuration:0.05
                          delay:0.10
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       [PEUIUtils setFrameHeight:0.0 ofView:okayGotItButton];
                       [PEUIUtils setFrameHeight:0.0 ofView:aboutButton];
                       [PEUIUtils setFrameHeight:0.0 ofView:subHeadingLabel];
                       [PEUIUtils setFrameHeight:0.0 ofView:icon];
                       [PEUIUtils setFrameHeight:0.0 ofView:header];
                     }
                     completion:nil];
    [UIView animateWithDuration:0.25
                          delay:0.10
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       [PEUIUtils setFrameHeight:0.0 ofView:bannerPanel];
                     }
                     completion:^(BOOL finished) {
                       [APP setMaintenanceAckAt:[NSDate date]];
                       [bannerPanel removeFromSuperview];
                       [APP refreshTabs];
                       if (navBannerRemovedBlk) {
                         navBannerRemovedBlk(bannerPanelHeight);
                       }
                     }];
  } forControlEvents:UIControlEventTouchUpInside];
  return bannerPanel;
}

+ (UIView *)maintenanceInProgressNavbarPanelForUser:(PELMUser *)user
                                     relativeToView:(UIView *)relativeToView
                                         controller:(UIViewController *)controller {
  UIView *bannerPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [bannerPanel setBackgroundColor:[UIColor maintenanceInProgressBannerBgColor]];
  UILabel *header = [PEUIUtils labelWithKey:@"Maintenance Outage"
                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                            backgroundColor:[UIColor clearColor]
                                  textColor:[UIColor whiteColor]
                        verticalTextPadding:3.0];
  UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yellow-exclamation-icon"]];
  UIView *headerPanel = [PEUIUtils panelWithRowOfViews:@[icon, header]
                         horizontalPaddingBetweenViews:10.0
                                        viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  [headerPanel setBackgroundColor:[UIColor clearColor]];
  NSMutableAttributedString *subHeading = [[NSMutableAttributedString alloc] init];
  [subHeading appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Estimated duration: %@ min."
                                                              textToAccent:[user.maintenanceDuration description]
                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]]];
  UILabel *subHeadingLabel = [PEUIUtils labelWithAttributeText:subHeading
                                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]
                                      fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption2]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:[UIColor whiteColor]
                                           verticalTextPadding:3.0];
  
  UIButton *aboutButton = [PEUIUtils buttonWithKey:@"What's this?"
                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                   backgroundColor:[UIColor cloudsColor]
                                         textColor:[UIColor rikerAppBlack]
                      disabledStateBackgroundColor:nil
                            disabledStateTextColor:nil
                                   verticalPadding:5.0
                                 horizontalPadding:15.0
                                      cornerRadius:2.0
                                            target:nil
                                            action:nil];
  UIView *buttonsPanel = [PEUIUtils panelWithRowOfViews:@[aboutButton]
                          horizontalPaddingBetweenViews:10.0
                                         viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  UIView *bannerContentPanel = [PEUIUtils panelWithColumnOfViews:@[headerPanel, subHeadingLabel, buttonsPanel]
                                     verticalPaddingBetweenViews:5.0
                                                  viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  [PEUIUtils setFrameHeight:bannerContentPanel.frame.size.height + 18.0 ofView:bannerPanel];
  [PEUIUtils placeView:bannerContentPanel inMiddleOf:bannerPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  [aboutButton bk_addEventHandler:^(id sender) {
    NSMutableAttributedString *alertDescription = [[NSMutableAttributedString alloc] init];
    [alertDescription appendAttributedString:AS(@"The Riker servers are currently undergoing maintenance. At this time you may not be able to sync new sets or logs.")];
    [alertDescription appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nDuring the outage, %@ can be used to store your sets and logs locally, and later you can bulk sync them to your account."
                                                                      textToAccent:@"Offline Mode"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [PEUIUtils showInfoAlertWithTitle:@"Maintenance Outage"
                     alertDescription:alertDescription
                  descLblHeightAdjust:0.0
            additionalContentSections:nil
                             topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                          buttonTitle:@"Okay"
                         buttonAction:^{}
                       relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  } forControlEvents:UIControlEventTouchUpInside];
  return bannerPanel;
}

+ (UIView *)breadcrumbPanelWithTemplateText:(NSString *)templateText
                               textToAccent:(NSString *)textToAccent
                             relativeToView:(UIView *)relativeToView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIFontTextStyle fontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                            iphone6Width:UIFontTextStyleCaption1
                                                        iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                    ipad:UIFontTextStyleBody];
  UIFont *boldFont = [PEUIUtils boldFontForTextStyle:fontTextStyle];
  UILabel *headingLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:templateText
                                                                                     textToAccent:textToAccent
                                                                                   accentTextFont:boldFont
                                                                                  accentTextColor:[UIColor rikerAppBlack]]
                                                       font:[UIFont preferredFontForTextStyle:fontTextStyle]
                                   fontForHeightCalculation:boldFont
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlackSemiClear]
                                        verticalTextPadding:[PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:9.0 ipad:15.0]
                                                 fitToWidth:relativeToView.frame.size.width - 18.0 - (iphoneXSafeInsetsSideVal * 2)];
  [headingLabel setTextAlignment:NSTextAlignmentCenter];
  UIView *headingPanel = [PEUIUtils panelWithWidthOf:0.95 relativeToView:relativeToView fixedHeight:headingLabel.frame.size.height + 15.0];
  [PEUIUtils adjustWidthOfView:headingPanel withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [headingPanel setBackgroundColor:[UIColor cloudsColor]];
  [[headingPanel layer] setCornerRadius:3.0];
  [PEUIUtils placeView:headingLabel inMiddleOf:headingPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  return headingPanel;
}

#pragma mark - User Settings Panels

- (PEComponentsMakerBlk)userSettingsFormComponentsWithWeightUomId:(NSNumber *)weightUomId
                                                        sizeUomId:(NSNumber *)sizeUomId
                                       displayDisclosureIndicator:(BOOL)displayDisclosureIndicator {
  return ^ NSDictionary * (UIViewController *parentViewController, UIView *relativeToView) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
    CGFloat desiredCommonHeight = [RPanelToolkit rowDataCellHeightWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle] uitoolkit:_uitoolkit];
    components[@(RUserSettingsTagWeightUom)] =
    [self makeTableViewWithTag:RUserSettingsTagWeightUom
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSNumber *weightUomId, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newWeightUnitsForSelectionScreenMakerWithItemSelectedAction:^(NSArray *weightUom, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(weightUom[0]);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedWeightUom:@[weightUomId, [RUtils weightUnitNameForUomId:weightUomId]]]();
                                                               }
                                                               pickerScreenTitle:@"Default weight units"
                                                                      fieldLabel:@"Default weight units"
                                                             fieldValueFormatter:^(NSNumber *weightUomId) {
                                                               return [RUtils weightUnitNameForUomId:weightUomId];
                                                             }
                                                                           value:weightUomId
                                                               valuePickedAction:^(NSNumber *weightUomId) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RUserSettingsTagWeightUomMsg)] = [PEUIUtils labelWithKey:@"Default units used when logging reps or your body weight."
                                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                          backgroundColor:[UIColor clearColor]
                                                                textColor:[UIColor darkGrayColor]
                                                      verticalTextPadding:3.0
                                                               fitToWidth:parentViewController.view.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
    components[@(RUserSettingsTagSizeUom)] =
    [self makeTableViewWithTag:RUserSettingsTagSizeUom
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSNumber *sizeUomId, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newSizeUnitsForSelectionScreenMakerWithItemSelectedAction:^(NSArray *sizeUom, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(sizeUom[0]);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedSizeUom:@[sizeUomId, [RUtils sizeUnitNameForUomId:sizeUomId]]]();
                                                               }
                                                               pickerScreenTitle:@"Default size units"
                                                                      fieldLabel:@"Default size units"
                                                             fieldValueFormatter:^(NSNumber *sizeUomId) {
                                                               return [RUtils sizeUnitNameForUomId:sizeUomId];
                                                             }
                                                                           value:sizeUomId
                                                               valuePickedAction:^(NSNumber *sizeUomId) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RUserSettingsTagSizeUomMsg)] = [PEUIUtils labelWithKey:@"Default units used when logging your arm size, chest size, etc."
                                                                   font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                        backgroundColor:[UIColor clearColor]
                                                              textColor:[UIColor darkGrayColor]
                                                    verticalTextPadding:3.0
                                                             fitToWidth:parentViewController.view.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
    UIView *parentView = [parentViewController view];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:relativeToView];
    UILabel *weightIncDecAmountLabel = [parentView viewWithTag:RUserSettingsTagWeightIncDecAmountMsg];
    if (!weightIncDecAmountLabel) {
      weightIncDecAmountLabel = [PEUIUtils labelWithKey:@"The amount to increase or decrease the weight by when recording sets."
                                                   font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor darkGrayColor]
                                    verticalTextPadding:3.0
                                             fitToWidth:parentView.frame.size.width - 15.0 - (iphoneXSafeInsetsSideVal * 2)];
      [weightIncDecAmountLabel setTag:RUserSettingsTagWeightIncDecAmountMsg];
    }
    components[@(RUserSettingsTagWeightIncDecAmountMsg)] = weightIncDecAmountLabel;
    UITextField *weightIncDecAmountTf = [parentView viewWithTag:RUserSettingsTagWeightIncDecAmount];
    if (!weightIncDecAmountTf) {
      weightIncDecAmountTf = tfMaker(@"Weight adjust amount", RUserSettingsTagWeightIncDecAmount);
      [PEUIUtils setFrameHeight:desiredCommonHeight ofView:weightIncDecAmountTf];
      [weightIncDecAmountTf setKeyboardType:UIKeyboardTypeNumberPad];
    }
    components[@(RUserSettingsTagWeightIncDecAmount)] = weightIncDecAmountTf;
    return components;
  };
}

- (void)placeUserSettingsViews:(NSDictionary *)userSettingsViews
                     ontoPanel:(UIView *)contentPanel
            weightIncDecAmount:(UIView *)weightIncDecAmount {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *weightIncDecAmountMsg = userSettingsViews[@(RUserSettingsTagWeightIncDecAmountMsg)];
  UIView *weightUomTableView = userSettingsViews[@(RUserSettingsTagWeightUom)];
  UIView *weightUomMsg = userSettingsViews[@(RUserSettingsTagWeightUomMsg)];
  UIView *sizeUomTableView = userSettingsViews[@(RUserSettingsTagSizeUom)];
  UIView *sizeUomMsg = userSettingsViews[@(RUserSettingsTagSizeUomMsg)];
  CGFloat vpadding = 15.0;
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:weightIncDecAmount
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  totalHeight += weightIncDecAmount.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:weightIncDecAmountMsg
                 below:weightIncDecAmount
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += weightIncDecAmountMsg.frame.size.height + 4.0;
  [PEUIUtils placeView:weightUomTableView
                 below:weightIncDecAmountMsg
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += weightUomTableView.frame.size.height + vpadding;
  [PEUIUtils placeView:weightUomMsg
                 below:weightUomTableView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:0.0
              hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += weightUomMsg.frame.size.height;
  [PEUIUtils placeView:sizeUomTableView
                 below:weightUomMsg
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += sizeUomTableView.frame.size.height + vpadding;
  [PEUIUtils placeView:sizeUomMsg
                 below:sizeUomTableView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:0.0
              hpadding:8.0 + iphoneXSafeInsetsSideVal];
  totalHeight += sizeUomMsg.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
}

- (PEEntityViewPanelMakerBlk)userSettingsViewPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController, PELMUser *user, RUserSettings *userSettings) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self userSettingsFormComponentsWithWeightUomId:userSettings.weightUom
                                                                     sizeUomId:userSettings.sizeUom
                                                    displayDisclosureIndicator:NO](parentViewController, contentPanel);
    void(^disableUserInteraction)(RUserSettingsTag) = ^(RUserSettingsTag tag) {
      UITableView *t = components[@(tag)];
      [t setUserInteractionEnabled:NO];
    };
    disableUserInteraction(RUserSettingsTagWeightUom);
    disableUserInteraction(RUserSettingsTagSizeUom);
    UIView *weightIncDecAmountPanel = [self tablePanelWithRowData:@[@[@"Weight adjust amount", [PEUtils descriptionOrEmptyIfNil:userSettings.weightIncDecAmount]]]
                                                        uitoolkit:_uitoolkit
                                                    fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                                       parentView:contentPanel];
    [PEUIUtils styleViewForIpad:weightIncDecAmountPanel];
    [self placeUserSettingsViews:components ontoPanel:contentPanel weightIncDecAmount:weightIncDecAmountPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEEntityPanelMakerBlk)userSettingsFormPanelMakerWithDefaultWeightUomBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                                         defaultSizeUomBlk:(NSNumber *(^)(void))defaultSizeUomBlk {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    NSNumber *weightUomId = [self valueAtTableTag:RUserSettingsTagWeightUom orBlockIfNil:defaultWeightUomBlk parentView:parentView];
    NSNumber *sizeUomId = [self valueAtTableTag:RUserSettingsTagSizeUom orBlockIfNil:defaultSizeUomBlk parentView:parentView];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self userSettingsFormComponentsWithWeightUomId:weightUomId
                                                                     sizeUomId:sizeUomId
                                                    displayDisclosureIndicator:YES](parentViewController, contentPanel);
    UIView *weightIncDecAmountPanel = components[@(RUserSettingsTagWeightIncDecAmount)];
    [self placeUserSettingsViews:components ontoPanel:contentPanel weightIncDecAmount:weightIncDecAmountPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)userSettingsFormPanelToUserSettingsBinder {
  return ^ void (UIView *panel, RUserSettings *userSettings) {
    [userSettings setWeightUom:[PEUIUtils valueForSingleTableViewWithTag:RUserSettingsTagWeightUom panel:panel]];
    [userSettings setSizeUom:[PEUIUtils valueForSingleTableViewWithTag:RUserSettingsTagSizeUom panel:panel]];
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:userSettings withNumberSetter:sel fromTextfieldWithTag:tag fromView:panel];
    };
    bindnum(RUserSettingsTagWeightIncDecAmount, @selector(setWeightIncDecAmount:));
  };
}

- (PEEntityToPanelBinderBlk)userSettingsToUserSettingsPanelBinder {
  return ^(RUserSettings *userSettings, UIView *panel) {
    if (userSettings) {
      [PEUIUtils setValueForSingleTableViewWithTag:RUserSettingsTagWeightUom panel:panel value:userSettings.weightUom];
      [PEUIUtils setValueForSingleTableViewWithTag:RUserSettingsTagSizeUom panel:panel value:userSettings.sizeUom];
      void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
        [PEUIUtils bindToTextControlWithTag:tag fromView:panel fromEntity:userSettings withGetter:sel];
      };
      bindtt(RUserSettingsTagWeightIncDecAmount, @selector(weightIncDecAmount));
    }
  };
}

- (PEEnableDisablePanelBlk)userSettingsFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag fromView:panel enable:enable];
    };
    void (^enabDisabTable)(NSInteger) = ^(NSInteger tag) {
      enabDisab(tag);
      [[panel viewWithTag:tag] setUserInteractionEnabled:enable];
    };
    enabDisabTable(RUserSettingsTagWeightUom);
    enabDisabTable(RUserSettingsTagSizeUom);
    enabDisab(RUserSettingsTagWeightIncDecAmount);
  };
}

#pragma mark - Set Panels

- (PEComponentsMakerBlk)setFormComponentsWithLoggedAt:(NSDate *)loggedAt
                                           ignoreTime:(BOOL)ignoreTime
                                             movement:(RMovement *)movement
                                      movementVariant:(RMovementVariant *)movementVariant
                                         movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                  movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                          weightUomId:(NSNumber *)weightUomId
                           displayDisclosureIndicator:(BOOL)displayDisclosureIndicator
                        mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                        weightTfDefaultedToBodyWeight:(WeightTfDefaultedNotice)weightTfDefaultedToBodyWeight
                                              forView:(BOOL)forView {
  return ^ NSDictionary * (UIViewController *parentViewController, UIView *relativeToView) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:relativeToView];
    UITextField *numRepsTf = tfMaker(@"Num reps", RSetTagNumReps);
    [numRepsTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(RSetTagNumReps)] = numRepsTf;
    CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
    UILabel *ignoreTimeMsgLabel = [PEUIUtils labelWithKey:@"Whether or not to track the time component (hour, minute and second) of when the set was recorded."
                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                          backgroundColor:[UIColor clearColor]
                                                textColor:[UIColor darkGrayColor]
                                      verticalTextPadding:3.0
                                               fitToWidth:relativeToView.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
    components[@(RSetTagIgnoreTimeMsgLabel)] = ignoreTimeMsgLabel;
    UITableView *loggedAtTableView =
    [self makeTableViewWithTag:RSetTagLoggedAt
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSDate *loggedAt, void(^valPickedAction)(id)) {
                                                                 UISwitch *ignoreTimeSwitch = components[@(RSetTagIgnoreTimeSwitch)];
                                                                 return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                      initialSelectedDate:loggedAt
                                                                                                           datePickerMode:(ignoreTimeSwitch.on ? UIDatePickerModeDate : UIDatePickerModeDateAndTime)
                                                                                                      logDatePickedAction:valPickedAction]();
                                                               }
                                                               pickerScreenTitle:@"Logged at"
                                                                      fieldLabel:@"Logged at"
                                                             fieldValueFormatter:^(NSDate *loggedAt) {
                                                               NSString *pattern;
                                                               if (forView) {
                                                                 if (ignoreTime) {
                                                                   pattern = DATE_PATTERN;
                                                                 } else {
                                                                   pattern = DATETIME_PATTERN;
                                                                 }
                                                               } else {
                                                                 UISwitch *ignoreTimeSwitch = components[@(RSetTagIgnoreTimeSwitch)];
                                                                 if (ignoreTimeSwitch.on) {
                                                                   pattern = DATE_PATTERN;
                                                                 } else {
                                                                   pattern = DATETIME_PATTERN;
                                                                 }
                                                               }
                                                               return [PEUtils stringFromDate:loggedAt withPattern:pattern];
                                                             }
                                                                           value:loggedAt
                                                               valuePickedAction:^(NSDate *loggedAt) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RSetTagLoggedAt)] = loggedAtTableView;
    CGFloat desiredCommonHeight = [RPanelToolkit rowDataCellHeightWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle] uitoolkit:_uitoolkit];
    CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:numRepsTf];
    [self makeSwitchWithTag:RSetTagIgnoreTimeSwitch
                   panelTag:RSetTagIgnoreTimePanel
                  labelText:@"Ignore time"
                  labelFont:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                              font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                panelHeight:desiredCommonHeight
                 parentView:relativeToView
                 components:components];
    UISwitch *ignoreTimeSwitch = components[@(RSetTagIgnoreTimeSwitch)];
    [ignoreTimeSwitch bk_addEventHandler:^(id sender) {
      UITableView *loggedAtTableView = components[@(RSetTagLoggedAt)];
      [loggedAtTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                               withRowAnimation:UITableViewRowAnimationAutomatic];
    } forControlEvents:UIControlEventTouchUpInside];
    UITextField *weightTf = tfMaker(@"Weight", RSetTagWeight);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:weightTf];
    [weightTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(RSetTagWeight)] = weightTf;
    components[@(RSetTagMovement)] =
    [self makeTableViewWithTag:RSetTagMovement
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, RMovement *movement, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newMovementsScreenMakerWithTitle:@"Choose Movement"
                                                                                                      itemSelectedAction:^(RMovement *selectedMovement, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                                                        valPickedAction(selectedMovement);
                                                                                                        [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                                                      } initialSelectedMovement:movement]();
                                                               }
                                                               pickerScreenTitle:@"Movement"
                                                                      fieldLabel:@"Movement"
                                                             fieldValueFormatter:^(RMovement *movement) {
                                                               return movement.canonicalName;
                                                             }
                                                                           value:movement
                                                               valuePickedAction:^(RMovement *movement) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                 NSDictionary *variantsDict = movementVariantsBlk(movement);
                                                                 NSArray *(^variantsArrayBlk)(void) = ^NSArray *{
                                                                   NSArray *variants = [variantsDict allValues];
                                                                   return [variants sortedArrayUsingComparator:^NSComparisonResult(RMovementVariant *mv1, RMovementVariant *mv2) {
                                                                     return [mv1.sortOrder compare:mv2.sortOrder];
                                                                   }];
                                                                 };
                                                                 if (variantsDict.count == 0) {
                                                                   [PEUIUtils setValueForSingleTableViewWithTag:RSetTagMovementVariant
                                                                                                          panel:parentView
                                                                                                          value:nil];
                                                                   UITableView *movVariantsTableView = components[@(RSetTagMovementVariant)];
                                                                   [movVariantsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                               withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                   [movVariantsTableView setUserInteractionEnabled:NO];
                                                                 } else {
                                                                   RMovementVariant *currentSelectedMovVariant = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovementVariant panel:parentView];
                                                                   UITableView *movVariantsTableView = components[@(RSetTagMovementVariant)];
                                                                   [movVariantsTableView setUserInteractionEnabled:YES];
                                                                   if (![PEUtils isNil:currentSelectedMovVariant]) {
                                                                     if (variantsDict[currentSelectedMovVariant.localMasterIdentifier] == nil) {
                                                                       NSArray *variantsArray = variantsArrayBlk();
                                                                       RMovementVariant *firstMovVar = variantsArray[0];
                                                                       [PEUIUtils setValueForSingleTableViewWithTag:RSetTagMovementVariant
                                                                                                              panel:parentView
                                                                                                              value:firstMovVar];
                                                                       [movVariantsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                                   withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                     } else {
                                                                       // nothing to do
                                                                     }
                                                                   } else {
                                                                     NSArray *variantsArray = variantsArrayBlk();
                                                                     RMovementVariant *firstMovVar = variantsArray[0];
                                                                     [PEUIUtils setValueForSingleTableViewWithTag:RSetTagMovementVariant
                                                                                                            panel:parentView
                                                                                                            value:firstMovVar];
                                                                     [movVariantsTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                   }
                                                                 }
                                                                 if (movement.isBodyLift) {
                                                                   CGFloat multiplier = 1.0;
                                                                   if ([PEUtils isNotNil:movement.percentageOfBodyWeight]) {
                                                                     multiplier = movement.percentageOfBodyWeight.floatValue;
                                                                   }
                                                                   NSNumber *weightVal = nil;
                                                                   if ([PEUtils isNotNil:mostRecentBmlWithNonNilWeight]) {
                                                                     weightVal = [NSNumber numberWithFloat:[RUtils weightValueWithValue:mostRecentBmlWithNonNilWeight.bodyWeight
                                                                                                                     currentWeightUomId:mostRecentBmlWithNonNilWeight.bodyWeightUom
                                                                                                                      targetWeightUomId:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits
                                                                                                                                                                            panel:parentView]].floatValue * multiplier];
                                                                     [weightTf setText:[NSString stringWithFormat:@"%.f", weightVal.floatValue]];
                                                                   }
                                                                   if (weightTfDefaultedToBodyWeight) {
                                                                     weightTfDefaultedToBodyWeight([PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:parentView],
                                                                                                   mostRecentBmlWithNonNilWeight,
                                                                                                   weightVal,
                                                                                                   [RUtils weightUnitNameForUomId:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits panel:parentView]],
                                                                                                   parentViewController);
                                                                   }
                                                                 }
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RSetTagMovementVariant)] =
    [self makeTableViewWithTag:RSetTagMovementVariant
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, RMovementVariant *movementVariant, void(^valPickedAction)(id)) {
                                                                 RMovement *mov = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:parentView];
                                                                 return [_screenToolkit newMovementVariantsForSelectionScreenMakerWithItemSelectedAction:^(RMovementVariant *selectedMovementVariant, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(selectedMovementVariant);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedMovementVariant:movementVariant
                                                                         movement:mov]();
                                                               }
                                                               pickerScreenTitle:@"Movement Variant"
                                                                      fieldLabel:@"Movement variant"
                                                             fieldValueFormatter:^(RMovementVariant *movVariant) {
                                                               //return [PEUtils isNotNil:movVariant] ? movVariant.name : @"(not applicable)";
                                                               return [PEUtils isNotNil:movVariant] ? movVariant.name : @" --- ";
                                                             }
                                                                           value:movementVariant
                                                               valuePickedAction:^(RMovementVariant *movementVariant) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                 if (movementVariant.localMasterIdentifier.integerValue == BODY_MOVEMENT_VARIANT_ID) {
                                                                   RMovement *selectedMovement = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:parentView];
                                                                   CGFloat multiplier = 1.0;
                                                                   if ([PEUtils isNotNil:selectedMovement.percentageOfBodyWeight]) {
                                                                     multiplier = selectedMovement.percentageOfBodyWeight.floatValue;
                                                                   }
                                                                   NSNumber *weightVal = nil;
                                                                   if ([PEUtils isNotNil:mostRecentBmlWithNonNilWeight]) {
                                                                     weightVal = [NSNumber numberWithFloat:[RUtils weightValueWithValue:mostRecentBmlWithNonNilWeight.bodyWeight
                                                                                                                     currentWeightUomId:mostRecentBmlWithNonNilWeight.bodyWeightUom
                                                                                                                      targetWeightUomId:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits
                                                                                                                                                                            panel:parentView]].floatValue * multiplier];
                                                                     [weightTf setText:[NSString stringWithFormat:@"%.f", weightVal.floatValue]];
                                                                   }
                                                                   if (weightTfDefaultedToBodyWeight) {
                                                                     weightTfDefaultedToBodyWeight([PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:parentView],
                                                                                                   mostRecentBmlWithNonNilWeight,
                                                                                                   weightVal,
                                                                                                   [RUtils weightUnitNameForUomId:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits panel:parentView]],
                                                                                                   parentViewController);
                                                                   }
                                                                 }
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RSetTagWeightUnits)] =
    [self makeTableViewWithTag:RSetTagWeightUnits
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSNumber *weightUomId, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newWeightUnitsForSelectionScreenMakerWithItemSelectedAction:^(NSArray *weightUom, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(weightUom[0]);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedWeightUom:@[weightUomId, [RUtils weightUnitNameForUomId:weightUomId]]]();
                                                               }
                                                               pickerScreenTitle:@"Weight units"
                                                                      fieldLabel:@"Weight units"
                                                             fieldValueFormatter:^(NSNumber *weightUomId) {
                                                               return [RUtils weightUnitNameForUomId:weightUomId];
                                                             }
                                                                           value:weightUomId
                                                               valuePickedAction:^(NSNumber *newWeightUomId) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    [self makeSwitchWithTag:RSetTagToFailureSwitch
                   panelTag:RSetTagToFailurePanel
                  labelText:@"To failure"
                  labelFont:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                panelHeight:desiredCommonHeight
                 parentView:relativeToView
                 components:components];
    [self makeSwitchWithTag:RSetTagNegativesSwitch
                   panelTag:RSetTagNegativesPanel
                  labelText:@"Negatives"
                  labelFont:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                panelHeight:desiredCommonHeight
                 parentView:relativeToView
                 components:components];
    return components;
  };
}

- (PEEntityViewPanelMakerBlk)setViewPanelMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                                                           movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                                    movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                                      movementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                               movementVariantLoaderBlk:(RMovementVariant *(^)(NSNumber *))movementVariantLoaderBlk
                                          mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                          weightTfDefaultedToBodyWeight:(WeightTfDefaultedNotice)weightTfDefaultedToBodyWeight {
  return ^ UIView * (PEAddViewEditController *parentViewController, PELMUser *user, RSet *set) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self setFormComponentsWithLoggedAt:set.loggedAt
                                                        ignoreTime:set.ignoreTime
                                                          movement:movementLoaderBlk(set.movementId)
                                                   movementVariant:movementVariantLoaderBlk(set.movementVariantId)
                                                      movementsBlk:movementsBlk
                                               movementVariantsBlk:movementVariantsBlk
                                                       weightUomId:set.weightUom
                                        displayDisclosureIndicator:NO
                                     mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                     weightTfDefaultedToBodyWeight:weightTfDefaultedToBodyWeight
                                                           forView:YES](parentViewController, contentPanel);
    NSString *(^formatOrNil)(NSNumber *) = [RUtils weightFormatOrNilMaker];
    UITableView *setLoggedAtTableView = components[@(RSetTagLoggedAt)];
    [setLoggedAtTableView setUserInteractionEnabled:NO];
    UIView *ignoreTimePanel = [self tablePanelWithRowData:@[@[@"Ignore time", [PEUtils yesNoFromBool:set.ignoreTime]]]
                                                uitoolkit:_uitoolkit
                                            fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                               parentView:contentPanel];
    UILabel *ignoreTimeMsgLabel = components[@(RSetTagIgnoreTimeMsgLabel)];
    UITableView *movementTableView = components[@(RSetTagMovement)];
    [movementTableView setUserInteractionEnabled:NO];
    UITableView *movementVariantTableView = components[@(RSetTagMovementVariant)];
    [movementVariantTableView setUserInteractionEnabled:NO];
    UIView *weightPanel = [self tablePanelWithRowData:@[@[@"Weight", formatOrNil(set.weight)]]
                                            uitoolkit:_uitoolkit
                                        fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                           parentView:contentPanel];
    UITableView *weightUomTableView = components[@(RSetTagWeightUnits)];
    [weightUomTableView setUserInteractionEnabled:NO];
    UIView *repsPanel = [self tablePanelWithRowData:@[@[@"Reps", [PEUtils descriptionOrEmptyIfNil:set.numReps]]]
                                          uitoolkit:_uitoolkit
                                      fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                         parentView:contentPanel];
    UIView *toFailurePanel = [self tablePanelWithRowData:@[@[@"To failure", [PEUtils yesNoFromBool:set.toFailure]]]
                                               uitoolkit:_uitoolkit
                                           fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                              parentView:contentPanel];
    UIView *negativesPanel = [self tablePanelWithRowData:@[@[@"Negatives", [PEUtils yesNoFromBool:set.negatives]]]
                                               uitoolkit:_uitoolkit
                                           fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                              parentView:contentPanel];
    UIView *sectionPanel = [PEUIUtils panelWithColumnOfViews:@[repsPanel,
                                                               toFailurePanel,
                                                               negativesPanel]
                                 verticalPaddingBetweenViews:10.0
                                              viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *originationPanel = [self originationDevicePanelWithOriginationDevice:originationDevicesBlk()[set.originationDeviceId]
                                                                      parentView:contentPanel];
    UIView *importedAtPanel = nil;
    if (set.importedAt) {
      importedAtPanel = [self importedAtPanelWithImportedAt:set.importedAt entityType:@"set" parentView:parentView];
    }
    CGFloat vpaddingForTableViews = [PEUIUtils valueIfiPhone5Width:0.0
                                                      iphone6Width:0.0
                                                  iphone6PlusWidth:0.0
                                                              ipad:5.0];
    CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:setLoggedAtTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:[RUIUtils contentPanelTopPadding]
                hpadding:0.0];
    totalHeight += setLoggedAtTableView.frame.size.height + [RUIUtils contentPanelTopPadding];
    [PEUIUtils placeView:ignoreTimePanel
                   below:setLoggedAtTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += ignoreTimePanel.frame.size.height + 0.0;
    [PEUIUtils placeView:ignoreTimeMsgLabel
                   below:ignoreTimePanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:4.0
                hpadding:8.0 + iphoneXSafeInsetsSideVal];
    totalHeight += ignoreTimeMsgLabel.frame.size.height + 4.0;
    [PEUIUtils placeView:movementTableView
                   below:ignoreTimeMsgLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:15.0
                hpadding:0.0];
    totalHeight += movementTableView.frame.size.height + 15.0;
    [PEUIUtils placeView:movementVariantTableView
                   below:movementTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += movementVariantTableView.frame.size.height;
    [PEUIUtils placeView:weightPanel
                   below:movementVariantTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    totalHeight += weightPanel.frame.size.height + 15.0;
    [PEUIUtils placeView:weightUomTableView
                   below:weightPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    totalHeight += weightUomTableView.frame.size.height + 5.0;
    [PEUIUtils placeView:sectionPanel
                   below:weightUomTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    totalHeight += sectionPanel.frame.size.height + 15.0;
    [PEUIUtils placeView:originationPanel
                   below:sectionPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += originationPanel.frame.size.height + 20.0;
    if (importedAtPanel) {
      [PEUIUtils placeView:importedAtPanel
                     below:originationPanel
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:20.0
                  hpadding:0.0];
      totalHeight += importedAtPanel.frame.size.height + 20.0;
    }
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEEntityPanelMakerBlk)setFormPanelMakerWithDefaultLoggedAtBlk:(NSDate *(^)(void))defaultLoggedAtBlk
                                              defaultMovementBlk:(RMovement *(^)(void))defaultMovementBlk
                                       defaultMovementVariantBlk:(RMovementVariant *(^)(void))defaultMovementVariantBlk
                                             defaultWeightUomBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                                    movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                             movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                               movementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                   mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                   weightTfDefaultedToBodyWeight:(WeightTfDefaultedNotice)weightTfDefaultedToBodyWeight {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    NSDate *loggedAt = [self valueAtTableTag:RSetTagLoggedAt orBlockIfNil:defaultLoggedAtBlk parentView:parentView];
    NSNumber *weightUomId = [self valueAtTableTag:RSetTagWeightUnits orBlockIfNil:defaultWeightUomBlk parentView:parentView];
    RMovement *movement = [self valueAtTableTag:RSetTagMovement orBlockIfNil:defaultMovementBlk parentView:parentView];
    RMovementVariant *movementVariant = [self valueAtTableTag:RSetTagMovementVariant orBlockIfNil:defaultMovementVariantBlk parentView:parentView];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self setFormComponentsWithLoggedAt:loggedAt
                                                        ignoreTime:((UISwitch *)[parentView viewWithTag:RSetTagIgnoreTimeSwitch]).on
                                                          movement:movement
                                                   movementVariant:movementVariant
                                                      movementsBlk:movementsBlk
                                               movementVariantsBlk:movementVariantsBlk
                                                       weightUomId:weightUomId
                                        displayDisclosureIndicator:YES
                                     mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                     weightTfDefaultedToBodyWeight:weightTfDefaultedToBodyWeight
                                                           forView:NO](parentViewController, contentPanel);
    UITableView *setLoggedAtTableView = components[@(RSetTagLoggedAt)];
    UIView *ignoreTimePanel = components[@(RSetTagIgnoreTimePanel)];
    UILabel *ignoreTimeMsgLabel = components[@(RSetTagIgnoreTimeMsgLabel)];
    UITableView *movementTableView = components[@(RSetTagMovement)];
    UITableView *movementVariantTableView = components[@(RSetTagMovementVariant)];
    UITextField *weightTf = components[@(RSetTagWeight)];
    UITableView *weightUomTableView = components[@(RSetTagWeightUnits)];
    UITextField *repsTf = components[@(RSetTagNumReps)];
    UIView *toFailurePanel = components[@(RSetTagToFailurePanel)];
    UIView *negativesPanel = components[@(RSetTagNegativesPanel)];
    UIView *sectionPanel = [PEUIUtils panelWithColumnOfViews:@[repsTf,
                                                               toFailurePanel,
                                                               negativesPanel]
                                 verticalPaddingBetweenViews:10.0
                                              viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    CGFloat vpaddingForTableViews = [PEUIUtils valueIfiPhone5Width:0.0
                                                      iphone6Width:0.0
                                                  iphone6PlusWidth:0.0
                                                              ipad:5.0];
    CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:setLoggedAtTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:[RUIUtils contentPanelTopPadding]
                hpadding:0.0];
    totalHeight += setLoggedAtTableView.frame.size.height + [RUIUtils contentPanelTopPadding];
    [PEUIUtils placeView:ignoreTimePanel
                   below:setLoggedAtTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += ignoreTimePanel.frame.size.height + 0.0;
    [PEUIUtils placeView:ignoreTimeMsgLabel
                   below:ignoreTimePanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:4.0
                hpadding:8.0 + iphoneXSafeInsetsSideVal];
    totalHeight += ignoreTimeMsgLabel.frame.size.height + 4.0;
    [PEUIUtils placeView:movementTableView
                   below:ignoreTimeMsgLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:15.0
                hpadding:0.0];
    totalHeight += movementTableView.frame.size.height + 15.0;
    [PEUIUtils placeView:movementVariantTableView
                   below:movementTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += movementVariantTableView.frame.size.height;
    [PEUIUtils placeView:weightTf
                   below:movementVariantTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    totalHeight += weightTf.frame.size.height + 15.0;
    [PEUIUtils placeView:weightUomTableView
                   below:weightTf
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:4.0
                hpadding:0.0];
    totalHeight += weightUomTableView.frame.size.height + 5.0;
    [PEUIUtils placeView:sectionPanel
                   below:weightUomTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15.0
                hpadding:0.0];
    totalHeight += sectionPanel.frame.size.height + 15.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)setFormPanelToSetBinder {
  return ^ void (UIView *panel, RSet *set) {
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:set withNumberSetter:sel fromTextfieldWithTag:tag fromView:panel];
    };
    [set setLoggedAt:[PEUIUtils valueForSingleTableViewWithTag:RSetTagLoggedAt panel:panel]];
    [set setIgnoreTime:((UISwitch *)[panel viewWithTag:RSetTagIgnoreTimeSwitch]).on];    
    RMovement *movement = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:panel];
    [set setMovementId:movement.localMasterIdentifier];
    RMovementVariant *movementVariant = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovementVariant panel:panel];
    [set setMovementVariantId:movementVariant.localMasterIdentifier];
    NSNumber *origWeightUom = set.weightUom;
    [set setWeightUom:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits panel:panel]];
    [set setWeight:[RUtils weightValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RSetTagWeight fromView:panel]]
                             currentWeightUomId:origWeightUom
                              targetWeightUomId:set.weightUom]];
    bindnum(RSetTagNumReps, @selector(setNumReps:));
    [set setToFailure:((UISwitch *)[panel viewWithTag:RSetTagToFailureSwitch]).on];
    [set setNegatives:((UISwitch *)[panel viewWithTag:RSetTagNegativesSwitch]).on];
  };
}

- (PEEntityToPanelBinderBlk)setToSetPanelBinderWithMovementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                            movementVariantLoaderBlk:(RMovementVariant *(^)(NSNumber *))movementVariantLoaderBlk {
  return ^(RSet *set, UIView *panel) {
    if (set) {
      NSNumberFormatter *formatter = [RUtils weightNumberFormatter];
      void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
        [PEUIUtils bindToTextControlWithTag:tag
                                   fromView:panel
                                 fromEntity:set
                           withNumberGetter:sel
                                  formatter:formatter];
      };
      [PEUIUtils setValueForSingleTableViewWithTag:RSetTagLoggedAt panel:panel value:set.loggedAt];
      UISwitch *sw = (UISwitch *)[panel viewWithTag:RSetTagIgnoreTimeSwitch];
      [sw setOn:[set ignoreTime] animated:NO];     
      [PEUIUtils setValueForSingleTableViewWithTag:RSetTagMovement panel:panel value:movementLoaderBlk(set.movementId)];
      [PEUIUtils setValueForSingleTableViewWithTag:RSetTagMovementVariant panel:panel value:movementVariantLoaderBlk(set.movementVariantId)];
      bindtt(RSetTagWeight, @selector(weight));
      [PEUIUtils setValueForSingleTableViewWithTag:RSetTagWeightUnits panel:panel value:set.weightUom];
      bindtt(RSetTagNumReps, @selector(numReps));
      sw = (UISwitch *)[panel viewWithTag:RSetTagToFailureSwitch];
      [sw setOn:[set toFailure] animated:NO];
      sw = (UISwitch *)[panel viewWithTag:RSetTagNegativesSwitch];
      [sw setOn:[set negatives] animated:NO];
    }
  };
}

- (PEEnableDisablePanelBlk)setFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag fromView:panel enable:enable];
    };
    void (^enabDisabTable)(NSInteger) = ^(NSInteger tag) {
      enabDisab(tag);
      [[panel viewWithTag:tag] setUserInteractionEnabled:enable];
    };
    enabDisabTable(RSetTagLoggedAt);
    enabDisab(RSetTagIgnoreTimeSwitch);
    enabDisabTable(RSetTagMovement);
    if (enable) {
      if ([PEUIUtils valueForSingleTableViewWithTag:RSetTagMovementVariant panel:panel] == nil) {
          [PEUIUtils enableControlWithTag:RSetTagMovementVariant fromView:panel enable:NO];
        [[panel viewWithTag:RSetTagMovementVariant] setUserInteractionEnabled:NO];
      } else {
          enabDisabTable(RSetTagMovementVariant);
      }
    } else {
      enabDisabTable(RSetTagMovementVariant);
    }
    enabDisab(RSetTagWeight);
    enabDisabTable(RSetTagWeightUnits);
    enabDisab(RSetTagNumReps);
    enabDisab(RSetTagNegativesSwitch);
    enabDisab(RSetTagToFailureSwitch);
  };
}

- (PEEntityMakerBlk)setMakerWithOriginationDeviceId:(NSNumber *)originationDeviceId {
  return ^ PELMModelSupport * (UIView *panel) {
    NSNumber *(^tfnum)(NSInteger) = ^ NSNumber * (NSInteger tag) {
      return [PEUIUtils numberFromTextFieldWithTag:tag fromView:panel];
    };
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    RMovement *movement = (RMovement *)[PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:panel];
    NSNumber *movementVariantId = nil;
    RMovementVariant *movementVariant = (RMovementVariant *)[PEUIUtils valueForSingleTableViewWithTag:RSetTagMovementVariant panel:panel];
    if ([PEUtils isNotNil:movementVariant]) {
      movementVariantId = movementVariant.localMasterIdentifier;
    }
    RSet *set =
    [_coordDao setWithNumReps:tfnum(RSetTagNumReps)
                       weight:tfdec(RSetTagWeight)
                    weightUom:[PEUIUtils valueForSingleTableViewWithTag:RSetTagWeightUnits panel:panel]
                    negatives:((UISwitch *)[panel viewWithTag:RSetTagNegativesSwitch]).on
                    toFailure:((UISwitch *)[panel viewWithTag:RSetTagToFailureSwitch]).on
                     loggedAt:[PEUIUtils valueForSingleTableViewWithTag:RSetTagLoggedAt panel:panel]
                   ignoreTime:((UISwitch *)[panel viewWithTag:RSetTagIgnoreTimeSwitch]).on
                   movementId:movement.localMasterIdentifier
            movementVariantId:movementVariantId
          originationDeviceId:originationDeviceId
                   importedAt:nil
              correlationGuid:nil];
    return set;
  };
}

#pragma mark - Body Measurement Log Panel

- (PEComponentsMakerBlk)bmlFormComponentsWithLoggedAt:(NSDate *)loggedAt
                                          weightUomId:(NSNumber *)weightUomId
                                            sizeUomId:(NSNumber *)sizeUomId
                           displayDisclosureIndicator:(BOOL)displayDisclosureIndicator {
  return ^ NSDictionary * (UIViewController *parentViewController, UIView *relativeToView) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UITableView *loggedAtTableView =
    [self makeTableViewWithTag:RBmlTagLoggedAt
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSDate *loggedAt, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                      initialSelectedDate:loggedAt
                                                                                                           datePickerMode:UIDatePickerModeDate
                                                                                                      logDatePickedAction:valPickedAction]();
                                                               }
                                                               pickerScreenTitle:@"Logged at"
                                                                      fieldLabel:@"Logged at"
                                                             fieldValueFormatter:^(NSDate *loggedAt) {
                                                               return [PEUtils stringFromDate:loggedAt withPattern:@"MM/dd/YYYY"];
                                                             }
                                                                           value:loggedAt
                                                               valuePickedAction:^(NSDate *loggedAt) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    components[@(RBmlTagLoggedAt)] = loggedAtTableView;
    CGFloat desiredCommonHeight = [RPanelToolkit rowDataCellHeightWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle] uitoolkit:_uitoolkit];
    TaggedTextfieldMaker tfMaker = [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:relativeToView];
    UITextField *bodyWeightTf = tfMaker(@"Body weight", RBmlTagBodyWeight);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:bodyWeightTf];
    [bodyWeightTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(RBmlTagBodyWeight)] = bodyWeightTf;
    components[@(RBmlTagWeightUom)] =
    [self makeTableViewWithTag:RBmlTagWeightUom
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSNumber *weightUomId, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newWeightUnitsForSelectionScreenMakerWithItemSelectedAction:^(NSArray *weightUom, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(weightUom[0]);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedWeightUom:@[weightUomId, [RUtils weightUnitNameForUomId:weightUomId]]]();
                                                               }
                                                               pickerScreenTitle:@"Weight units"
                                                                      fieldLabel:@"Weight units"
                                                             fieldValueFormatter:^(NSNumber *weightUomId) {
                                                               return [RUtils weightUnitNameForUomId:weightUomId];
                                                             }
                                                                           value:weightUomId
                                                               valuePickedAction:^(NSNumber *newWeightUomId) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    UITextField *armSizeTf = tfMaker(@"Arm size", RBmlTagArmSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:armSizeTf];
    [armSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *chestSizeTf = tfMaker(@"Chest size", RBmlTagChestSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:chestSizeTf];
    [chestSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *calfSizeTf = tfMaker(@"Calf size", RBmlTagCalfSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:calfSizeTf];
    [calfSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *neckSizeTf = tfMaker(@"Neck size", RBmlTagNeckSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:neckSizeTf];
    [neckSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *waistSizeTf = tfMaker(@"Waist size", RBmlTagWaistSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:waistSizeTf];
    [waistSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *thighSizeTf = tfMaker(@"Thigh size", RBmlTagThighSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:thighSizeTf];
    [thighSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *forearmSizeTf = tfMaker(@"Forearm size", RBmlTagForearmSize);
    [PEUIUtils setFrameHeight:desiredCommonHeight ofView:forearmSizeTf];
    [forearmSizeTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(RBmlTagArmSize)] = armSizeTf;
    components[@(RBmlTagChestSize)] = chestSizeTf;
    components[@(RBmlTagCalfSize)] = calfSizeTf;
    components[@(RBmlTagNeckSize)] = neckSizeTf;
    components[@(RBmlTagWaistSize)] = waistSizeTf;
    components[@(RBmlTagThighSize)] = thighSizeTf;
    components[@(RBmlTagForearmSize)] = forearmSizeTf;
    components[@(RBmlTagSizeUom)] =
    [self makeTableViewWithTag:RBmlTagSizeUom
                     numFields:1
       dataSourceDelegateMaker:^(UITableView *tableView) {
         return
         [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:parentViewController
                                                               pickerScreenMaker:^(NSString *title, NSNumber *sizeUomId, void(^valPickedAction)(id)) {
                                                                 return [_screenToolkit newSizeUnitsForSelectionScreenMakerWithItemSelectedAction:^(NSArray *sizeUom, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                   valPickedAction(sizeUom[0]);
                                                                   [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                 } initialSelectedSizeUom:@[sizeUomId, [RUtils sizeUnitNameForUomId:sizeUomId]]]();
                                                               }
                                                               pickerScreenTitle:@"Size units"
                                                                      fieldLabel:@"Size units"
                                                             fieldValueFormatter:^(NSNumber *sizeUomId) {
                                                               return [RUtils sizeUnitNameForUomId:sizeUomId];
                                                             }
                                                                           value:sizeUomId
                                                               valuePickedAction:^(NSNumber *newSizeUomId) {
                                                                 [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];                                                                
                                                               }
                                                      displayDisclosureIndicator:displayDisclosureIndicator
                                                                       labelFont:nil
                                                                       valueFont:nil
                                                                    leftIconName:nil
                                                                  relativeToView:relativeToView];
       }
                relativeToView:relativeToView
          parentViewController:parentViewController];
    return components;
  };
}

- (PEEntityViewPanelMakerBlk)bmlViewPanelMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk {
  return ^ UIView * (PEAddViewEditController *parentViewController, PELMUser *user, RBodyMeasurementLog *bml) {
    UIView *parentView = [parentViewController view];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self bmlFormComponentsWithLoggedAt:bml.loggedAt
                                                       weightUomId:bml.bodyWeightUom
                                                         sizeUomId:bml.sizeUom
                                        displayDisclosureIndicator:NO](parentViewController, contentPanel);
    NSString *(^formatOrNil)(NSNumber *) = [RUtils weightFormatOrNilMaker];
    UITableView *bmlLoggedAtTableView = components[@(RBmlTagLoggedAt)];
    [bmlLoggedAtTableView setUserInteractionEnabled:NO];
    UITableView *bmlWeightUomTableView = components[@(RBmlTagWeightUom)];
    [bmlWeightUomTableView setUserInteractionEnabled:NO];
    NSMutableArray *section2RowData = [NSMutableArray array];
    [section2RowData addObjectsFromArray:@[@[@"Body weight", formatOrNil(bml.bodyWeight)]]];
    UIView *section2RowDataPanel = [self tablePanelWithRowData:section2RowData
                                                     uitoolkit:_uitoolkit
                                                 fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                                    parentView:contentPanel];
    NSMutableArray *section3RowData = [NSMutableArray array];
    [section3RowData addObjectsFromArray:@[@[@"Arm size", formatOrNil(bml.armSize)],
                                           @[@"Chest size", formatOrNil(bml.chestSize)],
                                           @[@"Calf size", formatOrNil(bml.calfSize)],
                                           @[@"Thigh size", formatOrNil(bml.thighSize)],
                                           @[@"Forearm size", formatOrNil(bml.forearmSize)],
                                           @[@"Waist size", formatOrNil(bml.waistSize)],
                                           @[@"Neck size", formatOrNil(bml.neckSize)]]];
    UITableView *bmlSizeUomTableView = components[@(RBmlTagSizeUom)];
    [bmlSizeUomTableView setUserInteractionEnabled:NO];
    UIView *section3RowDataPanel =
    [PEUIUtils panelWithColumnOfViews:@[bmlSizeUomTableView,
                                        [self tablePanelWithRowData:section3RowData
                                                          uitoolkit:_uitoolkit
                                                      fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                                         parentView:contentPanel]]
          verticalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:1.85
                                                        iphone6Width:1.85
                                                    iphone6PlusWidth:5.0
                                                                ipad:5.0]
                       viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *sectionsPanel = [PEUIUtils panelWithColumnOfViews:@[section2RowDataPanel, section3RowDataPanel]
                                  verticalPaddingBetweenViews:20.0
                                               viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *originationPanel = [self originationDevicePanelWithOriginationDevice:originationDevicesBlk()[bml.originationDeviceId]
                                                                      parentView:contentPanel];
    UIView *importedAtPanel = nil;
    if (bml.importedAt) {
      importedAtPanel = [self importedAtPanelWithImportedAt:bml.importedAt entityType:@"body log" parentView:contentPanel];
    }
    CGFloat vpaddingForTableViews = [PEUIUtils valueIfiPhone5Width:0.0
                                                      iphone6Width:0.0
                                                  iphone6PlusWidth:5.0
                                                              ipad:5.0];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:bmlLoggedAtTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:[RUIUtils contentPanelTopPadding]
                hpadding:0.0];
    totalHeight += bmlLoggedAtTableView.frame.size.height + [RUIUtils contentPanelTopPadding];
    [PEUIUtils placeView:bmlWeightUomTableView
                   below:bmlLoggedAtTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0.0];
    totalHeight += bmlWeightUomTableView.frame.size.height + 10.0;
    [PEUIUtils placeView:sectionsPanel
                   below:bmlWeightUomTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += sectionsPanel.frame.size.height;
    [PEUIUtils placeView:originationPanel
                   below:sectionsPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:20.0
                hpadding:0.0];
    totalHeight += originationPanel.frame.size.height + 20.0;
    if (importedAtPanel) {
      [PEUIUtils placeView:importedAtPanel
                     below:originationPanel
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:20.0
                  hpadding:0.0];
      totalHeight += importedAtPanel.frame.size.height + 20.0;
    }
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEEntityPanelMakerBlk)bmlFormPanelMakerWithDefaultLoggedAtBlk:(NSDate *(^)(void))defaultLoggedAtBlk
                                           defaultWeightUomIdBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                             defaultSizeUomIdBlk:(NSNumber *(^)(void))defaultSizeUomBlk {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    NSDate *loggedAt = [self valueAtTableTag:RBmlTagLoggedAt orBlockIfNil:defaultLoggedAtBlk parentView:parentView];
    NSNumber *weightUomId = [self valueAtTableTag:RBmlTagWeightUom orBlockIfNil:defaultWeightUomBlk parentView:parentView];
    NSNumber *sizeUomId = [self valueAtTableTag:RBmlTagSizeUom orBlockIfNil:defaultSizeUomBlk parentView:parentView];
    UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:parentView fixedHeight:0.0];
    NSDictionary *components = [self bmlFormComponentsWithLoggedAt:loggedAt
                                                       weightUomId:weightUomId
                                                         sizeUomId:sizeUomId
                                        displayDisclosureIndicator:YES](parentViewController, contentPanel);
    UITableView *bmlLoggedAtTableView = components[@(RBmlTagLoggedAt)];
    UITableView *bmlWeightUomTableView = components[@(RBmlTagWeightUom)];
    UITextField *bodyWeightTf = components[@(RBmlTagBodyWeight)];
    UITableView *sizeUomTableView = components[@(RBmlTagSizeUom)];
    UITextField *armSizeTf = components[@(RBmlTagArmSize)];
    UITextField *chestSizeTf = components[@(RBmlTagChestSize)];
    UITextField *calfSizeTf = components[@(RBmlTagCalfSize)];
    UITextField *neckSizeTf = components[@(RBmlTagNeckSize)];
    UITextField *waistSizeTf = components[@(RBmlTagWaistSize)];
    UITextField *forearmSizeTf = components[@(RBmlTagForearmSize)];
    UITextField *thighSizeTf = components[@(RBmlTagThighSize)];
    UIView *section2Panel = [PEUIUtils panelWithColumnOfViews:@[bodyWeightTf]
                                  verticalPaddingBetweenViews:5.0
                                               viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *section3Panel =
    [PEUIUtils panelWithColumnOfViews:@[sizeUomTableView,
                                        [PEUIUtils panelWithColumnOfViews:@[armSizeTf,
                                                                            chestSizeTf,
                                                                            calfSizeTf,
                                                                            thighSizeTf,
                                                                            forearmSizeTf,
                                                                            waistSizeTf,
                                                                            neckSizeTf]
                                              verticalPaddingBetweenViews:5.0
                                                           viewsAlignment:PEUIHorizontalAlignmentTypeLeft]]
          verticalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:1.85
                                                        iphone6Width:1.85
                                                    iphone6PlusWidth:5.0
                                                                ipad:5.0]
                       viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *sectionsPanel = [PEUIUtils panelWithColumnOfViews:@[section2Panel, section3Panel]
                                  verticalPaddingBetweenViews:20.0
                                               viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    CGFloat vpaddingForTableViews = [PEUIUtils valueIfiPhone5Width:0.0
                                                      iphone6Width:0.0
                                                  iphone6PlusWidth:5.0
                                                              ipad:5.0];
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:bmlLoggedAtTableView
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:[RUIUtils contentPanelTopPadding]
                hpadding:0.0];
    totalHeight += bmlLoggedAtTableView.frame.size.height + [RUIUtils contentPanelTopPadding];
    [PEUIUtils placeView:bmlWeightUomTableView
                   below:bmlLoggedAtTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0.0];
    totalHeight += bmlWeightUomTableView.frame.size.height + 10.0;
    [PEUIUtils placeView:sectionsPanel
                   below:bmlWeightUomTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:vpaddingForTableViews
                hpadding:0.0];
    totalHeight += sectionsPanel.frame.size.height;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
    return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                         scrolling:YES
                                  forceScrollPanel:NO
                               scrollContentOffset:[parentViewController scrollContentOffset]
                                    scrollDelegate:parentViewController
                              delaysContentTouches:YES
                                           bounces:YES
                                  notScrollViewBlk:^{ [parentViewController resetScrollOffset]; }
                                        controller:parentViewController];
  };
}

- (PEPanelToEntityBinderBlk)bmlFormPanelToBmlBinder {
  return ^ void (UIView *panel, RBodyMeasurementLog *bml) {
    [bml setLoggedAt:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagLoggedAt panel:panel]];
    NSNumber *origUom = bml.bodyWeightUom;
    [bml setBodyWeightUom:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagWeightUom panel:panel]];
    [bml setBodyWeight:[RUtils weightValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagBodyWeight fromView:panel]]
                                 currentWeightUomId:origUom
                                  targetWeightUomId:bml.bodyWeightUom]];
    origUom = bml.sizeUom;
    [bml setSizeUom:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagSizeUom panel:panel]];
    [bml setArmSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagArmSize fromView:panel]]
                              currentSizeUomId:origUom
                               targetSizeUomId:bml.sizeUom]];
    [bml setCalfSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagCalfSize fromView:panel]]
                               currentSizeUomId:origUom
                                targetSizeUomId:bml.sizeUom]];
    [bml setChestSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagChestSize fromView:panel]]
                                currentSizeUomId:origUom
                                 targetSizeUomId:bml.sizeUom]];
    [bml setNeckSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagNeckSize fromView:panel]]
                               currentSizeUomId:origUom
                                targetSizeUomId:bml.sizeUom]];
    [bml setWaistSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagWaistSize fromView:panel]]
                                currentSizeUomId:origUom
                                 targetSizeUomId:bml.sizeUom]];
    [bml setThighSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagThighSize fromView:panel]]
                                currentSizeUomId:origUom
                                 targetSizeUomId:bml.sizeUom]];
    [bml setForearmSize:[RUtils sizeValueWithValue:[PEUtils nullSafeDecimalNumberFromString:[PEUIUtils stringFromTextFieldWithTag:RBmlTagForearmSize fromView:panel]]
                                  currentSizeUomId:origUom
                                   targetSizeUomId:bml.sizeUom]];
  };
}

- (PEEntityToPanelBinderBlk)bmlToBmlPanelBinder {
  NSNumberFormatter *formatter = [RUtils weightNumberFormatter];
  return ^ void (RBodyMeasurementLog *bml, UIView *panel) {
    if (bml) {
      void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
        [PEUIUtils bindToTextControlWithTag:tag
                                   fromView:panel
                                 fromEntity:bml
                           withNumberGetter:sel
                                  formatter:formatter];
      };
      [PEUIUtils setValueForSingleTableViewWithTag:RBmlTagLoggedAt panel:panel value:bml.loggedAt];
      [PEUIUtils setValueForSingleTableViewWithTag:RBmlTagWeightUom panel:panel value:bml.bodyWeightUom];
      bindtt(RBmlTagBodyWeight, @selector(bodyWeight));
      [PEUIUtils setValueForSingleTableViewWithTag:RBmlTagSizeUom panel:panel value:bml.sizeUom];
      bindtt(RBmlTagArmSize, @selector(armSize));
      bindtt(RBmlTagCalfSize, @selector(calfSize));
      bindtt(RBmlTagChestSize, @selector(chestSize));
      bindtt(RBmlTagNeckSize, @selector(neckSize));
      bindtt(RBmlTagWaistSize, @selector(waistSize));
      bindtt(RBmlTagThighSize, @selector(thighSize));
      bindtt(RBmlTagForearmSize, @selector(forearmSize));
    }
  };
}

- (PEEnableDisablePanelBlk)bmlFormPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag fromView:panel enable:enable];
    };
    enabDisab(RBmlTagLoggedAt);
    enabDisab(RBmlTagWeightUom);
    enabDisab(RBmlTagBodyWeight);
    enabDisab(RBmlTagSizeUom);
    enabDisab(RBmlTagArmSize);
    enabDisab(RBmlTagChestSize);
    enabDisab(RBmlTagCalfSize);
    enabDisab(RBmlTagNeckSize);
    enabDisab(RBmlTagWaistSize);
    enabDisab(RBmlTagForearmSize);
    enabDisab(RBmlTagThighSize);
    UITableView *tableView = (UITableView *)[panel viewWithTag:RBmlTagLoggedAt];
    [tableView setUserInteractionEnabled:enable];
    tableView = (UITableView *)[panel viewWithTag:RBmlTagWeightUom];
    [tableView setUserInteractionEnabled:enable];
    tableView = (UITableView *)[panel viewWithTag:RBmlTagSizeUom];
    [tableView setUserInteractionEnabled:enable];
  };
}

- (PEEntityMakerBlk)bmlMakerWithOriginationDeviceId:(NSNumber *)originationDeviceId {
  return ^ PELMModelSupport * (UIView *panel) {
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    RBodyMeasurementLog *bml =
    [_coordDao bmlWithBodyWeight:tfdec(RBmlTagBodyWeight)
                   bodyWeightUom:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagWeightUom panel:panel]
                         armSize:tfdec(RBmlTagArmSize)
                        calfSize:tfdec(RBmlTagCalfSize)
                       chestSize:tfdec(RBmlTagChestSize)
                         sizeUom:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagSizeUom panel:panel]
                        neckSize:tfdec(RBmlTagNeckSize)
                       waistSize:tfdec(RBmlTagWaistSize)
                       thighSize:tfdec(RBmlTagThighSize)
                     forearmSize:tfdec(RBmlTagForearmSize)
                        loggedAt:[PEUIUtils valueForSingleTableViewWithTag:RBmlTagLoggedAt panel:panel]
             originationDeviceId:originationDeviceId
                      importedAt:nil];
    return bml;
  };
}

@end
