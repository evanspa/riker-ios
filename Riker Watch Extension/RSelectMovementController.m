//
//  RSelectMovementController.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectMovementController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RSelectEntityRowController.h"

@implementation RSelectMovementController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSArray *movements = [self movements];
  NSInteger numMovements = movements.count;
  [self.movementsTable setNumberOfRows:numMovements withRowType:@"MovementRow"];
  for (NSInteger i = 0; i < numMovements; i++) {
    RSelectEntityRowController *rowController = [self.movementsTable rowControllerAtIndex:i];
    NSDictionary *movement = movements[i];
    [rowController.label setText:movement[@"name"]];
    
    //[rowController.group setHeight:]
   
    //NSLog(@"%@ label height: [%f], group: [%f]", movement[@"name"], rowController.group.
    
    //[rowController.group sizeToFitHeight];
  }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *movements = [self movements];
  NSDictionary *movement = movements[rowIndex];
  EXT.selectedMovementId = movement[@"id"];
  EXT.selectedMovementName = movement[@"name"];
  EXT.selectedMovementIsBodyLift = [(NSNumber *)movement[@"is-body-lift"] boolValue];
  EXT.selectedMovementPercentageOfBodyWeight = movement[@"percentage-of-body-weight"];
  EXT.selectedMovementVariantId = nil;
  EXT.selectedMovementVariantName = nil;
  NSNumber *numVariants = movement[@"variant-count"];
  NSString *nextController;
  if (numVariants.integerValue > 1) {
    nextController = @"SelectMovementVariant";
  } else if (numVariants.integerValue > 0) {
    NSDictionary *movementVariant = [EXT movementVariants][0];
    EXT.selectedMovementVariantId = movementVariant[@"id"];
    EXT.selectedMovementVariantName = movementVariant[@"name"];
    nextController = @"EnterReps";
  } else {
    nextController = @"EnterReps";
  }
  [self pushControllerWithName:nextController context:nil];
}

- (NSArray *)movements {
  NSDictionary *movementsByMuscleGroupId = EXT.movementsAndSettings[@"movements"];
  return movementsByMuscleGroupId[EXT.selectedMuscleGroupId.description];
}

@end
