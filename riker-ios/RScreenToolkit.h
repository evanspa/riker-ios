//
//  RScreenToolkit.h
//  riker-ios
//
//  Created by PEVANS on 10/27/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCoordinatorDao.h"
#import "PEUIToolkit.h"
#import "PEListViewController.h"
#import "PEUIUtils.h"
#import "RUtils.h"

@class PELMUser;
@class RSet;
@class SKProduct;

typedef UIViewController * (^RUnauthScreenMaker)(void);
typedef UIViewController * (^RAuthScreenMaker)(void);
typedef void (^WeightTfDefaultedNotice)(RMovement *, RBodyMeasurementLog *, NSNumber *, NSString *, UIViewController *);

@interface RScreenToolkit : NSObject

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
                   uitoolkit:(PEUIToolkit *)uitoolkits
             userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Properties

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

#pragma mark - Generic Screens

- (RUnauthScreenMaker)newDatePickerScreenMakerWithTitle:(NSString *)title
                                    initialSelectedDate:(NSDate *)date
                                         datePickerMode:(UIDatePickerMode)datePickerMode
                                    logDatePickedAction:(void(^)(NSDate *))logDatePickedAction;

- (RUnauthScreenMaker)newWeightUnitsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                         initialSelectedWeightUom:(NSArray *)initialSelectedWeightUom;

- (RUnauthScreenMaker)newSizeUnitsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                         initialSelectedSizeUom:(NSArray *)initialSelectedSizeUom;

- (RUnauthScreenMaker)newGendersForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                     initialSelectedGenderVal:(NSArray *)initialSelectedGenderVal;

#pragma mark - Body Measurement Log Screens

- (RAuthScreenMaker)newViewBmlsScreenMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk;

- (RAuthScreenMaker)newViewUnsyncedBmlsScreenMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk;

- (RAuthScreenMaker)newAddBmlScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                  listViewController:(PEListViewController *)listViewController;

- (RAuthScreenMaker)newBmlDetailScreenMakerWithBml:(RBodyMeasurementLog *)bml
                                      bmlIndexPath:(NSIndexPath *)bmlIndexPath
                                    itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                listViewController:(PEListViewController *)listViewController
                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk;

#pragma mark - Set Screens

- (WeightTfDefaultedNotice)weightTfDefaultedToBodyWeightMaker;

- (RAuthScreenMaker)newViewSetsScreenMakerWithMovementsBlk:(NSDictionary *(^)(void))movementsBlk
                                    allMovementVariantsBlk:(NSDictionary *(^)(void))allMovementVariantsBlk
                                         defaultMovementId:(NSNumber *)defaultMovementId
                                  defaultMovementVariantId:(NSNumber *)defaultMovementVariantId
                             mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                       movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                     originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk;

- (RAuthScreenMaker)newViewUnsyncedSetsScreenMakerWithMovementsBlk:(NSDictionary *(^)(void))movementsBlk
                                            allMovementVariantsBlk:(NSDictionary *(^)(void))allMovementVariantsBlk
                                               movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                                     mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight;

- (RAuthScreenMaker)newAddSetScreenMakerWithDelegate:(PEItemAddedBlk)itemAddedBlk
                                  listViewController:(PEListViewController *)listViewController
                                   defaultMovementId:(NSNumber *)defaultMovementId
                            defaultMovementVariantId:(NSNumber *)defaultMovementVariantId
                       mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                        movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                 movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk;

- (RAuthScreenMaker)newSetDetailScreenMakerWithSet:(RSet *)set
                                      setIndexPath:(NSIndexPath *)setIndexPath
                                    itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                listViewController:(PEListViewController *)listViewController
                                      movementsBlk:(NSDictionary *(^)(void))movementsBlk
                               movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                             originationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                     mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                   deletedCallback:(void(^)(void))deletedCallback;

#pragma mark - Movement Screens

- (RUnauthScreenMaker)newMovementsScreenMakerWithTitle:(NSString *)title
                                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                               initialSelectedMovement:(RMovement *)initialSelectedMovement;

