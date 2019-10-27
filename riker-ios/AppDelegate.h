//
//  AppDelegate.h
//  riker-ios
//
//  Created by PEVANS on 10/10/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PEAuthTokenDelegate.h"
@import UIKit;
@import StoreKit;
@import WatchConnectivity;

@class PELMUser;
@class RMovement;
@class RMovementVariant;
@class PELMMainSupport;
@class RSet;
@class HKHealthStore;
@protocol RCoordinatorDao;

FOUNDATION_EXPORT NSString * const RIKER_ENDPOINT_PREFIX;
FOUNDATION_EXPORT NSString * const RIKER_ITUNES_APP_ID;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
PEAuthTokenDelegate,
SKPaymentTransactionObserver,
WCSessionDelegate>

#pragma mark - Security and User-related

- (void)logout;
- (BOOL)isUserLoggedIn;
- (BOOL)isUserLoggedIn:(PELMUser *)user;
- (BOOL)doesUserHaveValidAuthToken;
- (BOOL)doesUserHaveValidAuthToken:(PELMUser *)user;

#pragma mark - Total Num Unsynced Entities Refresher

- (void)refreshTabs;

#pragma mark - Resetting the user interface and tab bar delegate

- (void)resetUserInterface;

#pragma mark - Properties

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSArray *signInErrMessages;
@property (nonatomic) NSArray *saveUserErrMessages;
@property (nonatomic) NSArray *saveSetErrMessages;
@property (nonatomic) NSArray *saveBmlErrMessages;
@property (nonatomic) BOOL userSettingsOpenFromSettingsScreen;
@property (nonatomic) BOOL userSettingsOpenFromUnsyncedEditsScreen;
@property (nonatomic) HKHealthStore *healthStore;

#pragma mark - Used by Enter Reps Screen

@property (nonatomic) NSMutableDictionary *sets;

#pragma mark - Record Open (inside PEAddViewEditController)

- (BOOL)isSetOpen:(RSet *)set;

- (void)setOpened:(RSet *)set;

- (void)setClosed:(RSet *)set;

- (void)clearOpenSets;

#pragma mark - Chart Cache Regeneration

+ (void)regenerateChartCacheOnAppDelegateWithCoordDao:(id<RCoordinatorDao>)coordDao;

#pragma mark - Methods

- (BOOL)offlineMode;

- (void)setOfflineMode:(BOOL)offlineMode;

- (NSDate *)usedWatchAppAt;

- (void)setUsedWatchAppAt:(NSDate *)date;

- (NSDate *)firstLaunchAt;

- (void)setExperiencedSplashScreenAt:(NSDate *)date;

- (void)unlistenToPaymentTransactions;

- (NSString *)iapRikerSubscriptionProductIdentifier;

- (NSString *)rikerSupportEmail;

- (NSString *)rikerTermsOfServiceUrl;

- (NSString *)rikerTermsOfServiceBareNavUrl;

- (NSString *)rikerPrivacyPolicyUrl;

- (NSString *)rikerPrivacyPolicyBareNavUrl;

- (NSString *)rikerSecurityPolicyUrl;

- (NSString *)rikerSecurityPolicyBareNavUrl;

- (NSString *)rikerFaqUrl;

- (NSString *)rikerHomeUrl;

- (NSString *)rikerFaqBareNavUrl;

- (void)setUser:(PELMUser *)user tabBarController:(UITabBarController *)tabBarController;

- (NSDate *)changelogUpdatedAt;

- (void)setChangelogUpdatedAt:(NSDate *)updatedAt;

- (NSDate *)maintenanceAckAt;

- (void)setMaintenanceAckAt:(NSDate *)ackAt;

- (NSString *)urlForImageName:(NSString *)imageName;

- (NSDate *)suppressedWeightTfDefaultedToBodyWeightPopupAt;

- (void)setSuppressWeightTfDefaultedToBodyWeightPopup:(NSDate *)value;

- (NSDate *)iphone32bitLineChartMsgAckAt;

- (void)setIphone32bitLineChartMsgAckAt:(NSDate *)date;

@end

