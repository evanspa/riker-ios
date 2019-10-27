//
//  REnrollSynchronizeScreen.h
//  riker-ios
//
//  Created by PEVANS on 1/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIkit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"
@import WatchConnectivity;

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class SKProduct;

@interface REnrollSynchronizeScreen : PELocalDataBaseController <MBProgressHUDDelegate, WCSessionDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
           subscriptionProduct:(SKProduct *)subscriptionProduct
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
