//
//  RScreenToolkit.m
//  riker-ios
//
//  Created by PEVANS on 10/27/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RScreenToolkit.h"
#import <BlocksKit/UIView+BlocksKit.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/NSDate+DateTools.h>
#import <StoreKit/StoreKit.h>
#import "UIColor+RAdditions.h"
#import "RUIUtils.h"
#import "RPanelToolkit.h"
#import "AppDelegate.h"
#import "PEUtils.h"
#import "RUtils.h"
#import "PEDatePickerController.h"
#import "NSString+PEAdditions.h"
#import "PELMUser.h"
#import "RAppNotificationNames.h"
#import "REditsInProgressController.h"
#import "PELocalDao.h"
#import "RSettingsController.h"
#import "RSet.h"
#import "PEUIUtils.h"
#import "PELMUIUtils.h"
#import "RAccountController.h"
#import "RRecordsController.h"
#import "RDashboardV2Controller.h"
#import "RBodyMeasurementLog.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "RChangeLog.h"
#import "RUserSettings.h"
#import "RInfoScreen.h"
#import "RErrorDomainsAndCodes.h"
#import "RSelectScreen.h"
#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "REnterRepsScreen.h"
@import Firebase;
@import Crashlytics;
#import "RChartConfig.h"
#import "REnterMeasurementScreen.h"
#import "RGeneralInfoController.h"
#import "RMovementInfoController.h"
#import "RWatchUtils.h"
#import "RAppleWatchController.h"

NSInteger const PAGINATION_PAGE_SIZE = 30;
NSInteger const USER_ACCOUNT_STATUS_PANEL_TAG = 12;

@implementation RScreenToolkit {
  id<RCoordinatorDao> _coordDao;
  NSDictionary *_originationDevices;
  RPanelToolkit *_panelToolkit;
  PELMDaoErrorBlk _errorBlk;
  NSNumberFormatter *_generalFormatter;
  RUserSettingsBlk _userSettingsBlk;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
                   uitoolkit:(PEUIToolkit *)uitoolkit
             userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                       error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _userSettingsBlk = userSettingsBlk;
    _panelToolkit = [[RPanelToolkit alloc] initWithCoordinatorDao:coordDao
                                                    screenToolkit:self
                                                        uitoolkit:uitoolkit
                                                            error:errorBlk];
    _generalFormatter = [[NSNumberFormatter alloc] init];
    [_generalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_generalFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [_generalFormatter setMaximumFractionDigits:1];
  }
  return self;
}

#pragma mark - Helpers

- (PEWouldBeIndexOfEntity)wouldBeIndexBlkForEqualityBlock:(BOOL(^)(id, id))equalityBlock
                                        flatEntityFetcher:(NSArray *(^)(void))entityFetcher {
  return ^ NSIndexPath *(PELMMainSupport *entity) {
    NSArray *entities = entityFetcher();
    NSInteger index = 0;
    NSInteger count = 0;
    for (PELMMainSupport *e in entities) {
      if (equalityBlock(e, entity)) {
        index = count;
        return [NSIndexPath indexPathForRow:count inSection:0];
      }
      count++;
    }
    return [NSIndexPath indexPathForRow:index inSection:0];
  };
}

- (PEModalOperationStarted)commonModalOperationStartedBlock {
  return ^{
  };
}

- (PEModalOperationDone)commonModalOperationDoneBlock {
  return ^{
  };
}

- (void)deselectSelectedRowForTableOnView:(UIView *)parentView tableViewTag:(NSInteger)tableViewTag {
  UITableView *tableView = (UITableView *)[parentView viewWithTag:tableViewTag];
  if ([tableView indexPathForSelectedRow]) {
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
  }
}

- (NSString *)formattedValueForValue:(id)value formatter:(NSString *(^)(id))formatter {
  if (![PEUtils isNil:value]) {
    return formatter(value);
  } else {
    return @"---";
  }
}

- (CGFloat(^)(id))heightForCellsBlkWithExtraPadding:(CGFloat)extraPadding {
  return ^CGFloat (id __not_used__) {
    return [PEUIUtils sizeOfText:@""
                        withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
    _uitoolkit.verticalPaddingForButtons + 15.0 + extraPadding;
  };
}

- (CGFloat(^)(id))heightForCellsBlk {
  return [self heightForCellsBlkWithExtraPadding:25.0];
}

- (PEDependencyFetcherBlk)makeDepFetcherBlkForUser:(PELMUser *)user {
  return ^(PEAddViewEditController *ctrl,
           RSet *remoteSet,
           PESyncNotFoundBlk notFoundBlk,
           PESyncSuccessBlk successBlk,
           PESyncRetryAfterBlk retryAfterBlk,
           PESyncServerTempErrorBlk tempErrBlk,
           PESyncAuthRequiredBlk authReqdBlk,
           PESyncForbiddenBlk forbiddenBlk) {
    CGFloat percentOfFetching = 1.0;
    NSString *mainMsgFragment = @"fetching dependencies";
    NSString *recordTitle = @"Dependencies";
    [_coordDao.userCoordinatorDao fetchChangelogForUser:user
                                        ifModifiedSince:[APP changelogUpdatedAt]
                                    notFoundOnServerBlk:^{
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle);
                                        [APP refreshTabs];
                                      });
                                    }
                                             successBlk:^(RChangeLog *changelog) {
                                               if (changelog) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                   [APP setChangelogUpdatedAt:changelog.updatedAt];
                                                   [_coordDao saveChangelog:changelog
                                                                    forUser:user
                                                            userSettingsBlk:_userSettingsBlk
                                                                      error:[RUtils localSaveErrorHandlerMaker]()];
                                                   [_coordDao logFirebaseUserProperties];
                                                   successBlk(1.0, mainMsgFragment, recordTitle);
                                                   [APP refreshTabs];
                                                 });
                                               }
                                             }
                                     remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter);
                                         [APP refreshTabs];
                                       });
                                     }
                                     tempRemoteErrorBlk:^{
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                         tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle);
                                         [APP refreshTabs];
                                       });
                                     }
                                    addlAuthRequiredBlk:^{
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle);
                                        [APP refreshTabs];
                                      });
                                    }];
  };
}

- (NSNumber *(^)(void))defaultWeightUnitsBlkMakerForUser:(PELMUser *)user {
  return ^NSNumber *{
    RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
    NSNumber *defaultWeightUnits = @(DEFAULT_WEIGHT_UNITS);
    if ([PEUtils isNotNil:userSettings]) {
      defaultWeightUnits = userSettings.weightUom;
    }
    return defaultWeightUnits;
  };
}

- (NSNumber *(^)(void))defaultSizeUnitsBlkMakerForUser:(PELMUser *)user {
  return ^NSNumber *{
    RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
    NSNumber *defaultWeightUnits = @(DEFAULT_SIZE_UNITS);
    if ([PEUtils isNotNil:userSettings]) {
      defaultWeightUnits = userSettings.sizeUom;
    }
    return defaultWeightUnits;
  };
}

- (PEIsUserVerified)newIsUserVerifiedBlk {
  return ^BOOL {
    PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [PEUtils isNotNil:user.verifiedAt];
  };
}

#pragma mark - Generic Screens

