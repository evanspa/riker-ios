//
//  RRawLineDataPointsByDateTuple.h
//  Riker
//
//  Created by PEVANS on 1/24/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RAbstractChartEntityDataTuple.h"

@class RRawLineDataPointTuple;

@interface RRawLineDataPointsByDateTuple : RAbstractChartEntityDataTuple

@property (nonatomic) NSMutableDictionary<NSDate *, RRawLineDataPointTuple *> *dataPointsByDate;

@end