- (RUnauthScreenMaker)newMovementInfoScreenMakerWithMovement:(RMovement *)movement
                                       enableStartSetButtons:(BOOL)enableStartSetButtons;

#pragma mark - Movement Variant Screens

- (RUnauthScreenMaker)newMovementVariantsForSelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                        initialSelectedMovementVariant:(RMovementVariant *)initialSelectedMovementVariant
                                                                              movement:(RMovement *)movement;

#pragma mark - Drafts Screens

- (RAuthScreenMaker)newViewUnsyncedEditsScreenMaker;

#pragma mark - Settings Screens

- (RAuthScreenMaker)newViewSettingsScreenMaker;

#pragma mark - User Account Screens

- (RAuthScreenMaker)newUserAccountDetailScreenMaker;

#pragma mark - Profile & Settings Screens

- (RAuthScreenMaker)newUserSettingsDetailScreenMakerWithSettings:(RUserSettings *)userSettings;

#pragma mark - File Picker Screen

- (RUnauthScreenMaker)newImportFilePickerScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                               screenTitle:(NSString *)screenTitle
                                                          fileNameContains:(NSString *)fileNameContains;

#pragma mark - User Stat Screens

- (RAuthScreenMaker)newUserStatsLaunchScreenMakerWithParentController:(UIViewController *)parentController;

#pragma mark - Home Screen

- (RAuthScreenMaker)newHomeScreenMaker;

#pragma mark - Chart Config Aggregate-by Picker Screen

- (RUnauthScreenMaker)newChartConfigAggregateBySelectionScreenMakerWithItemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                                                            initialSelectedAggregateByVal:(NSArray *)initialSelectedAggregateByVal;

#pragma mark - Records Screen

- (RAuthScreenMaker)newRecordsScreenMaker;

#pragma mark - Apple Watch Screen

- (RUnauthScreenMaker)newAppleWatchScreenMaker;

#pragma mark - Info Screens

- (RUnauthScreenMaker)newGeneralInfoScreenMaker;

- (RUnauthScreenMaker)newUseRikerWithoutAccountScreenMaker;

- (RUnauthScreenMaker)newAfterTrialOptionsPeriodScreenMakerWithSubscriptionProduct:(SKProduct *)subscriptionProduct;

- (RUnauthScreenMaker)newRikerAccountBenefitsScreenMaker;

#pragma mark - Enter Body Weight Screen

- (RUnauthScreenMaker)newBodyWeightInputScreenMakerWithDismissedBlk:(void(^)(void))dismissedBlk;

#pragma mark - Enter Body Measurement Log starting point Screen

- (RUnauthScreenMaker)newSelectBodyPartScreenMaker;

#pragma mark - Enter Reps

- (RUnauthScreenMaker)newSelectMovementVariantScreenMakerWithBodySegmentName:(NSString *)bodySegmentName
                                                                 muscleGroup:(RMuscleGroup *)muscleGroup
                                                                    movement:(RMovement *)movement
                                                                 cancellable:(BOOL)cancellable
                                                        enterRepsDismissable:(BOOL)enterRepsDismissable;

- (RUnauthScreenMaker)newSelectBodySegmentScreenMaker;

- (RUnauthScreenMaker)newSelectMuscleGroupScreenMakerWithBodySegmentId:(NSNumber *)bodySegmentId
                                                       bodySegmentName:(NSString *)bodySegmentName
                                                           cancellable:(BOOL)cancellable
                                                  enterRepsDismissable:(BOOL)enterRepsDismissable;

- (RUnauthScreenMaker)newEnterRepsScreenMakerWithMovement:(RMovement *)movement
                                                  variant:(RMovementVariant *)variant
                                              dismissable:(BOOL)dismissable;

#pragma mark - Account Screen

- (RAuthScreenMaker)newAccountScreenMaker;

#pragma mark - Tab-bar Authenticated Landing Screen

- (RAuthScreenMaker)newTabBarHomeLandingScreenMakerIsLoggedIn:(BOOL)isLoggedIn;

@end
