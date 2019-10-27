//
//  RNormalizedLineChartDataEntry.h
//  riker-ios
//
//  Created by PEVANS on 3/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RNormalizedLineChartDataEntry : NSObject

+ (instancetype)dataEntry;

@property (nonatomic) NSDate *date;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSDecimalNumber *aggregateSummedValue;
@property (nonatomic) NSDecimalNumber *avgAggregateValue;
@property (nonatomic) NSDecimalNumber *distribution;
@property (nonatomic) NSNumber *groupIndex;

- (void)incrementCount;

- (void)addToAggregateSummedValue:(NSDecimalNumber *)value;

- (void)calculateAvgAggregateValue;
- (void)calculateDistributionWithGroupIndexTotals:(NSDictionary *)groupIndexTotals;

@end
