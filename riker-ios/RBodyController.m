//
//  RBodyController.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RBodyController.h"
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
#import "RChartBodyRawData.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"

@implementation RBodyController {
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
                             screenTitle:@"Your Body"
                                    user:user
                 entitiesAndRawDataCache:entitiesAndRawDataCache];
  
  if (self) {
    self.calcAverages = NO;
    self.calcPercentages = NO;
  }
  return self;
}

- (NSDate *)veryFirstLoggedAt {
  return self.veryFirstBmlLoggedAt;
}

- (NSDate *)veryLastLoggedAt {
  return self.veryLastBmlLoggedAt;
}

#pragma mark - Your Body Content

- (UIView *)yourContentRelativeToView:(UIView *)relativeToView {
  self.chartAndLoaderTuplesArray = [NSMutableArray array];
  self.chartAndLoaderTuples = [NSMutableDictionary dictionary];
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  CGFloat totalHeightSubContentPanel = 0.0;
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // 'Body' views
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  UIView *bodyMeasurementsContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:subContentPanel fixedHeight:0.0];
  __block CGFloat totalHeightBodyMeasurementsContentPanel = 0.0;
  NSString *bodyMeasurementsHeadingText = @"Your Body";
  UIView *bodyMeasurementsMetricHeadingPanel =
  [RAbstractChartController makeMetricTypeHeadingPanelWithTitle:bodyMeasurementsHeadingText
                                                 infoAlertTitle:bodyMeasurementsHeadingText
                                           infoAlertDescription:nil
                                                 settingsAction:^{ [self globalChartConfigSettingsCalcPercentages:self.calcPercentages
                                                                                                     calcAverages:self.calcAverages]; }
                                                 relativeToView:bodyMeasurementsContentPanel
                                                     controller:self
                                       chartReloadButtonHandler:^{
                                         [self loadChartsWithCompletion:nil
                                              showAlertIfAlreadyLoading:YES
                                                               headless:NO
                                                        calcPercentages:self.calcPercentages
                                                           calcAverages:self.calcAverages];
                                       }];
  __block CGFloat vpadding;
  CGFloat betweenHeadingPanelsVpadding = 2.5;
  CGFloat carouselVpadding = 12.0;
  vpadding = 0.0;
  [PEUIUtils placeView:bodyMeasurementsMetricHeadingPanel
               atTopOf:bodyMeasurementsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightBodyMeasurementsContentPanel += bodyMeasurementsMetricHeadingPanel.frame.size.height + vpadding;
  UIView *(^buildAndPlaceHeadingPanelAndCarousel)(UIView *, CGFloat, NSMutableDictionary *(^)(RChartBodyRawData *), NSString *, NSString *, UIColor *, UIColor *, NSString *(^)(RUserSettings *, double), RUomDisplayBlk, UIButton *, BOOL) =
  ^UIView * (UIView *topView, CGFloat topViewVpadding, NSMutableDictionary *(^timeSeriesDictBlk)(RChartBodyRawData *), NSString *chartTitle, NSString *chartIdPrefix, UIColor *headingPanelColor, UIColor *lineColor, NSString *(^yaxisValueLabelBlk)(RUserSettings *, double), RUomDisplayBlk uomDisplayBlk, UIButton *jumpToButton, BOOL logging) {    
    NSDictionary *chartAndLoaderTuples =
    [RAbstractChartController makeBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:timeSeriesDictBlk
                                                                                              chartTitle:chartTitle
                                                                                           chartIdPrefix:chartIdPrefix
                                                                                               lineColor:lineColor
                                                                                      yaxisValueLabelBlk:yaxisValueLabelBlk
                                                                                             maxValueBlk:^(RNormalizedTimeSeriesTupleCollection *dataEntries) { return dataEntries.maxAvgAggregateValue; }
                                                                                               yvalueBlk:^(RNormalizedLineChartDataEntry *dataEntry) { return dataEntry.avgAggregateValue; }
                                                                                       yaxisFormatterBlk:^(double maxValue) {
                                                                                         return [[RNumberValueFormatter alloc] initWithScalingFactor:[RAbstractChartController yaxisScalingFactorForMaxValue:maxValue]];
                                                                                       }
                                                                                         yaxisMaximumBlk:^(double maxValue) { return maxValue * 1.05; }
                                                                                          relativeToView:bodyMeasurementsContentPanel
                                                                                             bodyConfigs:^(NSString *chartId) { return [self.coordDao chartConfigWithChartId:chartId user:self.user error:[RUtils localFetchErrorHandlerMaker]()]; }
                                                                                            isPercentage:NO
                                                                                           uomDisplayBlk:uomDisplayBlk
                                                                                              controller:self
                                                                                       chartViewDelegate:self
                                                                                               uitoolkit:self.uitoolkit
                                                                                           screenToolkit:self.screenToolkit
                                                                                            panelToolkit:self.panelToolkit
                                                                                                coordDao:self.coordDao
                                                                                                headless:NO
                                                                                 entitiesAndRawDataCache:self.entitiesAndRawDataCache
                                                                                         calcPercentages:self.calcPercentages
                                                                                            calcAverages:self.calcAverages
                                                                                                 logging:logging];    
    NSString *chartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix](0);
    NSArray *chartIdAndTuple = chartAndLoaderTuples[chartId];
    RChartAndLoaderTuple *(^chartAndLoaderTupleBlk)(void) = chartIdAndTuple[1];
    RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTupleBlk();
    [self.chartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
    self.chartAndLoaderTuples[chartId] = chartAndLoaderTuple;
    UIView *carousel = chartAndLoaderTuple.chartPanelView;
    NSString *chartTitleLowercase = [chartTitle lowercaseString];
    NSMutableAttributedString *chartsHelpDesc = [[NSMutableAttributedString alloc] init];
    [chartsHelpDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"The %@ timeline chart illustrates your %%@.", chartTitleLowercase]
                                                                    textToAccent:[NSString stringWithFormat:@"%@ over time", chartTitleLowercase]
                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    UIView *timelineTypeHeadingPanel =
    [RAbstractChartController makeChartTypeHeadingPanelWithTitle:[NSString stringWithFormat:@"%@ Timeline", chartTitle]
                                                  infoAlertTitle:[NSString stringWithFormat:@"%@ Timeline", chartTitle]
                                            infoAlertDescription:chartsHelpDesc
                                                 backgroundColor:headingPanelColor
                                                moreChartsAction:nil
                                                  relativeToView:bodyMeasurementsContentPanel
                                                      controller:self];
    vpadding = topViewVpadding;
    [PEUIUtils placeView:timelineTypeHeadingPanel
                   below:topView
                    onto:bodyMeasurementsContentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:bodyMeasurementsContentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeightBodyMeasurementsContentPanel += timelineTypeHeadingPanel.frame.size.height + vpadding;
    vpadding = carouselVpadding;
    [PEUIUtils placeView:carousel
                   below:timelineTypeHeadingPanel
                    onto:bodyMeasurementsContentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:bodyMeasurementsContentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeightBodyMeasurementsContentPanel += carousel.frame.size.height + vpadding;
    [self configureJumpToButton:jumpToButton contentPanel:subContentPanel headingPanel:timelineTypeHeadingPanel];
    return carousel;
  };
  UIButton *(^makeJumpButton)(NSString *) = [RAbstractChartController jumpButtonMaker];
  UIButton *jumpToBodyWeightButton = makeJumpButton(@"body weight");
  UIButton *jumpToArmSizeButton = makeJumpButton(@"arms");
  UIButton *jumpToChestSizeButton = makeJumpButton(@"chest");
  UIButton *jumpToCalfSizeButton = makeJumpButton(@"calfs");
  UIButton *jumpToThighSizeButton = makeJumpButton(@"thighs");
  UIButton *jumpToForearmSizeButton = makeJumpButton(@"forearms");
  UIButton *jumpToWaistSizeButton = makeJumpButton(@"waist");
  UIButton *jumpToNeckSizeButton = makeJumpButton(@"neck");
  UIView *jumpToPanel = [RAbstractChartController jumpPanelWithButtons:[[NSMutableArray alloc] initWithArray:@[jumpToBodyWeightButton, jumpToArmSizeButton, jumpToChestSizeButton, jumpToCalfSizeButton, jumpToThighSizeButton, jumpToForearmSizeButton, jumpToWaistSizeButton, jumpToNeckSizeButton]]
                                    relativeToView:bodyMeasurementsContentPanel];
  // create and place body measurement panel/carousel pairs
  [PEUIUtils placeView:jumpToPanel
                 below:bodyMeasurementsMetricHeadingPanel
                  onto:bodyMeasurementsContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:bodyMeasurementsContentPanel
              vpadding:betweenHeadingPanelsVpadding
              hpadding:0.0];
  totalHeightBodyMeasurementsContentPanel += jumpToPanel.frame.size.height + betweenHeadingPanelsVpadding;
  BOOL isPortaitMode = [PEUIUtils isPortraitMode];
  UIView *topView =
  buildAndPlaceHeadingPanelAndCarousel(jumpToPanel,
                                       betweenHeadingPanelsVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.bodyWeightTimeSeries; },
                                       @"Body Weight",
                                       CHART_ID_PREFIX_BODY_WEIGHT,
                                       [UIColor colorWithRed:93/255.0 green:63/255.0 blue:106/255.0 alpha:0.5], // bellflower color
                                       [UIColor colorWithRed:93/255.0 green:63/255.0 blue:106/255.0 alpha:1.0],
                                       [RAbstractChartController makeWeightYaxisLabelBlkIsPortraitMode:isPortaitMode],
                                       ^(RUserSettings *userSettings) { return [RUtils weightUnitNameForUomId:userSettings.weightUom]; },
                                       jumpToBodyWeightButton,
                                       NO);
  NSString *(^yaxisSizeLabelBlk)(RUserSettings *, double) = [RAbstractChartController makeSizeYaxisLabelBlkIsPortraitMode:isPortaitMode];
  RUomDisplayBlk sizeUomDisplayBlk = ^(RUserSettings *userSettings) { return [RUtils sizeUnitNameForUomId:userSettings.sizeUom]; };
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.armSizeTimeSeries; },
                                       @"Arm Size",
                                       CHART_ID_PREFIX_ARM_SIZE,
                                       [UIColor colorWithRed:0/255.0 green:49/255.0 blue:113/255.0 alpha:0.5], // navy blue color
                                       [UIColor colorWithRed:0/255.0 green:49/255.0 blue:113/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToArmSizeButton,
                                       NO);
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.chestSizeTimeSeries; },
                                       @"Chest Size",
                                       CHART_ID_PREFIX_CHEST_SIZE,
                                       [UIColor colorWithRed:202/255.0 green:105/255.0 blue:36/255.0 alpha:0.5], // amber
                                       [UIColor colorWithRed:202/255.0 green:105/255.0 blue:36/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToChestSizeButton,
                                       NO);
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.calfSizeTimeSeries; },
                                       @"Calf Size",
                                       CHART_ID_PREFIX_CALF_SIZE,
                                       [UIColor colorWithRed:161/255.0 green:121/255.0 blue:23/255.0 alpha:0.5], // rapeseed oil
                                       [UIColor colorWithRed:161/255.0 green:121/255.0 blue:23/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToCalfSizeButton,
                                       NO);
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.thighSizeTimeSeries; },
                                       @"Thigh Size",
                                       CHART_ID_PREFIX_THIGH_SIZE,
                                       [UIColor colorWithRed:46/255.0 green:204/255.0 blue:113/255.0 alpha:0.5], // emerald
                                       [UIColor colorWithRed:46/255.0 green:204/255.0 blue:113/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToThighSizeButton,
                                       NO);
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.forearmSizeTimeSeries; },
                                       @"Forearm Size",
                                       CHART_ID_PREFIX_FOREARM_SIZE,
                                       [UIColor colorWithRed:242/255.0 green:38/255.0 blue:19/255.0 alpha:0.5], // pomegranate
                                       [UIColor colorWithRed:242/255.0 green:38/255.0 blue:19/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToForearmSizeButton,
                                       NO);
  topView =
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.waistSizeTimeSeries; },
                                       @"Waist Size",
                                       CHART_ID_PREFIX_WAIST_SIZE,
                                       [UIColor colorWithRed:142/255.0 green:68/255.0 blue:173/255.0 alpha:0.5], // studio
                                       [UIColor colorWithRed:142/255.0 green:68/255.0 blue:173/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToWaistSizeButton,
                                       NO);
  buildAndPlaceHeadingPanelAndCarousel(topView,
                                       carouselVpadding,
                                       ^(RChartBodyRawData *chartData) { return chartData.neckSizeTimeSeries; },
                                       @"Neck Size",
                                       CHART_ID_PREFIX_NECK_SIZE,
                                       [UIColor colorWithRed:44/255.0 green:62/255.0 blue:80/255.0 alpha:0.5], // midnight blue
                                       [UIColor colorWithRed:44/255.0 green:62/255.0 blue:80/255.0 alpha:1.0],
                                       yaxisSizeLabelBlk,
                                       sizeUomDisplayBlk,
                                       jumpToNeckSizeButton,
                                       NO);
  
  totalHeightBodyMeasurementsContentPanel += carouselVpadding; // to give it some bottom-margin
  [PEUIUtils setFrameHeight:totalHeightBodyMeasurementsContentPanel ofView:bodyMeasurementsContentPanel];  
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  // Place all the main content panels on the subContentPanel
  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
  [PEUIUtils placeView:bodyMeasurementsContentPanel
               atTopOf:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:0.0
              hpadding:0.0];
  totalHeightSubContentPanel += bodyMeasurementsContentPanel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeightSubContentPanel ofView:subContentPanel];
  return subContentPanel;
}

