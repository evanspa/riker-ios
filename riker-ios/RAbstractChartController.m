//
//  RAbstractChartController.m
//  riker-ios
//
//  Created by PEVANS on 11/4/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RAbstractChartController.h"
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
#import "Riker-Swift.h"
#import "RChartAndLoaderTuple.h"
#import "RWatchUtils.h"
#import "RAbstractChartEntityDataTuple.h"
#import "RPieSliceDataTuple.h"
#import "RNormalizedTimeSeriesTuple.h"
#import "RLineChartDataCache.h"
#import "LineChartDataSet+RAdditions.h"

CGFloat const RCHART_ANIMATION_DURATION = 1.2;

CGFloat const CHART_RELOAD_BUTTON_ROTATION_DURATION = 0.20;

NSInteger const RCHART_CARD_PANEL_TAG = 19;

NSString * const SETTINGS_ICON_SET_IMAGE_NAME   = @"bootstrap-blue-settings-30";
NSString * const SETTINGS_ICON_UNSET_IMAGE_NAME = @"riker-semi-black-settings-30";

@implementation RAbstractChartController {
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  UIButton *_chartReloadButton;
  BOOL _chartsReloadButtonNeedsAnimation;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                   screenTitle:(NSString *)screenTitle
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache {
  self = [super initWithRequireRepaintNotifications:@[]
                                        screenTitle:screenTitle];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _normalLineWidth = [PEUIUtils valueIfiPhone5Width:1.5 iphone6Width:1.75 iphone6PlusWidth:2.0 ipad:2.75];
    _thickLineWidth = [PEUIUtils valueIfiPhone5Width:1.75 iphone6Width:2.0 iphone6PlusWidth:2.25 ipad:3.0];
    _thickerLineWidth = [PEUIUtils valueIfiPhone5Width:2.0 iphone6Width:2.25 iphone6PlusWidth:2.5 ipad:3.25];
    _user = user;
    self.bodySegmentColors = [NSMutableDictionary dictionary];
    self.muscleGroupColors = [NSMutableDictionary dictionary];
    self.lowerBodyMuscleGroupColors = [NSMutableDictionary dictionary];
    self.muscleColors = [NSMutableDictionary dictionary];
    self.movementVariantColors = [NSMutableDictionary dictionary];
    self.singleValueContainerLineColor = @{@(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER) : [UIColor bootstrapPrimary]};
    [self setDelaysContentTouches:NO];
    _entitiesAndRawDataCache = entitiesAndRawDataCache;
  }
  return self;
}

#pragma mark - Helpers

+ (NSArray *)hardChartReloadNotificationNames {
  return @[REntityAddedNotification,
           REntityUpdatedNotification,
           REntityDeletedNotification,
           RChangelogDownloadedNotification,
           RImportCompleteNotification];
}

+ (NSArray *)hardChartForcedReloadNotificationNames {
  return @[RAppDeleteAllDataNotification, RAppLoginNotification];
}

+ (NSNumberFormatter *)percentNumberFormatter {
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.numberStyle = NSNumberFormatterPercentStyle;
  formatter.maximumFractionDigits = 0;
  formatter.multiplier = @1.0f;
  formatter.percentSymbol = @"%";
  return formatter;
}

+ (NSNumberFormatter *)plainNumberFormatter {
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.numberStyle = NSNumberFormatterNoStyle;
  return formatter;
}

+ (UIFont *)legendFont {
  return [UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:9.0
                                                    iphone6Width:10.0
                                                iphone6PlusWidth:12.0
                                                            ipad:16.0]];
}

+ (ChartIdMaker)makeChartIdMakerWithPrefix:(NSString *)chartIdPrefix {
  return ^NSString * (NSInteger chartId) {
    return [NSString stringWithFormat:@"%@-%ld", chartIdPrefix, (long)chartId];
  };
}

+ (RChartConfigAggregateBy)suggestedAggregateByWithFirstDate:(NSDate *)firstDate lastDate:(NSDate *)lastDate {
  NSInteger daysFrom = [lastDate daysFrom:firstDate];
  if (daysFrom >= 4380) { // 12 years worth of days
    return RChartConfigAggregateByYear;
  }
  if (daysFrom >= 2190) { // 6 years worth of days
    return RChartConfigAggregateByHalfYear;
  }
  if (daysFrom >= 1095) { // 3 years worth of days
    return RChartConfigAggregateByQuarter;
  }
  if (daysFrom >= 540) {  // 1.5 years...
    return RChartConfigAggregateByMonth;
  }
  if (daysFrom >= 93) {  // 3 months...
    return RChartConfigAggregateByWeek;
  }
  return RChartConfigAggregateByDay;
}

+ (NSArray *(^)(NSArray *))makeTripleSorter {
  return ^NSArray * (NSArray *chartDataTuples) {
    return [chartDataTuples sortedArrayUsingComparator:^NSComparisonResult(RAbstractChartEntityDataTuple *chartDataTuple1, RAbstractChartEntityDataTuple *chartDataTuple2) {
      return [chartDataTuple1.name compare:chartDataTuple2.name];
    }];
  };
}

+ (NSArray *)mainColors {
  return @[[UIColor colorWithRed:137/255.0 green:196/255.0 blue:244/255.0 alpha:1.0], // jordy blue
           [UIColor colorWithRed:245/255.0 green:143/255.0 blue:132/255.0 alpha:1.0], // ibis wing color
           [UIColor colorWithRed:255/255.0 green:164/255.0 blue:0/255.0 alpha:1.0], // bright golden yellow
           [UIColor colorWithRed:135/255.0 green:211/255.0 blue:124/255.0 alpha:1.0],  // gossip green
           [UIColor colorWithRed:190/255.0 green:144/255.0 blue:212/255.0 alpha:1.0], // light wisteria - light purple
           [UIColor colorWithRed:75/255.0  green:119/255.0 blue:190/255.0 alpha:1.0], // Steel blue
           [UIColor colorWithRed:155/255.0 green:89/255.0  blue:182/255.0 alpha:1.0], // Wisteria purple
           [UIColor colorWithRed:245/255.0 green:215/255.0 blue:110/255.0 alpha:1.0], // cream can
           [UIColor colorWithRed:189/255.0 green:195/255.0 blue:199/255.0 alpha:1.0], // Silver sand grey
           [UIColor colorWithRed:64/255.0  green:122/255.0 blue:82/255.0  alpha:1.0], // Patina dark green
           [UIColor colorWithRed:161/255.0 green:121/255.0 blue:23/255.0 alpha:1.0], // rapeseed brown-ish
           [UIColor colorWithRed:157/255.0 green:41/255.0 blue:51/255.0 alpha:1.0], // cochineel red
           [UIColor colorWithRed:0/255.0 green:49/255.0 blue:113/255.0 alpha:1.0], // navy blue
           [UIColor colorWithRed:249/255.0 green:105/255.0 blue:14/255.0 alpha:1.0] // ecstasy
           ];
}

+ (NSString *(^)(RUserSettings *, double))makeYaxisLabelBlkWithType:(NSString *)type isPortraitMode:(BOOL)isPortraitMode {
  BOOL truncate = ![PEUIUtils isIpad] && !isPortraitMode;
  return ^(RUserSettings *userSettings, double max) {
    if (max > 999999) {
      return [NSString stringWithFormat:@"in millions of %@", type];
    } else if (max > 99999) {
      return truncate ? [NSString stringWithFormat:@"in hund. of thous. of %@", type] : [NSString stringWithFormat:@"in hundreds of thousands of %@", type];
    } else if (max > 9999) {
      return truncate ? [NSString stringWithFormat:@"in tens of thous. of %@", type] : [NSString stringWithFormat:@"in tens of thousands of %@", type];
    } else if (max > 999) {
      return [NSString stringWithFormat:@"in thousands of %@", type];
    } else {
      return [NSString stringWithFormat:@"%@", type];
    }
  };
}

+ (NSString *(^)(RUserSettings *, double))makeWeightYaxisLabelBlkIsPortraitMode:(BOOL)isPortraitMode {
  return ^(RUserSettings *userSettings, double max) {
    NSString *type = [RUtils weightUnitNameForUomId:userSettings.weightUom];
    return [self makeYaxisLabelBlkWithType:type isPortraitMode:isPortraitMode](userSettings, max);
  };
}

+ (NSString *(^)(RUserSettings *, double))makeSizeYaxisLabelBlkIsPortraitMode:(BOOL)isPortraitMode {
  return ^(RUserSettings *userSettings, double max) {
    NSString *type = [RUtils sizeUnitNameForUomId:userSettings.sizeUom];
    return [self makeYaxisLabelBlkWithType:type isPortraitMode:isPortraitMode](userSettings, max);
  };
}

+ (double)yaxisScalingFactorForMaxValue:(double)max {
  if (max > 999999) {
    return 0.000001;
  } else if (max > 99999) {
    return 0.00001;
  } else if (max > 9999) {
    return 0.0001;
  } else if (max > 999) {
    return 0.001;
  } else {
    return 1.0;
  }
}

+ (void)configureChartLoadingHud:(MBProgressHUD *)progressHud {
  progressHud.removeFromSuperViewOnHide = YES;
  progressHud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
  progressHud.bezelView.color = [UIColor clearColor];
}

+ (UIView *)viewForHudDisplayForTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple {
  if (chartAndLoaderTuple.noChartDataPanel) {
    return chartAndLoaderTuple.chartCardPanel;
  } else if (chartAndLoaderTuple.lineChartView) {
    return chartAndLoaderTuple.lineChartView;
  } else {
    return chartAndLoaderTuple.pieChartView;
  }
}

+ (UIButton *(^)(NSString *))jumpButtonMaker {
  return ^ UIButton * (NSString *title) {
    UIButton *jumpButton = [PEUIUtils buttonWithKey:title
                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]]
                                    backgroundColor:[UIColor rikerAppBlackResultantNavbarColor]
                                          textColor:[UIColor whiteColor]
                       disabledStateBackgroundColor:nil
                             disabledStateTextColor:nil
                                    verticalPadding:12.0
                                  horizontalPadding:14.0
                                       cornerRadius:5.0
                                             target:nil
                                             action:nil];
    [PEUIUtils applyBorderToView:jumpButton withColor:[UIColor whiteColor] width:1.25];
    return jumpButton;
  };
}

+ (UIView *)jumpPanelWithButtons:(NSArray *)jumpButtonsArray
                  relativeToView:(UIView *)relativeToView {
  UIView *jumpToPanel = [PEUIUtils panelWithFixedWidth:relativeToView.frame.size.width fixedHeight:0.0];
  [jumpToPanel setBackgroundColor:[UIColor rikerAppBlackResultantNavbarColor]];
  UIView *jumpToButtonsPanel = [PEUIUtils panelOfBrickLayedViewsFromItems:jumpButtonsArray
                                                                viewMaker:^UIView *(NSInteger i, id __) { return jumpButtonsArray[i]; }
                                                                extraView:nil
                                                           availableWidth:relativeToView.frame.size.width
                                                                 hpadding:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:8.0 iphone6PlusWidth:10.0 ipad:14.0]
                                                                 vpadding:8.0];
  [PEUIUtils setFrameHeight:jumpToButtonsPanel.frame.size.height + 20.0 ofView:jumpToPanel];
  [PEUIUtils placeView:jumpToButtonsPanel inMiddleOf:jumpToPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  return jumpToPanel;
}

#pragma mark - Colors

- (void)configureColors {
  [self configureColorsWithMuscles:nil];
}

- (void)configureColorsWithMuscles:(NSArray *)muscles {
  NSArray *mainColors = [RAbstractChartController mainColors];
  self.bodySegmentColors[@(UPPER_BODY_SEGMENT_ID)] = mainColors[0];
  self.bodySegmentColors[@(LOWER_BODY_SEGMENT_ID)] = mainColors[1];

  self.muscleGroupColors[@(SHOULDER_MG_ID)]   = mainColors[0];
  self.muscleGroupColors[@(CHEST_MG_ID)]      = mainColors[1];
  self.muscleGroupColors[@(TRICEP_MG_ID)]     = mainColors[2];
  self.muscleGroupColors[@(CORE_MG_ID)]        = mainColors[3];
  self.muscleGroupColors[@(FOREARMS_MG_ID)]   = mainColors[4];
  self.muscleGroupColors[@(BACK_MG_ID)]       = mainColors[5];
  self.muscleGroupColors[@(BICEPS_MG_ID)]     = mainColors[6];

  self.muscleGroupColors[@(GLUTES_MG_ID)]     = mainColors[7];
  self.muscleGroupColors[@(QUADRICEPS_MG_ID)] = mainColors[8];
  self.muscleGroupColors[@(HAMSTRINGS_MG_ID)] = mainColors[9];
  self.muscleGroupColors[@(CALVES_MG_ID)]     = mainColors[10];
  self.muscleGroupColors[@(HIP_ABDUCTORS_MG_ID)] = mainColors[11];
  self.muscleGroupColors[@(HIP_FLEXORS_MG_ID)] = mainColors[12];

  self.lowerBodyMuscleGroupColors[@(GLUTES_MG_ID)] = mainColors[7];
  self.lowerBodyMuscleGroupColors[@(QUADRICEPS_MG_ID)] = mainColors[8];
  self.lowerBodyMuscleGroupColors[@(HAMSTRINGS_MG_ID)] = mainColors[9];
  self.lowerBodyMuscleGroupColors[@(CALVES_MG_ID)] = mainColors[10];
  self.lowerBodyMuscleGroupColors[@(HIP_ABDUCTORS_MG_ID)] = mainColors[11];
  self.lowerBodyMuscleGroupColors[@(HIP_FLEXORS_MG_ID)] = mainColors[12];

  self.movementVariantColors[@(BARBELL_MOVEMENT_VARIANT_ID)] = mainColors[0];
  self.movementVariantColors[@(DUMBBELL_MOVEMENT_VARIANT_ID)] = mainColors[1];
  self.movementVariantColors[@(MACHINE_MOVEMENT_VARIANT_ID)] = mainColors[2];
  self.movementVariantColors[@(SMITH_MACHINE_MOVEMENT_VARIANT_ID)] = mainColors[3];
  self.movementVariantColors[@(CABLE_MOVEMENT_VARIANT_ID)] = mainColors[4];
  self.movementVariantColors[@(CURL_BAR_MOVEMENT_VARIANT_ID)] = mainColors[5];
  self.movementVariantColors[@(SLED_MOVEMENT_VARIANT_ID)] = mainColors[6];
  self.movementVariantColors[@(BODY_MOVEMENT_VARIANT_ID)] = mainColors[7];
  self.movementVariantColors[@(KETTLEBELL_MOVEMENT_VARIANT_ID)] = mainColors[8];

  if (muscles) {
    void (^setMuscleColors)(NSArray *, NSNumber *, NSMutableDictionary *, NSArray *) = ^(NSArray *entities, NSNumber *muscleGroupId, NSMutableDictionary *muscleColors, NSArray *colors) {
      NSMutableDictionary *entityColors = muscleColors[muscleGroupId];
      NSInteger colorIndex = 0;
      for (RMuscle *entity in entities) {
        if ([entity.muscleGroupId isEqualToNumber:muscleGroupId]) {
          entityColors[entity.localMasterIdentifier] = colors[colorIndex];
          colorIndex++;
        }
      }
    };
    self.muscleColors[@(SHOULDER_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(CHEST_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(TRICEP_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(CORE_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(BACK_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(HAMSTRINGS_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(BICEPS_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(FOREARMS_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(QUADRICEPS_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(CALVES_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(GLUTES_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(HIP_ABDUCTORS_MG_ID)] = [NSMutableDictionary dictionary];
    self.muscleColors[@(HIP_FLEXORS_MG_ID)] = [NSMutableDictionary dictionary];
    setMuscleColors(muscles, @(SHOULDER_MG_ID), self.muscleColors, mainColors);
    setMuscleColors(muscles, @(CHEST_MG_ID), self.muscleColors, mainColors);
    setMuscleColors(muscles, @(TRICEP_MG_ID), self.muscleColors, mainColors);
    setMuscleColors(muscles, @(CORE_MG_ID), self.muscleColors, mainColors);
    setMuscleColors(muscles, @(BACK_MG_ID), self.muscleColors, mainColors);
    setMuscleColors(muscles, @(HAMSTRINGS_MG_ID), self.muscleColors, @[mainColors[9]]);
    setMuscleColors(muscles, @(BICEPS_MG_ID), self.muscleColors, @[mainColors[6]]);
    setMuscleColors(muscles, @(FOREARMS_MG_ID), self.muscleColors, @[mainColors[4]]);
    setMuscleColors(muscles, @(QUADRICEPS_MG_ID), self.muscleColors, @[mainColors[8]]);
    setMuscleColors(muscles, @(CALVES_MG_ID), self.muscleColors, @[mainColors[10]]);
    setMuscleColors(muscles, @(GLUTES_MG_ID), self.muscleColors, @[mainColors[7]]);
    setMuscleColors(muscles, @(HIP_ABDUCTORS_MG_ID), self.muscleColors, @[mainColors[11]]);
    setMuscleColors(muscles, @(HIP_FLEXORS_MG_ID), self.muscleColors, @[mainColors[12]]);
  }
}

#pragma mark - Chart Section Maker

+ (ChartSectionPanelMaker)chartSectionPanelMakerRelativeToView:(UIView *)relativeToView {
  CGFloat hpadding = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:16.0 iphone6PlusWidth:18.0 ipad:24.0];
  return ^RChartAndLoaderTuple * (NSString *title, NSAttributedString *description, BOOL areIndividualMuscleDistributionCharts) {
    RChartAndLoaderTuple *chartAndLoaderTuple = [[RChartAndLoaderTuple alloc] init];
    UIView *panel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
    [panel setBackgroundColor:[UIColor rikerAppBlackResultantNavbarColor]];
    [PEUIUtils styleViewForIpad:panel];
    UIButton *(^makeJumpButton)(NSString *) = [self jumpButtonMaker];
    chartAndLoaderTuple.jumptToTopButton = makeJumpButton(@"top");
    UILabel *titleLabel =
    [PEUIUtils labelWithKey:title
                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                      iphone6Width:UIFontTextStyleTitle3
                                                                                  iphone6PlusWidth:UIFontTextStyleTitle2
                                                                                              ipad:UIFontTextStyleTitle2]]
            backgroundColor:[UIColor clearColor]
                  textColor:[UIColor cloudsColor]
        verticalTextPadding:5.0
                 fitToWidth:panel.frame.size.width - (hpadding * 2) - (chartAndLoaderTuple.jumptToTopButton.frame.size.width + 20.0)];
    CGFloat availableWidth = panel.frame.size.width - (hpadding * 2);
    UILabel *descriptionLabel =
    [PEUIUtils labelWithAttributeText:description
                                 font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                      backgroundColor:[UIColor clearColor]
                            textColor:[UIColor cloudsColor]
                  verticalTextPadding:5.0
                           fitToWidth:availableWidth];
    NSMutableArray *jumpButtonsArray = [NSMutableArray array];
    chartAndLoaderTuple.jumpToAllButton = makeJumpButton(@"all");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToAllButton];
    chartAndLoaderTuple.jumpToUpperBodyButton = makeJumpButton(@"upper body");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToUpperBodyButton];
    chartAndLoaderTuple.jumpToShouldersButton = makeJumpButton(@"shoulders");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToShouldersButton];
    chartAndLoaderTuple.jumpToChestButton = makeJumpButton(@"chest");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToChestButton];
    chartAndLoaderTuple.jumpToBackButton = makeJumpButton(@"back");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToBackButton];
    if (!areIndividualMuscleDistributionCharts) {
      chartAndLoaderTuple.jumpToBicepsButton = makeJumpButton(@"biceps");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToBicepsButton];
    }
    chartAndLoaderTuple.jumpToTricepsButton = makeJumpButton(@"triceps");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToTricepsButton];
    if (!areIndividualMuscleDistributionCharts) {
      chartAndLoaderTuple.jumpToForearmsButton = makeJumpButton(@"forearms");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToForearmsButton];
    }
    chartAndLoaderTuple.jumpToAbsButton = makeJumpButton(@"core");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToAbsButton];
    chartAndLoaderTuple.jumpToLowerBodyButton = makeJumpButton(@"lower body");
    [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToLowerBodyButton];
    if (!areIndividualMuscleDistributionCharts) {
      chartAndLoaderTuple.jumpToQuadsButton = makeJumpButton(@"quads");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToQuadsButton];
      chartAndLoaderTuple.jumpToHamstringsButton = makeJumpButton(@"hamstrings");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToHamstringsButton];
      chartAndLoaderTuple.jumpToCalfsButton = makeJumpButton(@"calfs");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToCalfsButton];
      chartAndLoaderTuple.jumpToGlutesButton = makeJumpButton(@"glutes");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToGlutesButton];
      chartAndLoaderTuple.jumpToHipAbductorsButton = makeJumpButton(@"hip abductors");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToHipAbductorsButton];
      chartAndLoaderTuple.jumpToHipFlexorsButton = makeJumpButton(@"hip flexors");
      [jumpButtonsArray addObject:chartAndLoaderTuple.jumpToHipFlexorsButton];
    }
    UIView *jumpToButtonsPanel = [PEUIUtils panelOfBrickLayedViewsFromItems:jumpButtonsArray
                                                                  viewMaker:^UIView *(NSInteger i, id __) { return jumpButtonsArray[i]; }
                                                                  extraView:nil
                                                             availableWidth:availableWidth
                                                                   hpadding:8.0
                                                                   vpadding:8.0];
    // place views
    CGFloat totalHeight = 0.0;
    CGFloat vpadding = 15.0;
    [PEUIUtils placeView:titleLabel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:hpadding];
    totalHeight += titleLabel.frame.size.height + vpadding;
    [PEUIUtils placeView:chartAndLoaderTuple.jumptToTopButton atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:10.0 hpadding:10.0];
    vpadding = 20.0;
    [PEUIUtils placeView:descriptionLabel below:titleLabel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
    totalHeight += descriptionLabel.frame.size.height + vpadding;
    vpadding = 10.0;
    [PEUIUtils placeView:jumpToButtonsPanel below:descriptionLabel onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
    totalHeight += jumpToButtonsPanel.frame.size.height + vpadding;
    totalHeight += 15; // some bottom margin
    [PEUIUtils setFrameHeight:totalHeight ofView:panel];
    chartAndLoaderTuple.chartPanelView = panel;
    return chartAndLoaderTuple;
  };
}

