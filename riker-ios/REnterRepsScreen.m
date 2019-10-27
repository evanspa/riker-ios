//
//  REnterRepsScreen.m
//  riker-ios
//
//  Created by PEVANS on 2/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "REnterRepsScreen.h"
#import <TNRadioButtonGroup/TNRadioButtonGroup.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "NSString+RAdditions.h"
#import "UIColor+RAdditions.h"
#import "RAppNotificationNames.h"
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
#import "RMovementVariant.h"
#import "RUserSettings.h"
#import "PEUtils.h"
#import "RLogging.h"
#import "RBodyMeasurementLog.h"
#import "PESingleValueTableViewDataSourceDelegate.h"
#import "RSet.h"
@import Firebase;
#import "RWatchUtils.h"

@implementation REnterRepsScreen {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RUserSettings *(^_userSettingsBlk)(PELMUser *);
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  NSArray *_breadcrumbs;
  BOOL _dismissable;
  RMovement *_movement;
  RMovementVariant *_movementVariant;
  BOOL _toggleChangeUnitsPanel;
  BOOL _animateChangeUnitsPanel;
  BOOL _toggleMorePanel;
  NSNumber *_weightUomId;
  TNRadioButtonGroup *_weightUnitsGroup;
  NSNumber *_numReps;
  NSDecimalNumber *_weight;
  UITextField *_weightTf;
  UITextField *_numRepsTf;
  UISwitch *_toFailureSwitch;
  UISwitch *_negativesSwitch;
  UISwitch *_realtimeSwitch;
  UISwitch *_ignoreTimeSwitch;
  BOOL _toFailure;
  BOOL _negatives;
  BOOL _realtime;
  BOOL _hasShownWeightTfDefaultedNotice;
  BOOL _ignoreTime;
  NSDate *_manuallyLoggedAt;
  UIButton *_currentSetButton;
  BOOL _animateCurrentSetButton;
  UIView *_unitsPanel;
  NSNumberFormatter *_decimalFormatter;
  NSTimer *_timer;
  NSNumber *_weightIncDecAmount;
  BOOL _hasSavedASet;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                   breadcrumbs:(NSArray *)breadcrumbs
                   dismissable:(BOOL)dismissable
               userSettingsBlk:(RUserSettings *(^)(PELMUser *))userSettingsBlk
                      movement:(RMovement *)movement
               movementVariant:(RMovementVariant *)movementVariant
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Enter Reps"];
  if (self) {
    _breadcrumbs = breadcrumbs;
    _dismissable = dismissable;
    _userSettingsBlk = userSettingsBlk;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _movement = movement;
    _movementVariant = movementVariant;
    [self setDelaysContentTouches:NO];
    _toggleChangeUnitsPanel = NO;
    _animateChangeUnitsPanel = NO;
    _toggleMorePanel = NO;
    _realtime = YES;
    _manuallyLoggedAt = [NSDate date];
    _decimalFormatter = [RUtils weightNumberFormatter];
  }
  return self;
}

- (NSString *)setsKey {
  NSMutableString *key = [[NSMutableString alloc] initWithString:_movement.localMasterIdentifier.description];
  if (_movementVariant) {
    [key appendString:[NSString stringWithFormat:@"-%@", _movementVariant.localMasterIdentifier.description]];
  }
  return key;
}

#pragma mark - Dismiss

