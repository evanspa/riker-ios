//
//  RSelectMovementVariantController.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectMovementVariantController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RSelectEntityRowController.h"

@implementation RSelectMovementVariantController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSArray *movementVariants = [EXT movementVariants];
  NSInteger numMovementVariants = movementVariants.count;
  [self.movementVariantsTable setNumberOfRows:numMovementVariants withRowType:@"MovementVariantRow"];
  for (NSInteger i = 0; i < numMovementVariants; i++) {
    RSelectEntityRowController *rowController = [self.movementVariantsTable rowControllerAtIndex:i];
    NSDictionary *movementVariant = movementVariants[i];
    [rowController.label setText:movementVariant[@"name"]];
  }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *movementVariants = [EXT movementVariants];
  NSDictionary *movementVariant = movementVariants[rowIndex];
  EXT.selectedMovementVariantId = movementVariant[@"id"];
  EXT.selectedMovementVariantName = movementVariant[@"name"];
  [self pushControllerWithName:@"EnterReps" context:nil];
}

@end



