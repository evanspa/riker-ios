//
//  RInfoScreen.h
//  riker-ios
//
//  Created by PEVANS on 12/21/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

@class PEUIToolkit;
@class RScreenToolkit;

@interface RInfoScreen : PEBaseController <UIScrollViewDelegate>

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
            heading:(NSString *)heading
           sections:(NSArray *)sections
          uitoolkit:(PEUIToolkit *)uitoolkit
      screenToolkit:(RScreenToolkit *)screenToolkit
     viewDidLoadBlk:(void(^)(void))viewDidLoadBlk;

@end
