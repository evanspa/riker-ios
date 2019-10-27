//
//  RWatchComplicationDataSource.m
//  riker-ios
//
//  Created by PEVANS on 6/6/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RWatchComplicationDataSource.h"
#import "RExtensionUtils.h"

@implementation RWatchComplicationDataSource

#pragma mark Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication
                                            withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
  handler(CLKComplicationTimeTravelDirectionBackward);
}

#pragma mark - Helpers

- (NSDate *)dateFromEntityDict:(NSDictionary *)entityDict key:(NSString *)key {
  return [NSDate dateWithTimeIntervalSince1970:((NSNumber *)entityDict[key]).doubleValue / 1000.0];
}

- (NSDate *)startDateForWorkout:(NSDictionary *)workout {
  return [self dateFromEntityDict:workout key:@"start-date-unix-time"];
}

- (NSDate *)loggedAtForSet:(NSDictionary *)set {
  return [self dateFromEntityDict:set key:@"logged-at-unix-time"];
}

- (CLKComplicationTimelineEntry *)utilitarianLargeTimelineEntryFromSet:(NSDictionary *)set {
  NSDate *loggedAt = [self loggedAtForSet:set];
  CLKComplicationTemplateUtilitarianLargeFlat *template = [[CLKComplicationTemplateUtilitarianLargeFlat alloc] init];
  template.textProvider = [CLKSimpleTextProvider textProviderWithText:set[@"movement"]];
  return [CLKComplicationTimelineEntry entryWithDate:loggedAt complicationTemplate:template];
}

- (CLKComplicationTimelineEntry *)modularLargeTimelineEntryFromWorkout:(NSDictionary *)workout {
  NSDate *workoutStartDate = [self startDateForWorkout:workout];
  CLKComplicationTemplateModularLargeStandardBody *template = [[CLKComplicationTemplateModularLargeStandardBody alloc] init];
  template.headerTextProvider = [CLKSimpleTextProvider textProviderWithText:@"Last Workout"];
  NSArray *muscleGroupTuples = workout[@"impacted-muscle-group-tuples"];
  NSArray *muscleGroupTuple = muscleGroupTuples[0];
  NSString *muscleGroupName = muscleGroupTuple[2];
  NSDecimalNumber *percentageOfTotal = muscleGroupTuple[1];
  template.body1TextProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ - %.f%%", muscleGroupName, percentageOfTotal.floatValue * 100.0]];
  if (muscleGroupTuples.count > 1) {
    muscleGroupTuple = muscleGroupTuples[1];
    muscleGroupName = muscleGroupTuple[2];
    percentageOfTotal = muscleGroupTuple[1];
    template.body2TextProvider = [CLKSimpleTextProvider textProviderWithText:[NSString stringWithFormat:@"%@ - %.f%%", muscleGroupName, percentageOfTotal.floatValue * 100.0]];
  }
  return [CLKComplicationTimelineEntry entryWithDate:workoutStartDate complicationTemplate:template];
}

- (void)timelineDateWithHandler:(void (^)(NSDate *date))handler
                   jsonFileName:(NSString *)jsonFileName
                    entitiesKey:(NSString *)entitiesKey
                        dateKey:(NSString *)dateKey
                  arraySelector:(SEL)arraySelector {
  NSDictionary *entitiesDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:jsonFileName];
  if (entitiesDict) {
    NSArray *entities = entitiesDict[entitiesKey];
    if (entities.count > 0) {
      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      NSDictionary *entityDict = [entities performSelector:arraySelector];
      #pragma clang diagnostic pop
      handler([self dateFromEntityDict:entityDict key:dateKey]);
    } else {
      handler(nil);
    }
  } else {
    handler(nil);
  }
}

