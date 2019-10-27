//
//  RWorkoutsController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RWorkoutsController.h"
#import "RExtensionUtils.h"
#import "RWorkoutsRowController.h"

@implementation RWorkoutsController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *workoutsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:WORKOUTS_JSON_FILE_NAME];
  if (workoutsDict) {
    NSArray *workouts = workoutsDict[@"workouts"];
    NSInteger numWorkouts = workouts.count;
    NSDateFormatter *dateFormatter = [RExtensionUtils dateFormatter];
    NSDateFormatter *dayOfWeekFormatter = [RExtensionUtils dayOfWeekFormatter];
    [self.workoutsTable setNumberOfRows:numWorkouts withRowType:@"WorkoutRow"];
    if (numWorkouts > 0) {
       [_noWorkoutsFoundGroup setHidden:YES];
    }
    for (NSInteger i = 0; i < numWorkouts; i++) {
      RWorkoutsRowController *rowController = [self.workoutsTable rowControllerAtIndex:i];
      NSDictionary *workout = workouts[i];
      NSDate *startDate = [RExtensionUtils dateFromDict:workout key:@"start-date-unix-time"];
      [rowController.dateLabel setText:[dateFormatter stringFromDate:startDate]];
      [rowController.dayOfWeekLabel setText:[dayOfWeekFormatter stringFromDate:startDate]];
      [rowController.durationLabel setText:workout[@"duration-formatted"]];
      [rowController.caloriesLabel setText:workout[@"calories-burned-formatted"]];      
      NSArray *muscleGroupTuples = workout[@"impacted-muscle-group-tuples"];
      [self bindMuscleGroupTuple:muscleGroupTuples[0] toLabel:rowController.muscleGroup1];
      if (muscleGroupTuples.count > 1) {
        [self bindMuscleGroupTuple:muscleGroupTuples[1] toLabel:rowController.muscleGroup2];
        if (muscleGroupTuples.count > 2) {
          [self bindMuscleGroupTuple:muscleGroupTuples[2] toLabel:rowController.muscleGroup3];
          if (muscleGroupTuples.count > 3) {
              [self bindMuscleGroupTuple:muscleGroupTuples[3] toLabel:rowController.muscleGroup4];
          } else {
              [rowController.muscleGroup4 setHidden:YES];
          }
        } else {
          [rowController.muscleGroup3 setHeight:YES];
          [rowController.muscleGroup4 setHidden:YES];
        }
      } else {
        [rowController.muscleGroup2 setHidden:YES];
        [rowController.muscleGroup3 setHidden:YES];
        [rowController.muscleGroup4 setHidden:YES];
      }
    }
  }
}

- (void)bindMuscleGroupTuple:(NSArray *)muscleGroupTuple toLabel:(WKInterfaceLabel *)label {
  NSString *muscleGroupName = muscleGroupTuple[2];
  NSDecimalNumber *percentageOfTotal = muscleGroupTuple[1];
  [label setText:[NSString stringWithFormat:@"%@ - %.f%%", muscleGroupName, percentageOfTotal.floatValue * 100.0]];
}

@end
