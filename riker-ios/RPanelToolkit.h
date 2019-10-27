//
//  RPanelToolkit.h
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEUIToolkit.h"
#import "PEAddViewEditController.h"
#import "RScreenToolkit.h"
#import "RUtils.h"

@protocol RCoordinatorDao;
@protocol WCSessionDelegate;
@class PELMUser;
@class RUserSettings;
@class SKProduct;
@class JGActionSheet;

typedef NS_ENUM(NSInteger, PELMUserTag) {
  PELMUserTagEmail = 1,
  PELMUserTagPassword,
  PELMUserTagConfirmPassword
};

typedef NS_ENUM(NSInteger, RSetTag) {
  RSetTagMovement = 4,
  RSetTagMovementVariant,
  RSetTagLoggedAt,
  RSetTagIgnoreTimeSwitch,
  RSetTagIgnoreTimePanel,
  RSetTagIgnoreTimeMsgLabel,
  RSetTagWeight,
  RSetTagWeightUnits,
  RSetTagNumReps,
  RSetTagToFailureSwitch,
  RSetTagToFailurePanel,
  RSetTagNegativesSwitch,
  RSetTagNegativesPanel
};

typedef NS_ENUM(NSInteger, RBmlTag) {
  RBmlTagLoggedAt = 17,
  RBmlTagWeightUom,
  RBmlTagBodyWeight,
  RBmlTagSizeUom,
  RBmlTagArmSize,
  RBmlTagChestSize,
  RBmlTagCalfSize,
  RBmlTagNeckSize,
  RBmlTagWaistSize,
  RBmlTagThighSize,
  RBmlTagForearmSize
};

typedef NS_ENUM(NSInteger, RUserSettingsTag) {
  RUserSettingsTagWeightUom = 28,
  RUserSettingsTagWeightUomMsg,
  RUserSettingsTagSizeUom,
  RUserSettingsTagSizeUomMsg,
  RUserSettingsTagWeightIncDecAmount,
  RUserSettingsTagWeightIncDecAmountMsg
};

FOUNDATION_EXPORT NSString * const USE_RIKER_EXCLUSIVELY_TEXT;
FOUNDATION_EXPORT NSString * const USE_RIKER_WITHOUT_ACCOUNT_TEXT;

@interface RPanelToolkit : NSObject

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(id<RCoordinatorDao>)coordDao
               screenToolkit:(RScreenToolkit *)screenToolkit
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Export Helpers

- (void)invokeExportWithController:(UIViewController *)controller;

#pragma mark - Change Log Panel

- (void)invokeChangelogFetchForUser:(PELMUser *)user
                    userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
          actionIfChangesDownloaded:(void(^)(void))actionIfChangesDownloaded
                 successButtonTitle:(NSString *(^)(PELMUser *))successButtonTitle
            addlSuccessButtonAction:(void(^)(void))addlSuccessButtonAction
                         controller:(UIViewController *)controller;

- (UIView *)changeLogPanelWithParentView:(UIView *)contentPanel
                              controller:(UIViewController *)controller
                                    user:(PELMUser *)user
                         userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
               actionIfChangesDownloaded:(void(^)(void))actionIfChangesDownloaded;

#pragma mark - Helpers

+ (CGFloat)rowDataCellHeightWithFontTextStyle:(UIFontTextStyle)fontTextStyle
                                    uitoolkit:(PEUIToolkit *)uitoolkit;

- (UITableView *)makeTableViewWithTag:(NSInteger)tag
                            numFields:(NSInteger)numFields
              dataSourceDelegateMaker:(id(^)(UITableView *))dataSourceDelegateMaker
                       relativeToView:(UIView *)relativeToView
                 parentViewController:(UIViewController *)parentViewController;

+ (UIFont *)contentInfoButtonFont;

- (UIView *)loggedInCrudToolbarHelpPanelWithWidth:(CGFloat)panelWidth;

- (UIView *)healthKitSwitchPanelWithController:(PEBaseController *)controller
                                           tag:(NSInteger)tag
                                relativeToView:(UIView *)relativeToView;

