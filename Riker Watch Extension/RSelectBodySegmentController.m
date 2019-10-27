//
//  RSelectBodySegmentController.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectBodySegmentController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RSelectEntityRowController.h"

@implementation RSelectBodySegmentController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSArray *bodySegments = [self bodySegments];
  NSInteger numBodySegments = bodySegments.count;
  [self.bodySegmentsTable setNumberOfRows:numBodySegments withRowType:@"BodySegmentRow"];
  for (NSInteger i = 0; i < numBodySegments; i++) {
    RSelectEntityRowController *rowController = [self.bodySegmentsTable rowControllerAtIndex:i];
    NSDictionary *bodySegment = bodySegments[i];
    [rowController.label setText:bodySegment[@"name"]];
  }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  NSArray *bodySegments = [self bodySegments];
  EXT.selectedBodySegmentId = bodySegments[rowIndex][@"id"];
  [self pushControllerWithName:@"SelectMuscleGroup" context:nil];
}

- (NSArray *)bodySegments {
  return EXT.movementsAndSettings[@"body-segments"];
}

@end