#pragma mark - Chart Settings Notification Handling

- (void)chartSettingsClearedNotification:(NSNotification *)notification {
  [super chartSettingsClearedNotification:notification];
  NSDictionary *userInfo = notification.userInfo;
  RChartConfigCategory chartConfigCategory = ((NSNumber *)userInfo[@"chartCategory"]).integerValue;
  if (chartConfigCategory == [self chartConfigCategory]) {
    [self.coordDao deleteChartConfigByChartId:userInfo[@"chartId"] user:self.user error:[RUtils localSaveErrorHandlerMaker]()];
  }
}

- (void)chartSettingsDoneNotification:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  RChartConfigCategory chartConfigCategory = ((NSNumber *)userInfo[@"chartCategory"]).integerValue;
  if (chartConfigCategory == [self chartConfigCategory]) {
    NSString *chartId = userInfo[@"chartId"];
    [self.coordDao saveNewOrExistingByChartIdChartConfig:userInfo[@"chartConfig"] forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    [self chartSettingsDidChangeForChartId:chartId];
  }
}

#pragma mark - Chart Config Helpers

- (RChartConfigCategory)chartConfigCategory {
  return RChartConfigCategoryBody;
}

- (NSString *)globalChartConfigSettingsTitlePart {
  return @"Body Measurement";
}