- (UIView *)offlineModeSwitchPanelRelativeToView:(UIView *)relativeToView
                                     displayIcon:(BOOL)displayIcon;

#pragma mark - Alert Helpers

- (JGActionSheetSection *)goOfflineAlertSectionRelativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)watchReminderAlertSectionRelativeToView:(UIView *)relativeToView;

#pragma mark - User Account Panels

- (PEEntityViewPanelMakerBlk)userAccountViewPanelMakerWithAccountStatusLabelTag:(NSInteger)accountStatusLabelTag
                                                       becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction
                                                                  fontTextStyle:(UIFontTextStyle)fontTextStyle;

- (PEEntityPanelMakerBlk)userAccountFormPanelMaker;

- (PEPanelToEntityBinderBlk)userFormPanelToUserBinder;

- (PEEntityToPanelBinderBlk)userToUserPanelBinder;

- (PEEnableDisablePanelBlk)userFormPanelEnablerDisabler;

- (void)invokeSendVerificationEmailWithController:(UIViewController *)controller
                         becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction;

- (UIView *)emailStatusPanelForUser:(PELMUser *)user
                           panelTag:(NSNumber *)panelTag
               includeRefreshButton:(BOOL)includeRefreshButton
                     relativeToView:(UIView *)relativeToView
                      fontTextStyle:(UIFontTextStyle)fontTextStyle
                         controller:(UIViewController *)controller
           becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction;

- (void)refreshEmailStatusPanelForUser:(PELMUser *)user
                              panelTag:(NSNumber *)panelTag
                  includeRefreshButton:(BOOL)includeRefreshButton
                        relativeToView:(UIView *)relativeToView
                         fontTextStyle:(UIFontTextStyle)fontTextStyle
                            controller:(UIViewController *)controller
              becameUnauthButtonAction:(void(^)(UIViewController *))becameUnauthButtonAction;

+ (UIButton *)forgotPasswordButtonForUser:(PELMUser *)user
                           coordinatorDao:(id<RCoordinatorDao>)coordDao
                                uitoolkit:(PEUIToolkit *)uitoolkit
                               controller:(UIViewController *)controller;

+ (NSArray *)accountStatusTextForUser:(PELMUser *)user;

- (UIView *)accountStatusPanelForUser:(PELMUser *)user
                       relativeToView:(UIView *)relativeToView
                           controller:(UIViewController *)controller;

+ (NSArray *)whyPaymentFailedExpandingInfoPanelWithToggles:(NSMutableDictionary *)toggles
                                              contentIndex:(NSInteger)contentIndex
                             baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                belowViews:(NSArray *)belowViews
                                            relativeToView:(UIView *)relativeToView;

- (NSArray *)myPaymentInfoExpandingInfoPanelForUser:(PELMUser *)user
                                includeUpdateButton:(BOOL)includeUpdateButton
                          includeCancellationButton:(BOOL)includeCancellationButton
                                            toggles:(NSMutableDictionary *)toggles
                                       contentIndex:(NSInteger)contentIndex
                      baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                         belowViews:(NSArray *)belowViews
                                         controller:(UIViewController *)controller
                                     relativeToView:(UIView *)relativeToView
                                subscriptionProduct:(SKProduct *)subscriptionProduct;

+ (NSArray *)enrollInSubscriptionExpandingInfoPanelWithTitle:(NSString *)title
                                                    reenroll:(BOOL)reenroll
                                         subscriptionProduct:(SKProduct *)subscriptionProduct
                                                     toggles:(NSMutableDictionary *)toggles
                                                contentIndex:(NSInteger)contentIndex
                               baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                  belowViews:(NSArray *)belowViews
                                              relativeToView:(UIView *)relativeToView;

+ (NSArray *)useRikerAppExclusivelyExpandingInfoPanelWithTitle:(NSString *)title
                                                       toggles:(NSMutableDictionary *)toggles
                                                  contentIndex:(NSInteger)contentIndex
                                 baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                                                    belowViews:(NSArray *)belowViews
                                                relativeToView:(UIView *)relativeToView;

