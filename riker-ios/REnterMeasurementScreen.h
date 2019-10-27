//
//  REnterMeasurementScreen.h
//  riker-ios
//
//  Created by PEVANS on 3/22/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PEBaseController.h"
#import "RUtils.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;
@class RBodyMeasurementLog;

@interface REnterMeasurementScreen : PEBaseController <MBProgressHUDDelegate>

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
                   panelTookit:(RPanelToolkit *)panelToolkit;

@end
