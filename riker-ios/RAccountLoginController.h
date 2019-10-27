//
//  RAccountLoginController.h
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"
@import WatchConnectivity;

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;

@interface RAccountLoginController : PELocalDataBaseController <MBProgressHUDDelegate,
UITextFieldDelegate,
WCSessionDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
