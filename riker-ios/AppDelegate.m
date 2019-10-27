//
//  AppDelegate.m
//  riker-ios
//
//  Created by PEVANS on 10/10/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "AppDelegate.h"

#import <iAd/iAd.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import <Stripe/Stripe.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <AFNetworking/AFNetworking.h>
@import Firebase;
#import "RAppNotificationNames.h"
#import "PELMNotificationNames.h"
#import "PEUtils.h"
#import "RUtils.h"
#import "RErrorDomainsAndCodes.h"
#import "RCoordinatorDao.h"
#import "RCoordinatorDaoImpl.h"
#import "RLogging.h"
#import "HCCharset.h"
#import "PELMUser.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "UIColor+RAdditions.h"
#import "RSplashController.h"
#import "PELMUser.h"
#import "PELMMainSupport.h"
#import "RSet.h"
#import "RUIUtils.h"
#import "PEBaseController.h"
@import HealthKit;
#import <DateTools/DateTools.h>
#import "RBodyMeasurementLog.h"
#import "RWatchUtils.h"
#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RUserSettings.h"
#import "RWorkout.h"
#import "RAbstractChartController.h"
#import "RChartIdPrefixes.h"
#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedLineChartDataEntry.h"
#import "RChartBodyRawData.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <Toast/Toast.h>
#import "UIWindow+RAdditions.h"

id (^bundleVal)(NSString *) = ^(NSString *key) {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
};

int (^intBundleVal)(NSString *) = ^(NSString *key) {
  return [(NSNumber *)bundleVal(key) intValue];
};

BOOL (^boolBundleVal)(NSString *) = ^(NSString *key) {
  return [bundleVal(key) boolValue];
};

// Keys in app plist
NSString * const RRestServiceTimeoutKey                 = @"timeout";
NSString * const RRestServicePreferredCharsetKey        = @"Riker REST service preferred charset";
NSString * const RRestServicePreferredLanguageKey       = @"Riker REST service preferred language";
NSString * const RRestServicePreferredFormatKey         = @"Riker REST service preferred format";
NSString * const RRestServiceMtVersionKey               = @"Riker REST service mt-version";
NSString * const RAuthenticationSchemeKey               = @"Riker Authentication scheme";
NSString * const RAuthenticationTokenNameKey            = @"Riker Authentication token param name";
NSString * const RAppleSearchAdsAttributionPathCompKey  = @"Riker Search Ads Attribution REST path component";
NSString * const RErrorMaskHeaderNameKey                = @"Riker error mask header name";
NSString * const RTransactionIdHeaderNameKey            = @"Riker transaction id header name";
NSString * const REstablishSessionHeaderNameKey         = @"Riker establish session header name";
NSString * const RUserAgentDeviceMakeHeaderNameKey      = @"Riker user agent device make header name";
NSString * const RUserAgentDeviceOsHeaderNameKey        = @"Riker user agent device os header name";
NSString * const RUserAgentDeviceOsVersionHeaderNameKey = @"Riker user agent device os version header name";
NSString * const RAuthTokenResponseHeaderNameKey        = @"Riker auth token response header name";
NSString * const RIfModifiedSinceHeaderNameKey          = @"Riker if-modified-since header name";
NSString * const RIfUnmodifiedSinceHeaderNameKey        = @"Riker if-unmodified-since header name";
NSString * const RLoginFailedReasonHeaderNameKey        = @"Riker login failed reason header name";
NSString * const RAccountClosedReasonHeaderNameKey      = @"Riker account closed reason header name";
NSString * const RTimeoutForCoordDaoMainThreadOpsKey    = @"Riker timeout for main thread coordinator dao operations";
NSString * const RTimeIntervalForFlushToRemoteMasterKey = @"Riker time interval for flush to remote master";
NSString * const RIsUserLoggedInIndicatorKey            = @"Riker is user logged in indicator";
NSString * const RSupportEmailKey                       = @"Riker support email";
NSString * const RIapSubscriptionProductIdentifierKey   = @"Riker IAP Subscription Product Identifier";
NSString * const RTermsOfServiceUriKey                  = @"Riker terms of service uri";
NSString * const RTermsOfServiceBareNavUriKey           = @"Riker terms of service bare nav uri";
NSString * const RPrivacyPolicyUriKey                   = @"Riker privacy policy uri";
NSString * const RPrivacyPolicyBareNavUriKey            = @"Riker privacy policy bare nav uri";
NSString * const RSecurityPolicyUriKey                  = @"Riker security policy uri";
NSString * const RSecurityPolicyBareNavUriKey           = @"Riker security policy bare nav uri";
NSString * const RFaqUriKey                             = @"Riker faq uri";
NSString * const RFaqBareNavUriKey                      = @"Riker faq bare nav uri";

// Tab-bar controller indexes
typedef NS_ENUM(NSInteger, RAppTabBarIndex) {
  RAppTabBarIndexHome,
  RAppTabBarIndexRecords,
  RAppTabBarIndexSettings
};

// NSUserDefaults keys
NSString * const RChangelogUpdatedAtUserDefaultsKey = @"Riker changelog updated at";
NSString * const RSuppressWeightTfDefaultedToBodyWeightPopupKey = @"RSuppressWeightTfDefaultedToBodyWeightPopupKey";
NSString * const RMaintenanceAckAtDefaultsKey = @"Riker maintenance acked at";
NSString * const RExperiencedSplashScreenAt = @"RExperiencedSplashScreenAt";
NSString * const RUsedWatchAppAt = @"RUsedWatchAppAt";
NSString * const RFirstLaunchAt = @"RFirstLaunchAt";
NSString * const ROfflineModeEnabledAt = @"ROfflineModeEnabledAt";
NSString * const RIPhone32BitLineChartMsgAckAtKey = @"RIPhone32BitLineChartMsgAckAtKey";

#ifdef RIKER_DEV
NSString * const RStripeApiKey = @"Riker Stripe Test Api Key";
NSString * const RApiResourceFilename = @"riker-api-resource.localdev";
NSString * const RIKER_ENDPOINT_PREFIX = @"https://dev.rikerapp.com";
#else
NSString * const RStripeApiKey = @"Riker Stripe Prod Api Key";
NSString * const RApiResourceFilename = @"riker-api-resource";
NSString * const RIKER_ENDPOINT_PREFIX = @"https://www.rikerapp.com";
#endif

NSString * const RIKER_ITUNES_APP_ID = @"1196920730";

NSString * const RDataFileExtension = @"data";
NSString * const RLocalSqlLiteDataFileName = @"riker-local-sqlite-datafile";

// Keychain service names
NSString * const RAppKeychainService = @"riker-app";

@implementation AppDelegate {
  MBProgressHUD *_HUD;
  NSString *_authToken;
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  UITabBarController *_tabBarController;
  NSMutableDictionary *_openSets;
  BOOL _offlineMode;
  BOOL _syncFromWatchInProgress;
}

#pragma mark - Record Open (inside PEAddViewEditController)

