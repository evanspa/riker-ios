//
//  REnterMeasurementScreen.m
//  riker-ios
//
//  Created by PEVANS on 3/22/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "REnterMeasurementScreen.h"
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
@import Firebase;

@implementation REnterMeasurementScreen {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RUserSettingsBlk _userSettingsBlk;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  BOOL _dismissable;
  BOOL _toggleChangeUnitsPanel;
  BOOL _animateChangeUnitsPanel;
  NSNumber *_uomId;
  TNRadioButtonGroup *_unitsGroup;
  NSNumber *_value;
  UITextField *_valueTf;
  NSDate *_manuallyLoggedAt;
  UIView *_unitsPanel;
  NSString *_title;
  UIKeyboardType _keyboardType;
  NSNumber *(^_toValueBlk)(NSString *, NSNumber *, NSNumber *);
  NSNumberFormatter *_numberFormatter;
  NSString *_headerText;
  NSString *_saveButtonTitle;
  void (^_mutateBmlBlk)(RBodyMeasurementLog *, NSString *, NSNumber *, RUserSettings *);
  NSNumber *(^_defaultUomIdBlk)(RUserSettings *);
  NSString *_uomDefaultPrefixMessage;
  NSString *(^_uomNameBlk)(NSNumber *);
  NSString *_valueTfPlaceholderText;
  NSArray *_uomOptions;
  void (^_dismissedBlk)(void);
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                         title:(NSString *)title
                    headerText:(NSString *)headerText
               saveButtonTitle:(NSString *)saveButtonTitle
                  mutateBmlBlk:(void(^)(RBodyMeasurementLog *, NSString *, NSNumber *, RUserSettings *))mutateBmlBlk
               defaultUomIdBlk:(NSNumber *(^)(RUserSettings *))defaultUomIdBlk
       uomDefaultPrefixMessage:(NSString *)uomDefaultPrefixMessage
                    uomNameBlk:(NSString *(^)(NSNumber *))uomNameBlk
        valueTfPlaceholderText:(NSString *)valueTfPlaceholderTf
                    uomOptions:(NSArray *)uomOptions
                  keyboardType:(UIKeyboardType)keyboardType
                    toValueBlk:(NSNumber *(^)(NSString *, NSNumber *, NSNumber *))toValueBlk
         maximumFractionDigits:(NSInteger)maximumFractionDigits
                   dismissable:(BOOL)dismissable
                  dismissedBlk:(void(^)(void))dismissedBlk
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:title];
  if (self) {
    _title = title;
    _headerText = headerText;
    _saveButtonTitle = saveButtonTitle;
    _mutateBmlBlk = mutateBmlBlk;
    _defaultUomIdBlk = defaultUomIdBlk;
    _uomDefaultPrefixMessage = uomDefaultPrefixMessage;
    _uomNameBlk = uomNameBlk;
    _valueTfPlaceholderText = valueTfPlaceholderTf;
    _uomOptions = uomOptions;
    _keyboardType = keyboardType;
    _toValueBlk = toValueBlk;
    _dismissable = dismissable;
    _userSettingsBlk = userSettingsBlk;
    _dismissedBlk = dismissedBlk;
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    [self setDelaysContentTouches:NO];
    _toggleChangeUnitsPanel = NO;
    _animateChangeUnitsPanel = NO;
    _manuallyLoggedAt = [NSDate date];
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    _numberFormatter.maximumFractionDigits = maximumFractionDigits;
    _numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
  }
  return self;
}

#pragma mark - Dismiss

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:_dismissedBlk];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  if (_dismissable) {
    UINavigationItem *navItem = [self navigationItem];
    UIBarButtonItem *dismissBtn =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [navItem setRightBarButtonItem:dismissBtn];
  }
}

#pragma mark - Data Binding

