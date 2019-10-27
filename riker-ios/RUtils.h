//
//  RUtils.h
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELMDefs.h"
#import "RWatchUtils.h"
#import "RChartConfig.h"

@class PEBaseController;
@class PELMUser;
@class RMovement;
@class RBodyMeasurementLog;
@class RUserSettings;
@protocol RLocalDao;
@protocol RCoordinatorDao;
@class RChartStrengthRawData;
@class RSet;
@class RNormalizedTimeSeriesTupleCollection;
@class RChartBodyRawData;
@class SKProduct;
@class HKHealthStore;
@class RWorkout;
@class WCSession;
@protocol WCSessionDelegate;

typedef void (^REnableUserInteractionBlk)(BOOL);

// http://stackoverflow.com/a/34996246/1034895
#define TICK(XXX) NSDate *XXX = [NSDate date]
#define TOCK(XXX) DDLogDebug(@"%s: %f seconds", #XXX, -[XXX timeIntervalSinceNow])

typedef NSArray * (^ErrMsgsMaker)(NSInteger errCode);

typedef void (^(^ServerBusyHandlerMaker)(MBProgressHUD *, UIViewController *, UIView *))(NSDate *);

typedef void (^(^SynchUnitOfWorkHandlerMaker)(MBProgressHUD *, void(^)(PELMUser *), void(^)(void), UIViewController *, UIView *))(PELMUser *, NSError *);

typedef void (^(^SynchUnitOfWorkHandlerMakerZeroArg)(MBProgressHUD *, void(^)(void), void(^)(void), UIViewController *, UIView *))(NSError *);

typedef void (^(^LocalDatabaseErrorHandlerMakerWithHUD)(MBProgressHUD *, UIViewController *, UIView *))(NSError *, int, NSString *);

typedef void (^(^LocalDatabaseErrorHandlerMaker)(void))(NSError *, int, NSString *);

typedef RUserSettings * (^RUserSettingsBlk)(PELMUser *);

typedef void(^RMovementInserter)(NSNumber *,
NSString *,
BOOL,
NSDecimalNumber *,
NSNumber *,
NSNumber *,
NSArray *,
NSArray *,
NSArray *);

typedef void(^RMovementInserterImp)(NSNumber *,
NSString *,
BOOL,
NSDecimalNumber *,
NSArray *,
NSArray *,
NSArray *,
NSArray *);

typedef void (^RMovementAliasInserter)(NSInteger, NSInteger, NSString *);
typedef void (^ROriginationDeviceInserter) (NSNumber *, NSString *, NSString *);
typedef void (^RSecondaryMovementInserter)(NSInteger, NSInteger);
typedef void (^RMovementVariantMaskUpdater)(NSInteger, NSArray *);
typedef void (^RMuscleGroupInserter)(NSNumber *, NSNumber *, NSString *, NSString *);
typedef void (^RMuscleInserter)(NSNumber *, NSNumber *, NSString *, NSString *);

FOUNDATION_EXPORT NSInteger  const LBS_ID;
FOUNDATION_EXPORT NSString * const LBS_NAME;

FOUNDATION_EXPORT NSInteger  const KG_ID;
FOUNDATION_EXPORT NSString * const KG_NAME;

FOUNDATION_EXPORT NSInteger  const INCHES_ID;
FOUNDATION_EXPORT NSString * const INCHES_NAME;

FOUNDATION_EXPORT NSInteger const  CM_ID;
FOUNDATION_EXPORT NSString * const CM_NAME;

FOUNDATION_EXPORT NSString * const GENDER_MALE;
FOUNDATION_EXPORT NSInteger const GENDER_MALE_VAL;

FOUNDATION_EXPORT NSString * const GENDER_FEMALE;
FOUNDATION_EXPORT NSInteger const GENDER_FEMALE_VAL;

FOUNDATION_EXPORT NSInteger const DEFAULT_MOVEMENT_ID;
FOUNDATION_EXPORT NSInteger const DEFAULT_MOVEMENT_VARIANT_ID;

FOUNDATION_EXPORT NSInteger const DEFAULT_WEIGHT_UNITS;
FOUNDATION_EXPORT NSInteger const DEFAULT_SIZE_UNITS;
FOUNDATION_EXPORT NSInteger const DEFAULT_DISTANCE_UNITS;
FOUNDATION_EXPORT NSInteger const DEFAULT_WEIGHT_INC_DEC_AMOUNT;

FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_WEB;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_PEBBLE;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_IPHONE;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_IPAD;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_APPLE_WATCH;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_ANDROID_WEAR;
FOUNDATION_EXPORT NSInteger const ORIGINATION_DEVICE_ID_ANDROID;

FOUNDATION_EXPORT NSInteger const UPPER_BODY_SEGMENT_ID;
FOUNDATION_EXPORT NSInteger const LOWER_BODY_SEGMENT_ID;

FOUNDATION_EXPORT NSInteger const SHOULDER_MG_ID;
FOUNDATION_EXPORT NSInteger const CHEST_MG_ID;
FOUNDATION_EXPORT NSInteger const TRICEP_MG_ID;
FOUNDATION_EXPORT NSInteger const CORE_MG_ID;
FOUNDATION_EXPORT NSInteger const BACK_MG_ID;
FOUNDATION_EXPORT NSInteger const CALVES_MG_ID;
FOUNDATION_EXPORT NSInteger const BICEPS_MG_ID;
FOUNDATION_EXPORT NSInteger const FOREARMS_MG_ID;
FOUNDATION_EXPORT NSInteger const GLUTES_MG_ID;
FOUNDATION_EXPORT NSInteger const QUADRICEPS_MG_ID;
FOUNDATION_EXPORT NSInteger const HAMSTRINGS_MG_ID;
FOUNDATION_EXPORT NSInteger const HIP_ABDUCTORS_MG_ID;
FOUNDATION_EXPORT NSInteger const HIP_FLEXORS_MG_ID;

FOUNDATION_EXPORT CGFloat const IPHONE_5_PORTRAIT_WIDTH;
FOUNDATION_EXPORT CGFloat const IPHONE_5_PORTRAIT_HEIGHT;

FOUNDATION_EXPORT CGFloat const IPHONE_6_PORTRAIT_WIDTH;
FOUNDATION_EXPORT CGFloat const IPHONE_6_PORTRAIT_HEIGHT;

FOUNDATION_EXPORT CGFloat const IPHONE_6_PLUS_PORTRAIT_WIDTH;
FOUNDATION_EXPORT CGFloat const IPHONE_6_PLUS_PORTRAIT_HEIGHT;

FOUNDATION_EXPORT CGFloat const IPAD_PRO_12IN_PORTRAIT_WIDTH;
FOUNDATION_EXPORT CGFloat const IPAD_PRO_12IN_PORTRAIT_HEIGHT;

FOUNDATION_EXPORT NSString * const DATE_PATTERN;
FOUNDATION_EXPORT NSString * const DATETIME_PATTERN;

FOUNDATION_EXPORT NSInteger const LMID_KEY_FOR_SINGLE_VALUE_CONTAINER;

FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_BODY_SEGMENT;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_MUSCLE_GROUP;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_MUSCLE;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_MUSCLE_ALIAS;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_MOVEMENT;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_MOVEMENT_VARIANT;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_ORIGINATION_DEVICE;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_USER_ACCOUNT;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_USER_SETTINGS;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_SET;
FOUNDATION_EXPORT NSString * const CHANGELOG_DETAIL_BML;

FOUNDATION_EXPORT CGFloat const PRIMARY_MUSCLE_PERCENTAGE;

// Sugar for getting localized strings
#define LS(key) NSLocalizedString(key, nil)

#define AS(str) [[NSAttributedString alloc] initWithString:str]

#define ASA(str, attrs) [[NSAttributedString alloc] initWithString:str attributes:attrs]

// Sugar for getting handle to application delegate
#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])

typedef NSAttributedString *(^AsMaker)(NSString *, NSString *);

typedef NS_ENUM(NSInteger, RChartDataFetchMode) {
  RChartDataFetchModeWeightLiftedLine = 1,
  RChartDataFetchModeWeightLiftedDist,
  RChartDataFetchModeRepsLine,
  RChartDataFetchModeRepsDist,
  RChartDataFetchModeTimeBetweenSetsLine,
  RChartDataFetchModeTimeBetweenSetsDist,
  RChartDataFetchModeAllCrossSection, // not used anymore (but will keep in case fetch-mode is used in any cache keys)
  RChartDataFetchModeWeightLiftedCrossSection,
  RChartDataFetchModeRepsCrossSection,
  RChartDataFetchModeTimeBetweenSetsCrossSection
};

