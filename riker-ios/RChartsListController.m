//
//  RChartsListController.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RChartsListController.h"
@import Firebase;
#import <QuartzCore/QuartzCore.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/DateTools.h>
#import <SVPullToRefresh/UIScrollView+SVPullToRefresh.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "RLocalDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "PELMUser.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RLogging.h"
#import "RUIUtils.h"
#import "PEUtils.h"
#import "PELocalDao.h"
#import "RPanelToolkit.h"
#import "RAppNotificationNames.h"
#import "RSelectScreen.h"
#import "RBodySegment.h"
#import "RPanelToolkit.h"
#import "RUserSettings.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"
#import "RMovement.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMovementVariant.h"
#import "NSString+RAdditions.h"
#import "RUtils.h"
#import "RChartStrengthRawData.h"
#import "RDateValueFormatter.h"
#import "RNumberValueFormatter.h"
#import "RPercentageFormatter.h"
#import "RChartConfig.h"
#import "RChartFilterScreen.h"
#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedLineChartDataEntry.h"
#import "RChartBodyRawData.h"

@implementation RChartsListController {
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  RUserSettingsBlk _userSettingsBlk;
  UIView *_mainContentPanel;
  NSString *_metricHeadingText;
  NSAttributedString *_metricAlertDescription;
  NSString *_chartTypeHeadingText;
  NSString *_chartTypeAlertTitleText;
  NSAttributedString *_chartTypeAlertDescription;
  UIColor *_chartTypeBackgroundColor;
  RChartConfig *(^_strengthChartConfigs)(NSString *);
  RChartConfig *_globalStrengthChartConfig;
  RChartDataFetchMode _fetchMode;
  NSDictionary *(^_chartAndLoaderTuplesMaker)(RChartsListController *, UIView *);
  id<RCoordinatorDao> _coordDao;
  NSMutableArray *_strengthChartAndLoaderTuplesArray;
  NSMutableDictionary *_strengthChartAndLoaderTuples;
  NSArray *_muscles;
  NSString *_chartConfigTitlePart;
  RAbstractChartController *_parentController;
  CGFloat _muscleGroupsSectionPanelY;
  CGFloat _movementVariantsSectionPanelY;
  NSDecimalNumber *_nextUpPosition;
  NSNumber *_isNextUpPositionMuscleGroups;
  NSDecimalNumber *_currentChartPosition;
  RChartConfigCategory _chartConfigCategory;
}

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
                  calcAverages:(BOOL)calcAverages {
  self = [super initWithStoreCoordinator:coordDao
                         userSettingsBlk:userSettingsBlk
                               uitoolkit:uitoolkit
                           screenToolkit:screenToolkit
                            panelToolkit:panelToolkit
                             screenTitle:screenTitle
                                    user:user
                 entitiesAndRawDataCache:entitiesAndRawDataCache];
  if (self) {
    _coordDao = coordDao;
    _userSettingsBlk = userSettingsBlk;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _fetchMode = fetchMode;
    _strengthChartConfigs = strengthChartConfigs;
    _globalStrengthChartConfig = globalStrengthChartConfig;
    _metricHeadingText = metricHeadingText;
    _metricAlertDescription = metricAlertDescription;
    _chartTypeHeadingText = chartTypeHeadingText;
    _chartTypeAlertTitleText = chartTypeAlertTitleText;
    _chartTypeAlertDescription = chartTypeAlertDescription;
    _chartTypeBackgroundColor = chartTypeBackgroundColor;
    _chartAndLoaderTuplesMaker = chartAndLoaderTuplesMaker;
    _chartConfigTitlePart = chartConfigTitlePart;
    _parentController = parentController;
    _chartConfigCategory = chartConfigCategory;
    self.calcPercentages = calcPercentages;
    self.calcAverages = calcAverages;
  }
  return self;
}

#pragma mark - Main Content

