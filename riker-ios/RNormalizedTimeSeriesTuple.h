//
//  RNormalizedTimeSeriesTuple.h
//  Riker
//
//  Created by PEVANS on 1/25/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import "RAbstractChartEntityDataTuple.h"

@class RNormalizedLineChartDataEntry;

@interface RNormalizedTimeSeriesTuple : RAbstractChartEntityDataTuple

@property (nonatomic) NSMutableArray<RNormalizedLineChartDataEntry *> *normalizedTimeSeries;

@end