- (BOOL)isSetOpen:(RSet *)set {
  return [PEUtils isNotNil:set.correlationGuid] && [PEUtils isNotNil:_openSets[set.correlationGuid]];
}

- (void)setOpened:(RSet *)set {
  if (set.correlationGuid) {
    _openSets[set.correlationGuid] = set.correlationGuid;
  }
}

- (void)setClosed:(RSet *)set {
  if (set.correlationGuid) {
    [_openSets removeObjectForKey:set.correlationGuid];
  }
}

- (void)clearOpenSets {
  [_openSets removeAllObjects];
}

#pragma mark - Methods

- (UICKeyChainStore *)rikerKeyChainStore {
  UICKeyChainStore *keyChainStore = [UICKeyChainStore keyChainStoreWithService:@"com.rikerapp.rauth-token"];
  keyChainStore.accessibility = UICKeyChainStoreAccessibilityAlways;
  return keyChainStore;
}

- (void)unlistenToPaymentTransactions {
  [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (NSString *)iapRikerSubscriptionProductIdentifier {
  return bundleVal(RIapSubscriptionProductIdentifierKey);
}

- (NSString *)rikerSupportEmail {
  return bundleVal(RSupportEmailKey);
}

- (NSString *)absoluteRikerUrlFromUri:(NSString *)uri {
  #ifdef RIKER_DEV
  NSString *uriPrefix = @""; // @"/#";  (using the hash is no longer needed because I've changed my dev workflow on the riker-web side to ALWAYS run local node server, so I don't need to use the hash in the URL anymore)
  #else
  NSString *uriPrefix = @"";
  #endif
  return [NSString stringWithFormat:@"%@%@%@", RIKER_ENDPOINT_PREFIX, uriPrefix, uri];
}

- (NSString *)rikerTermsOfServiceUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RTermsOfServiceUriKey)];
}

- (NSString *)rikerTermsOfServiceBareNavUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RTermsOfServiceBareNavUriKey)];
}

- (NSString *)rikerPrivacyPolicyUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RPrivacyPolicyUriKey)];
}

- (NSString *)rikerPrivacyPolicyBareNavUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RPrivacyPolicyBareNavUriKey)];
}

- (NSString *)rikerSecurityPolicyUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RSecurityPolicyUriKey)];
}

- (NSString *)rikerSecurityPolicyBareNavUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RSecurityPolicyBareNavUriKey)];
}

- (NSString *)rikerFaqUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RFaqUriKey)];
}

- (NSString *)rikerHomeUrl {
  return [self absoluteRikerUrlFromUri:@""];
}

- (NSString *)rikerFaqBareNavUrl {
  return [self absoluteRikerUrlFromUri:bundleVal(RFaqBareNavUriKey)];
}

- (void)setUser:(PELMUser *)user tabBarController:(UITabBarController *)tabBarController {
  _tabBarController = tabBarController;
}

- (NSDate *)changelogUpdatedAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults objectForKey:RChangelogUpdatedAtUserDefaultsKey];
}

- (void)setChangelogUpdatedAt:(NSDate *)updatedAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:updatedAt forKey:RChangelogUpdatedAtUserDefaultsKey];
}

- (NSDate *)maintenanceAckAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults objectForKey:RMaintenanceAckAtDefaultsKey];
}

- (void)setMaintenanceAckAt:(NSDate *)ackAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:ackAt forKey:RMaintenanceAckAtDefaultsKey];
}

- (NSString *)urlForImageName:(NSString *)imageName {
  return [NSString stringWithFormat:@"%@/images/%@", RIKER_ENDPOINT_PREFIX, imageName];
}

- (NSDate *)suppressedWeightTfDefaultedToBodyWeightPopupAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults objectForKey:RSuppressWeightTfDefaultedToBodyWeightPopupKey];
}

- (void)setSuppressWeightTfDefaultedToBodyWeightPopup:(NSDate *)value {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:value forKey:RSuppressWeightTfDefaultedToBodyWeightPopupKey];
}

- (NSDate *)iphone32bitLineChartMsgAckAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return [defaults objectForKey:RIPhone32BitLineChartMsgAckAtKey];
}

- (void)setIphone32bitLineChartMsgAckAt:(NSDate *)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:RIPhone32BitLineChartMsgAckAtKey];
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  // could happen - i.e., user installs Riker from App Store, doesn't launch
  // Riker iPhone app, goes right into Watch App, trys to sync some records...this
  // method could get called before the store coordinator is done initializing
  _syncFromWatchInProgress = YES;
  CGFloat delay = 0.0;
  if (![self firstLaunchAt]) {
    delay = 2.0;
  }
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self setUsedWatchAppAt:[NSDate date]];
    NSNumber *action = userInfo[RWATCHMSG_ACTION_KEY];
    switch (action.integerValue) {
      case RWatchMsgActionFetchAllIPhoneData:
        [session transferUserInfo:[RUtils wrapPayload:[RUtils allDataForAppleWatchWithCoordDao:self->_coordDao] action:RWatchMsgActionFetchAllIPhoneDataAck]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          [[[APP window] visibleViewController].view makeToast:@"Data sent to Apple Watch"];
        });
        break;
      case RWatchMsgActionSaveNewSets: {
        NSInteger numSaved = [RUtils handleSaveNewSetsFromWatchWithPayload:userInfo[RWATCHMSG_PAYLOAD_KEY]
                                                                  coordDao:self->_coordDao];
        PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
        PELMUser *user = (PELMUser *)[self->_coordDao userWithError:errorBlk];
        RUserSettings *userSettings = [self->_coordDao userSettingsForUser:user error:errorBlk];
        NSDictionary *setsBmlsAndWorkouts = [RUtils setsBmlsAndWorkoutsForAppleWatchWithUser:user
                                                                                    coordDao:self->_coordDao
                                                                                userSettings:userSettings
                                                                                       error:errorBlk];
        NSMutableDictionary *successPayload = [RUtils wrapPayload:setsBmlsAndWorkouts action:RWatchMsgActionEntitySaveAck];
        successPayload[RWATCHMSG_LOCAL_ENTITY_FILES_KEY] = userInfo[RWATCHMSG_LOCAL_ENTITY_FILES_KEY];
        [session transferUserInfo:successPayload];
        if (numSaved > 0) {
          [self refreshTabs];
          [self regenerateChartCacheAsBgTaskWithCoordDao:self->_coordDao];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[[APP window] visibleViewController].view makeToast:[NSString stringWithFormat:@"%d set%@ received and saved from Apple Watch", numSaved, numSaved > 1 ? @"s" : @""]];
          });
        }
      }
        break;
      case RWatchMsgActionSaveNewBmls: {
        // fyi, this will save the bmls and ALSO will sync the body weight bmls to HK
        NSInteger numSaved = [RUtils handleSaveNewBmlsFromWatchWithPayload:userInfo[RWATCHMSG_PAYLOAD_KEY]
                                                                  coordDao:self->_coordDao
                                                               healthStore:[self healthStore]];
        PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
        PELMUser *user = (PELMUser *)[self->_coordDao userWithError:errorBlk];
        RUserSettings *userSettings = [self->_coordDao userSettingsForUser:user error:errorBlk];
        NSMutableDictionary *successPayload =
        [RUtils wrapPayload:[RUtils setsBmlsAndWorkoutsForAppleWatchWithUser:user
                                                                    coordDao:self->_coordDao
                                                                userSettings:userSettings
                                                                       error:errorBlk]
                     action:RWatchMsgActionEntitySaveAck];
        successPayload[RWATCHMSG_LOCAL_ENTITY_FILES_KEY] = userInfo[RWATCHMSG_LOCAL_ENTITY_FILES_KEY];
        [session transferUserInfo:successPayload];
        if (numSaved > 0) {
          [self refreshTabs];
          [self regenerateChartCacheAsBgTaskWithCoordDao:self->_coordDao];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[[APP window] visibleViewController].view makeToast:[NSString stringWithFormat:@"%d body log%@ received and saved from Apple Watch", numSaved, numSaved > 1 ? @"s" : @""]];
          });
        }
      }
    }
    _syncFromWatchInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
      [self attemptSetSyncToHkAndSyncAllToRikerAccount];
    });
  });
}

