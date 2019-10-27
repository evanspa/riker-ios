//
//  RDateValueFormatter.m
//  riker-ios
//
//  Created by PEVANS on 3/7/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RDateValueFormatter.h"

@implementation RDateValueFormatter {
  NSDateFormatter *_dateFormatter;
}

#pragma mark - Initializers

- (id)initWithFormat:(NSString *)format {
  self = [super init];
  if (self) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateFormat = format;
  }
  return self;
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis {
  return [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:value]];
}

@end
