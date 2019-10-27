//
//  RAbstractChartController.h
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEBaseController.h"
#import "RUtils.h"
#import "RChartConfig.h"
#import "PELMDefs.h"
#import "RChartAndLoaderTuple.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import Charts;
#pragma clang pop

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;
@class RNormalizedLineChartDataEntry;

typedef RNormalizedTimeSeriesTupleCollection *(^NormalizedTimeSeriesCollectionMaker)(id, RChartConfigAggregateBy);

typedef NSDictionary *(^PieChartDataContainerMaker)(RChartStrengthRawData *);

typedef RChartAndLoaderTuple *(^PieChartAndLoaderTupleMaker)(NSString *, NSString *, NSString *, PieChartDataContainerMaker, NSDictionary *, NSAttributedString *, NSArray *(^)(NSArray *), RChartSectionJumpId, BOOL);

typedef RChartAndLoaderTuple *(^LineChartAndLoaderTupleMaker)(NSString *, NSString *, NSString *, NormalizedTimeSeriesCollectionMaker, NSDictionary *, CGFloat, NSAttributedString *, NSArray *(^)(NSArray *), RChartSectionJumpId, BOOL);

typedef RChartAndLoaderTuple *(^ChartSectionPanelMaker)(NSString *, NSAttributedString *, BOOL);

typedef NSString *(^ChartIdMaker)(NSInteger);

typedef id(^RChartRawDataBlk)(
PELMUser *user,
RUserSettings *userSettings,
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
NSArray *,
NSDate *,
NSDate *);

typedef NSArray *(^RFilteredDataBlk)(PELMUser *user, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt, BOOL boundedEndDate);

FOUNDATION_EXPORT CGFloat const RCHART_ANIMATION_DURATION;

@interface RAbstractChartController : PEBaseController <ChartViewDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                   screenTitle:(NSString *)screenTitle
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache;

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad;

#pragma mark - Properites

@property (nonatomic) id<RCoordinatorDao> coordDao;
@property (nonatomic) CGFloat normalLineWidth;
@property (nonatomic) CGFloat thickLineWidth;
@property (nonatomic) CGFloat thickerLineWidth;
@property (nonatomic) NSDate *veryFirstSetLoggedAt;
@property (nonatomic) NSDate *veryLastSetLoggedAt;
@property (nonatomic) NSDate *veryFirstBmlLoggedAt;
@property (nonatomic) NSDate *veryLastBmlLoggedAt;
@property (nonatomic) NSMutableDictionary *bodySegmentColors;
@property (nonatomic) NSMutableDictionary *muscleGroupColors;
@property (nonatomic) NSMutableDictionary *lowerBodyMuscleGroupColors;
@property (nonatomic) NSMutableDictionary *muscleColors;
@property (nonatomic) NSMutableDictionary *movementVariantColors;
@property (nonatomic) NSDictionary *singleValueContainerLineColor;
@property (nonatomic) BOOL forcedReloadChartsNeeded;
@property (nonatomic) BOOL deviceWasRotated;
@property (nonatomic) BOOL globalStrengthConfigWasSet;
@property (nonatomic) BOOL animateAllSettingsButtons;
@property (nonatomic) BOOL areTheChartsLoading;
@property (nonatomic) PELMUser *user;
@property (nonatomic) NSMutableDictionary *entitiesAndRawDataCache;
@property (nonatomic) BOOL calcPercentages;
@property (nonatomic) BOOL calcAverages;

#pragma mark - Helpers

+ (NSArray *)hardChartReloadNotificationNames;

+ (NSArray *)hardChartForcedReloadNotificationNames;

+ (NSNumberFormatter *)percentNumberFormatter;

+ (NSNumberFormatter *)plainNumberFormatter;

+ (UIFont *)legendFont;

+ (ChartIdMaker)makeChartIdMakerWithPrefix:(NSString *)chartIdPrefix;

