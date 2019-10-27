//
//  RNormalizedTimeSeriesTupleCollection.h
//  riker-ios
//
//  Created by PEVANS on 3/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RNormalizedTimeSeriesTuple;

@interface RNormalizedTimeSeriesTupleCollection : NSObject

+ (instancetype)dataEntries;

@property (nonatomic) NSMutableDictionary<NSNumber *, RNormalizedTimeSeriesTuple *> *normalizedTimeSeriesTuplesDict;

@property (nonatomic) NSDecimalNumber *maxAggregateSummedValue;
@property (nonatomic) NSDecimalNumber *maxAvgAggregateValue;
@property (nonatomic) NSDecimalNumber *maxDistributionValue;

- (void)setNormalizedTimeSeriesTuple:(RNormalizedTimeSeriesTuple *)normalizedTimeSeriesTuple
            forLocalMasterIdentifier:(NSNumber *)identifier;

@end