#pragma mark - Chart Title Makers

+ (UILabel *)makeChartTitleLabel:(NSString *)title fitToWidth:(CGFloat)fitToWidth {
  UIFont *font = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:32.0]
                                                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                      iphone6Width:UIFontTextStyleCaption1
                                                                                                                  iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                              ipad:UIFontTextStyleTitle3]]];
  UILabel *titleLabel =
  [PEUIUtils labelWithKey:title
                     font:font
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor rikerAppBlack]
      verticalTextPadding:4.0
               fitToWidth:fitToWidth];
  [titleLabel setTextAlignment:NSTextAlignmentCenter];
  return titleLabel;
}

+ (UILabel *)makeChartSubTitleLabel:(NSString *)subTitle fitToWidth:(CGFloat)fitToWidth {
  UIFont *font = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0]
                                                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                                                                      iphone6Width:UIFontTextStyleCaption2
                                                                                                                  iphone6PlusWidth:UIFontTextStyleCaption1
                                                                                                                              ipad:UIFontTextStyleSubheadline]]];
  UILabel *subTitleLabel =
  [PEUIUtils labelWithKey:subTitle
                     font:font
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor rikerAppBlack]
      verticalTextPadding:2.0
               fitToWidth:fitToWidth];
  [subTitleLabel setTextAlignment:NSTextAlignmentCenter];
  return subTitleLabel;
}

#pragma mark - Chart Helpers

- (void)nullOutMainContentPanel {}

- (NSDate *)veryFirstLoggedAt {
  return _veryFirstSetLoggedAt;
}

- (NSDate *)veryLastLoggedAt {
  return _veryLastSetLoggedAt;
}

+ (void)initializeNoDataForChart:(ChartViewBase *)chartView {
  chartView.noDataFont = [UIFont boldSystemFontOfSize:[PEUIUtils valueIfiPhone5Width:16.0
                                                                        iphone6Width:18.0
                                                                    iphone6PlusWidth:24.0
                                                                                ipad:28.0]];
  chartView.noDataText = @""; //@"Charts not loaded.";
  chartView.noDataTextColor = [UIColor rikerAppBlack];
}

#pragma mark - Chart Panel Maker

