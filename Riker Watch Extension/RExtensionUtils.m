//
//  RExtensionUtils.m
//  riker-ios
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import "RExtensionUtils.h"
#import "RWatchUtils.h"

NSString * const MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME = @"movements-and-settings.json";
NSString * const WORKOUTS_JSON_FILE_NAME = @"workouts.json";
NSString * const SETS_JSON_FILE_NAME = @"sets.json";
NSString * const BMLS_JSON_FILE_NAME = @"bmls.json";

@implementation RExtensionUtils

+ (void)setTextOrHideLabel:(WKInterfaceLabel *)label
                      text:(NSString *)text {
  if (text) {
    [label setHidden:NO];
    [label setText:text];
  } else {
    [label setHidden:YES];
  }
}

+ (void)persistIPhoneEntities:(NSDictionary *)entities
         entitiesJsonFileName:(NSString *)entitiesJsonFileName
             entitiesArrayKey:(NSString *)arrayKey {
  NSDictionary *entitiesDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:entitiesJsonFileName];
  NSMutableArray *currentEntities = [NSMutableArray arrayWithArray:entitiesDict[arrayKey]];
  // remove current iPhone entities
  NSInteger numCurrentEntities = currentEntities.count;
  for (NSInteger i = numCurrentEntities - 1; i >= 0; i--) {
    NSDictionary *entity = currentEntities[i];
    NSNumber *syncedToIPhone = entity[@"synced-to-iphone"];
    if (syncedToIPhone && syncedToIPhone.boolValue) {
      [currentEntities removeObjectAtIndex:i];
    } else {
      // if a current entity has this field, and here we are processing a new
      // payload from the iPhone, then, contained in the payload would be the
      // now-synced version of the entity, so yeah, we can remove these local
      // 'sync-requested' entities too.
      NSNumber *syncRequested = entity[@"sync-requested"];
      if (syncRequested && syncRequested.boolValue) {
        [currentEntities removeObjectAtIndex:i];
      }
    }
  }
  NSArray *payloadEntities = entities[arrayKey];
  NSMutableArray *newEntities = [NSMutableArray arrayWithArray:currentEntities];
  for (NSDictionary *entity in payloadEntities) {
    [newEntities addObject:entity];
  }
  [newEntities sortUsingComparator:^NSComparisonResult(NSDictionary *entity1, NSDictionary *entity2) {
    NSNumber *loggedAtUnixTime1 = entity1[@"logged-at-unix-time"];
    NSNumber *loggedAtUnixTime2 = entity2[@"logged-at-unix-time"];
    return [loggedAtUnixTime2 compare:loggedAtUnixTime1];
  }];
  [RExtensionUtils pruneOldestIfTooManyEntities:newEntities];
  [RExtensionUtils saveDictionary:@{ arrayKey: newEntities }
    toDocumentsFolderWithFilename:entitiesJsonFileName];
}

+ (void)persistPayload:(NSDictionary *)payload {
  NSDictionary *movsAndSettings = payload[@"movements-and-settings-container"];
  NSDictionary *workouts = payload[@"workouts-container"];
  NSDictionary *sets = payload[@"sets-container"];
  NSDictionary *bmls = payload[@"bmls-container"];
  if (movsAndSettings) {
    [RExtensionUtils saveDictionary:movsAndSettings
      toDocumentsFolderWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
  }
  if (workouts) {
    [RExtensionUtils saveDictionary:workouts
      toDocumentsFolderWithFilename:WORKOUTS_JSON_FILE_NAME];
  }
  if (sets) {
    [RExtensionUtils persistIPhoneEntities:sets entitiesJsonFileName:SETS_JSON_FILE_NAME entitiesArrayKey:@"sets"];
  }
  if (bmls) {
    [RExtensionUtils persistIPhoneEntities:bmls entitiesJsonFileName:BMLS_JSON_FILE_NAME entitiesArrayKey:@"bmls"];
  }
}

+ (NSNumber *)unixTimeFromDate:(NSDate *)date {
  NSDecimalNumber *dateNum = [[NSDecimalNumber alloc] initWithDouble:date.timeIntervalSince1970];
  dateNum = [dateNum decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:1000]];
  dateNum = [dateNum decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                                       scale:0
                                                                                                            raiseOnExactness:NO
                                                                                                             raiseOnOverflow:NO
                                                                                                            raiseOnUnderflow:NO                                                                                                         raiseOnDivideByZero:NO]];
  return dateNum;
}

