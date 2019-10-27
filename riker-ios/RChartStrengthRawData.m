//
//  RChartStrengthRawData.m
//  riker-ios
//
//  Created by PEVANS on 3/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RChartStrengthRawData.h"

@implementation RChartStrengthRawData

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

#pragma mark - Creation Helpers

+ (instancetype)timeBetweenDistChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.totalTimeBetweenSetsSameMovByBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByMuscleGroup = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByUpperBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByLowerBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByShoulderMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByBackMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByAbsMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByChestMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalTimeBetweenSetsSameMovByTricepsMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalUpperBodyTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalLowerBodyTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalShoulderTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalBackTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalTricepsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalAbsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalChestTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHamstringsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalQuadsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalCalfsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalGlutesTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHipAbductorsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHipFlexorsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalBicepsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalForearmsTimeBetweenSetsSameMovByMovementVariant = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)timeBetweenLineChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.timeBetweenSetsSameMovTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByUpperBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByLowerBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByShoulderMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByBackMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByAbsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByChestMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByTricepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByBicepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByForearmsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByHamstringsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByQuadsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByCalfsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByGlutesMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByHipAbductorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.timeBetweenSetsSameMovByHipFlexorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.backTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.absTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.chestTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)weightLiftedLineChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.weightTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByUpperBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByLowerBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByShoulderMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByBackMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByAbsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByChestMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByTricepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByBicepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByForearmsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByHamstringsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByQuadsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByCalfsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByGlutesMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByHipAbductorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.weightByHipFlexorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.upperBodyWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.lowerBodyWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.shoulderWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.backWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.tricepsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.bicepsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.forearmsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.absWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.chestWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hamstringsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.quadsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.calfsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.glutesWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipAbductorsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipFlexorsWeightByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)totalWeightLiftedDistChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.weightLiftedByBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByMuscleGroup = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByUpperBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByLowerBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByShoulderMg = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByBackMg = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByTricepsMg = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByAbsMg = [NSMutableDictionary dictionary];
  chartStrengthData.weightLiftedByChestMg = [NSMutableDictionary dictionary];
  chartStrengthData.upperBodyWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.lowerBodyWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.shoulderWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.backWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.tricepsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.bicepsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.forearmsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.absWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.chestWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.hamstringsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.quadsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.calfsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.glutesWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.hipAbductorsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.hipFlexorsWeightLiftedByMovementVariant = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)repsLineChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.repsTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByUpperBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByLowerBodySegmentTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByShoulderMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByBackMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByAbsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByChestMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByTricepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByBicepsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByForearmsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByHamstringsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByQuadsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByCalfsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByGlutesMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByHipAbductorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.repsByHipFlexorsMgTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.upperBodyRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.lowerBodyRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.shoulderRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.backRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.tricepsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.bicepsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.forearmsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.absRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.chestRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hamstringsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.quadsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.calfsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.glutesRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipAbductorsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  chartStrengthData.hipFlexorsRepsByMovementVariantTimeSeries = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)repsDistChartRawData {
  RChartStrengthRawData *chartStrengthData = [[RChartStrengthRawData alloc] init];
  chartStrengthData.totalRepsByBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByMuscleGroup = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByUpperBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByLowerBodySegment = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByShoulderMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByBackMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByTricepsMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByAbsMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalRepsByChestMg = [NSMutableDictionary dictionary];
  chartStrengthData.totalUpperBodyRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalLowerBodyRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalShoulderRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalBackRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalTricepsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalAbsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalChestRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHamstringsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalQuadsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalCalfsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalGlutesRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHipAbductorsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalHipFlexorsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalBicepsRepsByMovementVariant = [NSMutableDictionary dictionary];
  chartStrengthData.totalForearmsRepsByMovementVariant = [NSMutableDictionary dictionary];
  return chartStrengthData;
}

+ (instancetype)crossSectionChartRawData {
  RChartStrengthRawData *chartDataContainer = [[RChartStrengthRawData alloc] init];
  chartDataContainer.weightLiftedByMuscleGroup = [NSMutableDictionary dictionary];
  chartDataContainer.weightByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  chartDataContainer.totalRepsByMuscleGroup = [NSMutableDictionary dictionary];
  chartDataContainer.repsByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  chartDataContainer.totalTimeBetweenSetsSameMovByMuscleGroup = [NSMutableDictionary dictionary];
  chartDataContainer.timeBetweenSetsSameMovByMuscleGroupTimeSeries = [NSMutableDictionary dictionary];
  return chartDataContainer;
}

@end