+ (NSArray *)makeChartPanelWithTitle:(NSString *)title
                          entityType:(NSString *)entityType
                         isLineChart:(BOOL)isLineChart
                             chartId:(NSString *)chartId
                            subTitle:(NSString *)subTitle
                          chartMaker:(UIView *(^)(UIView *))chartMaker
                     helpDescription:(NSAttributedString *)helpDescription
                        chartConfigs:(RChartConfig *(^)(NSString *))chartConfigs
                      relativeToView:(UIView *)relativeToView
                veryFirstLoggedAtBlk:(NSDate *(^)(void))veryFirstLoggedAtBlk
                 vertLastLoggedAtBlk:(NSDate *(^)(void))veryLastLoggedAtBlk
                 chartConfigCategory:(RChartConfigCategory)chartConfigCategory
                          controller:(UIViewController *)controller
                           uitoolkit:(PEUIToolkit *)uitoolkit
                       screenToolkit:(RScreenToolkit *)screenToolkit
                        panelToolkit:(RPanelToolkit *)panelToolkit
                             logging:(BOOL)logging {
  UIView *chartPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [chartPanel setBackgroundColor:[UIColor clearColor]];
  CGFloat chartCardPanelWidth = ([PEUIUtils valueIfiPhone5Width:0.925
                                                  iphone6Width:0.925
                                              iphone6PlusWidth:0.925
                                                          ipad:0.985] * relativeToView.frame.size.width) - [PEUIUtils iphoneXSafeInsetsSide];
  UIView *chartCardPanel = [PEUIUtils panelWithFixedWidth:chartCardPanelWidth fixedHeight:0.0];
  [chartCardPanel setBackgroundColor:[UIColor colorWithRed:(0xF9 / 255.0) green:(0xF9 / 255.0) blue:(0xF9 / 255.0) alpha:1.0]];
  CGFloat chartTitleHpadding = [PEUIUtils valueIfiPhone5Width:50.0
                                                 iphone6Width:50.0
                                             iphone6PlusWidth:54.0
                                                         ipad:60.0];
  CGFloat titleFitToWidth = chartCardPanel.frame.size.width - (chartTitleHpadding * 2);
  UILabel *chartTitle = [self makeChartTitleLabel:title fitToWidth:titleFitToWidth];
  __block UIImage *settingsBtnImage;
  UIButton *settingsBtn = nil;
  void (^setViewsForConfig)(RChartConfig *) = ^(RChartConfig *chartConfig) {
    settingsBtnImage = [UIImage imageNamed:SETTINGS_ICON_SET_IMAGE_NAME];
  };
  void (^setViewsForNoConfig)(void) = ^{
    settingsBtnImage = [UIImage imageNamed:SETTINGS_ICON_UNSET_IMAGE_NAME];
  };
  RChartConfig *chartConfig = chartConfigs(chartId);
  if (chartConfig) {
    setViewsForConfig(chartConfig);
  } else {
    setViewsForNoConfig();
  }
  settingsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, settingsBtnImage.size.width, settingsBtnImage.size.height)];
  [settingsBtn setImage:settingsBtnImage forState:UIControlStateNormal];
  [settingsBtn bk_addEventHandler:^(id sender) {
    RChartConfig *chartConfig = chartConfigs(chartId);
    BOOL isNewConfig = NO;
    NSDate *veryFirstLoggedAt = nil;
    NSDate *veryLastLoggedAt = nil;
    if (!chartConfig) {
      veryFirstLoggedAt = veryFirstLoggedAtBlk();
      veryLastLoggedAt = veryLastLoggedAtBlk();
      isNewConfig = YES;
      chartConfig = [RChartConfig chartConfig];
      chartConfig.chartId = chartId;
      chartConfig.category = chartConfigCategory;
      chartConfig.startDate = [PEUtils dateWithoutTimeFromDate:veryFirstLoggedAt];
      chartConfig.endDate = [[PEUtils dateWithoutTimeFromDate:veryLastLoggedAt] dateByAddingDays:1];
      chartConfig.aggregateBy = @([RAbstractChartController suggestedAggregateByWithFirstDate:veryFirstLoggedAt lastDate:veryLastLoggedAt]);
    }
    RChartFilterScreen *chartConfigScreen =
    [[RChartFilterScreen alloc] initWithTitle:@"Chart Config"
                              mainHeadingText:title
                                   entityType:entityType
                       enableLineChartOptions:isLineChart
                        enablePieChartOptions:!isLineChart
                                veryFirstDate:veryFirstLoggedAt ? veryFirstLoggedAt : veryFirstLoggedAtBlk()
                                 veryLastDate:veryLastLoggedAt ? veryLastLoggedAt : veryLastLoggedAtBlk()
                                  chartConfig:chartConfig
                             clearButtonTitle:isNewConfig ? nil : @"Clear"
                                     clearBlk:^{
                                       [[NSNotificationCenter defaultCenter] postNotificationName:RChartSettingsClearedNotification
                                                                                           object:nil
                                                                                         userInfo:@{ @"chartId": chartId,
                                                                                                     @"chartCategory": @(chartConfigCategory) }];
                                     }
                                      doneBlk:^(RChartConfig *chartConfig) {
                                        [[NSNotificationCenter defaultCenter] postNotificationName:RChartSettingsDoneNotification
                                                                                            object:nil
                                                                                          userInfo:@{ @"chartId": chartId,
                                                                                                      @"chartConfig": chartConfig,
                                                                                                      @"chartCategory": @(chartConfigCategory)
                                                                                                      }];
                                      }
                                    uitoolkit:uitoolkit
                                screenToolkit:screenToolkit
                                 panelToolkit:panelToolkit];
    [controller presentViewController:[PEUIUtils navigationControllerWithController:chartConfigScreen
                                                                navigationBarHidden:NO]
                             animated:YES
                           completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *chartSubTitle = nil;
  if (subTitle) {
    chartSubTitle = [self makeChartSubTitleLabel:subTitle fitToWidth:titleFitToWidth];
  }
  UIView *chartViewContainer = chartMaker(chartCardPanel);
  UIButton *chartHelpButton = [RAbstractChartController makeInfoIconWithAlertTitle:title
                                                                  alertDescription:helpDescription
                                                                     fontTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                                             iphone6Width:UIFontTextStyleBody
                                                                                                         iphone6PlusWidth:UIFontTextStyleBody
                                                                                                                     ipad:UIFontTextStyleTitle3]
                                                                      infoIconSize:[self chartCircleHelpIconSize]
                                                                   backgroundColor:[UIColor rikerAppBlackSemiClear]
                                                                         textColor:[UIColor whiteColor]
                                                                        controller:controller];
  CGFloat totalHeight = 0.0;
  CGFloat chartCardPanelHeight = 0.0;
  CGFloat vpadding = 8.0;
  CGFloat settingsBtnPadding = 8.0;
  [PEUIUtils placeView:chartHelpButton atTopOf:chartCardPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:settingsBtnPadding hpadding:settingsBtnPadding];
  if (chartSubTitle) {
    vpadding = [PEUIUtils valueIfiPhone5Width:4.0 iphone6Width:4.0 iphone6PlusWidth:5.0 ipad:8.0];
  } else {
    vpadding = [PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:8.0 iphone6PlusWidth:10.0 ipad:14.0];
  }
  [PEUIUtils placeView:chartTitle
               atTopOf:chartCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  CGFloat chartTitleVPadding = vpadding;
  chartCardPanelHeight += chartTitle.frame.size.height + vpadding;
  UIView *topView = chartTitle;
  if (settingsBtn) {
    [PEUIUtils placeView:settingsBtn atTopOf:chartCardPanel withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:settingsBtnPadding hpadding:settingsBtnPadding];
  }
  if (chartSubTitle) {
    vpadding = 4.0;
    [PEUIUtils placeView:chartSubTitle
                   below:chartTitle
                    onto:chartCardPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:chartCardPanel
                vpadding:vpadding
                hpadding:0.0];
    chartCardPanelHeight += chartSubTitle.frame.size.height + vpadding;
    topView = chartSubTitle;
  }
  if (chartSubTitle) {
    vpadding = 15.0;
  } else {
    vpadding = 25.0;
  }
  [PEUIUtils placeView:chartViewContainer
                 below:topView
                  onto:chartCardPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:chartCardPanel
              vpadding:vpadding
              hpadding:0.0];
  chartCardPanelHeight += chartViewContainer.frame.size.height + vpadding;
  chartCardPanelHeight += [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:6.0 iphone6PlusWidth:8.0 ipad:15.0]; // some extra padding for good measure
  [PEUIUtils setFrameHeight:chartCardPanelHeight ofView:chartCardPanel];
  [chartCardPanel setTag:RCHART_CARD_PANEL_TAG];
  [PEUIUtils placeView:chartCardPanel atTopOf:chartPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
  totalHeight += chartCardPanel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeight ofView:chartPanel];
  [PEUIUtils cardifyView:chartPanel];
  NSMutableArray *returnTuple = [NSMutableArray array];
  [returnTuple addObject:chartPanel];
  [returnTuple addObject:settingsBtn];
  [returnTuple addObject:chartCardPanel];
  [returnTuple addObject:chartTitle];
  [returnTuple addObject:@(chartTitleVPadding)];
  if (chartSubTitle) {
    [returnTuple addObject:chartSubTitle];
  }
  return returnTuple;
}

#pragma mark - Pie Chart Helpers

+ (CGFloat)pieChartHeight {
  return [PEUIUtils valueIfiPhone5Width:275.0 iphone6Width:290.0 iphone6PlusWidth:315.0 ipad:385.0];
}

+ (PieChartView *)templatePieChartViewWithWidth:(CGFloat)width
                                         height:(CGFloat)height
                                       delegate:(id<ChartViewDelegate>)delegate {
  PieChartView *pieChartView = [[PieChartView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
  pieChartView.delegate = delegate;
  pieChartView.usePercentValuesEnabled = YES;
  pieChartView.drawHoleEnabled = NO;
  pieChartView.drawCenterTextEnabled = NO;
  pieChartView.rotationEnabled = NO;
  [pieChartView setUserInteractionEnabled:NO];
  pieChartView.highlightPerTapEnabled = NO;
  pieChartView.chartDescription.text = nil;
  [RAbstractChartController initializeNoDataForChart:pieChartView];
  ChartLegend *legend = pieChartView.legend;
  legend.yOffset = 0.0;
  legend.wordWrapEnabled = YES;
  legend.font = [RAbstractChartController legendFont];
  return pieChartView;
}

+ (PieChartData *)pieChartDataFromDataSet:(PieChartDataSet *)dataSet
                          numberFormatter:(NSNumberFormatter *)numberFormatter
                            valueFontSize:(CGFloat)valueFontSize {
  PieChartData *pieChartData = [[PieChartData alloc] initWithDataSet:dataSet];
  [pieChartData setValueFormatter:[[ChartDefaultValueFormatter alloc] initWithFormatter:numberFormatter]];
  [pieChartData setValueFont:[UIFont systemFontOfSize:valueFontSize]];
  [pieChartData setValueTextColor:[UIColor blackColor]];
  return pieChartData;
}

+ (PieChartDataEntry *)pieChartDataEntryFromValueLabelPair:(RPieSliceDataTuple *)pieSliceTuple {
  return [[PieChartDataEntry alloc] initWithValue:pieSliceTuple.value.doubleValue
                                            label:pieSliceTuple.name];
}

+ (PieChartAndLoaderTupleMaker)pieChartAndLoaderTupleMakerWithChartHeight:(CGFloat)chartHeight
                                                        noDataHeadingText:(NSString *)noDataHeadingText
                                                          noDataLabelText:(NSString *)noDataLabelText
                                                               entityType:(NSString *)entityType
                                                             chartConfigs:(RChartConfig *(^)(NSString *))chartConfigs
                                                     veryFirstLoggedAtBlk:(NSDate *(^)(void))veryFirstLoggedAtBlk
                                                      veryLastLoggedAtBlk:(NSDate *(^)(void))veryLastLoggedAtBlk
                                                                fetchMode:(RChartDataFetchMode)fetchMode
                                                           relativeToView:(UIView *)relativeToView
                                                                 coordDao:(id<RCoordinatorDao>)coordDao
                                                               controller:(RAbstractChartController *)controller
                                                      chartConfigCategory:(RChartConfigCategory)chartConfigCategory
                                                                uitoolkit:(PEUIToolkit *)uitoolkit
                                                            screenToolkit:(RScreenToolkit *)screenToolkit
                                                             panelToolkit:(RPanelToolkit *)panelToolkit
                                                                 headless:(BOOL)headless {
  CGFloat entryLabelFontSize = [PEUIUtils valueIfiPhone5Width:7.0 iphone6Width:7.5 iphone6PlusWidth:8.0 ipad:9.0];
  CGFloat valueLinePart1OffsetPercentage = [PEUIUtils valueIfiPhone5Width:0.85 iphone6Width:0.85 iphone6PlusWidth:0.85 ipad:0.85];
  CGFloat valueLinePart1Length = [PEUIUtils valueIfiPhone5Width:0.375 iphone6Width:0.40 iphone6PlusWidth:0.40 ipad:0.40];
  CGFloat valueLinePart2Length = [PEUIUtils valueIfiPhone5Width:0.475 iphone6Width:0.50 iphone6PlusWidth:0.50 ipad:0.50];
  CGFloat datasetValueFontSize = [PEUIUtils valueIfiPhone5Width:7.0 iphone6Width:9.0 iphone6PlusWidth:10.0 ipad:14.0];
  return ^RChartAndLoaderTuple *(NSString *chartId,
                                 NSString *title,
                                 NSString *subTitle,
                                 PieChartDataContainerMaker makePieChartDataContainer,
                                 NSDictionary *entityColors,
                                 NSAttributedString *helpDescription,
                                 NSArray *(^sortTriples)(NSArray *),
                                 RChartSectionJumpId jumpId,
                                 BOOL logging) {
    RChartAndLoaderTuple *chartAndLoaderTuple = [[RChartAndLoaderTuple alloc] init];
    RPieChartDataLoader pieChartDataLoader = ^NSArray * (id defaultChartData,
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
                                                         NSDictionary *movementVariantsDict) {
      NSDictionary *dataDict;
      RChartConfig *chartConfig = chartConfigs(chartId);
      NSString *settingsButtonIconImageName = SETTINGS_ICON_UNSET_IMAGE_NAME;
      if (chartConfig) {
        settingsButtonIconImageName = SETTINGS_ICON_SET_IMAGE_NAME;
        NSArray *filteredSets = [coordDao ascendingSetsForUser:user
                                             onOrAfterLoggedAt:chartConfig.startDate
                                            onOrBeforeLoggedAt:chartConfig.endDate
                                                         error:[RUtils localFetchErrorHandlerMaker]()];
        RChartStrengthRawData *filteredChartData = [RUtils chartStrengthRawDataForUser:user
                                                                          userSettings:userSettings
                                                                          bodySegments:bodySegments
                                                                      bodySegmentsDict:bodySegmentsDict
                                                                          muscleGroups:muscleGroups
                                                                      muscleGroupsDict:muscleGroupsDict
                                                                               muscles:muscles
                                                                           musclesDict:musclesDict
                                                                             movements:movements
                                                                         movementsDict:movementsDict
                                                                      movementVariants:movementVariants
                                                                  movementVariantsDict:movementVariantsDict
                                                                                  sets:filteredSets
                                                                             fetchMode:fetchMode
                                                                       calcPercentages:NO
                                                                          calcAverages:NO];
        dataDict = makePieChartDataContainer(filteredChartData);
      } else {
        dataDict = makePieChartDataContainer(defaultChartData);
      }
      NSArray *pieSliceDataTuples = dataDict.allValues;
      if (sortTriples) {
        pieSliceDataTuples = sortTriples(pieSliceDataTuples);
      }
      BOOL noData = YES;
      NSMutableArray *colorScheme = [NSMutableArray array];
      for (RPieSliceDataTuple *pieSliceDataTuple in pieSliceDataTuples) {
        PieChartDataEntry *dataEntry = [self pieChartDataEntryFromValueLabelPair:pieSliceDataTuple];
        if (dataEntry.value > 0) {
          NSNumber *localMasterIdentifier = pieSliceDataTuple.localMasterIdentifier;
          [colorScheme addObject:entityColors[localMasterIdentifier]];
          noData = NO;
        }
      }
      id pieChartData = [NSNull null];
      if (!noData) {
        NSMutableArray *dataEntries = [NSMutableArray arrayWithCapacity:pieSliceDataTuples.count];
        for (RPieSliceDataTuple *pieSliceDataTuple in pieSliceDataTuples) {
          PieChartDataEntry *dataEntry = [self pieChartDataEntryFromValueLabelPair:pieSliceDataTuple];
          if (logging) {
            NSLog(@"dataEntry.value: %f, label: %@", dataEntry.value, dataEntry.label);
          }
          if (dataEntry.value > 0.0) {
            [dataEntries addObject:dataEntry];
          }
        }
        PieChartDataSet *dataSet = [[PieChartDataSet alloc] initWithEntries:dataEntries label:nil];
        dataSet.colors = colorScheme;
        if (chartConfig.suppressPieSliceLabels) {
          dataSet.drawValuesEnabled = NO;
        } else {
          dataSet.entryLabelFont = [UIFont systemFontOfSize:entryLabelFontSize];
          dataSet.drawValuesEnabled = YES;
          dataSet.valueLineColor = [UIColor rikerAppBlack];
          dataSet.valueLinePart1OffsetPercentage = valueLinePart1OffsetPercentage;
          dataSet.valueLinePart1Length = valueLinePart1Length;
          dataSet.valueLinePart2Length = valueLinePart2Length;
          dataSet.xValuePosition = PieChartValuePositionOutsideSlice;
        }
        pieChartData = [self pieChartDataFromDataSet:dataSet numberFormatter:[self percentNumberFormatter] valueFontSize:datasetValueFontSize];
      }
      return @[pieChartData,
               @(chartConfig.suppressPieSliceLabels),
               settingsButtonIconImageName,
               @(chartConfig != nil)];
    };
    chartAndLoaderTuple.pieChartDataLoader = pieChartDataLoader;
    NSArray *chartPanelAndSettingsButton =
    [RAbstractChartController makeChartPanelWithTitle:title
                                           entityType:entityType
                                          isLineChart:NO
                                              chartId:chartId
                                             subTitle:subTitle
                                           chartMaker:^UIView *(UIView *cardChartPanel) {
                                             PieChartView *pieChartView = [RAbstractChartController templatePieChartViewWithWidth:chartHeight height:chartHeight delegate:controller];
                                             RChartConfig *chartConfig = chartConfigs(chartId);
                                             if (chartConfig.suppressPieSliceLabels) {
                                               [pieChartView setDrawEntryLabelsEnabled:NO];
                                             }
                                             chartAndLoaderTuple.pieChartView = pieChartView;
                                             return pieChartView;
                                           }
                                      helpDescription:helpDescription
                                         chartConfigs:chartConfigs
                                       relativeToView:relativeToView
                                 veryFirstLoggedAtBlk:veryFirstLoggedAtBlk
                                  vertLastLoggedAtBlk:veryLastLoggedAtBlk
                                  chartConfigCategory:chartConfigCategory
                                           controller:controller
                                            uitoolkit:uitoolkit
                                        screenToolkit:screenToolkit
                                         panelToolkit:panelToolkit
                                              logging:logging];
    chartAndLoaderTuple.chartPanelView = chartPanelAndSettingsButton[0];
    chartAndLoaderTuple.settingsButton = chartPanelAndSettingsButton[1];
    chartAndLoaderTuple.chartCardPanel = chartPanelAndSettingsButton[2];
    chartAndLoaderTuple.chartTitleLabel = chartPanelAndSettingsButton[3];
    chartAndLoaderTuple.chartTitleVPadding = ((NSNumber *)chartPanelAndSettingsButton[4]).floatValue;
    if (chartPanelAndSettingsButton.count >= 6) {
      chartAndLoaderTuple.chartSubTitleLabel = chartPanelAndSettingsButton[5];
    }
    chartAndLoaderTuple.jumpId = jumpId;
    return chartAndLoaderTuple;
  };
}

#pragma mark - Line Chart Helpers

+ (CGFloat)lineChartHeight {
  if ([PEUIUtils isPortraitMode]) {
    return [PEUIUtils valueIfiPhone5Width:305.0 iphone6Width:325.0 iphone6PlusWidth:330.0 ipad:450.0];
  } else {
    return [PEUIUtils valueIfiPhone5Width:160.0 iphone6Width:185.0 iphone6PlusWidth:190.0 ipad:310.0];
  }
}

+ (void)configureMarkerOnLineChart:(LineChartView *)lineChartView isPercentage:(BOOL)isPercentage uom:(NSString *)uom {
  RBalloonMarker *marker = [[RBalloonMarker alloc] initWithUom:uom
                                                  isPercentage:isPercentage
                                                         color:[UIColor rikerAppBlackResultantNavbarColor]
                                                          font:[UIFont systemFontOfSize:16.0]
                                                     textColor:UIColor.whiteColor
                                                        insets:UIEdgeInsetsMake(8.0, 8.0, 20.0, 8.0)];
  marker.chartView = lineChartView;
  marker.minimumSize = CGSizeMake(80.f, 40.f);
  lineChartView.marker = marker;
}

+ (LineChartView *)templateLineChartViewWithWidth:(CGFloat)width
                                           height:(CGFloat)height
                                   xaxisFormatter:(id<IChartAxisValueFormatter>)xaxisFormatter
                                  xaxisLabelCount:(NSInteger)xaxisLabelCount
                                   yaxisFormatter:(id<IChartAxisValueFormatter>)yaxisFormatter
                                     yaxisMaximum:(CGFloat)yaxisMaximum
                                     yaxisMinimum:(NSDecimalNumber *)yaxisMinimum
                                         delegate:(id<ChartViewDelegate>)delegate {
  LineChartView *lineChartView = [[LineChartView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
  lineChartView.delegate = delegate;
  [lineChartView setUserInteractionEnabled:YES];
  lineChartView.highlightPerTapEnabled = YES;
  lineChartView.chartDescription.text = nil;
  lineChartView.chartDescription.enabled = YES;
  lineChartView.dragEnabled = NO;
  [lineChartView setScaleEnabled:NO];
  lineChartView.pinchZoomEnabled = NO;
  lineChartView.drawGridBackgroundEnabled = NO;
  [self initializeNoDataForChart:lineChartView];
  ChartXAxis *xAxis = lineChartView.xAxis;
  xAxis.labelCount = xaxisLabelCount;
  xAxis.centerAxisLabelsEnabled = YES;
  xAxis.drawGridLinesEnabled = YES;
  xAxis.gridLineDashLengths = @[@3.0f, @3.0f];
  xAxis.gridLineDashPhase = 0.0f;
  xAxis.gridColor = [UIColor silverColor];
  xAxis.granularityEnabled = YES;
  xAxis.granularity = 1;
  xAxis.valueFormatter = xaxisFormatter;
  xAxis.labelPosition = XAxisLabelPositionTop;
  xAxis.labelFont = [UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:8.0 iphone6PlusWidth:10.0 ipad:14.0]];
  xAxis.labelTextColor = [UIColor rikerAppBlack];
  ChartYAxis *leftAxis = lineChartView.leftAxis;
  [leftAxis removeAllLimitLines];
  leftAxis.axisMaximum = yaxisMaximum;
  if (yaxisMinimum) {
    leftAxis.axisMinimum = yaxisMinimum.floatValue;
  }
  leftAxis.gridLineDashLengths = @[@3.0f, @3.0f];
  leftAxis.gridColor = [UIColor silverColor];
  leftAxis.drawZeroLineEnabled = NO;
  leftAxis.drawLimitLinesBehindDataEnabled = NO;
  leftAxis.valueFormatter = yaxisFormatter;
  leftAxis.labelPosition = YAxisLabelPositionOutsideChart;
  leftAxis.labelFont = [UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:8.0 iphone6PlusWidth:10.0 ipad:14.0]];
  leftAxis.labelTextColor = [UIColor rikerAppBlack];
  lineChartView.rightAxis.enabled = NO;
  lineChartView.legend.form = ChartLegendFormLine;
  ChartLegend *legend = lineChartView.legend;
  legend.yOffset = 0.0;
  legend.xOffset = -15.0;
  legend.wordWrapEnabled = YES;
  legend.font = [self legendFont];
  return lineChartView;
}

+ (void)configureDataSet:(LineChartDataSet *)dataSet
               lineColor:(UIColor *)lineColor
               lineWidth:(CGFloat)lineWidth {
  NSInteger dataEntriesCount = dataSet.entryCount;
  if (dataEntriesCount > 10) {
    dataSet.drawCircleHoleEnabled = NO;
    dataSet.circleRadius = 2.0;
  } else if (dataEntriesCount > 5) {
    dataSet.drawCircleHoleEnabled = NO;
    dataSet.circleRadius = 3.0;
  } else if (dataEntriesCount > 4) {
    dataSet.drawCircleHoleEnabled = YES;
    dataSet.circleRadius = 4.5;
  } else if (dataEntriesCount > 3) {
    dataSet.drawCircleHoleEnabled = YES;
    dataSet.circleRadius = 5.0;
  } else if (dataEntriesCount > 2) {
    dataSet.drawCircleHoleEnabled = YES;
    dataSet.circleRadius = 5.25;
  } else if (dataEntriesCount > 1) {
    dataSet.drawCircleHoleEnabled = YES;
    dataSet.circleRadius = 5.5;
  } else if (dataEntriesCount > 0) { // one
    ChartDataEntry *chartDataEntry = dataSet.entries[0];
    if (chartDataEntry.y > 0.0) {
      dataSet.drawCircleHoleEnabled = YES;
      dataSet.circleRadius = 6.0;
    } else { // hide the point
      dataSet.drawCircleHoleEnabled = NO;
      dataSet.circleRadius = 0.0;
    }
  } else {
    dataSet.drawCircleHoleEnabled = NO;
    dataSet.circleRadius = 0.0;
  }
  dataSet.highlightEnabled = YES;
  [dataSet setDrawHighlightIndicators:YES];
  [dataSet setColor:lineColor];
  [dataSet setCircleColor:lineColor];
  [dataSet setLineWidth:lineWidth];
  dataSet.drawValuesEnabled = NO;
  dataSet.mode = LineChartModeHorizontalBezier;
}

+ (LineChartAndLoaderTupleMaker)lineChartAndLoaderTupleMakerWithChartHeight:(CGFloat)chartHeight
                                                            filteredDataBlk:(RFilteredDataBlk)filteredDataBlk
                                                            chartRawDataBlk:(RChartRawDataBlk)chartRawDataBlk
                                                         yaxisValueLabelBlk:(NSString *(^)(RUserSettings *, double maxValue))yaxisValueLabelBlk
                                                                maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                  yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                          yaxisFormatterBlk:(id<IChartAxisValueFormatter>(^)(double))yaxisFormatterBlk
                                                            yaxisMaximumBlk:(double(^)(double))yaxisMaximumBlk
                                                               yaxisMinimum:(NSDecimalNumber *)yaxisMinimum
                                                                ignoreZeros:(BOOL)ignoreZeros
                                                          noDataHeadingText:(NSString *)noDataHeadingText
                                                            noDataLabelText:(NSString *)noDataLabelText
                                                                 entityType:(NSString *)entityType
                                                               chartConfigs:(RChartConfig *(^)(NSString *))chartConfigs
                                                       veryFirstLoggedAtBlk:(NSDate *(^)(void))veryFirstLoggedAtBlk
                                                        veryLastLoggedAtBlk:(NSDate *(^)(void))veryLastLoggedAtBlk
                                                               isPercentage:(BOOL)isPercentage
                                                              uomDisplayBlk:(RUomDisplayBlk)uomDisplayBlk
                                                             relativeToView:(UIView *)relativeToView
                                                                   coordDao:(id<RCoordinatorDao>)coordDao
                                                          chartViewDelegate:(id<ChartViewDelegate>)chartViewDelegate
                                                        chartConfigCategory:(RChartConfigCategory)chartConfigCategory
                                                                 controller:(UIViewController *)controller
                                                                  uitoolkit:(PEUIToolkit *)uitoolkit
                                                              screenToolkit:(RScreenToolkit *)screenToolkit
                                                               panelToolkit:(RPanelToolkit *)panelToolkit
                                                                   headless:(BOOL)headless
                                                    entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                  fetchMode:(RChartDataFetchMode)fetchMode {
  return ^RChartAndLoaderTuple * (NSString *chartId,
                                  NSString *title,
                                  NSString *subTitle,
                                  NormalizedTimeSeriesCollectionMaker makeNormalizedTimeSeriesCollection,
                                  NSDictionary *entityColors,
                                  CGFloat lineWidth,
                                  NSAttributedString *helpDescription,
                                  NSArray *(^sortTriples)(NSArray *),
                                  RChartSectionJumpId jumpId,
                                  BOOL logging) {
    RChartAndLoaderTuple *chartAndLoaderTuple = [[RChartAndLoaderTuple alloc] init];
    chartAndLoaderTuple.isPercentage = isPercentage;
    chartAndLoaderTuple.uomDisplayBlk = uomDisplayBlk;
    RLineChartDataLoader lineChartDataLoader = ^NSArray * (id defaultChartRawData,
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
                                                           NSDate *defaultChartDataStartDate,
                                                           NSDate *defaultChartDataEndDate) {
      NSNumber *chartConfigLocalMasterIdentifier = nil;
      RChartConfig *chartConfig = chartConfigs(chartId);
      NSString *settingsButtonIconImageName = SETTINGS_ICON_UNSET_IMAGE_NAME;
      if (chartConfig) {
        chartConfigLocalMasterIdentifier = chartConfig.localMasterIdentifier;
        settingsButtonIconImageName = SETTINGS_ICON_SET_IMAGE_NAME;
      }
      id<IChartAxisValueFormatter> xaxisFormatter;
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      RLineChartDataCache *lineChartDataCache = [coordDao lineChartDataCacheForChartId:chartId
                                                                         chartConfigId:chartConfigLocalMasterIdentifier
                                                                                  user:user
                                                                                 error:errorBlk];
      if (lineChartDataCache) {
        DDLogInfo(@"In chart loading, cache HIT for chart identifier: [%@]", chartId);
        if (headless) {
          return nil;
        } else {
          xaxisFormatter = [[RDateValueFormatter alloc] initWithFormat:[RChartConfig xaxisDateFormatForAggregateByValue:lineChartDataCache.aggregateBy]];
          double maxDoubleValue = lineChartDataCache.maxValue.doubleValue;
          id<IChartAxisValueFormatter> yaxisFormatter = yaxisFormatterBlk(maxDoubleValue);
          double yaxisMaximum = yaxisMaximumBlk(maxDoubleValue);
          NSString *yaxisLabelText = nil;
          if (yaxisValueLabelBlk) {
            yaxisLabelText = yaxisValueLabelBlk(userSettings, maxDoubleValue);
          }
          NSArray *dataSets = lineChartDataCache.lineChartData.dataSets;
          NSInteger numDataSets = dataSets.count;
          for (int i = 0; i < numDataSets; i++) {
            LineChartDataSet *dataSet = dataSets[i];
            UIColor *lineColor = entityColors[dataSet.entityLocalMasterIdentifier];
            [self configureDataSet:dataSet lineColor:lineColor lineWidth:lineWidth];
          }
          return @[lineChartDataCache.lineChartData,
                   @(lineChartDataCache.xaxisLabelCount),
                   xaxisFormatter,
                   yaxisFormatter,
                   @(yaxisMaximum),
                   yaxisLabelText ? yaxisLabelText : [NSNull null],
                   settingsButtonIconImageName,
                   @(chartConfig != nil)];
        }
      } else {
        if (!headless) {
          DDLogInfo(@"In chart loading, cache MISS for chart identifier: [%@]", chartId);
        }
        NSDate *chartDataStartDate = defaultChartDataStartDate;
        NSDate *chartDataEndDate = defaultChartDataEndDate;
        RChartConfigAggregateBy defaultAggregateBy =
        [RAbstractChartController suggestedAggregateByWithFirstDate:defaultChartDataStartDate lastDate:defaultChartDataEndDate];
        RChartConfigAggregateBy aggregateBy = defaultAggregateBy;
        RNormalizedTimeSeriesTupleCollection *normalizedTimeSeriesCollection = nil;
        xaxisFormatter = [[RDateValueFormatter alloc] initWithFormat:[RChartConfig xaxisDateFormatForAggregateByValue:defaultAggregateBy]];
        if (chartConfig) {
          chartDataStartDate = chartConfig.startDate;
          chartDataEndDate = chartConfig.endDate;
          aggregateBy = chartConfig.aggregateBy.integerValue;
          NSString *cacheKeySubPart;
          if (chartConfig.boundedEndDate) {
            cacheKeySubPart = [NSString stringWithFormat:@"_%@_%@",
                               [PEUtils millisecondsFromDate:chartDataStartDate],
                               [PEUtils millisecondsFromDate:chartDataEndDate]];
          } else {
            cacheKeySubPart = [NSString stringWithFormat:@"_%@",
                               [PEUtils millisecondsFromDate:chartDataStartDate]];
          }
          NSString *entitiesCacheKey = [NSString stringWithFormat:@"%@_entities_%@", entityType, cacheKeySubPart];
          NSString *rawDataCacheKey = [NSString stringWithFormat:@"raw_data_%@_fetch_mode_%ld", cacheKeySubPart, (long)fetchMode];
          xaxisFormatter = [[RDateValueFormatter alloc] initWithFormat:[RChartConfig xaxisDateFormatForAggregateByValue:aggregateBy]];
          NSArray *filteredEntities = entitiesAndRawDataCache[entitiesCacheKey];
          if (!filteredEntities) {
            filteredEntities = filteredDataBlk(user, chartDataStartDate, chartDataEndDate, chartConfig.boundedEndDate);
            entitiesAndRawDataCache[entitiesCacheKey] = filteredEntities;
            DDLogInfo(@"Cache MISS for filtered entities for chart id: [%@]", chartId);
          } else {
            DDLogInfo(@"Cache HIT for filtered entities for chart id: [%@]", chartId);
          }
          if (filteredEntities.count > 0) {
            id filteredChartRawData = entitiesAndRawDataCache[rawDataCacheKey];
            if (!filteredChartRawData) {
              filteredChartRawData = chartRawDataBlk(user,
                                                     userSettings,
                                                     bodySegments,
                                                     bodySegmentsDict,
                                                     muscleGroups,
                                                     muscleGroupsDict,
                                                     muscles,
                                                     musclesDict,
                                                     movements,
                                                     movementsDict,
                                                     movementVariants,
                                                     movementVariantsDict,
                                                     filteredEntities,
                                                     chartDataStartDate,
                                                     chartDataEndDate);
              entitiesAndRawDataCache[rawDataCacheKey] = filteredChartRawData;
              DDLogInfo(@"Cache MISS for raw data for chart id: [%@]", chartId);
            } else {
              DDLogInfo(@"Cache HIT for raw data for chart id: [%@]", chartId);
            }
            normalizedTimeSeriesCollection = makeNormalizedTimeSeriesCollection(filteredChartRawData, aggregateBy);
          }
        } else {
          if (defaultChartDataStartDate) {
            normalizedTimeSeriesCollection = makeNormalizedTimeSeriesCollection(defaultChartRawData, aggregateBy);
          }
        }
        BOOL hasDataEntries = NO;
        NSDecimalNumber *max = nil;
        if (normalizedTimeSeriesCollection) {
          hasDataEntries = YES;
          max = maxValueBlk(normalizedTimeSeriesCollection);
        }
        if (hasDataEntries && ([[NSDecimalNumber zero] compare:max] == NSOrderedAscending)) {
          NSDictionary *normalizedTimeSeriesTuplesDict = normalizedTimeSeriesCollection.normalizedTimeSeriesTuplesDict;
          NSArray *normalizedTimeSeriesTuples = normalizedTimeSeriesTuplesDict.allValues;
          if (sortTriples) {
            normalizedTimeSeriesTuples = sortTriples(normalizedTimeSeriesTuples);
          }
          NSInteger numTimeSeriesTuples = normalizedTimeSeriesTuples.count;
          NSMutableArray *dataSets = [NSMutableArray arrayWithCapacity:numTimeSeriesTuples];
          NSInteger xaxisLabelCount = 0;
          for (NSInteger i = 0; i < numTimeSeriesTuples; i++) {
            RNormalizedTimeSeriesTuple *normalizedTimeSeriesTuple = normalizedTimeSeriesTuples[i];
            NSArray *normalizedTimeSeries = normalizedTimeSeriesTuple.normalizedTimeSeries;
            NSString *label = normalizedTimeSeriesTuple.name;
            NSNumber *entityLocalMasterIdentifier = normalizedTimeSeriesTuple.localMasterIdentifier;
            UIColor *lineColor = nil;
            if (!headless) {
              lineColor = entityColors[entityLocalMasterIdentifier];
            }
            NSInteger normalizedTimeSeriesCount = normalizedTimeSeries.count;
            if (normalizedTimeSeriesCount > xaxisLabelCount) {
              xaxisLabelCount = normalizedTimeSeriesCount;
            }
            NSMutableArray *lineChartDataEntries = [NSMutableArray arrayWithCapacity:normalizedTimeSeriesCount];
            for (NSInteger i = 0; i < normalizedTimeSeriesCount; i++) {
              RNormalizedLineChartDataEntry *normalizedLineChartDataEntry = normalizedTimeSeries[i];
              NSDate *date = normalizedLineChartDataEntry.date;
              NSDecimalNumber *value = yvalueBlk(normalizedLineChartDataEntry);
              BOOL skip = NO;
              if (ignoreZeros) {
                if ([value compare:[NSDecimalNumber zero]] == NSOrderedSame) {
                  skip = YES;
                }
              }
              if (!skip) {
                ChartDataEntry *chartDataEntry = [[ChartDataEntry alloc] initWithX:[date timeIntervalSince1970]
                                                                                 y:value.doubleValue];
                if (logging) {
                  NSLog(@"data entry, date: [%@], value: [%@]", date, value);
                }
                [lineChartDataEntries addObject:chartDataEntry];
              }
            }
            LineChartDataSet *dataSet = [[LineChartDataSet alloc] initWithEntries:lineChartDataEntries label:label];
            dataSet.entityLocalMasterIdentifier = entityLocalMasterIdentifier;
            if (!headless) {
              [self configureDataSet:dataSet lineColor:lineColor lineWidth:lineWidth];
            }
            [dataSets addObject:dataSet];
          }
          if (xaxisLabelCount > 6) {
            xaxisLabelCount = 6;
          }
          LineChartData *lineChartData = [[LineChartData alloc] initWithDataSets:dataSets];
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [coordDao saveLineChartDataCacheWithChartData:lineChartData
                                                  chartId:chartId
                                            chartConfigId:chartConfigLocalMasterIdentifier
                                                 category:chartConfigCategory
                                              aggregateBy:aggregateBy
                                          xaxisLabelCount:xaxisLabelCount
                                                 maxValue:max
                                                     user:user
                                                    error:errorBlk];
          });
          if (headless) {
            return nil;
          } else {
            double yaxisMaximum = yaxisMaximumBlk(max.doubleValue);
            id<IChartAxisValueFormatter> yaxisFormatter = yaxisFormatterBlk(max.doubleValue);
            NSString *yaxisLabelText = nil;
            if (yaxisValueLabelBlk) {
              yaxisLabelText = yaxisValueLabelBlk(userSettings, max.doubleValue);
            }
            return @[lineChartData,
                     @(xaxisLabelCount),
                     xaxisFormatter,
                     yaxisFormatter,
                     @(yaxisMaximum),
                     yaxisLabelText ? yaxisLabelText : [NSNull null],
                     settingsButtonIconImageName,
                     @(chartConfig != nil)];
          }
        }
        if (headless) {
          return nil;
        } else {
          return @[[NSNull null],
                   [NSNull null],
                   [NSNull null],
                   [NSNull null],
                   [NSNull null],
                   [NSNull null],
                   settingsButtonIconImageName,
                   @(chartConfig != nil)];
        }
      }
    };
    chartAndLoaderTuple.lineChartDataLoader = lineChartDataLoader;
    if (!headless) {
      NSArray *chartPanelAndSettingsButton =
      [RAbstractChartController makeChartPanelWithTitle:title
                                             entityType:entityType
                                            isLineChart:YES
                                                chartId:chartId
                                               subTitle:subTitle
                                             chartMaker:^UIView * (UIView *cardChartPanel) {
                                               LineChartView *chart = [RAbstractChartController templateLineChartViewWithWidth:0.925 * cardChartPanel.frame.size.width
                                                                                                                        height:chartHeight
                                                                                                                xaxisFormatter:nil
                                                                                                               xaxisLabelCount:0
                                                                                                                yaxisFormatter:nil
                                                                                                                  yaxisMaximum:0.0
                                                                                                                  yaxisMinimum:yaxisMinimum
                                                                                                                      delegate:chartViewDelegate];
                                               chartAndLoaderTuple.lineChartView = chart;
                                               if (yaxisValueLabelBlk) {
                                                 UILabel *yaxisLabel = [PEUIUtils labelWithKey:@"IN HUNDREDS OF THOUSANDS OF LBS"
                                                                                          font:[UIFont boldSystemFontOfSize:[PEUIUtils valueIfiPhone5Width:8.0
                                                                                                                                              iphone6Width:10.0
                                                                                                                                          iphone6PlusWidth:12.0
                                                                                                                                                      ipad:14.0]]
                                                                               backgroundColor:[UIColor clearColor]
                                                                                     textColor:[UIColor clearColor]
                                                                           verticalTextPadding:0.0];
                                                 yaxisLabel.textAlignment = NSTextAlignmentCenter;
                                                 yaxisLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
                                                 UIView *chartPanel = [PEUIUtils panelWithWidthOf:0.960 relativeToView:cardChartPanel fixedHeight:chartHeight];
                                                 [PEUIUtils placeView:yaxisLabel inMiddleOf:chartPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:0.0];
                                                 [PEUIUtils placeView:chart inMiddleOf:chartPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
                                                 chartAndLoaderTuple.yaxisLabelView = yaxisLabel;
                                                 return chartPanel;
                                               } else {
                                                 return chart;
                                               }
                                             }
                                        helpDescription:helpDescription
                                           chartConfigs:chartConfigs
                                         relativeToView:relativeToView
                                   veryFirstLoggedAtBlk:veryFirstLoggedAtBlk
                                    vertLastLoggedAtBlk:veryLastLoggedAtBlk
                                    chartConfigCategory:chartConfigCategory
                                             controller:controller
                                              uitoolkit:uitoolkit
                                          screenToolkit:screenToolkit
                                           panelToolkit:panelToolkit
                                                logging:logging];
      chartAndLoaderTuple.chartPanelView = chartPanelAndSettingsButton[0];
      chartAndLoaderTuple.settingsButton = chartPanelAndSettingsButton[1];
      chartAndLoaderTuple.chartCardPanel = chartPanelAndSettingsButton[2];
      chartAndLoaderTuple.chartTitleLabel = chartPanelAndSettingsButton[3];
      chartAndLoaderTuple.chartTitleVPadding = ((NSNumber *)chartPanelAndSettingsButton[4]).floatValue;
      if (chartPanelAndSettingsButton.count >= 6) {
        chartAndLoaderTuple.chartSubTitleLabel = chartPanelAndSettingsButton[5];
      }
      chartAndLoaderTuple.jumpId = jumpId;
    }
    return chartAndLoaderTuple;
  };
}

#pragma mark - Info Icon Makers

+ (UIButton *)makeInfoIconWithAlertTitle:(NSString *)title
                        alertDescription:(NSAttributedString *)infoDescText
                           fontTextStyle:(UIFontTextStyle)fontTextStyle
                            infoIconSize:(CGFloat)infoIconSize
                         backgroundColor:(UIColor *)backgroundColor
                               textColor:(UIColor *)textColor
                              controller:(UIViewController *)controller {
  UIButton *infoBtn = [PEUIUtils buttonWithKey:@"i"
                                          font:[PEUIUtils infoIconFont]
                               backgroundColor:backgroundColor
                                     textColor:textColor
                  disabledStateBackgroundColor:nil
                        disabledStateTextColor:nil
                               verticalPadding:0.0
                             horizontalPadding:0.0
                                  cornerRadius:infoIconSize * 0.5
                                        target:nil
                                        action:nil];
  [infoBtn bk_addEventHandler:^(id sender) {
    [PEUIUtils showInfoAlertWithTitle:title
                     alertDescription:infoDescText
                  descLblHeightAdjust:0.0
            additionalContentSections:nil
                             topInset:[PEUIUtils topInsetForAlertsWithController:controller]
                          buttonTitle:@"Okay."
                         buttonAction:^{}
                       relativeToView:[PEUIUtils parentViewForAlertsForController:controller]];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidth:infoIconSize ofView:infoBtn];
  [PEUIUtils setFrameHeight:infoIconSize ofView:infoBtn];
  return infoBtn;
}

+ (UIButton *)makeMetricInfoIconWithAlertTitle:(NSString *)title
                              alertDescription:(NSAttributedString *)infoDescText
                                    controller:(UIViewController *)controller {
  return [RAbstractChartController makeInfoIconWithAlertTitle:title
                                             alertDescription:infoDescText
                                                fontTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                        iphone6Width:UIFontTextStyleBody
                                                                                    iphone6PlusWidth:UIFontTextStyleBody
                                                                                                ipad:UIFontTextStyleTitle3]
                                                 infoIconSize:[RAbstractChartController circleHelpIconSize]
                                              backgroundColor:[UIColor cloudsColor]
                                                    textColor:[UIColor rikerAppBlack]
                                                   controller:controller];
}

+ (UIButton *)makeChartTypeInfoIconWithAlertTitle:(NSString *)title
                                 alertDescription:(NSAttributedString *)infoDescText
                                       controller:(UIViewController *)controller {
  return [RAbstractChartController makeInfoIconWithAlertTitle:title
                                             alertDescription:infoDescText
                                                fontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                                 infoIconSize:[RAbstractChartController circleHelpIconSize]
                                              backgroundColor:[UIColor cloudsColor]
                                                    textColor:[UIColor rikerAppBlack]
                                                   controller:controller];
}

#pragma mark - Circle Help Icon Size

+ (CGFloat)chartCircleHelpIconSize {
  return [PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:30.0 ipad:34.0];
}

+ (CGFloat)circleHelpIconSize {
  return [PEUIUtils valueIfiPhone5Width:26.0 iphone6Width:28.0 iphone6PlusWidth:30.0 ipad:34.0];
}

#pragma mark - Heading Panel Title Left Horizontal Padding

+ (CGFloat)headingPanelTitleHpadding {
  return [PEUIUtils valueIfiPhone5Width:8.0
                           iphone6Width:12.0
                       iphone6PlusWidth:15.0
                                   ipad:23.0] + [PEUIUtils iphoneXSafeInsetsSide];
}

#pragma mark - Metric Type Heading Panel Maker

+ (UIView *)makeMetricTypeHeadingPanelWithTitle:(NSString *)title
                                 infoAlertTitle:(NSString *)infoAlertTitle
                           infoAlertDescription:(NSAttributedString *)infoAlertDescription
                                 settingsAction:(void(^)(void))settingsAction
                                 relativeToView:(UIView *)relativeToView
                                     controller:(UIViewController *)controller
                       chartReloadButtonHandler:(void(^)(void))chartReloadButtonHandler {
  UIButton *infoButton = nil;
  if (infoAlertDescription) {
    infoButton = [RAbstractChartController makeMetricInfoIconWithAlertTitle:infoAlertTitle
                                                           alertDescription:infoAlertDescription
                                                                 controller:controller];
  }
  UIImage *settingsImage = [UIImage imageNamed:@"settings-white-30"];
  UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [settingsButton setFrame:[[UIImageView alloc] initWithImage:settingsImage].frame];
  [settingsButton setBackgroundImage:settingsImage forState:UIControlStateNormal];
  [settingsButton bk_addEventHandler:^(id sender) { settingsAction(); }
                    forControlEvents:UIControlEventTouchUpInside];
  UIImage *chartReloadImage = [UIImage imageNamed:@"chart-reload-white-30"];
  UIButton *chartReloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [chartReloadButton setFrame:[[UIImageView alloc] initWithImage:chartReloadImage].frame];
  [chartReloadButton setBackgroundImage:chartReloadImage forState:UIControlStateNormal];
  [chartReloadButton bk_addEventHandler:^(id sender) { chartReloadButtonHandler(); }
                       forControlEvents:UIControlEventTouchUpInside];
  UIFont *titleFont = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:43.0 iphone6Width:43.0 iphone6PlusWidth:43.0 ipad:46.0]
                                                            font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                                                           iphone6Width:UIFontTextStyleTitle3
                                                                                                                       iphone6PlusWidth:UIFontTextStyleTitle2
                                                                                                                                   ipad:UIFontTextStyleTitle2]]];
  UILabel *headerLabel =
  [PEUIUtils labelWithKey:title
                     font:titleFont
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor cloudsColor]
      verticalTextPadding:[PEUIUtils valueIfiPhone5Width:12.0 iphone6Width:13.0 iphone6PlusWidth:18.0 ipad:22.0]];
  NSMutableArray *viewsArray = [NSMutableArray array];
  [viewsArray addObject:headerLabel];
  if (infoButton) {
    [viewsArray addObject:infoButton];
  }
  [viewsArray addObject:settingsButton];
  [viewsArray addObject:chartReloadButton];
  UIView *headerPanelItems = [PEUIUtils panelOfBrickLayedViewsFromItems:viewsArray
                                                              viewMaker:^UIView *(NSInteger i, id __) { return viewsArray[i]; }
                                                              extraView:nil
                                                         availableWidth:relativeToView.frame.size.width
                                                               hpadding:[PEUIUtils valueIfiPhone5Width:18.0 iphone6Width:18.0 iphone6PlusWidth:20.0 ipad:24.0]
                                                               vpadding:16.0];
  UIView *headerPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:headerPanelItems.frame.size.height + 10.0];
  [PEUIUtils placeView:headerPanelItems inMiddleOf:headerPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  [headerPanel setBackgroundColor:[UIColor rikerAppBlackResultantNavbarColor]];
  [PEUIUtils styleViewForIpad:headerPanel];
  return headerPanel;
}