+ (BOOL)deleteEntity:(NSDictionary *)entityDict
         entityIndex:(NSInteger)entityIndex
    entitiesFileName:(NSString *)entitiesFileName
         entitiesKey:(NSString *)entitiesKey {
  NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *absoluteFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, entityDict[@"file-name"]];
  BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath:absoluteFilePath error:nil];
  if (removeSuccess) {
    NSDictionary *setsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:entitiesFileName];
    NSArray *entities = setsDict[entitiesKey];
    NSMutableArray *mutableEntities = [NSMutableArray arrayWithArray:entities];
    [mutableEntities removeObjectAtIndex:entityIndex];
    [RExtensionUtils saveDictionary:@{ entitiesKey: mutableEntities } toDocumentsFolderWithFilename:entitiesFileName];
  }
  return removeSuccess;
}

+ (NSNumberFormatter *)weightNumberFormatter {
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.numberStyle = NSNumberFormatterDecimalStyle;
  formatter.maximumFractionDigits = 1;
  formatter.roundingMode = NSNumberFormatterRoundHalfUp;
  return formatter;
}

+ (NSDateFormatter *)dateFormatterWithPattern:(NSString *)pattern {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:pattern];
  return dateFormatter;
}

+ (NSDateFormatter *)dayOfWeekFormatter {
  return [RExtensionUtils dateFormatterWithPattern:@"EEEE"];
}

+ (NSDateFormatter *)dateTimeFormatter {
  return [RExtensionUtils dateFormatterWithPattern:@"MM/dd/yyyy h:mm:ss a"];
}

+ (NSDateFormatter *)dateFormatter {
  return [RExtensionUtils dateFormatterWithPattern:@"MM/dd/yyyy"];
}

+ (NSDate *)dateFromDict:(NSDictionary *)dictionary key:(NSString *)key {
  return [NSDate dateWithTimeIntervalSince1970:((NSNumber *)dictionary[key]).doubleValue / 1000.0];
}

+ (NSString *)absolutePathOfDocumentsFileWithFilename:(NSString *)filename {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentDirectory = [paths objectAtIndex:0];
  return [documentDirectory stringByAppendingPathComponent:filename];
}

+ (NSMutableDictionary *)dictionaryFromDocumentsFolderWithFilename:(NSString *)filename {
  return [RExtensionUtils dictionaryFromAbsoluteFilePath:[RExtensionUtils absolutePathOfDocumentsFileWithFilename:filename]];
}

+ (NSMutableDictionary *)dictionaryFromAbsoluteFilePath:(NSString *)filepath {
  NSString *jsonString = [[NSString alloc] initWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:NULL];
  NSError *jsonError;
  if (jsonString) {
    return [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                                         options:NSJSONReadingMutableContainers
                                                                                           error:&jsonError]];
  }
  return nil;
}