#pragma mark - Chart Cache Regeneration

+ (void)regenerateChartCacheWithCoordDao:(id<RCoordinatorDao>)coordDao {
  TICK(CHART_CACHE_REGEN);
  /*****************************************************************************
   One-time needed data
   *****************************************************************************/
  PELMDaoErrorBlk errorBlk = [RUtils localSaveErrorHandlerMaker]();
  PELMUser *user = [coordDao userWithError:errorBlk];
  RUserSettings *userSettings = [coordDao userSettingsForUser:user error:errorBlk];
  // sets (and set related)
  NSArray *bodySegments = [coordDao bodySegmentsWithError:errorBlk];
  NSDictionary *bodySegmentsDict = [RUtils dictFromMasterEntitiesArray:bodySegments];
  NSArray *muscleGroups = [coordDao muscleGroupsWithError:errorBlk];
  NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:muscleGroups];
  NSArray *muscles = [coordDao musclesWithError:errorBlk];
  NSDictionary *musclesDict = [RUtils dictFromMasterEntitiesArray:muscles];
  NSArray *movements = [coordDao movementsWithError:errorBlk];
  NSDictionary *movementsDict = [RUtils dictFromMasterEntitiesArray:movements];
  NSArray *movementVariants = [coordDao movementVariantsWithError:errorBlk];
  NSDictionary *movementVariantsDict = [RUtils dictFromMasterEntitiesArray:movementVariants];
  NSArray *sets = [coordDao ascendingSetsForUser:user error:errorBlk];
  RSet *firstSet = [sets firstObject];
  RSet *lastSet = [sets lastObject];
  NSDate *veryFirstSetOnOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:firstSet.loggedAt];
  NSDate *veryLastSetOnOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:lastSet.loggedAt] dateByAddingDays:1];
  // bmls
  NSArray *bmls = [coordDao ascendingBmlsForUser:user error:errorBlk];
  RBodyMeasurementLog *firstBml = [bmls firstObject];
  RBodyMeasurementLog *lastBml = [bmls lastObject];
  NSDate *veryLastBmlLoggedAt = lastBml.loggedAt;
  NSDate *veryFirstBmlLoggedAt = firstBml.loggedAt;
  /*****************************************************************************
   Helper blocks
   *****************************************************************************/
  RChartStrengthRawData * (^defaultRawData)(RChartDataFetchMode) = ^RChartStrengthRawData * (RChartDataFetchMode fetchMode) {
    return [RUtils chartStrengthRawDataForUser:user
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
                                     fetchMode:fetchMode
                               calcPercentages:YES
                                  calcAverages:YES];
  };
  void (^executeDataLoaders)(id, NSDictionary *, NSDate *, NSDate *) = ^(id defaultRawData, NSDictionary *dictionary, NSDate *veryFirstEntityOnOrAfterLoggedAt, NSDate *veryLastEntityOnOrBeforeLoggedAt) {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull chartId, NSArray * _Nonnull tuple, BOOL * _Nonnull stop) {
      RChartAndLoaderTuple *(^loaderTupleMaker)(void) = tuple[1];
      RChartAndLoaderTuple *loaderTuple = loaderTupleMaker();
      loaderTuple.lineChartDataLoader(defaultRawData,
                                      user,
                                      userSettings,
                                      bodySegments,
                                      bodySegmentsDict,
                                      muscleGroups,
                                      muscleGroupsDict,
                                      muscles,
                                      musclesDict,
                                      movements,
                                      movementsDict,
                                      movementVariants,
                                      movementVariantsDict,
                                      veryFirstEntityOnOrAfterLoggedAt,
                                      veryLastEntityOnOrBeforeLoggedAt);
    }];
  };
  RChartConfig *(^chartConfigLoader)(NSString *) = ^RChartConfig * (NSString *chartId) {
    return [coordDao chartConfigWithChartId:chartId user:user error:errorBlk];
  };
  
  /*****************************************************************************
   Delete the existing chart cache
   *****************************************************************************/
  [coordDao deleteChartCacheForUser:user error:errorBlk];
  
  /* Entities and raw data cache */
  NSMutableDictionary *entitiesAndRawDataCache = [NSMutableDictionary dictionary];
  
  /*****************************************************************************
   Generate the weight lifted chart cache
   *****************************************************************************/
  RChartDataFetchMode fetchMode = RChartDataFetchModeWeightLiftedLine;
  RChartStrengthRawData *defaultRawLineData = defaultRawData(fetchMode);
  // total weight lifted
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:NO
                                                                                  calculateDistributions:NO
                                                                                           chartIdPrefix:CHART_ID_PREFIX_WEIGHT_LIFTED_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:NO
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:YES],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // average weight lifted
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:YES
                                                                                  calculateDistributions:NO
                                                                                           chartIdPrefix:CHART_ID_PREFIX_WEIGHT_LIFTED_AVG_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:NO
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // weight lifted dist / time
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:NO
                                                                                  calculateDistributions:YES
                                                                                           chartIdPrefix:CHART_ID_PREFIX_WEIGHT_LIFTED_DIST_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxDistributionValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.distribution; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:YES
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  /*****************************************************************************
   Generate the reps chart cache
   *****************************************************************************/
  fetchMode = RChartDataFetchModeRepsLine;
  defaultRawLineData = defaultRawData(fetchMode);
  // total reps
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:NO
                                                                                  calculateDistributions:NO
                                                                                           chartIdPrefix:CHART_ID_PREFIX_REPS_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:NO
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // average reps
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:YES
                                                                                  calculateDistributions:NO
                                                                                           chartIdPrefix:CHART_ID_PREFIX_REPS_AVG_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:NO
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // reps dist / time
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                       calculateAverages:NO
                                                                                  calculateDistributions:YES
                                                                                           chartIdPrefix:CHART_ID_PREFIX_REPS_DIST_TIME
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxDistributionValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.distribution; }
                                                                                         strengthConfigs:chartConfigLoader
                                                                                   areDistributionTuples:YES
                                                                                                coordDao:coordDao
                                                                                 entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                 logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  /*****************************************************************************
   Generate the rest-time chart cache
   *****************************************************************************/
  fetchMode = RChartDataFetchModeTimeBetweenSetsLine;
  defaultRawLineData = defaultRawData(fetchMode);
  // total rest time
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                                  calculateAverages:NO
                                                                                             calculateDistributions:NO
                                                                                                      chartIdPrefix:CHART_ID_PREFIX_TBS_TIME
                                                                                                        maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                                                          yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                                                    strengthConfigs:chartConfigLoader
                                                                                              areDistributionTuples:NO
                                                                                                           coordDao:coordDao
                                                                                            entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                            logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // average rest time
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                                  calculateAverages:YES
                                                                                             calculateDistributions:NO
                                                                                                      chartIdPrefix:CHART_ID_PREFIX_TBS_AVG_TIME
                                                                                                        maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                                          yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                                    strengthConfigs:chartConfigLoader
                                                                                              areDistributionTuples:NO
                                                                                                           coordDao:coordDao
                                                                                            entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                            logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  // rest time dist / time
  executeDataLoaders(defaultRawLineData,
                     [RAbstractChartController makeHeadlessTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                                  calculateAverages:NO
                                                                                             calculateDistributions:YES
                                                                                                      chartIdPrefix:CHART_ID_PREFIX_TBS_DIST_TIME
                                                                                                        maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxDistributionValue; }
                                                                                                          yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.distribution; }
                                                                                                    strengthConfigs:chartConfigLoader
                                                                                              areDistributionTuples:YES
                                                                                                           coordDao:coordDao
                                                                                            entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                            logging:NO],
                     veryFirstSetOnOrAfterLoggedAt,
                     veryLastSetOnOrBeforeLoggedAt);
  /*****************************************************************************
   Generate the body chart cache
   *****************************************************************************/
  RChartBodyRawData *defaultBodyRawLineData = [RUtils chartBodyDataForUser:user userSettings:userSettings bmls:bmls];
  void (^executeBodyDataLoaders)(NSMutableDictionary *(^)(RChartBodyRawData *), NSString *) = ^(NSMutableDictionary *(^timeSeriesDictBlk)(RChartBodyRawData *), NSString *chartIdPrefix){
    executeDataLoaders(defaultBodyRawLineData,
                       [RAbstractChartController makeHeadlessBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:timeSeriesDictBlk
                                                                                                                      chartIdPrefix:chartIdPrefix                                                                                                                        maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                                                          yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                                                        bodyConfigs:^(NSString *chartId) { return [coordDao chartConfigWithChartId:chartId user:user error:errorBlk]; }
                                                                                                                           coordDao:coordDao
                                                                                                            entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                                                    calcPercentages:YES
                                                                                                                       calcAverages:NO
                                                                                                                            logging:NO],
                       veryFirstBmlLoggedAt,
                       veryLastBmlLoggedAt);
  };
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.bodyWeightTimeSeries; }, CHART_ID_PREFIX_BODY_WEIGHT);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.armSizeTimeSeries; }, CHART_ID_PREFIX_ARM_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.neckSizeTimeSeries; }, CHART_ID_PREFIX_NECK_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.chestSizeTimeSeries; }, CHART_ID_PREFIX_CHEST_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.forearmSizeTimeSeries; }, CHART_ID_PREFIX_FOREARM_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.waistSizeTimeSeries; }, CHART_ID_PREFIX_WAIST_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.calfSizeTimeSeries; }, CHART_ID_PREFIX_CALF_SIZE);
  executeBodyDataLoaders(^(RChartBodyRawData *chartData) { return chartData.thighSizeTimeSeries; }, CHART_ID_PREFIX_THIGH_SIZE);
  TOCK(CHART_CACHE_REGEN);
}