#pragma mark - Chart Type Heading Panel Maker

+ (UIView *)makeChartTypeHeadingPanelWithTitle:(NSString *)title
                                infoAlertTitle:(NSString *)infoAlertTitle
                          infoAlertDescription:(NSAttributedString *)infoAlertDescription
                               backgroundColor:(UIColor *)backgroundColor
                              moreChartsAction:(void(^)(RAbstractChartController *))moreChartsAction
                                relativeToView:(UIView *)relativeToView
                                    controller:(RAbstractChartController *)controller {
  UIButton *infoButton = [RAbstractChartController makeChartTypeInfoIconWithAlertTitle:infoAlertTitle
                                                                      alertDescription:infoAlertDescription
                                                                            controller:controller];
  UIButton *moreChartsButton = nil;
  if (moreChartsAction) {
    NSString *moreChartsBtnTitle = @"more charts";
    UIFont *moreChartsBtnFont = [UIFont preferredFontForTextStyle:[PEUIUtils captionFontTextStyle]];
    moreChartsButton = [PEUIUtils buttonWithKey:moreChartsBtnTitle
                                           font:moreChartsBtnFont
                                backgroundColor:[UIColor clearColor] //[UIColor rikerAppBlackResultantNavbarColor]
                                      textColor:[UIColor whiteColor]
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:14.0
                              horizontalPadding:18.0
                                   cornerRadius:4.0
                                         target:nil
                                         action:nil];
    [PEUIUtils applyBorderToView:moreChartsButton withColor:[UIColor whiteColor] width:1.5];
    [moreChartsButton bk_addEventHandler:^(id sender) {
      moreChartsAction(controller);
    } forControlEvents:UIControlEventTouchUpInside];
  }
  UIFont *headerFont = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:34.0]
                                                             font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  UILabel *headerLabel =
  [PEUIUtils labelWithKey:title
                     font:headerFont
          backgroundColor:[UIColor clearColor]
                textColor:[UIColor whiteColor]
      verticalTextPadding:[PEUIUtils valueIfiPhone5Width:12.0 iphone6Width:13.0 iphone6PlusWidth:18.0 ipad:22.0]];
  NSMutableArray *viewsArray = [NSMutableArray array];
  [viewsArray addObject:headerLabel];
  [viewsArray addObject:infoButton];
  if (moreChartsButton) {
    [viewsArray addObject:moreChartsButton];
  }
  UIView *headerPanelItems = [PEUIUtils panelOfBrickLayedViewsFromItems:viewsArray
                                                              viewMaker:^UIView *(NSInteger i, id __) { return viewsArray[i]; }
                                                              extraView:nil
                                                         availableWidth:relativeToView.frame.size.width
                                                               hpadding:[PEUIUtils valueIfiPhone5Width:14.0 iphone6Width:14.0 iphone6PlusWidth:16.0 ipad:20.0]
                                                               vpadding:8.0];
  UIView *headerPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:headerPanelItems.frame.size.height + 10.0];
  [headerPanel setBackgroundColor:backgroundColor];
  [PEUIUtils styleViewForIpad:headerPanel];
  [PEUIUtils placeView:headerPanelItems inMiddleOf:headerPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  [PEUIUtils styleViewForIpad:headerPanel];
  return headerPanel;
}

#pragma mark - Chart Settings Notification Handling

- (void)chartSettingsClearedNotification:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  NSString *chartId = userInfo[@"chartId"];
  [self chartSettingsDidChangeForChartId:chartId];
}

- (void)chartSettingsDoneNotification:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  RChartConfigCategory chartConfigCategory = ((NSNumber *)userInfo[@"chartCategory"]).integerValue;
  if (chartConfigCategory == [self chartConfigCategory]) {
    NSString *chartId = userInfo[@"chartId"];
    [self chartSettingsDidChangeForChartId:chartId];
  }
}

- (void)chartSettingsDidChangeForChartId:(NSString *)chartId {
  // overriden in subclasses
}

#pragma mark - Chart Config Helpers

- (RChartConfigCategory)chartConfigCategory {
  return RChartConfigCategoryWeight;
}

- (RChartConfig *)globalConfig {
  return [self.coordDao chartConfigWithChartId:[RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user] user:self.user error:[RUtils localFetchErrorHandlerMaker]()];
}

