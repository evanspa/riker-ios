//
//  RRepsController.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RRepsController.h"
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

@implementation RRepsController {
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
                             screenTitle:@"Reps"
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
  // 'Reps' views
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  UIView *repsContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:subContentPanel fixedHeight:0.0];
  CGFloat totalHeightRepsContentPanel = 0.0;
  NSAttributedString *metricDesc = [RUtils repsMetricDesc];
  NSString *metricHeadingText = @"Reps";
  UIView *repsMetricHeadingPanel = [RAbstractChartController makeMetricTypeHeadingPanelWithTitle:metricHeadingText
                                                                                  infoAlertTitle:metricHeadingText
                                                                            infoAlertDescription:metricDesc
                                                                                  settingsAction:^{ [self globalChartConfigSettingsCalcPercentages:self.calcPercentages
                                                                                                                                      calcAverages:self.calcAverages]; }
                                                                                  relativeToView:repsContentPanel
                                                                                      controller:self
                                                                        chartReloadButtonHandler:^{
                                                                          [self loadChartsWithCompletion:nil
                                                                               showAlertIfAlreadyLoading:YES
                                                                                                headless:NO
                                                                                         calcPercentages:self.calcPercentages
                                                                                            calcAverages:self.calcAverages];
                                                                        }];
  chartIdPrefix = CHART_ID_PREFIX_REPS_TIME;
  chartTitlePrefix = @"Total ";
  chartTitlePostfix = @"";
  NSString *repsQualifier = @"sum total of all your reps";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {        
    return [RAbstractChartController makeRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                     calculateAverages:NO
                                                                calculateDistributions:NO
                                                                         chartIdPrefix:chartIdPrefix
                                                                    yaxisValueLabelBlk:[RAbstractChartController makeYaxisLabelBlkWithType:@"reps" isPortraitMode:isPortraitMode]
                                                                           maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                             yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                     yaxisFormatterBlk:^(double maxValue) {
                                                                       return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                     }
                                                                       yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                          isPercentage:NO
                                                                      chartTitlePrefix:chartTitlePrefix
                                                                     chartTitlePostfix:chartTitlePostfix
                                                                  sectionHighlightText:@"your total rep count"
                                                                         repsQualifier:repsQualifier
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
  NSDictionary *chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, repsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateRepsLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateRepsLiftedTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Total Reps";
  chartTypeAlertTitleText = @"Total Reps Timeline Charts";
  chartTypeBackgroundColor = [UIColor greenBambooSemiClear];
  UIView *aggregateRepsTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeRepsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Reps Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeRepsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Reps"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:repsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_REPS_AVG_TIME;
  chartTitlePrefix = @"Average ";
  chartTitlePostfix = @" per Set";
  repsQualifier = @"per-set average of all your reps";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                     calculateAverages:YES
                                                                calculateDistributions:NO
                                                                         chartIdPrefix:chartIdPrefix
                                                                    yaxisValueLabelBlk:[RAbstractChartController makeYaxisLabelBlkWithType:@"reps" isPortraitMode:isPortraitMode]
                                                                           maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                             yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                     yaxisFormatterBlk:^(double maxValue) {
                                                                       return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                     }
                                                                       yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                          isPercentage:NO
                                                                      chartTitlePrefix:chartTitlePrefix
                                                                     chartTitlePostfix:chartTitlePostfix
                                                                  sectionHighlightText:@"your rep count per-set average"
                                                                         repsQualifier:repsQualifier
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
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, repsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *avgRepsPerSetLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils avgRepsPerSetTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Average per Set";
  chartTypeAlertTitleText = @"Average Reps per Set Timeline Charts";
  UIView *avgRepsPerSetTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeRepsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Avg Reps Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeRepsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Reps"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:YES];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:repsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_REPS_DIST;
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeRepsPieChartAndLoaderTuplesWithFetchMode:fetchMode
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
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, repsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](1); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateRepsPieChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateRepsLiftedPieChartsHelpDesc];
  chartTypeHeadingText = @"Distribution";
  chartTypeAlertTitleText = @"Distribution";
  UIView *aggregateRepsPieChartTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeRepsDist
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Reps Pie"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeRepsDist, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Reps"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:repsContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_REPS_DIST_TIME;
  chartTitlePrefix = @"";
  chartTitlePostfix = @" Distribution";
  repsQualifier = @"percentage of all your reps";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
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
                                                                  sectionHighlightText:@"how your total rep count distributes"
                                                                         repsQualifier:repsQualifier
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
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, repsContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *repsDistributionLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils repsDistributionTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Distribution / Time";
  chartTypeAlertTitleText = @"Reps Distribution Timeline Charts";
  UIView *repsDistributionTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeRepsLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Reps Distribution"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeRepsLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Reps"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:YES
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:repsContentPanel
                                                    controller:self];
  // make jump-to buttons panel
  NSArray *jumpToButtons = [self makeJumpToButtons];
  UIButton *jumpToTotalButton = jumpToButtons[0];
  UIButton *jumpToAvgButton = jumpToButtons[1];
  UIButton *jumpToDistButton = jumpToButtons[2];
  UIButton *jumpToDistTimeButton = jumpToButtons[3];
  UIView *jumpToPanel = [RAbstractChartController jumpPanelWithButtons:[[NSMutableArray alloc] initWithArray:@[jumpToTotalButton, jumpToAvgButton, jumpToDistButton, jumpToDistTimeButton]]
                                    relativeToView:repsContentPanel];
  // place 'Reps' content onto repsContentPanel
  CGFloat betweenHeadingPanelsVpadding = 2.5;
  CGFloat carouselVpadding = 12.0;
  [PEUIUtils placeView:repsMetricHeadingPanel
               atTopOf:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightRepsContentPanel += repsMetricHeadingPanel.frame.size.height;
  CGFloat vpadding = betweenHeadingPanelsVpadding;
  [PEUIUtils placeView:jumpToPanel
                 below:repsMetricHeadingPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += jumpToPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateRepsTimelineTypeHeadingPanel
                 below:jumpToPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += aggregateRepsTimelineTypeHeadingPanel.frame.size.height + vpadding;
  vpadding = carouselVpadding;
  [PEUIUtils placeView:aggregateRepsLineChartsCarousel
                 below:aggregateRepsTimelineTypeHeadingPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += aggregateRepsLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgRepsPerSetTimelineTypeHeadingPanel
                 below:aggregateRepsLineChartsCarousel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += avgRepsPerSetTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgRepsPerSetLineChartsCarousel
                 below:avgRepsPerSetTimelineTypeHeadingPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += avgRepsPerSetLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateRepsPieChartTypeHeadingPanel
                 below:avgRepsPerSetLineChartsCarousel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += aggregateRepsPieChartTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateRepsPieChartsCarousel
                 below:aggregateRepsPieChartTypeHeadingPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += aggregateRepsPieChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:repsDistributionTimelineTypeHeadingPanel
                 below:aggregateRepsPieChartsCarousel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += repsDistributionTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:repsDistributionLineChartsCarousel
                 below:repsDistributionTimelineTypeHeadingPanel
                  onto:repsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:repsContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightRepsContentPanel += repsDistributionLineChartsCarousel.frame.size.height + vpadding;
  totalHeightRepsContentPanel += carouselVpadding; // to give it some bottom-margin
  [PEUIUtils setFrameHeight:totalHeightRepsContentPanel ofView:repsContentPanel];
  
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // Place all the main content panels on the subContentPanel
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  [PEUIUtils placeView:repsContentPanel
               atTopOf:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightSubContentPanel += repsContentPanel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeightSubContentPanel ofView:subContentPanel];
  
  // configure jump-to buttons
  [self configureJumpToButton:jumpToTotalButton contentPanel:subContentPanel headingPanel:aggregateRepsTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToAvgButton contentPanel:subContentPanel headingPanel:avgRepsPerSetTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistButton contentPanel:subContentPanel headingPanel:aggregateRepsPieChartTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistTimeButton contentPanel:subContentPanel headingPanel:repsDistributionTimelineTypeHeadingPanel];
  
  return subContentPanel;
}

#pragma mark - Chart Loading

- (RChartDataFetchMode)fetchMode {
  return RChartDataFetchModeRepsCrossSection;
}

#pragma mark - Chart Config Helpers

- (RChartConfigCategory)chartConfigCategory {
  return RChartConfigCategoryReps;
}

- (NSString *)globalChartConfigSettingsTitlePart {
  return @"Reps";
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  void (^populateChartConfigs)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *) = [self populateChartConfigsBlkWithGlobalConfig:globalConfig];
  void (^populateStrengthChartConfigs)(NSString *) = ^(NSString *chartIdPrefix) {
    populateChartConfigs(^(NSString *chartId, RChartConfig *chartConfig) {
      [self.coordDao saveNewOrExistingByChartIdChartConfig:chartConfig forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    }, MAX_STRENGTH_CHARTS_PER_PREFIX, chartIdPrefix);
  };
  populateStrengthChartConfigs(CHART_ID_PREFIX_REPS_DIST);
  populateStrengthChartConfigs(CHART_ID_PREFIX_REPS_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_REPS_AVG_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_REPS_DIST_TIME);
  [self.entitiesAndRawDataCache removeAllObjects];
}

@end


