//
//  UIFont+RAdditions.m
//  riker-ios
//
//  Created by PEVANS on 11/3/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "UIFont+RAdditions.h"
#import "PEUIUtils.h"

@implementation UIFont (RAdditions)

+ (UIFont *)rikerTitleFont {
  return [UIFont fontWithName:@"jr!hand"
                         size:[PEUIUtils valueIfiPhone5Width:82.0
                                                iphone6Width:90.0
                                            iphone6PlusWidth:98.0
                                                        ipad:132.0
                                                 ipadPro12in:142.0]];
}

@end
