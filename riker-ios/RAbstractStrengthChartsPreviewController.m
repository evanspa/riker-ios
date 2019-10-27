//
//  RAbstractStrengthChartsPreviewController.m
//  Riker
//
//  Created by PEVANS on 10/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RAbstractStrengthChartsPreviewController.h"
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
#import "RChartsListController.h"
#import "RWatchUtils.h"
@import StoreKit;
#import "RChartAndLoaderTuple.h"
#import "PEUtils.h"
#import "RChartIdPrefixes.h"

@implementation RAbstractStrengthChartsPreviewController

#pragma mark - Chart Config

- (NSString *)globalChartConfigSettingsEntityType {
  return @"set";
}

#pragma mark - Chart Loading

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages {
  if (headless || (!self.areTheChartsLoading || self.deviceWasRotated)) {
    void (^allDoneBlk)(NSInteger, NSInteger, NSInteger, NSInteger) = nil;
    if (!headless) {
      self.areTheChartsLoading = YES;
      [self enableAllChartLoadingHudsForTuples:self.chartAndLoaderTuplesArray];
      allDoneBlk = ^(NSInteger numSets, NSInteger numDaysOfSets, NSInteger numBmls, NSInteger numDaysOfBmls) {
        self.animateAllSettingsButtons = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RCHART_ANIMATION_DURATION * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          self.areTheChartsLoading = NO;
        });
        if ((numSets > 0 && numDaysOfSets == 0) || (numBmls > 0 && numDaysOfBmls == 0)) {
          [self maybeShow32bitIphoneLineChartMsg];
        }
        if (completion) { completion(); }
      };
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
      PELMUser *user = (PELMUser *)[self.coordDao userWithError:errorBlk];
      RUserSettings *userSettings = [self.coordDao userSettingsForUser:user error:errorBlk];
      NSArray *bodySegments = [self.coordDao bodySegmentsWithError:errorBlk];
      NSDictionary *bodySegmentsDict = [RUtils dictFromMasterEntitiesArray:bodySegments];
      NSArray *muscleGroups = [self.coordDao muscleGroupsWithError:errorBlk];
      NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:muscleGroups];
      NSArray *muscles = [self.coordDao musclesWithError:errorBlk];
      NSDictionary *musclesDict = [RUtils dictFromMasterEntitiesArray:muscles];
      NSArray *movements = [self.coordDao movementsWithError:errorBlk];
      NSDictionary *movementsDict = [RUtils dictFromMasterEntitiesArray:movements];
      NSArray *movementVariants = [self.coordDao movementVariantsWithError:errorBlk];
      NSDictionary *movementVariantsDict = [RUtils dictFromMasterEntitiesArray:movementVariants];
      NSArray *sets = [self.coordDao ascendingSetsForUser:user error:errorBlk];
      _numSets = [sets count];
      RSet *firstSet = [sets firstObject];
      RSet *lastSet = [sets lastObject];
      NSInteger numDaysOfSets = [lastSet.loggedAt daysLaterThan:firstSet.loggedAt];
      self.veryLastSetLoggedAt = lastSet.loggedAt;
      self.veryFirstSetLoggedAt = firstSet.loggedAt;
      NSArray *bmls = [self.coordDao ascendingBmlsForUser:user error:errorBlk];
      RBodyMeasurementLog *firstBml = [bmls firstObject];
      RBodyMeasurementLog *lastBml = [bmls lastObject];
      NSInteger numDaysOfBmls = [lastBml.loggedAt daysLaterThan:firstBml.loggedAt];
      self.veryLastBmlLoggedAt = lastBml.loggedAt;
      self.veryFirstBmlLoggedAt = firstBml.loggedAt;
      NSDate *veryFirstSetOnOrAfterLoggedAt = [PEUtils dateWithoutTimeFromDate:self.veryFirstSetLoggedAt];
      NSDate *veryLastSetOnOrBeforeLoggedAt = [[PEUtils dateWithoutTimeFromDate:self.veryLastSetLoggedAt] dateByAddingDays:1];
      RChartStrengthRawData *defaultStrengthChartData =
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
                                fetchMode:[self fetchMode]
                          calcPercentages:self.calcPercentages
                             calcAverages:self.calcAverages];
      NSInteger numStrengthTuples = self.chartAndLoaderTuplesArray.count;
      NSInteger totalNumTuplesToProcess = numStrengthTuples;
      __block NSInteger totalTuplesProcessed = 0;
      void (^processTuples)(NSArray *, id, NSDate *, NSDate *) = ^(NSArray *chartAndLoaderTuples, id defaultChartData, NSDate *onOrAfterLoggedAt, NSDate *onOrBeforeLoggedAt) {
        NSInteger numTuples = chartAndLoaderTuples.count;
        for (NSInteger i = 0; i < numTuples; i++) {
          RChartAndLoaderTuple *chartAndLoaderTuple = chartAndLoaderTuples[i];
          if (chartAndLoaderTuple.lineChartDataLoader) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              NSArray *result = chartAndLoaderTuple.lineChartDataLoader(defaultChartData,
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
              if (!headless) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  totalTuplesProcessed++;
                  [self handleLineChartResult:result
                          chartAndLoaderTuple:chartAndLoaderTuple
                                 userSettings:userSettings
                        animateSettingsButton:self.animateAllSettingsButtons];
                  if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(sets.count, numDaysOfSets, bmls.count, numDaysOfBmls); }
                });
              }
            });
          } else if (chartAndLoaderTuple.pieChartDataLoader) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              NSArray *result = chartAndLoaderTuple.pieChartDataLoader(defaultChartData,
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
              if (!headless) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  totalTuplesProcessed++;
                  [self handlePieChartResult:result
                         chartAndLoaderTuple:chartAndLoaderTuple
                       animateSettingsButton:self.animateAllSettingsButtons];
                  if (totalTuplesProcessed + 1 == totalNumTuplesToProcess) { allDoneBlk(sets.count, numDaysOfSets, bmls.count, numDaysOfBmls); }
                });
              }
            });
          }
        }
      };
      processTuples(self.chartAndLoaderTuplesArray, defaultStrengthChartData, veryFirstSetOnOrAfterLoggedAt, veryLastSetOnOrBeforeLoggedAt);
    });
  } else {
    if (completion) { completion(); }
    if (showAlertIfAlreadyLoading) { [self showChartsAlreadyLoadingInfoAlert]; }
  }
}

#pragma mark - Jump To Buttons

- (NSArray *)makeJumpToButtons {
  UIButton *(^makeJumpButton)(NSString *) = [RAbstractChartController jumpButtonMaker];
  return @[makeJumpButton(@"total"),
           makeJumpButton(@"avg"),
           makeJumpButton(@"dist"),
           makeJumpButton(@"dist / time")];
}

@end
