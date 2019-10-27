//
//  RSetDetailController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSetDetailController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"

@implementation RSetDetailController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *set = EXT.selectedSet;
  NSDateFormatter *dateTimeFormatter = [RExtensionUtils dateTimeFormatter];
  NSDate *loggedAt = [RExtensionUtils dateFromDict:set key:@"logged-at-unix-time"];
  [_dateLabel setText:[dateTimeFormatter stringFromDate:loggedAt]];
  [_movementLabel setText:set[@"movement"]];
  [_movementVariantLabel setText:set[@"movement-variant"]];
  NSNumber *syncedToIPhone = set[@"synced-to-iphone"];
  if (syncedToIPhone) {
    [_syncedLabel setText:nil];
    [_deleteButton setHidden:YES];
  } else {
    NSNumber *syncRequested = set[@"sync-requested"];
    if (syncRequested && syncRequested.boolValue) {
      [_syncedLabel setText:@"sent to iPhone"];
      [_deleteButton setHidden:YES];
    } else {
      [_editOrDeleteLabel setText:nil];
    }
  }
  [_repsAndWeightLabel setText:set[@"reps-and-weight-desc"]];
  [_toFailureLabel setText:set[@"to-failure-desc"]];
  [_negativesLabel setText:set[@"negatives-desc"]];
}

- (IBAction)delete {
  BOOL removeSuccess = [RExtensionUtils deleteEntity:EXT.selectedSet
                                         entityIndex:EXT.selectedSetIndex
                                    entitiesFileName:SETS_JSON_FILE_NAME
                                         entitiesKey:@"sets"];
  if (removeSuccess) {
    [RExtensionUtils reloadComplications];
    EXT.deletedSetIndex = @(EXT.selectedSetIndex);
    [self popController];
  } else {
    [self presentControllerWithName:@"Oops" context:@"Error attempting to delete set.\nTry again."];
  }
}

@end



