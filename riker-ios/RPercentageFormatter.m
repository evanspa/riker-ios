//
//  RPercentageFormatter.m
//  riker-ios
//
//  Created by PEVANS on 3/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RPercentageFormatter.h"

@implementation RPercentageFormatter {
  NSNumberFormatter *_numberFormatter;
}

- (id)init {
  self = [super init];
  if (self) {
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
  }
  return self;
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis {
  return [_numberFormatter stringFromNumber:@(value)];
}

@end