- (void)dismiss {
  if (_hasSavedASet) {
    [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  if (_dismissable) {
    UINavigationItem *navItem = [self navigationItem];
    UIBarButtonItem *dismissBtn =
    [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [navItem setRightBarButtonItem:dismissBtn];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  if (_hasSavedASet) {
    [AppDelegate regenerateChartCacheOnAppDelegateWithCoordDao:_coordDao];
  }
  [super viewWillDisappear:animated];
}

#pragma mark - Data Binding

- (void)bindNumRepsUiToModel {
  NSString *numRepsTfVal = _numRepsTf.text;
  if (numRepsTfVal && [numRepsTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
    _numReps = [NSNumber numberWithInteger:[numRepsTfVal integerValue]];
  } else {
    _numReps = nil;
  }
}

- (void)bindWeightUiToModelWithTargetWeightUomId:(NSNumber *)targetWeightUomId {
  NSString *weightTfVal = _weightTf.text;
  if (weightTfVal && [weightTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
    _weight = [RUtils weightValueWithValue:[NSDecimalNumber decimalNumberWithString:_weightTf.text]
                        currentWeightUomId:_weightUomId
                         targetWeightUomId:targetWeightUomId];
  } else {
    _weight = nil;
  }
}

- (void)bindUiToModelWithTargetWeightUomId:(NSNumber *)targetWeightUomId {
  [self bindWeightUiToModelWithTargetWeightUomId:targetWeightUomId];
  [self bindNumRepsUiToModel];
  _toFailure = _toFailureSwitch.on;
  _negatives = _negativesSwitch.on;
  if (_realtimeSwitch) {
    _realtime = _realtimeSwitch.on;
  }
  if (_ignoreTimeSwitch) {
    _ignoreTime = _ignoreTimeSwitch.on;
  }
}

#pragma mark - Notifications

- (void)weightUnitsGroupUpdated:(NSNotification *)notification {
  TNRadioButton *selectedRadioOption = _weightUnitsGroup.selectedRadioButton;
  NSInteger selectedRadioUomId = [selectedRadioOption.data.identifier integerValue];
  if (selectedRadioUomId != _weightUomId.integerValue) {
    NSNumber *newWeightUomId = [NSNumber numberWithInteger:selectedRadioUomId];
    [self bindUiToModelWithTargetWeightUomId:newWeightUomId];
    _weightUomId = newWeightUomId;
    [self setNeedsRepaint:YES];
    [self viewDidAppear:YES];
  }
}

#pragma mark - Enable / Disable UI

- (void)disableUi {
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
  [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
}

- (void)enableUi {
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
  [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
}

#pragma mark - Device Rotation

- (void)willRepaintDueToRotate {
  [super willRepaintDueToRotate];
  [self bindUiToModelWithTargetWeightUomId:_weightUomId];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  __block NSMutableArray *sets = [[APP sets] objectForKey:[self setsKey]];
  CGFloat totalHeight = 0.0;
  NSMutableString *headerText = [NSMutableString stringWithString:_movement.canonicalName];
  if (_movementVariant) {
    [headerText appendFormat:@" - %@", _movementVariant.name];
  }
  CGFloat setButtonDiamater = [PEUIUtils valueIfiPhone5Width:35.0
                                                iphone6Width:38.0
                                            iphone6PlusWidth:40.0
                                                        ipad:45.0];
  CGFloat setButtonTextPadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:3.5 iphone6PlusWidth:4.0 ipad:5.0];
  CGFloat setButtonMargin = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:14.0 ipad:20.0];
  UIFontTextStyle setButtonTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                 iphone6Width:UIFontTextStyleBody
                                                             iphone6PlusWidth:UIFontTextStyleBody
                                                                         ipad:UIFontTextStyleTitle3];
  UIButton *(^makeSetButton)(NSInteger, RSet *) = ^UIButton * (NSInteger setNumber, RSet *set) {
    UIButton *setBtn = [PEUIUtils buttonWithKey:[NSString stringWithFormat:@"%ld", (long)setNumber]
                                           font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:28.0 iphone6PlusWidth:32.0 ipad:36.0]
                                                                                      font:[PEUIUtils boldFontForTextStyle:setButtonTextStyle]]
                                backgroundColor:[UIColor bootstrapPrimary]
                                      textColor:[UIColor whiteColor]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:setButtonTextPadding
                              horizontalPadding:setButtonTextPadding
                                   cornerRadius:setButtonDiamater * 0.5
                                         target:nil
                                         action:nil];
    [PEUIUtils setFrameWidth:setButtonDiamater ofView:setBtn];
    [PEUIUtils setFrameHeight:setButtonDiamater ofView:setBtn];
    [setBtn bk_addEventHandler:^(id sender) {
      [self bindUiToModelWithTargetWeightUomId:_weightUomId];
      RSet *refetchedSet = [_coordDao setWithCorrelationGuid:set.correlationGuid error:[RUtils localFetchErrorHandlerMaker]()];
      if (refetchedSet) {        
        if ([APP isSetOpen:refetchedSet]) {
          [PEUIUtils showWarningAlertWithMsgs:nil
                                        title:@"Already open."
                             alertDescription:[PEUIUtils attributedTextWithTemplate:@"Looks like you already have this record open on the %@ tab.  Bounce over there to view/edit/delete your set."
                                                                       textToAccent:@"Records"
                                                                     accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                          descLblHeightAdjust:0.0
                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                 }
                               relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
        } else {
          PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
          PELMUser *user = [_coordDao userWithError:errorBlk];
          UIViewController *setDetailScreen =
          [_screenToolkit newSetDetailScreenMakerWithSet:refetchedSet
                                            setIndexPath:nil
                                          itemChangedBlk:nil
                                      listViewController:nil
                                            movementsBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao movementsWithNilMuscleIdsWithError:errorBlk]];}
                                     movementVariantsBlk:^(RMovement *movement) {
                                       NSArray *movementVariants = [_coordDao movementVariantsWithError:errorBlk];
                                       return [RUtils dictFromMasterEntitiesArray:[RUtils filterMovementVariants:movementVariants
                                                                                                       usingMask:movement.variantMask.integerValue]];
                                     }
                                   originationDevicesBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:errorBlk]];}
                           mostRecentBmlWithNonNilWeight:[_coordDao mostRecentBmlWithNonNilWeightForUser:user error:errorBlk]
                                         deletedCallback:^{
                                           [sets removeObjectAtIndex:setNumber - 1];
                                           _animateCurrentSetButton = YES;
                                           [self setNeedsRepaint:YES];
                                           [self viewDidAppear:YES];
                                         }]();
          [self presentViewController:[PEUIUtils navigationControllerWithController:setDetailScreen
                                                                navigationBarHidden:NO]
                             animated:YES
                           completion:nil];
        }
      } else {
        [PEUIUtils showWarningAlertWithMsgs:nil
                                      title:@"Set not found."
                           alertDescription:AS(@"Looks like this set no longer exists.")
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 [sets removeObjectAtIndex:setNumber - 1];
                                 _animateCurrentSetButton = YES;
                                 [self setNeedsRepaint:YES];
                                 [self viewDidAppear:YES];
                               }
                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    return setBtn;
  };
  UIButton *(^makeCurrentSetButton)(NSInteger) = ^UIButton * (NSInteger currentSetNumber) {
    UIButton *setBtn = [PEUIUtils buttonWithKey:[NSString stringWithFormat:@"%ld", (long)currentSetNumber]
                                           font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:28.0 iphone6PlusWidth:32.0 ipad:36.0]
                                                                                      font:[PEUIUtils boldFontForTextStyle:setButtonTextStyle]]
                                backgroundColor:[UIColor clearColor]
                                      textColor:[UIColor rikerAppBlack]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:setButtonTextPadding
                              horizontalPadding:setButtonTextPadding
                                   cornerRadius:setButtonDiamater * 0.5
                                         target:nil
                                         action:nil];
    [PEUIUtils setFrameWidth:setButtonDiamater ofView:setBtn];
    [PEUIUtils setFrameHeight:setButtonDiamater ofView:setBtn];
    [PEUIUtils applyBorderToView:setBtn withColor:[UIColor bootstrapPrimary] width:3.0];
    [setBtn setEnabled:NO];
    [setBtn setBackgroundImage:[PEUIUtils imageWithColor:[UIColor clearColor]] forState:UIControlStateDisabled];
    return setBtn;
  };  
  CGFloat infoIconSize = [PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:26.0 iphone6PlusWidth:26.0 ipad:26.0];
  UIButton *aboutMovementBtn = [PEUIUtils buttonWithKey:@"i"
                                                   font:[PEUIUtils infoIconFont]
                                        backgroundColor:[UIColor rikerAppBlackResultantNavbarColor]
                                              textColor:[UIColor whiteColor]
                           disabledStateBackgroundColor:nil
                                 disabledStateTextColor:nil
                                        verticalPadding:0.0
                                      horizontalPadding:0.0
                                           cornerRadius:infoIconSize * 0.5
                                                 target:nil
                                                 action:nil];
  [PEUIUtils setFrameWidth:infoIconSize ofView:aboutMovementBtn];
  [PEUIUtils setFrameHeight:infoIconSize ofView:aboutMovementBtn];
  [aboutMovementBtn bk_addEventHandler:^(id sender) {
    UIViewController *movementInfoScreen = [_screenToolkit newMovementInfoScreenMakerWithMovement:_movement
                                                                            enableStartSetButtons:NO]();
    [self.navigationController pushViewController:movementInfoScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *headerLabel = [PEUIUtils labelWithKey:headerText
                                            font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                                           iphone6Width:UIFontTextStyleTitle3
                                                                                                       iphone6PlusWidth:UIFontTextStyleTitle2
                                                                                                                   ipad:UIFontTextStyleTitle1]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor rikerAppBlack]
                             verticalTextPadding:5.0
                                      fitToWidth:contentPanel.frame.size.width - (15.0 * 2) - aboutMovementBtn.frame.size.width - 10.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIButton *(^makeSaveSetButton)(void) = ^{
    UIButton *btn = [PEUIUtils buttonWithKey:@"Save Set"
                                        font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:38.0]
                                                                                   font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                                                                                  iphone6Width:UIFontTextStyleBody
                                                                                                                                              iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                                                          ipad:UIFontTextStyleTitle2]]]
                             backgroundColor:[UIColor emerlandColor]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:34.0 ipad:40.0]
                           horizontalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:32.0]
                                cornerRadius:3.0
                                      target:nil
                                      action:nil];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    [btn bk_addEventHandler:^(id sender) {
      NSMutableArray *errMsgs = [NSMutableArray array];
      void (^validate)(UITextField *, NSString *, NSString *, NSString *) = ^(UITextField *tf, NSString *emptyErrMsg, NSString *nonNumericErrMsg, NSString *nonPositiveErrMsg) {
        NSString *tfValStr = [tf text];
        tfValStr = [tfValStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (tfValStr.length == 0) {
          [errMsgs addObject:emptyErrMsg];
        } else {
          NSNumber *val = [f numberFromString:tfValStr];
          if ([PEUtils isNil:val]) {
            [errMsgs addObject:nonNumericErrMsg];
          } else {
            if (val.integerValue <= 0) {
              [errMsgs addObject:nonPositiveErrMsg];
            }
          }
        }
      };
      validate(_weightTf, @"Weight cannot be empty", @"Weight must be a number", @"Weight must be a positive value");
      validate(_numRepsTf, @"Num reps cannot be empty", @"Num reps must be a number", @"Num reps must be a positive value");
      if ([errMsgs count] == 0) {
        NSDate *loggedAt;
        if (_realtimeSwitch == nil || _realtimeSwitch.on) { // realtime switch would be nil if the 'more' button is never clicked
          loggedAt = [NSDate date];
        } else {
          loggedAt = _manuallyLoggedAt;
        }
        RSet *set =
        [_coordDao setWithNumReps:[f numberFromString:_numRepsTf.text]
                           weight:[NSDecimalNumber decimalNumberWithString:_weightTf.text] //[f numberFromString:_weightTf.text]
                        weightUom:_weightUomId
                        negatives:_negativesSwitch.on
                        toFailure:_toFailureSwitch.on
                         loggedAt:loggedAt
                       ignoreTime:_ignoreTimeSwitch != nil ? _ignoreTimeSwitch.on : NO
                       movementId:_movement.localMasterIdentifier
                movementVariantId:_movementVariant.localMasterIdentifier
              originationDeviceId:[PEUIUtils isIpad] ? @(ORIGINATION_DEVICE_ID_IPAD) : @(ORIGINATION_DEVICE_ID_IPHONE)
                       importedAt:nil
                  correlationGuid:[[NSUUID UUID] UUIDString]];
        void(^postProcessingForSavedSet)(RSet *) = ^(RSet *newSet) {
          [[NSNotificationCenter defaultCenter] postNotificationName:REntityAddedNotification
                                                              object:self
                                                            userInfo:@{@"entity": newSet}];
          [RUtils logNewSetEventWithSet:set]; 
          if ([PEUtils isNil:sets]) {
            [[APP sets] removeAllObjects];
            sets = [NSMutableArray array];
            [[APP sets] setObject:sets forKey:[self setsKey]];
          }
          _hasSavedASet = YES;
          [sets addObject:newSet];
          [self setNeedsRepaint:YES];
          [self bindUiToModelWithTargetWeightUomId:_weightUomId];
          _animateCurrentSetButton = YES;
          [self viewDidAppear:YES];
        };
        PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
        if ([APP doesUserHaveValidAuthToken] && ![APP offlineMode] && ![user isBadAccount]) {
          void (^dialogDismissAction)(void) = ^{
            [APP refreshTabs];
            [self enableUi];
          };
          JGActionSheetSection *(^setLocallySavedSection)(void) = ^{
            return [PEUIUtils successAlertSectionWithTitle:@"Save saved."
                                          alertDescription:AS(@"Your set has been saved locally.")
                                       descLblHeightAdjust:0.0
                                            relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          };
          JGActionSheetSection *(^goOfflineSection)(void) = ^{
            return [_panelToolkit goOfflineAlertSectionRelativeToView:self.navigationController.view];
          };
          [self disableUi];
          MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          HUD.tag = RHUD_TAG;
          [self disableUi];
          HUD.delegate = self;
          HUD.mode = MBProgressHUDModeIndeterminate;
          HUD.label.text = @"Saving to the server...";
          void(^handleInexplicableError)(RSet *) = ^(RSet *set) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD hideAnimated:YES];
              [PEUIUtils showErrorAlertWithMsgs:nil
                                          title:@"Oops."
                               alertDescription:AS(@"An unknown error occurred while attempting to sync your set.")
                            descLblHeightAdjust:0.0
                      additionalContentSections:@[setLocallySavedSection(), goOfflineSection()]
                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                    buttonTitle:@"Okay."
                                   buttonAction:^{
                                     postProcessingForSavedSet(set);
                                     dialogDismissAction();
                                   }
                                 relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
            });
          };
          [_coordDao saveNewAndSyncImmediateSet:set
                                        forUser:user
                        writeUserReadonlyFields:YES
                            notFoundOnServerBlk:^{
                              [RUtils logEvent:@"not_found_wh_e_r_save_set"];
                              handleInexplicableError(set);
                            }
                                 addlSuccessBlk:^{
                                   [RUtils logEvent:@"success_wh_e_r_save_set"];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     [HUD hideAnimated:YES];
                                     [PEUIUtils showSuccessAlertWithTitle:@"Set saved and synced."
                                                         alertDescription:AS(@"Your set has been saved and synced to your account.")
                                                      descLblHeightAdjust:0.0
                                                 additionalContentSection:nil
                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                              buttonTitle:@"Okay."
                                                             buttonAction:^{
                                                               postProcessingForSavedSet(set);
                                                               dialogDismissAction();
                                                             }
                                                           relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                   });
                                 }
                         addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {
                           [RUtils logEvent:@"busy_wh_e_r_save_set"];
                           dispatch_async(dispatch_get_main_queue(), ^{
                             [HUD hideAnimated:YES];
                             [PEUIUtils showWaitAlertWithMsgs:nil
                                                        title:@"Busy with maintenance."
                                             alertDescription:AS(@"Your set could not be synced because the Riker server is currently busy undergoing maintenance.")
                                          descLblHeightAdjust:0.0
                                    additionalContentSections:@[setLocallySavedSection(), goOfflineSection()]
                                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                  buttonTitle:@"Okay."
                                                 buttonAction:^{
                                                 }
                                               relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                           });
                         }
                         addlTempRemoteErrorBlk:^{
                           [RUtils logEvent:@"temp_remote_err_wh_e_r_save_set"];
                           handleInexplicableError(set);
                         }
                             addlRemoteErrorBlk:^(NSInteger errMask) {
                               [RUtils logEvent:@"remote_err_wh_e_r_save_set"
                                         params:[RUtils eventLogParamsWithErrMask:errMask]];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 [HUD hideAnimated:YES];
                                 NSArray *errMsgs = [RUtils computeSetErrMsgs:errMask];
                                 [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                                             title:@"Oops."
                                                  alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"There %@ attempting to sync your set.", errMsgs.count > 1 ? @"were problems" : @"was a problem"]]
                                               descLblHeightAdjust:0.0
                                         additionalContentSections:@[setLocallySavedSection(), goOfflineSection()]
                                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                       buttonTitle:@"Okay."
                                                      buttonAction:^{
                                                        postProcessingForSavedSet(set);
                                                        dialogDismissAction();
                                                      }
                                                    relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                               });
                             }
                            addlAuthRequiredBlk:^{
                              [RUtils logEvent:@"auth_reqd_wh_e_r_save_set"];
                              dispatch_async(dispatch_get_main_queue(), ^{
                                [HUD hideAnimated:YES];
                                [PEUIUtils showErrorAlertWithMsgs:nil
                                                            title:@"Oops."
                                                 alertDescription:AS(@"Unable to sync your set.")
                                              descLblHeightAdjust:0.0
                                        additionalContentSections:@[[PEUIUtils becameUnauthenticatedSectionRelativeToView:self.navigationController.view],
                                                                    setLocallySavedSection()]
                                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                      buttonTitle:@"Okay."
                                                     buttonAction:^{
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                           object:self
                                                                                                         userInfo:nil];
                                                       postProcessingForSavedSet(set);
                                                       dialogDismissAction();
                                                     }
                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                              });
                            }
                               addlForbiddenBlk:^{
                                 [RUtils logEvent:@"forbidden_wh_e_r_save_set"];
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [HUD hideAnimated:YES];
                                   [PEUIUtils showErrorAlertWithMsgs:nil
                                                               title:@"Oops."
                                                    alertDescription:AS(@"Unable to sync your set.")
                                                 descLblHeightAdjust:0.0
                                           additionalContentSections:@[[PEUIUtils receivedNotPermittedSectionRelativeToView:self.navigationController.view],
                                                                       setLocallySavedSection()]
                                                            topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                         buttonTitle:@"Okay."
                                                        buttonAction:^{
                                                          postProcessingForSavedSet(set);
                                                          dialogDismissAction();
                                                        }
                                                      relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                 });
                               }
                                          error:[RUtils localSaveErrorHandlerMaker]()];
          
          
        } else {
          [_coordDao saveNewSet:set forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
          void (^buttonAction)(void) = ^{
            postProcessingForSavedSet(set);
            [APP refreshTabs];
          };
          if ([APP offlineMode]) {
            [RUtils logEvent:@"e_r_set_saved_local_wh_offline"];
            [PEUIUtils showOfflineModeEnabledAlertWithTitle:@"Set saved locally."
                                           alertDescription:AS(@"Your set has been saved locally.")
                                        descLblHeightAdjust:0.0
                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                buttonTitle:@"Okay."
                                               buttonAction:buttonAction
                                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else if ([APP isUserLoggedIn] && ![APP doesUserHaveValidAuthToken]) {
            [RUtils logEvent:@"e_r_set_saved_local_wh_unauth"];
            [PEUIUtils recordSavedWhileUnauthAlertWithTitle:@"Set saved locally."
                                           alertDescription:AS(@"Your set has been saved locally.")
                                        descLblHeightAdjust:0.0
                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                buttonTitle:@"Okay."
                                               buttonAction:buttonAction
                                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else if ([APP isUserLoggedIn] && [user isBadAccount]) {
            [RUtils logEvent:@"e_r_set_saved_local_wh_bad_acct"];
            [PEUIUtils recordSavedWhileBadAccountAlertWithTitle:@"Set saved locally."
                                               alertDescription:AS(@"Your set has been saved locally.")
                                            descLblHeightAdjust:0.0
                                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                    buttonTitle:@"Okay."
                                                   buttonAction:buttonAction
                                                 relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else {
            [RUtils logEvent:@"e_r_set_saved_local_wh_anon"];
            [PEUIUtils showSuccessAlertWithTitle:@"Set saved."
                                alertDescription:AS(@"Your set has been saved.")
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:buttonAction
                                  relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          }
        }
      } else {
        [RUtils logEvent:@"e_r_form_validation_err"];
        NSString *descriptionTitle;
        if (errMsgs.count == 1) {
          descriptionTitle = @"A problem to fix:";
        } else {
          descriptionTitle = @"Some problems to fix:";
        }
        [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                      title:@"Oops"
                           alertDescription:[[NSAttributedString alloc] initWithString:descriptionTitle]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{  }
                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
      }          
    } forControlEvents:UIControlEventTouchUpInside];
    return btn;
  };
  
  UIButton *saveSetTop = makeSaveSetButton();
  UIButton *saveSetBottom = makeSaveSetButton();
  UIButton *(^makeChangeHideUnitsButton)(CGFloat, NSString *) = ^UIButton * (CGFloat baseHpadding, NSString *title) {
    UIButton *button = [PEUIUtils buttonWithKey:title
                                           font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:36.0]
                                                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                                                   iphone6Width:UIFontTextStyleCaption1
                                                                                                                                               iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                                                           ipad:UIFontTextStyleBody]]]
                                backgroundColor:[UIColor cloudsColor]
                                      textColor:[UIColor rikerAppBlack]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:15.0
                              horizontalPadding:[PEUIUtils valueIfiPhone5Width:baseHpadding
                                                                  iphone6Width:baseHpadding + 5.0
                                                              iphone6PlusWidth:baseHpadding + 10.0
                                                                          ipad:baseHpadding + 15.0]
                                   cornerRadius:5.0
                                         target:nil
                                         action:nil];
    [PEUIUtils applyBorderToView:button withColor:[UIColor silverColor] width:2.0];
    [button bk_addEventHandler:^(id sender) {
      [self setNeedsRepaint:YES];
      _toggleChangeUnitsPanel = !_toggleChangeUnitsPanel;
      if (_toggleChangeUnitsPanel) {
        [RUtils logEvent:@"change_units_section_expanded"];
        _animateChangeUnitsPanel = YES;
        [self bindUiToModelWithTargetWeightUomId:_weightUomId];
        [self viewDidAppear:YES];
      } else {
        [self bindUiToModelWithTargetWeightUomId:_weightUomId];
        [self viewDidAppear:YES];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    return button;
  };
  UIButton *(^makeMoreLessButton)(NSString *) = ^UIButton * (NSString *title) {
    UIButton *button = [PEUIUtils buttonWithKey:title
                                           font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:36.0]
                                                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                                                   iphone6Width:UIFontTextStyleCaption1
                                                                                                                                               iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                                                           ipad:UIFontTextStyleBody]]]
                                backgroundColor:[UIColor cloudsColor]
                                      textColor:[UIColor rikerAppBlack]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:16.0
                              horizontalPadding:[PEUIUtils valueIfiPhone5Width:30.0
                                                                  iphone6Width:35.0
                                                              iphone6PlusWidth:40.0
                                                                          ipad:45.0]
                                   cornerRadius:5.0
                                         target:nil
                                         action:nil];
    [PEUIUtils applyBorderToView:button withColor:[UIColor rikerAppBlackResultantNavbarColor] width:2.0];
    [button bk_addEventHandler:^(id sender) {
      [self setNeedsRepaint:YES];
      _toggleMorePanel = !_toggleMorePanel;
      if (_toggleChangeUnitsPanel) {
        [RUtils logEvent:@"more_section_expanded"];
        [self bindUiToModelWithTargetWeightUomId:_weightUomId];
        [self viewDidAppear:YES];
      } else {
        [self bindUiToModelWithTargetWeightUomId:_weightUomId];
        [self viewDidAppear:YES];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    return button;
  };
  UIButton *changeHideUnitsButton = makeChangeHideUnitsButton(12.0, _toggleChangeUnitsPanel ? @"hide units" : @"change units");
  UIButton *moreLessButton = makeMoreLessButton(_toggleMorePanel ? @"less" : @"more");
  CGFloat repsWeightPanelHeight = 0.0;
  UIView *repsWeightPanel = [PEUIUtils panelWithFixedWidth:contentPanel.frame.size.width - (15.0 * 2) - (iphoneXSafeInsetsSideVal * 2) fixedHeight:50.0];
  [repsWeightPanel setBackgroundColor:[UIColor silverColor]];
  repsWeightPanel.layer.cornerRadius = 3.0;
  CGFloat tfMargin = 8.0; //[PEUIUtils valueIfiPhone5Width:4.0 iphone6Width:5.0 iphone6PlusWidth:6.0 ipad:10.0];
  UITextField *(^makeTextField)(NSString*, UIButton *, UIButton *, UIKeyboardType) = ^UITextField * (NSString *placeholder, UIButton *leftBtn, UIButton *rightBtn, UIKeyboardType keyboardType) {
    UITextField *tf = [PEUIUtils textfieldWithPlaceholderTextKey:placeholder
                                                            font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:36.0 iphone6Width:38.0 iphone6PlusWidth:38.0 ipad:46.0]
                                                                                                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle1
                                                                                                                                                                      iphone6Width:UIFontTextStyleTitle1
                                                                                                                                                                  iphone6PlusWidth:UIFontTextStyleTitle1
                                                                                                                                                                              ipad:UIFontTextStyleTitle1]]]
                                                 backgroundColor:[UIColor whiteColor]
                                                 leftViewPadding:8.0
                                                      fixedWidth:repsWeightPanel.frame.size.width - leftBtn.frame.size.width - rightBtn.frame.size.width - (8.0 * 2) - (tfMargin * 2)];
    tf.layer.cornerRadius = 3.0;
    [PEUIUtils setFrameHeight:leftBtn.frame.size.height ofView:tf];
    [tf setKeyboardType:keyboardType];
    return tf;
  };
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  RUserSettings *userSettings = _userSettingsBlk(user);
  if (!_weightUomId) {
    _weightUomId = userSettings.weightUom;
  }
  CGFloat brickPadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:5.0 iphone6PlusWidth:5.0 ipad:10.0];
  UIView *barbellPresetWeights = nil;
  if ([PEUtils isNotNil:_movementVariant] && _weightUomId.integerValue == LBS_ID) { // because I don't know what good presets are for kg folks
    if (_movementVariant.localMasterIdentifier.integerValue == BARBELL_MOVEMENT_VARIANT_ID ||
        _movementVariant.localMasterIdentifier.integerValue == SMITH_MACHINE_MOVEMENT_VARIANT_ID) {
      barbellPresetWeights =
      [PEUIUtils panelOfBrickLayedViewsFromItems:@[@"95", @"135", @"185", @"225"]
                                       viewMaker:^UIView * (NSInteger i, NSString *amount) {
                                         UIButton *btn = [PEUIUtils buttonWithKey:amount
                                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                                              iphone6Width:UIFontTextStyleCaption1
                                                                                                                                          iphone6PlusWidth:UIFontTextStyleCaption1
                                                                                                                                                      ipad:UIFontTextStyleBody]]
                                                                  backgroundColor:[UIColor cloudsColor]
                                                                        textColor:[UIColor rikerAppBlack]
                                                     disabledStateBackgroundColor:nil
                                                           disabledStateTextColor:nil
                                                                  verticalPadding:[PEUIUtils valueIfiPhone5Width:9.0 iphone6Width:9.0 iphone6PlusWidth:12.0 ipad:15.0]
                                                                horizontalPadding:[PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:20.0 iphone6PlusWidth:25.0 ipad:30.0]
                                                                     cornerRadius:5.0
                                                                           target:nil
                                                                           action:nil];
                                         [btn bk_addEventHandler:^(id sender) {
                                           [_weightTf setText:amount];
                                         } forControlEvents:UIControlEventTouchUpInside];
                                         [PEUIUtils applyBorderToView:btn withColor:[UIColor silverColor] width:2.0];
                                         return btn;
                                       }
                                       extraView:nil
                                  availableWidth:repsWeightPanel.frame.size.width - saveSetTop.frame.size.width - changeHideUnitsButton.frame.size.width - (brickPadding * 3)
                                        hpadding:brickPadding
                                        vpadding:brickPadding];
    }
  }
  
  UIButton *(^makeRepWeightIncDecButton)(NSString *, NSString *) = ^UIButton * (NSString *title, NSString *value) {
    UIFontTextStyle fontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle2
                                                              iphone6Width:UIFontTextStyleTitle2
                                                          iphone6PlusWidth:UIFontTextStyleTitle2
                                                                      ipad:UIFontTextStyleTitle1];
    UIFont *btnFont = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:26.0 iphone6PlusWidth:28.0 ipad:34.0]
                                                            font:[PEUIUtils boldFontForTextStyle:fontTextStyle]];
    UIButton *btn =
    [PEUIUtils buttonWithAttributedTitle:[PEUIUtils attributedTextWithTemplate:title
                                                                  textToAccent:value
                                                                accentTextFont:btnFont]
                fontForHeightCalculation:btnFont
                         backgroundColor:[UIColor rikerAppBlack]
            disabledStateBackgroundColor:nil
                         verticalPadding:[PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:27.0 iphone6PlusWidth:30.0 ipad:38.0]
                       horizontalPadding:0.0
                            cornerRadius:3.0
                                  target:nil
                                  action:nil];
    return btn;
  };
  NSArray *(^switchViews)(NSString *, NSString *) = ^NSArray *(NSString *title, NSString *infoDescText) {
    UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    UILabel *switchLabel = [PEUIUtils labelWithKey:title
                                              font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:34.0 iphone6Width:36.0 iphone6PlusWidth:36.0 ipad:42.0]
                                                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                                                                                      iphone6Width:UIFontTextStyleBody
                                                                                                                                                  iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                                                              ipad:UIFontTextStyleTitle3]]]
                                   backgroundColor:[UIColor clearColor]
                                         textColor:[UIColor rikerAppBlack]
                               verticalTextPadding:2.0];
    NSMutableArray *views = [NSMutableArray arrayWithArray:@[theSwitch, switchLabel]];
    if (infoDescText) {
      CGFloat size = switchLabel.frame.size.height * 1.20;
      UIButton *infoBtn = [PEUIUtils buttonWithKey:@"i"
                                              font:[PEUIUtils infoIconFont]
                                   backgroundColor:[UIColor cloudsColor]
                                         textColor:[UIColor rikerAppBlack]
                      disabledStateBackgroundColor:nil
                            disabledStateTextColor:nil
                                   verticalPadding:0.0
                                 horizontalPadding:0.0
                                      cornerRadius:size * 0.5
                                            target:nil
                                            action:nil];
      [infoBtn bk_addEventHandler:^(id sender) {
        [RUtils logHelpInfoPopupContentViewed:[NSString stringWithFormat:@"enter_reps_%@", title]];
        [PEUIUtils showInfoAlertWithTitle:title
                         alertDescription:[[NSAttributedString alloc] initWithString:infoDescText]
                      descLblHeightAdjust:0.0
                additionalContentSections:nil
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:^{}
                           relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
      } forControlEvents:UIControlEventTouchUpInside];
      [PEUIUtils setFrameWidth:size ofView:infoBtn];
      [PEUIUtils setFrameHeight:size ofView:infoBtn];
      [views addObject:infoBtn];
    }
    UIView *panel = [PEUIUtils panelWithRowOfViews:views
                     horizontalPaddingBetweenViews:10.0
                                    viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
    return @[panel, theSwitch];
  };
  NSString *weightUomName = [RUtils weightUnitNameForUomId:_weightUomId];
  _weightIncDecAmount = userSettings.weightIncDecAmount;
  NSString *decWeightTitle = [NSString stringWithFormat:@" %@ %@ ", @"%@", weightUomName];
  UIButton *decWeightButton = makeRepWeightIncDecButton(decWeightTitle, [NSString stringWithFormat:@"- %@", _weightIncDecAmount]);
  NSString *incWeightTitle = [NSString stringWithFormat:@" %@ %@ ", @"%@", weightUomName];
  UIButton *incWeightButton = makeRepWeightIncDecButton(incWeightTitle, [NSString stringWithFormat:@"+ %@", _weightIncDecAmount]);
  _weightTf = makeTextField(@"Weight", decWeightButton, incWeightButton, UIKeyboardTypeDecimalPad);
  UIButton *decRepsButton = makeRepWeightIncDecButton(@" %@ ", @"- 1");
  UIButton *incRepsButton = makeRepWeightIncDecButton(@" %@ ", @"+ 1");
  [PEUIUtils setFrameWidth:decWeightButton.frame.size.width ofView:decRepsButton];
  [PEUIUtils setFrameWidth:incWeightButton.frame.size.width ofView:incRepsButton];
  _numRepsTf = makeTextField(@"Reps", decRepsButton, incRepsButton, UIKeyboardTypeNumberPad);
  NSArray *toFailureViews = switchViews(@"To Failure", @"Did you do as many reps as possible?  Or did you have more in you?  If you had more reps in you, uncheck this.");
  UIView *toFailurePanel = toFailureViews[0];
  _toFailureSwitch = toFailureViews[1];
  [_toFailureSwitch setOn:_toFailure];
  
  UILabel *weightTfFooterLabel = nil;
  BOOL isBodyLift = NO;
  if (_movementVariant.localMasterIdentifier.integerValue == BODY_MOVEMENT_VARIANT_ID) {
    isBodyLift = YES;
  } else if (_movement.isBodyLift && [PEUtils isNil:_movementVariant]) {
    isBodyLift = YES;
  }
  if (isBodyLift) {
    PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    RBodyMeasurementLog *bml = [_coordDao mostRecentBmlWithNonNilWeightForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
    [PEUIUtils setFrameWidth:repsWeightPanel.frame.size.width - (8.0 * 2) ofView:_weightTf];
    NSDecimalNumber *weightPercentage = _movement.percentageOfBodyWeight;
    if (!weightPercentage) {
      weightPercentage = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    }
    NSMutableAttributedString *weightTfFooterText = [[NSMutableAttributedString alloc] init];
    [weightTfFooterText appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ is a body-lift movement Riker estimates to use "
                                                                        textToAccent:[_movement.canonicalName sentenceCase]
                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]];
    [weightTfFooterText appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@%% of your body weight."
                                                                        textToAccent:[[weightPercentage decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] description]
                                                                      accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]];
    if (bml) {
      NSDecimalNumber *defaultedWeight = [weightPercentage decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:bml.bodyWeight.description]];
      if (!_weight) {
        _weight = [RUtils weightValueWithValue:defaultedWeight currentWeightUomId:bml.bodyWeightUom targetWeightUomId:_weightUomId];
      }
      if (!_hasShownWeightTfDefaultedNotice) {
        WeightTfDefaultedNotice weightTfDefaultedNotice = [_screenToolkit weightTfDefaultedToBodyWeightMaker];
        weightTfDefaultedNotice(_movement,
                                bml,
                                _weight,
                                [RUtils weightUnitNameForUomId:_weightUomId],
                                self);
        _hasShownWeightTfDefaultedNotice = YES;
      }
    } else {
      [weightTfFooterText appendAttributedString:AS(@"  Keep that in mind when entering the weight value.")];
    }
    weightTfFooterLabel = [PEUIUtils labelWithAttributeText:weightTfFooterText
                                                       font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor rikerAppBlack]
                                        verticalTextPadding:5.0
                                                 fitToWidth:_weightTf.frame.size.width - (3.0 * 2)];
  }
  UIView *decRepsButtonBelowView;
  // place weight/reps panel views
  if (isBodyLift) {
    [PEUIUtils placeView:_weightTf atTopOf:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:8.0 hpadding:8.0];
    repsWeightPanelHeight += _weightTf.frame.size.height + 8.0;
    [PEUIUtils placeView:weightTfFooterLabel below:_weightTf onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:2.0 hpadding:3.0];
    repsWeightPanelHeight += weightTfFooterLabel.frame.size.height + 2.0;
    decRepsButtonBelowView = weightTfFooterLabel;
  } else {
    [PEUIUtils placeView:decWeightButton atTopOf:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:8.0 hpadding:8.0];
    repsWeightPanelHeight += decWeightButton.frame.size.height + 8.0;
    [PEUIUtils placeView:_weightTf toTheRightOf:decWeightButton onto:repsWeightPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:tfMargin];
    [PEUIUtils placeView:incWeightButton toTheRightOf:_weightTf onto:repsWeightPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:tfMargin];
    decRepsButtonBelowView = decWeightButton;
  }
  CGFloat decRepsButtonBelowViewVpadding = 8.0;
  if (_toggleChangeUnitsPanel) {
    UILabel *unitsLabel = [PEUIUtils labelWithKey:@"Units"
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:5.0];
    UIButton *hideUnitsButton = makeChangeHideUnitsButton(15.0, @"hide");
    CGFloat unitsPanelHeight = 0.0;
    _unitsPanel = [PEUIUtils panelWithFixedWidth:repsWeightPanel.frame.size.width - (8.0 * 2) fixedHeight:0.0];
    [_unitsPanel setBackgroundColor:[UIColor cloudsColor]];
    [PEUIUtils placeView:unitsLabel atTopOf:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:10.0];
    unitsPanelHeight += unitsLabel.frame.size.height + 10.0;
    [PEUIUtils placeView:hideUnitsButton toTheRightOf:unitsLabel onto:_unitsPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:15.0];
    TNCircularRadioButtonData *(^makeRadioOption)(NSString *label, NSInteger) = ^TNCircularRadioButtonData * (NSString *label, NSInteger uomId) {
      TNCircularRadioButtonData *radioOption = [TNCircularRadioButtonData new];
      radioOption.labelText = label;
      radioOption.identifier = [NSString stringWithFormat:@"%ld", (long)uomId];
      radioOption.labelFont = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
      radioOption.selected = _weightUomId.integerValue == uomId;
      radioOption.borderColor = [UIColor rikerAppBlack];
      radioOption.circleColor = [UIColor rikerAppBlack];
      radioOption.borderRadius = 16;
      radioOption.circleRadius = 8;
      return radioOption;
    };
    TNCircularRadioButtonData *lbsOption = makeRadioOption(LBS_NAME, LBS_ID);
    TNCircularRadioButtonData *kgOption = makeRadioOption(KG_NAME, KG_ID);
    _weightUnitsGroup = [[TNRadioButtonGroup alloc] initWithRadioButtonData:@[lbsOption, kgOption]
                                                                     layout:TNRadioButtonGroupLayoutVertical];
    _weightUnitsGroup.marginBetweenItems = 10.0;
    [_weightUnitsGroup create];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weightUnitsGroupUpdated:) name:SELECTED_RADIO_BUTTON_CHANGED object:_weightUnitsGroup];
    [PEUIUtils placeView:_weightUnitsGroup below:unitsLabel onto:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:0.0];
    unitsPanelHeight += _weightUnitsGroup.frame.size.height + 10.0;
    UILabel *unitsFooterLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Weight unit default can be set in your %@."
                                                                                           textToAccent:@"Profile and Settings"
                                                                                         accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]
                                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                         fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor rikerAppBlack]
                                              verticalTextPadding:5.0
                                                       fitToWidth:_unitsPanel.frame.size.width - (10.0 * 2)];
    [PEUIUtils placeView:unitsFooterLabel below:_weightUnitsGroup onto:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_unitsPanel vpadding:4.0 hpadding:10.0];
    unitsPanelHeight += unitsFooterLabel.frame.size.height + 4.0;
    unitsPanelHeight += 5.0; // bottom margin
    [PEUIUtils setFrameHeight:unitsPanelHeight ofView:_unitsPanel];
    [PEUIUtils placeView:_unitsPanel below:decRepsButtonBelowView onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel  vpadding:8.0 hpadding:8.0];
    repsWeightPanelHeight += _unitsPanel.frame.size.height + 8.0;
    decRepsButtonBelowView = _unitsPanel;
    decRepsButtonBelowViewVpadding = 8.0;
    if (_animateChangeUnitsPanel) {
      [PEUIUtils popAnimateView:_unitsPanel
                        scaleUp:1.0
                      scaleDown:0.975
                scaleUpDuration:0.50
              scaleDownDuration:0.25
          scaleIdentityDuration:0.15 completion:nil];
      _animateChangeUnitsPanel = NO;
    }
  }
  [PEUIUtils placeView:decRepsButton below:decRepsButtonBelowView onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:decRepsButtonBelowViewVpadding hpadding:8.0];
  repsWeightPanelHeight += decRepsButton.frame.size.height + decRepsButtonBelowViewVpadding;
  [PEUIUtils placeView:_numRepsTf toTheRightOf:decRepsButton onto:repsWeightPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:tfMargin];
  [PEUIUtils placeView:incRepsButton toTheRightOf:_numRepsTf onto:repsWeightPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:tfMargin];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:30.0];
  [PEUIUtils placeView:toFailurePanel below:decRepsButton onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding hpadding:10.0];
  repsWeightPanelHeight += toFailurePanel.frame.size.height + vpadding;
  
  if (!_toggleMorePanel) {
    [PEUIUtils placeView:moreLessButton below:toFailurePanel onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding hpadding:10.0];
    repsWeightPanelHeight += moreLessButton.frame.size.height + vpadding;
  }
  if (_toggleMorePanel) {
    NSArray *negativesViews = switchViews(@"Negatives", @"Slowly loading the weight in the 'down' position of a movement, with a partner helping to bring the weight to the starting position.\n\nAlso known as eccentric training.");
    UIView *negativesPanel = negativesViews[0];
    _negativesSwitch = negativesViews[1];
    [_negativesSwitch setOn:_negatives];
    NSArray *realtimeViews = switchViews(@"Real Time", @"If you're using Riker to record your sets as you're actually working out, keep this checked, and Riker will record the timestamps of your sets automatically.\n\nIf you're using Riker to record your sets that you previously wrote down in a journal (you're digitizing your old data), then uncheck this box so you can manually enter the date.");
    UIView *realtimePanel = realtimeViews[0];
    _realtimeSwitch = realtimeViews[1];
    [_realtimeSwitch setOn:_realtime];
    [_realtimeSwitch bk_addEventHandler:^(id sender) {
      // give slight delay before reload screen
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self bindUiToModelWithTargetWeightUomId:_weightUomId];
        [self setNeedsRepaint:YES];
        [self viewDidAppear:YES];
      });
    } forControlEvents:UIControlEventTouchUpInside];
    UIView *separator = [PEUIUtils panelWithFixedWidth:repsWeightPanel.frame.size.width - (10.0 * 2) fixedHeight:1];
    [separator setBackgroundColor:[UIColor rikerAppBlackSemiClear]];
    [PEUIUtils placeView:separator below:toFailurePanel onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding / 2.0 hpadding:10.0];
    repsWeightPanelHeight += separator.frame.size.height + vpadding / 2.0;
    [PEUIUtils placeView:negativesPanel below:separator onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding / 2.0 hpadding:10.0];
    repsWeightPanelHeight += negativesPanel.frame.size.height + vpadding;
    [PEUIUtils placeView:realtimePanel below:negativesPanel onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding hpadding:10.0];
    repsWeightPanelHeight += realtimePanel.frame.size.height + vpadding / 2.0;
    UIView *topView = realtimePanel;
    if (!_realtime) {
      UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                 iphone6Width:UIFontTextStyleCaption1
                                                                             iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                         ipad:UIFontTextStyleSubheadline]];
      UITableView *manuallyLoggedAt =
      [_panelToolkit makeTableViewWithTag:14982
                                numFields:1
                  dataSourceDelegateMaker:^(UITableView *tableView) {
                    return
                    [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:self
                                                                          pickerScreenMaker:^(NSString *title, NSDate *loggedAt, void(^valPickedAction)(id)) {
                                                                            return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                                 initialSelectedDate:loggedAt
                                                                                                                      datePickerMode:(_ignoreTime ? UIDatePickerModeDate : UIDatePickerModeDateAndTime)
                                                                                                                 logDatePickedAction:valPickedAction]();
                                                                          }
                                                                          pickerScreenTitle:@"Logged at"
                                                                                 fieldLabel:@"Logged at"
                                                                        fieldValueFormatter:^(NSDate *loggedAt) {
                                                                          if (_ignoreTime) {
                                                                            return [PEUtils stringFromDate:loggedAt withPattern:DATE_PATTERN];
                                                                          } else {
                                                                            return [PEUtils stringFromDate:loggedAt withPattern:DATETIME_PATTERN];
                                                                          }
                                                                        }
                                                                                      value:_manuallyLoggedAt
                                                                          valuePickedAction:^(NSDate *loggedAt) {
                                                                            _manuallyLoggedAt = loggedAt;
                                                                            [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                             withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                          }
                                                                 displayDisclosureIndicator:YES
                                                                                  labelFont:font
                                                                                  valueFont:font
                                                                               leftIconName:nil
                                                                             relativeToView:contentPanel];
                  }
                           relativeToView:contentPanel
                     parentViewController:self];
      [manuallyLoggedAt setBackgroundColor:[UIColor silverColor]];
      manuallyLoggedAt.layer.cornerRadius = 3.0;
      [PEUIUtils setFrameWidth:repsWeightPanel.frame.size.width - (10.0 * 2) ofView:manuallyLoggedAt];
      NSArray *views = switchViews(@"Ignore time of day", @"Ignore the hour, minute and seconds part of the log date. Instead, just save the date.");
      UIView *ignoreTimePanel = views[0];
      _ignoreTimeSwitch = views[1];
      [_ignoreTimeSwitch setOn:_ignoreTime];
      [_ignoreTimeSwitch bk_addEventHandler:^(id sender) {
        // give slight delay before reload screen
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          _ignoreTime = _ignoreTimeSwitch.on;
          [manuallyLoggedAt reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        });
      } forControlEvents:UIControlEventTouchUpInside];
      [PEUIUtils placeView:manuallyLoggedAt below:realtimePanel onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:0.0];
      repsWeightPanelHeight += manuallyLoggedAt.frame.size.height + 10.0;
      [PEUIUtils placeView:ignoreTimePanel below:manuallyLoggedAt onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:5.0 hpadding:0.0];
      repsWeightPanelHeight += ignoreTimePanel.frame.size.height + 5.0;
      topView = ignoreTimePanel;
    }
    [PEUIUtils placeView:moreLessButton below:topView onto:repsWeightPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:repsWeightPanel vpadding:vpadding hpadding:10.0];
    repsWeightPanelHeight += moreLessButton.frame.size.height + vpadding;
  }
  repsWeightPanelHeight += [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:14.0 ipad:20.0]; // bottom margin
  [PEUIUtils setFrameHeight:repsWeightPanelHeight ofView:repsWeightPanel];
  // place content panel views
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0
                               iphone6Width:15.0
                           iphone6PlusWidth:25.0
                                       ipad:40.0];
  [PEUIUtils placeView:headerLabel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils placeView:aboutMovementBtn toTheRightOf:headerLabel onto:contentPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  [PEUIUtils adjustYOfView:aboutMovementBtn withValue:1.0];
  totalHeight += headerLabel.frame.size.height + vpadding;
  if (sets.count > 0) {
    vpadding = [PEUIUtils valueIfiPhone5Width:2.0 iphone6Width:4.0 iphone6PlusWidth:9.0 ipad:15.0];
  } else {
    vpadding = 0.0;
  }
  UILabel *(^nextSetLabelMaker)(void) = ^UILabel * {
    return [PEUIUtils labelWithKey:@"next:"
                              font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:40.0]
                                                                     font:[UIFont preferredFontForTextStyle:setButtonTextStyle]]
                   backgroundColor:[UIColor clearColor]
                         textColor:[UIColor rikerAppBlack]
               verticalTextPadding:0.0];
  };
  UIView *setsPanel;
  UILabel *setLabel = [PEUIUtils labelWithKey:@"sets:"
                                         font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:40.0]
                                                                                font:[UIFont preferredFontForTextStyle:setButtonTextStyle]]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor rikerAppBlack]
                          verticalTextPadding:0.0];
  _currentSetButton = makeCurrentSetButton([sets count] + 1);
  if ([sets count] > 0) {
    NSMutableArray *panelItems = [NSMutableArray arrayWithArray:sets];
    [panelItems addObject:@(0)];
    setsPanel = [PEUIUtils panelOfBrickLayedViewsFromItems:panelItems
                                                 viewMaker:^UIView * (NSInteger i, id __not_used__) {
                                                   if (i == 0) {
                                                     UIView *setLabelContainer = [PEUIUtils panelWithFixedWidth:setLabel.frame.size.width fixedHeight:_currentSetButton.frame.size.height];
                                                     [PEUIUtils placeView:setLabel inMiddleOf:setLabelContainer withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
                                                     return setLabelContainer;
                                                   } else {
                                                     return makeSetButton(i, sets[i - 1]);
                                                   }
                                                 }
                                                 extraView:[PEUIUtils panelWithRowOfViews:@[nextSetLabelMaker(), _currentSetButton]
                                                            horizontalPaddingBetweenViews:10.0
                                                                           viewsAlignment:PEUIVerticalAlignmentTypeMiddle]
                                            availableWidth:contentPanel.frame.size.width - (15.0 + setLabel.frame.size.width + 5.0) - (iphoneXSafeInsetsSideVal * 2)
                                                  hpadding:setButtonMargin
                                                  vpadding:setButtonMargin];
  } else {
    setsPanel = [PEUIUtils panelWithFixedWidth:0.0
                                   fixedHeight:_currentSetButton.frame.size.height];
    UILabel *hypenLabel = [PEUIUtils labelWithKey:@"--"
                                             font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:40.0]
                                                                                        font:[PEUIUtils boldFontForTextStyle:setButtonTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor bootstrapPrimary]
                              verticalTextPadding:0.0];
    UILabel *nextSetLabel = nextSetLabelMaker();
    CGFloat setsPanelWidth = 0.0;
    CGFloat hpadding = 0.0;
    [PEUIUtils placeView:setLabel inMiddleOf:setsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:hpadding];
    setsPanelWidth += setLabel.frame.size.width + hpadding;
    hpadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:9.0 ipad:13.0];
    [PEUIUtils placeView:hypenLabel toTheRightOf:setLabel onto:setsPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:hpadding];
    setsPanelWidth += hypenLabel.frame.size.width + hpadding;
    hpadding = 10.0;
    [PEUIUtils placeView:nextSetLabel toTheRightOf:hypenLabel onto:setsPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:hpadding];
    setsPanelWidth += nextSetLabel.frame.size.width + hpadding;
    hpadding = 10.0;
    [PEUIUtils placeView:_currentSetButton toTheRightOf:nextSetLabel onto:setsPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:hpadding];
    setsPanelWidth += _currentSetButton.frame.size.width + hpadding;
    [PEUIUtils setFrameWidth:setsPanelWidth ofView:setsPanel];
  }
  if (_animateCurrentSetButton) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [PEUIUtils popAnimateView:_currentSetButton
                        scaleUp:1.3
                      scaleDown:0.8
                scaleUpDuration:0.18
              scaleDownDuration:0.12
          scaleIdentityDuration:0.12
                     completion:nil];
    });
    _animateCurrentSetButton = NO;
  }
  vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:30.0];
  [PEUIUtils placeView:setsPanel
                 below:headerLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += setsPanel.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:16.0 iphone6PlusWidth:18.0 ipad:22.0];
  [PEUIUtils placeView:saveSetTop
                 below:setsPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += saveSetTop.frame.size.height + vpadding;
  if (barbellPresetWeights) {
    if ((15.0 +
         (iphoneXSafeInsetsSideVal * 2) +
         saveSetTop.frame.size.width +
         (brickPadding * 2) +
         barbellPresetWeights.frame.size.width +
         15.0 +
         changeHideUnitsButton.frame.size.width +
         15.0) <= contentPanel.frame.size.width) {
      // only add preset buttons if there's room
      [PEUIUtils placeView:barbellPresetWeights
              toTheRightOf:saveSetTop
                      onto:contentPanel
             withAlignment:PEUIVerticalAlignmentTypeBottom
                  hpadding:brickPadding * 2];
    }
  }
  [PEUIUtils placeView:changeHideUnitsButton
                 below:setsPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeRight
alignmentRelativeToView:contentPanel
              vpadding:0.0
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils setFrameY:[PEUIUtils YForHeight:changeHideUnitsButton.frame.size.height
                               withAlignment:PEUIVerticalAlignmentTypeMiddle
                              relativeToView:saveSetTop
                                    vpadding:0.0]
                ofView:changeHideUnitsButton];
  
  [PEUIUtils placeView:repsWeightPanel
                 below:saveSetTop
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += repsWeightPanel.frame.size.height + 10.0;
  [PEUIUtils placeView:saveSetBottom
                 below:repsWeightPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += saveSetBottom.frame.size.height + 10.0;
  
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  
  // add button event handlers
  [decWeightButton bk_addEventHandler:^(id sender) {
    [self decrementWeight];
  } forControlEvents:UIControlEventTouchUpInside];
  [decWeightButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(decWeightLongPressHandler:)]];
  
  [incWeightButton bk_addEventHandler:^(id sender) {
    [self incrementWeight];
  } forControlEvents:UIControlEventTouchUpInside];
  [incWeightButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(incWeightLongPressHandler:)]];
  [decRepsButton bk_addEventHandler:^(id sender) {
    [self decrementReps];
  } forControlEvents:UIControlEventTouchUpInside];
  [decRepsButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(decRepsLongPressHandler:)]];
  [incRepsButton bk_addEventHandler:^(id sender) {
    [self incrementReps];
  } forControlEvents:UIControlEventTouchUpInside];
  [incRepsButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(incRepsLongPressHandler:)]];
  if (_weight) {
    [_weightTf setText:[_decimalFormatter stringFromNumber:_weight]];
  }
  if (_numReps) {
    [_numRepsTf setText:[_numReps description]];
  }
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Long Press Handler Helper