#pragma mark - Timeline Population

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication
                                withHandler:(void (^)(NSDate *date))handler {
  switch (complication.family) {
    case CLKComplicationFamilyModularLarge:
      [self timelineDateWithHandler:handler jsonFileName:WORKOUTS_JSON_FILE_NAME entitiesKey:@"workouts" dateKey:@"start-date-unix-time" arraySelector:@selector(lastObject)];
      break;
    case CLKComplicationFamilyUtilitarianLarge:
      [self timelineDateWithHandler:handler jsonFileName:SETS_JSON_FILE_NAME entitiesKey:@"sets" dateKey:@"logged-at-unix-time" arraySelector:@selector(lastObject)];
      break;
    default:
      handler(nil);
      break;
  }
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication
                              withHandler:(void (^)(NSDate *date))handler {
  switch (complication.family) {
    case CLKComplicationFamilyModularLarge:
      [self timelineDateWithHandler:handler jsonFileName:WORKOUTS_JSON_FILE_NAME entitiesKey:@"workouts" dateKey:@"start-date-unix-time" arraySelector:@selector(firstObject)];
      break;
    case CLKComplicationFamilyUtilitarianLarge:
      [self timelineDateWithHandler:handler jsonFileName:SETS_JSON_FILE_NAME entitiesKey:@"sets" dateKey:@"logged-at-unix-time" arraySelector:@selector(firstObject)];
      break;
    default:
      handler(nil);
      break;
  }
}

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication
                                   withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
  void(^process)(NSString *, NSString *, CLKComplicationTimelineEntry *(^)(NSDictionary *)) =
  ^(NSString *jsonFileName, NSString *entitiesKey, CLKComplicationTimelineEntry *(^makeTimelineEntry)(NSDictionary *entityDict)) {
    NSDictionary *entitiesDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:jsonFileName];
    if (entitiesDict) {
      NSArray *entities = entitiesDict[entitiesKey];
      if (entities.count > 0) {
        handler(makeTimelineEntry([entities firstObject]));
      } else {
        handler(nil);
      }
    } else {
      handler(nil);
    }
  };
  switch (complication.family) {
    case CLKComplicationFamilyModularLarge: {
      process(WORKOUTS_JSON_FILE_NAME, @"workouts", ^(NSDictionary *entityDict) { return [self modularLargeTimelineEntryFromWorkout:entityDict]; });
      break;
    }
    case CLKComplicationFamilyUtilitarianLarge: {
      process(SETS_JSON_FILE_NAME, @"sets", ^(NSDictionary *entityDict) { return [self utilitarianLargeTimelineEntryFromSet:entityDict]; });
      break;
    }
    default:
      handler(nil);
      break;
  }
}

- (void)getTimelineAnimationBehaviorForComplication:(CLKComplication *)complication
                                        withHandler:(void (^)(CLKComplicationTimelineAnimationBehavior behavior))handler {
  handler(CLKComplicationTimelineAnimationBehaviorAlways);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication
                               beforeDate:(NSDate *)beforeDate
                                    limit:(NSUInteger)limit
                              withHandler:(void (^)(NSArray<CLKComplicationTimelineEntry *> *entries))handler {
  void(^process)(NSString *, NSString *, NSString *, CLKComplicationTimelineEntry *(^)(NSDictionary *)) =
  ^(NSString *jsonFileName, NSString *entitiesKey, NSString *dateKey, CLKComplicationTimelineEntry *(^makeTimelineEntry)(NSDictionary *entityDict)) {
    NSDictionary *entitiesDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:jsonFileName];
    if (entitiesDict) {
      NSArray *entities = entitiesDict[entitiesKey];
      NSMutableArray *entitiesForTimeline = [NSMutableArray array];
      NSInteger numAdded = 0;
      for (NSDictionary *entityDict in entities) {
        NSDate *date = [self dateFromEntityDict:entityDict key:dateKey];
        if ([date compare:beforeDate] == NSOrderedAscending) {
          if (numAdded < limit) {
            [entitiesForTimeline addObject:makeTimelineEntry(entityDict)];
            numAdded++;
          } else {
            break;
          }
        }
      }
      handler([[[entitiesForTimeline reverseObjectEnumerator] allObjects] mutableCopy]); // reverse it
    } else {
      handler(nil);
    }
  };
  switch (complication.family) {
    case CLKComplicationFamilyModularLarge: {
      process(WORKOUTS_JSON_FILE_NAME, @"workouts", @"start-date-unix-time", ^(NSDictionary *entityDict) { return [self modularLargeTimelineEntryFromWorkout:entityDict]; });
      break;
    }
    case CLKComplicationFamilyUtilitarianLarge: {
      process(SETS_JSON_FILE_NAME, @"sets", @"logged-at-unix-time", ^(NSDictionary *entityDict) { return [self utilitarianLargeTimelineEntryFromSet:entityDict]; });
      break;
    }
    default:
      handler(nil);
      break;
  }
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication
                                afterDate:(NSDate *)afterDate
                                    limit:(NSUInteger)limit
                              withHandler:(void (^)(NSArray<CLKComplicationTimelineEntry *> *entries))handler {
  handler(nil);
}

#pragma mark - Descriptions and Sample Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication
                                        withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler CLK_AVAILABLE_WATCHOS_IOS(3_0, 10_0) {
  switch(complication.family) {
    case CLKComplicationFamilyModularLarge: {
      CLKComplicationTemplateModularLargeStandardBody *template = [[CLKComplicationTemplateModularLargeStandardBody alloc] init];
      template.headerTextProvider = [CLKSimpleTextProvider textProviderWithText:@"Last Workout"];
      template.body1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"shoulders - 80%"];
      template.body2TextProvider = [CLKSimpleTextProvider textProviderWithText:@"triceps - 20%"];
      handler(template);
      break;
    }
    case CLKComplicationFamilyUtilitarianLarge: {
      CLKComplicationTemplateUtilitarianLargeFlat *template = [[CLKComplicationTemplateUtilitarianLargeFlat alloc] init];
      template.textProvider = [CLKSimpleTextProvider textProviderWithText:@"bench press"];
      handler(template);
      break;
    }
    default:
      handler(nil);
      break;
  }
}

@end