- (void)regenerateChartCacheAsBgTaskWithCoordDao:(id<RCoordinatorDao>)coordDao {
  UIApplication *application = [UIApplication sharedApplication];
  __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
    DDLogInfo(@"Chart cache regeneration task expiration handler invoked");
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
  }];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [AppDelegate regenerateChartCacheWithCoordDao:coordDao];
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
  });
}

+ (void)regenerateChartCacheOnAppDelegateWithCoordDao:(id<RCoordinatorDao>)coordDao {
  dispatch_async(dispatch_get_main_queue(), ^{
    [APP regenerateChartCacheAsBgTaskWithCoordDao:coordDao];
  });
}

#pragma mark - Methods

- (BOOL)offlineMode {
  return _offlineMode;
}

- (void)setOfflineMode:(BOOL)offlineMode {
  _offlineMode = offlineMode;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if (offlineMode) {
    [defaults setObject:[NSDate date] forKey:ROfflineModeEnabledAt];
  } else {
    [defaults removeObjectForKey:ROfflineModeEnabledAt];
  }
}

- (NSDate *)usedWatchAppAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RUsedWatchAppAt];
}

- (void)setUsedWatchAppAt:(NSDate *)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:RUsedWatchAppAt];
}

- (NSDate *)firstLaunchAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RFirstLaunchAt];
}

- (void)setFirstLaunchAt:(NSDate *)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:RFirstLaunchAt];
}

- (void)setExperiencedSplashScreenAt:(NSDate *)date {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:date forKey:RExperiencedSplashScreenAt];
}

- (NSDate *)experiencedSplashScreenAt {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  return (NSDate *)[defaults objectForKey:RExperiencedSplashScreenAt];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
  BOOL handled = [[FIRDynamicLinks dynamicLinks] handleUniversalLink:userActivity.webpageURL
                                                          completion:^(FIRDynamicLink * _Nullable dynamicLink,
                                                                       NSError * _Nullable error) {                                                
                                                          }];
  return handled;
}

