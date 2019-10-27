//
//  RRestTimeController.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RRestTimeController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "RLocalDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RLogging.h"
#import "RUIUtils.h"
#import "PEUtils.h"
#import "PELocalDao.h"
#import "RPanelToolkit.h"
#import "RPanelToolkit.h"
#import "RUserSettings.h"
#import "NSString+RAdditions.h"
#import "RChartIdPrefixes.h"
#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedLineChartDataEntry.h"
#import "RNumberValueFormatter.h"
#import "RChartsListController.h"
#import "RPercentageFormatter.h"

@implementation RRestTimeController {
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache {
  self = [super initWithStoreCoordinator:coordDao
                         userSettingsBlk:userSettingsBlk
                               uitoolkit:uitoolkit
                           screenToolkit:screenToolkit
                            panelToolkit:panelToolkit
                             screenTitle:@"Rest Time"
                                    user:user
                 entitiesAndRawDataCache:entitiesAndRawDataCache];
  if (self) {
  }
  return self;
}

#pragma mark - Your Strength Content

- (UIView *)yourContentRelativeToView:(UIView *)relativeToView {
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  CGFloat totalHeightSubContentPanel = 0.0;
  NSDictionary *(^makeChartAndLoaderTuples)(RChartDataFetchMode, RAbstractChartController *, UIView *);
  NSString *chartIdPrefix;
  NSArray *allMuscleGroupsChartIdAndTuple;
  RChartAndLoaderTuple *(^chartAndLoaderTupleBlk)(void);
  RChartAndLoaderTuple *chartAndLoaderTuple;
  NSAttributedString *chartTypeHelpDesc;
  NSString *chartTypeHeadingText;
  NSString *chartTypeAlertTitleText;
  UIColor *chartTypeBackgroundColor;
  NSString *chartId;
  self.chartAndLoaderTuplesArray = [NSMutableArray array];
  self.chartAndLoaderTuples = [NSMutableDictionary dictionary];
  NSString *chartTitlePrefix;
  NSString *chartTitlePostfix;
  BOOL isPortraitMode = [PEUIUtils isPortraitMode];
  
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // 'Time Between Sets' views
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  UIView *timeBetweenSetsContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:subContentPanel fixedHeight:0.0];
  CGFloat totalHeightTimeBetweenSetsContentPanel = 0.0;
  NSAttributedString *metricDesc = [RUtils timeBetweenSetsMetricDesc];
  NSString *metricHeadingText = @"Rest Time";
  UIView *timeBetweenSetsMetricHeadingPanel =
  [RAbstractChartController makeMetricTypeHeadingPanelWithTitle:metricHeadingText
                                                 infoAlertTitle:metricHeadingText
                                           infoAlertDescription:metricDesc
                                                 settingsAction:^{ [self globalChartConfigSettingsCalcPercentages:self.calcPercentages
                                                                                                     calcAverages:self.calcAverages]; }
                                                 relativeToView:timeBetweenSetsContentPanel
                                                     controller:self
                                       chartReloadButtonHandler:^{
                                         [self loadChartsWithCompletion:nil
                                              showAlertIfAlreadyLoading:YES
                                                               headless:NO
                                                        calcPercentages:self.calcPercentages
                                                           calcAverages:self.calcAverages];
                                       }];
  chartIdPrefix = CHART_ID_PREFIX_TBS_TIME;
  chartTitlePrefix = @"Total ";
  chartTitlePostfix = @"";
  NSString *timeQualifier = @"sum total of all your time spent between sets";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                calculateAverages:NO
                                                                           calculateDistributions:NO
                                                                                    chartIdPrefix:chartIdPrefix
                                                                               yaxisValueLabelBlk:[RAbstractChartController makeYaxisLabelBlkWithType:@"seconds" isPortraitMode:isPortraitMode]
                                                                                      maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                                        yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                                yaxisFormatterBlk:^(double maxValue) {
                                                                                  return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                                }
                                                                                  yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                                     isPercentage:NO
                                                                                 chartTitlePrefix:chartTitlePrefix
                                                                                chartTitlePostfix:chartTitlePostfix
                                                                             sectionHighlightText:@"your total rest time between sets"
                                                                                    timeQualifier:timeQualifier
                                                                                   relativeToView:relativeToView
                                                                                  strengthConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                                       controller:ctrlr
                                                                            areDistributionTuples:NO
                                                                                         coordDao:self.coordDao
                                                                                chartViewDelegate:self
                                                                                        uitoolkit:self.uitoolkit
                                                                                    screenToolkit:self.screenToolkit
                                                                                     panelToolkit:self.panelToolkit
                                                                                         headless:NO
                                                                          entitiesAndRawDataCache:self.entitiesAndRawDataCache                                                                                  
                                                                                          logging:NO];
  };
  NSDictionary *chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, timeBetweenSetsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateTimeBetweenSetsSameMovLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateTimeBetweenSetsTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Total Rest Time";
  chartTypeAlertTitleText = @"Total Rest Time Timeline Charts";
  chartTypeBackgroundColor = [UIColor cochinealRedSemiClear];
  UIView *aggregateTimeBetweenSetsSameMovTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeTimeBetweenSetsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Rest Time Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeTimeBetweenSetsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Rest Time"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:timeBetweenSetsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_TBS_AVG_TIME;
  chartTitlePrefix = @"Average ";
  chartTitlePostfix = @" per Set";
  timeQualifier = @"per-set average of all your rest time";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                calculateAverages:YES
                                                                           calculateDistributions:NO
                                                                                    chartIdPrefix:chartIdPrefix
                                                                               yaxisValueLabelBlk:[RAbstractChartController makeYaxisLabelBlkWithType:@"seconds" isPortraitMode:isPortraitMode]
                                                                                      maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                        yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                yaxisFormatterBlk:^(double maxValue) {
                                                                                  return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                                }
                                                                                  yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                                     isPercentage:NO
                                                                                 chartTitlePrefix:chartTitlePrefix
                                                                                chartTitlePostfix:chartTitlePostfix
                                                                             sectionHighlightText:@"your rest time per-set average"
                                                                                    timeQualifier:timeQualifier
                                                                                   relativeToView:relativeToView
                                                                                  strengthConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                                       controller:ctrlr
                                                                            areDistributionTuples:NO
                                                                                         coordDao:self.coordDao
                                                                                chartViewDelegate:self
                                                                                        uitoolkit:self.uitoolkit
                                                                                    screenToolkit:self.screenToolkit
                                                                                     panelToolkit:self.panelToolkit
                                                                                         headless:NO
                                                                          entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                          logging:NO];
  };
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, timeBetweenSetsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *avgTimeBetweenSetsPerSetLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils avgTimeBetweenSetsPerSetTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Average per Set";
  chartTypeAlertTitleText = @"Average Rest Time Timeline Charts";
  UIView *avgTimeBetweenSetsPerSetTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeTimeBetweenSetsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Avg Rest Time Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeTimeBetweenSetsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Rest Time"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:YES];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:timeBetweenSetsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_TBS_DIST;
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeTimeBetweenSetsSameMovPieChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                      chartIdPrefix:chartIdPrefix
                                                                                     relativeToView:relativeToView
                                                                                    strengthConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                                         controller:ctrlr
                                                                                           coordDao:self.coordDao
                                                                                          uitoolkit:self.uitoolkit
                                                                                      screenToolkit:self.screenToolkit
                                                                                       panelToolkit:self.panelToolkit
                                                                                           headless:NO                                                                                    
                                                                                            logging:NO];
  };
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, timeBetweenSetsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](1); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateTimeBetweenSetsSameMovPieChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateTimeBetweenSetsSameMovPieChartsHelpDesc];
  chartTypeHeadingText = @"Distribution";
  chartTypeAlertTitleText = @"Distribution";
  UIView *aggregateTimeBetweenSetsSameMovPieChartTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeTimeBetweenSetsDist
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Rest Time Pie"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeTimeBetweenSetsDist, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Rest Time"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:timeBetweenSetsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_TBS_DIST_TIME;
  chartTitlePrefix = @"";
  chartTitlePostfix = @" Distribution";
  timeQualifier = @"percentage of all your rest time";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                                calculateAverages:NO
                                                                           calculateDistributions:YES
                                                                                    chartIdPrefix:chartIdPrefix
                                                                               yaxisValueLabelBlk:nil
                                                                                      maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxDistributionValue; }
                                                                                        yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.distribution; }
                                                                                yaxisFormatterBlk:^(double maxValue) { return [[RPercentageFormatter alloc] init]; }
                                                                                  yaxisMaximumBlk:^(double maxValue) { return 1.05; }
                                                                                     isPercentage:YES
                                                                                 chartTitlePrefix:chartTitlePrefix
                                                                                chartTitlePostfix:chartTitlePostfix
                                                                             sectionHighlightText:@"how your rest time distributes"
                                                                                    timeQualifier:timeQualifier
                                                                                   relativeToView:relativeToView
                                                                                  strengthConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                                       controller:ctrlr
                                                                            areDistributionTuples:YES
                                                                                         coordDao:self.coordDao
                                                                                chartViewDelegate:self
                                                                                        uitoolkit:self.uitoolkit
                                                                                    screenToolkit:self.screenToolkit
                                                                                     panelToolkit:self.panelToolkit
                                                                                         headless:NO
                                                                          entitiesAndRawDataCache:self.entitiesAndRawDataCache                                                                                  
                                                                                          logging:NO];
  };
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, timeBetweenSetsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *timeBetweenSetsSameMovDistributionLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils timeBetweenSetsSameMovLiftedDistributionTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Distribution / Time";
  chartTypeAlertTitleText = @"Rest Time Distribution Timeline Charts";
  UIView *timeBetweenSetsSameMovDistributionTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeTimeBetweenSetsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Rest Time Distribution"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeTimeBetweenSetsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Rest Time"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:YES
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:timeBetweenSetsContentPanel
                                                    controller:self];
  // make jump-to buttons panel
  NSArray *jumpToButtons = [self makeJumpToButtons];
  UIButton *jumpToTotalButton = jumpToButtons[0];
  UIButton *jumpToAvgButton = jumpToButtons[1];
  UIButton *jumpToDistButton = jumpToButtons[2];
  UIButton *jumpToDistTimeButton = jumpToButtons[3];
  UIView *jumpToPanel = [RAbstractChartController jumpPanelWithButtons:[[NSMutableArray alloc] initWithArray:@[jumpToTotalButton, jumpToAvgButton, jumpToDistButton, jumpToDistTimeButton]]
                                    relativeToView:timeBetweenSetsContentPanel];
  // place 'Time Between Sets' content onto timeBetweenSetsContentPanel
  CGFloat betweenHeadingPanelsVpadding = 2.5;
  CGFloat carouselVpadding = 12.0;
  [PEUIUtils placeView:timeBetweenSetsMetricHeadingPanel
               atTopOf:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += timeBetweenSetsMetricHeadingPanel.frame.size.height;
  CGFloat vpadding = betweenHeadingPanelsVpadding;
  [PEUIUtils placeView:jumpToPanel
                 below:timeBetweenSetsMetricHeadingPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += jumpToPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateTimeBetweenSetsSameMovTimelineTypeHeadingPanel
                 below:jumpToPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += aggregateTimeBetweenSetsSameMovTimelineTypeHeadingPanel.frame.size.height + vpadding;
  vpadding = carouselVpadding;
  [PEUIUtils placeView:aggregateTimeBetweenSetsSameMovLineChartsCarousel
                 below:aggregateTimeBetweenSetsSameMovTimelineTypeHeadingPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += aggregateTimeBetweenSetsSameMovLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgTimeBetweenSetsPerSetTimelineTypeHeadingPanel
                 below:aggregateTimeBetweenSetsSameMovLineChartsCarousel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += avgTimeBetweenSetsPerSetTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgTimeBetweenSetsPerSetLineChartsCarousel
                 below:avgTimeBetweenSetsPerSetTimelineTypeHeadingPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += avgTimeBetweenSetsPerSetLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateTimeBetweenSetsSameMovPieChartTypeHeadingPanel
                 below:avgTimeBetweenSetsPerSetLineChartsCarousel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += aggregateTimeBetweenSetsSameMovPieChartTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateTimeBetweenSetsSameMovPieChartsCarousel
                 below:aggregateTimeBetweenSetsSameMovPieChartTypeHeadingPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += aggregateTimeBetweenSetsSameMovPieChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:timeBetweenSetsSameMovDistributionTimelineTypeHeadingPanel
                 below:aggregateTimeBetweenSetsSameMovPieChartsCarousel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += timeBetweenSetsSameMovDistributionTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:timeBetweenSetsSameMovDistributionLineChartsCarousel
                 below:timeBetweenSetsSameMovDistributionTimelineTypeHeadingPanel
                  onto:timeBetweenSetsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:timeBetweenSetsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightTimeBetweenSetsContentPanel += timeBetweenSetsSameMovDistributionLineChartsCarousel.frame.size.height + vpadding;
  totalHeightTimeBetweenSetsContentPanel += carouselVpadding; // to give it some bottom-margin
  [PEUIUtils setFrameHeight:totalHeightTimeBetweenSetsContentPanel ofView:timeBetweenSetsContentPanel];
  
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // Place all the main content panels on the subContentPanel
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  [PEUIUtils placeView:timeBetweenSetsContentPanel
               atTopOf:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightSubContentPanel += timeBetweenSetsContentPanel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeightSubContentPanel ofView:subContentPanel];
  
  // configure jump-to buttons
  [self configureJumpToButton:jumpToTotalButton contentPanel:subContentPanel headingPanel:aggregateTimeBetweenSetsSameMovTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToAvgButton contentPanel:subContentPanel headingPanel:avgTimeBetweenSetsPerSetTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistButton contentPanel:subContentPanel headingPanel:aggregateTimeBetweenSetsSameMovPieChartTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistTimeButton contentPanel:subContentPanel headingPanel:timeBetweenSetsSameMovDistributionTimelineTypeHeadingPanel];
  
  return subContentPanel;
}

#pragma mark - Chart Loading

- (RChartDataFetchMode)fetchMode {
  return RChartDataFetchModeTimeBetweenSetsCrossSection;
}

#pragma mark - Chart Config Helpers

- (RChartConfigCategory)chartConfigCategory {
  return RChartConfigCategoryRest;
}

- (NSString *)globalChartConfigSettingsTitlePart {
  return @"Rest Time";
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  void (^populateChartConfigs)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *) = [self populateChartConfigsBlkWithGlobalConfig:globalConfig];
  void (^populateStrengthChartConfigs)(NSString *) = ^(NSString *chartIdPrefix) {
    populateChartConfigs(^(NSString *chartId, RChartConfig *chartConfig) {
      [self.coordDao saveNewOrExistingByChartIdChartConfig:chartConfig forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    }, MAX_STRENGTH_CHARTS_PER_PREFIX, chartIdPrefix);
  };
  populateStrengthChartConfigs(CHART_ID_PREFIX_TBS_DIST);
  populateStrengthChartConfigs(CHART_ID_PREFIX_TBS_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_TBS_AVG_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_TBS_DIST_TIME);
  [self.entitiesAndRawDataCache removeAllObjects];
}

@end



