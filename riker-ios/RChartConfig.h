//
//  RChartConfig.h
//  riker-ios
//
//  Created by PEVANS on 3/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PELMMainSupport.h"

typedef NS_ENUM(NSInteger, RChartConfigAggregateBy) {
  RChartConfigAggregateByDay   = 1,
  RChartConfigAggregateByWeek  = 7,
  RChartConfigAggregateByMonth = 30,
  RChartConfigAggregateByQuarter = 90,
  RChartConfigAggregateByHalfYear = 180,
  RChartConfigAggregateByYear  = 365
};

typedef NS_ENUM(NSInteger, RChartConfigCategory) {
  RChartConfigCategoryWeight = 1,
  RChartConfigCategoryReps,
  RChartConfigCategoryRest,
  RChartConfigCategoryBody
};

@interface RChartConfig : PELMMainSupport <NSCopying>

+ (RChartConfig *)chartConfig; 

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                          chartId:(NSString *)chartId
                         category:(RChartConfigCategory)category
                        startDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                   boundedEndDate:(BOOL)boundedEndDate
                      aggregateBy:(NSNumber *)aggregateBy
           suppressPieSliceLabels:(BOOL)suppressPieSliceLabels
                       importedAt:(NSDate *)importedAt;

#pragma mark - Creation Functions

+ (instancetype)chartConfigWithChartId:(NSString *)chartId
                              category:(RChartConfigCategory)category
                             startDate:(NSDate *)startDate
                               endDate:(NSDate *)endDate
                        boundedEndDate:(BOOL)boundedEndDate
                           aggregateBy:(NSNumber *)aggregateBy
                suppressPieSliceLabels:(BOOL)suppressPieSliceLabels
                            importedAt:(NSDate *)importedAt
                             mediaType:(HCMediaType *)mediaType;

+ (instancetype)chartConfigWithChartId:(NSString *)chartId
                              category:(RChartConfigCategory)category
                             startDate:(NSDate *)startDate
                               endDate:(NSDate *)endDate
                        boundedEndDate:(BOOL)boundedEndDate
                           aggregateBy:(NSNumber *)aggregateBy
                suppressPieSliceLabels:(BOOL)suppressPieSliceLabels
                            importedAt:(NSDate *)importedAt
                 localMasterIdentifier:(NSNumber *)localMasterIdentifier
                      globalIdentifier:(NSString *)globalIdentifier
                             mediaType:(HCMediaType *)mediaType
                             relations:(NSDictionary *)relations
                             createdAt:(NSDate *)createdAt
                             deletedAt:(NSDate *)deletedAt
                             updatedAt:(NSDate *)updatedAt;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RChartConfig *)chartConfig;

- (void)overwrite:(RChartConfig *)chartConfig;

#pragma mark - Properties

@property (nonatomic) NSDate *importedAt;
@property (nonatomic) NSString *chartId;
@property (nonatomic) RChartConfigCategory category;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) BOOL boundedEndDate;
@property (nonatomic) NSNumber *aggregateBy; // relevant to line charts only
@property (nonatomic) BOOL suppressPieSliceLabels; // relevant to pie charts only

#pragma mark - Equality

- (BOOL)isEqualToChartConfig:(RChartConfig *)chartConfig;

#pragma mark - Helpers

+ (NSString *)nameForAggregateByValue:(RChartConfigAggregateBy)aggregateBy;

+ (NSString *)xaxisDateFormatForAggregateByValue:(RChartConfigAggregateBy)aggregateBy;

@end