- (BOOL)application:(UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  FIRDynamicLink *dynamicLink = [[FIRDynamicLinks dynamicLinks] dynamicLinkFromCustomSchemeURL:url];
  if (dynamicLink) {
    if (dynamicLink.url) {
      // Handle the deep link. For example, show the deep-linked content,
      // apply a promotional offer to the user's account or show customized onboarding view.
      // ...
    } else {
      // Dynamic link has empty deep link. This situation will happens if
      // Firebase Dynamic Links iOS SDK tried to retrieve pending dynamic link,
      // but pending link is not available for this device/App combination.
      // At this point you may display default onboarding view.
    }
  }
  return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                        openURL:url
                                                        options:options];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [RLogging initializeLogging];
  [self initializeStoreCoordinator];
  [self initializeWatchIntegration];
  [self initializeStripe];
  [self initializeStoreKit];
  [self initializeNotificationObserving];
  [self initializeGlobalAppearanceSettings];
  [self initializeErrMessageCollections];
  [self initializeFirebase];
  [self initializeHealthKitStore];
  [self initializeOfflineMode];
  [self initializeToasting];
  if (![self firstLaunchAt]) {
    [self setFirstLaunchAt:[NSDate date]];
  }
  
  #ifdef RIKER_DEV
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [paths objectAtIndex:0];
    DDLogDebug(@"Docs folder: [%@]", docsDir);
  #endif

  _sets = [[NSMutableDictionary alloc] init];
  _openSets = [[NSMutableDictionary alloc] init];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  _uitoolkit = [AppDelegate defaultUIToolkit];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
  if (!user) {
    [self initializeUser];
    user = (PELMUser *)[_coordDao userWithError:errorBlk];
  }
  // some analytics stuff
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [_coordDao logFirebaseUserProperties];
  });
  _screenToolkit = [[RScreenToolkit alloc] initWithCoordinatorDao:_coordDao
                                                        uitoolkit:_uitoolkit
                                                  userSettingsBlk:^(PELMUser *user) { return [_coordDao userSettingsForUser:user error:errorBlk]; }
                                                            error:errorBlk];
  [_coordDao globalCancelSyncInProgressWithError:[RUtils localSaveErrorHandlerMaker]()];
  if ([self experiencedSplashScreenAt] != nil) {
    _authToken = [self storedAuthenticationTokenForUser:user];
    if (_authToken) {
      [_coordDao.userCoordinatorDao setAuthToken:_authToken];
    }
    if ([self isUserLoggedIn:user]) {      
      if ([self doesUserHaveValidAuthToken:user]) {
        DDLogDebug(@"User is logged in and has a valid authentication token.");
        _tabBarController = (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:YES]();
        [[self window] setRootViewController:_tabBarController];
      } else {
        DDLogDebug(@"User is logged in and does NOT have a valid authentication token.");
        _tabBarController = (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:YES]();
        [[self window] setRootViewController:_tabBarController];
      }
    } else {
      DDLogDebug(@"User is NOT logged in.");
      _tabBarController = (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:NO]();
      [[self window] setRootViewController:_tabBarController];
    }
  } else {
    RSplashController *splashController =
    [[RSplashController alloc] initWithStoreCoordinator:_coordDao
                                              uitoolkit:_uitoolkit
                                          screenToolkit:_screenToolkit
                                              againMode:NO];
    [[self window] setRootViewController:[PEUIUtils navigationControllerWithController:splashController]];
  }
  [self.window setBackgroundColor:[UIColor whiteColor]];
  [self.window makeKeyAndVisible];
  [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0), dispatch_get_main_queue(), ^{
    [self attemptSetSyncToHkAndSyncAllToRikerAccount];
  });
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [_coordDao logFirebaseUserProperties];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [RUtils logEvent:kFIREventAppOpen];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0), dispatch_get_main_queue(), ^{
    [self attemptSetSyncToHkAndSyncAllToRikerAccount];
  });
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
  if ([self experiencedSplashScreenAt] != nil) {
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    [self refreshTabsForUser:user];
  }
  [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [_coordDao logFirebaseUserProperties];
}

#pragma mark - Set Syncing

- (void)attemptSetSyncToHkAndSyncAllToRikerAccount {
  if (_syncFromWatchInProgress) {
    DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, sync from Watch is in progress.  Do nothing.");
  } else {
    DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, sync from Watch is NOT in progress.  Will attempt to sync sets to HK and Riker account (if applicable).");
    void(^syncRecordsToRikerAccount)(void) = ^{
      if ([self isUserLoggedIn] && [self doesUserHaveValidAuthToken]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [RUtils syncAllWithCoordinatorDao:_coordDao
                              uiInteraction:NO
                                 controller:(PEBaseController *)[self.window visibleViewController]];
        });
      }
    };
    BOOL healthKitIntegrationEnabled = [PEUtils isNotNil:[RUtils healthKitEnabledAt]];
    if (healthKitIntegrationEnabled && [PEUtils isNil:[RUtils hkWorkoutSaveDisabledAt]]) {
      [RUtils syncSetsToHealthkitWithSyncPromptDesc:nil
                                   includeFutureMsg:NO
                                 noSetsToSyncAction:^{
                                   DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, no sets to sync to Apple Health.  Proceeding to sync to Riker account (if applicable).");
                                   syncRecordsToRikerAccount();
                                 }
                           displayNoSetsToSyncAlert:NO
                            successOkayButtonAction:^{
                              DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, success syncing to Apple Health.  Proceeding to sync to Riker account (if applicable).");
                              [[NSNotificationCenter defaultCenter] postNotificationName:RWorkoutsSavedToHealthKitNotification
                                                                                  object:nil];
                              syncRecordsToRikerAccount();
                            }
                              errorOkayButtonAction:^{
                                DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, error syncing to Apple Health.  Proceeding to sync to Riker account (if applicable).");
                                [[NSNotificationCenter defaultCenter] postNotificationName:RErrorSavingWorkoutsToHealthKitNotification
                                                                                    object:nil];
                                syncRecordsToRikerAccount();
                              }
                                       notNowAction:^{
                                         DDLogDebug(@"inside attemptSetSyncToHkAndSyncAllToRikerAccount, not now for syncing sets to Apple Health.  Proceeding to sync to Riker account (if applicable).");
                                         syncRecordsToRikerAccount();
                                       }
                                         controller:(PEBaseController *)[self.window visibleViewController]
                                           coordDao:_coordDao
                                        healthStore:self.healthStore
                                      uiInteraction:NO];
    } else {
      syncRecordsToRikerAccount();
    }
  }
}

#pragma mark - Tab Helpers

- (void)setBadgeColorWithTabBarItem:(UITabBarItem *)tabBarItem color:(UIColor *)color {
  if ([tabBarItem respondsToSelector:@selector(setBadgeColor:)]) {
    [tabBarItem setBadgeColor:color];
  }
}

- (void)refreshTabs {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  [self refreshTabsForUser:user];
}

- (void)refreshTabsForUser:(PELMUser *)user {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (_tabBarController &&
        _tabBarController.tabBar &&
        _tabBarController.tabBar.items &&
        _tabBarController.tabBar.items.count > 0) {
      void (^clearEipsBadge)(void) = ^{
        [_tabBarController.tabBar.items[RAppTabBarIndexRecords] setBadgeValue:nil];
      };
      if ([self isUserLoggedIn:user]) {
        if (user) {
          if ([user isInMaintenanceWindow]) {
            [_tabBarController.tabBar.items[RAppTabBarIndexHome] setBadgeValue:@"!"];
            [self setBadgeColorWithTabBarItem:_tabBarController.tabBar.items[RAppTabBarIndexHome] color:[UIColor sunflowerColor]];
          } else if ([user hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:[self maintenanceAckAt]]) {
            [_tabBarController.tabBar.items[RAppTabBarIndexHome] setBadgeValue:@"i"];
            [self setBadgeColorWithTabBarItem:_tabBarController.tabBar.items[RAppTabBarIndexHome] color:[UIColor sunflowerColor]];
          } else {
            [_tabBarController.tabBar.items[RAppTabBarIndexHome] setBadgeValue:nil];
          }
          NSInteger totalNumUnsyncedEdits = [_coordDao totalNumUnsyncedEntitiesForUser:user];
          if (totalNumUnsyncedEdits > 0) {
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [_tabBarController.tabBar.items[RAppTabBarIndexRecords] setBadgeValue:[NSString stringWithFormat:@"%@", [formatter stringFromNumber:@(totalNumUnsyncedEdits)]]];
            [self setBadgeColorWithTabBarItem:_tabBarController.tabBar.items[RAppTabBarIndexRecords] color:[UIColor blackColor]];
          } else {
            clearEipsBadge();
          }
        } else {
          clearEipsBadge();
          [_tabBarController.tabBar.items[RAppTabBarIndexHome] setBadgeValue:nil];
        }
      } else {
        [_tabBarController.tabBar.items[RAppTabBarIndexHome] setBadgeValue:nil];
        clearEipsBadge();
      }
      [self setAccountIssueBadge];
    }
  });
}