@interface RUtils : NSObject

#pragma mark - Logout

+ (void)logoutWithController:(UIViewController *)controller
                    coordDao:(id<RCoordinatorDao>)coordDao
        watchSessionDelegate:(id<WCSessionDelegate>)watchSessionDelegate
  isFbLogoutFromNotification:(BOOL)isFbLogoutFromNotification
                 hudDelegate:(id<MBProgressHUDDelegate>)hudDelegate;

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
                             onSuccessDialogDismiss:(void(^)(void))onSuccessDialogDismiss;

#pragma mark - sync all

+ (void)syncAllWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
                    uiInteraction:(BOOL)simpleToastIfAllSuccess
                       controller:(PEBaseController *)controller;

#pragma mark - Workout Helpers

+ (NSArray *)workoutsTupleForDescendingSets:(NSArray *)descendingSets
                                       user:(PELMUser *)user
                               userSettings:(RUserSettings *)userSettings
                           allMovementsDict:(NSDictionary *)allMovementsDict
                        allMuscleGroupsDict:(NSDictionary *)allMuscleGroupsDict
                             allMusclesDict:(NSDictionary *)allMusclesDict
                                   forWatch:(BOOL)forWatch
                                   coordDao:(id<RLocalDao>)coordDao
                                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Apple Watch Helpers

+ (void)initiateAllDataToAppleWatchTransferWithCoordDao:(id<RCoordinatorDao>)coordDao
                                   watchSessionDelegate:(id<WCSessionDelegate>)watchSessionDelegate;

+ (void)transferAllDataToAppleWatchInBgWithCoordDao:(id<RCoordinatorDao>)coordDao
                                            session:(WCSession *)session;

+ (NSInteger)handleSaveNewBmlsFromWatchWithPayload:(NSArray *)bmlsPayload
                                          coordDao:(id<RCoordinatorDao>)coordDao
                                       healthStore:(HKHealthStore *)healthStore;

+ (NSInteger)handleSaveNewSetsFromWatchWithPayload:(NSArray *)setsPayload
                                          coordDao:(id<RCoordinatorDao>)coordDao;

//+ (NSMutableDictionary *)wrapAsSuccessPayload:(id)payload;
+ (NSMutableDictionary *)wrapPayload:(id)payload action:(RWatchMsgAction)action;

+ (NSDictionary *)emptySuccessWatchResponse;

+ (NSDictionary *)allDataForAppleWatchWithCoordDao:(id<RLocalDao>)coordDao;

+ (NSDictionary *)setsBmlsAndWorkoutsForAppleWatchWithUser:(PELMUser *)user
                                                  coordDao:(id<RLocalDao>)coordDao
                                              userSettings:(RUserSettings *)userSettings
                                                     error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)appleWatchBmlsWithBmls:(NSArray *)bmls;

+ (NSArray *)appleWatchSetsWithSets:(NSArray *)sets
                   allMovementsDict:(NSDictionary *)allMovementsDict
            allMovementVariantsDict:(NSDictionary *)allMovementVariantsDict;

#pragma mark - Healthkit

+ (void)appendHkFailMsgWithType:(NSString *)type
                            msg:(NSMutableAttributedString *)msg
                prependNewlines:(BOOL)prependNewlines
             includePrivacyInfo:(BOOL)includePrivacyInfo
                          error:(NSError *)error;

+ (void)appendHkSyncPromptAlertDesc:(NSMutableAttributedString *)syncPromptDesc
                      numSetsToSync:(NSInteger)numSetsToSync
                      numBmlsToSync:(NSInteger) numBodyWeightLogsToSync;

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
                                uiInteraction:(BOOL)uiInteraction;

+ (void)saveHealthKitWorkoutsWithCompletion:(void(^)(NSInteger, NSInteger, BOOL, NSError *))completion
               forceSyncAllComputedWorkouts:(BOOL)forceSyncAllComputedWorkouts
                   raiseNotificationOnError:(BOOL)raiseNotificationOnError
                                   coordDao:(id<RCoordinatorDao>)coordDao
                                healthStore:(HKHealthStore *)healthStore;