+ (RChartConfigAggregateBy)suggestedAggregateByWithFirstDate:(NSDate *)firstDate lastDate:(NSDate *)lastDate;

+ (NSArray *(^)(NSArray *))makeTripleSorter;

+ (NSArray *)mainColors;

+ (NSString *(^)(RUserSettings *, double))makeYaxisLabelBlkWithType:(NSString *)type isPortraitMode:(BOOL)isPortraitMode;

+ (NSString *(^)(RUserSettings *, double))makeWeightYaxisLabelBlkIsPortraitMode:(BOOL)isPortraitMode;

+ (NSString *(^)(RUserSettings *, double))makeSizeYaxisLabelBlkIsPortraitMode:(BOOL)isPortraitMode;

+ (double)yaxisScalingFactorForMaxValue:(double)max;

+ (void)configureMarkerOnLineChart:(LineChartView *)lineChartView isPercentage:(BOOL)isPercentage uom:(NSString *)uom;

+ (void)configureChartLoadingHud:(MBProgressHUD *)progressHud;

+ (UIView *)viewForHudDisplayForTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple;

+ (UIButton *(^)(NSString *))jumpButtonMaker;

+ (UIView *)jumpPanelWithButtons:(NSArray *)jumpButtonsArray
                  relativeToView:(UIView *)relativeToView;

#pragma mark - Colors

- (void)configureColors;

- (void)configureColorsWithMuscles:(NSArray *)muscles;

#pragma mark - Chart Loading

- (void)enableAllChartLoadingHudsForTuples:(NSArray *)chartAndLoaderTuplesArray;

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages;

- (void)showChartsAlreadyLoadingInfoAlert;

#pragma mark - Notification handlers

- (void)indicateChartHardForcedReloadNeeded:(NSNotification *)notification;

#pragma mark - Chart Settings Notification Handling

- (void)chartSettingsClearedNotification:(NSNotification *)notification;

#pragma mark - Chart Config Helpers

- (void)chartSettingsDidChangeForChartId:(NSString *)chartId;
- (RChartConfigCategory)chartConfigCategory;
- (void)nullOutMainContentPanel;
- (NSDate *)veryFirstLoggedAt;
- (NSDate *)veryLastLoggedAt;
- (RChartConfig *)globalConfig;
- (void)setGlobalConfig:(RChartConfig *)chartConfig;
- (void)clearAllChartConfigs;
- (NSString *)globalChartConfigSettingsTitlePart;
- (void)globalChartConfigSettingsCalcPercentages:(BOOL)calcPercentages
                                    calcAverages:(BOOL)calcAverages;
- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig;
- (void(^)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *))populateChartConfigsBlkWithGlobalConfig:(RChartConfig *)globalConfig;

#pragma mark - Load Charts and Helpers

- (void)animateSettingsButton:(UIButton *)settingsButton;

- (void)handleLineChartResult:(NSArray *)result
          chartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                 userSettings:(RUserSettings *)userSettings
        animateSettingsButton:(BOOL)animateSettingsButton;

- (void)handlePieChartResult:(NSArray *)result
         chartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
       animateSettingsButton:(BOOL)animateSettingsButton;

- (void)settingsDidChangeForChartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                                      fetchMode:(RChartDataFetchMode)fetchMode;

- (void)maybeShow32bitIphoneLineChartMsg;

#pragma mark - Metric Type Heading Panel Maker

+ (UIView *)makeMetricTypeHeadingPanelWithTitle:(NSString *)title
                                 infoAlertTitle:(NSString *)infoAlertTitle
                           infoAlertDescription:(NSAttributedString *)infoAlertDescription
                                 settingsAction:(void(^)(void))settingsAction
                                 relativeToView:(UIView *)relativeToView
                                     controller:(UIViewController *)controller
                       chartReloadButtonHandler:(void(^)(void))chartReloadButtonHandler;

#pragma mark - Chart Type Heading Panel Maker

