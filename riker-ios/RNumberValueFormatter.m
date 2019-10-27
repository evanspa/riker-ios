//
//  RNumberValueFormatter.m
//  riker-ios
//
//  Created by PEVANS on 3/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RNumberValueFormatter.h"

@implementation RNumberValueFormatter {
  NSNumberFormatter *_numberFormatter;
  CGFloat _scalingFactor;
}

#pragma mark - Initializers

- (id)initWithScalingFactor:(CGFloat)scalingFactor {
  self = [super init];
  if (self) {
    _scalingFactor = scalingFactor;
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.maximumFractionDigits = 1;
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    _numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
  }
  return self;
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis {
  return [_numberFormatter stringFromNumber:@(value * _scalingFactor)];
}

@end
