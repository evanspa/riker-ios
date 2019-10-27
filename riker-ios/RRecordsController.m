//
//  RRecordsController.m
//  riker-ios
//
//  Created by PEVANS on 11/3/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RRecordsController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <CHCSVParser/CHCSVParser.h>
#import "NSString+RAdditions.h"
#import "RAppNotificationNames.h"
#import "UIColor+RAdditions.h"
#import "PELocalDao.h"
#import "RPanelToolkit.h"
#import "PELMUser.h"
#import "PEUIUtils.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RPanelToolkit.h"
#import "RMovement.h"
#import "RUserSettings.h"
#import "PEUtils.h"
#import "RLogging.h"
@import Firebase;

NSString * const CSV_TRUE_STR = @"true";
NSString * const CSV_FALSE_STR = @"false";

@implementation RRecordsController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RUserSettingsBlk _userSettingsBlk;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  UIButton *_unsyncedEditsBtn;
  UIView *_changelogPanel;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:@[RChangelogDownloadedNotification,
                                                      RAppLoginNotification]
                                         screenTitle:@"Data Records"];
  if (self) {
    _userSettingsBlk = userSettingsBlk;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UIView *msgPanel =  [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"From here you can drill into all of your data records."
                                                                font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                     backgroundColor:[UIColor clearColor]
                                                           textColor:[UIColor darkGrayColor]
                                                 verticalTextPadding:3.0
                                                          fitToWidth:contentPanel.frame.size.width - (leftPadding + 3.0)]
                              padding:leftPadding];
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  CGFloat recordCountFromBottomPadding = [PEUIUtils valueIfiPhone5Width:2.0 iphone6Width:2.0 iphone6PlusWidth:4.0 ipad:8.0];
  CGFloat recordCountLeftPadding = [PEUIUtils valueIfiPhone5Width:6.0 iphone6Width:6.0 iphone6PlusWidth:8.0 ipad:12.0] + iphoneXSafeInsetsSideVal;
  UIButton *setsBtn = [PEUIUtils buttonWithLabel:@"Sets"
                                    tagForButton:nil
                                     recordCount:[_coordDao numSetsForUser:user error:[RUtils localFetchErrorHandlerMaker]()]
                          tagForRecordCountLabel:nil
                               addDisclosureIcon:YES
                       addlVerticalButtonPadding:[PEUIUtils valueIfiPhone5Width:16.0 iphone6Width:18.0 iphone6PlusWidth:22.0 ipad:26.0]
                    recordCountFromBottomPadding:recordCountFromBottomPadding
                          recordCountLeftPadding:recordCountLeftPadding
                                         handler:^{
                                           RAuthScreenMaker setsScreenMaker =
                                           [_screenToolkit newViewSetsScreenMakerWithMovementsBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao movementsWithError:errorBlk]];}
                                                                           allMovementVariantsBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao movementVariantsWithError:errorBlk]];}
                                                                                defaultMovementId:@(DEFAULT_MOVEMENT_ID)
                                                                         defaultMovementVariantId:@(DEFAULT_MOVEMENT_VARIANT_ID)
                                                                    mostRecentBmlWithNonNilWeight:[_coordDao mostRecentBmlWithNonNilWeightForUser:user error:errorBlk]
                                                                              movementVariantsBlk:^(RMovement *movement) {
                                                                                NSArray *movementVariants = [_coordDao movementVariantsWithError:errorBlk];
                                                                                return [RUtils dictFromMasterEntitiesArray:[RUtils filterMovementVariants:movementVariants usingMask:movement.variantMask.integerValue]];
                                                                              }
                                                                            originationDevicesBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:errorBlk]];}];
                                           [PEUIUtils displayController:setsScreenMaker()
                                                         fromController:self
                                                               animated:YES];
                                         }
                                       uitoolkit:_uitoolkit
                                  relativeToView:contentPanel];
  [PEUIUtils styleViewForIpad:setsBtn];
  UIButton *(^makeImpExpButton)(NSString *) = ^UIButton *(NSString *title) {
    return [PEUIUtils buttonWithKey:title
                               font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:32.0]
                                                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                    backgroundColor:[UIColor rikerAppBlackSemiClear]
                          textColor:[UIColor whiteColor]
       disabledStateBackgroundColor:nil
             disabledStateTextColor:nil
                    verticalPadding:[PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:10.0 iphone6PlusWidth:14.0 ipad:18.0]
                  horizontalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:20.0 iphone6PlusWidth:24.0 ipad:28.0]
                       cornerRadius:3.0
                             target:nil
                             action:nil];
  };
  void (^doExport)(NSString *, NSString *, NSInteger(^)(void), void(^)(NSString *, NSString *, PELMUser *)) = ^(NSString *fileNamePart, NSString *entityType, NSInteger(^recordCounter)(void), void(^exporter)(NSString *, NSString *, PELMUser *)) {
    if (recordCounter() > 0) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"yyyy-MM-dd"];
      NSDate *now = [NSDate date];
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      hud.tag = RHUD_TAG;
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [paths objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"riker-%@-%@.csv", fileNamePart, [dateFormatter stringFromDate:now]];
        PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
        exporter(docsDir, fileName, user);
        dispatch_async(dispatch_get_main_queue(), ^{
          [MBProgressHUD hideHUDForView:self.view animated:YES];
          NSMutableAttributedString *instructions = [[NSMutableAttributedString alloc] init];
          [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"To download this file to your computer, connect your device to %@, click on your device, navigate to "
                                                                        textToAccent:@"iTunes"
                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
          [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and scroll down to the "
                                                                        textToAccent:@"Apps"
                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
          [instructions appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ section.  You'll see Riker listed.  Click on Riker and you'll be able to see and download your data files."
                                                                        textToAccent:@"File Sharing"
                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
          [PEUIUtils showSuccessAlertWithMsgs:@[fileName]
                                        title:@"Export Complete."
                             alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your Riker %@ data has been exported to the following CSV file.", entityType]]
                          descLblHeightAdjust:0.0
                    additionalContentSections:@[[PEUIUtils infoAlertSectionWithTitle:@"Tip"
                                                                    alertDescription:instructions
                                                                 descLblHeightAdjust:0.0
                                                                      relativeToView:[PEUIUtils parentViewForAlertsForController:self]],
                                                [PEUIUtils infoAlertSectionWithTitle:@"Share"
                                                                    alertDescription:AS(@"The next screen will give you the option to share / save your CSV file to an external location.")
                                                                 descLblHeightAdjust:0.0
                                                                      relativeToView:[PEUIUtils parentViewForAlertsForController:self]]]
                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                   [PEUIUtils showConfirmAlertWithTitle:@"Share?"
                                                             titleImage:nil
                                                       alertDescription:AS(@"Would you like to share your CSV file?  You can email it, AirDrop it or save it to an external location.")
                                                    descLblHeightAdjust:0.0
                                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                        okayButtonTitle:@"Share"
                                                       okayButtonAction:^{
                                                          UIActivityViewController *activityViewController =
                                                          [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:fileName]]]
                                                                                            applicationActivities:nil];
                                                          [self.navigationController presentViewController:activityViewController
                                                                                                  animated:YES
                                                                                                completion:nil];
                                                        }
                                                        okayButtonStyle:JGActionSheetButtonStyleBlue
                                                      cancelButtonTitle:@"Cancel"
                                                     cancelButtonAction:^{
                                                       
                                                     }
                                                       cancelButtonSyle:JGActionSheetButtonStyleCancel
                                                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                 }
                               relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
        });
      });
    } else {
      [PEUIUtils showWarningAlertWithMsgs:nil
                                    title:[NSString stringWithFormat:@"You have no %@ records to export.", entityType]
                         alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"You do not currently have any %@ records to export at this time.", entityType]]
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:^{}
                           relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    }
  };
  
  void (^doImport)(NSString *,
                   NSString *,
                   NSString *,
                   id(^)(NSArray *, NSNumberFormatter *, NSDate *),
                   void(^)(NSArray *),
                   NSInteger,
                   NSArray *(^)(NSArray *, NSNumberFormatter *)) = ^(NSString *entityType,
                                                                     NSString *entityTypeAbbrev,
                                                                     NSString *fileNameContains,
                                                                     id(^makeEntity)(NSArray *, NSNumberFormatter *, NSDate *),
                                                                     void(^saveEntities)(NSArray *),
                                                                     NSInteger expectedNumColumns,
                                                                     NSArray *(^validateCsvEntity)(NSArray *, NSNumberFormatter *)) {
    [self presentViewController:[PEUIUtils navigationControllerWithController:[_screenToolkit newImportFilePickerScreenMakerWithItemSelectedAction:^(NSString *file, NSIndexPath *indexPath, UIViewController *controller, UITableView *tableView) {
      MBProgressHUD *outerHud = [MBProgressHUD showHUDAddedTo:[PEUIUtils parentViewForAlertsForController:controller] animated:YES];
      outerHud.tag = RHUD_TAG;
      UIFont *boldFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
      NSDictionary *paragraphBeforeSpacingAttrs = [PEUIUtils paragraphBeforeSpacingAttrs];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DDLogDebug(@"file: %@", file);
        NSArray *csvEntities = [NSArray arrayWithContentsOfCSVURL:[NSURL fileURLWithPath:file]];
        NSInteger numCsvSets = [csvEntities count] - 1;  // minus 1 so we don't count the header row
        if (numCsvSets > 0) {
          void(^problemPromptDeleteFile)(NSAttributedString *) = ^(NSAttributedString *desc) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [outerHud hideAnimated:YES];
              [PEUIUtils showWarningConfirmAlertWithTitle:@"Problem with import file."
                                         alertDescription:desc
                                      descLblHeightAdjust:0.0
                                                 topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                          okayButtonTitle:@"Remove file."
                                         okayButtonAction:^{
                                           [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                                           [PEUIUtils showInfoAlertWithTitle:@"File removed."
                                                            alertDescription:AS(@"Your import file has been deleted.")
                                                         descLblHeightAdjust:0.0
                                                   additionalContentSections:nil
                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                 buttonTitle:@"Okay."
                                                                buttonAction:^{
                                                                  [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                                                  [controller dismissViewControllerAnimated:YES completion:nil];
                                                                }
                                                              relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                         }
                                        cancelButtonTitle:@"Keep file."
                                       cancelButtonAction:^{
                                         [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                       }
                                           relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
            });
          };
          NSMutableAttributedString *(^makeProblemDesc)(void) = ^NSMutableAttributedString * {
            NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
            [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your import file, %@, has a problem with it and could not be imported.\n\n"
                                                                  textToAccent:[file lastPathComponent]
                                                                accentTextFont:boldFont]];
            return desc;
          };
          void (^appendShouldHave)(NSMutableAttributedString *) = ^(NSMutableAttributedString *problemDesc) {
            [problemDesc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ import files should have ", [entityType sentenceCase]]]];
          };
          NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
          f.numberStyle = NSNumberFormatterDecimalStyle;
          NSMutableAttributedString *problemDesc = nil;
          NSArray *headerRow = csvEntities[0];
          if (headerRow.count == expectedNumColumns) {
            for (NSInteger i = 1; i < csvEntities.count && problemDesc == nil; i++) {
              NSArray *csvEntity = csvEntities[i];
              if (csvEntity.count == expectedNumColumns) {
                NSArray *validationResult = validateCsvEntity(csvEntity, f);
                BOOL isValid = [validationResult[0] boolValue];
                BOOL isRefDataPresent = [validationResult[1] boolValue];
                if (!isValid) {
                  problemDesc = makeProblemDesc();
                  NSNumberFormatter *formatter = [NSNumberFormatter new];
                  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                  [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Row %@ contains invalid data."
                                                                               textToAccent:[NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(i)]]
                                                                             accentTextFont:boldFont]];
                  [RUtils logEvent:[NSString stringWithFormat:@"%@_import_failed_invalid_data", entityTypeAbbrev]];
                } else if (!isRefDataPresent) {
                  NSString *action;
                  if ([APP isUserLoggedIn]) {
                    action = @"\n\nPlease synchronize your account and try this again.  If you're still facing this issue after synchronizing, then there is probably something wrong with your import file.";
                  } else {
                    action = @"\n\nPlease download the latest verion of Riker from the App Store and try this again.  If you're still facing this issue after updating Riker from the App Store, then there is probably something wrong with your import file.";
                  }
                  [RUtils logEvent:[NSString stringWithFormat:@"%@_import_failed_ref_data_not_present", entityTypeAbbrev]];
                  problemDesc = makeProblemDesc();
                  NSNumberFormatter *formatter = [NSNumberFormatter new];
                  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                  [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Row %@ "
                                                                               textToAccent:[NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(i)]]
                                                                             accentTextFont:boldFont]];
                  [problemDesc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ that is not currently present on this device.  ", validationResult[2]]]];
                  [problemDesc appendAttributedString:[[NSAttributedString alloc] initWithString:action]];
                }
              } else {
                problemDesc = makeProblemDesc();
                appendShouldHave(problemDesc);
                NSNumberFormatter *formatter = [NSNumberFormatter new];
                [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ columns.  Row "
                                                                             textToAccent:[NSString stringWithFormat:@"%ld", (long)expectedNumColumns]
                                                                           accentTextFont:boldFont]];
                [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ has "
                                                                             textToAccent:[NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(i)]]
                                                                           accentTextFont:boldFont]];
                [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ columns."
                                                                             textToAccent:[NSString stringWithFormat:@"%lu", (unsigned long)csvEntity.count]
                                                                           accentTextFont:boldFont]];
                [RUtils logEvent:[NSString stringWithFormat:@"%@_import_failed_wrong_num_data_cols", entityTypeAbbrev]];
              }
            }
          } else {
            problemDesc = makeProblemDesc();
            appendShouldHave(problemDesc);
            [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ header columns.  Yours has "
                                                                         textToAccent:[NSString stringWithFormat:@"%ld", (long)expectedNumColumns]
                                                                       accentTextFont:boldFont]];
            [problemDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@."
                                                                         textToAccent:[NSString stringWithFormat:@"%lu", (unsigned long)headerRow.count]
                                                                       accentTextFont:boldFont]];
            [RUtils logEvent:[NSString stringWithFormat:@"%@_import_failed_ref_wrong_num_hdr_cols", entityTypeAbbrev]];
          }
          if ([PEUtils isNil:problemDesc]) {
            NSMutableAttributedString *description = [[NSMutableAttributedString alloc] init];
            [description appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"The file you selected,\n%@,\ncontains "
                                                                         textToAccent:[file lastPathComponent]
                                                                       accentTextFont:boldFont]];
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [description appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@.\nAre you sure you want to import "
                                                                         textToAccent:[NSString stringWithFormat:@"%@ %@ record%@", [formatter stringFromNumber:@(numCsvSets)], entityType, numCsvSets > 1 ? @"s" : @""]
                                                                       accentTextFont:boldFont
                                                                                attrs:paragraphBeforeSpacingAttrs]];
            [description appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@?", numCsvSets > 1 ? @"these records" : @"this record"]]];
            dispatch_async(dispatch_get_main_queue(), ^{
              [outerHud hideAnimated:YES];
              [PEUIUtils showConfirmAlertWithTitle:@"Confirm Import"
                                        titleImage:[UIImage imageNamed:@"info"]
                                  alertDescription:description
                               descLblHeightAdjust:0.0
                                          topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                   okayButtonTitle:@"Do Import"
                                  okayButtonAction:^{
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[PEUIUtils parentViewForAlertsForController:controller]
                                                                              animated:YES];
                                    hud.tag = RHUD_TAG;
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      NSDate *now = [NSDate date];
                                      NSMutableArray *entities = [NSMutableArray arrayWithCapacity:numCsvSets];
                                      for (NSInteger i = 1; i < csvEntities.count; i++) {
                                        NSArray *csvEntity = csvEntities[i];
                                        id entity = makeEntity(csvEntity, f, now);
                                        [entities addObject:entity];
                                      }
                                      saveEntities(entities);
                                      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                      [RUtils logEvent:[NSString stringWithFormat:@"%@_import_success", entityTypeAbbrev]
                                                params:@{@"num_imported" : @(entities.count)}];
                                      NSString *newFileName = [file stringByAppendingString:@".imported"];
                                      NSFileManager *fileManager = [NSFileManager defaultManager];
                                      [fileManager removeItemAtPath:newFileName error:nil]; // make sure existing file doesn't already exist
                                      [fileManager moveItemAtPath:file toPath:newFileName error:nil];
                                      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
                                      [desc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@%@ been imported successfully.\n\nYour import file:\n", entityType, numCsvSets > 1 ? @"s have" : @" has"]]];
                                      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@,\nhas been renamed to: "
                                                                                            textToAccent:[file lastPathComponent]
                                                                                          accentTextFont:boldFont]];
                                      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@.\n\nIt will no longer appear in your available files to import, but will still be available to access through iTunes."
                                                                                            textToAccent:[newFileName lastPathComponent]
                                                                                          accentTextFont:boldFont]];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        [hud hideAnimated:YES];
                                        [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@%@ Imported", entityType.sentenceCase, numCsvSets > 0 ? @"s" : @""]
                                                            alertDescription:desc
                                                         descLblHeightAdjust:0.0
                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                                                 buttonTitle:@"Okay"
                                                                buttonAction:^{
                                                                  [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                                                  [[NSNotificationCenter defaultCenter] postNotificationName:RImportCompleteNotification
                                                                                                                      object:self
                                                                                                                    userInfo:nil];
                                                                  [controller dismissViewControllerAnimated:YES completion:^{ [APP refreshTabs]; }];
                                                                }
                                                              relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
                                      });
                                    });
                                  }
                                   okayButtonStyle:JGActionSheetButtonStyleBlue
                                 cancelButtonTitle:@"Cancel"
                                cancelButtonAction:^{
                                  [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                }
                                  cancelButtonSyle:JGActionSheetButtonStyleCancel
                                    relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
            });
          } else {
            problemPromptDeleteFile(problemDesc);
          }
        } else {
          [RUtils logEvent:[NSString stringWithFormat:@"%@_import_failed_empty_file", entityTypeAbbrev]];
          NSMutableAttributedString *description = [[NSMutableAttributedString alloc] init];
          [description appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"The file you selected, %@,\ncontains no "
                                                                       textToAccent:[file lastPathComponent]
                                                                     accentTextFont:boldFont
                                                                              attrs:paragraphBeforeSpacingAttrs]];
          [description appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ records.", entityType]]];
          dispatch_async(dispatch_get_main_queue(), ^{
            [outerHud hideAnimated:YES];
            [PEUIUtils showWarningAlertWithMsgs:nil
                                          title:@"No Records Found"
                               alertDescription:description
                            descLblHeightAdjust:0.0
                                       topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                                    buttonTitle:@"Okay"
                                   buttonAction:^{
                                     [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                   }
                                 relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
          });
        }
      });
    }
                                                                                                                                       screenTitle:[NSString stringWithFormat:@"%@ Import - Choose File", [entityType sentenceCase]]
                                                                                                                                  fileNameContains:fileNameContains]()
                                                          navigationBarHidden:NO]
                       animated:YES
                     completion:^{}];
  };
  
  UIButton *(^makeImpExpHelpBtn)(NSString *, NSString *, CGFloat) = ^UIButton *(NSString *entityType, NSString *entityTypeAbbrev, CGFloat size) {
    UIButton *aboutImpExpInfoBtn = [PEUIUtils buttonWithKey:@"i"
                                                       font:[PEUIUtils infoIconFont]
                                            backgroundColor:[UIColor rikerAppBlackSemiClear]
                                                  textColor:[UIColor whiteColor]
                               disabledStateBackgroundColor:nil
                                     disabledStateTextColor:nil
                                            verticalPadding:3.0
                                          horizontalPadding:3.0
                                               cornerRadius:size * 0.5
                                                     target:nil
                                                     action:nil];
    [PEUIUtils setFrameWidth:size ofView:aboutImpExpInfoBtn];
    [PEUIUtils setFrameHeight:size ofView:aboutImpExpInfoBtn];
    [aboutImpExpInfoBtn bk_addEventHandler:^(id sender) {
      [RUtils logHelpInfoPopupContentViewed:[NSString stringWithFormat:@"import_export_%@_info", entityTypeAbbrev]];
      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
      [desc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Riker supports importing and exporting of your %@ data via ", entityType]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@."
                                                            textToAccent:@"iTunes File Sharing"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nTo download your export file to your computer, connect your device to %@, click on your device, navigate to "
                                                            textToAccent:@"iTunes"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and scroll down to the "
                                                            textToAccent:@"Apps"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ section.  You'll see Riker listed.  Click on Riker and you'll be able to see and download your data files."
                                                            textToAccent:@"File Sharing"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nTo import a file, add the CSV file to Riker through iTunes, and from within Riker, click the %@ button."
                                                            textToAccent:@"import"
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [PEUIUtils showInfoAlertWithTitle:@"Import / Export"
                       alertDescription:desc
                    descLblHeightAdjust:0.0
              additionalContentSections:nil
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay"
                           buttonAction:^{}
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    } forControlEvents:UIControlEventTouchUpInside];
    return aboutImpExpInfoBtn;
  };
  UIButton *exportSetsBtn = makeImpExpButton(@"export");
  [exportSetsBtn bk_addEventHandler:^(id sender) {
    doExport(@"sets",
             @"set",
             ^NSInteger { return [_coordDao numSetsForUser:user error:[RUtils localFetchErrorHandlerMaker]()]; },
             ^(NSString *docsDir, NSString *fileName, PELMUser *user) {
               [_coordDao exportWithPathToSetsFile:[docsDir stringByAppendingPathComponent:fileName]
                                              user:user
                                             error:[RUtils localFetchErrorHandlerMaker]()];
             });
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *importSetsBtn = makeImpExpButton(@"import");
  BOOL(^isEmptyOrNull)(NSString *) = ^BOOL (NSString *str) {
    return [[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 ||
    [str isEqualToString:@"null"];
  };
  [importSetsBtn bk_addEventHandler:^(id sender) {
    NSDictionary *movements = [RUtils dictFromMasterEntitiesArray:[_coordDao movementsWithError:errorBlk]];
    NSDictionary *movementVariants = [RUtils dictFromMasterEntitiesArray:[_coordDao movementVariantsWithError:errorBlk]];
    NSDictionary *originationDevices = [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:errorBlk]];
    doImport(@"set",
             @"set",
             @"sets",
             ^RSet *(NSArray *csvEntity, NSNumberFormatter *f, NSDate *now) {
      return [_coordDao setWithNumReps:[f numberFromString:csvEntity[12]]
                                weight:[NSDecimalNumber decimalNumberWithString:csvEntity[6]]
                             weightUom:[f numberFromString:csvEntity[8]]
                             negatives:[csvEntity[10] isEqualToString:CSV_TRUE_STR]
                             toFailure:[csvEntity[9] isEqualToString:CSV_TRUE_STR]
                              loggedAt:[self dateFromQuotedUnixTimeString:csvEntity[1] numberFormatter:f]
                            ignoreTime:[csvEntity[11] isEqualToString:CSV_TRUE_STR]
                            movementId:[f numberFromString:csvEntity[3]]
                     movementVariantId:isEmptyOrNull(csvEntity[5]) ? nil : [f numberFromString:csvEntity[5]]
                   originationDeviceId:[f numberFromString:csvEntity[14]]
                            importedAt:now
                       correlationGuid:nil];
    },
             ^(NSArray *entities) {
               [_coordDao saveNewSets:entities
                              forUser:user
                                error:[RUtils localSaveErrorHandlerMaker]()];
             },
             15,
             ^NSArray *(NSArray *csvEntity, NSNumberFormatter *f) {
               BOOL(^isNum)(NSString *) = ^BOOL (NSString *str) {
                 return [f numberFromString:str] != nil;
               };
               BOOL(^isNumOrEmpty)(NSString *) = ^BOOL (NSString *str) {
                 return isNum(str) || isEmptyOrNull(str);
               };
               BOOL(^isBool)(NSString *) = ^BOOL (NSString *str) {
                 return [str isEqualToString:CSV_TRUE_STR] || [str isEqualToString:CSV_FALSE_STR];
               };
               BOOL isValid = YES;
               BOOL isRefDataPresent = YES;
               NSString *refErrorMessage = @"";
               NSString *unixTimeStr = [csvEntity[1] stringByReplacingOccurrencesOfString:@"'" withString:@""];
               isValid = isValid && [unixTimeStr length] > 0;
               isValid = isValid && isNumOrEmpty(unixTimeStr);
               isValid = isValid && isNum(csvEntity[3]);
               isValid = isValid && isNumOrEmpty(csvEntity[5]);
               isValid = isValid && isNum(csvEntity[6]);
               isValid = isValid && isNumOrEmpty(csvEntity[8]);
               isValid = isValid && isBool(csvEntity[9]);
               isValid = isValid && isBool(csvEntity[10]);
               isValid = isValid && isBool(csvEntity[11]);
               isValid = isValid && isNum(csvEntity[12]);
               isValid = isValid && isNumOrEmpty(csvEntity[14]);
               if (isValid && isRefDataPresent) {
                 // check if movement is present locally
                 if (movements[[f numberFromString:csvEntity[3]]] == nil) {
                   isRefDataPresent = NO;
                   refErrorMessage = @"references a movement";
                 }
               }
               if (isValid && isRefDataPresent) {
                 // check if movement variant is present locally
                 if (!isEmptyOrNull(csvEntity[5]) && movementVariants[[f numberFromString:csvEntity[5]]] == nil) {
                   isRefDataPresent = NO;
                   refErrorMessage = @"references a movement variant";
                 }
               }
               if (isValid && isRefDataPresent) {
                 // check if origination device is present locally
                 if (originationDevices[[f numberFromString:csvEntity[14]]] == nil) {
                   isRefDataPresent = NO;
                   refErrorMessage = @"references Riker system data";
                 }
               }
               return @[@(isValid), @(isRefDataPresent), refErrorMessage];
             });
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *aboutSetsInfoBtn = makeImpExpHelpBtn(@"set", @"set", importSetsBtn.frame.size.height * 0.95);
  UIButton *bmlsBtn = [PEUIUtils buttonWithLabel:@"Body Logs"
                                    tagForButton:nil
                                     recordCount:[_coordDao numBmlsForUser:user error:[RUtils localFetchErrorHandlerMaker]()]
                          tagForRecordCountLabel:nil
                               addDisclosureIcon:YES
                       addlVerticalButtonPadding:[PEUIUtils valueIfiPhone5Width:16.0 iphone6Width:18.0 iphone6PlusWidth:22.0 ipad:26.0]
                    recordCountFromBottomPadding:recordCountFromBottomPadding
                          recordCountLeftPadding:recordCountLeftPadding
                                         handler:^{
                                           [PEUIUtils displayController:[_screenToolkit newViewBmlsScreenMakerWithOriginationDevicesBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:[RUtils localFetchErrorHandlerMaker]()]];}]()
                                                         fromController:self
                                                               animated:YES];
                                         }
                                       uitoolkit:_uitoolkit
                                  relativeToView:contentPanel];
  [PEUIUtils styleViewForIpad:bmlsBtn];
  UIButton *exportBmlsBtn = makeImpExpButton(@"export");
  [exportBmlsBtn bk_addEventHandler:^(id sender) {
    doExport(@"body-logs",
             @"body log",
             ^NSInteger { return [_coordDao numBmlsForUser:user error:[RUtils localFetchErrorHandlerMaker]()]; },
             ^(NSString *docsDir, NSString *fileName, PELMUser *user) {
               [_coordDao exportWithPathToBodyMeasurementLogsFile:[docsDir stringByAppendingPathComponent:fileName]
                                                             user:user
                                                            error:[RUtils localFetchErrorHandlerMaker]()];
             });
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *importBmlsBtn = makeImpExpButton(@"import");
  [importBmlsBtn bk_addEventHandler:^(id sender) {      
    NSDictionary *originationDevices = [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:errorBlk]];
    doImport(@"body log",
             @"bml",
             @"body-logs",
             ^RBodyMeasurementLog *(NSArray *csvEntity, NSNumberFormatter *f, NSDate *now) {
               return [_coordDao bmlWithBodyWeight:isEmptyOrNull(csvEntity[2]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[2]]
                                     bodyWeightUom:[f numberFromString:csvEntity[4]]
                                           armSize:isEmptyOrNull(csvEntity[7]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[7]]
                                          calfSize:isEmptyOrNull(csvEntity[5]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[5]]
                                         chestSize:isEmptyOrNull(csvEntity[6]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[6]]
                                           sizeUom:[f numberFromString:csvEntity[13]]
                                          neckSize:isEmptyOrNull(csvEntity[8]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[8]]
                                         waistSize:isEmptyOrNull(csvEntity[9]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[9]]
                                         thighSize:isEmptyOrNull(csvEntity[10]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[10]]
                                       forearmSize:isEmptyOrNull(csvEntity[11]) ? nil : [NSDecimalNumber decimalNumberWithString:csvEntity[11]]
                                          loggedAt:[self dateFromQuotedUnixTimeString:csvEntity[1] numberFormatter:f]
                               originationDeviceId:[f numberFromString:csvEntity[15]]
                                        importedAt:now];
             },
             ^(NSArray *entities) {
               [_coordDao saveNewBmls:entities forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
             },
             16,
             ^NSArray *(NSArray *csvEntity, NSNumberFormatter *f) {
               BOOL(^isNum)(NSString *) = ^BOOL (NSString *str) {
                 return [f numberFromString:str] != nil;
               };
               BOOL(^isNumOrEmpty)(NSString *) = ^BOOL (NSString *str) {
                 return isNum(str) || isEmptyOrNull(str);
               };
               BOOL isValid = YES;
               BOOL isRefDataPresent = YES;
               NSString *refErrorMessage = @"";
               NSString *unixTimeStr = [csvEntity[1] stringByReplacingOccurrencesOfString:@"'" withString:@""];
               isValid = isValid && [unixTimeStr length] > 0;
               isValid = isValid && isNumOrEmpty(unixTimeStr);
               isValid = isValid && isNumOrEmpty(csvEntity[2]);
               isValid = isValid && isNumOrEmpty(csvEntity[4]);
               isValid = isValid && isNumOrEmpty(csvEntity[5]);
               isValid = isValid && isNumOrEmpty(csvEntity[6]);
               isValid = isValid && isNumOrEmpty(csvEntity[7]);
               isValid = isValid && isNumOrEmpty(csvEntity[8]);
               isValid = isValid && isNumOrEmpty(csvEntity[9]);
               isValid = isValid && isNumOrEmpty(csvEntity[10]);
               isValid = isValid && isNumOrEmpty(csvEntity[11]);
               isValid = isValid && isNumOrEmpty(csvEntity[13]);
               isValid = isValid && isNumOrEmpty(csvEntity[15]);
               if (isValid && isRefDataPresent) {
                 // check if origination device is present locally
                 if (originationDevices[[f numberFromString:csvEntity[15]]] == nil) {
                   isRefDataPresent = NO;
                   refErrorMessage = @"references Riker system data";
                 }
               }
               return @[@(isValid), @(isRefDataPresent), refErrorMessage];
             });
  } forControlEvents:UIControlEventTouchUpInside];
  UIButton *aboutBmlsInfoBtn = makeImpExpHelpBtn(@"body log", @"bml", importBmlsBtn.frame.size.height);
  [PEUIUtils placeView:msgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = msgPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:setsBtn
                 below:msgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:10.0
              hpadding:0.0];
  totalHeight += setsBtn.frame.size.height + 10.0;
  [PEUIUtils placeView:importSetsBtn
                 below:setsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:4.0 + iphoneXSafeInsetsSideVal];
  totalHeight += importSetsBtn.frame.size.height + 5.0;
  [PEUIUtils placeView:exportSetsBtn toTheRightOf:importSetsBtn onto:contentPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  [PEUIUtils placeView:aboutSetsInfoBtn toTheRightOf:exportSetsBtn onto:contentPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  [PEUIUtils placeView:bmlsBtn
                 below:importSetsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:18.0
              hpadding:0.0];
  totalHeight += bmlsBtn.frame.size.height + 18.0;
  [PEUIUtils placeView:importBmlsBtn
                 below:bmlsBtn
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:4.0 + iphoneXSafeInsetsSideVal];
  totalHeight += importBmlsBtn.frame.size.height + 5.0;
  [PEUIUtils placeView:exportBmlsBtn toTheRightOf:importBmlsBtn onto:contentPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  [PEUIUtils placeView:aboutBmlsInfoBtn toTheRightOf:exportBmlsBtn onto:contentPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  [_unsyncedEditsBtn removeFromSuperview];
  [_changelogPanel removeFromSuperview];
  if ([APP isUserLoggedIn]) {
    NSInteger numUnsynced = [_coordDao totalNumUnsyncedEntitiesForUser:user];
    UIView *changelogAboveView = importBmlsBtn;
    if (numUnsynced > 0) {
      _unsyncedEditsBtn = [self unsyncedEditsButtonWithBadgeNum:numUnsynced relativeToView:contentPanel];
      [PEUIUtils placeView:_unsyncedEditsBtn below:importBmlsBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:35.0 hpadding:0.0];
      UIView *unsyncedMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Heads up.  You have some unsynced local edits."
                                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                backgroundColor:[UIColor clearColor]
                                                                      textColor:[UIColor darkGrayColor]
                                                            verticalTextPadding:3.0
                                                                     fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)]
                                                padding:8.0 + iphoneXSafeInsetsSideVal];
      totalHeight += _unsyncedEditsBtn.frame.size.height + 35.0;
      [PEUIUtils placeView:unsyncedMsgPanel below:_unsyncedEditsBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:4.0 hpadding:0.0];
      totalHeight += unsyncedMsgPanel.frame.size.height + 4.0;
      changelogAboveView = unsyncedMsgPanel;
    } else {
      NSString *labelText = @"No unsynced local edits";
      UIFont *labelFont = _uitoolkit.fontForButtonsBlk();
      UILabel *noUnsyncedLabel = [PEUIUtils labelWithKey:labelText
                                                    font:labelFont
                                         backgroundColor:[UIColor clearColor]
                                               textColor:[UIColor darkTextColor]
                                     verticalTextPadding:_uitoolkit.verticalPaddingForButtons];
      CGSize textSize = [PEUIUtils sizeOfText:labelText withFont:labelFont];
      UIView *noUnsyncedPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:textSize.height + _uitoolkit.verticalPaddingForButtons];
      [noUnsyncedPanel setBackgroundColor:[UIColor whiteColor]];
      UIImageView *greenCheckmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green-filled-checkmark-icon"]];
      UIView *noUnsyncedMsgPanel = [PEUIUtils leftPadView:[PEUIUtils labelWithKey:@"Good news.  You have no unsynced local edits."
                                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                  backgroundColor:[UIColor clearColor]
                                                                        textColor:[UIColor darkGrayColor]
                                                              verticalTextPadding:3.0
                                                                       fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)]
                                                  padding:8.0 + iphoneXSafeInsetsSideVal];
      [PEUIUtils styleViewForIpad:noUnsyncedPanel];
      [PEUIUtils placeView:[PEUIUtils panelWithRowOfViews:@[greenCheckmark, noUnsyncedLabel]
                            horizontalPaddingBetweenViews:10.0
                                           viewsAlignment:PEUIVerticalAlignmentTypeMiddle]
                inMiddleOf:noUnsyncedPanel
             withAlignment:PEUIHorizontalAlignmentTypeCenter
                  hpadding:0.0];
      [PEUIUtils placeView:noUnsyncedPanel below:importBmlsBtn onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:35.0 hpadding:0.0];
      totalHeight += noUnsyncedPanel.frame.size.height + 35.0;
      [PEUIUtils placeView:noUnsyncedMsgPanel below:noUnsyncedPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:4.0 hpadding:0.0];
      totalHeight += noUnsyncedMsgPanel.frame.size.height + 4.0;
      changelogAboveView = noUnsyncedMsgPanel;
    }
    _changelogPanel = [_panelToolkit changeLogPanelWithParentView:contentPanel
                                                       controller:self
                                                             user:user
                                                  userSettingsBlk:_userSettingsBlk
                                        actionIfChangesDownloaded:^{
                                          [RUtils initiateAllDataToAppleWatchTransferWithCoordDao:_coordDao watchSessionDelegate:self];
                                          [self viewDidAppear:YES];
                                        }];
    [PEUIUtils placeView:_changelogPanel below:changelogAboveView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:25.0 hpadding:0.0];
    totalHeight += _changelogPanel.frame.size.height + 25.0;
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(entityAddedNotification:)
                                               name:REntityAddedNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [APP clearOpenSets];
  [APP setUserSettingsOpenFromUnsyncedEditsScreen:NO]; // yes, this is needed (I know this isn't the 'unsynced edits screen')
}

#pragma mark - Entity Added notification

- (void)entityAddedNotification:(NSNotification *)notification {
  [self setNeedsRepaint:YES];
  [self viewDidAppear:YES];
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

#pragma mark - Helpers

- (NSDate *)dateFromQuotedUnixTimeString:(NSString *)quotedUnixTime
                         numberFormatter:(NSNumberFormatter *)numberFormatter {
  NSString *noQuotesStr = [quotedUnixTime stringByReplacingOccurrencesOfString:@"'" withString:@""];
  return [NSDate dateWithTimeIntervalSince1970:[numberFormatter numberFromString:noQuotesStr].doubleValue / 1000];
}

- (UIButton *)unsyncedEditsButtonWithBadgeNum:(NSInteger)numUnsynced relativeToView:(UIView *)relativeToView {
  return [PEUIUtils buttonWithLabel:@"Unsynced Edits"
                           badgeNum:numUnsynced
                         badgeColor:[UIColor blackColor]
                     badgeTextColor:[UIColor whiteColor]
                  addDisclosureIcon:YES
                            handler:^{
                              [PEUIUtils displayController:[_screenToolkit newViewUnsyncedEditsScreenMaker]()
                                            fromController:self
                                                  animated:YES];
                            }
                          uitoolkit:_uitoolkit
                     relativeToView:relativeToView];
}

@end
