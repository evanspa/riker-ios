//
//  RMainMenuController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RMainMenuController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "UIColor+RAdditions.h"
#import "RWatchUtils.h"

@implementation RMainMenuController {
  NSMutableArray *_setFiles;
  NSMutableArray *_bmlFiles;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  _setFiles = [NSMutableArray array];
  _bmlFiles = [NSMutableArray array];
}

- (NSDictionary *)rikerEntityInAbsoluteFile:(NSString *)absoluteFilePath
                                 fileSuffix:(NSString *)fileSuffix
                                  oldSuffix:(NSString *)oldSuffix
                                requiredKey:(NSString *)requiredKey {
  if ([absoluteFilePath hasSuffix:fileSuffix] || [absoluteFilePath hasSuffix:oldSuffix]) {
    NSMutableDictionary *entity = [RExtensionUtils dictionaryFromAbsoluteFilePath:absoluteFilePath];
    if ([entity objectForKey:requiredKey] != nil) {
      return entity;
    }
  }
  return nil;
}

- (void)didAppear {
  [super didAppear];
  EXT.deletedSetIndex = nil;
  EXT.deletedBmlIndex = nil;
  [_syncSetsButton setBackgroundColor:[UIColor rikerAppBlack]];
  [_syncSetsButton setEnabled:NO];
  [_syncBmlsButton setBackgroundColor:[UIColor rikerAppBlack]];
  [_syncBmlsButton setEnabled:NO];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    WCSession *session = [WCSession defaultSession];
    session.delegate = EXT; // re-assign back to extension delegate
    NSString *documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    [_setFiles removeAllObjects];
    [_bmlFiles removeAllObjects];
    void (^addIfSyncNotRequested)(NSMutableArray *, NSString *, NSString *, NSString *, NSString *) = ^(NSMutableArray *entities, NSString *absoluteFilePath, NSString *fileSuffix, NSString *oldFileSuffix, NSString *requiredKey) {
      NSDictionary *entity = [self rikerEntityInAbsoluteFile:absoluteFilePath
                                                  fileSuffix:fileSuffix
                                                   oldSuffix:oldFileSuffix
                                                 requiredKey:requiredKey];
      if (entity != nil) {
        NSNumber *syncRequested = entity[@"sync-requested"];
        if (syncRequested == nil || !syncRequested.boolValue) {
          [entities addObject:absoluteFilePath];
        } else {
          // okay, so lets see how old this file is...and if it is at least 90 days old,
          // we'll just go ahead and delete it...see, with early versions of riker, there was a
          // flaw with how deletions occured, so it's possible that synced records have never
          // been deleted from watch...this code below will ensure eventual cleanup of those
          // files...
          NSArray<NSString *> *components = [absoluteFilePath.lastPathComponent componentsSeparatedByString:@"."];
          if (components.count > 0) {
            NSString *unixTimeStr = components[0];
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            NSNumber *unixTime = [numberFormatter numberFromString:unixTimeStr];
            if (unixTime) {
              NSDate *date = [NSDate dateWithTimeIntervalSince1970:(unixTime).doubleValue / 1000.0];
              NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:date];
              int numberOfDaysAgo = secondsBetween / 86400;
              if (numberOfDaysAgo >= 90) {
                [[NSFileManager defaultManager] removeItemAtPath:absoluteFilePath error:nil];
              }
            }
          }
        }
      }
    };
    for (NSString *file in files) {
      NSString *absoluteFilePath = [NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, file];
      addIfSyncNotRequested(_setFiles, absoluteFilePath, @".riker.set.json", @".set.json", @"to-failure");
      addIfSyncNotRequested(_bmlFiles, absoluteFilePath, @".riker.bml.json", @".bml.json", @"logged-at");
    }
    EXT.numPendingSets = _setFiles.count;
    dispatch_async(dispatch_get_main_queue(), ^{
      if (_setFiles.count > 0) {
        [_syncSetsButton setTitle:[NSString stringWithFormat:@"%ld Set%@ to Sync", (long)_setFiles.count, _setFiles.count > 1 ? @"s" : @""]];
        [_syncSetsButton setBackgroundColor:[UIColor orangeColor]];
        [_syncSetsButton setEnabled:YES];
      } else {
        [_syncSetsButton setTitle:@"No Sets to Sync"];
        [_syncSetsButton setBackgroundColor:[UIColor rikerAppBlack]];
        [_syncSetsButton setEnabled:NO];
      }
      if (_bmlFiles.count > 0) {
        [_syncBmlsButton setTitle:[NSString stringWithFormat:@"%ld Body Log%@ to Sync", (long)_bmlFiles.count, _bmlFiles.count > 1 ? @"s" : @""]];
        [_syncBmlsButton setBackgroundColor:[UIColor orangeColor]];
        [_syncBmlsButton setEnabled:YES];
      } else {
        [_syncBmlsButton setTitle:@"No Body Logs to Sync"];
        [_syncBmlsButton setBackgroundColor:[UIColor rikerAppBlack]];
        [_syncBmlsButton setEnabled:NO];
      }
    });
  });
}

#pragma mark - Button Actions

- (IBAction)strengthTrainButtonAction {
  [self pushControllerWithName:@"SelectBodySegment" context:nil];
}

- (IBAction)logBodyMeasurement {
  [self pushControllerWithName:@"SelectWhatToMeasure" context:nil];
}

- (IBAction)syncSets {
  [self presentControllerWithName:@"EntitySyncer" context:@{@"entity-type": @"set",
                                                            @"entity-files": _setFiles,
                                                            @"entities-json-filename": SETS_JSON_FILE_NAME,
                                                            @"entities-json-array-key": @"sets",
                                                            @"msg-action": @(RWatchMsgActionSaveNewSets)}];
}

- (IBAction)syncBmls {
  [self presentControllerWithName:@"EntitySyncer" context:@{@"entity-type": @"body log",
                                                            @"entity-files": _bmlFiles,
                                                            @"entities-json-filename": BMLS_JSON_FILE_NAME,
                                                            @"entities-json-array-key": @"bmls",
                                                            @"msg-action": @(RWatchMsgActionSaveNewBmls)}];
}

- (IBAction)settings {
  [self pushControllerWithName:@"Settings" context:nil];
}

- (IBAction)workouts {
  [self pushControllerWithName:@"Workouts" context:nil];
}

- (IBAction)sets {
  [self pushControllerWithName:@"Sets" context:nil];
}

- (IBAction)bmls {
  [self pushControllerWithName:@"Bmls" context:nil];
}

@end



