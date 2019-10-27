//
//  RChartBodyData.m
//  riker-ios
//
//  Created by PEVANS on 3/24/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RChartBodyRawData.h"

@implementation RChartBodyRawData

#pragma mark - Initializer

- (id)init {
  self = [super init];
  if (self) {
    ////////////////////////////////////////////////////////////////////////////
    // Line chart data sources
    ////////////////////////////////////////////////////////////////////////////
    _bodyWeightTimeSeries = [NSMutableDictionary dictionary];
    _armSizeTimeSeries = [NSMutableDictionary dictionary];
    _chestSizeTimeSeries = [NSMutableDictionary dictionary];
    _calfSizeTimeSeries = [NSMutableDictionary dictionary];
    _thighSizeTimeSeries = [NSMutableDictionary dictionary];
    _forearmSizeTimeSeries = [NSMutableDictionary dictionary];
    _waistSizeTimeSeries = [NSMutableDictionary dictionary];
    _neckSizeTimeSeries = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - Creation Helper

+ (instancetype)chartRawData {
  return [[RChartBodyRawData alloc] init];
}

@end
