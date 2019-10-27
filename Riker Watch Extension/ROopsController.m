//
//  ROopsController.m
//  riker-ios
//
//  Created by PEVANS on 5/3/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "ROopsController.h"

@implementation ROopsController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  [_oopsMessageLabel setText:context];
}

- (IBAction)okay {
  [self dismissController];
}

@end



