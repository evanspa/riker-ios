//
//  RChartAndLoaderTuple.h
//  riker-ios
//
//  Created by PEVANS on 5/25/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
@import Charts;
#pragma clang pop

@class PELMUser;
@class RUserSettings;
@class MBProgressHUD;

typedef NSArray *(^RLineChartDataLoader)(id,
                                         PELMUser *,
                                         RUserSettings *,
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
                                         NSDate *,
                                         NSDate *);

typedef NSArray *(^RPieChartDataLoader)(id,
                                        PELMUser *,
                                        RUserSettings *,
                                        NSArray *bodySegments,
                                        NSDictionary *bodySegmentsDict,
                                        NSArray *muscleGroups,
                                        NSDictionary *muscleGroupsDict,
                                        NSArray *muscles,
                                        NSDictionary *musclesDict,
                                        NSArray *movements,
                                        NSDictionary *movementsDict,
                                        NSArray *movementVariants,
                                        NSDictionary *movementVariantsDict);

typedef NSString *(^RUomDisplayBlk)(RUserSettings *);

typedef NS_ENUM(NSInteger, RChartSectionJumpId) {
  RChartSectionJumpIdNone,
  RChartSectionJumpIdAll,
  RChartSectionJumpIdUpperBody,
  RChartSectionJumpIdShoulders,
  RChartSectionJumpIdChest,
  RChartSectionJumpIdBack,
  RChartSectionJumpIdBiceps,
  RChartSectionJumpIdTriceps,
  RChartSectionJumpIdForearms,
  RChartSectionJumpIdCore,
  RChartSectionJumpIdLowerBody,
  RChartSectionJumpIdQuads,
  RChartSectionJumpIdHamstrings,
  RChartSectionJumpIdCalfs,
  RChartSectionJumpIdGlutes,
  RChartSectionJumpIdHipAbductors,
  RChartSectionJumpIdHipFlexors
};

@interface RChartAndLoaderTuple : NSObject

@property (nonatomic) UIView *chartPanelView;
@property (nonatomic) UIButton *settingsButton;
@property (nonatomic) UIView *chartCardPanel;
@property (nonatomic) CGFloat chartTitleVPadding;
@property (nonatomic) UIView *chartTitleLabel;
@property (nonatomic) UIView *chartSubTitleLabel;
@property (nonatomic) BOOL shouldAnimateSettingsButton;
@property (nonatomic) UIButton *jumptToTopButton; // chart section
@property (nonatomic) UIButton *jumpToAllButton; // chart section
@property (nonatomic) UIButton *jumpToUpperBodyButton; // chart section
@property (nonatomic) UIButton *jumpToShouldersButton; // chart section
@property (nonatomic) UIButton *jumpToChestButton; // chart section
@property (nonatomic) UIButton *jumpToBackButton; // chart section
@property (nonatomic) UIButton *jumpToTricepsButton; // chart section
@property (nonatomic) UIButton *jumpToBicepsButton; // chart section
@property (nonatomic) UIButton *jumpToForearmsButton; // chart section
@property (nonatomic) UIButton *jumpToAbsButton; // chart section
@property (nonatomic) UIButton *jumpToLowerBodyButton; // chart section
@property (nonatomic) UIButton *jumpToHamstringsButton; // chart section
@property (nonatomic) UIButton *jumpToQuadsButton; // chart section
@property (nonatomic) UIButton *jumpToCalfsButton; // chart section
@property (nonatomic) UIButton *jumpToGlutesButton; // chart section
@property (nonatomic) UIButton *jumpToHipAbductorsButton; // chart section
@property (nonatomic) UIButton *jumpToHipFlexorsButton; // chart section

@property (nonatomic) MBProgressHUD *progressHud;
@property (nonatomic) UIView *noChartDataPanel;
@property (nonatomic) LineChartView *lineChartView;
@property (nonatomic) UILabel *yaxisLabelView;
@property (nonatomic) RLineChartDataLoader lineChartDataLoader;
@property (nonatomic) BOOL isPercentage;
@property (nonatomic) RUomDisplayBlk uomDisplayBlk;
@property (nonatomic) RChartSectionJumpId jumpId;

@property (nonatomic) PieChartView *pieChartView;
@property (nonatomic) RPieChartDataLoader pieChartDataLoader;

@end
