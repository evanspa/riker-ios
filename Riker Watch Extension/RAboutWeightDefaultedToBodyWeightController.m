//
//  RAboutWeightDefaultedToBodyWeightController.m
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RAboutWeightDefaultedToBodyWeightController.h"
#import "NSString+RAdditions.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RWatchUtils.h"

@implementation RAboutWeightDefaultedToBodyWeightController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *vals = context;
  NSString *movementName = vals[@"movement-name"];
  NSDecimalNumber *bodyWeight = vals[@"body-weight"];
  NSString *bodyWeightUomName = vals[@"body-weight-uom-name"];
  NSDecimalNumber *percentage = vals[@"percentage"];
  NSDecimalNumber *weight = vals[@"weight"];
  NSDecimalNumber *weightUomName = vals[@"weight-uom-name"];
  [_label1 setText:[NSString stringWithFormat:@"%@ is a body-lift movement estimated to use %@%% of your body weight.", movementName.sentenceCase, [[percentage decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] description]]];
  [_label2 setText:[NSString stringWithFormat:@"Based on your most recent body log, your body weight is %@ %@.  Therefore we've defaulted the weight field to %@ %@.",
                    bodyWeight,
                    bodyWeightUomName,
                    weight,
                    weightUomName]];
}

- (IBAction)gotIt {
  [self dismissController];
}

- (IBAction)gotItAndDontShowAgain {
  [EXT setSuppressedWeightDefaultedToBodyWeightPopupAt:[NSDate date]];
  [EXT writeSettings];
  [self dismissController];
}

@end



