//
//  RFaqScreen.h
//  riker-ios
//
//  Created by PEVANS on 8/23/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

@class PEUIToolkit;

@interface RFaqScreen : PEBaseController <UIWebViewDelegate>

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit;

@end