#pragma mark - Resetting the user interface and tab bar delegate

- (void)resetUserInterface {
  NSArray *controllers = [_tabBarController viewControllers];
  [controllers[RAppTabBarIndexHome] popToRootViewControllerAnimated:NO];
  [controllers[RAppTabBarIndexRecords] popToRootViewControllerAnimated:NO];
  [controllers[RAppTabBarIndexSettings] popToRootViewControllerAnimated:NO];
  [self refreshTabs];
  _userSettingsOpenFromSettingsScreen = NO;
  _userSettingsOpenFromUnsyncedEditsScreen = NO;
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  for (SKPaymentTransaction *transaction in transactions) {
    switch (transaction.transactionState) {
      case SKPaymentTransactionStatePurchasing:
        DDLogInfo(@"in AppDelegate, SKPaymentTransactionStatePurchasing");
        break;
      case SKPaymentTransactionStateDeferred:
        DDLogInfo(@"in AppDelegate, SKPaymentTransactionStateDeferred");
        [queue finishTransaction:transaction];
        break;
      case SKPaymentTransactionStateFailed:
        DDLogInfo(@"in AppDelegate, SKPaymentTransactionStateFailed");
        [queue finishTransaction:transaction];
        break;
      case SKPaymentTransactionStateRestored:
        DDLogInfo(@"in AppDelegate, SKPaymentTransactionStateRestored");
        [queue finishTransaction:transaction];
        break;
      case SKPaymentTransactionStatePurchased:
        DDLogInfo(@"in AppDelegate, SKPaymentTransactionStatePurchased");
        [queue finishTransaction:transaction];
        break;
    }
  }
}

#pragma mark - Handler for 'Send All Data to Watch notification'

- (void)sendAllDataToWatch {
  WCSession *session = [WCSession defaultSession];
  if ([session activationState] == WCSessionActivationStateActivated) {
    NSDictionary *allDataForAppleWatch = [RUtils allDataForAppleWatchWithCoordDao:_coordDao];
    [session transferUserInfo:@{ RWATCHMSG_PAYLOAD_KEY: allDataForAppleWatch,
                                 RWATCHMSG_ACTION_KEY: @(RWatchMsgActionPushAllIPhoneData),
                                 RWATCHMSG_RAISE_NOTIFICATION_KEY: @(YES) }];
    DDLogInfo(@"inside AppDelegate/sendAllDataToWatch, sending 'all data' to Apple Watch [session state activated].");
  } else {
    DDLogInfo(@"inside AppDelegate/sendAllDataToWathc, Apple Watch session state not activated [state: %ld]", [session activationState]);
  }
}

#pragma mark - Initialization helpers

- (void)initializeToasting {
  [CSToastManager setQueueEnabled:YES];
  CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
  style.cornerRadius = 10.0;
  style.messageColor = [UIColor whiteColor];
  style.backgroundColor = [UIColor rikerAppBlack];
  [CSToastManager setDefaultDuration:3.0];
  [CSToastManager setDefaultPosition:CSToastPositionBottom];
  [CSToastManager setSharedStyle:style];
}

- (void)initializeOfflineMode {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  _offlineMode = [defaults objectForKey:ROfflineModeEnabledAt] != nil;
}

- (void)initializeWatchIntegration {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    if ([WCSession isSupported]) {
      WCSession *session = [WCSession defaultSession];
      session.delegate = self;
      [session activateSession];      
    }
  });
}

- (void)initializeHealthKitStore {
  _healthStore = [[HKHealthStore alloc] init];
}

- (void)initializeFirebase {
  [FIRApp configure];
}

- (void)initializeStoreKit {
  // our delegate will listen for 'renew' transactions for the sole purpose that
  // it can finish them for cleanup reasons.
  SKPaymentQueue *paymentQueue = [SKPaymentQueue defaultQueue];
  [paymentQueue addTransactionObserver:self];
}

+ (PEUIToolkit *)defaultUIToolkit {
  UIColor *rikerAppBlack = [UIColor rikerAppBlack];
  [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor bootstrapPrimary] }
                                           forState:UIControlStateSelected];  
  return [[PEUIToolkit alloc] initWithColorForContentPanels:rikerAppBlack
                                            colorForWindows:[UIColor cloudsColor]
                           topBottomPaddingForContentPanels:15
                                                accentColor:[UIColor colorFromHexCode:@"FFBF40"]
                                          fontForButtonsBlk:^{
                                            return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:32.0]
                                                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]]];
                                          }
                                  verticalPaddingForButtons:[PEUIUtils valueIfiPhone5Width:22.0
                                                                              iphone6Width:24.0
                                                                          iphone6PlusWidth:28.0
                                                                                      ipad:36.0]
                                horizontalPaddingForButtons:[PEUIUtils valueIfiPhone5Width:25.0
                                                                              iphone6Width:25.0
                                                                          iphone6PlusWidth:30.0
                                                                                      ipad:40.0]
                                       fontForTextfieldsBlk:^{
                                         return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:22.0 ipad:26.0]
                                                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                       }
                                         colorForTextfields:[UIColor whiteColor]
                                  heightFactorForTextfields:[PEUIUtils valueIfiPhone5Width:2.075
                                                                              iphone6Width:2.075
                                                                          iphone6PlusWidth:2.485
                                                                                      ipad:3.250]
                               leftViewPaddingForTextfields:[PEUIUtils valueIfiPhone5Width:15.0
                                                                              iphone6Width:16.0
                                                                          iphone6PlusWidth:20.0
                                                                                      ipad:20.0]
                                  fontForTableCellTitlesBlk:^{
                                    return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:22.0 ipad:26.0]
                                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                  }
                                    colorForTableCellTitles:[UIColor blackColor]
                               fontForTableCellSubtitlesBlk:^{
                                 return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:18.0 iphone6Width:20.0 iphone6PlusWidth:20.0 ipad:24.0]
                                                                          font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                                           iphone6Width:UIFontTextStyleCaption1
                                                                                                                                       iphone6PlusWidth:UIFontTextStyleCaption1
                                                                                                                                                   ipad:UIFontTextStyleSubheadline]]];
                               }
                                 colorForTableCellSubtitles:[UIColor grayColor]];
}

