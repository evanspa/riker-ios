//
//  RDoEnrollScreen.h
//  riker-ios
//
//  Created by PEVANS on 1/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIkit.h>
#import <StoreKit/StoreKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class SKProduct;

@interface RDoEnrollScreen : PELocalDataBaseController <SKPaymentTransactionObserver, MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
           subscriptionProduct:(SKProduct *)subscriptionProduct;

@end
