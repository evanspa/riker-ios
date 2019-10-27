//
//  RBmlDetailController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/22/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RBmlDetailController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"

@implementation RBmlDetailController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *bml = EXT.selectedBml;
  NSDateFormatter *dateFormatter = [RExtensionUtils dateFormatter];
  NSDate *loggedAt = [RExtensionUtils dateFromDict:bml key:@"logged-at-unix-time"];
  [_dateLabel setText:[dateFormatter stringFromDate:loggedAt]];
  NSNumber *syncedToIPhone = bml[@"synced-to-iphone"];
  if (syncedToIPhone) {
    [_syncedLabel setHidden:YES];
    [_deleteButton setHidden:YES];
  } else {
    NSNumber *syncRequested = bml[@"sync-requested"];
    if (syncRequested && syncRequested.boolValue) {
      [_syncedLabel setText:@"sent to iPhone"];
      [_deleteButton setHidden:YES];
    } else {
      [_editOrDeleteLabel setText:nil];
    }
  }
  [_bmlTypeLabel setText:bml[@"bml-type"]];
  [RExtensionUtils setTextOrHideLabel:_bodyWeightLabel text:bml[@"body-weight"]];
  [_armSizeLabel setText:bml[@"arm-size"]];
  [RExtensionUtils setTextOrHideLabel:_armSizeLabel text:bml[@"arm-size"]];
  [RExtensionUtils setTextOrHideLabel:_calfSizeLabel text:bml[@"calf-size"]];
  [RExtensionUtils setTextOrHideLabel:_thighSizeLabel text:bml[@"thigh-size"]];
  [RExtensionUtils setTextOrHideLabel:_chestSizeLabel text:bml[@"chest-size"]];
  [RExtensionUtils setTextOrHideLabel:_waistSizeLabel text:bml[@"waist-size"]];
  [RExtensionUtils setTextOrHideLabel:_forearmSizeLabel text:bml[@"forearm-size"]];
  [RExtensionUtils setTextOrHideLabel:_neckSizeLabel text:bml[@"neck-size"]];
}

- (IBAction)delete {
  BOOL removeSuccess = [RExtensionUtils deleteEntity:EXT.selectedBml
                                         entityIndex:EXT.selectedBmlIndex
                                    entitiesFileName:BMLS_JSON_FILE_NAME
                                         entitiesKey:@"bmls"];
  if (removeSuccess) {
    EXT.deletedBmlIndex = @(EXT.selectedBmlIndex);
    [self popController];
  } else {
    [self presentControllerWithName:@"Oops" context:@"Error attempting to delete body log.\nTry again."];
  }
}

@end



