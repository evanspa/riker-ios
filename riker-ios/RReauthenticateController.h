//
//  RReauthenticateController.h
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;

@interface RReauthenticateController : PELocalDataBaseController <MBProgressHUDDelegate, UITextFieldDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
