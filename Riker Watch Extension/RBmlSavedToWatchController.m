//
//  RBmlSavedToWatchController.m
//  riker-ios
//
//  Created by PEVANS on 5/9/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RBmlSavedToWatchController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"

@implementation RBmlSavedToWatchController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    EXT.canDismissEnterBmlScreen = YES;
    [self dismissController];
  });
}

@end



