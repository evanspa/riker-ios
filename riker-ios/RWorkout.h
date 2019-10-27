//
//  RWorkout.h
//  riker-ios
//
//  Created by PEVANS on 10/13/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RWorkout : NSObject

#pragma mark - Properties

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) NSInteger durationSeconds;
@property (nonatomic) NSDecimalNumber *caloriesBurned;
@property (nonatomic) NSArray *impactedMuscleGroupTuples;

@end
