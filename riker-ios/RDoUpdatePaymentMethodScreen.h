//
//  RDoUpdatePaymentMethodScreen.h
//  riker-ios
//
//  Created by PEVANS on 1/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIkit.h>
#import <Stripe/Stripe.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;

@interface RDoUpdatePaymentMethodScreen : PELocalDataBaseController <MBProgressHUDDelegate, STPAddCardViewControllerDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
