//
//  RChartConfig.m
//  riker-ios
//
//  Created by PEVANS on 3/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RChartConfig.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

CGFloat const NUM_SECONDS_IN_DAY = 86400;

@implementation RChartConfig

+ (RChartConfig *)chartConfig {
  return [[RChartConfig alloc] init];
}

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
                       importedAt:(NSDate *)importedAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _chartId = chartId;
    _category = category;
    _startDate = startDate;
    _endDate = endDate;
    _boundedEndDate = boundedEndDate;
    _aggregateBy = aggregateBy;
    _suppressPieSliceLabels = suppressPieSliceLabels;
    _importedAt = importedAt;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RChartConfig *copy =
  [[RChartConfig alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                              localMasterIdentifier:[self localMasterIdentifier]
                                   globalIdentifier:[self globalIdentifier]
                                          mediaType:[self mediaType]
                                          relations:nil
                                          createdAt:[self createdAt]
                                          deletedAt:[self deletedAt]
                                          updatedAt:[self updatedAt]
                               dateCopiedFromMaster:[self dateCopiedFromMaster]
                                     editInProgress:NO
                                     syncInProgress:[self syncInProgress]
                                             synced:[self synced]
                                          editCount:[self editCount]
                                   syncHttpRespCode:[self syncHttpRespCode]
                                        syncErrMask:[self syncErrMask]
                                        syncRetryAt:[self syncRetryAt]
                                            chartId:_chartId
                                           category:_category
                                          startDate:_startDate
                                            endDate:_endDate
                                     boundedEndDate:_boundedEndDate
                                        aggregateBy:_aggregateBy
                             suppressPieSliceLabels:_suppressPieSliceLabels
                                         importedAt:_importedAt];
  return copy;
}

#pragma mark - Creation Functions

+ (instancetype)chartConfigWithChartId:(NSString *)chartId
                              category:(RChartConfigCategory)category
                             startDate:(NSDate *)startDate
                               endDate:(NSDate *)endDate
                        boundedEndDate:(BOOL)boundedEndDate
                           aggregateBy:(NSNumber *)aggregateBy
                suppressPieSliceLabels:(BOOL)suppressPieSliceLabels
                            importedAt:(NSDate *)importedAt
                             mediaType:(HCMediaType *)mediaType {
  return [RChartConfig chartConfigWithChartId:chartId
                                     category:category
                                    startDate:startDate
                                      endDate:endDate
                               boundedEndDate:boundedEndDate
                                  aggregateBy:aggregateBy
                       suppressPieSliceLabels:suppressPieSliceLabels
                                   importedAt:importedAt
                        localMasterIdentifier:nil
                             globalIdentifier:nil
                                    mediaType:mediaType
                                    relations:nil
                                    createdAt:nil
                                    deletedAt:nil
                                    updatedAt:nil];
}

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
                             updatedAt:(NSDate *)updatedAt {
  return [[RChartConfig alloc] initWithLocalMainIdentifier:nil
                                     localMasterIdentifier:localMasterIdentifier
                                          globalIdentifier:globalIdentifier
                                                 mediaType:mediaType
                                                 relations:relations
                                                 createdAt:createdAt
                                                 deletedAt:deletedAt
                                                 updatedAt:updatedAt
                                      dateCopiedFromMaster:nil
                                            editInProgress:NO
                                            syncInProgress:NO
                                                    synced:NO
                                                 editCount:0
                                          syncHttpRespCode:nil
                                               syncErrMask:nil
                                               syncRetryAt:nil
                                                   chartId:chartId
                                                  category:category
                                                 startDate:startDate
                                                   endDate:endDate
                                            boundedEndDate:boundedEndDate
                                               aggregateBy:aggregateBy
                                    suppressPieSliceLabels:suppressPieSliceLabels
                                                importedAt:importedAt];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RChartConfig *)chartConfig {
  [super overwriteDomainProperties:chartConfig];
  [self setChartId:chartConfig.chartId];
  [self setCategory:chartConfig.category];
  [self setStartDate:chartConfig.startDate];
  [self setEndDate:chartConfig.endDate];
  [self setAggregateBy:chartConfig.aggregateBy];
  [self setSuppressPieSliceLabels:chartConfig.suppressPieSliceLabels];
}

- (void)overwrite:(RChartConfig *)chartConfig {
  [super overwrite:chartConfig];
  [self overwriteDomainProperties:chartConfig];
}

#pragma mark - Equality

- (BOOL)isEqualToChartConfig:(RChartConfig *)chartConfig {
  if (!chartConfig) { return NO; }
  if ([super isEqualToMainSupport:chartConfig]) {
    return [PEUtils isStringProperty:@selector(chartId) equalFor:self and:chartConfig] &&
    [PEUtils isNumProperty:@selector(aggregateBy) equalFor:self and:chartConfig] &&
    [PEUtils isBoolProperty:@selector(suppressPieSliceLabels) equalFor:self and:chartConfig] &&
    [PEUtils isDateProperty:@selector(startDate) equalFor:self and:chartConfig] &&
    [PEUtils isDateProperty:@selector(endDate) equalFor:self and:chartConfig];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RChartConfig class]]) { return NO; }
  return [self isEqualToChartConfig:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self chartId] hash] ^
  [[self startDate] hash] ^
  [[self endDate] hash] ^
  [_aggregateBy hash] ^
  [[NSNumber numberWithBool:_suppressPieSliceLabels] hash];
}

#pragma mark - Helpers

+ (NSString *)nameForAggregateByValue:(RChartConfigAggregateBy)aggregateBy {
  switch (aggregateBy) {
    case RChartConfigAggregateByDay:
      return @"by day";
    case RChartConfigAggregateByWeek:
      return @"by week";
    case RChartConfigAggregateByMonth:
      return @"by month";
    case RChartConfigAggregateByQuarter:
      return @"by quarter";
    case RChartConfigAggregateByHalfYear:
      return @"by half-year";
    case RChartConfigAggregateByYear:
      return @"by year";
  }
  return nil;
}

+ (NSString *)xaxisDateFormatForAggregateByValue:(RChartConfigAggregateBy)aggregateBy {
  switch (aggregateBy) {
    case RChartConfigAggregateByDay:
      return @"d MMM";
    case RChartConfigAggregateByWeek:
      return @"d MMM";
    case RChartConfigAggregateByMonth:
      return @"MMM";
    case RChartConfigAggregateByQuarter:
      return @"MMM ''yy";
    case RChartConfigAggregateByHalfYear:
      return @"MMM ''yy";
    case RChartConfigAggregateByYear:
      return @"yyyy";
  }
  return nil;
}

@end