- (RUnauthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                    initialSelectedDate:(NSDate *)date
                                         datePickerMode:(UIDatePickerMode)datePickerMode
                                    logDatePickedAction:(void(^)(NSDate *))logDatePickedAction {
  return ^UIViewController *(void) {
    return [[PEDatePickerController alloc] initWithTitle:title
                                        heightPercentage:0.70
                                             initialDate:date
                                          datePickerMode:datePickerMode
                                     logDatePickedAction:logDatePickedAction];
  };
}

- (RUnauthScreenMaker)newWeightUnitsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                         initialSelectedWeightUom:(NSArray *)initialSelectedWeightUom {
  return ^ UIViewController *(void) {
    PEPageLoaderBlk pageLoader = ^ NSArray * (id anything) {
      return @[@[@(LBS_ID), LBS_NAME], @[@(KG_ID), KG_NAME]];
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(NSArray *uom) {return uom[1];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[NSArray class]
                                                                    title:@"Weight units"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedWeightUom
                                                            addItemAction:nil
                                                           cellIdentifier:@"RWeightUomCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(id item){return YES;}
                                                     wouldBeIndexOfEntity:nil
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:NO
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:nil
                                            entityUpdatedNotificationName:nil
                                            entityRemovedNotificationName:nil
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (RUnauthScreenMaker)newSizeUnitsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                         initialSelectedSizeUom:(NSArray *)initialSelectedSizeUom {
  return ^ UIViewController *(void) {
    PEPageLoaderBlk pageLoader = ^ NSArray * (id anything) {
      return @[@[@(INCHES_ID), INCHES_NAME], @[@(CM_ID), CM_NAME]];
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(NSArray *uom) {return uom[1];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[NSArray class]
                                                                    title:@"Size units"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedSizeUom
                                                            addItemAction:nil
                                                           cellIdentifier:@"RSizeUomCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(id item){return YES;}
                                                     wouldBeIndexOfEntity:nil
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:NO
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:nil
                                            entityUpdatedNotificationName:nil
                                            entityRemovedNotificationName:nil
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (RUnauthScreenMaker)newGendersForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                     initialSelectedGenderVal:(NSArray *)initialSelectedGenderVal {
  return ^ UIViewController *(void) {
    PEPageLoaderBlk pageLoader = ^ NSArray * (id anything) {
      return @[@[@(GENDER_MALE_VAL), GENDER_MALE], @[@(GENDER_FEMALE_VAL), GENDER_FEMALE]];
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(NSArray *uom) {return uom[1];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[NSArray class]
                                                                    title:@"Gender"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedGenderVal
                                                            addItemAction:nil
                                                           cellIdentifier:@"RGenderCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(id item){return YES;}
                                                     wouldBeIndexOfEntity:nil
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:NO
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:nil
                                            entityUpdatedNotificationName:nil
                                            entityRemovedNotificationName:nil
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

#pragma mark - Body Measurement Log Screens

- (PEItemDeleter)bmlItemDeleterForUser:(PELMUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 RBodyMeasurementLog *bml,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncAuthRequiredBlk authReqdBlk,
                                 PESyncForbiddenBlk forbiddenBlk) {
    NSString *mainMsgFragment = @"deleting body log";
    NSString *recordTitle = @"Body Log";
    [_coordDao deleteBml:bml
                 forUser:user
     notFoundOnServerBlk:^{
       dispatch_async(dispatch_get_main_queue(), ^{
         notFoundBlk(1, mainMsgFragment, recordTitle);
         [APP refreshTabs];
       });}
          addlSuccessBlk:^{
            dispatch_async(dispatch_get_main_queue(), ^{
              successBlk(1, mainMsgFragment, recordTitle);
              [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
              [APP refreshTabs];
            });
          }
      remoteStoreBusyBlk:^(NSDate *retryAfter) {
        dispatch_async(dispatch_get_main_queue(), ^{
          retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter);
          [APP refreshTabs];
        });}
      tempRemoteErrorBlk:^{
        dispatch_async(dispatch_get_main_queue(), ^{
          tempErrBlk(1, mainMsgFragment, recordTitle);
          [APP refreshTabs];
        });}
          remoteErrorBlk:^(NSInteger errMask) {
            dispatch_async(dispatch_get_main_queue(), ^{
              errBlk(1, mainMsgFragment, recordTitle, [RUtils computeBmlErrMsgs:errMask]);
              [APP refreshTabs];
            });}
     addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
            forbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                   error:[RUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)bmlItemLocalDeleter {
  return ^ (UIViewController *listViewController, RBodyMeasurementLog *bml, NSIndexPath *indexPath) {
    [_coordDao deleteBml:bml error:[RUtils localSaveErrorHandlerMaker]()];
    [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
    dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
  };
}

- (PETableCellContentViewStyler)bmlTableCellStyleWithOriginationDevices:(NSDictionary *)originationDevices {
  return [PELMUIUtils syncViewStylerWithTitleBlk:^(RBodyMeasurementLog *bml) {
    return [PEUtils stringFromDate:bml.loggedAt withPattern:DATE_PATTERN];
  }
                                       titleFont:nil
                                smallSubTitleBlk:nil
                              rightSideViewMaker:^(RBodyMeasurementLog *bml) {
                                UIFont *captionFont = [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:22.0 ipad:26.0]
                                                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]];
                                NSMutableString *weightValsStr = [NSMutableString string];
                                if ([PEUtils isNotNil:bml.bodyWeight]) {
                                  [weightValsStr appendString:[NSString stringWithFormat:@"Body weight: %@ %@", bml.bodyWeight, [RUtils weightUnitNameForUomId:bml.bodyWeightUom]]];
                                }
                                NSNumberFormatter *decimalFormatter = [RUtils weightNumberFormatter];
                                NSMutableArray *sizeValStrsArray = [NSMutableArray array];
                                if ([PEUtils isNotNil:bml.bodyWeight]) {
                                  [sizeValStrsArray addObject:[NSString stringWithFormat:@"Body weight: %@ %@", [_generalFormatter stringFromNumber:bml.bodyWeight], [RUtils weightUnitNameForUomId:bml.bodyWeightUom]]];
                                }
                                void (^appendSize)(NSNumber *, NSString *) = ^(NSNumber *val, NSString *abbrev) {
                                  if ([PEUtils isNotNil:val]) {
                                    [sizeValStrsArray addObject:[NSMutableString stringWithFormat:@"%@: %@ %@", abbrev, [decimalFormatter stringFromNumber:val], [RUtils sizeUnitNameForUomId:bml.sizeUom]]];
                                  }
                                };
                                appendSize(bml.armSize, @"Arm size");
                                appendSize(bml.chestSize, @"Chest size");
                                appendSize(bml.calfSize, @"Calf size");
                                appendSize(bml.neckSize, @"Neck size");
                                appendSize(bml.waistSize, @"Waist size");
                                appendSize(bml.thighSize, @"Thigh size");
                                appendSize(bml.forearmSize, @"Forearm size");
                                NSMutableArray *valPanelsArray = [NSMutableArray array];
                                if (sizeValStrsArray.count > 1) {
                                  [valPanelsArray addObject:[PEUIUtils labelWithKey:@"Multiple values set"
                                                                               font:captionFont
                                                                    backgroundColor:[UIColor clearColor]
                                                                          textColor:[UIColor grayColor]
                                                                verticalTextPadding:3.0]];
                                } else {
                                  [valPanelsArray addObject:[PEUIUtils labelWithKey:sizeValStrsArray[0]
                                                                               font:captionFont
                                                                    backgroundColor:[UIColor clearColor]
                                                                          textColor:[UIColor grayColor]
                                                                verticalTextPadding:3.0]];
                                }
                                UIView *valsPanel = [PEUIUtils panelWithColumnOfViews:valPanelsArray
                                                          verticalPaddingBetweenViews:0.0
                                                                       viewsAlignment:PEUIHorizontalAlignmentTypeRight];
                                UIImageView *origDeviceImageView = [RUIUtils imageViewForOriginationDevice:originationDevices[bml.originationDeviceId]];
                                UIImageView *importedImageView = nil;
                                CGFloat importedImageViewWidthWithPadding = 0.0;
                                if (bml.importedAt) {
                                  importedImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imported-small-icon"]];
                                  importedImageViewWidthWithPadding = importedImageView.frame.size.width;
                                  importedImageViewWidthWithPadding += (5.0 * 2);
                                }
                                CGFloat totalWidth = valsPanel.frame.size.width +
                                  origDeviceImageView.frame.size.width +
                                  importedImageViewWidthWithPadding +
                                  [PEUIUtils valueIfiPhone5Width:5.0
                                                    iphone6Width:15.0
                                                iphone6PlusWidth:20.0
                                                            ipad:20.0];
                                UIView *containerPanel = [PEUIUtils panelWithFixedWidth:totalWidth fixedHeight:[self heightForCellsBlk](nil)];
                                if (importedImageView) {
                                  [PEUIUtils placeView:importedImageView inMiddleOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
                                  [PEUIUtils placeView:origDeviceImageView toTheLeftOf:importedImageView onto:containerPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:5.0];
                                } else {
                                  [PEUIUtils placeView:origDeviceImageView inMiddleOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
                                }
                                [PEUIUtils placeView:valsPanel toTheLeftOf:origDeviceImageView onto:containerPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:5.0];
                                return containerPanel;
                              }
                          alwaysTopifyTitleLabel:NO
                                       uitoolkit:_uitoolkit
                            subtitleLeftHPadding:15.0
                        subtitleFitToWidthFactor:1.0
                                      isLoggedIn:[APP isUserLoggedIn]
                                    isEntityType:YES
                         importLimitExceededMask:@(RSaveBmlImportLimitExceeded)
           importedNotAllowedUnverifiedEmailMask:@(RSaveBmlImportUnverifiedEmail)];
}

- (RAuthScreenMaker)newViewBmlsScreenMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk {
  return ^ UIViewController * {
    void (^addBmlAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrl, PEItemAddedBlk itemAddedBlk) {
      // the reason we present the add screen as a nav-ctrl is so we that can experience
      // the animation effect of the view appearing from the bottom-up (and it being modal)
      UIViewController *addBmlScreen =
      [self newAddBmlScreenMakerWithDelegate:itemAddedBlk listViewController:listViewCtrl]();
      [listViewCtrl presentViewController:[PEUIUtils navigationControllerWithController:addBmlScreen
                                                                    navigationBarHidden:NO]
                                 animated:YES
                               completion:nil];
    };
    PEDetailViewMaker bmlDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                               id dataObject,
                                                               NSIndexPath *indexPath,
                                                               PEItemChangedBlk itemChangedBlk) {
      return [self newBmlDetailScreenMakerWithBml:dataObject
                                     bmlIndexPath:indexPath
                                   itemChangedBlk:itemChangedBlk
                               listViewController:listViewCtrl
                            originationDevicesBlk:originationDevicesBlk]();
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (RBodyMeasurementLog *lastBml) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      NSInteger pageSize = 100;
      if (lastBml) {
        return [_coordDao descendingBmlsForUser:user beforeLoggedAt:lastBml.loggedAt pageSize:pageSize error:errorBlk];
      } else {
        return [_coordDao descendingBmlsForUser:user pageSize:pageSize error:errorBlk];
      }
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(RBodyMeasurementLog *bml1, RBodyMeasurementLog *bml2) {
      return [bml1 doesHaveEqualIdentifiers:bml2];
    }                                                                 flatEntityFetcher:^{
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      return [_coordDao descendingBmlsForUser:user error:errorBlk];
    }];
    PETableCellContentViewStyler tableCellStyler = [self bmlTableCellStyleWithOriginationDevices:originationDevicesBlk()];
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RBodyMeasurementLog class]
                                                                    title:@"Body Logs"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addBmlAction
                                                           cellIdentifier:@"RBodyMeasurementLogCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:bmlDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:^{ return [user isBadAccount]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self bmlItemDeleterForUser:user]
                                                         itemLocalDeleter:[self bmlItemLocalDeleter]
                                                             isEntityType:YES
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (RAuthScreenMaker)newViewUnsyncedBmlsScreenMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk {
  return ^UIViewController * {
    PEDetailViewMaker bmlDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                               id dataObject,
                                                               NSIndexPath *indexPath,
                                                               PEItemChangedBlk itemChangedBlk) {
      return [self newBmlDetailScreenMakerWithBml:dataObject
                                     bmlIndexPath:indexPath
                                   itemChangedBlk:itemChangedBlk
                               listViewController:listViewCtrl
                            originationDevicesBlk:originationDevicesBlk]();
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (RBodyMeasurementLog *lastBml) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      return [_coordDao unsyncedBmlsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(RBodyMeasurementLog *bml1, RBodyMeasurementLog *bml2){return [bml1 doesHaveEqualIdentifiers:bml2];}
                                                                 flatEntityFetcher:^{ return pageLoader(nil); }];
    PETableCellContentViewStyler tableCellStyler = [self bmlTableCellStyleWithOriginationDevices:originationDevicesBlk()];
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RBodyMeasurementLog class]
                                                                    title:@"Unsynced Body Logs"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"RBodyMeasurementLogCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:bmlDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:^{ return [user isBadAccount]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self bmlItemDeleterForUser:user]
                                                         itemLocalDeleter:[self bmlItemLocalDeleter]
                                                             isEntityType:YES
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (PEEntityValidatorBlk)newBmlValidator {
  return ^NSArray *(UIView *bmlPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEMessageCollector cannotBeZeroCollector = [PEUIUtils newTfCannotBeZeroBlkForMsgs:errMsgs
                                                                          entityPanel:bmlPanel];
    cannotBeZeroCollector(RBmlTagBodyWeight, @"Body weight cannot be zero.");
    cannotBeZeroCollector(RBmlTagArmSize, @"Arm size cannot be zero.");
    cannotBeZeroCollector(RBmlTagChestSize, @"Chest size cannot be zero.");
    cannotBeZeroCollector(RBmlTagCalfSize, @"Calf size cannot be zero.");
    cannotBeZeroCollector(RBmlTagThighSize, @"Thigh size cannot be zero.");
    cannotBeZeroCollector(RBmlTagWaistSize, @"Waist size cannot be zero.");
    cannotBeZeroCollector(RBmlTagForearmSize, @"Forearm size cannot be zero.");
    cannotBeZeroCollector(RBmlTagNeckSize, @"Neck size cannot be zero.");
    NSString *bodyWeight = [PEUIUtils stringFromTextFieldWithTag:RBmlTagBodyWeight fromView:bmlPanel];
    NSString *armSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagArmSize fromView:bmlPanel];
    NSString *thighSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagThighSize fromView:bmlPanel];
    NSString *chestSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagChestSize fromView:bmlPanel];
    NSString *calfSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagCalfSize fromView:bmlPanel];
    NSString *waistSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagWaistSize fromView:bmlPanel];
    NSString *forearmSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagForearmSize fromView:bmlPanel];
    NSString *neckSize = [PEUIUtils stringFromTextFieldWithTag:RBmlTagNeckSize fromView:bmlPanel];
    if (bodyWeight.isBlank &&
        armSize.isBlank &&
        chestSize.isBlank &&
        thighSize.isBlank &&
        waistSize.isBlank &&
        forearmSize.isBlank &&
        neckSize.isBlank &&
        calfSize.isBlank) {
      [errMsgs addObject:@"At least one value must be supplied."];
    }
    return errMsgs;
  };
}

- (PEHasExceededImportLimit)newBmlHasExceededImportLimit {
  return ^BOOL {
    PELMDaoErrorBlk error = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[_coordDao userWithError:error];
    NSNumber *maxAllowedBmlImport = [user maxAllowedBmlImport];
    if (maxAllowedBmlImport) {
      return [_coordDao numSyncedImportedBmlsForUser:user error:error] >= maxAllowedBmlImport.integerValue;
    }
    return NO;
  };
}

- (RAuthScreenMaker)newAddBmlScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                  listViewController:(PEListViewController *)listViewController {
  return ^ UIViewController * {
    PESaveNewEntityLocalBlk newBmlSaverLocal = ^NSArray *(UIView *entityPanel, RBodyMeasurementLog *newBml) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveNewBml:newBml forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
      [RUtils saveHealthKitBmlsWithCompletion:nil noOpBlk:nil raiseNotificationOnError:YES coordDao:_coordDao healthStore:[APP healthStore]];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
      return @[@"Body measurement log saved.", @[@"Body measurement log saved locally."]];
    };
    PESaveNewEntityImmediateSyncBlk newBmlSaverImmediateSync = ^(UIView *entityPanel,
                                                                 RBodyMeasurementLog *newBml,
                                                                 PESyncNotFoundBlk notFoundBlk,
                                                                 PESyncSuccessBlk successBlk,
                                                                 PESyncRetryAfterBlk retryAfterBlk,
                                                                 PESyncServerTempErrorBlk tempErrBlk,
                                                                 PESyncServerErrorBlk errBlk,
                                                                 PESyncAuthRequiredBlk authReqdBlk,
                                                                 PESyncForbiddenBlk forbiddenBlk,
                                                                 PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving body log to the server";
      NSString *recordTitle = @"Body Log";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveNewAndSyncImmediateBml:newBml
                                    forUser:user
                    writeUserReadonlyFields:YES
                        notFoundOnServerBlk:^{
                          dispatch_async(dispatch_get_main_queue(), ^{
                            notFoundBlk(1, mainMsgFragment, recordTitle);
                            [APP refreshTabs];
                          });
                        }
                             addlSuccessBlk:^{
                               [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 successBlk(1, mainMsgFragment, recordTitle);
                                 [APP refreshTabs];                                 
                               });
                               [RUtils saveHealthKitBmlsWithCompletion:nil noOpBlk:nil raiseNotificationOnError:YES coordDao:_coordDao healthStore:[APP healthStore]];
                             }
                     addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                     addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                         addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [RUtils computeBmlErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                        addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                           addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                                      error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, RBodyMeasurementLog *newBml) {
      if (newBml && [newBml localMainIdentifier]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    PEEntityPanelMakerBlk formPanelMaker =
    [_panelToolkit bmlFormPanelMakerWithDefaultLoggedAtBlk:^NSDate *{ return [NSDate date]; }
                                     defaultWeightUomIdBlk:[self defaultWeightUnitsBlkMakerForUser:user]
                                       defaultSizeUomIdBlk:[self defaultSizeUnitsBlkMakerForUser:user]];
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:formPanelMaker
                                            entityToPanelBinder:[_panelToolkit bmlToBmlPanelBinder]
                                            panelToEntityBinder:[_panelToolkit bmlFormPanelToBmlBinder]
                                                    entityTitle:@"Body Log"
                                              entityNavbarTitle:@"Body Log"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit bmlMakerWithOriginationDeviceId:[PEUIUtils isIpad] ? @(ORIGINATION_DEVICE_ID_IPAD) : @(ORIGINATION_DEVICE_ID_IPHONE)]
                                            newEntitySaverLocal:newBmlSaverLocal
                                    newEntitySaverImmediateSync:newBmlSaverImmediateSync
                                 prepareUIForUserInteractionBlk:nil
                                               viewDidAppearBlk:nil
                                                entityValidator:[self newBmlValidator]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                   isBadAccount:^{ return [user isBadAccount]; }
                              allowedToRemoteSaveWithBadAccount:NO
                                allowedToDownloadWithBadAccount:NO
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:REntityAddedNotification
                                             addlContentSection:nil
                                                   panelToolkit:_panelToolkit
                                                promptGoOffline:YES
                                                     importedAt:^(RBodyMeasurementLog *bml) { return bml.importedAt; }
                                        importLimitExceededMask:@(RSaveBmlImportLimitExceeded)
                                         hasExceededImportLimit:[self newBmlHasExceededImportLimit]
                                                 isUserVerified:[self newIsUserVerifiedBlk]
                                                 viewDidLoadBlk:nil
                                                dismissCallback:nil];
  };
}

- (RAuthScreenMaker)newBmlDetailScreenMakerWithBml:(RBodyMeasurementLog *)bml
                                      bmlIndexPath:(NSIndexPath *)bmlIndexPath
                                    itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                listViewController:(PEListViewController *)listViewController
                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk {
  return ^ UIViewController * {
    PESaveEntityBlk bmlSaver = ^(PEAddViewEditController *ctrl, RBodyMeasurementLog *bml) {
      [_coordDao saveBml:bml error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEMarkAsDoneEditingLocalBlk doneEditingBmlLocal = ^(PEAddViewEditController *ctrl, RBodyMeasurementLog *bml) {
      [_coordDao markAsDoneEditingBml:bml error:[RUtils localSaveErrorHandlerMaker]()];
      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingBmlImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                        RBodyMeasurementLog *bml,
                                                                        PESyncNotFoundBlk notFoundBlk,
                                                                        PESyncSuccessBlk successBlk,
                                                                        PESyncRetryAfterBlk retryAfterBlk,
                                                                        PESyncServerTempErrorBlk tempErrBlk,
                                                                        PESyncServerErrorBlk errBlk,
                                                                        PESyncAuthRequiredBlk authReqdBlk,
                                                                        PESyncForbiddenBlk forbiddenBlk,
                                                                        PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving body log to the server";
      NSString *recordTitle = @"Body Log";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao markAsDoneEditingAndSyncBmlImmediate:bml
                                              forUser:user
                              writeUserReadonlyFields:YES
                                  notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                       addlSuccessBlk:^{
                                         successBlk(1, mainMsgFragment, recordTitle);
                                         dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                         [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                       }
                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                               addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                   addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [RUtils computeBmlErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                  addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                                     addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                                                error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               RBodyMeasurementLog *bml,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncForbiddenBlk forbiddenBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving body log to the server";
      NSString *recordTitle = @"Body Log";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao flushUnsyncedChangesToBml:bml
                                   forUser:user
                   writeUserReadonlyFields:YES
                       notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                            addlSuccessBlk:^{
                              successBlk(1, mainMsgFragment, recordTitle);
                              [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                              dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                            }
                    addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                    addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                        addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [RUtils computeBmlErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                       addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                          addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                     error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PENumRemoteDepsNotLocal numRemoteDepsNotLocalBlk = ^ NSInteger (RBodyMeasurementLog *remoteBml) {
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      ROriginationDevice *originationDevice = [_coordDao originationDeviceWithId:remoteBml.originationDeviceId error:errorBlk];
      NSInteger numNonLocalDeps = 0;
      if ([PEUtils isNil:originationDevice]) numNonLocalDeps++;
      return numNonLocalDeps;
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       RBodyMeasurementLog *bml,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk,
                                       PESyncForbiddenBlk forbiddenBlk) {
      NSString *mainMsgFragment = @"fetching body log";
      NSString *recordTitle = @"Body Log";
      float percentOfFetching = 1.0;
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao fetchBmlWithGlobalId:[bml globalIdentifier]
                      ifModifiedSince:[bml updatedAt]
                              forUser:user
                  notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                           successBlk:^(RBodyMeasurementLog *fetchedBml) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedBml); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                   remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                   tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                  addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                         forbiddenBlk:^{forbiddenBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    RBodyMeasurementLog *downloadedBml,
                                                    RBodyMeasurementLog *bml) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      downloadedBml.synced = YES;
      [_coordDao saveMasterBml:downloadedBml forUser:user writeUserReadonlyFields:YES error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEEntityPanelMakerBlk formPanelMaker =
    [_panelToolkit bmlFormPanelMakerWithDefaultLoggedAtBlk:^NSDate *{return bml.loggedAt;}
                                     defaultWeightUomIdBlk:^NSNumber *{return bml.bodyWeightUom;}
                                       defaultSizeUomIdBlk:^NSNumber *{return bml.sizeUom;}];
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:bml
                                                 listViewController:listViewController
                                                    entityIndexPath:bmlIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:formPanelMaker
                                               entityViewPanelMaker:[_panelToolkit bmlViewPanelMakerWithOriginationDevicesBlk:originationDevicesBlk]
                                                entityToPanelBinder:[_panelToolkit bmlToBmlPanelBinder]
                                                panelToEntityBinder:[_panelToolkit bmlFormPanelToBmlBinder]
                                                        entityTitle:@"Body Log"
                                                  entityNavbarTitle:@"Body Log"
                                               panelEnablerDisabler:[_panelToolkit bmlFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                        entitySaver:bmlSaver
                                             doneEditingEntityLocal:doneEditingBmlLocal
                                     doneEditingEntityImmediateSync:doneEditingBmlImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                       isBadAccount:^{ return [user isBadAccount]; }
                                  allowedToRemoteSaveWithBadAccount:NO
                                    allowedToDownloadWithBadAccount:NO
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:nil
                                                    entityValidator:[self newBmlValidator]
                                                           uploader:uploader
                                             uploadedSuccessMessage:@"This body log has been uploaded successfully."
                                              numRemoteDepsNotLocal:numRemoteDepsNotLocalBlk
                                                  fetchDependencies:[self makeDepFetcherBlkForUser:user]
                                                    updateDepsPanel:nil // turns out panel refreshes fine w/out this
                                                         downloader:downloaderBlk
                                     alreadyHaveLatestDownloadedMsg:@"You already have the latest version of this body log on your device."
                                                  postDownloadSaver:postDownloadSaverBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:[self bmlItemDeleterForUser:user]
                                                   itemLocalDeleter:[self bmlItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:REntityUpdatedNotification
                                      entityRemovedNotificationName:REntityDeletedNotification
                                                 masterEntityLoader:^id(NSNumber *localMasterIdentifier) {
                                                   return [_coordDao masterBmlWithId:localMasterIdentifier error:[RUtils localFetchErrorHandlerMaker]()];
                                                 }
                                      reauthReqdPostEditActivityBlk:nil
                                 actionIfReauthReqdNotifObservedBlk:nil
                                           promptCurrentPasswordBlk:nil
                                                       panelToolkit:_panelToolkit
                                                    promptGoOffline:YES
                                                         importedAt:^(RBodyMeasurementLog *bml) { return bml.importedAt; }
                                            importLimitExceededMask:@(RSaveBmlImportLimitExceeded)
                                             hasExceededImportLimit:[self newBmlHasExceededImportLimit]
                                                     isUserVerified:[self newIsUserVerifiedBlk]
                                                    deletedCallback:nil
                                                     viewDidLoadBlk:nil
                                                    dismissCallback:nil];
  };
}

#pragma mark - Sets screens

- (PEItemDeleter)setItemDeleterForUser:(PELMUser *)user {
  PEItemDeleter itemDeleter = ^ (UIViewController *listViewController,
                                 RSet *set,
                                 NSIndexPath *indexPath,
                                 PESyncNotFoundBlk notFoundBlk,
                                 PESyncSuccessBlk successBlk,
                                 PESyncRetryAfterBlk retryAfterBlk,
                                 PESyncServerTempErrorBlk tempErrBlk,
                                 PESyncServerErrorBlk errBlk,
                                 PESyncAuthRequiredBlk authReqdBlk,
                                 PESyncForbiddenBlk forbiddenBlk) {
    NSString *mainMsgFragment = @"deleting set";
    NSString *recordTitle = @"Set";
    [_coordDao deleteSet:set
                 forUser:user
     notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
          addlSuccessBlk:^{
            successBlk(1, mainMsgFragment, recordTitle);
            [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
            dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
      remoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
      tempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
          remoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSetErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
     addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
            forbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                   error:[RUtils localSaveErrorHandlerMaker]()];
  };
  return itemDeleter;
}

- (PEItemLocalDeleter)setItemLocalDeleter {
  return ^ (UIViewController *listViewController, RSet *set, NSIndexPath *indexPath) {
    [_coordDao deleteSet:set error:[RUtils localSaveErrorHandlerMaker]()];
    [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
    dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
  };
}

- (PETableCellContentViewStyler)setTableCellStyleWithOriginationDevices:(NSDictionary *)originationDevices
                                                              movements:(NSDictionary *)movements
                                                       movementVariants:(NSDictionary *)movementVariants {
  return [PELMUIUtils syncViewStylerWithTitleBlk:^(RSet *set) { return [[set loggedAt] timeAgoSinceNow]; }
                                       titleFont:nil
                                smallSubTitleBlk:^NSString *(RSet *set) {
                                  if ([set.loggedAt isEarlierThan:[[NSDate date] dateBySubtractingDays:1]]) {
                                    return [PEUtils stringFromDate:set.loggedAt withPattern:DATE_PATTERN];
                                  }
                                  return nil;
                                }
                              rightSideViewMaker:^(RSet *set) {
                                UIFont *captionFont = [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:22.0 ipad:26.0]
                                                                                        font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]];
                                RMovement *movement = movements[set.movementId];
                                NSMutableArray *valsViews = [NSMutableArray array];
                                CGFloat extraSpaceNeeded = 0.0;
                                if (set.importedAt) {
                                  // extra space is used up by 'imported' icon
                                  extraSpaceNeeded += 20.0;
                                }
                                UIView *movementLabel = [PEUIUtils labelWithKey:[PEUIUtils truncatedTextForText:movement.canonicalName
                                                                                                           font:captionFont
                                                                                                 availableWidth:[PEUIUtils valueIfiPhone5Width:155
                                                                                                                                  iphone6Width:185
                                                                                                                              iphone6PlusWidth:225
                                                                                                                                          ipad:300] - extraSpaceNeeded]
                                                                           font:captionFont
                                                                backgroundColor:[UIColor clearColor]
                                                                      textColor:[UIColor grayColor]
                                                            verticalTextPadding:3.0];
                                [valsViews addObject:movementLabel];
                                NSString *variantStr = nil;
                                BOOL isBodyLift = NO;
                                if ([PEUtils isNotNil:set.movementVariantId] && set.movementVariantId.integerValue == BODY_MOVEMENT_VARIANT_ID) {
                                  isBodyLift = YES;
                                } else if (movement.isBodyLift && [PEUtils isNil:set.movementVariantId]) {
                                  isBodyLift = YES;
                                }
                                if (isBodyLift) {
                                  variantStr = @"body lift";
                                } else {
                                  if (set.movementVariantId) {
                                    RMovementVariant *movementVariant = movementVariants[set.movementVariantId];
                                    variantStr = movementVariant.name;
                                  }
                                }
                                UIView *variantLabel = nil;
                                if (variantStr) {
                                  variantLabel = [PEUIUtils labelWithKey:variantStr
                                                                    font:captionFont
                                                         backgroundColor:[UIColor clearColor]
                                                               textColor:[UIColor grayColor]
                                                     verticalTextPadding:3.0];
                                  [valsViews addObject:variantLabel];
                                }
                                UIView *repsLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"%@ rep%@ of %@ %@",
                                                                             set.numReps,
                                                                             set.numReps.integerValue > 1 ? @"s" : @"",
                                                                             [_generalFormatter stringFromNumber:set.weight],
                                                                             [RUtils weightUnitNameForUomId:set.weightUom]]
                                                                       font:captionFont
                                                            backgroundColor:[UIColor clearColor]
                                                                  textColor:[UIColor grayColor]
                                                        verticalTextPadding:3.0];
                                [valsViews addObject:repsLabel];
                                UIView *valsPanel = [PEUIUtils panelWithColumnOfViews:valsViews
                                                          verticalPaddingBetweenViews:0.0
                                                                       viewsAlignment:PEUIHorizontalAlignmentTypeRight];
                                UIImageView *origDeviceImageView = [RUIUtils imageViewForOriginationDevice:originationDevices[set.originationDeviceId]];
                                UIImageView *importedImageView = nil;
                                CGFloat importedImageViewWidthWithPadding = 0.0;
                                if (set.importedAt) {
                                  importedImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imported-small-icon"]];
                                  importedImageViewWidthWithPadding = importedImageView.frame.size.width;
                                  importedImageViewWidthWithPadding += (5.0 * 2);
                                }
                                CGFloat totalWidth = valsPanel.frame.size.width +
                                origDeviceImageView.frame.size.width +
                                importedImageViewWidthWithPadding +
                                [PEUIUtils valueIfiPhone5Width:5.0
                                                  iphone6Width:15.0
                                              iphone6PlusWidth:20.0
                                                          ipad:20.0];
                                UIView *containerPanel = [PEUIUtils panelWithFixedWidth:totalWidth fixedHeight:[self heightForCellsBlk](nil)];
                                if (importedImageView) {
                                  [PEUIUtils placeView:importedImageView inMiddleOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
                                  [PEUIUtils placeView:origDeviceImageView toTheLeftOf:importedImageView onto:containerPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:5.0];
                                } else {
                                  [PEUIUtils placeView:origDeviceImageView inMiddleOf:containerPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
                                }
                                [PEUIUtils placeView:valsPanel toTheLeftOf:origDeviceImageView onto:containerPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:5.0];
                                return containerPanel;
                              }
                          alwaysTopifyTitleLabel:NO
                                       uitoolkit:_uitoolkit
                            subtitleLeftHPadding:15.0
                        subtitleFitToWidthFactor:1.0
                                      isLoggedIn:[APP isUserLoggedIn]
                                    isEntityType:YES
                         importLimitExceededMask:@(RSaveSetImportLimitExceeded)
           importedNotAllowedUnverifiedEmailMask:@(RSaveSetImportUnverifiedEmail)];
}

- (WeightTfDefaultedNotice)weightTfDefaultedToBodyWeightMaker {
  return ^(RMovement *movement, RBodyMeasurementLog *bml, NSNumber *weightVal, NSString *weightUnits, UIViewController *parentController) {
    NSDate *dateSuppressed = [APP suppressedWeightTfDefaultedToBodyWeightPopupAt];
    if ([PEUtils isNil:dateSuppressed] || [[NSDate date] monthsFrom:dateSuppressed] > 4) {
      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"The selected movement, %@, is a body-lift movement Riker estimates to use "
                                                            textToAccent:movement.canonicalName
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      NSDecimalNumber *percentageOfBodyWeight = [[NSDecimalNumber alloc] initWithString:@"1.0"];
      if ([PEUtils isNotNil:movement.percentageOfBodyWeight]) {
        percentageOfBodyWeight = movement.percentageOfBodyWeight;
      }
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ of your body weight."
                                                            textToAccent:[NSString stringWithFormat:@"%@%%", [percentageOfBodyWeight decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithString:@"100"]]]
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      if ([PEUtils isNotNil:bml]) {
        [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nBased on your most recent body log, your body weight is %@.  "
                                                              textToAccent:[NSString stringWithFormat:@"%@ %@", bml.bodyWeight, [RUtils weightUnitNameForUomId:bml.bodyWeightUom]]
                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
        [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Therefore we've defaulted the weight field to %@."
                                                              textToAccent:[NSString stringWithFormat:@"%.0f %@", weightVal.floatValue, weightUnits]
                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      } else {
        [desc appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\nKeep this in mind when entering the weight value."]];
      }
      // give slight delay before popping up
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.55 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [PEUIUtils showInfoAlertWithTitle:@"Body weight movement"
                         alertDescription:desc
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:parentController]
                          okayButtonTitle:@"Okay"
                         okayButtonAction:^{

                         }
                          okayButtonStyle:JGActionSheetButtonStyleBlue
                        cancelButtonTitle:@"Don't show me this again for a while."
                       cancelButtonAction:^{
                         [APP setSuppressWeightTfDefaultedToBodyWeightPopup:[NSDate date]];
                       }
                         cancelButtonSyle:JGActionSheetButtonStyleDefault
                           relativeToView:[PEUIUtils parentViewForAlertsForController:parentController]];
      });
    }
  };
}

- (RAuthScreenMaker)newViewSetsScreenMakerWithMovementsBlk:(NSDictionary *(^)(void))movementsBlk
                                    allMovementVariantsBlk:(NSDictionary *(^)(void))allMovementVariantsBlk
                                         defaultMovementId:(NSNumber *)defaultMovementId
                                  defaultMovementVariantId:(NSNumber *)defaultMovementVariantId
                             mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                       movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                     originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk {
  return ^ UIViewController * {
    void (^addSetAction)(PEListViewController *, PEItemAddedBlk) =
    ^(PEListViewController *listViewCtrl, PEItemAddedBlk itemAddedBlk) {
      // the reason we present the add screen as a nav-ctrl is so we that can experience
      // the animation effect of the view appearing from the bottom-up (and it being modal)
      UIViewController *addSetScreen =
      [self newAddSetScreenMakerWithDelegate:itemAddedBlk
                          listViewController:listViewCtrl
                           defaultMovementId:defaultMovementId
                    defaultMovementVariantId:defaultMovementVariantId
               mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                movementsBlk:movementsBlk
                         movementVariantsBlk:movementVariantsBlk
       ]();
      [listViewCtrl presentViewController:[PEUIUtils navigationControllerWithController:addSetScreen
                                                                    navigationBarHidden:NO]
                                 animated:YES
                               completion:nil];
    };
    PEDetailViewMaker setDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                               RSet *selectedSet,
                                                               NSIndexPath *indexPath,
                                                               PEItemChangedBlk itemChangedBlk) {
      return [self newSetDetailScreenMakerWithSet:selectedSet
                                     setIndexPath:indexPath
                                   itemChangedBlk:itemChangedBlk
                               listViewController:listViewCtrl
                                     movementsBlk:movementsBlk
                              movementVariantsBlk:movementVariantsBlk
                            originationDevicesBlk:originationDevicesBlk
                    mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                  deletedCallback:nil]();
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (RSet *lastSet) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      NSInteger pageSize = 100;
      if (lastSet) {
        return [_coordDao descendingSetsForUser:user beforeLoggedAt:lastSet.loggedAt pageSize:pageSize error:errorBlk];
      } else {
        return [_coordDao descendingSetsForUser:user pageSize:pageSize error:errorBlk];
      }
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(RSet *set1, RSet *set2){return [set1 doesHaveEqualIdentifiers:set2];}
                                                                 flatEntityFetcher:^{
                                                                   PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
                                                                   PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
                                                                   return [_coordDao descendingSetsForUser:user error:errorBlk];
                                                                 }];
    PETableCellContentViewStyler tableCellStyler =
    [self setTableCellStyleWithOriginationDevices:originationDevicesBlk()
                                        movements:movementsBlk()
                                 movementVariants:allMovementVariantsBlk()];
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RSet class]
                                                                    title:@"Sets"
                                                    isPaginatedDataSource:YES
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:addSetAction
                                                           cellIdentifier:@"RSetCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:setDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:^{ return [user isBadAccount]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self setItemDeleterForUser:user]
                                                         itemLocalDeleter:[self setItemLocalDeleter]
                                                             isEntityType:YES
                                                         viewDidAppearBlk:^(id _) { [APP clearOpenSets]; }
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (RAuthScreenMaker)newViewUnsyncedSetsScreenMakerWithMovementsBlk:(NSDictionary *(^)(void))movementsBlk
                                            allMovementVariantsBlk:(NSDictionary *(^)(void))allMovementVariantsBlk
                                               movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                                     mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight {
  return ^UIViewController * {
    PEDetailViewMaker setDetailViewMaker = ^UIViewController *(PEListViewController *listViewCtrl,
                                                               id dataObject,
                                                               NSIndexPath *indexPath,
                                                               PEItemChangedBlk itemChangedBlk) {
      return [self newSetDetailScreenMakerWithSet:dataObject
                                     setIndexPath:indexPath
                                   itemChangedBlk:itemChangedBlk
                               listViewController:listViewCtrl
                                     movementsBlk:movementsBlk
                              movementVariantsBlk:movementVariantsBlk
                            originationDevicesBlk:originationDevicesBlk
                    mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                  deletedCallback:nil]();
    };
    PEPageLoaderBlk pageLoader = ^ NSArray * (RSet *lastSet) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      return [_coordDao unsyncedSetsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(RSet *set1, RSet *set2){return [set1 doesHaveEqualIdentifiers:set2];}
                                                                 flatEntityFetcher:^{ return pageLoader(nil); }];
    PETableCellContentViewStyler tableCellStyler =
    [self setTableCellStyleWithOriginationDevices:originationDevicesBlk()
                                        movements:movementsBlk()
                                 movementVariants:allMovementVariantsBlk()];
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RSet class]
                                                                    title:@"Unsynced Sets"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:nil
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"RSetCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:setDetailViewMaker
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:^{ return [user isBadAccount]; }
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:[self setItemDeleterForUser:user]
                                                         itemLocalDeleter:[self setItemLocalDeleter]
                                                             isEntityType:YES
                                                         viewDidAppearBlk:^(id _) { [APP clearOpenSets]; }
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

- (PEEntityValidatorBlk)newSetValidatorWithMovementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk {
  return ^NSArray *(UIView *setPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    PEMessageCollector cannotBeBlankCollector = [PEUIUtils newTfCannotBeEmptyBlkForMsgs:errMsgs
                                                                            entityPanel:setPanel];
    PEMessageCollector cannotBeZeroCollector = [PEUIUtils newTfCannotBeZeroBlkForMsgs:errMsgs
                                                                          entityPanel:setPanel];
    cannotBeBlankCollector(RSetTagNumReps, @"Reps cannot be empty.");
    cannotBeZeroCollector(RSetTagNumReps, @"Reps cannot be zero.");
    cannotBeBlankCollector(RSetTagWeight, @"Weight cannot be empty.");
    cannotBeZeroCollector(RSetTagWeight, @"Weight cannot be zero.");
    RMovement *movement = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovement panel:setPanel];
    RMovementVariant *movementVariant = [PEUIUtils valueForSingleTableViewWithTag:RSetTagMovementVariant panel:setPanel];
    NSDictionary *allowedMovVariants = movementVariantsBlk(movement);
    if (allowedMovVariants.count > 0) {
      if ([PEUtils isNil:allowedMovVariants[movementVariant.localMasterIdentifier]]) {
        [errMsgs addObject:@"The movement variant is not valid for the selected movement."];
      }
    }
    return errMsgs;
  };
}

- (PEHasExceededImportLimit)newSetHasExceededImportLimit {
  return ^BOOL {
    PELMDaoErrorBlk error = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[_coordDao userWithError:error];
    NSNumber *maxAllowedSetImport = [user maxAllowedSetImport];
    if (maxAllowedSetImport) {
      return [_coordDao numSyncedImportedSetsForUser:user error:error] >= maxAllowedSetImport.integerValue;
    }
    return NO;
  };
}

- (RAuthScreenMaker)newAddSetScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                  listViewController:(PEListViewController *)listViewController
                                   defaultMovementId:(NSNumber *)defaultMovementId
                            defaultMovementVariantId:(NSNumber *)defaultMovementVariantId
                       mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                        movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                 movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk {
  return ^ UIViewController * {
    PESaveNewEntityLocalBlk newSetSaverLocal = ^NSArray *(UIView *entityPanel, RSet *newSet) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveNewSet:newSet forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
      [RUtils logNewSetEventWithSet:newSet];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
      return @[@"Set saved.", @[@"Set saved locally."]];
    };
    PESaveNewEntityImmediateSyncBlk newSetSaverImmediateSync = ^(UIView *entityPanel,
                                                                 RSet *newSet,
                                                                 PESyncNotFoundBlk notFoundBlk,
                                                                 PESyncSuccessBlk successBlk,
                                                                 PESyncRetryAfterBlk retryAfterBlk,
                                                                 PESyncServerTempErrorBlk tempErrBlk,
                                                                 PESyncServerErrorBlk errBlk,
                                                                 PESyncAuthRequiredBlk authReqdBlk,
                                                                 PESyncForbiddenBlk forbiddenBlk,
                                                                 PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving set to the server";
      NSString *recordTitle = @"Set";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao saveNewAndSyncImmediateSet:newSet
                                    forUser:user
                    writeUserReadonlyFields:YES
                        notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                             addlSuccessBlk:^{
                               successBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                               [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                               [RUtils logNewSetEventWithSet:newSet];
                             }
                     addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                     addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                         addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSetErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                        addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                           addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                                      error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEEntityAddCancelerBlk addCanceler = ^(PEAddViewEditController *ctrl, BOOL dismissCtrlr, RSet *newSet) {
      if (newSet && [newSet localMainIdentifier]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
      }
      if (dismissCtrlr) {
        [[ctrl navigationController] dismissViewControllerAnimated:YES completion:nil];
      }
    };
    RMovement *(^movementLoader)(NSNumber *) = ^(NSNumber *movementId) {
      return [_coordDao movementForMovementId:movementId error:[RUtils localFetchErrorHandlerMaker]()];
    };
    RMovementVariant *(^movementVariantLoader)(NSNumber *) = ^(NSNumber *movementVariantId) {
      if ([PEUtils isNotNil:movementVariantId]) {
        return [_coordDao movementVariantForMovementVariantId:movementVariantId error:[RUtils localFetchErrorHandlerMaker]()];
      }
      return (RMovementVariant *)nil;
    };
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    PEEntityPanelMakerBlk formPanelMaker =
    [_panelToolkit setFormPanelMakerWithDefaultLoggedAtBlk:^NSDate *{ return [NSDate date]; }
                                        defaultMovementBlk:^RMovement *{return movementsBlk()[defaultMovementId];}
                                 defaultMovementVariantBlk:^RMovementVariant * { return movementVariantLoader(defaultMovementVariantId); }
                                       defaultWeightUomBlk:[self defaultWeightUnitsBlkMakerForUser:user]
                                              movementsBlk:movementsBlk
                                       movementVariantsBlk:movementVariantsBlk
                                         movementLoaderBlk:movementLoader
                             mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                             weightTfDefaultedToBodyWeight:[self weightTfDefaultedToBodyWeightMaker]];
    return [PEAddViewEditController addEntityCtrlrWithUitoolkit:_uitoolkit
                                             listViewController:listViewController
                                                   itemAddedBlk:itemAddedBlk
                                           entityFormPanelMaker:formPanelMaker
                                            entityToPanelBinder:[_panelToolkit setToSetPanelBinderWithMovementLoaderBlk:movementLoader
                                                                                               movementVariantLoaderBlk:movementVariantLoader]
                                            panelToEntityBinder:[_panelToolkit setFormPanelToSetBinder]
                                                    entityTitle:@"Set"
                                              entityNavbarTitle:@"Set"
                                              entityAddCanceler:addCanceler
                                                    entityMaker:[_panelToolkit setMakerWithOriginationDeviceId:[PEUIUtils isIpad] ? @(ORIGINATION_DEVICE_ID_IPAD) : @(ORIGINATION_DEVICE_ID_IPHONE)]
                                            newEntitySaverLocal:newSetSaverLocal
                                    newEntitySaverImmediateSync:newSetSaverImmediateSync
                                 prepareUIForUserInteractionBlk:nil
                                               viewDidAppearBlk:nil
                                                entityValidator:[self newSetValidatorWithMovementVariantsBlk:movementVariantsBlk]
                                                isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                 isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                   isBadAccount:^{ return [user isBadAccount]; }
                              allowedToRemoteSaveWithBadAccount:NO
                                allowedToDownloadWithBadAccount:NO
                                                  isOfflineMode:^{ return [APP offlineMode]; }
                                 syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                          modalOperationStarted:[self commonModalOperationStartedBlock]
                                             modalOperationDone:[self commonModalOperationDoneBlock]
                                    entityAddedNotificationName:REntityAddedNotification
                                             addlContentSection:nil
                                                   panelToolkit:_panelToolkit
                                                promptGoOffline:YES
                                                     importedAt:^(RSet *set) { return set.importedAt; }
                                        importLimitExceededMask:@(RSaveSetImportLimitExceeded)
                                         hasExceededImportLimit:[self newSetHasExceededImportLimit]
                                                 isUserVerified:[self newIsUserVerifiedBlk]
                                                 viewDidLoadBlk:nil
                                                dismissCallback:nil];
  };
}

- (RAuthScreenMaker)newSetDetailScreenMakerWithSet:(RSet *)set
                                      setIndexPath:(NSIndexPath *)setIndexPath
                                    itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                listViewController:(PEListViewController *)listViewController
                                      movementsBlk:(NSDictionary *(^)(void))movementsBlk
                               movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                     mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                   deletedCallback:(void(^)(void))deletedCallback {
  return ^ UIViewController * {
    PESaveEntityBlk setSaver = ^(PEAddViewEditController *ctrl, RSet *set) {
      [_coordDao saveSet:set error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEMarkAsDoneEditingLocalBlk doneEditingSetLocal = ^(PEAddViewEditController *ctrl, RSet *set) {
      [_coordDao markAsDoneEditingSet:set error:[RUtils localSaveErrorHandlerMaker]()];
      [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingSetImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                        RSet *set,
                                                                        PESyncNotFoundBlk notFoundBlk,
                                                                        PESyncSuccessBlk successBlk,
                                                                        PESyncRetryAfterBlk retryAfterBlk,
                                                                        PESyncServerTempErrorBlk tempErrBlk,
                                                                        PESyncServerErrorBlk errBlk,
                                                                        PESyncAuthRequiredBlk authReqdBlk,
                                                                        PESyncForbiddenBlk forbiddenBlk,
                                                                        PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving set to the server";
      NSString *recordTitle = @"Set";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao markAsDoneEditingAndSyncSetImmediate:set
                                              forUser:user
                              writeUserReadonlyFields:YES
                                  notFoundOnServerBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }); }
                                       addlSuccessBlk:^{
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                           successBlk(1, mainMsgFragment, recordTitle);
                                           [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                           [APP refreshTabs];
                                         });
                                       }
                               addlRemoteStoreBusyBlk:^(NSDate *retryAfter) { dispatch_async(dispatch_get_main_queue(), ^{ retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs]; }); }
                               addlTempRemoteErrorBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }); }
                                   addlRemoteErrorBlk:^(NSInteger errMask) { dispatch_async(dispatch_get_main_queue(), ^{ errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSetErrMsgs:errMask]); [APP refreshTabs]; }); }
                                  addlAuthRequiredBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ authReqdBlk(1, mainMsgFragment, recordTitle); }); }
                                     addlForbiddenBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ forbiddenBlk(1, mainMsgFragment, recordTitle); }); }
                                                error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               RSet *set,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncForbiddenBlk forbiddenBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving set to the server";
      NSString *recordTitle = @"Set";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao flushUnsyncedChangesToSet:set
                                   forUser:user
                   writeUserReadonlyFields:YES
                       notFoundOnServerBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ notFoundBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }); }
                            addlSuccessBlk:^{
                              successBlk(1, mainMsgFragment, recordTitle);
                              dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                            }
                    addlRemoteStoreBusyBlk:^(NSDate *retryAfter){ dispatch_async(dispatch_get_main_queue(), ^{  retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); [APP refreshTabs]; }); }
                    addlTempRemoteErrorBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ tempErrBlk(1, mainMsgFragment, recordTitle); [APP refreshTabs]; }); }
                        addlRemoteErrorBlk:^(NSInteger errMask){ dispatch_async(dispatch_get_main_queue(), ^{ errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSetErrMsgs:errMask]); [APP refreshTabs]; }); }
                       addlAuthRequiredBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ authReqdBlk(1, mainMsgFragment, recordTitle); });}
                          addlForbiddenBlk:^{ dispatch_async(dispatch_get_main_queue(), ^{ forbiddenBlk(1, mainMsgFragment, recordTitle); });}
                                     error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEPrepareUIForUserInteractionBlk prepareUIForUserInteractionBlk = ^(PEAddViewEditController *ctrl, UIView *entityPanel) {
      if (![ctrl hasPoppedKeyboard]) {
        //UITextField *setNameTf = (UITextField *)[entityPanel viewWithTag:RSetTagName];
        //[setNameTf becomeFirstResponder];
        [ctrl setHasPoppedKeyboard:YES];
      }
    };
    PENumRemoteDepsNotLocal numRemoteDepsNotLocalBlk = ^ NSInteger (RSet *remoteSet) {
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      RMovement *movement = [_coordDao movementForMovementId:[remoteSet movementId] error:errorBlk];
      RMovementVariant *movementVariant = [_coordDao movementVariantForMovementVariantId:[remoteSet movementVariantId] error:errorBlk];
      ROriginationDevice *originationDevice = [_coordDao originationDeviceWithId:remoteSet.originationDeviceId error:errorBlk];
      NSInteger numNonLocalDeps = 0;
      if ([PEUtils isNil:movement]) numNonLocalDeps++;
      if ([PEUtils isNil:movementVariant]) numNonLocalDeps++;
      if ([PEUtils isNil:originationDevice]) numNonLocalDeps++;
      return numNonLocalDeps;
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       RSet *set,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk,
                                       PESyncForbiddenBlk forbiddenBlk) {
      NSString *mainMsgFragment = @"fetching set";
      NSString *recordTitle = @"set";
      float percentOfFetching = 1.0;
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao fetchSetWithGlobalId:[set globalIdentifier]
                      ifModifiedSince:[set updatedAt]
                              forUser:user
                  notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                           successBlk:^(RSet *fetchedSet) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedSet); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                   remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                   tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                  addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                         forbiddenBlk:^{forbiddenBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    RSet *downloadedSet,
                                                    RSet *set) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      downloadedSet.synced = YES;
      [_coordDao saveMasterSet:downloadedSet forUser:user writeUserReadonlyFields:YES error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    RMovement *(^movementLoader)(NSNumber *) = ^(NSNumber *movementId) {
      return [_coordDao movementForMovementId:movementId error:[RUtils localFetchErrorHandlerMaker]()];
    };
    RMovementVariant *(^movementVariantLoader)(NSNumber *) = ^(NSNumber *movementVariantId) {
      if ([PEUtils isNotNil:movementVariantId]) {
        return [_coordDao movementVariantForMovementVariantId:movementVariantId error:[RUtils localFetchErrorHandlerMaker]()];
      }
      return (RMovementVariant *)nil;
    };
    WeightTfDefaultedNotice weightTfDefaultedToBodyWeight = [self weightTfDefaultedToBodyWeightMaker];
    PEEntityPanelMakerBlk formPanelMaker =
    [_panelToolkit setFormPanelMakerWithDefaultLoggedAtBlk:^NSDate *{return set.loggedAt;}
                                        defaultMovementBlk:^RMovement *{return movementLoader(set.movementId);}
                                 defaultMovementVariantBlk:^RMovementVariant * {
                                   if ([PEUtils isNotNil:set.movementVariantId]) {
                                     return movementVariantLoader(set.movementVariantId);
                                   }
                                   return nil;
                                 }
                                       defaultWeightUomBlk:^NSNumber *{return set.weightUom;}
                                              movementsBlk:movementsBlk
                                       movementVariantsBlk:movementVariantsBlk
                                         movementLoaderBlk:movementLoader
                             mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                             weightTfDefaultedToBodyWeight:weightTfDefaultedToBodyWeight];
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:user
                                                             entity:set
                                                 listViewController:listViewController
                                                    entityIndexPath:setIndexPath
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:itemChangedBlk
                                               entityFormPanelMaker:formPanelMaker
                                               entityViewPanelMaker:[_panelToolkit setViewPanelMakerWithOriginationDevicesBlk:originationDevicesBlk
                                                                                                                 movementsBlk:movementsBlk
                                                                                                          movementVariantsBlk:movementVariantsBlk
                                                                                                            movementLoaderBlk:movementLoader
                                                                                                     movementVariantLoaderBlk:movementVariantLoader
                                                                                                mostRecentBmlWithNonNilWeight:mostRecentBmlWithNonNilWeight
                                                                                             weightTfDefaultedToBodyWeight:weightTfDefaultedToBodyWeight]
                                                entityToPanelBinder:[_panelToolkit setToSetPanelBinderWithMovementLoaderBlk:movementLoader
                                                                                                   movementVariantLoaderBlk:movementVariantLoader]
                                                panelToEntityBinder:[_panelToolkit setFormPanelToSetBinder]
                                                        entityTitle:@"Set"
                                                  entityNavbarTitle:@"Set"
                                               panelEnablerDisabler:[_panelToolkit setFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                        entitySaver:setSaver
                                             doneEditingEntityLocal:doneEditingSetLocal
                                     doneEditingEntityImmediateSync:doneEditingSetImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                       isBadAccount:^{ return [user isBadAccount]; }
                                  allowedToRemoteSaveWithBadAccount:NO
                                    allowedToDownloadWithBadAccount:NO
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                                   viewDidAppearBlk:nil
                                                    entityValidator:[self newSetValidatorWithMovementVariantsBlk:movementVariantsBlk]
                                                           uploader:uploader
                                             uploadedSuccessMessage:@"This set record has been uploaded successfully."
                                              numRemoteDepsNotLocal:numRemoteDepsNotLocalBlk
                                                  fetchDependencies:[self makeDepFetcherBlkForUser:user]
                                                    updateDepsPanel:nil // turns out panel refreshes fine w/out this
                                                         downloader:downloaderBlk
                                     alreadyHaveLatestDownloadedMsg:@"You already have the latest version of this set record on your device."
                                                  postDownloadSaver:postDownloadSaverBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:[self setItemDeleterForUser:user]
                                                   itemLocalDeleter:[self setItemLocalDeleter]
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:REntityUpdatedNotification
                                      entityRemovedNotificationName:REntityDeletedNotification
                                                 masterEntityLoader:^id(NSNumber *localMasterIdentifier) {
                                                   return [_coordDao masterSetWithId:localMasterIdentifier error:[RUtils localFetchErrorHandlerMaker]()];
                                                 }
                                      reauthReqdPostEditActivityBlk:nil
                                 actionIfReauthReqdNotifObservedBlk:nil
                                           promptCurrentPasswordBlk:nil
                                                       panelToolkit:_panelToolkit
                                                    promptGoOffline:YES
                                                         importedAt:^(RSet *set) { return set.importedAt; }
                                            importLimitExceededMask:@(RSaveSetImportLimitExceeded)
                                             hasExceededImportLimit:[self newSetHasExceededImportLimit]
                                                     isUserVerified:[self newIsUserVerifiedBlk]
                                                    deletedCallback:deletedCallback
                                                     viewDidLoadBlk:^{ [APP setOpened:set]; }
                                                    dismissCallback:^{ [APP setClosed:set]; }];
  };
}

