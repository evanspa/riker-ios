//
//  RExtensionDelegate.m
//  Riker Watch Extension
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RExtensionDelegate.h"
#import "RExtensionUtils.h"

NSString * const SETTINGS_JSON_FILE_NAME = @"riker-settings.json";
NSString * const SETTINGS_KEY_SUPPRESSED_WEIGHT_LBL_DEFAULTED_TO_BODY_WEIGHT_POPUP_AT = @"suppressed-body-weight-pop-up-at";
NSString * const SETTINGS_KEY_CAPTURE_NEGATIVES = @"capture-negatives";
NSString * const SETTINGS_KEY_LAST_SELECTED_MOVEMENT_ID = @"last-selected-movement-id";
NSString * const SETTINGS_KEY_LAST_SELECTED_MOVEMENT_NAME = @"last-selected-movement-name";
NSString * const SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_ID = @"last-selected-movement-variant-id";
NSString * const SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_NAME = @"last-selected-movement-variant-name";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_VISITED_AT = @"enter-reps-screen-last-visited-at";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_SET_NUMBER = @"enter-reps-screen-last-set-number";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_WEIGHT = @"enter-reps-screen-last-weight";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_REPS = @"enter-reps-screen-last-reps";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_TO_FAILURE = @"enter-reps-screen-last-to-failure";
NSString * const SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_NEGATIVES = @"enter-reps-screen-last-negatives";

@implementation RExtensionDelegate

#pragma mark - Helpers

- (BOOL)booleanSettingForKey:(NSString *)key {
  NSNumber *value = _settings[key];
  return [value boolValue];
}

- (NSDate *)dateSettingForKey:(NSString *)key {
  NSDecimalNumber *dateUnixTime = _settings[key];
  if (dateUnixTime) {
    return [NSDate dateWithTimeIntervalSince1970:dateUnixTime.doubleValue / 1000.0];
  }
  return nil;
}

- (void)raiseNotificationWithBodyText:(NSString *)bodyText {
  UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
  content.body = bodyText;
  UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
  UNNotificationRequest *request =
  [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                       content:content
                                       trigger:trigger];
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center addNotificationRequest:request withCompletionHandler:nil];
}

#pragma mark - User Notification Center Delegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
  completionHandler(UNNotificationPresentationOptionAlert);
}

#pragma mark - Watch Connectivity Delegate

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  NSNumber *action = userInfo[RWATCHMSG_ACTION_KEY];
  switch (action.integerValue) {
    case RWatchMsgActionEntitySaveAck: {
      NSDictionary *dataPayload = userInfo[RWATCHMSG_PAYLOAD_KEY];
      NSArray *lastPathComponentLocalEntityFiles = userInfo[RWATCHMSG_LOCAL_ENTITY_FILES_KEY];
      [RExtensionUtils persistPayload:dataPayload];
      [RExtensionUtils reloadComplications];
      for (NSInteger i = 0; i < lastPathComponentLocalEntityFiles.count; i++) {
        NSString *entityFile = [RExtensionUtils absolutePathOfDocumentsFileWithFilename:lastPathComponentLocalEntityFiles[i]];
        [[NSFileManager defaultManager] removeItemAtPath:entityFile error:nil];
      }
    }
      break;
    case RWatchMsgActionFetchAllIPhoneDataAck: {
      [RExtensionUtils persistPayload:userInfo[RWATCHMSG_PAYLOAD_KEY]];
      EXT.movementsAndSettings = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
      [RExtensionUtils reloadComplications];
      [self raiseNotificationWithBodyText:@"Movements, settings, workouts, sets and body logs have been synced from your iPhone."];  
    }
      break;
    case RWatchMsgActionPushAllIPhoneData: {
      NSDictionary *payloadDict = userInfo[RWATCHMSG_PAYLOAD_KEY];
      BOOL raiseNotification = ((NSNumber *)userInfo[RWATCHMSG_RAISE_NOTIFICATION_KEY]).boolValue;
      [RExtensionUtils persistPayload:payloadDict];
      EXT.movementsAndSettings = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
      [RExtensionUtils reloadComplications];
      if (raiseNotification) {
        [self raiseNotificationWithBodyText:@"Movements, settings, workouts, sets and body logs have been synced from your iPhone."];
      }
    }
      break;
  }
}

#pragma mark - Settings

- (void)setEnterRepsScreenLastSetNumber:(NSNumber *)setNumber { _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_SET_NUMBER] = setNumber; }
- (NSNumber *)enterRepsScreenLastSetNumber { return _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_SET_NUMBER]; }

- (void)setLastSelectedMovementId:(NSNumber *)movementId { _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_ID] = movementId; }
- (NSNumber *)lastSelectedMovementId { return _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_ID]; }

- (void)setLastSelectedMovementName:(NSString *)movementName { _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_NAME] = movementName; }
- (NSString *)lastSelectedMovementName { return _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_NAME]; }

- (void)setLastSelectedMovementVariantId:(NSNumber *)movementVariantId { _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_ID] = movementVariantId; }
- (NSNumber *)lastSelectedMovementVariantId { return _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_ID]; }