+ (UIView *)makeChartTypeHeadingPanelWithTitle:(NSString *)title
                                infoAlertTitle:(NSString *)infoAlertTitle
                          infoAlertDescription:(NSAttributedString *)infoAlertDescription
                               backgroundColor:(UIColor *)backgroundColor
                              moreChartsAction:(void(^)(RAbstractChartController *))moreChartsAction
                                relativeToView:(UIView *)relativeToView
                                    controller:(RAbstractChartController *)controller;

#pragma mark - Metric: Body Measurment - Timeline Single-Chart/Loader Tuples Maker

+ (NSDictionary *)makeBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:(NSMutableDictionary *(^)(RChartBodyRawData *))timeSeriesDictBlk
                                                                                  chartTitle:(NSString *)chartTitle
                                                                               chartIdPrefix:(NSString *)chartIdPrefix
                                                                                   lineColor:(UIColor *)lineColor
                                                                          yaxisValueLabelBlk:(NSString *(^)(RUserSettings *, double maxValue))yaxisValueLabelBlk
                                                                                 maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                                   yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                                           yaxisFormatterBlk:(id<IChartAxisValueFormatter>(^)(double))yaxisFormatterBlk
                                                                             yaxisMaximumBlk:(double(^)(double))yaxisMaximumBlk
                                                                              relativeToView:(UIView *)relativeToView
                                                                                 bodyConfigs:(RChartConfig *(^)(NSString *))bodyConfigs
                                                                                isPercentage:(BOOL)isPercentage
                                                                               uomDisplayBlk:(RUomDisplayBlk)uomDisplayBlk
                                                                                  controller:(RAbstractChartController *)controller
                                                                           chartViewDelegate:(id<ChartViewDelegate>)chartViewDelegate                                                                      
                                                                                   uitoolkit:(PEUIToolkit *)uitoolkit
                                                                               screenToolkit:(RScreenToolkit *)screenToolkit
                                                                                panelToolkit:(RPanelToolkit *)panelToolkit
                                                                                    coordDao:(id<RCoordinatorDao>)coordDao
                                                                                    headless:(BOOL)headless
                                                                     entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                             calcPercentages:(BOOL)calcPercentages
                                                                                calcAverages:(BOOL)calcAverages
                                                                                     logging:(BOOL)logging;

+ (NSDictionary *)makeHeadlessBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:(NSMutableDictionary *(^)(RChartBodyRawData *))timeSeriesDictBlk
                                                                                       chartIdPrefix:(NSString *)chartIdPrefix
                                                                                         maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                                           yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                                                         bodyConfigs:(RChartConfig *(^)(NSString *))bodyConfigs
                                                                                            coordDao:(id<RCoordinatorDao>)coordDao
                                                                             entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                                     calcPercentages:(BOOL)calcPercentages
                                                                                        calcAverages:(BOOL)calcAverages
                                                                                             logging:(BOOL)logging;

#pragma mark - Metric: Weight Lifted - Pie Chart/Loader Tuples Maker

+ (NSDictionary *)makeWeightLiftedPieChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                         chartIdPrefix:(NSString *)chartIdPrefix
                                                        relativeToView:(UIView *)relativeToView
                                                       strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                            controller:(RAbstractChartController *)controller
                                                              coordDao:(id<RCoordinatorDao>)coordDao
                                                   chartConfigCategory:(RChartConfigCategory)chartConfigCategory
                                                             uitoolkit:(PEUIToolkit *)uitoolkit
                                                         screenToolkit:(RScreenToolkit *)screenToolkit
                                                          panelToolkit:(RPanelToolkit *)panelToolkit
                                                              headless:(BOOL)headless
                                                               logging:(BOOL)logging;

#pragma mark - Metric: Weight Lifted - Timeline Chart/Loader Tuples Maker

