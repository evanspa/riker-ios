//
//  RCreateAccountController.h
//  riker-ios
//
//  Created by PEVANS on 10/30/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"
@import WatchConnectivity;

@protocol MBProgressHUDDelegate;
@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;

@interface RCreateAccountController : PELocalDataBaseController <MBProgressHUDDelegate,
UITextFieldDelegate,
WCSessionDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