+ (void)saveHealthKitBmlsWithCompletion:(void(^)(NSInteger, BOOL, NSError *))completion
                                noOpBlk:(void(^)(void))noOpBlk
               raiseNotificationOnError:(BOOL)raiseNotificationOnError
                               coordDao:(id<RCoordinatorDao>)coordDao
                            healthStore:(HKHealthStore *)healthStore;

+ (void)setLastHkWorkoutEndDate:(NSDate *)endDate;

+ (NSDate *)lastHkWorkoutEndDate;

+ (void)clearHkWorkoutEndDate;

+ (void)setHkWorkoutSaveDisabledAt:(NSDate *)deniedDate;

+ (NSDate *)hkWorkoutSaveDisabledAt;

+ (void)clearHkWorkoutDisabledAt;

+ (void)setLastHkBodyWeightEndDate:(NSDate *)endDate;

+ (NSDate *)lastHkBodyWeightEndDate;

+ (void)clearHkBodyWeightEndDate;

+ (void)setHkBodyWeightSaveDisabledAt:(NSDate *)deniedDate;

+ (NSDate *)hkBodyWeightSaveDisabledAt;

+ (void)clearHkBodyWeightDisabledAt;

+ (NSDate *)healthKitEnabledAt;

+ (void)setHealthKitEnabledAt:(NSDate *)enabledAt;

+ (void)disableHealthKit;

#pragma mark - Weight Format Helpers

+ (NSNumberFormatter *)weightNumberFormatter;

+ (NSString *(^)(NSNumber *))weightFormatOrNilMaker;

#pragma mark - Weight Lifted - Attributed Strings

+ (NSAttributedString *)weightLiftedMetricDesc;
+ (NSAttributedString *)aggregateWeightLiftedPieChartsHelpDesc;
+ (NSAttributedString *)aggregateWeightLiftedTimelineChartsHelpDesc;
+ (NSAttributedString *)avgWeightLiftedTimelineChartsHelpDesc;
+ (NSAttributedString *)weightLiftedDistributionTimelineChartsHelpDesc;

#pragma mark - Reps - Attributed Strings

+ (NSAttributedString *)repsMetricDesc;
+ (NSAttributedString *)aggregateRepsLiftedPieChartsHelpDesc;
+ (NSAttributedString *)aggregateRepsLiftedTimelineChartsHelpDesc;
+ (NSAttributedString *)avgRepsPerSetTimelineChartsHelpDesc;
+ (NSAttributedString *)repsDistributionTimelineChartsHelpDesc;

#pragma mark - Time Between Sets - Attributed Strings

+ (NSAttributedString *)timeBetweenSetsMetricDesc;
+ (NSAttributedString *)aggregateTimeBetweenSetsSameMovPieChartsHelpDesc;
+ (NSAttributedString *)aggregateTimeBetweenSetsTimelineChartsHelpDesc;
+ (NSAttributedString *)avgTimeBetweenSetsPerSetTimelineChartsHelpDesc;
+ (NSAttributedString *)timeBetweenSetsSameMovLiftedDistributionTimelineChartsHelpDesc;

#pragma mark - Chart Helpers

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
                                          calcAverages:(BOOL)calcAverages;

+ (RChartBodyRawData *)chartBodyDataForUser:(PELMUser *)user
                            userSettings:(RUserSettings *)userSettings                            
                                    bmls:(NSArray *)bmls;

+ (RNormalizedTimeSeriesTupleCollection *)normalizeUsingGroupIntervalInDays:(NSInteger)groupSizeInDays
                                                                  firstDate:(NSDate *)firstDate
                                                                   lastDate:(NSDate *)lastDate
                                                           withRawContainer:(NSDictionary *)rawContainer
                                                          calculateAverages:(BOOL)calculateAverages
                                                     calculateDistributions:(BOOL)calculateDistributions
                                                                    logging:(BOOL)logging;

+ (NSString *)dictKeyForMovementId:(NSNumber *)movementId movementVariantId:(NSNumber *)movementVariantId;

+ (BOOL)doesSet:(RSet *)set1 haveSameMovementVariantAsSet:(RSet *)set2;

+ (void(^)(NSDictionary *, NSNumber *, NSDecimalNumber *, NSDate *))makeAddToBlk;

+ (void (^)(NSMutableDictionary *, NSDate *))makeHolePluggerCalcPercentages:(BOOL)calcPercentages
                                                               calcAverages:(BOOL)calcAverages;