#pragma mark - Movement Screens

- (RUnauthScreenMaker)newMovementsScreenMakerWithTitle:(NSString *)title
                                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                               initialSelectedMovement:(RMovement *)initialSelectedMovement {
  return ^{
    PEPageLoaderBlk pageLoader = ^ NSArray * (RMovement *lastMovement) {
      return [_coordDao muscleGroupsAndMovementsWithError:[RUtils localFetchErrorHandlerMaker]()];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk =
    ^NSIndexPath *(RMovement *movement) {
      NSArray *mgsAndMovements = pageLoader(nil);
      NSInteger numMgs = [mgsAndMovements count];
      for (int i = 0; i < numMgs; i++) {
        NSArray *movements = mgsAndMovements[i][@"movs"];
        NSInteger numMovs = [movements count];
        for (int j = 0; j < numMovs; j++) {
          if ([((RMovement *)movements[j]) isEqualToMovement:movement]) {
            return [NSIndexPath indexPathForRow:i inSection:j];
          }
        }
      }
      return nil;
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(RMovement *movement) {return [movement canonicalName];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    NSMutableArray *(^rowsInSection)(NSInteger, id) = ^NSMutableArray *(NSInteger sectionIndex, NSArray *mgsAndMovs) {
      NSDictionary *mgNameAndMovsDict = mgsAndMovs[sectionIndex];
      return mgNameAndMovsDict[@"movs"];
    };
    NSString *(^titleForHeaderInSection)(NSInteger, id) = ^NSString *(NSInteger sectionIndex, NSArray *mgsAndMovs) {
      NSDictionary *mgNameAndMovsDict = mgsAndMovs[sectionIndex];
      return mgNameAndMovsDict[@"mg_name"];
    };
    RMovement *(^dataObjectAccessor)(NSIndexPath *, id) = ^RMovement *(NSIndexPath *indexPath, NSArray *mgsAndMovs) {
      NSDictionary *mgNameAndMovsDict = mgsAndMovs[indexPath.section];
      NSArray *movements = mgNameAndMovsDict[@"movs"];
      return movements[indexPath.row];
    };
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RMovement class]
                                                                    title:title
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedMovement
                                                            addItemAction:nil
                                                           cellIdentifier:@"RMovementCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:YES
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStyleGrouped
                                                            rowsInSection:rowsInSection
                                                  titleForHeaderInSection:titleForHeaderInSection
                                                       dataObjectAccessor:dataObjectAccessor
                                                              cancellable:NO];
  };
}

- (RUnauthScreenMaker)newMovementInfoScreenMakerWithMovement:(RMovement *)movement
                                       enableStartSetButtons:(BOOL)enableStartSetButtons {
  return ^{
    return [[RMovementInfoController alloc] initWithStoreCoordinator:_coordDao
                                                            movement:movement
                                                           uitoolkit:_uitoolkit
                                                       screenToolkit:self
                                                        panelToolkit:_panelToolkit
                                               enableStartSetButtons:enableStartSetButtons];
  };
}

#pragma mark - Movement Variant Screens

- (RUnauthScreenMaker)newMovementVariantsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                        initialSelectedMovementVariant:(RMovementVariant *)initialSelectedMovementVariant
                                                                              movement:(RMovement *)movement {
  return ^{
    PEPageLoaderBlk pageLoader = ^ NSArray * (RMovementVariant *lastMovementVariant) {
      return [RUtils filterMovementVariants:[_coordDao movementVariantsWithError:[RUtils localFetchErrorHandlerMaker]()]
                                  usingMask:movement.variantMask.integerValue];
    };
    PEWouldBeIndexOfEntity wouldBeIndexBlk = [self wouldBeIndexBlkForEqualityBlock:^(RMovementVariant *m1, RMovementVariant *m2){return [m1 isEqualToMovementVariant:m2];}
                                                                 flatEntityFetcher:^{ return pageLoader(nil); }];
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(RMovementVariant *movementVariant) {return [movementVariant name];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RMovementVariant class]
                                                                    title:@"Choose Movement Variant"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedMovementVariant
                                                            addItemAction:nil
                                                           cellIdentifier:@"RMovementVariantCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                                     wouldBeIndexOfEntity:wouldBeIndexBlk
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:YES
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:REntityAddedNotification
                                            entityUpdatedNotificationName:REntityUpdatedNotification
                                            entityRemovedNotificationName:REntityDeletedNotification
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

#pragma mark - Drafts Screens

- (RAuthScreenMaker)newViewUnsyncedEditsScreenMaker {
  return ^ UIViewController * {
    return [[REditsInProgressController alloc] initWithStoreCoordinator:_coordDao
                                                              uitoolkit:_uitoolkit
                                                          screenToolkit:self];
  };
}

#pragma mark - Settings Screens

- (RAuthScreenMaker)newViewSettingsScreenMaker {
  return ^ UIViewController * {
    return [[RSettingsController alloc] initWithStoreCoordinator:_coordDao
                                                 userSettingsBlk:_userSettingsBlk
                                                       uitoolkit:_uitoolkit
                                                   screenToolkit:self
                                                     panelTookit:_panelToolkit];
  };
}

#pragma mark - User Account Screens

- (PEEntityValidatorBlk)newUserAccountValidatorWithUser:(PELMUser *)user {
  return ^NSArray *(UIView *userAccountPanel) {
    NSMutableArray *errMsgs = [NSMutableArray array];
    NSString *email = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagEmail]) text];
    NSString *password = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagPassword]) text];
    NSString *confirmPassword = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagConfirmPassword]) text];
    if ([email isBlank]) {
      [errMsgs addObject:@"E-mail cannot be blank."];
    } else {

      if (![password isBlank]) {
        if ([confirmPassword isBlank]) {
          [errMsgs addObject:@"To update your password, re-enter it in the 'Confirm Password' field."];
        } else if (![password isEqualToString:confirmPassword]) {
          [errMsgs addObject:@"Passwords do not match."];
        }
      } else {
        NSString *confirmPassword = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagConfirmPassword]) text];
        if (![confirmPassword isBlank]) {
          [errMsgs addObject:@"If you want to update your password, you have to enter it in both the 'Password' and 'Confirm Password' fields."];
        }
      }
    }
    return errMsgs;
  };
}

