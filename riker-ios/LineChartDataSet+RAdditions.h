//
//  LineChartDataSet+RAdditions.h
//  Riker
//
//  Created by PEVANS on 1/29/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Charts;

@interface LineChartDataSet (RAdditions)

@property (nonatomic, strong) NSNumber *entityLocalMasterIdentifier;
@property (nonatomic, strong) NSNumber *localId;

@end