+ (NSDictionary *)makeWeightLiftedChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                  calculateAverages:(BOOL)calculateAverages
                                             calculateDistributions:(BOOL)calculateDistributions
                                                      chartIdPrefix:(NSString *)chartIdPrefix
                                                 yaxisValueLabelBlk:(NSString *(^)(RUserSettings *userSettings, double maxValue))yaxisValueLabelBlk
                                                        maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                          yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                  yaxisFormatterBlk:(id<IChartAxisValueFormatter>(^)(double))yaxisFormatterBlk
                                                    yaxisMaximumBlk:(double(^)(double))yaxisMaximumBlk
                                                       isPercentage:(BOOL)isPercentage
                                                   chartTitlePrefix:(NSString *)chartTitlePrefix
                                                  chartTitlePostfix:(NSString *)chartTitlePostfix
                                               sectionHighlightText:(NSString *)sectionHighlightText
                                              weightLiftedQualifier:(NSString *)weightLiftedQualifier
                                                     relativeToView:(UIView *)relativeToView
                                                    strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                         controller:(RAbstractChartController *)controller
                                              areDistributionTuples:(BOOL)areDistributionTuples
                                                           coordDao:(id<RCoordinatorDao>)coordDao
                                                  chartViewDelegate:(id<ChartViewDelegate>)chartViewDelegate
                                                          uitoolkit:(PEUIToolkit *)uitoolkit
                                                      screenToolkit:(RScreenToolkit *)screenToolkit
                                                       panelToolkit:(RPanelToolkit *)panelToolkit
                                                           headless:(BOOL)headless
                                            entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                            logging:(BOOL)logging;

+ (NSDictionary *)makeHeadlessWeightLiftedChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                          calculateAverages:(BOOL)calculateAverages
                                                     calculateDistributions:(BOOL)calculateDistributions
                                                              chartIdPrefix:(NSString *)chartIdPrefix
                                                                maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                  yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                            strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                      areDistributionTuples:(BOOL)areDistributionTuples
                                                                   coordDao:(id<RCoordinatorDao>)coordDao
                                                    entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                    logging:(BOOL)logging;

#pragma mark - Metric: Reps - Pie Chart/Loader Tuples Maker

+ (NSDictionary *)makeRepsPieChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                 chartIdPrefix:(NSString *)chartIdPrefix
                                                relativeToView:(UIView *)relativeToView
                                               strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                    controller:(RAbstractChartController *)controller
                                                      coordDao:(id<RCoordinatorDao>)coordDao
                                                     uitoolkit:(PEUIToolkit *)uitoolkit
                                                 screenToolkit:(RScreenToolkit *)screenToolkit
                                                  panelToolkit:(RPanelToolkit *)panelToolkit
                                                      headless:(BOOL)headless
                                                       logging:(BOOL)logging;

#pragma mark - Metric: Reps - Timeline Chart/Loader Tuples Maker

+ (NSDictionary *)makeRepsTimelineChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                  calculateAverages:(BOOL)calculateAverages
                                             calculateDistributions:(BOOL)calculateDistributions
                                                      chartIdPrefix:(NSString *)chartIdPrefix
                                                 yaxisValueLabelBlk:(NSString *(^)(RUserSettings *, double maxValue))yaxisValueLabelBlk
                                                        maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                          yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                  yaxisFormatterBlk:(id<IChartAxisValueFormatter>(^)(double))yaxisFormatterBlk
                                                    yaxisMaximumBlk:(double(^)(double))yaxisMaximumBlk
                                                       isPercentage:(BOOL)isPercentage
                                                   chartTitlePrefix:(NSString *)chartTitlePrefix
                                                  chartTitlePostfix:(NSString *)chartTitlePostfix
                                               sectionHighlightText:(NSString *)sectionHighlightText
                                                      repsQualifier:(NSString *)repsQualifier
                                                     relativeToView:(UIView *)relativeToView
                                                    strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                         controller:(RAbstractChartController *)controller
                                              areDistributionTuples:(BOOL)areDistributionTuples
                                                           coordDao:(id<RCoordinatorDao>)coordDao
                                                  chartViewDelegate:(id<ChartViewDelegate>)chartViewDelegate
                                                          uitoolkit:(PEUIToolkit *)uitoolkit
                                                      screenToolkit:(RScreenToolkit *)screenToolkit
                                                       panelToolkit:(RPanelToolkit *)panelToolkit
                                                           headless:(BOOL)headless
                                            entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                            logging:(BOOL)logging;