- (void)initializeNotificationObserving {
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(resetUserInterface)
                                               name:RAppDeleteAllDataNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(resetUserInterface)
                                               name:RAppAccountCreationNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshTabs)
                                               name:RAppReauthReqdNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshTabs)
                                               name:RAppReauthNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(resetUserInterface)
                                               name:RAppLoginNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sendAllDataToWatch)
                                               name:RSendAllDataToAppleWatchNotification
                                             object:nil];
  /*[[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification
                                                    object:nil
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:
   ^(NSNotification *notification) {
     void (^checkAndDoLogout)(FBSDKAccessToken *) = ^(FBSDKAccessToken *fbAccessToken) {
       PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
       if ([self isUserLoggedIn:user] && user.facebookUserId) {
         if (fbAccessToken == nil || ![user.facebookUserId isEqualToString:fbAccessToken.userID]) {
           UITabBarController * tabBarController = _tabBarController;
           PEBaseController *controller = tabBarController.selectedViewController;
           if (!controller) {
             controller = tabBarController.viewControllers[tabBarController.selectedIndex];
           }
           DDLogInfo(@"The current Facebook access token is old or the user ID does not match the facebookUserId of the current user. %@", NSStringFromClass(controller.class));
           dispatch_async(dispatch_get_main_queue(), ^{
             [RUtils logoutWithController:controller
                                 coordDao:_coordDao
                     watchSessionDelegate:self
               isFbLogoutFromNotification:YES
                              hudDelegate:nil];
           });
         } else {
           DDLogInfo(@"The current Facebook access token user ID matches the current user's faceUserId [%@]", user.facebookUserId);
         }
       }
     };
     DDLogDebug(@"FBSDKAccessTokenDidChangeNotification notification received.  User info: %@", notification.userInfo);
     if (notification.userInfo[FBSDKAccessTokenDidChangeUserID]) {
       FBSDKAccessToken *fbAccessToken = notification.userInfo[FBSDKAccessTokenChangeNewKey];
       if (fbAccessToken) {
         checkAndDoLogout(fbAccessToken);
       } else {
         if (notification.userInfo[FBSDKAccessTokenChangeOldKey]) {
           DDLogInfo(@"FBSDK notification indicates token is old.  Should log user out.");
           checkAndDoLogout(nil);
         }
       }
     } else if (notification.userInfo[FBSDKAccessTokenDidExpire]) {
       // take no action
     }
   }];*/
}

- (void)initializeGlobalAppearanceSettings {
  UIColor *textTintColor = [RUIUtils navbarTextTintColor];
  [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : textTintColor}
                                              forState:UIControlStateNormal];
  [UIImageView appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]].tintColor = textTintColor;
  if ([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
    [UINavigationBar appearance].tintColor = textTintColor;
  }
}

- (void)initializeStripe {
  STPPaymentConfiguration *config = [STPPaymentConfiguration sharedConfiguration];
  [config setPublishableKey:bundleVal(RStripeApiKey)];
  //[config setSmsAutofillDisabled:YES];
}

- (PELMUser *)initializeUser {
  return
  [_coordDao.userCoordinatorDao newLocalUserWithUserSettingsMtVersion:[_coordDao userSettingsResMtVersion]
                                                                error:[RUtils localSaveErrorHandlerMaker]()];
}

- (void)initializeStoreCoordinator {
  NSBundle *mainBundle = [NSBundle mainBundle];
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  NSURL *localSqlLiteDataFileUrl =
  [[fileMgr URLForDirectory:NSLibraryDirectory
                   inDomain:NSUserDomainMask
          appropriateForURL:nil
                     create:YES
                      error:nil]
   URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",
                                RLocalSqlLiteDataFileName,
                                RDataFileExtension]];
  NSString *sqliteDataFilePath = [localSqlLiteDataFileUrl absoluteString];
  DDLogInfo(@"About to load local database from: [%@]", sqliteDataFilePath);
  NSString *restServiceMtVersion = bundleVal(RRestServiceMtVersionKey);
  _coordDao = [[RCoordinatorDaoImpl alloc] initWithSqliteDataFilePath:sqliteDataFilePath
                                            localDatabaseCreationError:[RUtils localDatabaseCreationErrorHandlerMaker]()
                                        timeoutForMainThreadOperations:intBundleVal(RTimeoutForCoordDaoMainThreadOpsKey)
                                                         acceptCharset:[HCCharset UTF8]
                                                        acceptLanguage:bundleVal(RRestServicePreferredLanguageKey)
                                                    contentTypeCharset:[HCCharset UTF8]
                                                            authScheme:bundleVal(RAuthenticationSchemeKey)
                                                    authTokenParamName:bundleVal(RAuthenticationTokenNameKey)
                                                             authToken:nil
                                                   errorMaskHeaderName:bundleVal(RErrorMaskHeaderNameKey)
                                            establishSessionHeaderName:bundleVal(REstablishSessionHeaderNameKey)
                                           authTokenResponseHeaderName:bundleVal(RAuthTokenResponseHeaderNameKey)
                                             ifModifiedSinceHeaderName:bundleVal(RIfModifiedSinceHeaderNameKey)
                                           ifUnmodifiedSinceHeaderName:bundleVal(RIfUnmodifiedSinceHeaderNameKey)
                                           loginFailedReasonHeaderName:bundleVal(RLoginFailedReasonHeaderNameKey)
                                         accountClosedReasonHeaderName:bundleVal(RAccountClosedReasonHeaderNameKey)
                                          bundleHoldingApiJsonResource:mainBundle
                                             nameOfApiJsonResourceFile:RApiResourceFilename
                                                       apiResMtVersion:restServiceMtVersion
                                                 changelogResMtVersion:restServiceMtVersion
                                                      userResMtVersion:restServiceMtVersion
                                              bodySegmentResMtVersion:restServiceMtVersion
                                              muscleGroupResMtVersion:restServiceMtVersion
                                                   muscleResMtVersion:restServiceMtVersion
                                              muscleAliasResMtVersion:restServiceMtVersion
                                                 movementResMtVersion:restServiceMtVersion
                                            movementAliasResMtVersion:restServiceMtVersion
                                          movementVariantResMtVersion:restServiceMtVersion
                                        originationDeviceResMtVersion:restServiceMtVersion
                                             userSettingsResMtVersion:restServiceMtVersion
                                       bodyMeasurementLogResMtVersion:restServiceMtVersion
                                                      setResMtVersion:restServiceMtVersion
                                                     authTokenDelegate:self
                                              allowInvalidCertificates:NO];
  [_coordDao initializeDatabaseWithSqliteDataFilePath:sqliteDataFilePath
                                                error:[RUtils localSaveErrorHandlerMaker]()];
}