- (UIView *)mainContentWithUser:(PELMUser *)user
                   userSettings:(RUserSettings *)userSettings
                 relativeToView:(UIView *)relativeToView {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  UIView *metricHeadingPanel =
  [RAbstractChartController makeMetricTypeHeadingPanelWithTitle:_metricHeadingText
                                                 infoAlertTitle:_metricHeadingText
                                           infoAlertDescription:_metricAlertDescription
                                                 settingsAction:^{ [self globalChartConfigSettingsCalcPercentages:self.calcPercentages
                                                                                                     calcAverages:self.calcAverages]; }
                                                 relativeToView:contentPanel
                                                     controller:self
                                       chartReloadButtonHandler:^{
                                         [self loadChartsWithCompletion:nil
                                              showAlertIfAlreadyLoading:YES
                                                               headless:NO
                                                        calcPercentages:self.calcPercentages
                                                           calcAverages:self.calcAverages];
                                       }];
  UIView *chartTypeHeadingPanel =
  [RAbstractChartController makeChartTypeHeadingPanelWithTitle:_chartTypeHeadingText
                                                infoAlertTitle:_chartTypeAlertTitleText
                                          infoAlertDescription:_chartTypeAlertDescription
                                               backgroundColor:_chartTypeBackgroundColor
                                              moreChartsAction:nil
                                                relativeToView:contentPanel
                                                    controller:self];
  // place views onto content panel
  CGFloat vpadding = -8.0;
  CGFloat carouselVpadding = 12.0;
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:metricHeadingPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += metricHeadingPanel.frame.size.height + vpadding;
  vpadding = 2.5;
  [PEUIUtils placeView:chartTypeHeadingPanel
                 below:metricHeadingPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += chartTypeHeadingPanel.frame.size.height + vpadding;
  UIButton *(^makeJumpButton)(NSString *) = [RAbstractChartController jumpButtonMaker];
  UIButton *jumpToMuscleGroupsButton = makeJumpButton(@"muscle groups");
  UIButton *jumpToMovVariantsButton = makeJumpButton(@"movement variants");
  UIView *jumpToPanel = [RAbstractChartController jumpPanelWithButtons:@[jumpToMuscleGroupsButton, jumpToMovVariantsButton] relativeToView:contentPanel];
  [PEUIUtils placeView:jumpToPanel
                 below:chartTypeHeadingPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += jumpToPanel.frame.size.height + vpadding;
  vpadding = carouselVpadding;
  UIView *topView = jumpToPanel;
  NSArray *chartAndLoaderTuplesArray = [_chartAndLoaderTuplesMaker(self, contentPanel) allValues];
  chartAndLoaderTuplesArray = [chartAndLoaderTuplesArray sortedArrayUsingComparator:^NSComparisonResult(NSArray * _Nonnull chartIdAndTupleBlk1, NSArray * _Nonnull chartIdAndTupleBlk2) {
    NSNumber *sortOrder1 = chartIdAndTupleBlk1[2];
    NSNumber *sortOrder2 = chartIdAndTupleBlk2[2];
    return [sortOrder1 compare:sortOrder2];
  }];
  _strengthChartAndLoaderTuplesArray = [NSMutableArray array];
  _strengthChartAndLoaderTuples = [NSMutableDictionary dictionary];
  void (^configureToScroll)(NSNumber *, CGFloat, UIButton *, CGPoint) = ^(NSNumber *isNextUpPositionMuscleGroups, CGFloat previousPosition, UIButton *button, CGPoint point) {
    [button bk_addEventHandler:^(id sender) {
      _isNextUpPositionMuscleGroups = isNextUpPositionMuscleGroups;
      _nextUpPosition = [[NSDecimalNumber alloc] initWithFloat:previousPosition];
      [UIScrollView animateWithDuration:0.3
                             animations:^(void) { [((UIScrollView *)self.displayPanel) setContentOffset:CGPointMake(point.x, point.y - [PEUIUtils valueIfiPhoneXSMaxOrXrInPortrait:24.0 other:0.0])]; }
                             completion:nil];
    } forControlEvents:UIControlEventTouchUpInside];
  };
  RChartAndLoaderTuple *muscleGroupSectionTuple = nil;
  RChartAndLoaderTuple *movementVariantsSectionTuple = nil;
  NSMutableDictionary *mgJumpIds = [NSMutableDictionary dictionary];
  NSMutableDictionary *mvJumpIds = [NSMutableDictionary dictionary];
  BOOL areMuscleGroupTuples = NO;
  for (NSArray *chartIdAndTupleBlk in chartAndLoaderTuplesArray) {
    RChartAndLoaderTuple *(^chartAndLoaderTupleBlk)(void) = chartIdAndTupleBlk[1];
    RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTupleBlk();
    [_strengthChartAndLoaderTuplesArray addObject:chartAndLoaderTuple];
    _strengthChartAndLoaderTuples[chartIdAndTupleBlk[0]] = chartAndLoaderTuple;
    UIView *chart = chartAndLoaderTuple.chartPanelView;
    [PEUIUtils placeView:chart
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeight += chart.frame.size.height + vpadding;
    if (chartIdAndTupleBlk.count > 3 && ((NSNumber *)chartIdAndTupleBlk[3]).boolValue) { // is section panel
      configureToScroll(nil, 0.0, chartAndLoaderTuple.jumptToTopButton, CGPointZero);
      areMuscleGroupTuples = !areMuscleGroupTuples;
      if (!muscleGroupSectionTuple) {
        _muscleGroupsSectionPanelY = chart.frame.origin.y;
        muscleGroupSectionTuple = chartAndLoaderTuple;
        if (_isNextUpPositionMuscleGroups && _isNextUpPositionMuscleGroups.boolValue) {
          _nextUpPosition = [[NSDecimalNumber alloc] initWithFloat:_muscleGroupsSectionPanelY];
        }
      } else {
        _movementVariantsSectionPanelY = chart.frame.origin.y;
        movementVariantsSectionTuple = chartAndLoaderTuple;
        if (_isNextUpPositionMuscleGroups && !_isNextUpPositionMuscleGroups.boolValue) {
          _nextUpPosition = [[NSDecimalNumber alloc] initWithFloat:_movementVariantsSectionPanelY];
        }
      }
    } else {
      if (areMuscleGroupTuples) {
        mgJumpIds[@(chartAndLoaderTuple.jumpId)] = @(chart.frame.origin.y);
      } else {
        mvJumpIds[@(chartAndLoaderTuple.jumpId)] = @(chart.frame.origin.y);
      }
    }
    topView = chart;
  }
  void (^configureMgToScroll)(UIButton *, RChartSectionJumpId) = ^(UIButton *button, RChartSectionJumpId jumpId) {
    configureToScroll(@(YES),
                      _muscleGroupsSectionPanelY,
                      button,
                      CGPointMake(0, ((NSNumber *)mgJumpIds[@(jumpId)]).floatValue));
  };
  configureMgToScroll(muscleGroupSectionTuple.jumpToAllButton, RChartSectionJumpIdAll);
  configureMgToScroll(muscleGroupSectionTuple.jumpToUpperBodyButton, RChartSectionJumpIdUpperBody);
  configureMgToScroll(muscleGroupSectionTuple.jumpToShouldersButton, RChartSectionJumpIdShoulders);
  configureMgToScroll(muscleGroupSectionTuple.jumpToChestButton, RChartSectionJumpIdChest);
  configureMgToScroll(muscleGroupSectionTuple.jumpToBackButton, RChartSectionJumpIdBack);
  configureMgToScroll(muscleGroupSectionTuple.jumpToBicepsButton, RChartSectionJumpIdBiceps);
  configureMgToScroll(muscleGroupSectionTuple.jumpToTricepsButton, RChartSectionJumpIdTriceps);
  configureMgToScroll(muscleGroupSectionTuple.jumpToForearmsButton, RChartSectionJumpIdForearms);
  configureMgToScroll(muscleGroupSectionTuple.jumpToAbsButton, RChartSectionJumpIdCore);
  configureMgToScroll(muscleGroupSectionTuple.jumpToLowerBodyButton, RChartSectionJumpIdLowerBody);
  configureMgToScroll(muscleGroupSectionTuple.jumpToHamstringsButton, RChartSectionJumpIdHamstrings);
  configureMgToScroll(muscleGroupSectionTuple.jumpToQuadsButton, RChartSectionJumpIdQuads);
  configureMgToScroll(muscleGroupSectionTuple.jumpToCalfsButton, RChartSectionJumpIdCalfs);
  configureMgToScroll(muscleGroupSectionTuple.jumpToGlutesButton, RChartSectionJumpIdGlutes);
  configureMgToScroll(muscleGroupSectionTuple.jumpToHipAbductorsButton, RChartSectionJumpIdHipAbductors);
  configureMgToScroll(muscleGroupSectionTuple.jumpToHipFlexorsButton, RChartSectionJumpIdHipFlexors);
  void (^configureMvToScroll)(UIButton *, RChartSectionJumpId) = ^(UIButton *button, RChartSectionJumpId jumpId) {
    configureToScroll(@(NO),
                      _movementVariantsSectionPanelY,
                      button,
                      CGPointMake(0, ((NSNumber *)mvJumpIds[@(jumpId)]).floatValue));
  };
  configureMvToScroll(movementVariantsSectionTuple.jumpToAllButton, RChartSectionJumpIdAll);
  configureMvToScroll(movementVariantsSectionTuple.jumpToUpperBodyButton, RChartSectionJumpIdUpperBody);
  configureMvToScroll(movementVariantsSectionTuple.jumpToShouldersButton, RChartSectionJumpIdShoulders);
  configureMvToScroll(movementVariantsSectionTuple.jumpToLowerBodyButton, RChartSectionJumpIdLowerBody);
  configureMvToScroll(movementVariantsSectionTuple.jumpToChestButton, RChartSectionJumpIdChest);
  configureMvToScroll(movementVariantsSectionTuple.jumpToBackButton, RChartSectionJumpIdBack);
  configureMvToScroll(movementVariantsSectionTuple.jumpToBicepsButton, RChartSectionJumpIdBiceps);
  configureMvToScroll(movementVariantsSectionTuple.jumpToTricepsButton, RChartSectionJumpIdTriceps);
  configureMvToScroll(movementVariantsSectionTuple.jumpToForearmsButton, RChartSectionJumpIdForearms);
  configureMvToScroll(movementVariantsSectionTuple.jumpToAbsButton, RChartSectionJumpIdCore);
  configureMvToScroll(movementVariantsSectionTuple.jumpToLowerBodyButton, RChartSectionJumpIdLowerBody);
  configureMvToScroll(movementVariantsSectionTuple.jumpToHamstringsButton, RChartSectionJumpIdHamstrings);
  configureMvToScroll(movementVariantsSectionTuple.jumpToQuadsButton, RChartSectionJumpIdQuads);
  configureMvToScroll(movementVariantsSectionTuple.jumpToCalfsButton, RChartSectionJumpIdCalfs);
  configureMvToScroll(movementVariantsSectionTuple.jumpToGlutesButton, RChartSectionJumpIdGlutes);
  configureMvToScroll(movementVariantsSectionTuple.jumpToHipAbductorsButton, RChartSectionJumpIdHipAbductors);
  configureMvToScroll(movementVariantsSectionTuple.jumpToHipFlexorsButton, RChartSectionJumpIdHipFlexors);

  totalHeight += carouselVpadding; // to give it some bottom-margin
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  configureToScroll(nil, 0.0, jumpToMuscleGroupsButton, CGPointMake(0, _muscleGroupsSectionPanelY));
  configureToScroll(nil, 0.0, jumpToMovVariantsButton, CGPointMake(0, _movementVariantsSectionPanelY));
  return contentPanel;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
  RUserSettings *userSettings = [self.coordDao userSettingsForUser:user error:errorBlk];
  // yes, we need to load the muscles here and load the colors before the chart
  // loading can happen
  _muscles = [_coordDao musclesWithError:errorBlk];
  [self configureColorsWithMuscles:_muscles];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                      relativeToView:self.view
                                         fixedHeight:0.0];
  // make views
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
  CGFloat totalHeightSubContent = 0.0;
  // main panel content
  _mainContentPanel = [self mainContentWithUser:user userSettings:userSettings relativeToView:contentPanel];
  CGFloat vpadding = 8.0;
  CGFloat betweenHeadingPanelsVpadding = 2.5;
  // place 'Total Weight Lifted' content onto subContentPanel
  [PEUIUtils placeView:_mainContentPanel
               atTopOf:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContent += _mainContentPanel.frame.size.height + vpadding;
  // set height and place sub-content panel
  [PEUIUtils setFrameHeight:totalHeightSubContent ofView:subContentPanel];
  // place views
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:subContentPanel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:betweenHeadingPanelsVpadding hpadding:0.0];
  totalHeight += subContentPanel.frame.size.height + betweenHeadingPanelsVpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Chart Loading

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages {
  if (headless || (!self.areTheChartsLoading || self.deviceWasRotated)) {
    void (^allDoneBlk)(BOOL, NSInteger, NSInteger) = nil;
    if (!headless) {
      self.areTheChartsLoading = YES;
      [self enableAllChartLoadingHudsForTuples:_strengthChartAndLoaderTuplesArray];
      allDoneBlk = ^(BOOL areLineCharts, NSInteger numSets, NSInteger numDaysOfSets) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RCHART_ANIMATION_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          self.areTheChartsLoading = NO;
        });
        if (areLineCharts && numSets > 0 && numDaysOfSets == 0) {
          [self maybeShow32bitIphoneLineChartMsg];
        }
        if (completion) {
          completion();
        }
      };
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
      RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:errorBlk];
      NSArray *bodySegments = [_coordDao bodySegmentsWithError:errorBlk];
      NSDictionary *bodySegmentsDict = [RUtils dictFromMasterEntitiesArray:bodySegments];
      NSArray *muscleGroups = [_coordDao muscleGroupsWithError:errorBlk];
      NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:muscleGroups];
      NSDictionary *musclesDict = [RUtils dictFromMasterEntitiesArray:_muscles];
      NSArray *movements = [_coordDao movementsWithError:errorBlk];
      NSDictionary *movementsDict = [RUtils dictFromMasterEntitiesArray:movements];
      NSArray *movementVariants = [_coordDao movementVariantsWithError:errorBlk];
      NSDictionary *movementVariantsDict = [RUtils dictFromMasterEntitiesArray:movementVariants];
      NSArray *sets = [self.coordDao ascendingSetsForUser:user error:errorBlk];
      RSet *firstSet = [sets firstObject];
      RSet *lastSet = [sets lastObject];
      NSInteger numDaysOfSets = [lastSet.loggedAt daysLaterThan:firstSet.loggedAt];
      self.veryLastSetLoggedAt = lastSet.loggedAt;
      self.veryFirstSetLoggedAt = firstSet.loggedAt;
      NSDate *onOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:self.veryFirstSetLoggedAt];
      NSDate *onOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:[self veryLastLoggedAt]] dateByAddingDays:1];
      RChartStrengthRawData *strengthChartData =
      [RUtils chartStrengthRawDataForUser:user
                             userSettings:userSettings
                             bodySegments:bodySegments
                         bodySegmentsDict:bodySegmentsDict
                             muscleGroups:muscleGroups
                         muscleGroupsDict:muscleGroupsDict
                                  muscles:_muscles
                              musclesDict:musclesDict
                                movements:movements
                            movementsDict:movementsDict
                         movementVariants:movementVariants
                     movementVariantsDict:movementVariantsDict
                                     sets:sets
                                fetchMode:_fetchMode
                          calcPercentages:self.calcPercentages
                             calcAverages:self.calcAverages];
      NSInteger numStrengthTuples = _strengthChartAndLoaderTuplesArray.count;
      NSInteger totalNumTuplesToProcess = numStrengthTuples;
      __block NSInteger totalTuplesProcessed = 0;
      void (^processTuples)(NSArray *, id) = ^(NSArray *chartAndLoaderTuples, id chartData) {
        NSInteger numTuples = chartAndLoaderTuples.count;
        for (NSInteger i = 0; i < numTuples; i++) {
          RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTuples[i];
          if (chartAndLoaderTuple.lineChartDataLoader) {
            NSArray *result = chartAndLoaderTuple.lineChartDataLoader(chartData,
                                                                      user,
                                                                      userSettings,
                                                                      bodySegments,
                                                                      bodySegmentsDict,
                                                                      muscleGroups,
                                                                      muscleGroupsDict,
                                                                      _muscles,
                                                                      musclesDict,
                                                                      movements,
                                                                      movementsDict,
                                                                      movementVariants,
                                                                      movementVariantsDict,
                                                                      onOrAfterLoggedAt,
                                                                      onOrBeforeLoggedAt);
            if (!headless) {
              dispatch_async(dispatch_get_main_queue(), ^{
                totalTuplesProcessed++;
                [self handleLineChartResult:result
                        chartAndLoaderTuple:chartAndLoaderTuple
                               userSettings:userSettings
                      animateSettingsButton:NO];
                if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(YES, sets.count, numDaysOfSets); }
              });
            }
          } else if (chartAndLoaderTuple.pieChartDataLoader) {
            NSArray *result = chartAndLoaderTuple.pieChartDataLoader(chartData,
                                                                     user,
                                                                     userSettings,
                                                                     bodySegments,
                                                                     bodySegmentsDict,
                                                                     muscleGroups,
                                                                     muscleGroupsDict,
                                                                     _muscles,
                                                                     musclesDict,
                                                                     movements,
                                                                     movementsDict,
                                                                     movementVariants,
                                                                     movementVariantsDict);
            if (!headless) {
              dispatch_async(dispatch_get_main_queue(), ^{
                totalTuplesProcessed++;
                [self handlePieChartResult:result
                       chartAndLoaderTuple:chartAndLoaderTuple
                     animateSettingsButton:NO];
                if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(NO, sets.count, numDaysOfSets); }
              });
            }
          } else {
            if (!headless) {
              // chart and tuple loader is for a chart section (no-op)
              totalTuplesProcessed++;
              if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(NO, sets.count, numDaysOfSets); }
            }
          }
        }
      };
      processTuples(_strengthChartAndLoaderTuplesArray, strengthChartData);
    });
  } else {
    if (completion) { completion(); }
    if (showAlertIfAlreadyLoading) { [self showChartsAlreadyLoadingInfoAlert]; }
  }
}

