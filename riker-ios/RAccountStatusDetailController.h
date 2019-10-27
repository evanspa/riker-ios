//
//  RAccountStatusDetailController.h
//  riker-ios
//
//  Created by PEVANS on 12/31/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PELMUser;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;

@interface RAccountStatusDetailController : PELocalDataBaseController <MBProgressHUDDelegate, SKProductsRequestDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                    doneAction:(void(^)(PELMUser *))doneAction;

@end