+ (UIView *)upcomingMaintenanceNavbarPanelForUser:(PELMUser *)user
                                   relativeToView:(UIView *)relativeToView
                                       controller:(UIViewController *)controller
                              navBannerRemovedBlk:(void(^)(CGFloat))navBannerRemovedBlk;

+ (UIView *)maintenanceInProgressNavbarPanelForUser:(PELMUser *)user
                                     relativeToView:(UIView *)relativeToView
                                         controller:(UIViewController *)controller;

+ (UIView *)breadcrumbPanelWithTemplateText:(NSString *)templateText
                               textToAccent:(NSString *)textToAccent
                             relativeToView:(UIView *)relativeToView;

#pragma mark - User Settings Panels

- (PEEntityViewPanelMakerBlk)userSettingsViewPanelMaker;

- (PEEntityPanelMakerBlk)userSettingsFormPanelMakerWithDefaultWeightUomBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                                         defaultSizeUomBlk:(NSNumber *(^)(void))defaultSizeUomBlk;

- (PEPanelToEntityBinderBlk)userSettingsFormPanelToUserSettingsBinder;

- (PEEntityToPanelBinderBlk)userSettingsToUserSettingsPanelBinder;

- (PEEnableDisablePanelBlk)userSettingsFormPanelEnablerDisabler;

#pragma mark - Set Panels

- (PEEntityViewPanelMakerBlk)setViewPanelMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk
                                                           movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                                    movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                                      movementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                               movementVariantLoaderBlk:(RMovementVariant *(^)(NSNumber *))movementVariantLoaderBlk
                                          mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                          weightTfDefaultedToBodyWeight:(WeightTfDefaultedNotice)weightTfDefaultedToBodyWeight;

- (PEEntityPanelMakerBlk)setFormPanelMakerWithDefaultLoggedAtBlk:(NSDate *(^)(void))defaultLoggedAtBlk
                                              defaultMovementBlk:(RMovement *(^)(void))defaultMovementBlk
                                       defaultMovementVariantBlk:(RMovementVariant *(^)(void))defaultMovementVariantBlk
                                             defaultWeightUomBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                                    movementsBlk:(NSDictionary *(^)(void))movementsBlk
                                             movementVariantsBlk:(NSDictionary *(^)(RMovement *))movementVariantsBlk
                                               movementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                   mostRecentBmlWithNonNilWeight:(RBodyMeasurementLog *)mostRecentBmlWithNonNilWeight
                                   weightTfDefaultedToBodyWeight:(WeightTfDefaultedNotice)weightTfDefaultedToBodyWeight;

- (PEPanelToEntityBinderBlk)setFormPanelToSetBinder;

- (PEEntityToPanelBinderBlk)setToSetPanelBinderWithMovementLoaderBlk:(RMovement *(^)(NSNumber *))movementLoaderBlk
                                            movementVariantLoaderBlk:(RMovementVariant *(^)(NSNumber *))movementVariantLoaderBlk;

- (PEEnableDisablePanelBlk)setFormPanelEnablerDisabler;

- (PEEntityMakerBlk)setMakerWithOriginationDeviceId:(NSNumber *)originationDeviceId;

#pragma mark - Body Measurement Log Panel

- (PEEntityViewPanelMakerBlk)bmlViewPanelMakerWithOriginationDevicesBlk:(NSDictionary *(^)(void))originationDevicesBlk;

- (PEEntityPanelMakerBlk)bmlFormPanelMakerWithDefaultLoggedAtBlk:(NSDate *(^)(void))defaultLoggedAtBlk
                                           defaultWeightUomIdBlk:(NSNumber *(^)(void))defaultWeightUomBlk
                                             defaultSizeUomIdBlk:(NSNumber *(^)(void))defaultSizeUomBlk;

- (PEPanelToEntityBinderBlk)bmlFormPanelToBmlBinder;

- (PEEntityToPanelBinderBlk)bmlToBmlPanelBinder;

- (PEEnableDisablePanelBlk)bmlFormPanelEnablerDisabler;

- (PEEntityMakerBlk)bmlMakerWithOriginationDeviceId:(NSNumber *)originationDeviceId;

@end
