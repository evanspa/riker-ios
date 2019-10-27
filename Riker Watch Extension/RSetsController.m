//
//  RSetsController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSetsController.h"
#import "RExtensionUtils.h"
#import "RSetsRowController.h"
#import "RExtensionDelegate.h"

@implementation RSetsController {
  NSMutableDictionary *_setsDict;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  _setsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:SETS_JSON_FILE_NAME];
  if (_setsDict) {
    NSArray *sets = _setsDict[@"sets"];
    NSInteger numSets = sets.count;
    if (numSets > 0) {
      [_noSetsFoundGroup setHidden:YES];
    }
    [self.setsTable setNumberOfRows:numSets withRowType:@"SetRow"];
    NSDateFormatter *dateTimeFormatter = [RExtensionUtils dateTimeFormatter];
    for (NSInteger i = 0; i < numSets; i++) {
      RSetsRowController *rowController = [self.setsTable rowControllerAtIndex:i];
      NSDictionary *set = sets[i];
      NSDate *loggedAt = [RExtensionUtils dateFromDict:set key:@"logged-at-unix-time"];
      [rowController.dateLabel setText:[dateTimeFormatter stringFromDate:loggedAt]];
      [rowController.movementLabel setText:set[@"movement"]];
      [rowController.movementVariantLabel setText:set[@"movement-variant"]];      
      NSNumber *syncedToIPhone = set[@"synced-to-iphone"];
      if (syncedToIPhone) {
        [rowController.syncedLabel setText:nil];
      } else {
        NSNumber *syncRequested = set[@"sync-requested"];
        if (syncRequested && syncRequested.boolValue) {
          [rowController.syncedLabel setText:@"sent to iPhone"];
        }
      }
      [rowController.repsAndWeightLabel setText:set[@"reps-and-weight-desc"]];
    }
  }
}

- (void)didAppear {
  [super didAppear];
  if (EXT.deletedSetIndex) {
    NSInteger deletedSetIndexInt = EXT.deletedSetIndex.integerValue;
    // update the 'model'
    NSArray *sets = _setsDict[@"sets"];
    NSMutableArray *mutableSets = [NSMutableArray arrayWithArray:sets];
    [mutableSets removeObjectAtIndex:deletedSetIndexInt];
    _setsDict[@"sets"] = mutableSets;
    // update the 'view'
    [self.setsTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:deletedSetIndexInt]];
  }
  EXT.deletedSetIndex = nil;
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *sets = _setsDict[@"sets"];
  EXT.selectedSet = sets[rowIndex];
  EXT.selectedSetIndex = rowIndex;
  [self pushControllerWithName:@"SetDetail" context:nil];
}

@end