- (NSString *)globalChartConfigSettingsEntityType {
  return @"body log";
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  void (^populateChartConfigs)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *) = [self populateChartConfigsBlkWithGlobalConfig:globalConfig];
  void (^populateBodyChartConfigs)(NSString *) = ^(NSString *chartIdPrefix) {
    populateChartConfigs(^(NSString *chartId, RChartConfig *chartConfig) {
      [self.coordDao saveNewOrExistingByChartIdChartConfig:chartConfig forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    }, MAX_BODY_CHARTS_PER_PREFIX, chartIdPrefix);
  };
  populateBodyChartConfigs(CHART_ID_PREFIX_BODY_WEIGHT);
  populateBodyChartConfigs(CHART_ID_PREFIX_NECK_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_ARM_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_THIGH_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_WAIST_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_FOREARM_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_CHEST_SIZE);
  populateBodyChartConfigs(CHART_ID_PREFIX_CALF_SIZE);
  [self.entitiesAndRawDataCache removeAllObjects];
}

- (void)settingsDidChangeForChartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                                      fetchMode:(RChartDataFetchMode)__not_used__ {
  if (chartAndLoaderTuple.progressHud) {
    [chartAndLoaderTuple.progressHud hideAnimated:NO];
  }
  UIView *viewForHudDisplay = [RAbstractChartController viewForHudDisplayForTuple:chartAndLoaderTuple];
  chartAndLoaderTuple.progressHud = [MBProgressHUD showHUDAddedTo:viewForHudDisplay animated:YES];
  [viewForHudDisplay bringSubviewToFront:chartAndLoaderTuple.progressHud];
  [RAbstractChartController configureChartLoadingHud:chartAndLoaderTuple.progressHud];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
    RUserSettings *userSettings = [self.coordDao userSettingsForUser:user error:errorBlk];
    dispatch_async(dispatch_get_main_queue(), ^{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *bmls = [self.coordDao ascendingBmlsForUser:user error:errorBlk];
        RSet *firstBml = [bmls firstObject];
        RSet *lastBml = [bmls lastObject];
        self.veryLastBmlLoggedAt = lastBml.loggedAt;
        self.veryFirstBmlLoggedAt = firstBml.loggedAt;
        dispatch_async(dispatch_get_main_queue(), ^{
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *onOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:self.veryLastBmlLoggedAt];
            NSDate *onOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:[self veryFirstBmlLoggedAt]] dateByAddingDays:1];
            RChartBodyRawData *bodychartData =
            [RUtils chartBodyDataForUser:user userSettings:userSettings bmls:bmls];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (chartAndLoaderTuple.lineChartDataLoader) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                  NSArray *result = chartAndLoaderTuple.lineChartDataLoader(bodychartData,
                                                                            user,
                                                                            userSettings,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            nil,
                                                                            onOrAfterLoggedAt,
                                                                            onOrBeforeLoggedAt);
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleLineChartResult:result chartAndLoaderTuple:chartAndLoaderTuple userSettings:userSettings animateSettingsButton:YES];
                  });
                });
              } else if (chartAndLoaderTuple.pieChartDataLoader) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                  NSArray *result = chartAndLoaderTuple.pieChartDataLoader(bodychartData,
                                                                           user,
                                                                           userSettings,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil,
                                                                           nil);
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self handlePieChartResult:result chartAndLoaderTuple:chartAndLoaderTuple animateSettingsButton:YES];
                  });
                });
              }
            });
          });
        });
      });
    });
  });
}