+ (void)saveDictionary:(NSDictionary *)dictionary toDocumentsFolderWithFilename:(NSString *)filename {
  NSString *finalPath = [RExtensionUtils absolutePathOfDocumentsFileWithFilename:filename];
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  [jsonString writeToFile:finalPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString *)saveToWatchEntity:(NSMutableDictionary *)entity entityType:(NSString *)entityType {
  NSDate *loggedAt = entity[@"logged-at"];
  NSNumber *loggedAtTime = [RExtensionUtils unixTimeFromDate:loggedAt];
  entity[@"logged-at"] = loggedAtTime; // needs to be number to save to json
  NSString *fileName = [NSString stringWithFormat: @"%@.riker.%@.json", loggedAtTime, entityType];
  [RExtensionUtils saveDictionary:entity toDocumentsFolderWithFilename:fileName];
  entity[@"logged-at"] = loggedAt; // revert back to date object
  return fileName;
}

+ (void)reloadComplications {
  CLKComplicationServer *complicationServer = [CLKComplicationServer sharedInstance];
  for (CLKComplication *complication in complicationServer.activeComplications) {
    [complicationServer reloadTimelineForComplication:complication];
  }
}

+ (void)extendComplications {
  CLKComplicationServer *complicationServer = [CLKComplicationServer sharedInstance];
  for (CLKComplication *complication in complicationServer.activeComplications) {
    [complicationServer extendTimelineForComplication:complication];
  }
}

+ (void)pruneOldestIfTooManyEntities:(NSMutableArray *)entities {
  while (entities.count > MAX_RECENT_ENTITIES) {
    [entities removeLastObject];
  }
}

+ (void)extendSetsTimelineWithLoggedAt:(NSDate *)loggedAt
                          movementName:(NSString *)movementName
                   movementVariantName:(NSString *)movementVariantName
                               numReps:(NSInteger)numReps
                                weight:(NSDecimalNumber *)weight
                         weightUomName:(NSString *)weightUomName
                             toFailure:(BOOL)toFailure
                             negatives:(BOOL)negatives
                              fileName:(NSString *)fileName {
  NSDictionary *setsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:SETS_JSON_FILE_NAME];
  NSArray *currentSets = setsDict[@"sets"];
  NSMutableArray *newSets = [NSMutableArray arrayWithArray:currentSets];
  NSMutableDictionary *setDict = [NSMutableDictionary dictionary];
  setDict[@"logged-at-unix-time"] = [RExtensionUtils unixTimeFromDate:loggedAt];
  setDict[@"movement"] = movementName;
  if (movementVariantName) {
    setDict[@"movement-variant"] = movementVariantName;
  }
  setDict[@"file-name"] = fileName;
  setDict[@"reps-and-weight-desc"] = [NSString stringWithFormat:@"%d rep%@ of %@ %@",
                                      numReps,
                                      numReps > 1 ? @"s" : @"",
                                      weight,
                                      weightUomName];
  setDict[@"to-failure-desc"] = [NSString stringWithFormat:@"To failure? %@", toFailure ? @"Yes" : @"No"];
  setDict[@"negatives-desc"] = [NSString stringWithFormat:@"Negatives? %@", negatives ? @"Yes" : @"No"];
  [newSets insertObject:setDict atIndex:0];
  [RExtensionUtils pruneOldestIfTooManyEntities:newSets];
  [RExtensionUtils saveDictionary:@{ @"sets": newSets } toDocumentsFolderWithFilename:SETS_JSON_FILE_NAME];
  [RExtensionUtils reloadComplications];
}

+ (void)extendBmlsWithLoggedAt:(NSDate *)loggedAt
                       bmlType:(RBmlType)bmlType
                         title:(NSString *)title
                         value:(NSDecimalNumber *)value
                      uomLabel:(NSString *)uomLabel
                      fileName:(NSString *)fileName {
  NSDictionary *bmlsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:BMLS_JSON_FILE_NAME];
  NSArray *currentBmls = bmlsDict[@"bmls"];
  NSMutableArray *newBmls = [NSMutableArray arrayWithArray:currentBmls];
  NSMutableDictionary *bmlDict = [NSMutableDictionary dictionary];
  bmlDict[@"logged-at-unix-time"] = [RExtensionUtils unixTimeFromDate:loggedAt];
  bmlDict[@"bml-type"] = title;  
  NSNumberFormatter *decimalFormatter = [RExtensionUtils weightNumberFormatter];
  NSString *valueStr = [decimalFormatter stringFromNumber:value];
  bmlDict[@"value"] = valueStr;
  switch (bmlType) {
    case RBmlTypeArms:
      bmlDict[@"arm-size"] = [NSMutableString stringWithFormat:@"Arms: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeNeck:
      bmlDict[@"neck-size"] = [NSMutableString stringWithFormat:@"Neck: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeChest:
      bmlDict[@"chest-size"] = [NSMutableString stringWithFormat:@"Chest: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeWaist:
      bmlDict[@"waist-size"] = [NSMutableString stringWithFormat:@"Waist: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeCalves:
      bmlDict[@"calf-size"] = [NSMutableString stringWithFormat:@"Calfs: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeThighs:
      bmlDict[@"thigh-size"] = [NSMutableString stringWithFormat:@"Thighs: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeForearms:
      bmlDict[@"forearm-size"] = [NSMutableString stringWithFormat:@"Forearms: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeBodyWeight:
      bmlDict[@"body-weight"] = [NSMutableString stringWithFormat:@"Body weight: %@ %@", valueStr, uomLabel];
      break;
    case RBmlTypeSeveral: // not applicable here
      break;
  }
  bmlDict[@"file-name"] = fileName;
  [newBmls insertObject:bmlDict atIndex:0];
  [RExtensionUtils pruneOldestIfTooManyEntities:newBmls];
  [RExtensionUtils saveDictionary:@{ @"bmls": newBmls } toDocumentsFolderWithFilename:BMLS_JSON_FILE_NAME];
}

@end
