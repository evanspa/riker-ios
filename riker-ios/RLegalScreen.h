//
//  RLegalScreen.h
//  riker-ios
//
//  Created by PEVANS on 2/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

@class PEUIToolkit;
@class RScreenToolkit;

@interface RLegalScreen : PEBaseController

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit
          screenToolkit:(RScreenToolkit *)screenToolkit;

@end
