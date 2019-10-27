//
//  RChartFilterScreen.h
//  riker-ios
//
//  Created by PEVANS on 3/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"

@class RChartConfig;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;

@interface RChartFilterScreen : PELocalDataBaseController

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
    mainHeadingText:(NSString *)mainHeadingText
         entityType:(NSString *)entityType
enableLineChartOptions:(BOOL)enableLineChartOptions
enablePieChartOptions:(BOOL)enablePieChartOptions
      veryFirstDate:(NSDate *)veryFirstDate
       veryLastDate:(NSDate *)veryLastDate
        chartConfig:(RChartConfig *)chartConfig
   clearButtonTitle:(NSString *)clearButtonTitle
           clearBlk:(void(^)(void))clearBlk
            doneBlk:(void(^)(RChartConfig *))doneBlk
          uitoolkit:(PEUIToolkit *)uitoolkit
      screenToolkit:(RScreenToolkit *)screenToolkit
       panelToolkit:(RPanelToolkit *)panelToolkit;

@end
