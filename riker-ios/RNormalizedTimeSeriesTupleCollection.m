//
//  RNormalizedTimeSeriesTupleCollection.m
//  riker-ios
//
//  Created by PEVANS on 3/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedTimeSeriesTuple.h"

@implementation RNormalizedTimeSeriesTupleCollection

- (id)init {
  self = [super init];
  if (self) {
    _normalizedTimeSeriesTuplesDict = [NSMutableDictionary dictionary];
    _maxAggregateSummedValue = [NSDecimalNumber zero];
    _maxAvgAggregateValue = [NSDecimalNumber zero];
    _maxDistributionValue = [NSDecimalNumber zero];
  }
  return self;
}

+ (instancetype)dataEntries {
  return [[RNormalizedTimeSeriesTupleCollection alloc] init];
}

- (void)setNormalizedTimeSeriesTuple:(RNormalizedTimeSeriesTuple *)normalizedTimeSeriesTuple
            forLocalMasterIdentifier:(NSNumber *)identifier {
  _normalizedTimeSeriesTuplesDict[identifier] = normalizedTimeSeriesTuple;
}

#pragma mark - NSObject

- (NSString *)description {
  NSMutableString *desc = [NSMutableString string];
  [desc appendFormat:@"Max aggregate summed value: [%@], max avg aggregate value: [%@], max distribution value: [%@]",
   _maxAggregateSummedValue,
   _maxAvgAggregateValue,
   _maxDistributionValue];
  [desc appendFormat:@"container: %@", _normalizedTimeSeriesTuplesDict];
  return desc;
}

@end
