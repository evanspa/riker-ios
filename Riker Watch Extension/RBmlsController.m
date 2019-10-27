//
//  RBmlsController.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RBmlsController.h"
#import "RExtensionUtils.h"
#import "RBmlsRowController.h"
#import "RExtensionDelegate.h"

@implementation RBmlsController {
  NSMutableDictionary *_bmlsDict;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  _bmlsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:BMLS_JSON_FILE_NAME];
  if (_bmlsDict) {
    NSArray *bmls = _bmlsDict[@"bmls"];
    NSInteger numBmls = bmls.count;
    if (numBmls > 0) {
      [_noBmlsFoundGroup setHidden:YES];
    }
    [self.bmlsTable setNumberOfRows:numBmls withRowType:@"BmlRow"];
    NSDateFormatter *dateFormatter = [RExtensionUtils dateFormatter];
    for (NSInteger i = 0; i < numBmls; i++) {
      RBmlsRowController *rowController = [self.bmlsTable rowControllerAtIndex:i];
      NSDictionary *bml = bmls[i];
      NSDate *loggedAt = [RExtensionUtils dateFromDict:bml key:@"logged-at-unix-time"];
      [rowController.dateLabel setText:[dateFormatter stringFromDate:loggedAt]];
      [rowController.bmlTypeLabel setText:bml[@"bml-type"]];
      [RExtensionUtils setTextOrHideLabel:rowController.bodyWeightLabel text:bml[@"body-weight"]];
      [RExtensionUtils setTextOrHideLabel:rowController.armSizeLabel text:bml[@"arm-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.calfSizeLabel text:bml[@"calf-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.thighSizeLabel text:bml[@"thigh-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.chestSizeLabel text:bml[@"chest-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.waistSizeLabel text:bml[@"waist-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.forearmSizeLabel text:bml[@"forearm-size"]];
      [RExtensionUtils setTextOrHideLabel:rowController.neckSizeLabel text:bml[@"neck-size"]];
      NSNumber *syncedToIPhone = bml[@"synced-to-iphone"];
      if (syncedToIPhone) {
        [rowController.syncedLabel setText:nil];
      } else {
        NSNumber *syncRequested = bml[@"sync-requested"];
        if (syncRequested && syncRequested.boolValue) {
          [rowController.syncedLabel setText:@"sent to iPhone"];
        }
      }
    }
  }
}

- (void)didAppear {
  [super didAppear];
  if (EXT.deletedBmlIndex) {
    NSInteger deletedBmlIndexInt = EXT.deletedBmlIndex.integerValue;
    // update the 'model'
    NSArray *bmls = _bmlsDict[@"bmls"];
    NSMutableArray *mutableBmls = [NSMutableArray arrayWithArray:bmls];
    [mutableBmls removeObjectAtIndex:deletedBmlIndexInt];
    _bmlsDict[@"bmls"] = mutableBmls;
    // update the 'view'
    [self.bmlsTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:deletedBmlIndexInt]];
  }
  EXT.deletedBmlIndex = nil;
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *bmls = _bmlsDict[@"bmls"];
  EXT.selectedBml = bmls[rowIndex];
  EXT.selectedBmlIndex = rowIndex;
  [self pushControllerWithName:@"BmlDetail" context:nil];
}

@end
