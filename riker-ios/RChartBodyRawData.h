//
//  RChartBodyData.h
//  riker-ios
//
//  Created by PEVANS on 3/24/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RChartBodyRawData : NSObject

#pragma mark - Creation Helper

+ (instancetype)chartRawData;

#pragma mark - Data Date Range

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;

////////////////////////////////////////////////////////////////////////////////
// Line chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary *bodyWeightTimeSeries;
@property (nonatomic) NSMutableDictionary *armSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *chestSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *calfSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *thighSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *forearmSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *waistSizeTimeSeries;
@property (nonatomic) NSMutableDictionary *neckSizeTimeSeries;

@end