- (PEPromptCurrentPasswordBlk)makePromptCurrentPasswordBlk {
  return ^BOOL(UIView *userAccountPanel, PELMUser *origUser) {
    if (origUser.hasPassword) {
      NSString *tfEmail = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagEmail]) text];
      NSString *password = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagPassword]) text];
      NSString *confirmPassword = [((UITextField *)[userAccountPanel viewWithTag:PELMUserTagConfirmPassword]) text];
      tfEmail = [tfEmail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      NSString *userEmail = [origUser.email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if ([tfEmail.lowercaseString isEqualToString:userEmail.lowercaseString]) {
        if ([password isBlank] && [confirmPassword isBlank]) {
          return NO;
        }
      }
      return YES;
    }
    return NO;
  };
}

- (RAuthScreenMaker)newUserAccountDetailScreenMaker {
  return ^ UIViewController * {
    PESaveEntityBlk userSaver = ^(PEAddViewEditController *ctrl, PELMUser *user) {
      [_coordDao saveUser:user error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingUserImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                         PELMUser *user,
                                                                         PESyncNotFoundBlk notFoundBlk,
                                                                         PESyncSuccessBlk successBlk,
                                                                         PESyncRetryAfterBlk retryAfterBlk,
                                                                         PESyncServerTempErrorBlk tempErrBlk,
                                                                         PESyncServerErrorBlk errBlk,
                                                                         PESyncAuthRequiredBlk authReqdBlk,
                                                                         PESyncForbiddenBlk forbiddenBlk,
                                                                         PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving user account to the server";
      NSString *recordTitle = @"User account";
      [_coordDao.userCoordinatorDao markAsDoneEditingAndSyncUserImmediate:user
                                                      notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                                           addlSuccessBlk:^{
                                                             successBlk(1, mainMsgFragment, recordTitle);
                                                             dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                                             [[Crashlytics sharedInstance] setUserIdentifier:user.globalIdentifier];
                                                             [[Crashlytics sharedInstance] setUserEmail:user.email];
                                                             [FIRAnalytics setUserID:user.globalIdentifier];
                                                             [FIRAnalytics setUserPropertyString:user.email forName:@"email"];
                                                           }
                                                   addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {
                                                     retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter);
                                                     dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                                   }
                                                   addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                                       addlRemoteErrorBlk:^(NSInteger errMask) {
                                                         errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSaveUsrErrMsgs:errMask]);
                                                         dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                                       }
                                                      addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                                                                    error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       PELMUser *user,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk,
                                       PESyncForbiddenBlk forbiddenBlk) {
      NSString *mainMsgFragment = @"fetching user account";
      NSString *recordTitle = @"User account";
      float percentOfFetching = 1.0;
      [_coordDao.userCoordinatorDao fetchUser:user
                              ifModifiedSince:[user updatedAt]
                          notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                   successBlk:^(PELMUser *fetchedUser) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedUser); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                           remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                           tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                          addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    PELMUser *downloadedUser,
                                                    PELMUser *user) {
      downloadedUser.synced = YES;
      [_coordDao saveMasterUser:downloadedUser error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEViewDidAppearBlk viewDidAppearBlk = ^(PEAddViewEditController *ctrl) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_panelToolkit refreshEmailStatusPanelForUser:user
                                           panelTag:@(USER_ACCOUNT_STATUS_PANEL_TAG)
                               includeRefreshButton:NO
                                     relativeToView:ctrl.view
                                      fontTextStyle:[PEUIUtils userAccountInfoFontTextStyle]
                                         controller:ctrl
                           becameUnauthButtonAction:^(UIViewController *ctrl) {[[ctrl navigationController] popViewControllerAnimated:YES];}];
    };
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:nil
                                                             entity:user
                                                 listViewController:nil
                                                    entityIndexPath:nil
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:nil
                                               entityFormPanelMaker:[_panelToolkit userAccountFormPanelMaker]
                                               entityViewPanelMaker:[_panelToolkit userAccountViewPanelMakerWithAccountStatusLabelTag:USER_ACCOUNT_STATUS_PANEL_TAG
                                                                                                             becameUnauthButtonAction:^(UIViewController *ctrl) {[[ctrl navigationController] popViewControllerAnimated:YES];}
                                                                     fontTextStyle:[PEUIUtils userAccountInfoFontTextStyle]]
                                                entityToPanelBinder:[_panelToolkit userToUserPanelBinder]
                                                panelToEntityBinder:[_panelToolkit userFormPanelToUserBinder]
                                                        entityTitle:@"User Account"
                                                  entityNavbarTitle:@"User Account"
                                               panelEnablerDisabler:[_panelToolkit userFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                        entitySaver:userSaver
                                             doneEditingEntityLocal:nil
                                     doneEditingEntityImmediateSync:doneEditingUserImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                       isBadAccount:^{ return [user isBadAccount]; }
                                  allowedToRemoteSaveWithBadAccount:YES
                                    allowedToDownloadWithBadAccount:YES
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:nil
                                                   viewDidAppearBlk:viewDidAppearBlk
                                                    entityValidator:[self newUserAccountValidatorWithUser:user]
                                                           uploader:nil
                                             uploadedSuccessMessage:nil
                                              numRemoteDepsNotLocal:nil
                                                  fetchDependencies:nil
                                                    updateDepsPanel:nil
                                                         downloader:downloaderBlk
                                     alreadyHaveLatestDownloadedMsg:@"You already have the latest version of your account information on your device."
                                                  postDownloadSaver:postDownloadSaverBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:nil
                                                   itemLocalDeleter:nil
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:REntityUpdatedNotification
                                      entityRemovedNotificationName:REntityDeletedNotification
                                                 masterEntityLoader:^id(NSNumber *localMasterIdentifier) {
                                                   return [_coordDao masterUserWithId:localMasterIdentifier error:[RUtils localFetchErrorHandlerMaker]()];
                                                 }
                                      reauthReqdPostEditActivityBlk:^(UIViewController *ctrl) {[[ctrl navigationController] popViewControllerAnimated:YES];}
                                 actionIfReauthReqdNotifObservedBlk:^(UIViewController *ctrl) {
                                   [[ctrl navigationController] popViewControllerAnimated:YES];
                                 }
                                           promptCurrentPasswordBlk:[self makePromptCurrentPasswordBlk]
                                                       panelToolkit:_panelToolkit
                                                    promptGoOffline:NO
                                                         importedAt:nil
                                            importLimitExceededMask:nil
                                             hasExceededImportLimit:nil
                                                     isUserVerified:[self newIsUserVerifiedBlk]
                                                    deletedCallback:nil
                                                     viewDidLoadBlk:nil
                                                    dismissCallback:nil];
  };
}

