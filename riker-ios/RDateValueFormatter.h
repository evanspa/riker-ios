//
//  RDateValueFormatter.h
//  riker-ios
//
//  Created by PEVANS on 3/7/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import Charts;
#pragma clang pop

@interface RDateValueFormatter : NSObject <IChartAxisValueFormatter>

#pragma mark - Initializers

- (id)initWithFormat:(NSString *)format;

@end
