//
//  RRecordsController.h
//  riker-ios
//
//  Created by PEVANS on 11/3/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"
@import WatchConnectivity;

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;

@interface RRecordsController : PELocalDataBaseController <MBProgressHUDDelegate, WCSessionDelegate>

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit;

@end
