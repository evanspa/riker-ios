//
//  RDashboardV2Controller.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RDashboardV2Controller.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <DateTools/DateTools.h>
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
#import "PELMUser.h"
#import "RAppNotificationNames.h"
#import "RRepsController.h"
#import "RRestTimeController.h"
#import "RBodyController.h"
#import "RWorkout.h"
#import "RMuscleGroup.h"
#import "RSelectScreen.h"

@implementation RDashboardV2Controller {
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                          user:(PELMUser *)user {
  self = [super initWithStoreCoordinator:coordDao
                         userSettingsBlk:userSettingsBlk
                               uitoolkit:uitoolkit
                           screenToolkit:screenToolkit
                            panelToolkit:panelToolkit
                             screenTitle:@"Riker Home"
                                    user:user
                 entitiesAndRawDataCache:[NSMutableDictionary dictionary]];
  if (self) {
  }
  return self;
}

#pragma mark - Your Strength Content

- (UIView *)yourContentRelativeToView:(UIView *)relativeToView {
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  CGFloat totalHeightSubContentPanel = 0.0;
  NSDictionary *(^makeChartAndLoaderTuples)(RChartDataFetchMode, RAbstractChartController *, UIView *);
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // 'Weight Lifted' views
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  UIView *weightLiftedContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:subContentPanel fixedHeight:0.0];
  CGFloat totalHeightWeightLiftedContentPanel = 0.0;
  NSAttributedString *metricDesc = [RUtils weightLiftedMetricDesc];
  NSString *metricHeadingText = @"Weight Lifted";
  UIView *weightLiftedMetricHeadingPanel =
  [RAbstractChartController makeMetricTypeHeadingPanelWithTitle:metricHeadingText
                                                 infoAlertTitle:metricHeadingText
                                           infoAlertDescription:metricDesc
                                                 settingsAction:^{ [self globalChartConfigSettingsCalcPercentages:self.calcPercentages
                                                                                                     calcAverages:self.calcAverages]; }
                                                 relativeToView:weightLiftedContentPanel
                                                     controller:self
                                       chartReloadButtonHandler:^{
                                         [self loadChartsWithCompletion:nil
                                              showAlertIfAlreadyLoading:YES
                                                               headless:NO
                                                        calcPercentages:self.calcPercentages
                                                           calcAverages:self.calcAverages];
                                       }];
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
  chartIdPrefix = CHART_ID_PREFIX_WEIGHT_LIFTED_TIME;
  NSString *chartTitlePrefix = @"Total ";
  NSString *chartTitlePostfix = @"";
  NSString *weightLiftedQualifier = @"sum total of all your weight lifted";
  BOOL isPortraitMode = [PEUIUtils isPortraitMode];
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                     calculateAverages:NO
                                                                calculateDistributions:NO
                                                                         chartIdPrefix:chartIdPrefix
                                                                    yaxisValueLabelBlk:[RAbstractChartController makeWeightYaxisLabelBlkIsPortraitMode:isPortraitMode]
                                                                           maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAggregateSummedValue; }
                                                                             yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.aggregateSummedValue; }
                                                                     yaxisFormatterBlk:^(double maxValue) {
                                                                       return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                     }
                                                                       yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                          isPercentage:NO
                                                                      chartTitlePrefix:chartTitlePrefix
                                                                     chartTitlePostfix:chartTitlePostfix
                                                                  sectionHighlightText:@"your total weight lifted"
                                                                 weightLiftedQualifier:weightLiftedQualifier
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
  NSDictionary *chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, weightLiftedContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '2' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateWeightLiftedLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateWeightLiftedTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Total Weight Lifted";
  chartTypeAlertTitleText = @"Total Weight Lifted Timeline Charts";
  chartTypeBackgroundColor = [UIColor bootstrapPrimarySemiClear];
  UIView *totalAggregateWeightTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeWeightLiftedLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Weight Lifted Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeWeightLiftedLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Weight Lifted"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:weightLiftedContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_WEIGHT_LIFTED_AVG_TIME;
  chartTitlePrefix = @"Average ";
  chartTitlePostfix = @" per Set";
  weightLiftedQualifier = @"per-set average of all your weight lifted";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                     calculateAverages:YES
                                                                calculateDistributions:NO
                                                                         chartIdPrefix:chartIdPrefix
                                                                    yaxisValueLabelBlk:[RAbstractChartController makeWeightYaxisLabelBlkIsPortraitMode:isPortraitMode]
                                                                           maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                             yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                     yaxisFormatterBlk:^(double maxValue) {
                                                                       return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                     }
                                                                       yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                          isPercentage:NO
                                                                      chartTitlePrefix:chartTitlePrefix
                                                                     chartTitlePostfix:chartTitlePostfix
                                                                  sectionHighlightText:@"your weight lifted per-set average"
                                                                 weightLiftedQualifier:weightLiftedQualifier
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
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, weightLiftedContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '2' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *avgWeightLiftedPerSetLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils avgWeightLiftedTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Average per Set";
  chartTypeAlertTitleText = @"Average Weight Lifted per Set Timeline Charts";
  UIView *avgWeightLiftedPerSetTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeWeightLiftedLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Avg Weight Lifted Trend"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeWeightLiftedLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Weight Lifted"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:YES];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:weightLiftedContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_WEIGHT_LIFTED_DIST;
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeWeightLiftedPieChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                            chartIdPrefix:chartIdPrefix
                                                                           relativeToView:relativeToView
                                                                          strengthConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                               controller:ctrlr
                                                                                 coordDao:self.coordDao
                                                                      chartConfigCategory:RChartConfigCategoryWeight
                                                                                uitoolkit:self.uitoolkit
                                                                            screenToolkit:self.screenToolkit
                                                                             panelToolkit:self.panelToolkit
                                                                                 headless:NO
                                                                                  logging:NO];
  };
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, weightLiftedContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](1); // '1' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *aggregateWeightLiftedPieChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils aggregateWeightLiftedPieChartsHelpDesc];
  chartTypeHeadingText = @"Distribution";
  chartTypeAlertTitleText = @"Weight Lifted Distribution Pie Charts";
  UIView *aggregateWeightLiftedPieChartTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeWeightLiftedDist
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Weight Lifted Pie"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeWeightLiftedDist, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Weight Lifted"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:NO
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:weightLiftedContentPanel
                                                    controller:self];
  chartIdPrefix = CHART_ID_PREFIX_WEIGHT_LIFTED_DIST_TIME;
  chartTitlePrefix = @"";
  chartTitlePostfix = @" Distribution";
  weightLiftedQualifier = @"percentage of all your weight lifted";
  makeChartAndLoaderTuples = ^(RChartDataFetchMode fetchMode, RAbstractChartController *ctrlr, UIView *relativeToView) {
    return [RAbstractChartController makeWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
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
                                                                  sectionHighlightText:@"how your total weight lifted distributes"
                                                                 weightLiftedQualifier:weightLiftedQualifier
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
  chartAndLoaderTuples = makeChartAndLoaderTuples([self fetchMode], self, weightLiftedContentPanel);
  chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](2); // '2' is for the 'all muscle groups' chart
  allMuscleGroupsChartIdAndTuple = chartAndLoaderTuples[chartId];
  chartAndLoaderTupleBlk = allMuscleGroupsChartIdAndTuple[1];
  chartAndLoaderTuple = chartAndLoaderTupleBlk();
  [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
  self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
  UIView *weightLiftedDistributionLineChartsCarousel = chartAndLoaderTuple.chartPanelView;
  chartTypeHelpDesc = [RUtils weightLiftedDistributionTimelineChartsHelpDesc];
  chartTypeHeadingText = @"Distribution / Time";
  chartTypeAlertTitleText = @"Weight Lifted Distribution Timeline Charts";
  UIView *weightLiftedDistributionTimelineTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:chartTypeHeadingText
                                                infoAlertTitle:chartTypeAlertTitleText
                                          infoAlertDescription:chartTypeHelpDesc
                                               backgroundColor:chartTypeBackgroundColor
                                              moreChartsAction:^(RAbstractChartController *homeController) {
                                                RChartsListController *ctrl =
                                                [[RChartsListController alloc] initWithStoreCoordinator:self.coordDao
                                                                                              fetchMode:RChartDataFetchModeWeightLiftedLine
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                            screenTitle:@"Weight Lifted Distribution"
                                                                                   strengthChartConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                              globalStrengthChartConfig:[self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()]
                                                                                      metricHeadingText:metricHeadingText
                                                                                 metricAlertDescription:metricDesc
                                                                                   chartTypeHeadingText:chartTypeHeadingText
                                                                                chartTypeAlertTitleText:chartTypeAlertTitleText
                                                                              chartTypeAlertDescription:chartTypeHelpDesc
                                                                               chartTypeBackgroundColor:chartTypeBackgroundColor
                                                                              chartAndLoaderTuplesMaker:^(RChartsListController *listCtrlr, UIView *relativeToView) {
                                                                                return makeChartAndLoaderTuples(RChartDataFetchModeWeightLiftedLine, listCtrlr, relativeToView);
                                                                              }
                                                                                   chartConfigTitlePart:@"Weight Lifted"
                                                                                       parentController:self
                                                                                    chartConfigCategory:[self chartConfigCategory]
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                        calcPercentages:YES
                                                                                           calcAverages:NO];
                                                [self.navigationController pushViewController:ctrl animated:YES];
                                              }
                                                relativeToView:weightLiftedContentPanel
                                                    controller:self];
  // make jump-to buttons panel
  NSArray *jumpToButtons = [self makeJumpToButtons];
  UIButton *jumpToTotalButton = jumpToButtons[0];
  UIButton *jumpToAvgButton = jumpToButtons[1];
  UIButton *jumpToDistButton = jumpToButtons[2];
  UIButton *jumpToDistTimeButton = jumpToButtons[3];
  UIView *jumpToPanel = [RAbstractChartController jumpPanelWithButtons:[[NSMutableArray alloc] initWithArray:@[jumpToTotalButton, jumpToAvgButton, jumpToDistButton, jumpToDistTimeButton]]
                                    relativeToView:weightLiftedContentPanel];
  // place the views
  CGFloat vpadding;
  CGFloat betweenHeadingPanelsVpadding = 2.5;
  CGFloat carouselVpadding = 12.0;
  // place 'Weight Lifted' content onto weightLiftedContentPanel
  vpadding = 0.0;
  [PEUIUtils placeView:weightLiftedMetricHeadingPanel
               atTopOf:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += weightLiftedMetricHeadingPanel.frame.size.height + vpadding;
  vpadding = betweenHeadingPanelsVpadding;
  [PEUIUtils placeView:jumpToPanel
                 below:weightLiftedMetricHeadingPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += jumpToPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:totalAggregateWeightTimelineTypeHeadingPanel
                 below:jumpToPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += totalAggregateWeightTimelineTypeHeadingPanel.frame.size.height + vpadding;
  vpadding = carouselVpadding;
  [PEUIUtils placeView:aggregateWeightLiftedLineChartsCarousel
                 below:totalAggregateWeightTimelineTypeHeadingPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += aggregateWeightLiftedLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgWeightLiftedPerSetTimelineTypeHeadingPanel
                 below:aggregateWeightLiftedLineChartsCarousel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += avgWeightLiftedPerSetTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:avgWeightLiftedPerSetLineChartsCarousel
                 below:avgWeightLiftedPerSetTimelineTypeHeadingPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += avgWeightLiftedPerSetLineChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateWeightLiftedPieChartTypeHeadingPanel
                 below:avgWeightLiftedPerSetLineChartsCarousel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += aggregateWeightLiftedPieChartTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:aggregateWeightLiftedPieChartsCarousel
                 below:aggregateWeightLiftedPieChartTypeHeadingPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += aggregateWeightLiftedPieChartsCarousel.frame.size.height + vpadding;
  [PEUIUtils placeView:weightLiftedDistributionTimelineTypeHeadingPanel
                 below:aggregateWeightLiftedPieChartsCarousel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += weightLiftedDistributionTimelineTypeHeadingPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:weightLiftedDistributionLineChartsCarousel
                 below:weightLiftedDistributionTimelineTypeHeadingPanel
                  onto:weightLiftedContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:weightLiftedContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightWeightLiftedContentPanel += weightLiftedDistributionLineChartsCarousel.frame.size.height + vpadding;
  totalHeightWeightLiftedContentPanel += carouselVpadding; // to give it some bottom-margin
  [PEUIUtils setFrameHeight:totalHeightWeightLiftedContentPanel ofView:weightLiftedContentPanel];

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // Reps and Time-Between-Sets Buttons
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  UIView *(^btnMaker)(NSString *, UIColor *, void(^)(void), NSString *) = ^ UIView * (NSString *title, UIColor *bgColor, void(^actionBlk)(void), NSString *msg) {
    UIButton *btn = [self.uitoolkit systemButtonMaker](title, nil, nil);
    [PEUIUtils setFrameWidthOfView:btn ofWidth:[PEUIUtils widthOfForContent] relativeTo:self.view];
    [PEUIUtils addDisclosureIndicatorToButton:btn color:[UIColor whiteColor]];
    [PEUIUtils setBackgroundColorOfButton:btn color:bgColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn bk_addEventHandler:^(id sender) {
      actionBlk();
    } forControlEvents:UIControlEventTouchUpInside];
    NSMutableAttributedString *attrMessage =
    [[NSMutableAttributedString  alloc] initWithString:msg];
    UIFont *fontForHeightCalculation = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    UIView *msgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                              fontForHeightCalculation:fontForHeightCalculation
                                                        relativeToView:relativeToView];
    return [PEUIUtils panelWithColumnOfViews:@[btn, msgPanel]
                 verticalPaddingBetweenViews:4.0
                              viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  };
  UIView *repsButtonAndMsgView = btnMaker(@"Reps",
                                          [UIColor greenBambooSemiClear],
                                          ^{ [self displayRepsScreen]; },
                                          @"View your reps charts.");
  UIView *timeBetweenSetsButtonAndMsgView = btnMaker(@"Rest Time",
                                                     [UIColor cochinealRedSemiClear],
                                                     ^{ [self displayTimeBetweenSetsScreen]; },
                                                     @"View your rest-time between sets charts.");
  UIView *bodyButtonAndMsgView = btnMaker(@"Your Body",
                                          [UIColor grayColor],
                                          ^{ [self displayBodyScreen]; },
                                          @"View your body measurement charts.");

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // Place all the main content panels on the subContentPanel
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  [PEUIUtils placeView:weightLiftedContentPanel
               atTopOf:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightSubContentPanel += weightLiftedContentPanel.frame.size.height;
  vpadding = 15.0;
  [PEUIUtils placeView:repsButtonAndMsgView
                 below:weightLiftedContentPanel
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContentPanel += repsButtonAndMsgView.frame.size.height + vpadding;
  [PEUIUtils placeView:timeBetweenSetsButtonAndMsgView
                 below:repsButtonAndMsgView
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContentPanel += timeBetweenSetsButtonAndMsgView.frame.size.height + vpadding;
  [PEUIUtils placeView:bodyButtonAndMsgView
                 below:timeBetweenSetsButtonAndMsgView
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContentPanel += bodyButtonAndMsgView.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeightSubContentPanel ofView:subContentPanel];
  
  // configure jump-to buttons
  [self configureJumpToButton:jumpToTotalButton contentPanel:subContentPanel headingPanel:totalAggregateWeightTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToAvgButton contentPanel:subContentPanel headingPanel:avgWeightLiftedPerSetTimelineTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistButton contentPanel:subContentPanel headingPanel:aggregateWeightLiftedPieChartTypeHeadingPanel];
  [self configureJumpToButton:jumpToDistTimeButton contentPanel:subContentPanel headingPanel:weightLiftedDistributionTimelineTypeHeadingPanel];
  
  return subContentPanel;
}

#pragma mark - Helpers

- (void)startNewSet {
  [self presentViewController:[PEUIUtils navigationControllerWithController:[self.screenToolkit newSelectBodySegmentScreenMaker]()
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (void)startNewBodyLog {
  [self presentViewController:[PEUIUtils navigationControllerWithController:[self.screenToolkit newSelectBodyPartScreenMaker]()
                                                        navigationBarHidden:NO]
                     animated:YES
                   completion:nil];
}

- (void)displayRepsScreen {
  [[self navigationController] pushViewController:[[RRepsController alloc] initWithStoreCoordinator:self.coordDao
                                                                                    userSettingsBlk:self.userSettingsBlk
                                                                                          uitoolkit:self.uitoolkit
                                                                                      screenToolkit:self.screenToolkit
                                                                                       panelToolkit:self.panelToolkit
                                                                                               user:self.user
                                                                            entitiesAndRawDataCache:self.entitiesAndRawDataCache]
                                         animated:YES];
}

- (void)displayTimeBetweenSetsScreen {
  [[self navigationController] pushViewController:[[RRestTimeController alloc] initWithStoreCoordinator:self.coordDao
                                                                                        userSettingsBlk:self.userSettingsBlk
                                                                                              uitoolkit:self.uitoolkit
                                                                                          screenToolkit:self.screenToolkit
                                                                                           panelToolkit:self.panelToolkit
                                                                                                   user:self.user
                                                                                entitiesAndRawDataCache:self.entitiesAndRawDataCache]
                                         animated:YES];
}

- (void)displayBodyScreen {
  [[self navigationController] pushViewController:[[RBodyController alloc] initWithStoreCoordinator:self.coordDao
                                                                                    userSettingsBlk:self.userSettingsBlk
                                                                                          uitoolkit:self.uitoolkit
                                                                                      screenToolkit:self.screenToolkit
                                                                                       panelToolkit:self.panelToolkit
                                                                                               user:self.user
                                                                            entitiesAndRawDataCache:self.entitiesAndRawDataCache]
                                         animated:YES];
}

- (void)displayWorkoutsScreenWithMuscleGroupsDict:(NSDictionary *)muscleGroupsDict {
  PEPageLoaderBlk pageLoader = ^ NSArray * (RWorkout *lastWorkout) {
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
    NSArray *muscles = [self.coordDao musclesWithError:errorBlk];
    NSArray *movements = [self.coordDao movementsWithError:errorBlk];    
    NSArray *descendingSets;
    NSInteger pageSize = 200;
    if (lastWorkout) {
      descendingSets = [self.coordDao descendingSetsForUser:user beforeLoggedAt:lastWorkout.startDate pageSize:pageSize error:errorBlk];
    } else {
      descendingSets = [self.coordDao descendingSetsForUser:user pageSize:pageSize error:errorBlk];
    }
    NSArray *workoutsTuple = [RUtils workoutsTupleForDescendingSets:descendingSets
                                                               user:user
                                                       userSettings:[self.coordDao userSettingsForUser:user error:errorBlk]
                                                   allMovementsDict:[RUtils dictFromMasterEntitiesArray:movements]
                                                allMuscleGroupsDict:muscleGroupsDict
                                                     allMusclesDict:[RUtils dictFromMasterEntitiesArray:muscles]
                                                           forWatch:NO
                                                           coordDao:self.coordDao
                                                              error:errorBlk];
    NSMutableArray *workouts = workoutsTuple[0];
    if (workouts.count > 1 && descendingSets.count == pageSize) {
      // because our sets are paginated, we don't know if the last workout element
      // in workouts array really represents a "full" workout (because, the sets
      // that came back may have been cutoff mid-workout); and therefore, we simply
      // blow away the last workout in the array
      [workouts removeLastObject];
    }
    return workouts;
  };
  UIFontTextStyle impactedMgLabelFontTextStyle = [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                           iphone6Width:UIFontTextStyleSubheadline
                                                                       iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                   ipad:UIFontTextStyleBody];
  CGFloat maxAllowedPointSizeImpactedMgLabels = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:22.0 ipad:26.0];
  UIFont *fontForHeightCalculation = [PEUIUtils boldFontWithMaxAllowedPointSize:maxAllowedPointSizeImpactedMgLabels
                                                                           font:[PEUIUtils boldFontForTextStyle:impactedMgLabelFontTextStyle]];
  CGFloat maxHeightOfImpactedMgLabel = [PEUIUtils sizeOfText:@"0" withFont:fontForHeightCalculation].height + 2; // plus 2 because of internal vertical spacing for the labels
  CGFloat (^cellHeightBlk)(RWorkout *) = ^CGFloat (RWorkout *workout) {
    BOOL hasEnergyComputed = workout.caloriesBurned != nil;
    NSInteger numImpactedMgs = workout.impactedMuscleGroupTuples.count;
    if (numImpactedMgs <= 3) {
      return [PEUIUtils valueIfiPhone5Width:hasEnergyComputed ? 100.0 : 90.0
                               iphone6Width:hasEnergyComputed ? 100.0 : 90.0
                           iphone6PlusWidth:hasEnergyComputed ? 110.0 : 95.0
                                       ipad:140.0
                                ipadPro12in:155.0];
    } else {
      return numImpactedMgs * // the number of labels
      maxHeightOfImpactedMgLabel + // height of each label
      (numImpactedMgs - 1) * 4.0 + // for the vertical padding in-between the labels
      40.0; // for some extra top/bottom margin
    }
  };
  NSInteger tableCellTagLeftPanel = 16;
  NSInteger tableCellTagRightPanel = 17;
  PETableCellContentViewStyler tableCellStyler = ^(UITableViewCell *cell, UIView *view, RWorkout *workout) {
    [[view viewWithTag:tableCellTagLeftPanel] removeFromSuperview];
    [[view viewWithTag:tableCellTagRightPanel] removeFromSuperview];
    UILabel *timeAgoLabel = [self.uitoolkit tableCellTitleMaker]([workout.startDate timeAgoSinceNow], view.frame.size.width);
    UILabel *(^makeSubLabel)(NSString *) = ^UILabel *(NSString *title) {
      return [PEUIUtils labelWithKey:title
                                font:[UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:11.0
                                                                                iphone6Width:12.0
                                                                            iphone6PlusWidth:14.0
                                                                                        ipad:18.0]]
                     backgroundColor:[UIColor clearColor]
                           textColor:[UIColor grayColor]
                 verticalTextPadding:2.0];
    };
    // left panel
    NSMutableArray *leftPanelSubLabels = [NSMutableArray array];
    [leftPanelSubLabels addObject:makeSubLabel([PEUtils stringFromDate:workout.startDate withPattern:DATE_PATTERN])];    
    NSString *durationValStr = [NSString stringWithFormat:@"%.1f", workout.durationSeconds / 60.0];
    [leftPanelSubLabels addObject:makeSubLabel([NSString stringWithFormat:@"%@ minute%@", durationValStr, [durationValStr isEqualToString:@"1"] ? @"" : @"s"])];
    if (workout.caloriesBurned) {
      [leftPanelSubLabels addObject:makeSubLabel([NSString stringWithFormat:@"%.1f kcal", workout.caloriesBurned.floatValue])];
    }
    UIView *leftPanelSubLabelsPanel = [PEUIUtils panelWithColumnOfViews:leftPanelSubLabels
                                            verticalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:2.0 iphone6Width:2.0 iphone6PlusWidth:3.0 ipad:5.0 ipadPro12in:5.0]
                                                         viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *leftPanel = [PEUIUtils panelWithColumnOfViews:@[timeAgoLabel, leftPanelSubLabelsPanel]
                              verticalPaddingBetweenViews:8.0
                                           viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    leftPanel.tag = tableCellTagLeftPanel;
    [PEUIUtils placeView:leftPanel inMiddleOf:view withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:25.0];
    // right panel
    NSMutableArray *impactedMuscleGroupPanels = [NSMutableArray arrayWithCapacity:workout.impactedMuscleGroupTuples.count];
    for (int i = 0; i < workout.impactedMuscleGroupTuples.count; i++) {
      NSArray *muscleGroupTuple = workout.impactedMuscleGroupTuples[i];
      NSNumber *muscleGroupId = muscleGroupTuple[0];
      NSDecimalNumber *percentageOfTotal = muscleGroupTuple[1];
      RMuscleGroup *muscleGroup = muscleGroupsDict[muscleGroupId];
      UIFont *font;
      UIColor *textColor;
      if (i == 0) {
        font = [PEUIUtils boldFontWithMaxAllowedPointSize:maxAllowedPointSizeImpactedMgLabels
                                                     font:[PEUIUtils boldFontForTextStyle:impactedMgLabelFontTextStyle]];
        textColor = [UIColor blackColor];
      } else {
        font = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSizeImpactedMgLabels
                                                 font:[UIFont preferredFontForTextStyle:impactedMgLabelFontTextStyle]];
        textColor = [UIColor grayColor];
      }
      [impactedMuscleGroupPanels addObject:[PEUIUtils labelWithKey:[NSString stringWithFormat:@"%@ - %.f%%", muscleGroup.name, percentageOfTotal.floatValue * 100.0]
                                                              font:font
                                                   backgroundColor:[UIColor clearColor]
                                                         textColor:textColor
                                               verticalTextPadding:2.0]];
    }
    UIView *rightPanel = [PEUIUtils panelWithColumnOfViews:impactedMuscleGroupPanels
                               verticalPaddingBetweenViews:4.0
                                            viewsAlignment:PEUIHorizontalAlignmentTypeRight];
    rightPanel.tag = tableCellTagRightPanel;
    [PEUIUtils placeView:rightPanel
              inMiddleOf:view
           withAlignment:PEUIHorizontalAlignmentTypeRight
                hpadding:25.0 + ([PEUIUtils iphoneXSafeInsetsSide] * 2)];
  };
  UIViewController *workoutsController =
  [[PEListViewController alloc] initWithClassOfDataSourceObjects:[RWorkout class]
                                                           title:@"Workouts"
                                           isPaginatedDataSource:YES
                                                 tableCellStyler:tableCellStyler
                                              itemSelectedAction:nil
                                             initialSelectedItem:nil
                                                   addItemAction:nil
                                                  cellIdentifier:@"RWorkoutCell"
                                                  initialObjects:nil // deprecated
                                                      pageLoader:pageLoader
                                                   cellHeightBlk:cellHeightBlk
                                                 detailViewMaker:nil
                                                       uitoolkit:self.uitoolkit
                                  doesEntityBelongToThisListView:^BOOL(PELMMainSupport *entity){return YES;}
                                            wouldBeIndexOfEntity:nil
                                                 isAuthenticated:nil
                                                  isUserLoggedIn:nil
                                                    isBadAccount:nil
                                             itemChildrenCounter:nil
                                             itemChildrenMsgsBlk:nil
                                                     itemDeleter:nil
                                                itemLocalDeleter:nil
                                                    isEntityType:NO
                                                viewDidAppearBlk:nil
                                     entityAddedNotificationName:nil
                                   entityUpdatedNotificationName:nil
                                   entityRemovedNotificationName:nil
                                                  tableViewStyle:UITableViewStylePlain
                                                   rowsInSection:nil
                                         titleForHeaderInSection:nil
                                              dataObjectAccessor:nil
                                                     cancellable:NO];
  [[self navigationController] pushViewController:workoutsController animated:YES];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                      relativeToView:self.view
                                         fixedHeight:0.0];
  // because none of the charts we display on the home page feature individual
  // muscles, we don't need to load the muscles and muscle colors (although
  // we do on the charts list screen)
  [self configureColors];
  // make views
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
  CGFloat totalHeightSubContent = 0.0;
  UIView *mainContentPanel = nil;
  if (self.isRepaintDueToNonDataChange) {
    // only skip main panel re-gen if this repaint was due to user changing the
    // status of the segmented control, or some other non-data change, such
    // as displaying offline mode banner or maintenance banner (and of course the
    // panels are not currently null)
    if (self.yourContentPanel == nil) {
      self.yourContentPanel = [self yourContentRelativeToView:contentPanel];
    }
  } else {
    self.yourContentPanel = [self yourContentRelativeToView:contentPanel];
  }
  mainContentPanel = self.yourContentPanel;
  CGFloat vpadding;
  // place movements search bar
  [subContentPanel setTag:RCONTENT_PANEL_TAG];
  UISearchBar *movementSearchBar = [RUIUtils movementSearchBarWithDelegate:self relativeToView:subContentPanel];
  vpadding = -2.0;
  [PEUIUtils placeView:movementSearchBar atTopOf:subContentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeightSubContent += movementSearchBar.frame.size.height + vpadding;
  UIButton *(^btnMaker1)(NSString *, SEL) = ^ UIButton * (NSString *title, SEL action) {
    UIButton *btn = [PEUIUtils buttonWithKey:title
                                        font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:38.0 iphone6Width:40.0 iphone6PlusWidth:40.0 ipad:44.0]
                                                                               font:[PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]]]
                             backgroundColor:[UIColor bootstrapPrimary]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:[PEUIUtils valueIfiPhone5Width:16.0 iphone6Width:16.0 iphone6PlusWidth:20.0 ipad:24.0]
                           horizontalPadding:[PEUIUtils valueIfiPhone5Width:16.0 iphone6Width:22.0 iphone6PlusWidth:28.0 ipad:34]
                                cornerRadius:5.0
                                      target:self
                                      action:action];
    return btn;
  };
  UIButton *newSetButton = btnMaker1(@"New Set", @selector(startNewSet));
  UIButton *newBodyLogButton = btnMaker1(@"New Body Log", @selector(startNewBodyLog));
  UIView *newSetAndBodyLogBtnPanel = [PEUIUtils panelWithRowOfViews:@[newSetButton, newBodyLogButton]
                                      horizontalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:10.0 iphone6PlusWidth:12.0 ipad:16.0]
                                                     viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  UIButton *(^btnMaker2)(NSString *, UIColor *, SEL) = ^ UIButton * (NSString *title, UIColor *bgColor, SEL action) {
    UIButton *btn = [PEUIUtils buttonWithKey:title
                                        font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:32.0 iphone6Width:34.0 iphone6PlusWidth:34.0 ipad:38.0]
                                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                             backgroundColor:bgColor
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:[PEUIUtils valueIfiPhone5Width:14.0 iphone6Width:14.0 iphone6PlusWidth:18.0 ipad:26.0]
                           horizontalPadding:[PEUIUtils valueIfiPhone5Width:16.0 iphone6Width:20.0 iphone6PlusWidth:26.0 ipad:32]
                                cornerRadius:5.0
                                      target:self
                                      action:action];
    return btn;
  };
  UIButton *viewWorkoutsButton = btnMaker2(@"Workouts", [UIColor grayColor], nil);
  [viewWorkoutsButton bk_addEventHandler:^(id sender) {
    NSArray *muscleGroups = [self.coordDao muscleGroupsWithError:errorBlk];
    [self displayWorkoutsScreenWithMuscleGroupsDict:[RUtils dictFromMasterEntitiesArray:muscleGroups]];
  }
                        forControlEvents:UIControlEventTouchUpInside];
  UIButton *repsBtn = btnMaker2(@"Reps", [UIColor greenBambooSemiClear], @selector(displayRepsScreen));
  UIButton *restTimeBtn = btnMaker2(@"Rest Time", [UIColor cochinealRedSemiClear], @selector(displayTimeBetweenSetsScreen));
  UIButton *bodyBtn = btnMaker2(@"Your Body", [UIColor grayColor], @selector(displayBodyScreen));
  UIView *repsAndTimeBetweenSetsBtnsPanel = [PEUIUtils panelWithRowOfViews:@[repsBtn, restTimeBtn, bodyBtn, viewWorkoutsButton]
                                             horizontalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:10.0 iphone6PlusWidth:12.0 ipad:16.0]
                                                            viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
  if (repsAndTimeBetweenSetsBtnsPanel.frame.size.width > subContentPanel.frame.size.width) {
    repsAndTimeBetweenSetsBtnsPanel = [PEUIUtils panelWithRowOfViews:@[[PEUIUtils panelWithColumnOfViews:@[repsBtn, restTimeBtn] verticalPaddingBetweenViews:10.0 viewsAlignment:PEUIHorizontalAlignmentTypeRight],
                                                                       [PEUIUtils panelWithColumnOfViews:@[bodyBtn, viewWorkoutsButton] verticalPaddingBetweenViews:10.0 viewsAlignment:PEUIHorizontalAlignmentTypeLeft]]
                                       horizontalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:10.0 iphone6PlusWidth:12.0 ipad:16.0]
                                                      viewsAlignment:PEUIVerticalAlignmentTypeMiddle];
    if (repsAndTimeBetweenSetsBtnsPanel.frame.size.width > subContentPanel.frame.size.width) {
      // one last shot at making them fit
      repsAndTimeBetweenSetsBtnsPanel = [PEUIUtils panelWithColumnOfViews:@[repsBtn, restTimeBtn, bodyBtn, viewWorkoutsButton]
                                              verticalPaddingBetweenViews:10.0
                                                           viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
    }
  }
  // place the views
  vpadding = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:12.0 iphone6PlusWidth:12.0 ipad:16.0];
  [PEUIUtils placeView:newSetAndBodyLogBtnPanel
                 below:movementSearchBar
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:subContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContent += newSetAndBodyLogBtnPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:repsAndTimeBetweenSetsBtnsPanel
                 below:newSetAndBodyLogBtnPanel
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:subContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContent += repsAndTimeBetweenSetsBtnsPanel.frame.size.height + vpadding;
  [PEUIUtils placeView:mainContentPanel
                 below:repsAndTimeBetweenSetsBtnsPanel
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:subContentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContent += mainContentPanel.frame.size.height + vpadding;
  // set height and place sub-content panel
  [PEUIUtils setFrameHeight:totalHeightSubContent ofView:subContentPanel];
  CGFloat topViewVpadding;
  CGFloat (^adjustForOfflineMode)(UIView *, CGFloat) = ^CGFloat (UIView *view, CGFloat addlAdjust) {
    UIView *offlineLabel = [PEUIUtils offlineModeLabelWithController:self];
    if (offlineLabel) {
      self.adjustedViewsForOfflineMode = YES;
      CGFloat adjustment = offlineLabel.frame.size.height + addlAdjust;
      [PEUIUtils adjustYOfView:view withValue:adjustment];
      return adjustment;
    }
    return 0.0;
  };
  if ([user isInMaintenanceWindow]) {
    UIView *topView = [RPanelToolkit maintenanceInProgressNavbarPanelForUser:user relativeToView:contentPanel controller:self];
    topViewVpadding = 0.0;
    self.maintenanceNoticeAdded = YES;
    self.unAckdUpcomingMaintenanceNoticeAdded = NO;
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:topView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(topView, 0.0);
    totalHeight += topView.frame.size.height + topViewVpadding;
    [PEUIUtils placeView:subContentPanel below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
    totalHeight += subContentPanel.frame.size.height + 0.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  } else if ([user hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:[APP maintenanceAckAt]]) {
    UIView *topView = [RPanelToolkit upcomingMaintenanceNavbarPanelForUser:user
                                                            relativeToView:contentPanel
                                                                controller:self
                                                       navBannerRemovedBlk:^(CGFloat bannerPanelHeight) {
                                                         [UIView animateWithDuration:0.25
                                                                               delay:0.00
                                                                             options:UIViewAnimationOptionCurveEaseInOut
                                                                          animations:^{
                                                                            [PEUIUtils adjustYOfView:subContentPanel withValue:(-1 * bannerPanelHeight)];
                                                                          }
                                                                          completion:nil];
                                                         self.unAckdUpcomingMaintenanceNoticeAdded = NO;
                                                       }];
    self.maintenanceNoticeAdded = NO;
    self.unAckdUpcomingMaintenanceNoticeAdded = YES;
    topViewVpadding = 0.0;
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:topView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(topView, 0.0);
    totalHeight += topView.frame.size.height + topViewVpadding;
    [PEUIUtils placeView:subContentPanel below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
    totalHeight += subContentPanel.frame.size.height + 0.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  } else {
    self.maintenanceNoticeAdded = NO;
    self.unAckdUpcomingMaintenanceNoticeAdded = NO;
    CGFloat totalHeight = 0.0;
    topViewVpadding = 2.5;
    [PEUIUtils placeView:subContentPanel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(subContentPanel, -1.0);
    totalHeight += subContentPanel.frame.size.height + topViewVpadding;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  }
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Chart Loading

- (RChartDataFetchMode)fetchMode {
  return RChartDataFetchModeWeightLiftedCrossSection;
}

#pragma mark - Chart Config Helpers

- (NSString *)globalChartConfigSettingsTitlePart {
  return @"Weight Lifted";
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  void (^populateChartConfigs)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *) = [self populateChartConfigsBlkWithGlobalConfig:globalConfig];
  void (^populateStrengthChartConfigs)(NSString *) = ^(NSString *chartIdPrefix) {
    populateChartConfigs(^(NSString *chartId, RChartConfig *chartConfig) {
      [self.coordDao saveNewOrExistingByChartIdChartConfig:chartConfig forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    }, MAX_STRENGTH_CHARTS_PER_PREFIX, chartIdPrefix);
  };
  populateStrengthChartConfigs(CHART_ID_PREFIX_WEIGHT_LIFTED_DIST);
  populateStrengthChartConfigs(CHART_ID_PREFIX_WEIGHT_LIFTED_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_WEIGHT_LIFTED_AVG_TIME);
  populateStrengthChartConfigs(CHART_ID_PREFIX_WEIGHT_LIFTED_DIST_TIME);
  [self.entitiesAndRawDataCache removeAllObjects];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[self.uitoolkit colorForWindows]];
  if (@available(iOS 10.3, *)) {
    if ([[APP firstLaunchAt] daysAgo] >= 30) {
      [SKStoreReviewController requestReview];
    }
  }
}

- (void)viewDidAppear:(BOOL)animated {
  void (^triggerRepaint)(void) = ^{
    self.isRepaintDueToNonDataChange = YES;
    self.needsRepaint = YES;
    [APP refreshTabs];
  };
  PELMUser *user = (PELMUser *)[self.coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
  if ([user isInMaintenanceWindow]) {
    if (!self.maintenanceNoticeAdded) {
      triggerRepaint();
    }
  } else if ([user hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:[APP maintenanceAckAt]]) {
    if (!self.unAckdUpcomingMaintenanceNoticeAdded) {
      triggerRepaint();
    }
  } else {
    if (self.maintenanceNoticeAdded || self.unAckdUpcomingMaintenanceNoticeAdded) {
      triggerRepaint();
    }
  }
  if ([APP offlineMode]) { // because we don't want the search bar to be covered by the offline mode bar
    if (!self.adjustedViewsForOfflineMode) {
      triggerRepaint();
    }
  } else { // offline mode was turned off
    if (self.adjustedViewsForOfflineMode) {
      triggerRepaint();
      self.adjustedViewsForOfflineMode = NO;
    }
  }
  [super viewDidAppear:animated];
  [RUIUtils movementSearchBarViewDidLoadHandlerWithController:self
                                        movementSearchResults:self.movementSearchResults];
}

@end
