//
//  RSelectWhatToMeasureController.m
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectWhatToMeasureController.h"
#import "RWatchUtils.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RWatchUtils.h"

@implementation RSelectWhatToMeasureController

- (IBAction)bodyWeight {
  [self pushControllerWithName:@"EnterBml"
                       context:@{@"bml-type": @(RBmlTypeBodyWeight),
                                 @"uom-name": EXT.movementsAndSettings[@"weight-uom-name"],
                                 @"uom-id": EXT.movementsAndSettings[@"weight-uom-id"],
                                 @"num-fraction-digits": @(1),
                                 @"rotational-scaling-factor": @(5),
                                 @"title": @"Body Weight",
                                 @"bml-type-key": @"body-weight",
                                 @"default-value": @"150.0"}];
}

- (void)pushEnterSizeControllerWithBmlType:(RBmlType)bmlType title:(NSString *)title bmlTypeKey:(NSString *)bmlTypeKey {
  [self pushControllerWithName:@"EnterBml"
                       context:@{@"bml-type": @(bmlType),
                                 @"uom-name": EXT.movementsAndSettings[@"size-uom-name"],
                                 @"uom-id": EXT.movementsAndSettings[@"size-uom-id"],
                                 @"num-fraction-digits": @(1),
                                 @"rotational-scaling-factor": @(5),
                                 @"title": title,
                                 @"bml-type-key": bmlTypeKey}];
}

- (IBAction)arms {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeArms title:@"Arm Size" bmlTypeKey:@"arm-size"];
}

- (IBAction)chest {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeChest title:@"Chest Size" bmlTypeKey:@"chest-size"];
}

- (IBAction)calves {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeCalves title:@"Calf Size" bmlTypeKey:@"calf-size"];
}

- (IBAction)thighs {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeThighs title:@"Thigh Size" bmlTypeKey:@"thigh-size"];
}

- (IBAction)forearms {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeForearms title:@"Forearm Size" bmlTypeKey:@"forearm-size"];
}

- (IBAction)waist {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeWaist title:@"Waist Size" bmlTypeKey:@"waist-size"];
}

- (IBAction)neck {
  [self pushEnterSizeControllerWithBmlType:RBmlTypeNeck title:@"Neck Size" bmlTypeKey:@"neck-size"];
}

@end