#pragma mark - Chart Loading

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages {
  if (!self.areTheChartsLoading || self.deviceWasRotated) {
    self.areTheChartsLoading = YES;
    [self enableAllChartLoadingHudsForTuples:self.chartAndLoaderTuplesArray];
    void (^allDoneBlk)(NSInteger, NSInteger) = ^(NSInteger numBmls, NSInteger numDaysOfBmls) {
      self.animateAllSettingsButtons = NO;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RCHART_ANIMATION_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.areTheChartsLoading = NO;
      });
      if (numBmls > 0 && numDaysOfBmls == 0) {
        [self maybeShow32bitIphoneLineChartMsg];
      }
      if (completion) {
        completion();
      }
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
      RUserSettings *userSettings = [self.coordDao userSettingsForUser:user error:errorBlk];
      NSArray *bmls = [self.coordDao ascendingBmlsForUser:user error:errorBlk];
      RBodyMeasurementLog *firstBml = [bmls firstObject];
      RBodyMeasurementLog *lastBml = [bmls lastObject];
      NSInteger numDaysOfBmls = [lastBml.loggedAt daysLaterThan:firstBml.loggedAt];
      self.veryLastBmlLoggedAt = lastBml.loggedAt;
      self.veryFirstBmlLoggedAt = firstBml.loggedAt;
      dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          RChartBodyRawData *bodyChartData =
          [RUtils chartBodyDataForUser:user userSettings:userSettings bmls:bmls];
          NSDate *veryFirstBmlOnOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:self.veryFirstBmlLoggedAt];
          NSDate *veryLastBmlOnOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:self.veryLastBmlLoggedAt] dateByAddingDays:1];
          dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger numBodyTuples = self.chartAndLoaderTuplesArray.count;
            NSInteger totalNumTuplesToProcess = numBodyTuples;
            __block NSInteger totalTuplesProcessed = 0;
            void (^processTuples)(NSArray *, id, NSDate *, NSDate *) = ^(NSArray *chartAndLoaderTuples, id chartData, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt) {
              NSInteger numTuples = chartAndLoaderTuples.count;
              for (NSInteger i = 0; i < numTuples; i++) {
                RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTuples[i];
                if (chartAndLoaderTuple.lineChartDataLoader) {
                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSArray *result = chartAndLoaderTuple.lineChartDataLoader(chartData,
                                                                              user,
                                                                              userSettings,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              nil,
                                                                              onOrAfterLoggedAt,
                                                                              onOrBeforeLoggedAt);
                    dispatch_async(dispatch_get_main_queue(), ^{
                      totalTuplesProcessed++;
                      [self handleLineChartResult:result
                              chartAndLoaderTuple:chartAndLoaderTuple
                                     userSettings:userSettings
                            animateSettingsButton:self.animateAllSettingsButtons];
                      if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(bmls.count, numDaysOfBmls); }
                    });
                  });
                } else if (chartAndLoaderTuple.pieChartDataLoader) {
                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSArray *result = chartAndLoaderTuple.pieChartDataLoader(chartData,
                                                                             user,
                                                                             userSettings,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil,
                                                                             nil);
                    dispatch_async(dispatch_get_main_queue(), ^{
                      totalTuplesProcessed++;
                      [self handlePieChartResult:result
                             chartAndLoaderTuple:chartAndLoaderTuple
                           animateSettingsButton:self.animateAllSettingsButtons];
                      if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(bmls.count, numDaysOfBmls); }
                    });
                  });
                }
              }
            };
            processTuples(self.chartAndLoaderTuplesArray, bodyChartData, veryFirstBmlOnOrAfterLoggedAt, veryLastBmlOnOrBeforeLoggedAt);
          });
        });
      });
    });
  } else {
    if (completion) { completion(); }
    if (showAlertIfAlreadyLoading) { [self showChartsAlreadyLoadingInfoAlert]; }
  }
}

@end