#pragma mark - Profile & Settings Screens

- (RAuthScreenMaker)newUserSettingsDetailScreenMakerWithSettings:(RUserSettings *)userSettings {
  return ^ UIViewController * {
    PESaveEntityBlk userSettingsSaver = ^(PEAddViewEditController *ctrl, RUserSettings *userSettings) {
      [_coordDao saveUserSettings:userSettings error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEMarkAsDoneEditingLocalBlk doneEditingUserSettingsLocal = ^(PEAddViewEditController *ctrl, RUserSettings *userSettings) {
      [_coordDao markAsDoneEditingUserSettings:userSettings error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
      });
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PEMarkAsDoneEditingImmediateSyncBlk doneEditingUserSettingsImmediateSync = ^(PEAddViewEditController *ctrl,
                                                                                 RUserSettings *userSettings,
                                                                                 PESyncNotFoundBlk notFoundBlk,
                                                                                 PESyncSuccessBlk successBlk,
                                                                                 PESyncRetryAfterBlk retryAfterBlk,
                                                                                 PESyncServerTempErrorBlk tempErrBlk,
                                                                                 PESyncServerErrorBlk errBlk,
                                                                                 PESyncAuthRequiredBlk authReqdBlk,
                                                                                 PESyncForbiddenBlk forbiddenBlk,
                                                                                 PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving profile and settings account to the server";
      NSString *recordTitle = @"Profile and settings";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao markAsDoneEditingAndSyncUserSettingsImmediate:userSettings
                                                       forUser:user
                                       writeUserReadonlyFields:YES
                                           notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                                addlSuccessBlk:^{
                                                  successBlk(1, mainMsgFragment, recordTitle);
                                                  [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                                  dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                                }
                                        addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                        addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                            addlRemoteErrorBlk:^(NSInteger errMask) {errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSaveUsrErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                           addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                                              addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                                                         error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEUploaderBlk uploader = ^(PEAddViewEditController *ctrl,
                               RUserSettings *userSettings,
                               PESyncNotFoundBlk notFoundBlk,
                               PESyncSuccessBlk successBlk,
                               PESyncRetryAfterBlk retryAfterBlk,
                               PESyncServerTempErrorBlk tempErrBlk,
                               PESyncServerErrorBlk errBlk,
                               PESyncAuthRequiredBlk authReqdBlk,
                               PESyncForbiddenBlk forbiddenBlk,
                               PESyncDependencyUnsynced depUnsyncedBlk) {
      NSString *mainMsgFragment = @"saving profile and settings to the server";
      NSString *recordTitle = @"Profile and settings";
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao flushUnsyncedChangesToUserSettings:userSettings
                                            forUser:user
                            writeUserReadonlyFields:YES
                                notFoundOnServerBlk:^{notFoundBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                     addlSuccessBlk:^{
                                       successBlk(1, mainMsgFragment, recordTitle);
                                       [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
                                       dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
                                     }
                             addlRemoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(1, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                             addlTempRemoteErrorBlk:^{tempErrBlk(1, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                 addlRemoteErrorBlk:^(NSInteger errMask){errBlk(1, mainMsgFragment, recordTitle, [RUtils computeSetErrMsgs:errMask]); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                addlAuthRequiredBlk:^{authReqdBlk(1, mainMsgFragment, recordTitle);}
                                   addlForbiddenBlk:^{forbiddenBlk(1, mainMsgFragment, recordTitle);}
                                              error:[RUtils localSaveErrorHandlerMaker]()];
    };
    PEDownloaderBlk downloaderBlk = ^ (PEAddViewEditController *ctrl,
                                       RUserSettings *userSettings,
                                       PESyncNotFoundBlk notFoundBlk,
                                       PEDownloadSuccessBlk successBlk,
                                       PESyncRetryAfterBlk retryAfterBlk,
                                       PESyncServerTempErrorBlk tempErrBlk,
                                       PESyncAuthRequiredBlk authReqdBlk,
                                       PESyncForbiddenBlk forbiddenBlk) {
      NSString *mainMsgFragment = @"fetching profile and settings";
      NSString *recordTitle = @"Profile and settings";
      float percentOfFetching = 1.0;
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      [_coordDao fetchUserSettingsWithGlobalId:[userSettings globalIdentifier]
                               ifModifiedSince:[userSettings updatedAt]
                                       forUser:user
                           notFoundOnServerBlk:^{notFoundBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                    successBlk:^(RUserSettings *fetchedUserSettings) {successBlk(percentOfFetching, mainMsgFragment, recordTitle, fetchedUserSettings); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                            remoteStoreBusyBlk:^(NSDate *retryAfter){retryAfterBlk(percentOfFetching, mainMsgFragment, recordTitle, retryAfter); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                            tempRemoteErrorBlk:^{tempErrBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                           addlAuthRequiredBlk:^{authReqdBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}
                                  forbiddenBlk:^{forbiddenBlk(percentOfFetching, mainMsgFragment, recordTitle); dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });}];
    };
    PEPostDownloaderSaver postDownloadSaverBlk = ^ (PEAddViewEditController *ctrl,
                                                    RUserSettings *downloadedUserSettings,
                                                    RUserSettings *userSettings) {
      PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
      downloadedUserSettings.synced = YES;
      [_coordDao saveMasterUserSettings:downloadedUserSettings forUser:user writeUserReadonlyFields:YES error:[RUtils localSaveErrorHandlerMaker]()];
      dispatch_async(dispatch_get_main_queue(), ^{ [APP refreshTabs]; });
    };
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    return [PEAddViewEditController viewEntityCtrlrWithParentEntity:nil
                                                             entity:userSettings
                                                 listViewController:nil
                                                    entityIndexPath:nil
                                                          uitoolkit:_uitoolkit
                                                     itemChangedBlk:nil
                                               entityFormPanelMaker:[_panelToolkit userSettingsFormPanelMakerWithDefaultWeightUomBlk:^{ return userSettings.weightUom; }
                                                                                                                   defaultSizeUomBlk:^{ return userSettings.sizeUom; }]
                                               entityViewPanelMaker:[_panelToolkit userSettingsViewPanelMaker]
                                                entityToPanelBinder:[_panelToolkit userSettingsToUserSettingsPanelBinder]
                                                panelToEntityBinder:[_panelToolkit userSettingsFormPanelToUserSettingsBinder]
                                                        entityTitle:@"Profile and Settings"
                                                  entityNavbarTitle:@"Prof. & Settings"
                                               panelEnablerDisabler:[_panelToolkit userSettingsFormPanelEnablerDisabler]
                                                  entityAddCanceler:nil
                                                        entitySaver:userSettingsSaver
                                             doneEditingEntityLocal:doneEditingUserSettingsLocal
                                     doneEditingEntityImmediateSync:doneEditingUserSettingsImmediateSync
                                                    isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                     isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                       isBadAccount:^{ return [user isBadAccount]; }
                                  allowedToRemoteSaveWithBadAccount:NO
                                    allowedToDownloadWithBadAccount:NO
                                                      isOfflineMode:^{ return [APP offlineMode]; }
                                     syncImmediateMBProgressHUDMode:MBProgressHUDModeIndeterminate
                                     prepareUIForUserInteractionBlk:nil
                                                   viewDidAppearBlk:nil
                                                    entityValidator:nil
                                                           uploader:uploader
                                             uploadedSuccessMessage:@"Your profile and settings have been uploaded successfully."
                                              numRemoteDepsNotLocal:nil
                                                  fetchDependencies:nil
                                                    updateDepsPanel:nil
                                                         downloader:downloaderBlk
                                     alreadyHaveLatestDownloadedMsg:@"You already have the latest version of your profile and settings on your device."
                                                  postDownloadSaver:postDownloadSaverBlk
                                                itemChildrenCounter:nil
                                                itemChildrenMsgsBlk:nil
                                                        itemDeleter:nil
                                                   itemLocalDeleter:nil
                                              modalOperationStarted:[self commonModalOperationStartedBlock]
                                                 modalOperationDone:[self commonModalOperationDoneBlock]
                                      entityUpdatedNotificationName:REntityUpdatedNotification
                                      entityRemovedNotificationName:REntityDeletedNotification
                                                 masterEntityLoader:^id(NSNumber *localMasterIdentifier) {
                                                   return [_coordDao masterUserSettingsWithId:localMasterIdentifier error:[RUtils localFetchErrorHandlerMaker]()];
                                                 }
                                      reauthReqdPostEditActivityBlk:^(UIViewController *ctrl) {
                                        [[ctrl navigationController] popViewControllerAnimated:YES];
                                      }
                                 actionIfReauthReqdNotifObservedBlk:^(UIViewController *ctrl) {
                                   [[ctrl navigationController] popViewControllerAnimated:YES];
                                 }
                                           promptCurrentPasswordBlk:nil
                                                       panelToolkit:_panelToolkit
                                                    promptGoOffline:YES
                                                         importedAt:nil
                                            importLimitExceededMask:nil
                                             hasExceededImportLimit:nil
                                                     isUserVerified:[self newIsUserVerifiedBlk]
                                                    deletedCallback:nil
                                                     viewDidLoadBlk:nil
                                                    dismissCallback:nil];
  };
}

#pragma mark - File Picker Screen

- (RUnauthScreenMaker)newImportFilePickerScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                               screenTitle:(NSString *)screenTitle
                                                          fileNameContains:(NSString *)fileNameContains {
  return ^ UIViewController *(void) {
    PEPageLoaderBlk pageLoader = ^ NSArray * (id anything) {
      NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
      NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
      NSMutableArray *desiredFiles = [NSMutableArray array];
      for (NSString *file in files) {
        //if ([file containsString:fileNameContains] && ![file containsString:@".csv.imported"]) {
        if (![file containsString:@".csv.imported"]) {
          [desiredFiles addObject:[NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, file]];
        }
      }
      return [desiredFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *file1, NSString *file2) {
        return [file2 compare:file1];
      }];
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(NSString *file) {
      return [file lastPathComponent];
    }
                                                                                 titleFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[NSString class]
                                                                    title:screenTitle
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:nil
                                                            addItemAction:nil
                                                           cellIdentifier:@"RFileCell"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(id item){return YES;}
                                                     wouldBeIndexOfEntity:nil
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:NO
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:nil
                                            entityUpdatedNotificationName:nil
                                            entityRemovedNotificationName:nil
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:YES];
  };
}


#pragma mark - User Stat Screens

- (RAuthScreenMaker)newUserStatsLaunchScreenMakerWithParentController:(UIViewController *)parentController {
  return ^UIViewController * {
    return [[UIViewController alloc] initWithNibName:nil bundle:nil];
  };
}

#pragma mark - Home Screen

- (RAuthScreenMaker)newHomeScreenMaker {
  return ^UIViewController * {
    return [[RDashboardV2Controller alloc] initWithStoreCoordinator:_coordDao
                                                    userSettingsBlk:_userSettingsBlk
                                                          uitoolkit:_uitoolkit
                                                      screenToolkit:self
                                                       panelToolkit:_panelToolkit
                                                               user:[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()]];
  };
}

#pragma mark - Chart Config Aggregate-by Picker Screen

- (RUnauthScreenMaker)newChartConfigAggregateBySelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                            initialSelectedAggregateByVal:(NSArray *)initialSelectedAggregateByVal {
  return ^ UIViewController *(void) {
    PEPageLoaderBlk pageLoader = ^ NSArray * (id anything) {
      return @[@[@(RChartConfigAggregateByDay), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByDay]],
                 @[@(RChartConfigAggregateByWeek), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByWeek]],
                 @[@(RChartConfigAggregateByMonth), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByMonth]],
                 @[@(RChartConfigAggregateByQuarter), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByQuarter]],
                 @[@(RChartConfigAggregateByHalfYear), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByHalfYear]],
                 @[@(RChartConfigAggregateByYear), [RChartConfig nameForAggregateByValue:RChartConfigAggregateByYear]]];
    };
    PETableCellContentViewStyler tableCellStyler = [PELMUIUtils syncViewStylerWithTitleBlk:^(NSArray *initialSelectedAggregateByVal) {return initialSelectedAggregateByVal[1];}
                                                                                 titleFont:nil
                                                                          smallSubTitleBlk:nil
                                                                        rightSideViewMaker:nil
                                                                    alwaysTopifyTitleLabel:NO
                                                                                 uitoolkit:_uitoolkit
                                                                      subtitleLeftHPadding:15.0
                                                                  subtitleFitToWidthFactor:1.0
                                                                                isLoggedIn:[APP isUserLoggedIn]
                                                                              isEntityType:NO
                                                                   importLimitExceededMask:nil
                                                     importedNotAllowedUnverifiedEmailMask:nil];
    return [[PEListViewController alloc] initWithClassOfDataSourceObjects:[NSArray class]
                                                                    title:@"Aggregate by"
                                                    isPaginatedDataSource:NO
                                                          tableCellStyler:tableCellStyler
                                                       itemSelectedAction:itemSelectedAction
                                                      initialSelectedItem:initialSelectedAggregateByVal
                                                            addItemAction:nil
                                                           cellIdentifier:@"RChartConfigAggregateBy"
                                                           initialObjects:nil //pageLoader(nil) - deprecated
                                                               pageLoader:pageLoader
                                                            cellHeightBlk:[self heightForCellsBlk]
                                                          detailViewMaker:nil
                                                                uitoolkit:_uitoolkit
                                           doesEntityBelongToThisListView:^BOOL(id item){return YES;}
                                                     wouldBeIndexOfEntity:nil
                                                          isAuthenticated:^{ return [APP doesUserHaveValidAuthToken]; }
                                                           isUserLoggedIn:^{ return [APP isUserLoggedIn]; }
                                                             isBadAccount:nil
                                                      itemChildrenCounter:nil
                                                      itemChildrenMsgsBlk:nil
                                                              itemDeleter:nil
                                                         itemLocalDeleter:nil
                                                             isEntityType:NO
                                                         viewDidAppearBlk:nil
                                              entityAddedNotificationName:nil
                                            entityUpdatedNotificationName:nil
                                            entityRemovedNotificationName:nil
                                                           tableViewStyle:UITableViewStylePlain
                                                            rowsInSection:nil
                                                  titleForHeaderInSection:nil
                                                       dataObjectAccessor:nil
                                                              cancellable:NO];
  };
}

#pragma mark - Records Screen

- (RAuthScreenMaker)newRecordsScreenMaker {
  return ^ UIViewController * {
    return [[RRecordsController alloc] initWithStoreCoordinator:_coordDao
                                                userSettingsBlk:_userSettingsBlk
                                                      uitoolkit:_uitoolkit
                                                  screenToolkit:self
                                                    panelTookit:_panelToolkit];
  };
}

#pragma mark - Apple Watch Screen

- (RUnauthScreenMaker)newAppleWatchScreenMaker {
  return ^UIViewController * {
    return [[RAppleWatchController alloc] initWithStoreCoordinator:_coordDao uitoolkit:_uitoolkit screenToolkit:self panelTookit:_panelToolkit];
  };
}

#pragma mark - Info Screen

- (RUnauthScreenMaker)newGeneralInfoScreenMaker {
  return ^UIViewController * {
    return [[RGeneralInfoController alloc] initWithStoreCoordinator:_coordDao uitoolkit:_uitoolkit screenToolkit:self panelToolkit:_panelToolkit];
  };
}

- (RUnauthScreenMaker)newUseRikerWithoutAccountScreenMaker {
  return ^UIViewController * {
    NSString *leftIcon = [PEUIUtils objIfiPhone5Width:@"info-icon" iphone6Width:@"info-icon" iphone6PlusWidth:@"info-icon" ipad:@"info"];
    return [[RInfoScreen alloc] initWithTitle:@"Riker Without Account"
                                      heading:nil
                                     sections:@[@[@"Can I use Riker without creating\nan account?",
                                                  AS(USE_RIKER_WITHOUT_ACCOUNT_TEXT),
                                                  leftIcon]]
                                    uitoolkit:_uitoolkit
                                screenToolkit:self
                               viewDidLoadBlk:^{

                               }];
  };
}

- (RUnauthScreenMaker)newAfterTrialOptionsPeriodScreenMakerWithSubscriptionProduct:(SKProduct *)subscriptionProduct {
  return ^UIViewController * {
    NSString *leftIcon = [PEUIUtils objIfiPhone5Width:@"info-icon" iphone6Width:@"info-icon" iphone6PlusWidth:@"info-icon" ipad:@"info"];
    NSMutableAttributedString *enroll = [[NSMutableAttributedString alloc] init];
    [enroll appendAttributedString:AS(@"Enroll in a Riker subscription and continue to enjoy the benefits of having a Riker account.")];
    [enroll appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nThe cost is %@ per year."
                                                            textToAccent:[RUtils formattedPriceOfProduct:subscriptionProduct]
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]];
    NSDictionary *spacingAttrs = [PEUIUtils paragraphBeforeSpacingAttrs];
    [enroll appendAttributedString:ASA(@"\nAdditional info:", [PEUIUtils attrsWithPpBeforeSpacing:[PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:16.0 ipad:22.0]])];
    [RUtils appendiTunesSubscriptionInfoToAttrString:enroll
                                      prependNewline:YES
                                 subscriptionProduct:subscriptionProduct
                                   spacingAttributes:spacingAttrs];
    return [[RInfoScreen alloc] initWithTitle:@"Choices After Trial"
                                      heading:@"After the 90-day trial, you'll have 2 choices for continuing with Riker:"
                                     sections:@[@[@"1. Enroll in a subscription",
                                                  enroll,
                                                  leftIcon],
                                                @[@"2. Use Riker app exclusively",
                                                  AS(USE_RIKER_EXCLUSIVELY_TEXT),
                                                  leftIcon]
                                                ]
                                    uitoolkit:_uitoolkit
                                screenToolkit:self
                               viewDidLoadBlk:^{

                               }];
  };
}

- (RUnauthScreenMaker)newRikerAccountBenefitsScreenMaker {
  return ^UIViewController * {
    NSString *leftIcon = [PEUIUtils objIfiPhone5Width:@"green-filled-checkmark-icon"
                                         iphone6Width:@"green-filled-checkmark-icon"
                                     iphone6PlusWidth:@"green-filled-checkmark-icon"
                                                 ipad:@"green-filled-checkmark-med"];
    NSMutableAttributedString *syncableToAllDevices = [[NSMutableAttributedString alloc] init];
    [syncableToAllDevices appendAttributedString:AS(@"With a Riker account, your data is syncable to all of your devices, including:\n")];
    NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
    NSAttributedString *devicesList = ASA(@"\t\u2022 iPhones and iPads", attrs);
    [syncableToAllDevices appendAttributedString:devicesList];
    //[syncableToAllDevices appendAttributedString:AS(@"\n\t\u2022 Android phones and tablets")];
    //[syncableToAllDevices appendAttributedString:AS(@"\n\t\u2022 Kindle Fire")];
    [syncableToAllDevices appendAttributedString:AS(@"\n\t\u2022 Web")];
    NSArray *sections = @[@[@"Syncable to all your devices",
                            syncableToAllDevices,
                            leftIcon,
                            ^{ [RUtils logExpandingInfoContentViewed:@"syncable_to_all_devices"]; }],
                          @[@"Safe storage of your data",
                            AS(@"With a Riker account, your data is safely and securely stored on our servers, making it accessible to all your devices."),
                            leftIcon,
                            ^{ [RUtils logExpandingInfoContentViewed:@"safe_storage_of_your_data"]; }],
                          @[@"Web access",
                            AS(@"With a Riker account, you'll be able to access your data from the Riker web site."),
                            leftIcon,
                            ^{ [RUtils logExpandingInfoContentViewed:@"web_access"]; }]
                          ];
    return [[RInfoScreen alloc] initWithTitle:@"Riker Account Benefits"
                                      heading:@"There are several benefits to having a Riker account subscription:"
                                     sections:sections
                                    uitoolkit:_uitoolkit
                                screenToolkit:self
                               viewDidLoadBlk:^{}];
  };
}

#pragma mark - Enter Body Weight Screen

- (RUnauthScreenMaker)newBodyWeightInputScreenMakerWithDismissedBlk:(void(^)(void))dismissedBlk {
  return ^UIViewController * {
    return [[REnterMeasurementScreen alloc] initWithStoreCoordinator:_coordDao
                                                               title:@"Enter Body Weight"
                                                          headerText:@"Body Weight"
                                                     saveButtonTitle:@"Save Body Log"
                                                        mutateBmlBlk:^(RBodyMeasurementLog *bml, NSString *value, NSNumber *uomId, RUserSettings *userSettings) {
                                                          bml.sizeUom = userSettings.sizeUom; // always want to have this field non-nil
                                                          bml.bodyWeightUom = uomId;
                                                          bml.bodyWeight = [NSDecimalNumber decimalNumberWithString:value];
                                                        }
                                                     defaultUomIdBlk:^NSNumber *(RUserSettings *userSettings) { return userSettings.weightUom; }
                                             uomDefaultPrefixMessage:@"Weight unit default can be set in your"
                                                          uomNameBlk:^NSString *(NSNumber *uomId) { return [RUtils weightUnitNameForUomId:uomId]; }
                                              valueTfPlaceholderText:@"Body Weight"
                                                          uomOptions:@[@[LBS_NAME, @(LBS_ID)], @[KG_NAME, @(KG_ID)]]
                                                        keyboardType:UIKeyboardTypeDecimalPad
                                                          toValueBlk:^NSNumber *(NSString *value, NSNumber *uomId, NSNumber *targetUomId) {
                                                            return [RUtils weightValueWithValue:[NSDecimalNumber decimalNumberWithString:value]
                                                                             currentWeightUomId:uomId
                                                                              targetWeightUomId:targetUomId];
                                                          }
                                               maximumFractionDigits:1
                                                         dismissable:YES
                                                        dismissedBlk:dismissedBlk
                                                     userSettingsBlk:_userSettingsBlk
                                                           uitoolkit:_uitoolkit
                                                       screenToolkit:self
                                                         panelTookit:_panelToolkit];
  };
}

#pragma mark - Enter Body Measurement Log starting point Screen

- (RUnauthScreenMaker)newSelectBodyPartScreenMaker {
  UIViewController *(^makeSizeInputController)(NSString *, SEL) = ^UIViewController *(NSString *sizeType, SEL setter) {
    return [[REnterMeasurementScreen alloc] initWithStoreCoordinator:_coordDao
                                                               title:[NSString stringWithFormat:@"Enter %@ Size", sizeType]
                                                          headerText:[NSString stringWithFormat:@"%@ Size", sizeType]
                                                     saveButtonTitle:@"Save Body Log"
                                                        mutateBmlBlk:^(RBodyMeasurementLog *bml, NSString *value, NSNumber *uomId, RUserSettings *userSettings) {
                                                          bml.bodyWeightUom = userSettings.weightUom; // always want to have this field non-nil
                                                          bml.sizeUom = uomId;
                                                          #pragma clang diagnostic push
                                                          #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                                          [bml performSelector:setter withObject:[NSDecimalNumber decimalNumberWithString:value]];
                                                          #pragma clang diagnostic pop
                                                        }
                                                     defaultUomIdBlk:^NSNumber *(RUserSettings *userSettings) { return userSettings.sizeUom; }
                                             uomDefaultPrefixMessage:@"Size unit default can be set in your"
                                                          uomNameBlk:^NSString *(NSNumber *uomId) { return [RUtils sizeUnitNameForUomId:uomId]; }
                                              valueTfPlaceholderText:[NSString stringWithFormat:@"%@ Size", sizeType]
                                                          uomOptions:@[@[INCHES_NAME, @(INCHES_ID)], @[CM_NAME, @(CM_ID)]]
                                                        keyboardType:UIKeyboardTypeDecimalPad
                                                          toValueBlk:^NSNumber *(NSString *value, NSNumber *uomId, NSNumber *targetUomId) {
                                                            return [RUtils sizeValueWithValue:[NSDecimalNumber decimalNumberWithString:value]
                                                                             currentSizeUomId:uomId
                                                                              targetSizeUomId:targetUomId];
                                                          }
                                               maximumFractionDigits:1
                                                         dismissable:YES
                                                        dismissedBlk:nil
                                                     userSettingsBlk:_userSettingsBlk
                                                           uitoolkit:_uitoolkit
                                                       screenToolkit:self
                                                         panelTookit:_panelToolkit];
  };
  UIViewController *(^makeBodyWeightInputController)(void) = ^UIViewController * {
    return [self newBodyWeightInputScreenMakerWithDismissedBlk:nil]();
  };
  return ^UIViewController * {
    RSelectScreen *selectBodyPart =
    [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                    coordDao:_coordDao
                               screenToolkit:self
                                       title:@"What to Measure?"
                                 breadcrumbs:@[]
                                itemsFetcher:^{ return @[@[@(RBmlTypeBodyWeight), @"Body Weight"],
                                                         @[@(RBmlTypeArms), @"Arms"],
                                                         @[@(RBmlTypeChest), @"Chest"],
                                                         @[@(RBmlTypeCalves), @"Calfs"],
                                                         @[@(RBmlTypeThighs), @"Thighs"],
                                                         @[@(RBmlTypeForearms), @"Forearms"],
                                                         @[@(RBmlTypeWaist), @"Waist"],
                                                         @[@(RBmlTypeNeck), @"Neck"],
                                                         @[@(RBmlTypeSeveral), @"I want to log several"] // need to give different color treatment (bootstrap-semi?)
                                                         ]; }
                       titleForSelectButtons:^(NSArray *bmlType2Tuple) { return bmlType2Tuple[1]; }
                              actionOnSelect:^(UIViewController *controller, NSArray *bmlType2Tuple) {
                                RBmlType bmlType = ((NSNumber *)bmlType2Tuple[0]).integerValue;
                                UIViewController *nextController = nil;
                                switch (bmlType) {
                                  case RBmlTypeBodyWeight:
                                    nextController = makeBodyWeightInputController();
                                    break;
                                  case RBmlTypeArms:
                                    nextController = makeSizeInputController(@"Arm", @selector(setArmSize:));
                                    break;
                                  case RBmlTypeChest:
                                    nextController = makeSizeInputController(@"Chest", @selector(setChestSize:));
                                    break;
                                  case RBmlTypeCalves:
                                    nextController = makeSizeInputController(@"Calf", @selector(setCalfSize:));
                                    break;
                                  case RBmlTypeThighs:
                                    nextController = makeSizeInputController(@"Thigh", @selector(setThighSize:));
                                    break;
                                  case RBmlTypeForearms:
                                    nextController = makeSizeInputController(@"Forearm", @selector(setForearmSize:));
                                    break;
                                  case RBmlTypeWaist:
                                    nextController = makeSizeInputController(@"Waist", @selector(setWaistSize:));
                                    break;
                                  case RBmlTypeNeck:
                                    nextController = makeSizeInputController(@"Neck", @selector(setNeckSize:));
                                    break;
                                  case RBmlTypeSeveral:
                                    nextController = [self newAddBmlScreenMakerWithDelegate:^(UIViewController *ctrl, id record) {
                                      [ctrl dismissViewControllerAnimated:YES completion:nil];
                                    }
                                                                         listViewController:nil]();
                                    break;
                                }
                                [controller.navigationController pushViewController:nextController animated:YES];
                              }
                                 cancellable:YES
                          colorForLastButton:[UIColor rikerAppBlack]
                         isMovementSelection:NO
                   movementSearchBarVPadding:0.0];
    return selectBodyPart;
  };
}

#pragma mark - Enter Reps

- (RUnauthScreenMaker)newSelectMovementVariantScreenMakerWithBodySegmentName:(NSString *)bodySegmentName
                                                                 muscleGroup:(RMuscleGroup *)muscleGroup
                                                                    movement:(RMovement *)movement
                                                                 cancellable:(BOOL)cancellable
                                                        enterRepsDismissable:(BOOL)enterRepsDismissable {
  return ^UIViewController * {
    NSMutableArray *breadcrumbs = [NSMutableArray array];
    if (bodySegmentName) {
      [breadcrumbs addObject:bodySegmentName];
    }
    if (muscleGroup) {
      [breadcrumbs addObject:muscleGroup.name];
    }
    if (movement) {
      [breadcrumbs addObject:movement.canonicalName];
    }
    return
    [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                    coordDao:_coordDao
                               screenToolkit:self
                                       title:@"Select Movement Variant"
                                 breadcrumbs:breadcrumbs
                                itemsFetcher:^{ return [_coordDao movementVariantsForMovementVariantMask:movement.variantMask error:[RUtils localFetchErrorHandlerMaker]()]; }
                       titleForSelectButtons:^(RMovementVariant *variant) { return variant.name; }
                              actionOnSelect:^(UIViewController *controller, RMovementVariant *variant) {
                                UIViewController *enterReps = [self newEnterRepsScreenMakerWithMovement:movement
                                                                                                variant:variant
                                                                                            dismissable:enterRepsDismissable]();
                                [controller.navigationController pushViewController:enterReps animated:YES];
                              }
                                 cancellable:cancellable
                          colorForLastButton:nil
                         isMovementSelection:NO
                   movementSearchBarVPadding:0.0];
  };
}

- (RUnauthScreenMaker)newSelectMuscleGroupScreenMakerWithBodySegmentId:(NSNumber *)bodySegmentId
                                                       bodySegmentName:(NSString *)bodySegmentName
                                                           cancellable:(BOOL)cancellable
                                                  enterRepsDismissable:(BOOL)enterRepsDismissable {
  return ^UIViewController * {
    RSelectScreen *selectMuscleGroup =
    [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                    coordDao:_coordDao
                               screenToolkit:self
                                       title:@"Select Muscle Group"
                                 breadcrumbs:@[bodySegmentName]
                                itemsFetcher:^{ return [_coordDao muscleGroupsForBodySegmentId:bodySegmentId error:[RUtils localFetchErrorHandlerMaker]()]; }
                       titleForSelectButtons:^(RMuscleGroup *muscleGroup) { return muscleGroup.name; }
                              actionOnSelect:^(UIViewController *controller, RMuscleGroup *muscleGroup) {
                                RSelectScreen *selectMovement =
                                [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                                                coordDao:_coordDao
                                                           screenToolkit:self
                                                                   title:@"Select Movement"
                                                             breadcrumbs:@[bodySegmentName, muscleGroup.name]
                                                            itemsFetcher:^{ return [_coordDao movementsForMuscleGroupId:muscleGroup.localMasterIdentifier error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                   titleForSelectButtons:^(RMovement *movement) { return movement.canonicalName; }
                                                          actionOnSelect:^(UIViewController *controller, RMovement *movement) {
                                                            void(^launchEnterReps)(UIViewController *, RMovementVariant *) = ^(UIViewController *controller, RMovementVariant *variant) {
                                                              UIViewController *enterReps = [self newEnterRepsScreenMakerWithMovement:movement
                                                                                                                              variant:variant
                                                                                                                          dismissable:enterRepsDismissable]();
                                                              [controller.navigationController pushViewController:enterReps animated:YES];
                                                            };
                                                            if (movement.variantMask && movement.variantMask.integerValue != 0) {
                                                              NSArray *variants = [_coordDao movementVariantsForMovementVariantMask:movement.variantMask error:[RUtils localFetchErrorHandlerMaker]()];
                                                              if (variants.count > 1) {
                                                                RSelectScreen *selectVariant =
                                                                [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                                                                                coordDao:_coordDao
                                                                                           screenToolkit:self
                                                                                                   title:@"Select Movement Variant"
                                                                                             breadcrumbs:@[bodySegmentName, muscleGroup.name, movement.canonicalName]
                                                                                            itemsFetcher:^{ return variants; }
                                                                                   titleForSelectButtons:^(RMovementVariant *variant) { return variant.name; }
                                                                                          actionOnSelect:^(UIViewController *controller, RMovementVariant *variant) {
                                                                                            launchEnterReps(controller, variant);
                                                                                          }
                                                                                             cancellable:NO
                                                                                      colorForLastButton:nil
                                                                                     isMovementSelection:NO
                                                                               movementSearchBarVPadding:0.0];
                                                                [controller.navigationController pushViewController:selectVariant animated:YES];
                                                              } else {
                                                                launchEnterReps(controller, variants[0]);
                                                              }
                                                            } else {
                                                              launchEnterReps(controller, nil);
                                                            }
                                                          }
                                                             cancellable:NO
                                                      colorForLastButton:nil
                                                     isMovementSelection:YES
                                               movementSearchBarVPadding:0.0];
                                [controller.navigationController pushViewController:selectMovement animated:YES];
                              }
                                 cancellable:cancellable
                          colorForLastButton:nil
                         isMovementSelection:NO
                   movementSearchBarVPadding:0.0];
    return selectMuscleGroup;
  };
}

- (RUnauthScreenMaker)newSelectBodySegmentScreenMaker {
  return ^UIViewController * {
    return [[RSelectScreen alloc] initWithUitoolkit:_uitoolkit
                                           coordDao:_coordDao
                                      screenToolkit:self
                                              title:@"Select Body Segment"
                                        breadcrumbs:@[]
                                       itemsFetcher:^{ return [_coordDao bodySegmentsWithError:[RUtils localFetchErrorHandlerMaker]()]; }
                              titleForSelectButtons:^(RBodySegment *bodySegment) { return bodySegment.name; }
                                     actionOnSelect:^(UIViewController *controller, RBodySegment *bodySegment) {
                                       [controller.navigationController pushViewController:[self newSelectMuscleGroupScreenMakerWithBodySegmentId:bodySegment.localMasterIdentifier
                                                                                                                                  bodySegmentName:bodySegment.name
                                                                                                                                      cancellable:YES
                                                                                                                             enterRepsDismissable:YES]()
                                                                                  animated:YES];
                                     }
                                        cancellable:YES
                                 colorForLastButton:nil
                                isMovementSelection:NO
                          movementSearchBarVPadding:[PEUIUtils valueIfiPhoneXSMaxOrXrInPortrait:24.0 other:0.0]];
    // ^^^ Very weird bug that only effects the "select" screen right here and only on Xs Max and Xr devices, in portrait mode.  Without the added vpadding,
    // the movement search screen would be behind the nav bar partially.
  };
}

- (RUnauthScreenMaker)newEnterRepsScreenMakerWithMovement:(RMovement *)movement
                                                  variant:(RMovementVariant *)variant
                                              dismissable:(BOOL)dismissable {
  return ^UIViewController * {
    return [[REnterRepsScreen alloc] initWithStoreCoordinator:_coordDao
                                                  breadcrumbs:@[]
                                                  dismissable:dismissable
                                              userSettingsBlk:_userSettingsBlk
                                                     movement:movement
                                              movementVariant:variant
                                                    uitoolkit:_uitoolkit
                                                screenToolkit:self
                                                  panelTookit:_panelToolkit];
  };
}

#pragma mark - Account Screen

- (RAuthScreenMaker)newAccountScreenMaker {
  return ^ UIViewController * {
    return [[RAccountController alloc] initWithStoreCoordinator:_coordDao
                                                userSettingsBlk:_userSettingsBlk
                                                      uitoolkit:_uitoolkit
                                                  screenToolkit:self
                                                   panelToolkit:_panelToolkit];
  };
}

#pragma mark - Tab-bar Authenticated Landing Screen

- (RAuthScreenMaker)newTabBarHomeLandingScreenMakerIsLoggedIn:(BOOL)isLoggedIn {
  return ^ UIViewController * {
    UITabBarController *tabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    UIViewController *homeController = [self newHomeScreenMaker]();
    UIViewController *recordsController = [self newRecordsScreenMaker]();
    UIViewController *settingsController = [self newViewSettingsScreenMaker]();
    tabBarController.viewControllers = @[[PEUIUtils navControllerWithRootController:homeController
                                                                navigationBarHidden:NO
                                                                    tabBarItemTitle:@"Home"
                                                                    tabBarItemImage:[UIImage imageNamed:@"tab-home"]
                                                            tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                                         [PEUIUtils navControllerWithRootController:recordsController
                                                                navigationBarHidden:NO
                                                                    tabBarItemTitle:@"Sets and Body Logs"
                                                                    tabBarItemImage:[UIImage imageNamed:@"tab-records"]
                                                            tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-records"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]],
                                         [PEUIUtils navControllerWithRootController:settingsController
                                                                navigationBarHidden:NO
                                                                    tabBarItemTitle:@"Settings"
                                                                    tabBarItemImage:[UIImage imageNamed:@"tab-settings"]
                                                            tabBarItemSelectedImage:[[UIImage imageNamed:@"tab-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]]
                                         ];
    return tabBarController;
  };
}

@end