- (void)setGlobalConfig:(RChartConfig *)chartConfig {
  chartConfig.chartId = [RUtils globalChartIdWithCategory:[self chartConfigCategory] user:self.user];
  [_coordDao saveNewOrExistingByChartIdChartConfig:chartConfig forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
  [self.entitiesAndRawDataCache removeAllObjects];
}

- (void)clearAllChartConfigs {
  _animateAllSettingsButtons = YES;
  PELMDaoErrorBlk errorBlk = [RUtils localSaveErrorHandlerMaker]();
  RChartConfigCategory chartConfigCategory = [self chartConfigCategory];
  [self.coordDao deleteChartConfigByChartId:[RUtils globalChartIdWithCategory:chartConfigCategory user:self.user] user:self.user error:errorBlk];
  [self.coordDao deleteChartConfigsByCategory:chartConfigCategory user:self.user error:errorBlk];
  [self.entitiesAndRawDataCache removeAllObjects];
}

- (NSString *)globalChartConfigSettingsTitlePart {
  return @"<OVERRIDE>";
}

- (NSString *)globalChartConfigSettingsEntityType {
  return @"<OVERRIDE>";
}

- (void)globalChartConfigSettingsCalcPercentages:(BOOL)calcPercentages
                                    calcAverages:(BOOL)calcAverages {
  RChartConfig *globalConfig = nil;
  NSString *mainHeadingText;
  NSString *entityType;
  RChartConfig *globalStrengthChartConfig = [self globalConfig];
  if (!globalStrengthChartConfig) {
    globalStrengthChartConfig = [RChartConfig chartConfig];
    globalStrengthChartConfig.category = [self chartConfigCategory];
  }
  globalConfig = globalStrengthChartConfig;
  NSString *titlePart = [self globalChartConfigSettingsTitlePart];
  mainHeadingText = [NSString stringWithFormat:@"%@ Charts Config", titlePart];
  entityType = [self globalChartConfigSettingsEntityType];
  if ([self veryFirstLoggedAt] && [self veryLastLoggedAt]) {
    if (!globalConfig.startDate) {
      globalConfig.startDate = [PEUtils dateWithoutTimeFromDate:[self veryFirstLoggedAt]];
    }
    if (!globalConfig.endDate) {
      globalConfig.endDate = [[PEUtils dateWithoutTimeFromDate:[self veryLastLoggedAt]] dateByAddingDays:1];
    }
    if (!globalConfig.aggregateBy) {
      globalConfig.aggregateBy = @([RAbstractChartController suggestedAggregateByWithFirstDate:[self veryFirstLoggedAt] lastDate:[self veryLastLoggedAt]]);
    }
    RChartFilterScreen *chartConfigScreen =
    [[RChartFilterScreen alloc] initWithTitle:@"Chart Config"
                              mainHeadingText:mainHeadingText
                                   entityType:entityType
                       enableLineChartOptions:YES
                        enablePieChartOptions:YES
                                veryFirstDate:[self veryFirstLoggedAt]
                                 veryLastDate:[self veryLastLoggedAt]
                                  chartConfig:globalConfig
                             clearButtonTitle:[NSString stringWithFormat:@"Clear All %@%@Chart Config", titlePart, [PEUIUtils objIfiPhone5Width:@"\n" iphone6Width:@"\n" iphone6PlusWidth:@"\n" ipad:@" "]]
                                     clearBlk:^{
                                       [self clearAllChartConfigs];
                                       [self loadChartsWithCompletion:nil showAlertIfAlreadyLoading:NO headless:NO calcPercentages:calcPercentages calcAverages:calcAverages];
                                     }
                                      doneBlk:^(RChartConfig *chartConfig) {
                                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                        hud.tag = RHUD_TAG;
                                        hud.label.text = @"Saving chart config...";
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                          [self setGlobalConfig:chartConfig];
                                          [self populateAllConfigsFromGlobalConfig:chartConfig];
                                          _animateAllSettingsButtons = YES;
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                            [hud hideAnimated:YES];
                                            [self loadChartsWithCompletion:nil showAlertIfAlreadyLoading:NO headless:NO calcPercentages:calcPercentages calcAverages:calcAverages];
                                          });
                                        });
                                      }
                                    uitoolkit:_uitoolkit
                                screenToolkit:_screenToolkit
                                 panelToolkit:_panelToolkit];
    [self presentViewController:[PEUIUtils navigationControllerWithController:chartConfigScreen
                                                          navigationBarHidden:NO]
                       animated:YES
                     completion:nil];
  } else {
    NSString *desc = [NSString stringWithFormat:@"There are currently no charts to configure settings for."];
    [PEUIUtils showWarningAlertWithMsgs:nil
                                  title:[NSString stringWithFormat:@"No Charts to Configure"]
                       alertDescription:[[NSAttributedString alloc] initWithString:desc]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{}
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
  }
}

- (void(^)(void(^)(NSString *, RChartConfig *), NSInteger, NSString *))populateChartConfigsBlkWithGlobalConfig:(RChartConfig *)globalConfig {
  return ^(void(^chartConfigs)(NSString *chartId, RChartConfig *chartConfig), NSInteger maxChartsPerPrefix, NSString *chartIdPrefix) {
    ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
    for (NSInteger i = 0; i < maxChartsPerPrefix; i++) {
      NSString *chartId = makeChartId(i);
      RChartConfig *configCopy = [globalConfig copy];
      configCopy.localMasterIdentifier = nil;
      configCopy.chartId = chartId;
      chartConfigs(chartId, configCopy);
    }
  };
}

- (void)populateAllConfigsFromGlobalConfig:(RChartConfig *)globalConfig {
  // override in sub-classes
}

#pragma mark - Load Charts and Helpers

- (void)animateSettingsButton:(UIButton *)settingsButton {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [PEUIUtils popAnimateView:settingsButton
                      scaleUp:1.40
                    scaleDown:0.50
              scaleUpDuration:0.75
            scaleDownDuration:0.35
        scaleIdentityDuration:0.35
                   completion:nil];
  });
}

- (UIView *)makeAndPlaceNoDataToChartYetPanelWithTag:(NSInteger)tag
                                           labelText:(NSString *)labelText
                                      chartCardPanel:(UIView *)chartCardPanel
                                     chartTitleLabel:(UIView *)chartTitleLabel
                             chartTitleLabelVPadding:(CGFloat)chartTitleLabelVPadding
                                  chartSubTitleLabel:(UIView *)chartSubTitleLabel {
  UIView *noChartDataPanel = [PEUIUtils panelWithWidthOf:0.85 andHeightOf:0.75 relativeToView:chartCardPanel];
  noChartDataPanel.layer.cornerRadius = 5.0;
  noChartDataPanel.backgroundColor = [UIColor noDataToChartBgColor];
  noChartDataPanel.tag = tag;
  NSString *noDataToChartImageName;
  CGFloat vpaddingBetweenImageAndLabel;
  if ([PEUIUtils isPortraitMode]) {
    noDataToChartImageName = @"no-data-to-chart-yet-graph";
    vpaddingBetweenImageAndLabel = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:18.0 iphone6PlusWidth:20.0 ipad:24.0];
  } else {
    vpaddingBetweenImageAndLabel = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:15.0 iphone6PlusWidth:18.0 ipad:22.0];
    noDataToChartImageName = [PEUIUtils objIfiPhone5Width:@"no-data-to-chart-yet-graph-smaller"
                                             iphone6Width:@"no-data-to-chart-yet-graph-smaller"
                                         iphone6PlusWidth:@"no-data-to-chart-yet-graph-smaller"
                                                     ipad:@"no-data-to-chart-yet-graph"];
  }
  UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:noDataToChartImageName]];
  UILabel *label = [PEUIUtils labelWithKey:labelText
                                      font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:30.0]
                                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor noDataToChartTextColor]
                       verticalTextPadding:0.0
                                fitToWidth:noChartDataPanel.frame.size.width - 30];
  UIView *imageAndLabelPanel = [PEUIUtils panelWithColumnOfViews:@[imageView, label]
                                     verticalPaddingBetweenViews:vpaddingBetweenImageAndLabel
                                                  viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  [PEUIUtils placeView:imageAndLabelPanel
            inMiddleOf:noChartDataPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  CGFloat xval = [PEUIUtils XForWidth:noChartDataPanel.frame.size.width withAlignment:PEUIHorizontalAlignmentTypeCenter relativeToView:chartCardPanel hpadding:0.0];
  [PEUIUtils setFrameX:xval - chartCardPanel.frame.origin.x ofView:noChartDataPanel];
  UIView *topView = chartTitleLabel;
  CGFloat vpadding = 30.0;
  if (chartSubTitleLabel) {
    topView = chartSubTitleLabel;
    vpadding = 15.0;
  }
  [PEUIUtils placeView:noChartDataPanel below:topView onto:chartCardPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  CGFloat heightDiff = (noChartDataPanel.frame.origin.y + noChartDataPanel.frame.size.height) - chartCardPanel.frame.size.height;
  if (heightDiff > -15) { // we want 15 margin between bottom edge of no-chart panel and outer card panel
    [PEUIUtils adjustHeightOfView:noChartDataPanel withValue:-1 * (heightDiff + 15.0)];
    [PEUIUtils adjustYOfView:imageAndLabelPanel withValue:-1 * (heightDiff + 15.0) / 2];
  }
  return noChartDataPanel;
}

- (void)handleLineChartResult:(NSArray *)result
          chartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                 userSettings:(RUserSettings *)userSettings
        animateSettingsButton:(BOOL)animateSettingsButton {
  LineChartData *lineChartData = [PEUtils isNotNil:result[0]] ? result[0] : nil;
  NSString *settingsButtonIconImageName = result[6];
  BOOL wasConfigSet = ((NSNumber *)result[7]).boolValue;
  LineChartView *lineChart = chartAndLoaderTuple.lineChartView;
  NSNumber *xaxisLabelCount = result[1];
  id<IChartAxisValueFormatter> xaxisFormatter = [PEUtils isNotNil:result[2]] ? result[2] : nil;
  id<IChartAxisValueFormatter> yaxisFormatter = [PEUtils isNotNil:result[3]] ? result[3] : nil;
  NSNumber *yaxisMaximum = result[4];
  id yaxisLabelText = result[5];
  ChartXAxis *xAxis = lineChart.xAxis;
  xAxis.labelCount = [PEUtils isNotNil:xaxisLabelCount] ? xaxisLabelCount.integerValue : 0;
  xAxis.valueFormatter = xaxisFormatter;
  ChartYAxis *leftAxis = lineChart.leftAxis;
  leftAxis.axisMaximum = [PEUtils isNotNil:yaxisMaximum] ? yaxisMaximum.floatValue : 0.0;
  leftAxis.valueFormatter = yaxisFormatter;
  if ([PEUtils isNotNil:yaxisLabelText]) {
    if (yaxisMaximum == nil || yaxisMaximum.floatValue <= 0.0) {
      chartAndLoaderTuple.yaxisLabelView.textColor = [UIColor clearColor];
    } else {
      chartAndLoaderTuple.yaxisLabelView.textColor = [UIColor rikerAppBlack];
    }
    chartAndLoaderTuple.yaxisLabelView.text = [yaxisLabelText uppercaseString];
  } else {
    chartAndLoaderTuple.yaxisLabelView.textColor = [UIColor clearColor];
  }
  [RAbstractChartController configureMarkerOnLineChart:lineChart
                                          isPercentage:chartAndLoaderTuple.isPercentage
                                                   uom:chartAndLoaderTuple.uomDisplayBlk(userSettings)];
  NSInteger noDataToChartPanelTag = 4792;
  if ([PEUtils isNil:lineChartData]) {
    [chartAndLoaderTuple.progressHud hideAnimated:YES];
    chartAndLoaderTuple.progressHud = nil;
    chartAndLoaderTuple.yaxisLabelView.textColor = [UIColor clearColor];
    NSString *noDataToChartLabelText;
    if (wasConfigSet) {
      noDataToChartLabelText = @"No data to chart for the configured date range.";
      [chartAndLoaderTuple.settingsButton setImage:[UIImage imageNamed:settingsButtonIconImageName] forState:UIControlStateNormal];
      [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:YES];
    } else {
      noDataToChartLabelText = @"No data to chart yet.";
      [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:NO];
      [chartAndLoaderTuple.settingsButton setImage:nil forState:UIControlStateNormal];
    }
    lineChart.noDataText = @"";
    chartAndLoaderTuple.noChartDataPanel =
    [self makeAndPlaceNoDataToChartYetPanelWithTag:noDataToChartPanelTag
                                         labelText:noDataToChartLabelText
                                    chartCardPanel:chartAndLoaderTuple.chartCardPanel
                                   chartTitleLabel:chartAndLoaderTuple.chartTitleLabel
                           chartTitleLabelVPadding:chartAndLoaderTuple.chartTitleVPadding
                                chartSubTitleLabel:chartAndLoaderTuple.chartSubTitleLabel];

  } else {
    chartAndLoaderTuple.noChartDataPanel = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RCHART_ANIMATION_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [chartAndLoaderTuple.progressHud hideAnimated:YES];
      chartAndLoaderTuple.progressHud = nil;
    });
    [chartAndLoaderTuple.settingsButton setImage:[UIImage imageNamed:settingsButtonIconImageName] forState:UIControlStateNormal];
    [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:YES];
    [[chartAndLoaderTuple.chartCardPanel viewWithTag:noDataToChartPanelTag] removeFromSuperview];
  }
  lineChart.data = lineChartData;
  [lineChart animateWithXAxisDuration:RCHART_ANIMATION_DURATION];
  [lineChart setNeedsLayout];
  if (animateSettingsButton) {
    [self animateSettingsButton:chartAndLoaderTuple.settingsButton];
  }
}

- (void)handlePieChartResult:(NSArray *)result
         chartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
       animateSettingsButton:(BOOL)animateSettingsButton {
  PieChartView *pieChartView = chartAndLoaderTuple.pieChartView;
  id resultData = result[0];
  NSString *settingsButtonIconImageName = result[2];
  BOOL wasConfigSet = ((NSNumber *)result[3]).boolValue;
  NSInteger noDataToChartPanelTag = 4793;
  if ([PEUtils isNotNil:resultData]) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RCHART_ANIMATION_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [chartAndLoaderTuple.progressHud hideAnimated:YES];
      chartAndLoaderTuple.progressHud = nil;
    });
    PieChartData *pieChartData = resultData;
    BOOL suppressPieSliceLabels = ((NSNumber *)result[1]).boolValue;
    [pieChartView setDrawEntryLabelsEnabled:!suppressPieSliceLabels];
    pieChartView.data = pieChartData;
    [pieChartView animateWithXAxisDuration:RCHART_ANIMATION_DURATION yAxisDuration:RCHART_ANIMATION_DURATION];
    [pieChartView setNeedsLayout];
    [chartAndLoaderTuple.settingsButton setImage:[UIImage imageNamed:settingsButtonIconImageName] forState:UIControlStateNormal];
    [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:YES];
    [[chartAndLoaderTuple.chartCardPanel viewWithTag:noDataToChartPanelTag] removeFromSuperview];
    chartAndLoaderTuple.noChartDataPanel = nil;
  } else {
    [chartAndLoaderTuple.progressHud hideAnimated:YES];
    chartAndLoaderTuple.progressHud = nil;
    NSString *noDataToChartLabelText;
    if (wasConfigSet) {
      noDataToChartLabelText = @"No data to chart for the configured date range.";
      [chartAndLoaderTuple.settingsButton setImage:[UIImage imageNamed:settingsButtonIconImageName] forState:UIControlStateNormal];
      [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:YES];
    } else {
      noDataToChartLabelText = @"No data to chart yet.";
      [chartAndLoaderTuple.settingsButton setUserInteractionEnabled:NO];
      [chartAndLoaderTuple.settingsButton setImage:nil forState:UIControlStateNormal];
    }
    pieChartView.noDataText = @"";
    chartAndLoaderTuple.noChartDataPanel =
    [self makeAndPlaceNoDataToChartYetPanelWithTag:noDataToChartPanelTag
                                         labelText:noDataToChartLabelText
                                    chartCardPanel:chartAndLoaderTuple.chartCardPanel
                                   chartTitleLabel:chartAndLoaderTuple.chartTitleLabel
                           chartTitleLabelVPadding:chartAndLoaderTuple.chartTitleVPadding
                                chartSubTitleLabel:chartAndLoaderTuple.chartSubTitleLabel];
    [pieChartView setData:nil];
    [pieChartView clearValues];
  }
  if (animateSettingsButton) {
    [self animateSettingsButton:chartAndLoaderTuple.settingsButton];
  }
}

- (void)settingsDidChangeForChartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                                      fetchMode:(RChartDataFetchMode)fetchMode {
  [self settingsDidChangeForStrengthChartAndLoaderTuple:chartAndLoaderTuple fetchMode:fetchMode];
}

- (void)settingsDidChangeForStrengthChartAndLoaderTuple:(RChartAndLoaderTuple *)chartAndLoaderTuple
                                              fetchMode:(RChartDataFetchMode)fetchMode {
  if (chartAndLoaderTuple.progressHud) {
    [chartAndLoaderTuple.progressHud hideAnimated:NO];
  }
  UIView *viewForHudDisplay = [RAbstractChartController viewForHudDisplayForTuple:chartAndLoaderTuple];
  chartAndLoaderTuple.progressHud = [MBProgressHUD showHUDAddedTo:viewForHudDisplay animated:YES];
  [viewForHudDisplay bringSubviewToFront:chartAndLoaderTuple.progressHud];
  [RAbstractChartController configureChartLoadingHud:chartAndLoaderTuple.progressHud];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
    RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:errorBlk];
    NSArray *bodySegments = [_coordDao bodySegmentsWithError:errorBlk];
    NSDictionary *bodySegmentsDict = [RUtils dictFromMasterEntitiesArray:bodySegments];
    NSArray *muscleGroups = [_coordDao muscleGroupsWithError:errorBlk];
    NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:muscleGroups];
    NSArray *muscles = [_coordDao musclesWithError:errorBlk];
    NSDictionary *musclesDict = [RUtils dictFromMasterEntitiesArray:muscles];
    NSArray *movements = [_coordDao movementsWithError:errorBlk];
    NSDictionary *movementsDict = [RUtils dictFromMasterEntitiesArray:movements];
    NSArray *movementVariants = [_coordDao movementVariantsWithError:errorBlk];
    NSDictionary *movementVariantsDict = [RUtils dictFromMasterEntitiesArray:movementVariants];
    NSArray *sets = [self.coordDao ascendingSetsForUser:user error:errorBlk];
    RSet *firstSet = [sets firstObject];
    RSet *lastSet = [sets lastObject];
    self.veryLastSetLoggedAt = lastSet.loggedAt;
    self.veryFirstSetLoggedAt = firstSet.loggedAt;
    NSDate *onOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:self.veryFirstSetLoggedAt];
    NSDate *onOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:[self veryLastLoggedAt]] dateByAddingDays:1];
    RChartStrengthRawData *chartData =
    [RUtils chartStrengthRawDataForUser:user
                           userSettings:userSettings
                           bodySegments:bodySegments
                       bodySegmentsDict:bodySegmentsDict
                           muscleGroups:muscleGroups
                       muscleGroupsDict:muscleGroupsDict
                                muscles:muscles
                            musclesDict:musclesDict
                              movements:movements
                          movementsDict:movementsDict
                       movementVariants:movementVariants
                   movementVariantsDict:movementVariantsDict
                                   sets:sets
                              fetchMode:fetchMode
                        calcPercentages:self.calcPercentages
                           calcAverages:self.calcAverages];
    if (chartAndLoaderTuple.lineChartDataLoader) {
      NSArray *result = chartAndLoaderTuple.lineChartDataLoader(chartData,
                                                                user,
                                                                userSettings,
                                                                bodySegments,
                                                                bodySegmentsDict,
                                                                muscleGroups,
                                                                muscleGroupsDict,
                                                                muscles,
                                                                musclesDict,
                                                                movements,
                                                                movementsDict,
                                                                movementVariants,
                                                                movementVariantsDict,
                                                                onOrAfterLoggedAt,
                                                                onOrBeforeLoggedAt);
      dispatch_async(dispatch_get_main_queue(), ^{
        [self handleLineChartResult:result
                chartAndLoaderTuple:chartAndLoaderTuple
                       userSettings:userSettings
              animateSettingsButton:YES];
      });
    } else if (chartAndLoaderTuple.pieChartDataLoader) {
      NSArray *result = chartAndLoaderTuple.pieChartDataLoader(chartData,
                                                               user,
                                                               userSettings,
                                                               bodySegments,
                                                               bodySegmentsDict,
                                                               muscleGroups,
                                                               muscleGroupsDict,
                                                               muscles,
                                                               musclesDict,
                                                               movements,
                                                               movementsDict,
                                                               movementVariants,
                                                               movementVariantsDict);
      dispatch_async(dispatch_get_main_queue(), ^{
        [self handlePieChartResult:result
               chartAndLoaderTuple:chartAndLoaderTuple
             animateSettingsButton:YES];
      });
    }
  });
}

