//
//  RChangeLog.h
//  riker-ios
//
//  Created by PEVANS on 10/21/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEChangelog.h"

@class RUserSettings;
@class RSet;
@class RBodyMeasurementLog;

@class RBodySegment;
@class RMuscleGroup;
@class RMuscle;
@class RMuscleAlias;
@class RMovement;
@class RMovementAlias;
@class RMovementVariant;
@class ROriginationDevice;

@interface RChangeLog : PEChangelog

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt;

#pragma mark - User Data

- (void)setUserSettings:(RUserSettings *)userSettings;
- (RUserSettings *)userSettings;

- (void)addSet:(RSet *)set;
- (NSArray *)sets;

- (void)addBodyMeasurementLog:(RBodyMeasurementLog *)bodyMeasurementLog;
- (NSArray *)bodyMeasurementLogs;

#pragma mark - Ref Data

- (void)addBodySegment:(RBodySegment *)bodySegment;
- (NSArray *)bodySegments;

- (void)addMuscleGroup:(RMuscleGroup *)muscleGroup;
- (NSArray *)muscleGroups;

- (void)addMuscle:(RMuscle *)muscle;
- (NSArray *)muscles;

- (void)addMuscleAlias:(RMuscleAlias *)muscleAlias;
- (NSArray *)muscleAliases;

- (void)addMovement:(RMovement *)movement;
- (NSArray *)movements;

- (void)addMovementAlias:(RMovementAlias *)movementAlias;
- (NSArray *)movementAliases;

- (void)addMovementVariant:(RMovementVariant *)movementVariant;
- (NSArray *)movementVariants;

- (void)addOriginationDevice:(ROriginationDevice *)originationDevice;
- (NSArray *)originationDevices;

@end
