//
//  RNumberValueFormatter.h
//  riker-ios
//
//  Created by PEVANS on 3/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import Charts;
#pragma clang pop

@interface RNumberValueFormatter : NSObject <IChartAxisValueFormatter>

#pragma mark - Initializers

- (id)initWithScalingFactor:(CGFloat)scalingFactor;

@end
