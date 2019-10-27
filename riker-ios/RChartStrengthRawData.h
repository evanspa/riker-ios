//
//  RChartStrengthRawData.h
//  riker-ios
//
//  Created by PEVANS on 3/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RPieSliceDataTuple;
@class RRawLineDataPointsByDateTuple;

@interface RChartStrengthRawData : NSObject

#pragma mark - Creation Helpers

+ (instancetype)timeBetweenDistChartRawData;
+ (instancetype)timeBetweenLineChartRawData;
+ (instancetype)weightLiftedLineChartRawData;
+ (instancetype)totalWeightLiftedDistChartRawData;
+ (instancetype)repsLineChartRawData;
+ (instancetype)repsDistChartRawData;
+ (instancetype)crossSectionChartRawData;

#pragma mark - Data Date Range

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;

#pragma mark - Containers

////////////////////////////////////////////////////////////////////////////////
// Weight Lifted - pie chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByMuscleGroup;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByUpperBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByLowerBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByShoulderMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByBackMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByAbsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByChestMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *weightLiftedByTricepsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *upperBodyWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *lowerBodyWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *shoulderWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *backWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *tricepsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *bicepsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *forearmsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *absWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *chestWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *hamstringsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *quadsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *calfsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *glutesWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *hipAbductorsWeightLiftedByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *hipFlexorsWeightLiftedByMovementVariant;

////////////////////////////////////////////////////////////////////////////////
// Weight Lifted - line chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByMuscleGroupTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByUpperBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByLowerBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByShoulderMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByBackMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByAbsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByChestMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByTricepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByBicepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByForearmsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByHamstringsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByQuadsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByCalfsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByGlutesMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByHipAbductorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *weightByHipFlexorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *upperBodyWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *lowerBodyWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *shoulderWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *backWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *tricepsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *bicepsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *forearmsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *absWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *chestWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hamstringsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *quadsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *calfsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *glutesWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipAbductorsWeightByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipFlexorsWeightByMovementVariantTimeSeries;

////////////////////////////////////////////////////////////////////////////////
// Reps - pie chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByMuscleGroup;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByUpperBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByLowerBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByShoulderMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByBackMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByAbsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByChestMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalRepsByTricepsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalUpperBodyRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalLowerBodyRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalShoulderRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalBackRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTricepsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalBicepsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalForearmsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalAbsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalChestRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHamstringsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalQuadsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalCalfsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalGlutesRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHipAbductorsRepsByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHipFlexorsRepsByMovementVariant;

////////////////////////////////////////////////////////////////////////////////
// Reps - line chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByMuscleGroupTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByUpperBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByLowerBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByShoulderMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByBackMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByAbsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByChestMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByTricepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByBicepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByForearmsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByHamstringsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByQuadsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByCalfsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByGlutesMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByHipAbductorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *repsByHipFlexorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *upperBodyRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *lowerBodyRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *shoulderRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *backRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *tricepsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *bicepsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *forearmsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *absRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *chestRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hamstringsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *quadsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *calfsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *glutesRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipAbductorsRepsByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipFlexorsRepsByMovementVariantTimeSeries;

////////////////////////////////////////////////////////////////////////////////
// Time Between Sets - pie chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByMuscleGroup;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByUpperBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByLowerBodySegment;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByShoulderMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByBackMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByAbsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByChestMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTimeBetweenSetsSameMovByTricepsMg;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalUpperBodyTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalLowerBodyTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalShoulderTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalBackTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalTricepsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalBicepsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalForearmsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalAbsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalChestTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHamstringsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalQuadsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalCalfsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalGlutesTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHipAbductorsTimeBetweenSetsSameMovByMovementVariant;
@property (nonatomic) NSMutableDictionary<NSNumber *, RPieSliceDataTuple *> *totalHipFlexorsTimeBetweenSetsSameMovByMovementVariant;

////////////////////////////////////////////////////////////////////////////////
// Time Between Sets - line chart data sources
////////////////////////////////////////////////////////////////////////////////
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByMuscleGroupTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByUpperBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByLowerBodySegmentTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByShoulderMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByBackMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByAbsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByChestMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByTricepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByBicepsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByForearmsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByHamstringsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByQuadsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByCalfsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByGlutesMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByHipAbductorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *timeBetweenSetsSameMovByHipFlexorsMgTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *upperBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *lowerBodyTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *shoulderTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *backTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *tricepsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *bicepsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *forearmsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *absTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *chestTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hamstringsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *quadsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *calfsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *glutesTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipAbductorsTimeBetweenSetsSameMovByMovementVariantTimeSeries;
@property (nonatomic) NSMutableDictionary<NSNumber *, RRawLineDataPointsByDateTuple *> *hipFlexorsTimeBetweenSetsSameMovByMovementVariantTimeSeries;

@end
