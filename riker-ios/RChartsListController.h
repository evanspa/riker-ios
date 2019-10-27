//
//  RChartsListController.h
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"
#import "RAbstractChartController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;
@class RChartStrengthRawData;
@class RCachingChartDataDao;

typedef NSArray *(^ChartsCarouselMaker)(id chartsListController,
UIView *relativeToView,
RChartStrengthRawData *,
NSArray *bodySegments,
NSDictionary *bodySegmentsDict,
NSArray *muscleGroups,
NSDictionary *muscleGroupsDict,
NSArray *muscles,
NSDictionary *musclesDict,
NSArray *movements,
NSDictionary *movementsDict,
NSArray *movementVariants,
NSDictionary *movementVariantsDict,
NSArray *sets);

@interface RChartsListController : RAbstractChartController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     fetchMode:(RChartDataFetchMode)fetchMode
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                   screenTitle:(NSString *)screenTitle             
          strengthChartConfigs:(RChartConfig *(^)(NSString *))strengthChartConfigs
     globalStrengthChartConfig:(RChartConfig *)globalStrengthChartConfig
             metricHeadingText:(NSString *)metricHeadingText
        metricAlertDescription:(NSAttributedString *)metricAlertDescription
          chartTypeHeadingText:(NSString *)chartTypeHeadingText
       chartTypeAlertTitleText:(NSString *)chartTypeAlertTitleText
     chartTypeAlertDescription:(NSAttributedString *)chartTypeAlertDescription
      chartTypeBackgroundColor:(UIColor *)chartTypeBackgroundColor
     chartAndLoaderTuplesMaker:(NSDictionary *(^)(RChartsListController *, UIView *))chartAndLoaderTuplesMaker
          chartConfigTitlePart:(NSString *)chartConfigTitlePart
              parentController:(RAbstractChartController *)parentController
           chartConfigCategory:(RChartConfigCategory)chartConfigCategory
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
               calcPercentages:(BOOL)calcPercentages
                  calcAverages:(BOOL)calcAverages;

@end