- (void)initializeErrMessageCollections {
  _signInErrMessages = @[@[@(RSignInEmailNotProvided),    @"signin.email-notprovided"],
                         @[@(RSignInInvalidEmail),        @"signin.email-invalid"],
                         @[@(RSignInPasswordNotProvided), @"signin.password-notprovided"],
                         @[@(RSignInInvalidCredentials),  @"signin.credentials-invalid"]];
  _saveUserErrMessages = @[@[@(RSaveUsrInvalidEmail),                     @"saveusr.email-invalid"],
                           @[@(RSaveUsrEmailNotProvided),                 @"saveusr.email-notprovided"],
                           @[@(RSaveUsrPasswordNotProvided),              @"saveusr.password-notprovided"],
                           @[@(RSaveUsrEmailAlreadyRegistered),           @"saveusr.email-already-registered"],
                           @[@(RSaveUsrCurrentPasswordNotProvided),       @"saveusr.current-password-not-provided"],
                           @[@(RSaveUsrCurrentPasswordIncorrect),         @"saveusr.current-password-incorrect"],
                           @[@(RSaveUsrPasswordConfirmPasswordDontMatch), @"saveusr.password-confirm-password-dont-match"],
                           @[@(RSaveUsrConfirmPasswordNotProvided),       @"saveusr.confirm-password-notprovided"],
                           @[@(RSaveUsrConfirmPasswordOnlyProvided),      @"saveusr.confirm-password-onlyprovided"]];
  _saveSetErrMessages = @[@[@(RSaveSetImportLimitExceeded),   @"saveset.import-limit-exceeded"],
                          @[@(RSaveSetImportUnverifiedEmail), @"saveset.import-unverified-email"]];
  _saveBmlErrMessages = @[@[@(RSaveBmlImportLimitExceeded),   @"savebml.import-limit-exceeded"],
                          @[@(RSaveBmlImportUnverifiedEmail), @"savebml.import-unverified-email"]];
}

#pragma mark - RAuthTokenDelegate protocol

- (void)didReceiveNewAuthToken:(NSString *)authToken
       forUserGlobalIdentifier:(NSString *)userGlobalIdentifier {
  DDLogDebug(@"Received new authentication token: [%@].  About to store in \
keychain under key: [%@].  Is main thread? %@", authToken, userGlobalIdentifier,
             [PEUtils yesNoFromBool:[NSThread isMainThread]]);
  UICKeyChainStore *keyChainStore = [self rikerKeyChainStore];
  [keyChainStore setString:authToken forKey:userGlobalIdentifier];
  [self setAccountIssueBadge];
  
  //[_keychainStore removeItemForKey:FPAuthenticationRequiredAtKey];
  // FYI, the reason we don't set the authToken on our _coordDao object is because
  // it is doing it itself; i.e., because the auth token is received THROUGH the
  // _coordDao, the _coordDao updates itself as it arrives.
}

- (void)authRequired:(HCAuthentication *)authentication {
  DDLogDebug(@"Notified that 'auth required' from some remote operation.  Therefore \
I'm going to insert this knowledge into the keychian so the app knows it's currently \
in an unauthenticated state.  Is main thread?  %@", [PEUtils yesNoFromBool:[NSThread isMainThread]]);
  UICKeyChainStore *keyChainStore = [self rikerKeyChainStore];
  [keyChainStore removeAllItems];
  [self setAccountIssueBadge];
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if (user.facebookUserId) {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
  }
}

#pragma mark - Security and User-related

- (void)logout {
  UICKeyChainStore *keyChainStore = [self rikerKeyChainStore];
  [keyChainStore removeAllItems];
  // get handles to all data elements we want to "remember" (yes, even though
  // the user is logging out, we still want to retain a subset of the values
  // currently stored in NSUserDefaults
  NSDate *experiencedSplashScreenAt = [self experiencedSplashScreenAt];
  NSDate *usedWatchAppAt = [self usedWatchAppAt];
  NSDate *firstLaunchAt = [self firstLaunchAt];
  NSDate *hkWorkoutSaveDisabledAt = [RUtils hkWorkoutSaveDisabledAt];
  NSDate *hkBodyWeightSaveDisabledAt = [RUtils hkBodyWeightSaveDisabledAt];
  NSDate *healthKitEnabledAt = [RUtils healthKitEnabledAt];
  NSDate *lastHkWorkoutEndDate = [RUtils lastHkWorkoutEndDate];
  NSDate *lastHkBodyWeightEndDate = [RUtils lastHkBodyWeightEndDate];
  NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
  // clear out NSUserDefaults
  [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
  // re-persist these data elements
  if (experiencedSplashScreenAt) { [self setExperiencedSplashScreenAt:experiencedSplashScreenAt]; }
  if (usedWatchAppAt) { [self setUsedWatchAppAt:usedWatchAppAt]; }
  if (hkWorkoutSaveDisabledAt) { [RUtils setHkWorkoutSaveDisabledAt:hkWorkoutSaveDisabledAt]; }
  if (hkBodyWeightSaveDisabledAt) { [RUtils setHkBodyWeightSaveDisabledAt:hkBodyWeightSaveDisabledAt]; }
  if (healthKitEnabledAt) { [RUtils setHealthKitEnabledAt:healthKitEnabledAt]; }
  if (lastHkWorkoutEndDate) { [RUtils setLastHkWorkoutEndDate:lastHkWorkoutEndDate]; }
  if (lastHkBodyWeightEndDate) { [RUtils setLastHkBodyWeightEndDate:lastHkBodyWeightEndDate]; }
  [self setFirstLaunchAt:firstLaunchAt];
  [self resetUserInterface];
  [self setOfflineMode:NO];
}

- (BOOL)isUserLoggedIn {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  return [self isUserLoggedIn:user];
}

- (BOOL)isUserLoggedIn:(PELMUser *)user {
  if (user) {
    if ([user globalIdentifier]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)doesUserHaveValidAuthToken {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  return [self doesUserHaveValidAuthToken:user];
}

- (BOOL)doesUserHaveValidAuthToken:(PELMUser *)user {
  return [PEUtils isNotNil:[self storedAuthenticationTokenForUser:user]];
}

- (NSString *)storedAuthenticationTokenForUser:(PELMUser *)user {
  NSString *globalIdentifier = [user globalIdentifier];
  NSString *authToken = nil;
  if (globalIdentifier) {
    UICKeyChainStore *keyChainStore = [self rikerKeyChainStore];
    authToken = [keyChainStore stringForKey:globalIdentifier];
  }
  return authToken;
}

- (void)setAccountIssueBadge {
  PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if ([self isUserLoggedIn:user] && ![self doesUserHaveValidAuthToken:user]) {
    [self enableAccountIssueBadge:YES color:[UIColor redColor]];
  } else if ([user isBadAccount]) {
    [self enableAccountIssueBadge:YES color:[UIColor redColor]];
  } else if (![user paidEnrollmentEstablishedAt] && [user isTrialPeriodAlmostExpired]) {
    [self enableAccountIssueBadge:YES color:[UIColor carrotColor]];
  } else if ([user isPaymentPastDue] || (![user paidEnrollmentEstablishedAt] && [user isTrialPeriodAlmostExpired])) {
    [self enableAccountIssueBadge:YES color:[UIColor carrotColor]];
  } else {
    [self enableAccountIssueBadge:NO color:nil];
  }
}

- (void)enableAccountIssueBadge:(BOOL)enableBadge color:(UIColor *)color {  
}

@end
