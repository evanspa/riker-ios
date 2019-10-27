//
//  RAppleWatchController.h
//  Riker
//
//  Created by PEVANS on 10/24/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"
@import WatchConnectivity;

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;

@interface RAppleWatchController : PELocalDataBaseController <MBProgressHUDDelegate, WCSessionDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao               
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit;

@end
