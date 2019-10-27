//
//  RSetSavedToWatchController.m
//  riker-ios
//
//  Created by PEVANS on 5/5/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSetSavedToWatchController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RWatchUtils.h"

@implementation RSetSavedToWatchController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  EXT.setNumber++;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self dismissController];
  });
}

@end



