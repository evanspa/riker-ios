//
//  RNormalizedLineChartDataEntry.m
//  riker-ios
//
//  Created by PEVANS on 3/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RNormalizedLineChartDataEntry.h"

@implementation RNormalizedLineChartDataEntry

- (id)init {
  self = [super init];
  if (self) {
    _count = 0;
    _aggregateSummedValue = [NSDecimalNumber zero];
    _avgAggregateValue = [NSDecimalNumber zero];
    _distribution = [NSDecimalNumber zero];
  }
  return self;
}

+ (instancetype)dataEntry {
  return [[RNormalizedLineChartDataEntry alloc] init];
}

- (void)incrementCount {
  _count++;
}

- (void)addToAggregateSummedValue:(NSDecimalNumber *)value {
  _aggregateSummedValue = [_aggregateSummedValue decimalNumberByAdding:value];
}

- (void)calculateAvgAggregateValue {
  if (_count > 0) {
    NSDecimalNumber *count = [[NSDecimalNumber alloc] initWithInteger:_count];
    _avgAggregateValue = [_aggregateSummedValue decimalNumberByDividingBy:count];
  }
}

- (void)calculateDistributionWithGroupIndexTotals:(NSDictionary *)groupIndexTotals {
  NSDecimalNumber *groupIndexTotal = groupIndexTotals[_groupIndex];
  if ([groupIndexTotal compare:[NSDecimalNumber zero]] == NSOrderedDescending) {
    _distribution = [_aggregateSummedValue decimalNumberByDividingBy:groupIndexTotal];
  }
}

#pragma mark - NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"date: [%@], count: [%ld], aggregate summed value: [%@], avg aggregate value: [%@], distribution %%: [%@]",
          _date,
          (long)_count,
          _aggregateSummedValue,
          _avgAggregateValue,
          _distribution];
}

@end