+ (NSDictionary *)makeHeadlessRepsTimelineChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                          calculateAverages:(BOOL)calculateAverages
                                                     calculateDistributions:(BOOL)calculateDistributions
                                                              chartIdPrefix:(NSString *)chartIdPrefix
                                                                maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                  yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                            strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                      areDistributionTuples:(BOOL)areDistributionTuples
                                                                   coordDao:(id<RCoordinatorDao>)coordDao
                                                    entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                    logging:(BOOL)logging;

#pragma mark - Metric: Time Between Sets - Pie Chart/Loader Tuples Maker

+ (NSDictionary *)makeTimeBetweenSetsSameMovPieChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                                   chartIdPrefix:(NSString *)chartIdPrefix
                                                                  relativeToView:(UIView *)relativeToView
                                                                 strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                                      controller:(RAbstractChartController *)controller
                                                                        coordDao:(id<RCoordinatorDao>)coordDao
                                                                       uitoolkit:(PEUIToolkit *)uitoolkit
                                                                   screenToolkit:(RScreenToolkit *)screenToolkit
                                                                    panelToolkit:(RPanelToolkit *)panelToolkit
                                                                        headless:(BOOL)headless
                                                                         logging:(BOOL)logging;

#pragma mark - Metric: Time Between Sets - Timeline Chart/Loader Tuples Maker

+ (NSDictionary *)makeTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                             calculateAverages:(BOOL)calculateAverages
                                                        calculateDistributions:(BOOL)calculateDistributions
                                                                 chartIdPrefix:(NSString *)chartIdPrefix
                                                            yaxisValueLabelBlk:(NSString *(^)(RUserSettings *, double maxValue))yaxisValueLabelBlk
                                                                   maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                     yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                             yaxisFormatterBlk:(id<IChartAxisValueFormatter>(^)(double))yaxisFormatterBlk
                                                               yaxisMaximumBlk:(double(^)(double))yaxisMaximumBlk
                                                                  isPercentage:(BOOL)isPercentage
                                                              chartTitlePrefix:(NSString *)chartTitlePrefix
                                                             chartTitlePostfix:(NSString *)chartTitlePostfix
                                                          sectionHighlightText:(NSString *)sectionHighlightText
                                                                 timeQualifier:(NSString *)timeQualifier
                                                                relativeToView:(UIView *)relativeToView
                                                               strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                                    controller:(RAbstractChartController *)controller
                                                         areDistributionTuples:(BOOL)areDistributionTuples
                                                                      coordDao:(id<RCoordinatorDao>)coordDao
                                                             chartViewDelegate:(id<ChartViewDelegate>)chartViewDelegate
                                                                     uitoolkit:(PEUIToolkit *)uitoolkit
                                                                 screenToolkit:(RScreenToolkit *)screenToolkit
                                                                  panelToolkit:(RPanelToolkit *)panelToolkit
                                                                      headless:(BOOL)headless
                                                       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                       logging:(BOOL)logging;

+ (NSDictionary *)makeHeadlessTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:(RChartDataFetchMode)fetchMode
                                                                     calculateAverages:(BOOL)calculateAverages
                                                                calculateDistributions:(BOOL)calculateDistributions
                                                                         chartIdPrefix:(NSString *)chartIdPrefix
                                                                           maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                             yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                                       strengthConfigs:(RChartConfig *(^)(NSString *))strengthConfigs
                                                                 areDistributionTuples:(BOOL)areDistributionTuples
                                                                              coordDao:(id<RCoordinatorDao>)coordDao
                                                               entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                               logging:(BOOL)logging;

@end