- (void)setLastSelectedMovementVariantName:(NSString *)movementVariantName { _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_NAME] = movementVariantName; }
- (NSString *)lastSelectedMovementVariantName { return _settings[SETTINGS_KEY_LAST_SELECTED_MOVEMENT_VARIANT_NAME]; }

- (void)setEnterRepsScreenLastVisitedAtTime:(NSNumber *)loggedAtTime { _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_VISITED_AT] = loggedAtTime; }
- (NSDate *)enterRepsScreenLastVisitedAt { return [self dateSettingForKey:SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_VISITED_AT]; }

- (void)setEnterRepsScreenLastWeight:(NSDecimalNumber *)weight { _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_WEIGHT] = weight; }

- (NSDecimalNumber *)enterRepsScreenLastWeight {
  NSNumber *weight = _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_WEIGHT];
  if (weight) {
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", weight]];
  }
  return nil;
}

- (void)setEnterRepsScreenLastReps:(NSNumber *)reps { _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_REPS] = reps; }
- (NSDecimalNumber *)enterRepsScreenLastReps {  
  NSNumber *reps = _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_REPS];
  if (reps) {
    return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", reps]];
  }
  return nil;
}

- (void)setEnterRepsScreenLastToFailure:(BOOL)toFailure {
  _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_TO_FAILURE] = @(toFailure);
}

- (BOOL)enterRepsScreenLastToFailure {
  NSNumber *toFailure = _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_TO_FAILURE];
  if (toFailure) {
    return [toFailure boolValue];
  }
  return NO;
}

- (void)setEnterRepsScreenLastNegatives:(BOOL)negatives {
  _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_NEGATIVES] = @(negatives);
}

- (BOOL)enterRepsScreenLastNegatives {
  NSNumber *negatives = _settings[SETTINGS_KEY_ENTER_REPS_SCREEN_LAST_NEGATIVES];
  if (negatives) {
    return [negatives boolValue];
  }
  return NO;
}

- (BOOL)captureNegatives { return [self booleanSettingForKey:SETTINGS_KEY_CAPTURE_NEGATIVES]; }
- (void)setCaptureNegatives:(BOOL)captureNegatives { _settings[SETTINGS_KEY_CAPTURE_NEGATIVES] = @(captureNegatives); }

- (NSDate *)suppressedWeightDefaultedToBodyWeightPopupAt {
  NSNumber *unixTime = _settings[SETTINGS_KEY_SUPPRESSED_WEIGHT_LBL_DEFAULTED_TO_BODY_WEIGHT_POPUP_AT];
  if (unixTime) {
    return [NSDate dateWithTimeIntervalSince1970:([unixTime doubleValue] / 1000.0)];
  }
  return nil;
}

- (void)setSuppressedWeightDefaultedToBodyWeightPopupAt:(NSDate *)date {
  _settings[SETTINGS_KEY_SUPPRESSED_WEIGHT_LBL_DEFAULTED_TO_BODY_WEIGHT_POPUP_AT] = @([date timeIntervalSince1970] * 1000.0);
}

- (void)writeSettings {
  [RExtensionUtils saveDictionary:_settings toDocumentsFolderWithFilename:SETTINGS_JSON_FILE_NAME];
}

- (NSArray *)movementVariants {
  NSMutableDictionary *movementVariantsByMovementId = EXT.movementsAndSettings[@"movement-variants"];
  return movementVariantsByMovementId[EXT.selectedMovementId.description];
}

#pragma mark - Lifecycle

- (void)applicationDidFinishLaunching {
  NSString *movementsAndSettingsAbsoluteFile =
  [RExtensionUtils absolutePathOfDocumentsFileWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:movementsAndSettingsAbsoluteFile]) {
    EXT.movementsAndSettings = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
  } else {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *url = [mainBundle URLForResource:@"initial-movements-and-settings" withExtension:@".json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSError *jsonError;
    EXT.movementsAndSettings = [NSMutableDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                             options:NSJSONReadingMutableContainers
                                                                                                               error:&jsonError]];
  }
  
  _settings = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:SETTINGS_JSON_FILE_NAME];
  if (!_settings) {
    _settings = [[NSMutableDictionary alloc] initWithCapacity:1];
    _settings[SETTINGS_KEY_CAPTURE_NEGATIVES] = @(NO);
    [self writeSettings];
  }
  WCSession *session = [WCSession defaultSession];
  session.delegate = self;
  [session activateSession];
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert)
                        completionHandler:^(BOOL granted, NSError * _Nullable error) {                          
                        }];
  center.delegate = self;
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
  [self setEnterRepsScreenLastSetNumber:@(EXT.setNumber)];
  [self writeSettings];
}

/*- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
  // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
  for (WKRefreshBackgroundTask * task in backgroundTasks) {
    // Check the Class of each task to decide how to process it
    if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
      // Be sure to complete the background task once you’re done.
      WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
      [backgroundTask setTaskCompleted];
    } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
      // Snapshot tasks have a unique completion call, make sure to set your expiration date
      WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
      [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
    } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
      // Be sure to complete the background task once you’re done.
      WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
      [backgroundTask setTaskCompleted];
    } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
      // Be sure to complete the background task once you’re done.
      WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
      [backgroundTask setTaskCompleted];
    } else {
      // make sure to complete unhandled task types
      [task setTaskCompleted];
    }
  }
}*/

@end
