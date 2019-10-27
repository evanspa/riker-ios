//
//  RChangeLog.m
//  riker-ios
//
//  Created by PEVANS on 10/21/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RChangeLog.h"

#import "RUserSettings.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"

#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMuscleAlias.h"
#import "RMovement.h"
#import "RMovementAlias.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"

@implementation RChangeLog {
  RUserSettings *_userSettings;
  NSMutableArray *_sets;
  NSMutableArray *_bodyMeasurementLogs;
  
  NSMutableArray *_bodySegments;
  NSMutableArray *_muscleGroups;
  NSMutableArray *_muscles;
  NSMutableArray *_muscleAliases;
  NSMutableArray *_movements;
  NSMutableArray *_movementAliases;
  NSMutableArray *_movementVariants;
  NSMutableArray *_originationDevices;
}

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt {
  self = [super initWithUpdatedAt:updatedAt];
  if (self) {
    _sets = [NSMutableArray array];
    _bodyMeasurementLogs = [NSMutableArray array];
    
    _bodySegments = [NSMutableArray array];
    _muscleGroups = [NSMutableArray array];
    _muscles = [NSMutableArray array];
    _muscleAliases = [NSMutableArray array];
    _movements = [NSMutableArray array];
    _movementAliases = [NSMutableArray array];
    _movementVariants = [NSMutableArray array];
    _originationDevices = [NSMutableArray array];
  }
  return self;
}

#pragma mark - User Data

- (void)setUserSettings:(RUserSettings *)userSettings {
  _userSettings = userSettings;
}

- (RUserSettings *)userSettings {
  return _userSettings;
}

- (void)addSet:(RSet *)set {
  [_sets addObject:set];
}

- (NSArray *)sets {
  return _sets;
}

- (void)addBodyMeasurementLog:(RBodyMeasurementLog *)bodyMeasurementLog {
  [_bodyMeasurementLogs addObject:bodyMeasurementLog];
}

- (NSArray *)bodyMeasurementLogs {
  return _bodyMeasurementLogs;
}

#pragma mark - Ref Data

- (void)addBodySegment:(RBodySegment *)bodySegment {
  [_bodySegments addObject:bodySegment];
}

- (NSArray *)bodySegments {
  return _bodySegments;
}

- (void)addMuscleGroup:(RMuscleGroup *)muscleGroup {
  [_muscleGroups addObject:muscleGroup];
}

- (NSArray *)muscleGroups {
  return _muscleGroups;
}

- (void)addMuscle:(RMuscle *)muscle {
  [_muscles addObject:muscle];
}

- (NSArray *)muscles {
  return _muscles;
}

- (void)addMuscleAlias:(RMuscleAlias *)muscleAlias {
  [_muscleAliases addObject:muscleAlias];
}

- (NSArray *)muscleAliases {
  return _muscleAliases;
}

- (void)addMovement:(RMovement *)movement {
  [_movements addObject:movement];
}

- (NSArray *)movements {
  return _movements;
}

- (void)addMovementAlias:(RMovementAlias *)movementAlias {
  [_movementAliases addObject:movementAlias];
}

- (NSArray *)movementAliases {
  return _movementAliases;
}

- (void)addMovementVariant:(RMovementVariant *)movementVariant {
  [_movementVariants addObject:movementVariant];
}

- (NSArray *)movementVariants {
  return _movementVariants;
}

- (void)addOriginationDevice:(ROriginationDevice *)originationDevice {
  [_originationDevices addObject:originationDevice];
}

- (NSArray *)originationDevices {
  return _originationDevices;
}

@end