- (void)longPressHandler:(UIGestureRecognizer *)gestureRecognizer timerActionSelector:(SEL)timerActionSelector {
  switch (gestureRecognizer.state) {
    case UIGestureRecognizerStatePossible:
    case UIGestureRecognizerStateChanged:
      // to get rid of compiler warning
      break;
    case UIGestureRecognizerStateBegan: {
      _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:timerActionSelector userInfo:nil repeats:YES];
      break;
    }
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
    case UIGestureRecognizerStateEnded:
      [_timer invalidate];
      break;
  }
}

#pragma mark - Long Press Handlers

- (void)incRepsLongPressHandler:(UIGestureRecognizer *)gestureRecognizer {
  [self longPressHandler:gestureRecognizer timerActionSelector:@selector(incrementReps)];
}

- (void)decRepsLongPressHandler:(UIGestureRecognizer *)gestureRecognizer {
  [self longPressHandler:gestureRecognizer timerActionSelector:@selector(decrementReps)];
}

- (void)incWeightLongPressHandler:(UIGestureRecognizer *)gestureRecognizer {
  [self longPressHandler:gestureRecognizer timerActionSelector:@selector(incrementWeight)];
}

- (void)decWeightLongPressHandler:(UIGestureRecognizer *)gestureRecognizer {
  [self longPressHandler:gestureRecognizer timerActionSelector:@selector(decrementWeight)];
}