+ (NSString *)globalChartIdWithCategory:(RChartConfigCategory)category user:(PELMUser *)user;

#pragma mark - Analytics Helpers

+ (void)logScreen:(NSString *)screenTitle fromController:(UIViewController *)controller;

+ (void)logEvent:(NSString *)event;

+ (void)logEvent:(NSString *)event params:(NSDictionary *)params;

+ (void)logNewSetEventWithSet:(RSet *)newSet;

+ (void)logExpandingInfoContentViewed:(NSString *)contentName;

+ (void)logHelpInfoPopupContentViewed:(NSString *)contentName;

+ (NSMutableDictionary *)eventLogParamsWithNumRecords:(NSInteger)numRecords;

+ (NSMutableDictionary *)eventLogParamsWithErrMask:(NSInteger)errMask;

+ (NSMutableDictionary *)eventLogParamsWithSyncAttemptErrors:(NSInteger)syncAttemptErrors;

#pragma mark - General Helpers

+ (void)appendiTunesSubscriptionInfoToAttrString:(NSMutableAttributedString *)subscriptionInfo
                                  prependNewline:(BOOL)prependNewline
                             subscriptionProduct:(SKProduct *)subscriptionProduct
                               spacingAttributes:(NSDictionary *)spacingAttrs;

+ (NSString *)formattedPriceOfProduct:(SKProduct *)product;

+ (AsMaker)asMakerWithFontTextStyle:(UIFontTextStyle)fontTextStyle;

+ (void)contactRikerSupport;

+ (NSString *)truncatedText:(NSString *)text maxLength:(NSInteger)maxLength;

+ (NSString *)weightUnitNameForUomId:(NSNumber *)uomId;

+ (NSString *)sizeUnitNameForUomId:(NSNumber *)uomId;

+ (NSString *)genderNameForGenderVal:(NSNumber *)genderVal;

+ (NSDecimalNumber *)weightValueWithValue:(NSDecimalNumber *)value
                       currentWeightUomId:(NSNumber *)currentWeightUomId
                        targetWeightUomId:(NSNumber *)targetWeightUomId;

+ (NSDecimalNumber *)sizeValueWithValue:(NSDecimalNumber *)value
                       currentSizeUomId:(NSNumber *)currentSizeUomId
                        targetSizeUomId:(NSNumber *)targetSizeUomId;

+ (NSDictionary *)dictFromMasterEntitiesArray:(NSArray *)masterEntities;

+ (NSString *)deviceName;

+ (BOOL)is32bitIphone;

#pragma mark - User Helpers

+ (NSString *)hashedValueForAccountName:(NSString*)userAccountName;
+ (NSArray *)computeSignInErrMsgs:(NSUInteger)signInErrMask;
+ (NSArray *)computeSaveUsrErrMsgs:(NSInteger)saveUsrErrMask;

#pragma mark - Body Measurement Log Helpers

+ (NSArray *)computeBmlErrMsgs:(NSInteger)bmlErrMask;

#pragma mark - Set Helpers

+ (NSArray *)computeSetErrMsgs:(NSInteger)setErrMask;

+ (NSArray *)filterMovementVariants:(NSArray *)movementVariants
                          usingMask:(NSInteger)variantMask;

#pragma mark - Various Error Handler Helpers

+ (ServerBusyHandlerMaker)serverBusyHandlerMakerForUIWithButtonAction:(void(^)(void))buttonAction;
+ (SynchUnitOfWorkHandlerMakerZeroArg)loginHandlerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker;
+ (SynchUnitOfWorkHandlerMaker)synchUnitOfWorkHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker;
+ (SynchUnitOfWorkHandlerMakerZeroArg)synchUnitOfWorkZeroArgHandlerMakerWithErrMsgsMaker:(ErrMsgsMaker)errMsgsMaker;
+ (LocalDatabaseErrorHandlerMakerWithHUD)localDatabaseErrorHudHandlerMaker;
+ (LocalDatabaseErrorHandlerMaker)localSaveErrorHandlerMaker;
+ (LocalDatabaseErrorHandlerMaker)localFetchErrorHandlerMaker;
+ (LocalDatabaseErrorHandlerMaker)localErrorHandlerForBackgroundProcessingMaker;
+ (LocalDatabaseErrorHandlerMaker)localDatabaseCreationErrorHandlerMaker;

@end
