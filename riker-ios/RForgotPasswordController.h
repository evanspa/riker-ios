//
//  RForgotPasswordController.h
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PELMUser;
@class PEUIToolkit;

@interface RForgotPasswordController : PELocalDataBaseController <MBProgressHUDDelegate, UITextFieldDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                          user:(PELMUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit;

@end
