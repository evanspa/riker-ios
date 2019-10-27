//
//  RLineChartDataCache.h
//  Riker
//
//  Created by PEVANS on 1/28/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RChartConfig.h"

@class LineChartData;

@interface RLineChartDataCache : NSObject

@property (nonatomic) LineChartData *lineChartData;
@property (nonatomic) RChartConfigAggregateBy aggregateBy;
@property (nonatomic) NSInteger xaxisLabelCount;
@property (nonatomic) NSDecimalNumber *maxValue;

@end