#pragma mark - Button Handlers

- (void)incrementReps {
  NSString *numRepsTfVal = _numRepsTf.text;
  if (numRepsTfVal && [numRepsTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
    NSInteger numRepsTfIntVal = [numRepsTfVal integerValue];
    [_numRepsTf setText:[NSString stringWithFormat:@"%ld", (long)numRepsTfIntVal + 1]];
  } else {
    [_numRepsTf setText:@"1"];
  }
}

- (void)decrementReps {
  NSString *numRepsTfVal = _numRepsTf.text;
  if (numRepsTfVal && [numRepsTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
    NSInteger numRepsTfIntVal = [numRepsTfVal integerValue];
    NSInteger diff = numRepsTfIntVal - 1;   
    if (diff < 0) {
      [_numRepsTf setText:@"0"];
    } else {
      [_numRepsTf setText:[NSString stringWithFormat:@"%ld", (long)diff]];
    }
  }
}

- (void)decrementWeight {
  NSString *weightTfVal = _weightTf.text;
  if (weightTfVal && [weightTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
    NSDecimalNumber *weightTfDecimalVal = [NSDecimalNumber decimalNumberWithString:weightTfVal];
    NSInteger incDecAmount = _weightIncDecAmount.integerValue;
    NSDecimalNumber *diff = [weightTfDecimalVal decimalNumberBySubtracting:[[NSDecimalNumber alloc] initWithInteger:incDecAmount]];
    if ([diff compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
      [_weightTf setText:@"0"];
    } else {
      [_weightTf setText:[_decimalFormatter stringFromNumber:diff]];
    }
  }
}

- (void)incrementWeight {
  NSString *weightTfVal = _weightTf.text;
  if (weightTfVal && [weightTfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
    NSDecimalNumber *weightTfDecimalVal = [NSDecimalNumber decimalNumberWithString:weightTfVal];
    NSInteger incDecAmount = _weightIncDecAmount.integerValue;
    [_weightTf setText:[_decimalFormatter stringFromNumber:[weightTfDecimalVal decimalNumberByAdding:[[NSDecimalNumber alloc] initWithInteger:incDecAmount]]]];
  } else {
    [_weightTf setText:[_weightIncDecAmount description]];
  }
}

@end