- (void)bindUiToModelWithTargetUomId:(NSNumber *)targetUomId {
  NSString *tfVal = _valueTf.text;
  if (tfVal && [tfVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
    _value = _toValueBlk(tfVal, _uomId, targetUomId);
  } else {
    _value = nil;
  }
}

#pragma mark - Notifications

- (void)unitsGroupUpdated:(NSNotification *)notification {
  TNRadioButton *selectedRadioOption = _unitsGroup.selectedRadioButton;
  NSInteger selectedRadioUomId = [selectedRadioOption.data.identifier integerValue];
  if (selectedRadioUomId != _uomId.integerValue) {
    NSNumber *newUomId = [NSNumber numberWithInteger:selectedRadioUomId];
    [self bindUiToModelWithTargetUomId:newUomId];
    _uomId = newUomId;
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

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat totalHeight = 0.0;
  PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  RUserSettings *userSettings = _userSettingsBlk(user);
  if (!_uomId) {
    if (_defaultUomIdBlk) {
      _uomId = _defaultUomIdBlk(userSettings);
    }
  }
  NSString *uomName = nil;
  if (_uomNameBlk) {
    uomName = _uomNameBlk(_uomId);
  }
  UILabel *headerLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"%@ - %@", _headerText, uomName]
                                            font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                                           iphone6Width:UIFontTextStyleTitle3
                                                                                                       iphone6PlusWidth:UIFontTextStyleTitle2
                                                                                                                   ipad:UIFontTextStyleTitle1]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor rikerAppBlack]
                             verticalTextPadding:5.0
                                      fitToWidth:contentPanel.frame.size.width - (15.0 * 2) - (iphoneXSafeInsetsSideVal * 2)];
  UIButton *(^makeSaveBmlButton)(void) = ^{
    UIButton *btn = [PEUIUtils buttonWithKey:_saveButtonTitle
                                        font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                                       iphone6Width:UIFontTextStyleBody
                                                                                                   iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                               ipad:UIFontTextStyleTitle2]]
                             backgroundColor:[UIColor emerlandColor]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:34.0 ipad:40.0]
                           horizontalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:32.0]
                                cornerRadius:3.0
                                      target:nil
                                      action:nil];
    [btn bk_addEventHandler:^(id sender) {
      NSMutableArray *errMsgs = [NSMutableArray array];
      void (^validate)(UITextField *, NSString *, NSString *, NSString *) = ^(UITextField *tf, NSString *emptyErrMsg, NSString *nonNumericErrMsg, NSString *nonPositiveErrMsg) {
        NSString *tfValStr = [tf text];
        tfValStr = [tfValStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (tfValStr.length == 0) {
          [errMsgs addObject:emptyErrMsg];
        } else {
          NSNumber *val = [_numberFormatter numberFromString:tfValStr];
          if ([PEUtils isNil:val]) {
            [errMsgs addObject:nonNumericErrMsg];
          } else {
            if (val.integerValue <= 0) {
              [errMsgs addObject:nonPositiveErrMsg];
            }
          }
        }
      };
      validate(_valueTf, @"Value cannot be empty", @"Value must be a number", @"Value must be a positive value");
      if ([errMsgs count] == 0) {
        RBodyMeasurementLog *bml =
        [_coordDao bmlWithBodyWeight:nil
                       bodyWeightUom:nil
                             armSize:nil
                            calfSize:nil
                           chestSize:nil
                             sizeUom:nil
                            neckSize:nil
                           waistSize:nil
                           thighSize:nil
                         forearmSize:nil
                            loggedAt:_manuallyLoggedAt != nil ? _manuallyLoggedAt : [NSDate date]
                 originationDeviceId:[PEUIUtils isIpad] ? @(ORIGINATION_DEVICE_ID_IPAD) : @(ORIGINATION_DEVICE_ID_IPHONE)
                          importedAt:nil];
        _mutateBmlBlk(bml, _valueTf.text, _uomId, userSettings);
        void(^postProcessingForSavedBml)(RBodyMeasurementLog *) = ^(RBodyMeasurementLog *newBml) {
          [[NSNotificationCenter defaultCenter] postNotificationName:REntityAddedNotification
                                                              object:self
                                                            userInfo:@{@"entity": newBml}];          
          [self dismiss];
        };
        PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
        if ([APP doesUserHaveValidAuthToken] && ![APP offlineMode] && ![user isBadAccount]) {
          void (^dialogDismissAction)(void) = ^{
            [APP refreshTabs];
            [self enableUi];
          };
          JGActionSheetSection *(^bmlLocallySavedSection)(void) = ^{
            return [PEUIUtils successAlertSectionWithTitle:@"Body log saved."
                                          alertDescription:AS(@"Your body log has been saved locally.")
                                       descLblHeightAdjust:0.0
                                            relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          };
          JGActionSheetSection *(^goOfflineSection)(void) = ^{
            return [_panelToolkit goOfflineAlertSectionRelativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          };
          [self disableUi];
          MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          HUD.tag = RHUD_TAG;
          [self disableUi];
          HUD.delegate = self;
          HUD.mode = MBProgressHUDModeIndeterminate;
          HUD.label.text = @"Saving to the server...";
          void(^handleInexplicableError)(RBodyMeasurementLog *) = ^(RBodyMeasurementLog *bml) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [HUD hideAnimated:YES];
              [PEUIUtils showErrorAlertWithMsgs:nil
                                          title:@"Oops."
                               alertDescription:AS(@"An unknown error occurred while attempting to sync your body log.")
                            descLblHeightAdjust:0.0
                      additionalContentSections:@[bmlLocallySavedSection(), goOfflineSection()]
                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                    buttonTitle:@"Okay."
                                   buttonAction:^{
                                     postProcessingForSavedBml(bml);
                                     dialogDismissAction();
                                   }
                                 relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
            });
          };
          [_coordDao saveNewAndSyncImmediateBml:bml
                                        forUser:user
                        writeUserReadonlyFields:YES
                            notFoundOnServerBlk:^{
                              [RUtils logEvent:@"not_found_wh_e_r_save_bml"];
                              handleInexplicableError(bml);
                            }
                                 addlSuccessBlk:^{
                                   [RUtils logEvent:@"success_wh_e_r_save_bml"];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     [RUtils saveHealthKitBmlsWithCompletion:nil noOpBlk:nil raiseNotificationOnError:YES coordDao:_coordDao healthStore:[APP healthStore]];
                                     [HUD hideAnimated:YES];
                                     [PEUIUtils showSuccessAlertWithTitle:@"Body log saved and synced."
                                                         alertDescription:AS(@"Your body log has been saved and synced to your account.")
                                                      descLblHeightAdjust:0.0
                                                 additionalContentSection:nil
                                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                              buttonTitle:@"Okay."
                                                             buttonAction:^{
                                                               postProcessingForSavedBml(bml);
                                                               dialogDismissAction();
                                                             }
                                                           relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                   });
                                 }
                         addlRemoteStoreBusyBlk:^(NSDate *retryAfter) {
                           [RUtils logEvent:@"busy_wh_e_r_save_bml"];
                           dispatch_async(dispatch_get_main_queue(), ^{
                             [HUD hideAnimated:YES];
                             [PEUIUtils showWaitAlertWithMsgs:nil
                                                        title:@"Busy with maintenance."
                                             alertDescription:AS(@"Your body log could not be synced because the Riker server is currently busy undergoing maintenance.")
                                          descLblHeightAdjust:0.0
                                    additionalContentSections:@[bmlLocallySavedSection(), goOfflineSection()]
                                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                  buttonTitle:@"Okay."
                                                 buttonAction:^{
                                                 }
                                               relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                           });
                         }
                         addlTempRemoteErrorBlk:^{
                           [RUtils logEvent:@"temp_remote_err_wh_e_r_save_bml"];
                           handleInexplicableError(bml);
                         }
                             addlRemoteErrorBlk:^(NSInteger errMask) {
                               [RUtils logEvent:@"remote_err_wh_e_r_save_bml"
                                         params:[RUtils eventLogParamsWithErrMask:errMask]];
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 [HUD hideAnimated:YES];
                                 NSArray *errMsgs = [RUtils computeBmlErrMsgs:errMask];
                                 [PEUIUtils showErrorAlertWithMsgs:errMsgs
                                                             title:@"Oops."
                                                  alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"There %@ attempting to sync your body  log.", errMsgs.count > 1 ? @"were problems" : @"was a problem"]]
                                               descLblHeightAdjust:0.0
                                         additionalContentSections:@[bmlLocallySavedSection(), goOfflineSection()]
                                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                       buttonTitle:@"Okay."
                                                      buttonAction:^{
                                                        postProcessingForSavedBml(bml);
                                                        dialogDismissAction();
                                                      }
                                                    relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                               });
                             }                                
                            addlAuthRequiredBlk:^{
                              [RUtils logEvent:@"auth_reqd_wh_e_r_save_bml"];
                              dispatch_async(dispatch_get_main_queue(), ^{
                                [HUD hideAnimated:YES];
                                [PEUIUtils showErrorAlertWithMsgs:nil
                                                            title:@"Oops."
                                                 alertDescription:AS(@"Unable to sync your body log.")
                                              descLblHeightAdjust:0.0
                                        additionalContentSections:@[[PEUIUtils becameUnauthenticatedSectionRelativeToView:[PEUIUtils parentViewForAlertsForController:self]],
                                                                    bmlLocallySavedSection()]
                                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                      buttonTitle:@"Okay."
                                                     buttonAction:^{
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                                           object:self
                                                                                                         userInfo:nil];
                                                       postProcessingForSavedBml(bml);
                                                       dialogDismissAction();
                                                     }
                                                   relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                              });
                            }
                               addlForbiddenBlk:^{
                                 [RUtils logEvent:@"forbidden_wh_e_r_save_bml"];
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   [HUD hideAnimated:YES];
                                   [PEUIUtils showErrorAlertWithMsgs:nil
                                                               title:@"Oops."
                                                    alertDescription:AS(@"Unable to sync your body log.")
                                                 descLblHeightAdjust:0.0
                                           additionalContentSections:@[[PEUIUtils receivedNotPermittedSectionRelativeToView:[PEUIUtils parentViewForAlertsForController:self]],
                                                                       bmlLocallySavedSection()]
                                                            topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                         buttonTitle:@"Okay."
                                                        buttonAction:^{
                                                          postProcessingForSavedBml(bml);
                                                          dialogDismissAction();
                                                        }
                                                      relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
                                 });
                               }
                                          error:[RUtils localSaveErrorHandlerMaker]()];
          
          
        } else {
          [_coordDao saveNewBml:bml forUser:user error:[RUtils localSaveErrorHandlerMaker]()];
          [RUtils saveHealthKitBmlsWithCompletion:nil noOpBlk:nil raiseNotificationOnError:YES coordDao:_coordDao healthStore:[APP healthStore]];
          void (^buttonAction)(void) = ^{
            postProcessingForSavedBml(bml);
            [APP refreshTabs];
          };
          if ([APP offlineMode]) {
            [RUtils logEvent:@"e_r_bml_saved_local_wh_offline"];
            [PEUIUtils showOfflineModeEnabledAlertWithTitle:@"Body log saved locally."
                                           alertDescription:AS(@"Your body log has been saved locally.")
                                        descLblHeightAdjust:0.0
                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                buttonTitle:@"Okay."
                                               buttonAction:buttonAction
                                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else if ([APP isUserLoggedIn] && ![APP doesUserHaveValidAuthToken]) {
            [RUtils logEvent:@"e_r_bml_saved_local_wh_unauth"];
            [PEUIUtils recordSavedWhileUnauthAlertWithTitle:@"Body log saved locally."
                                           alertDescription:AS(@"Your body log has been saved locally.")
                                        descLblHeightAdjust:0.0
                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                buttonTitle:@"Okay."
                                               buttonAction:buttonAction
                                             relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else if ([APP isUserLoggedIn] && [user isBadAccount]) {
            [RUtils logEvent:@"e_r_bml_saved_local_wh_bad_acct"];
            [PEUIUtils recordSavedWhileBadAccountAlertWithTitle:@"Body log saved locally."
                                               alertDescription:AS(@"Your body log has been saved locally.")
                                            descLblHeightAdjust:0.0
                                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                    buttonTitle:@"Okay."
                                                   buttonAction:buttonAction
                                                 relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
          } else {
            [RUtils logEvent:@"e_r_bml_saved_local_wh_anon"];
            [PEUIUtils showSuccessAlertWithTitle:@"Body log saved."
                                alertDescription:AS(@"Your body log has been saved.")
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
  UIButton *saveBmlTop = makeSaveBmlButton();
  UIButton *saveBmlBottom = makeSaveBmlButton();
  UIButton *(^makeChangeHideUnitsButton)(NSString *) = ^UIButton * (NSString *title) {
    UIButton *button = [PEUIUtils buttonWithKey:title
                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                            iphone6Width:UIFontTextStyleCaption1
                                                                                                        iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                    ipad:UIFontTextStyleBody]]
                                backgroundColor:[UIColor cloudsColor]
                                      textColor:[UIColor rikerAppBlack]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:15.0
                              horizontalPadding:[PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:15.0 iphone6PlusWidth:20.0 ipad:25.0]
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
        [self bindUiToModelWithTargetUomId:_uomId];
        [self viewDidAppear:YES];
      } else {
        [self bindUiToModelWithTargetUomId:_uomId];
        [self viewDidAppear:YES];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    return button;
  };
  UIButton *changeHideUnitsButton = nil;
  if (_defaultUomIdBlk) {
    changeHideUnitsButton = makeChangeHideUnitsButton(_toggleChangeUnitsPanel ? @"hide units" : @"change units");
  }
  CGFloat valuePanelHeight = 0.0;
  UIView *valuePanel = [PEUIUtils panelWithFixedWidth:contentPanel.frame.size.width - (15.0 * 2) - (iphoneXSafeInsetsSideVal * 2) fixedHeight:0.0];
  [valuePanel setBackgroundColor:[UIColor silverColor]];
  valuePanel.layer.cornerRadius = 3.0;
  UITextField *(^makeTextField)(NSString*) = ^UITextField * (NSString *placeholder) {
    UITextField *tf = [PEUIUtils textfieldWithPlaceholderTextKey:placeholder
                                                            font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle1
                                                                                                                           iphone6Width:UIFontTextStyleTitle1
                                                                                                                       iphone6PlusWidth:UIFontTextStyleTitle1
                                                                                                                                   ipad:UIFontTextStyleTitle1]]
                                                 backgroundColor:[UIColor whiteColor]
                                                 leftViewPadding:8.0
                                                      fixedWidth:valuePanel.frame.size.width - (8.0 * 2)];
    tf.layer.cornerRadius = 3.0;
    [tf setKeyboardType:_keyboardType];
    return tf;
  };
  _valueTf = makeTextField([NSString stringWithFormat:@"%@%@", _valueTfPlaceholderText, uomName != nil ? [NSString stringWithFormat:@" (%@)", uomName] : @""]);
  if (_value) {
    [_valueTf setText:[_numberFormatter stringFromNumber:_value]];
  }
  UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UITableView *loggedAtTableView =
  [_panelToolkit makeTableViewWithTag:14982
                            numFields:1
              dataSourceDelegateMaker:^(UITableView *tableView) {
                PESingleValueTableViewDataSourceDelegate *dsDelegate =
                [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:self
                                                                      pickerScreenMaker:^(NSString *title, NSDate *loggedAt, void(^valPickedAction)(id)) {
                                                                        return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                             initialSelectedDate:loggedAt
                                                                                                                  datePickerMode:UIDatePickerModeDate
                                                                                                             logDatePickedAction:valPickedAction]();
                                                                      }
                                                                      pickerScreenTitle:@"Logged at"
                                                                             fieldLabel:@"Logged at"
                                                                    fieldValueFormatter:^(NSDate *loggedAt) { return [PEUtils stringFromDate:loggedAt withPattern:DATE_PATTERN]; }
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
                dsDelegate.textLabelColor = [UIColor rikerAppBlack];
                return dsDelegate;
              }
                       relativeToView:contentPanel
                 parentViewController:self];
  [loggedAtTableView setBackgroundColor:[UIColor silverColor]];
  loggedAtTableView.layer.cornerRadius = 3.0;
  [PEUIUtils setFrameWidth:valuePanel.frame.size.width - (8.0 * 2) ofView:loggedAtTableView];
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:12.0 iphone6PlusWidth:14.0 ipad:20.0];
  [PEUIUtils placeView:_valueTf atTopOf:valuePanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:8.0];
  valuePanelHeight += _valueTf.frame.size.height + vpadding;
  UIView *topView = _valueTf;
  if (_toggleChangeUnitsPanel) {
    UILabel *unitsLabel = [PEUIUtils labelWithKey:@"Units"
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:5.0];
    UIButton *hideUnitsButton = makeChangeHideUnitsButton(@"hide");
    CGFloat unitsPanelHeight = 0.0;
    _unitsPanel = [PEUIUtils panelWithFixedWidth:valuePanel.frame.size.width - (8.0 * 2) fixedHeight:0.0];
    [_unitsPanel setBackgroundColor:[UIColor cloudsColor]];
    [PEUIUtils placeView:unitsLabel atTopOf:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:10.0];
    unitsPanelHeight += unitsLabel.frame.size.height + 10.0;
    [PEUIUtils placeView:hideUnitsButton toTheRightOf:unitsLabel onto:_unitsPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:15.0];
    TNCircularRadioButtonData *(^makeRadioOption)(NSString *label, NSInteger) = ^TNCircularRadioButtonData * (NSString *label, NSInteger uomId) {
      TNCircularRadioButtonData *radioOption = [TNCircularRadioButtonData new];
      radioOption.labelText = label;
      radioOption.identifier = [NSString stringWithFormat:@"%ld", (long)uomId];
      radioOption.labelFont = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
      radioOption.selected = _uomId.integerValue == uomId;
      radioOption.borderColor = [UIColor rikerAppBlack];
      radioOption.circleColor = [UIColor rikerAppBlack];
      radioOption.borderRadius = 16;
      radioOption.circleRadius = 8;
      return radioOption;
    };
    NSMutableArray *radioButtonData = nil;
    if (_uomOptions) {
      radioButtonData = [NSMutableArray arrayWithCapacity:_uomOptions.count];
      //TNCircularRadioButtonData *lbsOption = makeRadioOption(LBS_NAME, LBS_ID);
      //TNCircularRadioButtonData *kgOption = makeRadioOption(KG_NAME, KG_ID);
      for (NSArray *uomOption in _uomOptions) {
        [radioButtonData addObject:makeRadioOption(uomOption[0], ((NSNumber *)uomOption[1]).integerValue)];
      }
      _unitsGroup = [[TNRadioButtonGroup alloc] initWithRadioButtonData:radioButtonData
                                                                 layout:TNRadioButtonGroupLayoutVertical];
      _unitsGroup.marginBetweenItems = 10.0;
      [_unitsGroup create];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unitsGroupUpdated:) name:SELECTED_RADIO_BUTTON_CHANGED object:_unitsGroup];
      [PEUIUtils placeView:_unitsGroup below:unitsLabel onto:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:10.0 hpadding:0.0];
      unitsPanelHeight += _unitsGroup.frame.size.height + 10.0;
      UILabel *unitsFooterLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"%@ %%@.", _uomDefaultPrefixMessage]
                                                                                             textToAccent:@"Profile and Settings"
                                                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]]
                                                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                           fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:UIFontTextStyleCaption1]
                                                    backgroundColor:[UIColor clearColor]
                                                          textColor:[UIColor rikerAppBlack]
                                                verticalTextPadding:5.0
                                                         fitToWidth:_unitsPanel.frame.size.width - (10.0 * 2)];
      [PEUIUtils placeView:unitsFooterLabel below:_unitsGroup onto:_unitsPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:_unitsPanel vpadding:4.0 hpadding:10.0];
      unitsPanelHeight += unitsFooterLabel.frame.size.height + 4.0;
      unitsPanelHeight += 5.0; // bottom margin
      [PEUIUtils setFrameHeight:unitsPanelHeight ofView:_unitsPanel];
      [PEUIUtils placeView:_unitsPanel below:_valueTf onto:valuePanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:valuePanel  vpadding:8.0 hpadding:8.0];
      valuePanelHeight += _unitsPanel.frame.size.height + 8.0;
      if (_animateChangeUnitsPanel) {
        [PEUIUtils popAnimateView:_unitsPanel
                          scaleUp:1.0
                        scaleDown:0.975
                  scaleUpDuration:0.50
                scaleDownDuration:0.25
            scaleIdentityDuration:0.15
                       completion:nil];
        _animateChangeUnitsPanel = NO;
      }
      topView = _unitsPanel;
    }
  }
  [PEUIUtils placeView:loggedAtTableView below:topView onto:valuePanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  valuePanelHeight += loggedAtTableView.frame.size.height + vpadding;
  valuePanelHeight += (vpadding - 3.5); // bottom margin...minus 5 because height of table view is a bit wonky
  [PEUIUtils setFrameHeight:valuePanelHeight ofView:valuePanel];
  // place content panel views
  vpadding = [PEUIUtils valueIfiPhone5Width:15.0
                               iphone6Width:15.0
                           iphone6PlusWidth:25.0
                                       ipad:40.0];
  [PEUIUtils placeView:headerLabel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += headerLabel.frame.size.height + vpadding;
  [PEUIUtils placeView:saveBmlTop
                 below:headerLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += saveBmlTop.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:2.0 iphone6Width:4.0 iphone6PlusWidth:9.0 ipad:15.0];
  if (changeHideUnitsButton) {
    [PEUIUtils placeView:changeHideUnitsButton
                   below:headerLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeRight
 alignmentRelativeToView:contentPanel
                vpadding:0.0
                hpadding:15.0 + iphoneXSafeInsetsSideVal];
    [PEUIUtils setFrameY:[PEUIUtils YForHeight:changeHideUnitsButton.frame.size.height
                                 withAlignment:PEUIVerticalAlignmentTypeMiddle
                                relativeToView:saveBmlTop
                                      vpadding:0.0]
                  ofView:changeHideUnitsButton];
  }
  [PEUIUtils placeView:valuePanel
                 below:saveBmlTop
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += valuePanel.frame.size.height + 10.0;
  [PEUIUtils placeView:saveBmlBottom
                 below:valuePanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  totalHeight += saveBmlBottom.frame.size.height + 10.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

@end