- (void)chartSettingsDidChangeForChartId:(NSString *)chartId {
  RChartAndLoaderTuple *chartAndLoaderTuple = _strengthChartAndLoaderTuples[chartId];
  if (chartAndLoaderTuple) {
    [self settingsDidChangeForChartAndLoaderTuple:chartAndLoaderTuple fetchMode:_fetchMode];
  }
}

#pragma mark - Chart Config Helpers

- (RChartConfigCategory)chartConfigCategory {
  return _chartConfigCategory;
}

- (NSString *)globalChartConfigSettingsTitlePart {
  return _chartConfigTitlePart;
}

- (NSString *)globalChartConfigSettingsEntityType {
  return @"set";
}

- (void)clearAllChartConfigs {
  [super clearAllChartConfigs];
  [_parentController loadChartsWithCompletion:nil
                    showAlertIfAlreadyLoading:NO
                                     headless:NO
                              calcPercentages:self.calcPercentages
                                 calcAverages:self.calcAverages];
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  [_parentController populateAllConfigsFromGlobalConfig:globalConfig];
  dispatch_async(dispatch_get_main_queue(), ^{
    [_parentController loadChartsWithCompletion:nil
                      showAlertIfAlreadyLoading:NO
                                       headless:NO
                                calcPercentages:self.calcPercentages
                                   calcAverages:self.calcAverages];
  });
}

#pragma mark - Go to Previous Scroll Position

- (void)gotoPreviousScrollPosition {
  [UIScrollView animateWithDuration:0.3
                         animations:^(void) {
                           CGFloat upPosition = 0.0;
                           if (_nextUpPosition) {
                             upPosition = _nextUpPosition.floatValue;
                             _nextUpPosition = nil;
                           }
                           [((UIScrollView *)self.displayPanel) setContentOffset:CGPointMake(0.0, upPosition - [PEUIUtils valueIfiPhoneXSMaxOrXrInPortrait:24.0 other:0.0])];
                         }
                         completion:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  UIBarButtonItem *gotoPreviousScrollPositionBtn =
  [[UIBarButtonItem alloc] initWithTitle:@"Up" style:UIBarButtonItemStylePlain target:self action:@selector(gotoPreviousScrollPosition)];
  [navItem setRightBarButtonItem:gotoPreviousScrollPositionBtn];
  _currentChartPosition = nil;
}

@end
