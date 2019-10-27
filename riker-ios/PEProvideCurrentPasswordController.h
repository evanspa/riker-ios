//
//  PEProvideCurrentPasswordController.h
//  riker-ios
//
//  Created by PEVANS on 12/18/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PELocalDataBaseController.h"

@class PEUIToolkit;

@interface PEProvideCurrentPasswordController : PELocalDataBaseController <UITextFieldDelegate>

#pragma mark - Initializers

- (id)initWithActionOnDone:(void(^)(NSString *))actionOnDone
              cancelAction:(void(^)(void))cancelAction
                 uitoolkit:(PEUIToolkit *)uitoolkit;

@end
