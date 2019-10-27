//
//  RSelectMuscleGroupController.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectMuscleGroupController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RSelectEntityRowController.h"

@implementation RSelectMuscleGroupController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSArray *muscleGroups = [self muscleGroups];
  NSInteger numMuscleGroups = muscleGroups.count;
  [self.muscleGroupsTable setNumberOfRows:numMuscleGroups withRowType:@"MuscleGroupRow"];
  for (NSInteger i = 0; i < numMuscleGroups; i++) {
    RSelectEntityRowController *rowController = [self.muscleGroupsTable rowControllerAtIndex:i];
    NSDictionary *muscleGroup = muscleGroups[i];
    [rowController.label setText:muscleGroup[@"name"]];
  }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *muscleGroups = [self muscleGroups];
  EXT.selectedMuscleGroupId = muscleGroups[rowIndex][@"id"];
  [self pushControllerWithName:@"SelectMovement" context:nil];
}

- (NSArray *)muscleGroups {
  NSDictionary *muscleGroupsByBodySegmentId = EXT.movementsAndSettings[@"muscle-groups"];
  return muscleGroupsByBodySegmentId[EXT.selectedBodySegmentId.description];
}

@end