- (void)maybeShow32bitIphoneLineChartMsg {
  if ([RUtils is32bitIphone]) {
    if (![APP iphone32bitLineChartMsgAckAt]) {
      [PEUIUtils showInfoAlertWithTitle:@"Line Charts"
                       alertDescription:AS(@"Line charts will start to render once you have at least 2 days worth of data.")
                    descLblHeightAdjust:0.0
              additionalContentSections:nil
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Got it."
                           buttonAction:^{
                             [APP setIphone32bitLineChartMsgAckAt:[NSDate date]];
                           }
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
    }
  }
}

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
                                                                                     logging:(BOOL)logging {
  CGFloat lineChartHeight = headless ? 0.0 : [RAbstractChartController lineChartHeight];
  LineChartAndLoaderTupleMaker makeLineChartPanel =
  [RAbstractChartController lineChartAndLoaderTupleMakerWithChartHeight:lineChartHeight
                                                        filteredDataBlk:^NSArray *(PELMUser *user, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt, BOOL boundedEndDate) {
                                                          if (boundedEndDate) {
                                                            return [coordDao ascendingBmlsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                               onOrBeforeLoggedAt:onOrBeforeLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          } else {
                                                            return [coordDao ascendingBmlsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          }
                                                        }
                                                        chartRawDataBlk:^ RChartBodyRawData * (PELMUser *user,
                                                                                               RUserSettings *userSettings,
                                                                                               NSArray *bodySegments, // not used
                                                                                               NSDictionary *bodySegmentsDict, // not used
                                                                                               NSArray *muscleGroups, // not used
                                                                                               NSDictionary *muscleGroupsDict, // not used
                                                                                               NSArray *muscles, // not used
                                                                                               NSDictionary *musclesDict, // not used
                                                                                               NSArray *movements, // not used
                                                                                               NSDictionary *movementsDict, // not used
                                                                                               NSArray *movementVariants, // not used
                                                                                               NSDictionary *movementVariantsDict, // not used
                                                                                               NSArray *filteredBmls,
                                                                                               NSDate *onOrAfterLoggedAt,
                                                                                               NSDate *onOrBeforeLoggedAt) {
                                                          return [RUtils chartBodyDataForUser:user
                                                                                 userSettings:userSettings
                                                                                         bmls:filteredBmls];
                                                        }
                                                     yaxisValueLabelBlk:yaxisValueLabelBlk
                                                            maxValueBlk:maxValueBlk
                                                              yvalueBlk:yvalueBlk
                                                      yaxisFormatterBlk:yaxisFormatterBlk
                                                        yaxisMaximumBlk:yaxisMaximumBlk
                                                           yaxisMinimum:nil
                                                            ignoreZeros:YES
                                                      noDataHeadingText:@"No data to chart yet."
                                                        noDataLabelText:@""
                                                             entityType:@"body log"
                                                           chartConfigs:bodyConfigs
                                                   veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                    veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                           isPercentage:isPercentage
                                                          uomDisplayBlk:uomDisplayBlk
                                                         relativeToView:relativeToView
                                                               coordDao:coordDao
                                                      chartViewDelegate:chartViewDelegate
                                                    chartConfigCategory:RChartConfigCategoryBody
                                                             controller:controller
                                                              uitoolkit:uitoolkit
                                                          screenToolkit:screenToolkit
                                                           panelToolkit:panelToolkit
                                                               headless:headless
                                                entitiesAndRawDataCache:entitiesAndRawDataCache
                                                              fetchMode:0];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  AsMaker as = nil;
  if (!headless) {
    as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  }
  NSMutableDictionary *lineChartMakers = [NSMutableDictionary dictionaryWithCapacity:1];
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  NSString *chartId = makeChartId(0);
  lineChartMakers[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeLineChartPanel(chartId,
                              chartTitle,
                              nil,
                              ^(RChartBodyRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                                return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                       firstDate:chartData.startDate
                                                                        lastDate:chartData.endDate
                                                                withRawContainer:timeSeriesDictBlk(chartData)
                                                               calculateAverages:YES
                                                          calculateDistributions:NO
                                                                         logging:logging && NO];
                              },
                              lineColor ? @{@(LMID_KEY_FOR_SINGLE_VALUE_CONTAINER) : lineColor} : nil,
                              controller.thickerLineWidth,
                              as ? as(@"This chart illustrates your %@, over time.", [chartTitle lowercaseString]) : nil,
                              tripleSorter,
                              RChartSectionJumpIdNone,
                              logging && NO);
  }];
  return lineChartMakers;
}

+ (NSDictionary *)makeHeadlessBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:(NSMutableDictionary *(^)(RChartBodyRawData *))timeSeriesDictBlk
                                                                                       chartIdPrefix:(NSString *)chartIdPrefix
                                                                                         maxValueBlk:(NSDecimalNumber *(^)(RNormalizedTimeSeriesTupleCollection *))maxValueBlk
                                                                                           yvalueBlk:(NSDecimalNumber *(^)(RNormalizedLineChartDataEntry *))yvalueBlk
                                                                                         bodyConfigs:(RChartConfig *(^)(NSString *))bodyConfigs
                                                                                            coordDao:(id<RCoordinatorDao>)coordDao
                                                                             entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache
                                                                                     calcPercentages:(BOOL)calcPercentages
                                                                                        calcAverages:(BOOL)calcAverages
                                                                                             logging:(BOOL)logging {
  return [RAbstractChartController makeBodyMeasurementTimelineSingleChartAndLoaderTuplesWithTimeSeriesDictBlk:timeSeriesDictBlk
                                                                                                   chartTitle:nil
                                                                                                chartIdPrefix:chartIdPrefix
                                                                                                    lineColor:nil
                                                                                           yaxisValueLabelBlk:nil
                                                                                                  maxValueBlk:maxValueBlk
                                                                                                    yvalueBlk:yvalueBlk
                                                                                            yaxisFormatterBlk:nil
                                                                                              yaxisMaximumBlk:nil
                                                                                               relativeToView:nil
                                                                                                  bodyConfigs:bodyConfigs
                                                                                                 isPercentage:0
                                                                                                uomDisplayBlk:nil
                                                                                                   controller:nil
                                                                                            chartViewDelegate:nil
                                                                                                    uitoolkit:nil
                                                                                                screenToolkit:nil
                                                                                                 panelToolkit:nil
                                                                                                     coordDao:coordDao
                                                                                                     headless:YES
                                                                                      entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                              calcPercentages:calcPercentages
                                                                                                 calcAverages:calcAverages
                                                                                                      logging:logging];
}

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
                                                               logging:(BOOL)logging {
  CGFloat pieChartHeight = [RAbstractChartController pieChartHeight];
  PieChartAndLoaderTupleMaker makeTuple =
  [RAbstractChartController pieChartAndLoaderTupleMakerWithChartHeight:pieChartHeight
                                                     noDataHeadingText:@"No data to chart."
                                                       noDataLabelText:@"No data"
                                                            entityType:@"set"
                                                          chartConfigs:strengthConfigs
                                                  veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                   veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                             fetchMode:fetchMode
                                                        relativeToView:relativeToView
                                                              coordDao:coordDao
                                                            controller:controller
                                                   chartConfigCategory:chartConfigCategory
                                                             uitoolkit:uitoolkit
                                                         screenToolkit:screenToolkit
                                                          panelToolkit:panelToolkit
                                                              headless:headless];
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  AsMaker asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  ChartSectionPanelMaker makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  NSMutableDictionary *pieCharts = [NSMutableDictionary dictionary];
  NSInteger sortOrder = 0;
  NSString *chartId = makeChartId(0);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Body Segments",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByBodySegment; },
                     controller.bodySegmentColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes between your upper and lower body.",
                        @"all movements"),
                     tripleSorter,
                     RChartSectionJumpIdNone,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(2);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Weight Lifted Distribution by Muscle Group",
                                 asb(@"The following pie charts detail %@ across the individual muscles of the main muscle groups.",
                                     @"how your total weight lifted distributes"), YES); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(1);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"All Muscle Groups",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByMuscleGroup; },
                     controller.muscleGroupColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across all your major muscle groups.",
                        @"all movements"),
                     tripleSorter,
                     RChartSectionJumpIdAll,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(3);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Upper Body Muscle Groups",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByUpperBodySegment; },
                     controller.muscleGroupColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across all your upper body muscle groups.",
                        @"upper body movements"),
                     tripleSorter,
                     RChartSectionJumpIdUpperBody,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(4);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Shoulders",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByShoulderMg; },
                     controller.muscleColors[@(SHOULDER_MG_ID)],
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across your individual shoulder muscles.",
                        @"movements that hit the shoulders"),
                     tripleSorter,
                     RChartSectionJumpIdShoulders,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(5);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Chest",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByChestMg; },
                     controller.muscleColors[@(CHEST_MG_ID)],
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across your individual chest muscles.",
                        @"movements that hit the chest"),
                     tripleSorter,
                     RChartSectionJumpIdChest,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(6);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Back",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByBackMg; },
                     controller.muscleColors[@(BACK_MG_ID)],
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across your individual back muscles.",
                        @"movements that hit the back"),
                     tripleSorter,
                     RChartSectionJumpIdBack,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(7);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Triceps",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByTricepsMg; },
                     controller.muscleColors[@(TRICEP_MG_ID)],
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across your individual tricep muscles.",
                        @"movements that hit the triceps"),
                     tripleSorter,
                     RChartSectionJumpIdTriceps,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(8);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Core",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByAbsMg; },
                     controller.muscleColors[@(CORE_MG_ID)],
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across your core muscles.",
                        @"movements that hit your core"),
                     tripleSorter,
                     RChartSectionJumpIdCore,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(9);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Lower Body Muscle Groups",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByLowerBodySegment; },
                     controller.lowerBodyMuscleGroupColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across all your lower body muscle groups.",
                        @"lower body movements"),
                     tripleSorter,
                     RChartSectionJumpIdLowerBody,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(10);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Weight Lifted Distribution by Movement Variant",
                                 asb(@"The following pie charts detail %@ across the different movement variants.",
                                     @"how your total weight lifted distributes"), NO); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(11);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"All Muscle Groups - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.weightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"all movements"),
                     tripleSorter,
                     RChartSectionJumpIdAll,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(12);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Upper Body - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.upperBodyWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit upper body muscles"),
                     tripleSorter,
                     RChartSectionJumpIdUpperBody,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(13);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Shoulders - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.shoulderWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the shoulders"),
                     tripleSorter,
                     RChartSectionJumpIdShoulders,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(14);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Chest - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.chestWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the chest"),
                     tripleSorter,
                     RChartSectionJumpIdChest,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(15);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Back - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.backWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the back"),
                     tripleSorter,
                     RChartSectionJumpIdBack,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(16);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Biceps - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.bicepsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the biceps"),
                     tripleSorter,
                     RChartSectionJumpIdBiceps,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(17);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Triceps - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.tricepsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the triceps"),
                     tripleSorter,
                     RChartSectionJumpIdTriceps,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(18);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Forearms - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.forearmsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the forearms"),
                     tripleSorter,
                     RChartSectionJumpIdForearms,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(19);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Core - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.absWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit your core"),
                     tripleSorter,
                     RChartSectionJumpIdCore,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(20);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Lower Body - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.lowerBodyWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit lower body muscles"),
                     tripleSorter,
                     RChartSectionJumpIdLowerBody,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(21);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Quads - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.quadsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the quadriceps"),
                     tripleSorter,
                     RChartSectionJumpIdQuads,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(22);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Hamstrings - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.hamstringsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the hamstrings"),
                     tripleSorter,
                     RChartSectionJumpIdHamstrings,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(23);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Calfs - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.calfsWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the calfs"),
                     tripleSorter,
                     RChartSectionJumpIdCalfs,
                     logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(24);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeTuple(chartId,
                     @"Weight Lifted Distribution",
                     @"Glutes - Movement Variants",
                     ^(RChartStrengthRawData *chartData) { return chartData.glutesWeightLiftedByMovementVariant; },
                     controller.movementVariantColors,
                     as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                        @"movements that hit the glutes"),
                     tripleSorter,
                     RChartSectionJumpIdGlutes,
                     logging && NO); }, @(sortOrder++)];
    chartId = makeChartId(25);
    pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
        return makeTuple(chartId,
                         @"Weight Lifted Distribution",
                         @"Hip Abductors - Movement Variants",
                         ^(RChartStrengthRawData *chartData) { return chartData.hipAbductorsWeightLiftedByMovementVariant; },
                         controller.movementVariantColors,
                         as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                            @"movements that hit the hip abductors"),
                         tripleSorter,
                         RChartSectionJumpIdHipAbductors,
                         logging && NO); }, @(sortOrder++)];
    chartId = makeChartId(26);
    pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
        return makeTuple(chartId,
                         @"Weight Lifted Distribution",
                         @"Hip Flexors - Movement Variants",
                         ^(RChartStrengthRawData *chartData) { return chartData.hipFlexorsWeightLiftedByMovementVariant; },
                         controller.movementVariantColors,
                         as(@"This chart illustrates how the sum total of all your weight lifted, for %@, distributes across the different movement variants.",
                            @"movements that hit the hip flexors"),
                         tripleSorter,
                         RChartSectionJumpIdHipFlexors,
                         logging && NO); }, @(sortOrder++)];
  return pieCharts;
}

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
                                                            logging:(BOOL)logging {
  CGFloat lineChartHeight = headless ? 0.0 : [RAbstractChartController lineChartHeight];
  LineChartAndLoaderTupleMaker tupleMaker =
  [RAbstractChartController lineChartAndLoaderTupleMakerWithChartHeight:lineChartHeight
                                                        filteredDataBlk:^NSArray *(PELMUser *user, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt, BOOL boundedEndDate) {
                                                          if (boundedEndDate) {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                               onOrBeforeLoggedAt:onOrBeforeLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          } else {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          }
                                                        }
                                                        chartRawDataBlk:^ RChartStrengthRawData * (PELMUser *user,
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
                                                                                                   NSArray *filteredSets,
                                                                                                   NSDate *onOrAfterLoggedAt,
                                                                                                   NSDate *onOrBeforeLoggedAt) {
                                                          return [RUtils chartStrengthRawDataForUser:user
                                                                                        userSettings:userSettings
                                                                                        bodySegments:bodySegments
                                                                                    bodySegmentsDict:bodySegmentsDict
                                                                                        muscleGroups:muscleGroups
                                                                                    muscleGroupsDict:muscleGroupsDict
                                                                                             muscles:muscles
                                                                                         musclesDict:musclesDict
                                                                                           movements:movements
                                                                                       movementsDict:movementsDict
                                                                                    movementVariants:movementVariants
                                                                                movementVariantsDict:movementVariantsDict
                                                                                                sets:filteredSets
                                                                                           fetchMode:fetchMode
                                                                                     calcPercentages:calculateDistributions
                                                                                        calcAverages:calculateAverages];
                                                        }
                                                     yaxisValueLabelBlk:yaxisValueLabelBlk
                                                            maxValueBlk:maxValueBlk
                                                              yvalueBlk:yvalueBlk
                                                      yaxisFormatterBlk:yaxisFormatterBlk
                                                        yaxisMaximumBlk:yaxisMaximumBlk
                                                           yaxisMinimum:[NSDecimalNumber zero]
                                                            ignoreZeros:YES //NO
                                                      noDataHeadingText:@"No data to chart."
                                                        noDataLabelText:@"No data"
                                                             entityType:@"set"
                                                           chartConfigs:strengthConfigs
                                                   veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                    veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                           isPercentage:isPercentage
                                                          uomDisplayBlk:^(RUserSettings *userSettings) { return [RUtils weightUnitNameForUomId:userSettings.weightUom]; }
                                                         relativeToView:relativeToView
                                                               coordDao:coordDao
                                                      chartViewDelegate:chartViewDelegate
                                                    chartConfigCategory:RChartConfigCategoryWeight
                                                             controller:controller
                                                              uitoolkit:uitoolkit
                                                          screenToolkit:screenToolkit
                                                           panelToolkit:panelToolkit
                                                               headless:headless
                                                entitiesAndRawDataCache:entitiesAndRawDataCache
                                                              fetchMode:fetchMode];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  AsMaker as = nil;
  AsMaker asb = nil;
  ChartSectionPanelMaker makeChartSectionPanel = nil;
  if (!headless) {
    as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
    makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  }
  RChartAndLoaderTuple *(^allWeightChartPanelMaker)(void) = nil;
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  NSString *chartId;
  NSInteger sortOrder = 0;
  if (!isPercentage) {
    // this chart only makes sense for non-percentage context
    chartId = makeChartId(0);
    allWeightChartPanelMaker = ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        nil,
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.singleValueContainerLineColor,
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates the %@, for %%@, over time.", weightLiftedQualifier],
                                @"all movements") : nil,
                        tripleSorter,
                        RChartSectionJumpIdNone,
                        logging && NO);
    };
  }
  NSMutableDictionary *lineCharts = [NSMutableDictionary dictionary];
  if (allWeightChartPanelMaker) {
    lineCharts[chartId] = @[chartId, allWeightChartPanelMaker, @(sortOrder++)];
  }
  chartId = makeChartId(1);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Body Segments",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.bodySegmentColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes between your upper and lower body, over time.",
                          weightLiftedQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdNone,
                      logging && NO);
  }, @(sortOrder++)];
  if (!headless) {
    chartId = makeChartId(3);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      NSString *title = [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix];
      return makeChartSectionPanel([NSString stringWithFormat:@"%@ by Muscle Group", title],
                                   asb(@"The following timeline charts detail %@ across the individual muscles of your muscle groups, over time.", sectionHighlightText),
                                   areDistributionTuples); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(2);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByMuscleGroupTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && YES];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your major muscle groups, over time.",
                          weightLiftedQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && YES);
  }, @(sortOrder++)];
  chartId = makeChartId(4);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByUpperBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your upper body muscle groups, over time.",
                          weightLiftedQualifier],
                         @"upper body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(5);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByShoulderMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(SHOULDER_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual shoulder muscles, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId= makeChartId(6);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByChestMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CHEST_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual chest muscles, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(7);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByBackMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(BACK_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual back muscles, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(8);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Biceps",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByBicepsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(BICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the biceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdBiceps,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(9);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByTricepsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(TRICEP_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual tricep muscles, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(10);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Forearms",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByForearmsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(FOREARMS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the forearms") : nil,
                        tripleSorter,
                        RChartSectionJumpIdForearms,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(11);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByAbsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CORE_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your core muscles, over time.",
                          weightLiftedQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(12);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByLowerBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.lowerBodyMuscleGroupColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your lower body muscle groups, over time.",
                          weightLiftedQualifier],
                         @"lower body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) { // single-muscle muscle groups, so is not relevant for this distribution chart
    chartId = makeChartId(13);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Quads",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByQuadsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(QUADRICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the quadriceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdQuads,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(14);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hamstrings",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByHamstringsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HAMSTRINGS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the hamstrings") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHamstrings,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(15);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Calfs",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByCalfsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(CALVES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the calfs") : nil,
                        tripleSorter,
                        RChartSectionJumpIdCalfs,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(16);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Glutes",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByGlutesMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(GLUTES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            weightLiftedQualifier],
                           @"movements that hit the glutes") : nil,
                        tripleSorter,
                        RChartSectionJumpIdGlutes,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(17);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Abductors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByHipAbductorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_ABDUCTORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 weightLiftedQualifier],
                                @"movements that hit the hip abductors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipAbductors,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(18);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Flexors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.weightByHipFlexorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_FLEXORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 weightLiftedQualifier],
                                @"movements that hit the hip flexors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipFlexors,
                        logging && NO);
    }, @(sortOrder++)];
  }
  if (!headless) {
    chartId = makeChartId(19);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return makeChartSectionPanel([NSString stringWithFormat:@"%@Weight Lifted%@ by Movement Variant", chartTitlePrefix, chartTitlePostfix],
                                   asb(@"The following timeline charts detail %@ across the different movement variants, over time.",
                                             sectionHighlightText), areDistributionTuples); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(20);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.weightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(21);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.upperBodyWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit upper body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(22);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.shoulderWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(23);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.chestWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(24);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.backWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(25);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Biceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.bicepsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the biceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBiceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(26);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.tricepsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(27);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Forearms - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.forearmsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the forearms") : nil,
                      tripleSorter,
                      RChartSectionJumpIdForearms,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(28);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.absWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(29);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.lowerBodyWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit lower body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(30);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Quads - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.quadsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the quadriceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdQuads,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(31);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hamstrings - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hamstringsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the hamstrings") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHamstrings,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(32);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Calfs - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.calfsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the calfs") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCalfs,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(33);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Glutes - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.glutesWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          weightLiftedQualifier],
                         @"movements that hit the glutes") : nil,
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(34);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Abductors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipAbductorsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                               weightLiftedQualifier],
                              @"movements that hit the hip abductors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHipAbductors,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(35);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Weight Lifted%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Flexors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipFlexorsWeightByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                               weightLiftedQualifier],
                              @"movements that hit the hip flexors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHipFlexors,
                      logging && NO);
  }, @(sortOrder++)];
  return lineCharts;
}

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
                                                                    logging:(BOOL)logging {
  return [RAbstractChartController makeWeightLiftedChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                   calculateAverages:calculateAverages
                                                              calculateDistributions:calculateDistributions
                                                                       chartIdPrefix:chartIdPrefix
                                                                  yaxisValueLabelBlk:nil
                                                                         maxValueBlk:maxValueBlk
                                                                           yvalueBlk:yvalueBlk
                                                                   yaxisFormatterBlk:nil
                                                                     yaxisMaximumBlk:nil
                                                                        isPercentage:0
                                                                    chartTitlePrefix:nil
                                                                   chartTitlePostfix:nil
                                                                sectionHighlightText:nil
                                                               weightLiftedQualifier:nil
                                                                      relativeToView:nil
                                                                     strengthConfigs:strengthConfigs
                                                                          controller:nil
                                                               areDistributionTuples:areDistributionTuples
                                                                            coordDao:coordDao
                                                                   chartViewDelegate:nil
                                                                           uitoolkit:nil
                                                                       screenToolkit:nil
                                                                        panelToolkit:nil
                                                                            headless:YES
                                                             entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                             logging:logging];
}

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
                                                       logging:(BOOL)logging {
  CGFloat pieChartHeight = [RAbstractChartController pieChartHeight];
  PieChartAndLoaderTupleMaker tupleMaker =
  [RAbstractChartController pieChartAndLoaderTupleMakerWithChartHeight:pieChartHeight
                                                     noDataHeadingText:@"No data to chart."
                                                       noDataLabelText:@"No data"
                                                            entityType:@"set"
                                                          chartConfigs:strengthConfigs
                                                  veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                   veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                             fetchMode:fetchMode
                                                        relativeToView:relativeToView
                                                              coordDao:coordDao
                                                            controller:controller
                                                   chartConfigCategory:RChartConfigCategoryReps
                                                             uitoolkit:uitoolkit
                                                         screenToolkit:screenToolkit
                                                          panelToolkit:panelToolkit
                                                              headless:headless];
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  AsMaker asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  ChartSectionPanelMaker makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  NSMutableDictionary *pieCharts = [NSMutableDictionary dictionary];
  NSInteger sortOrder = 0;
  NSString *chartId = makeChartId(0);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Body Segments",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByBodySegment; },
                      controller.bodySegmentColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes between your upper and lower body.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdNone,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(2);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Reps Distribution by Muscle Group",
                                 asb(@"The following pie charts detail %@ across the individual muscles of the main muscle groups.",
                                     @"how your total rep count distributes"), YES); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(1);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"All Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByMuscleGroup; },
                      controller.muscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across all your major muscle groups.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(3);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Upper Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByUpperBodySegment; },
                      controller.muscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across all your upper body muscle groups.",
                         @"upper body movements"),
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(4);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Shoulders",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByShoulderMg; },
                      controller.muscleColors[@(SHOULDER_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across your individual shoulder muscles.",
                         @"movements that hit the shoulders"),
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(5);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Chest",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByChestMg; },
                      controller.muscleColors[@(CHEST_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across your individual chest muscles.",
                         @"movements that hit the chest"),
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(6);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Back",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByBackMg; },
                      controller.muscleColors[@(BACK_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across your individual back muscles.",
                         @"movements that hit the back"),
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(7);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Triceps",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByTricepsMg; },
                      controller.muscleColors[@(TRICEP_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across your individual tricep muscles.",
                         @"movements that hit the triceps"),
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(8);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Core",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByAbsMg; },
                      controller.muscleColors[@(CORE_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across your core muscles.",
                         @"movements that hit your core"),
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(9);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Lower Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByLowerBodySegment; },
                      controller.lowerBodyMuscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across all your lower body muscle groups.",
                         @"lower body movements"),
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(10);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Reps Distribution by Movement Variant",
                                 asb(@"The following pie charts detail %@ across the different movement variants.",
                                     @"how your total rep count distributes"), NO); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(11);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"All Muscle Groups - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(12);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Upper Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalUpperBodyRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit upper body muscles"),
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(13);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Shoulders - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalShoulderRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the shoulders"),
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(14);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Chest - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalChestRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the chest"),
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(15);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Back - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalBackRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the back"),
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(16);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Biceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalBicepsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the biceps"),
                      tripleSorter,
                      RChartSectionJumpIdBiceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(17);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Triceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTricepsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the triceps"),
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(18);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Forearms - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalForearmsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the forearms"),
                      tripleSorter,
                      RChartSectionJumpIdForearms,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(19);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Core - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalAbsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit your core"),
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(20);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Lower Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalLowerBodyRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit lower body muscles"),
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(21);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Quads - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalQuadsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the quadriceps"),
                      tripleSorter,
                      RChartSectionJumpIdQuads,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(22);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Hamstrings - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHamstringsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the hamstrings"),
                      tripleSorter,
                      RChartSectionJumpIdHamstrings,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(23);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Calfs - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalCalfsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the calfs"),
                      tripleSorter,
                      RChartSectionJumpIdCalfs,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(24);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Glutes - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalGlutesRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the glutes"),
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(25);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Hip Abductors - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHipAbductorsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the hip abductors"),
                      tripleSorter,
                      RChartSectionJumpIdHipAbductors,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(26);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Reps Distribution",
                      @"Hip Flexors - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHipFlexorsRepsByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your reps, for %@, distributes across the different movement variants.",
                         @"movements that hit the hip flexors"),
                      tripleSorter,
                      RChartSectionJumpIdHipFlexors,
                      logging && NO); }, @(sortOrder++)];
  return pieCharts;
}

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
                                                            logging:(BOOL)logging {
  CGFloat lineChartHeight = headless ? 0.0 : [RAbstractChartController lineChartHeight];
  LineChartAndLoaderTupleMaker tupleMaker =
  [RAbstractChartController lineChartAndLoaderTupleMakerWithChartHeight:lineChartHeight
                                                        filteredDataBlk:^NSArray *(PELMUser *user, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt, BOOL boundedEndDate) {
                                                          if (boundedEndDate) {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                               onOrBeforeLoggedAt:onOrBeforeLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          } else {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          }
                                                        }
                                                        chartRawDataBlk:^ RChartStrengthRawData * (PELMUser *user,
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
                                                                                                   NSArray *filteredSets,
                                                                                                   NSDate *onOrAfterLoggedAt,
                                                                                                   NSDate *onOrBeforeLoggedAt) {
                                                          return [RUtils chartStrengthRawDataForUser:user
                                                                                        userSettings:userSettings
                                                                                        bodySegments:bodySegments
                                                                                    bodySegmentsDict:bodySegmentsDict
                                                                                        muscleGroups:muscleGroups
                                                                                    muscleGroupsDict:muscleGroupsDict
                                                                                             muscles:muscles
                                                                                         musclesDict:musclesDict
                                                                                           movements:movements
                                                                                       movementsDict:movementsDict
                                                                                    movementVariants:movementVariants
                                                                                movementVariantsDict:movementVariantsDict
                                                                                                sets:filteredSets
                                                                                           fetchMode:fetchMode
                                                                                     calcPercentages:calculateDistributions
                                                                                        calcAverages:calculateAverages];
                                                        }
                                                     yaxisValueLabelBlk:yaxisValueLabelBlk
                                                            maxValueBlk:maxValueBlk
                                                              yvalueBlk:yvalueBlk
                                                      yaxisFormatterBlk:yaxisFormatterBlk
                                                        yaxisMaximumBlk:yaxisMaximumBlk
                                                           yaxisMinimum:[NSDecimalNumber zero]
                                                            ignoreZeros:YES //NO
                                                      noDataHeadingText:@"No data to chart."
                                                        noDataLabelText:@"No data"
                                                             entityType:@"set"
                                                           chartConfigs:strengthConfigs
                                                   veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                    veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                           isPercentage:isPercentage
                                                          uomDisplayBlk:^(RUserSettings *userSettings) { return @"reps"; }
                                                         relativeToView:relativeToView
                                                               coordDao:coordDao
                                                      chartViewDelegate:chartViewDelegate
                                                    chartConfigCategory:RChartConfigCategoryReps
                                                             controller:controller
                                                              uitoolkit:uitoolkit
                                                          screenToolkit:screenToolkit
                                                           panelToolkit:panelToolkit
                                                               headless:headless
                                                entitiesAndRawDataCache:entitiesAndRawDataCache
                                                              fetchMode:fetchMode];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  AsMaker as = nil;
  AsMaker asb = nil;
  ChartSectionPanelMaker makeChartSectionPanel = nil;
  if (!headless) {
    as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
    makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  }
  RChartAndLoaderTuple *(^allRepsChartPanelMaker)(void) = nil;
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  NSInteger sortOrder = 0;
  NSString *chartId;
  if (!isPercentage) {
    // this chart only makes sense for non-percentage context
    chartId = makeChartId(0);
    allRepsChartPanelMaker = ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        nil,
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.singleValueContainerLineColor,
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates the %@, for %%@, over time.", repsQualifier],
                                @"all movements") : nil,
                        tripleSorter,
                        RChartSectionJumpIdNone,
                        logging && NO);
    };
  }
  NSMutableDictionary *lineCharts = [NSMutableDictionary dictionary];
  if (allRepsChartPanelMaker) {
    lineCharts[chartId] = @[chartId, allRepsChartPanelMaker, @(sortOrder++)];
  }
  chartId = makeChartId(1);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Body Segments",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.bodySegmentColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes between your upper and lower body, over time.",
                          repsQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdNone,
                      logging && NO);
  }, @(sortOrder++)];
  if (!headless) {
    chartId = makeChartId(3);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return makeChartSectionPanel([NSString stringWithFormat:@"%@Reps%@ by Muscle Group", chartTitlePrefix, chartTitlePostfix],
                                   asb(@"The following timeline charts detail %@ across the individual muscles of your muscle groups, over time.",
                                       sectionHighlightText), areDistributionTuples); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(2);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByMuscleGroupTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your major muscle groups, over time.",
                          repsQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(4);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByUpperBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your upper body muscle groups, over time.",
                          repsQualifier],
                         @"upper body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(5);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByShoulderMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(SHOULDER_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual shoulder muscles, over time.",
                          repsQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(6);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByChestMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CHEST_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual chest muscles, over time.",
                          repsQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(7);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByBackMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(BACK_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual back muscles, over time.",
                          repsQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(8);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Biceps",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByBicepsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(BICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the biceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdBiceps,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(9);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByTricepsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(TRICEP_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual tricep muscles, over time.",
                          repsQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(10);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Forearms",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByForearmsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(FOREARMS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the forearms") : nil,
                        tripleSorter,
                        RChartSectionJumpIdForearms,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(11);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByAbsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CORE_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your core muscles, over time.",
                          repsQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(12);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByLowerBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.lowerBodyMuscleGroupColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your lower body muscle groups, over time.",
                          repsQualifier],
                         @"lower body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(13);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Quads",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByQuadsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(QUADRICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the quadriceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdQuads,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(14);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hamstrings",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByHamstringsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HAMSTRINGS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the hamstrings") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHamstrings,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(15);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Calfs",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByCalfsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(CALVES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the calfs") : nil,
                        tripleSorter,
                        RChartSectionJumpIdCalfs,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(16);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Glutes",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByGlutesMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(GLUTES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            repsQualifier],
                           @"movements that hit the glutes") : nil,
                        tripleSorter,
                        RChartSectionJumpIdGlutes,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(17);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Abductors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByHipAbductorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_ABDUCTORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 repsQualifier],
                                @"movements that hit the hip abductors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipAbductors,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(18);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Flexors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.repsByHipFlexorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_FLEXORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 repsQualifier],
                                @"movements that hit the hip flexors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipFlexors,
                        logging && NO);
    }, @(sortOrder++)];
  }
  if (!headless) {
    chartId = makeChartId(17);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return makeChartSectionPanel([NSString stringWithFormat:@"%@Reps%@ by Movement Variant", chartTitlePrefix, chartTitlePostfix],
                                   asb(@"The following timeline charts detail %@ across the different movement variants, over time.",
                                       sectionHighlightText), areDistributionTuples); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(18);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.repsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(19);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.upperBodyRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit upper body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(20);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.shoulderRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(21);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.chestRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(22);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.backRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(23);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Biceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.bicepsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the biceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBiceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(24);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.tricepsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(25);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Forearms - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.forearmsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the forearms") : nil,
                      tripleSorter,
                      RChartSectionJumpIdForearms,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(26);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.absRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(27);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.lowerBodyRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit lower body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(28);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Quads - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.quadsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the quadriceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdQuads,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(29);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hamstrings - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hamstringsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the hamstrings") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHamstrings,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(30);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Calfs - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.calfsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the calfs") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCalfs,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(31);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Glutes - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.glutesRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                         @"movements that hit the glutes") : nil,
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(32);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Abductors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipAbductorsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                              @"movements that hit the hip abductors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHipAbductors,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(33);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Reps%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Flexors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipFlexorsRepsByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants.", repsQualifier],
                              @"movements that hit the hip flexors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHipFlexors,
                      logging && NO);
  }, @(sortOrder++)];
  return lineCharts;
}

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
                                                                    logging:(BOOL)logging {
  return [RAbstractChartController makeRepsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                   calculateAverages:calculateAverages
                                                              calculateDistributions:calculateDistributions
                                                                       chartIdPrefix:chartIdPrefix
                                                                  yaxisValueLabelBlk:nil
                                                                         maxValueBlk:maxValueBlk
                                                                           yvalueBlk:yvalueBlk
                                                                   yaxisFormatterBlk:nil
                                                                     yaxisMaximumBlk:nil
                                                                        isPercentage:0
                                                                    chartTitlePrefix:nil
                                                                   chartTitlePostfix:nil
                                                                sectionHighlightText:nil
                                                                       repsQualifier:nil
                                                                      relativeToView:nil
                                                                     strengthConfigs:strengthConfigs
                                                                          controller:nil
                                                               areDistributionTuples:areDistributionTuples
                                                                            coordDao:coordDao
                                                                   chartViewDelegate:nil
                                                                           uitoolkit:nil
                                                                       screenToolkit:nil
                                                                        panelToolkit:nil
                                                                            headless:YES
                                                             entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                             logging:logging];
}

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
                                                                         logging:(BOOL)logging {
  CGFloat pieChartHeight = [RAbstractChartController pieChartHeight];
  PieChartAndLoaderTupleMaker tupleMaker =
  [RAbstractChartController pieChartAndLoaderTupleMakerWithChartHeight:pieChartHeight
                                                     noDataHeadingText:@"No data to chart."
                                                       noDataLabelText:@"No data"
                                                            entityType:@"set"
                                                          chartConfigs:strengthConfigs
                                                  veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                   veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                             fetchMode:fetchMode
                                                        relativeToView:relativeToView
                                                              coordDao:coordDao
                                                            controller:controller
                                                   chartConfigCategory:RChartConfigCategoryRest
                                                             uitoolkit:uitoolkit
                                                         screenToolkit:screenToolkit
                                                          panelToolkit:panelToolkit
                                                              headless:headless];
  AsMaker as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  AsMaker asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  ChartSectionPanelMaker makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  NSMutableDictionary *pieCharts = [NSMutableDictionary dictionary];
  NSInteger sortOrder = 0;
  NSString *chartId = makeChartId(0);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Body Segments",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByBodySegment; },
                      controller.bodySegmentColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes between your upper and lower body.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdNone,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(2);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Rest Time Distribution by Muscle Group",
                                 asb(@"The following pie charts detail %@ across the individual muscles of the main muscle groups.",
                                     @"how your total rest time distributes"), YES); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(1);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"All Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByMuscleGroup; },
                      controller.muscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across all your major muscle groups.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(3);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Upper Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByUpperBodySegment; },
                      controller.muscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across all your upper body muscle groups.",
                         @"upper body movements"),
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(4);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Shoulders",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByShoulderMg; },
                      controller.muscleColors[@(SHOULDER_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across your individual shoulder muscles.",
                         @"movements that hit the shoulders"),
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(5);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Chest",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByChestMg; },
                      controller.muscleColors[@(CHEST_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across your individual chest muscles.",
                         @"movements that hit the chest"),
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(6);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Back",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByBackMg; },
                      controller.muscleColors[@(BACK_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across your individual back muscles.",
                         @"movements that hit the back"),
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(7);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Triceps",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByTricepsMg; },
                      controller.muscleColors[@(TRICEP_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across your individual tricep muscles.",
                         @"movements that hit the triceps"),
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(8);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Core",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByAbsMg; },
                      controller.muscleColors[@(CORE_MG_ID)],
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across your core muscles.",
                         @"movements that hit your core"),
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(9);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Lower Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByLowerBodySegment; },
                      controller.lowerBodyMuscleGroupColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across all your lower body muscle groups.",
                         @"lower body movements"),
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(10);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return makeChartSectionPanel(@"Rest Time Distribution by Movement Variant",
                                 asb(@"The following pie charts detail %@ across the different movement variants.",
                                     @"how your total rest time distributes"), NO); }, @(sortOrder++), @(YES)];
  chartId = makeChartId(11);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"All Muscle Groups - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"all movements"),
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(12);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Upper Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalUpperBodyTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit upper body muscles"),
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(13);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Shoulders - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalShoulderTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the shoulders"),
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(14);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Chest - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalChestTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the chest"),
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(15);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Back - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalBackTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the back"),
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(16);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Biceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalBicepsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the biceps"),
                      tripleSorter,
                      RChartSectionJumpIdBiceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(17);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Triceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalTricepsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the triceps"),
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(18);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Forearms - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalForearmsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the forearms"),
                      tripleSorter,
                      RChartSectionJumpIdForearms,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(19);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Core - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalAbsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit your core"),
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(20);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Lower Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalLowerBodyTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit lower body muscles"),
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(21);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Quads - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalQuadsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the quadriceps"),
                      tripleSorter,
                      RChartSectionJumpIdQuads,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(22);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Hamstrings - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHamstringsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the hamstrings"),
                      tripleSorter,
                      RChartSectionJumpIdHamstrings,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(23);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Calfs - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalCalfsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the calfs"),
                      tripleSorter,
                      RChartSectionJumpIdCalfs,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(24);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Glutes - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalGlutesTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the glutes"),
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(25);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Hip Abductors - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHipAbductorsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the hip abductors"),
                      tripleSorter,
                      RChartSectionJumpIdHipAbductors,
                      logging && NO); }, @(sortOrder++)];
  chartId = makeChartId(26);
  pieCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      @"Rest Time Distribution",
                      @"Hip Flexors - Movement Variants",
                      ^(RChartStrengthRawData *chartData) { return chartData.totalHipFlexorsTimeBetweenSetsSameMovByMovementVariant; },
                      controller.movementVariantColors,
                      as(@"This chart illustrates how the sum total of all your time spent between sets, for %@, distributes across the different movement variants.",
                         @"movements that hit the hip flexors"),
                      tripleSorter,
                      RChartSectionJumpIdHipFlexors,
                      logging && NO); }, @(sortOrder++)];
  return pieCharts;
}

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
                                                                       logging:(BOOL)logging {
  CGFloat lineChartHeight = headless ? 0.0 : [RAbstractChartController lineChartHeight];
  LineChartAndLoaderTupleMaker tupleMaker =
  [RAbstractChartController lineChartAndLoaderTupleMakerWithChartHeight:lineChartHeight
                                                        filteredDataBlk:^NSArray *(PELMUser *user, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt, BOOL boundedEndDate) {
                                                          if (boundedEndDate) {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                               onOrBeforeLoggedAt:onOrBeforeLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          } else {
                                                            return [coordDao ascendingSetsForUser:user
                                                                                onOrAfterLoggedAt:onOrAfterLoggedAt
                                                                                            error:[RUtils localFetchErrorHandlerMaker]()];
                                                          }
                                                        }
                                                        chartRawDataBlk:^ RChartStrengthRawData * (PELMUser *user,
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
                                                                                                   NSArray *filteredSets,
                                                                                                   NSDate *onOrAfterLoggedAt,
                                                                                                   NSDate *onOrBeforeLoggedAt) {
                                                          return [RUtils chartStrengthRawDataForUser:user
                                                                                        userSettings:userSettings
                                                                                        bodySegments:bodySegments
                                                                                    bodySegmentsDict:bodySegmentsDict
                                                                                        muscleGroups:muscleGroups
                                                                                    muscleGroupsDict:muscleGroupsDict
                                                                                             muscles:muscles
                                                                                         musclesDict:musclesDict
                                                                                           movements:movements
                                                                                       movementsDict:movementsDict
                                                                                    movementVariants:movementVariants
                                                                                movementVariantsDict:movementVariantsDict
                                                                                                sets:filteredSets
                                                                                           fetchMode:fetchMode
                                                                                     calcPercentages:calculateDistributions
                                                                                        calcAverages:calculateAverages];
                                                        }
                                                     yaxisValueLabelBlk:yaxisValueLabelBlk
                                                            maxValueBlk:maxValueBlk
                                                              yvalueBlk:yvalueBlk
                                                      yaxisFormatterBlk:yaxisFormatterBlk
                                                        yaxisMaximumBlk:yaxisMaximumBlk
                                                           yaxisMinimum:[NSDecimalNumber zero]
                                                            ignoreZeros:YES //NO
                                                      noDataHeadingText:@"No data to chart."
                                                        noDataLabelText:@"No data"
                                                             entityType:@"set"
                                                           chartConfigs:strengthConfigs
                                                   veryFirstLoggedAtBlk:^{ return [controller veryFirstLoggedAt]; }
                                                    veryLastLoggedAtBlk:^{ return [controller veryLastLoggedAt]; }
                                                           isPercentage:isPercentage
                                                          uomDisplayBlk:^(RUserSettings *userSettings) { return @"seconds"; }
                                                         relativeToView:relativeToView
                                                               coordDao:coordDao
                                                      chartViewDelegate:chartViewDelegate
                                                    chartConfigCategory:RChartConfigCategoryRest
                                                             controller:controller
                                                              uitoolkit:uitoolkit
                                                          screenToolkit:screenToolkit
                                                           panelToolkit:panelToolkit
                                                               headless:headless
                                                entitiesAndRawDataCache:entitiesAndRawDataCache
                                                              fetchMode:fetchMode];
  ChartIdMaker makeChartId = [RAbstractChartController makeChartIdMakerWithPrefix:chartIdPrefix];
  AsMaker as = nil;
  AsMaker asb = nil;
  ChartSectionPanelMaker makeChartSectionPanel = nil;
  if (!headless) {
    as = [RUtils asMakerWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]];
    asb = [RUtils asMakerWithFontTextStyle:[PEUIUtils bodyFontTextStyle]];
    makeChartSectionPanel = [RAbstractChartController chartSectionPanelMakerRelativeToView:relativeToView];
  }
  NSArray *(^tripleSorter)(NSArray *) = [RAbstractChartController makeTripleSorter];
  RChartAndLoaderTuple *(^allTimeChartPanelMaker)(void) = nil;
  NSString *chartId;
  NSInteger sortOrder = 0;
  if (!isPercentage) {
    // this chart only makes sense for non-percentage context
    chartId = makeChartId(0);
    allTimeChartPanelMaker = ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        nil,
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.singleValueContainerLineColor,
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates the %@, for %%@, over time.", timeQualifier],
                                @"all movements") : nil,
                        tripleSorter,
                        RChartSectionJumpIdNone,
                        logging && NO);
    };
  }
  NSMutableDictionary *lineCharts = [NSMutableDictionary dictionary];
  if (allTimeChartPanelMaker) {
    lineCharts[chartId] = @[chartId, allTimeChartPanelMaker, @(sortOrder++)];
  }
  chartId = makeChartId(1);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Body Segments",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.bodySegmentColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes between your upper and lower body, over time.",
                          timeQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdNone,
                      logging && NO);
  }, @(sortOrder++)];
  if (!headless) {
    chartId = makeChartId(3);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return makeChartSectionPanel([NSString stringWithFormat:@"%@Rest Time Between Sets%@ by Muscle Group", chartTitlePrefix, chartTitlePostfix],
                                   asb(@"The following timeline charts detail %@ across the individual muscles of your muscle groups.",
                                       sectionHighlightText), areDistributionTuples); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(2);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByMuscleGroupTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your major muscle groups, over time.",
                          timeQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(4);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByUpperBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleGroupColors,
                      controller.normalLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your upper body muscle groups, over time.",
                          timeQualifier],
                         @"upper body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(5);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByShoulderMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(SHOULDER_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual shoulder muscles, over time.",
                          timeQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(6);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByChestMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CHEST_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual chest muscles, over time.",
                          timeQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(7);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByBackMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(BACK_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual back muscles, over time.",
                          timeQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(8);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Biceps",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByBicepsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(BICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the biceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdBiceps,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(9);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByTricepsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(TRICEP_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your individual tricep muscles, over time.",
                          timeQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) {
    chartId = makeChartId(10);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Forearms",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByForearmsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(FOREARMS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the forearms") : nil,
                        tripleSorter,
                        RChartSectionJumpIdForearms,
                        logging && NO);
    }, @(sortOrder++)];
  }
  chartId = makeChartId(11);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByAbsMgTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.muscleColors[@(CORE_MG_ID)],
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across your core muscles, over time.",
                          timeQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(12);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body Muscle Groups",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByLowerBodySegmentTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.lowerBodyMuscleGroupColors,
                      controller.thickerLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across all your lower body muscle groups, over time.",
                          timeQualifier],
                         @"lower body movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  if (!areDistributionTuples) { // single-muscle muscle groups, so is not relevant for this distribution chart
    chartId = makeChartId(13);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Quads",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByQuadsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(QUADRICEPS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the quadriceps") : nil,
                        tripleSorter,
                        RChartSectionJumpIdQuads,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(14);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hamstrings",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByHamstringsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HAMSTRINGS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the hamstrings") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHamstrings,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(15);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Calfs",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByCalfsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(CALVES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the calfs") : nil,
                        tripleSorter,
                        RChartSectionJumpIdCalfs,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(16);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Glutes",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByGlutesMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(GLUTES_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                            timeQualifier],
                           @"movements that hit the glutes") : nil,
                        tripleSorter,
                        RChartSectionJumpIdGlutes,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(17);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Abductors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByHipAbductorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_ABDUCTORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 timeQualifier],
                                @"movements that hit the hip abductors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipAbductors,
                        logging && NO);
    }, @(sortOrder++)];
    chartId = makeChartId(18);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return tupleMaker(chartId,
                        [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                        @"Hip Flexors",
                        ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                          return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                                 firstDate:chartData.startDate
                                                                  lastDate:chartData.endDate
                                                          withRawContainer:chartData.timeBetweenSetsSameMovByHipFlexorsMgTimeSeries
                                                         calculateAverages:calculateAverages
                                                    calculateDistributions:calculateDistributions
                                                                   logging:logging && NO];
                        },
                        controller.muscleColors[@(HIP_FLEXORS_MG_ID)],
                        controller.thickerLineWidth,
                        as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, evolves over time.",
                                 timeQualifier],
                                @"movements that hit the hip flexors") : nil,
                        tripleSorter,
                        RChartSectionJumpIdHipFlexors,
                        logging && NO);
    }, @(sortOrder++)];
  }
  if (!headless) {
    chartId = makeChartId(19);
    lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
      return makeChartSectionPanel([NSString stringWithFormat:@"%@Rest Time Between Sets%@ by Movement Variant", chartTitlePrefix, chartTitlePostfix],
                                   asb(@"The following charts detail how your %@ distributes across the different movement variants, over time.",
                                       sectionHighlightText), NO); }, @(sortOrder++), @(YES)];
  }
  chartId = makeChartId(20);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"All Muscle Groups - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.timeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"all movements") : nil,
                      tripleSorter,
                      RChartSectionJumpIdAll,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(21);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Upper Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit upper body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdUpperBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(22);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Shoulders - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the shoulders") : nil,
                      tripleSorter,
                      RChartSectionJumpIdShoulders,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(23);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Chest - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.chestTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the chest") : nil,
                      tripleSorter,
                      RChartSectionJumpIdChest,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(24);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Back - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.backTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the back") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBack,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(25);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Biceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the biceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdBiceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(26);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Triceps - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the triceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdTriceps,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(27);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Forearms - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the forearms") : nil,
                      tripleSorter,
                      RChartSectionJumpIdForearms,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(28);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Core - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.absTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit your core") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCore,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(29);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Lower Body - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit lower body muscles") : nil,
                      tripleSorter,
                      RChartSectionJumpIdLowerBody,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(30);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Quads - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the quadriceps") : nil,
                      tripleSorter,
                      RChartSectionJumpIdQuads,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(31);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hamstrings - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the hamstrings") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHamstrings,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(32);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Calfs - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the calfs") : nil,
                      tripleSorter,
                      RChartSectionJumpIdCalfs,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(33);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Glutes - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                          timeQualifier],
                         @"movements that hit the glutes") : nil,
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(34);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Abductors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                               timeQualifier],
                              @"movements that hit the hip abductors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdHipAbductors,
                      logging && NO);
  }, @(sortOrder++)];
  chartId = makeChartId(35);
  lineCharts[chartId] = @[chartId, ^RChartAndLoaderTuple * (void) {
    return tupleMaker(chartId,
                      [NSString stringWithFormat:@"%@Rest Time%@", chartTitlePrefix, chartTitlePostfix],
                      @"Hip Flexors - Movement Variants",
                      ^(RChartStrengthRawData *chartData, RChartConfigAggregateBy aggregateBy) {
                        return [RUtils normalizeUsingGroupIntervalInDays:aggregateBy
                                                               firstDate:chartData.startDate
                                                                lastDate:chartData.endDate
                                                        withRawContainer:chartData.hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries
                                                       calculateAverages:calculateAverages
                                                  calculateDistributions:calculateDistributions
                                                                 logging:logging && NO];
                      },
                      controller.movementVariantColors,
                      controller.thickLineWidth,
                      as ? as([NSString stringWithFormat:@"This chart illustrates how the %@, for %%@, distributes across the different movement variants, over time.",
                               timeQualifier],
                              @"movements that hit the hip flexors") : nil,
                      tripleSorter,
                      RChartSectionJumpIdGlutes,
                      logging && NO);
  }, @(sortOrder++)];
  return lineCharts;
}

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
                                                                               logging:(BOOL)logging {
  return [RAbstractChartController makeTimeBetweenSetsTimelineChartAndLoaderTuplesWithFetchMode:fetchMode
                                                                              calculateAverages:calculateAverages
                                                                         calculateDistributions:calculateDistributions
                                                                                  chartIdPrefix:chartIdPrefix
                                                                             yaxisValueLabelBlk:nil
                                                                                    maxValueBlk:maxValueBlk
                                                                                      yvalueBlk:yvalueBlk
                                                                              yaxisFormatterBlk:nil
                                                                                yaxisMaximumBlk:nil
                                                                                   isPercentage:0
                                                                               chartTitlePrefix:nil
                                                                              chartTitlePostfix:nil
                                                                           sectionHighlightText:nil
                                                                                  timeQualifier:nil
                                                                                 relativeToView:nil
                                                                                strengthConfigs:strengthConfigs
                                                                                     controller:nil
                                                                          areDistributionTuples:areDistributionTuples
                                                                                       coordDao:coordDao
                                                                              chartViewDelegate:nil
                                                                                      uitoolkit:nil
                                                                                  screenToolkit:nil
                                                                                   panelToolkit:nil
                                                                                       headless:YES
                                                                        entitiesAndRawDataCache:entitiesAndRawDataCache
                                                                                        logging:logging];
}

