//
//  RAccountController.h
//  riker-ios
//
//  Created by PEVANS on 11/3/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PELocalDataBaseController.h"
#import <StoreKit/StoreKit.h>
#import "RUtils.h"
@import WatchConnectivity;

@protocol MBProgressHUDDelegate;
@protocol RCoordinatorDao;
@class PELMUser;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;

@interface RAccountController : PELocalDataBaseController <MBProgressHUDDelegate,
SKProductsRequestDelegate,
WCSessionDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit;

@end
