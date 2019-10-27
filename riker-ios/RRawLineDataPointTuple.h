//
//  RRawLineDataPointTuple.h
//  Riker
//
//  Created by PEVANS on 1/24/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RRawLineDataPointTuple : NSObject

@property (nonatomic) NSDecimalNumber *sum;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSDecimalNumber *percentage;
@property (nonatomic) NSDecimalNumber *avg;

@end