#pragma mark - Notification handlers

- (void)indicateChartHardReloadNeeded:(NSNotification *)notification {
  [self.coordDao deleteChartCacheForUser:_user error:[RUtils localSaveErrorHandlerMaker]()];
  [self.entitiesAndRawDataCache removeAllObjects];
  _forcedReloadChartsNeeded = YES;
}

- (void)indicateChartHardForcedReloadNeeded:(NSNotification *)notification {
  [self.coordDao deleteChartCacheForUser:_user error:[RUtils localSaveErrorHandlerMaker]()];
  [self.entitiesAndRawDataCache removeAllObjects];
  _forcedReloadChartsNeeded = YES;
}

#pragma mark - Device Rotation

- (void)willRepaintDueToRotate {
  _deviceWasRotated = YES;
}

#pragma mark - Rotate Chart Reload Button

- (void)rotateChartReloadButton {
  CABasicAnimation *rotate =
  [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  rotate.byValue = @(M_PI * -2); // Change to - angle for counter clockwise rotation
  rotate.duration = CHART_RELOAD_BUTTON_ROTATION_DURATION;
  [_chartReloadButton.layer addAnimation:rotate forKey:@"myRotationAnimation"];
  _chartsReloadButtonNeedsAnimation = NO;
}

#pragma mark - Chart Loading

- (void)enableAllChartLoadingHudsForTuples:(NSArray *)chartAndLoaderTuplesArray {
  NSInteger numTuples = chartAndLoaderTuplesArray.count;
  for (NSInteger i = 0; i < numTuples; i++) {
    RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTuplesArray[i];
    if ([PEUtils isNotNil:chartAndLoaderTuple.pieChartDataLoader] ||
        [PEUtils isNotNil:chartAndLoaderTuple.lineChartDataLoader]) {
      if (chartAndLoaderTuple.progressHud) {
        [chartAndLoaderTuple.progressHud hideAnimated:NO];
      }
      UIView *viewForHudDisplay = [RAbstractChartController viewForHudDisplayForTuple:chartAndLoaderTuple];
      chartAndLoaderTuple.progressHud = [MBProgressHUD showHUDAddedTo:viewForHudDisplay animated:YES];
      [viewForHudDisplay bringSubviewToFront:chartAndLoaderTuple.progressHud];
      [RAbstractChartController configureChartLoadingHud:chartAndLoaderTuple.progressHud];
    }
  }
}

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages {
  // to be overridden
}

- (void)showChartsAlreadyLoadingInfoAlert {
  [PEUIUtils showInfoAlertWithTitle:@"Already Loading"
                   alertDescription:AS(@"The charts are currently loading.")
                descLblHeightAdjust:0.0
          additionalContentSections:nil
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay"
                       buttonAction:^{}
                     relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
}

#pragma mark - Configure Pull-to-Refresh

- (void)configurePullToRefreshOnDisplayPanel:(UIScrollView *)displayPanel {
  void (^chartLoadingCompletionBlk)(void) = ^{
    [displayPanel.pullToRefreshView stopAnimating];
  };
  [displayPanel addPullToRefreshWithActionHandler:^{
    // I currently have a bug that I cannot reproduce (arrgg!) where sometimes
    // the charts have not loaded...so, if user taps (the now, always-white, chart-reload
    // button), I want it to always reload the charts
    [self loadChartsWithCompletion:chartLoadingCompletionBlk
         showAlertIfAlreadyLoading:YES
                          headless:NO
                   calcPercentages:self.calcPercentages
                      calcAverages:self.calcAverages];
  }];
  [displayPanel.pullToRefreshView setTitle:@"Pull to reload charts" forState:SVPullToRefreshStateTriggered];
  [displayPanel.pullToRefreshView setTitle:@"Pull to reload charts" forState:SVPullToRefreshStateStopped];
  [displayPanel.pullToRefreshView setTitle:@"Reloading charts..." forState:SVPullToRefreshStateLoading];
}

#pragma mark - Preferred Content Size Changed Notification Handler

- (void)preferredContentSizeChanged:(NSNotification *)notification {
  [self loadChartsWithCompletion:nil
       showAlertIfAlreadyLoading:NO
                        headless:NO
                 calcPercentages:self.calcPercentages
                    calcAverages:self.calcAverages];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  void (^addObserver)(SEL, NSString *) = ^(SEL selector, NSString *name) {
    [notificationCenter addObserver:self selector:selector name:name object:nil];
  };
  addObserver(@selector(chartSettingsClearedNotification:), RChartSettingsClearedNotification);
  addObserver(@selector(chartSettingsDoneNotification:), RChartSettingsDoneNotification);
  for (NSString *notificationName in [RAbstractChartController hardChartReloadNotificationNames]) {
    [notificationCenter addObserver:self
                           selector:@selector(indicateChartHardReloadNeeded:)
                               name:notificationName
                             object:nil];
  }
  for (NSString *notificationName in [RAbstractChartController hardChartForcedReloadNotificationNames]) {
    [notificationCenter addObserver:self
                           selector:@selector(indicateChartHardForcedReloadNeeded:)
                               name:notificationName
                             object:nil];
  }
  [notificationCenter addObserver:self
                         selector:@selector(preferredContentSizeChanged:)
                             name:UIContentSizeCategoryDidChangeNotification
                           object:nil];
  [self loadChartsWithCompletion:nil
       showAlertIfAlreadyLoading:NO
                        headless:NO
                 calcPercentages:self.calcPercentages
                    calcAverages:self.calcAverages];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  UIScrollView *displayPanel = (UIScrollView *)[self displayPanel];
  [self configurePullToRefreshOnDisplayPanel:displayPanel];
  if (_deviceWasRotated || _forcedReloadChartsNeeded) {
    [self loadChartsWithCompletion:nil
         showAlertIfAlreadyLoading:NO
                          headless:NO
                   calcPercentages:self.calcPercentages
                      calcAverages:self.calcAverages];
  }
  _forcedReloadChartsNeeded = NO;
  _deviceWasRotated = NO;
}

@end
