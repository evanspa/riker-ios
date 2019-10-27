//
//  RLocalDao.h
//  riker-ios
//
//  Created by PEVANS on 10/24/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PELMDefs.h"
#import "RUtils.h"

@protocol PELocalDao;

@class PELMUser;
@class RUserSettings;
@class RMuscleGroup;
@class RMuscle;
@class RMuscleAlias;
@class RBodySegment;
@class RMovement;
@class RMovementAlias;
@class RMovementVariant;
@class RSet;
@class RBodyMeasurementLog;
@class ROriginationDevice;
@class RChangeLog;
@class RUserSettings;
@class RChartConfig;
@class RLineChartDataCache;
@class LineChartData;

@protocol RLocalDao <PELocalDao>

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath;

#pragma mark - Initialize Database

- (void)initializeDatabaseWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                           error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Export

- (void)exportWithPathToSetsFile:(NSString *)setsFile
         bodyMeasurementLogsFile:(NSString *)bodyMeasurementLogsFile
                            user:(PELMUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)exportWithPathToSetsFile:(NSString *)setsFile
                            user:(PELMUser *)user
                           error:(PELMDaoErrorBlk)errorBlk;

- (void)exportWithPathToBodyMeasurementLogsFile:(NSString *)bodyMeasurementLogsFile
                                           user:(PELMUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Firebase User Property Logging

- (void)logFirebaseUserProperties;

#pragma mark - Unsynced and Sync-Needed Counts

- (NSInteger)numUnsyncedSettingsForUser:(PELMUser *)user;

- (NSInteger)numUnsyncedSetsForUser:(PELMUser *)user;

- (NSInteger)numUnsyncedBmlsForUser:(PELMUser *)user;

- (NSInteger)totalNumUnsyncedEntitiesForUser:(PELMUser *)user;

- (NSInteger)numSyncNeededSettingsForUser:(PELMUser *)user;

- (NSInteger)numSyncNeededSetsForUser:(PELMUser *)user;

- (NSInteger)numSyncNeededBmlsForUser:(PELMUser *)user;

- (NSInteger)totalNumSyncNeededEntitiesForUser:(PELMUser *)user;

#pragma mark - Change Log Operations

- (NSArray *)saveChangelog:(RChangeLog *)changelog
                   forUser:(PELMUser *)user
           userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Transform to Local Only User

- (void)checkLocalEntityGlobalIdsForUser:(PELMUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Origination Devices

- (NSArray *)originationDevicesWithError:(PELMDaoErrorBlk)errorBlk;

- (ROriginationDevice *)originationDeviceWithId:(NSNumber *)originationDeviceId
                                          error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Movements and Settings for Watch

- (NSMutableDictionary *)movementsAndSettingsForWatchWithUser:(PELMUser *)user
                                                 userSettings:(RUserSettings *)userSettings
                                                        error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Body Segments

- (NSArray *)bodySegmentsWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Muscle Groups

- (NSArray *)muscleGroupsWithError:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)muscleGroupsForBodySegmentId:(NSNumber *)bodySegmentId
                                    error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)muscleGroupsAndMovementsWithError:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Muscles

- (NSArray *)musclesWithError:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)primaryMusclesForMovementId:(NSNumber *)movementId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)secondaryMusclesForMovementId:(NSNumber *)movementId
                                     error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Muscle Alias

- (NSArray *)muscleAliasesForMuscleId:(NSNumber *)muscleId
                                error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Movements

- (NSArray *)movementsWithNameOrAliasLike:(NSString *)searchText error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)movementsWithNilMuscleIdsWithError:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)movementsWithError:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)movementsForMuscleGroupId:(NSNumber *)muscleGroupId
                                 error:(PELMDaoErrorBlk)errorBlk;

- (NSString *)canonicalNameForMovementId:(NSNumber *)movementId
                                   error:(PELMDaoErrorBlk)errorBlk;

- (RMovement *)movementForMovementId:(NSNumber *)movementId
                               error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterMovement:(RMovement *)movement
                        error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Movement Alias

- (NSArray *)movementAliasesForMovementId:(NSNumber *)movementId
                                    error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Movement Variants

- (NSArray *)movementVariantsWithError:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)movementVariantsForMovementVariantMask:(NSNumber *)variantMask
                                              error:(PELMDaoErrorBlk)errorBlk;

- (NSString *)nameForMovementVariantId:(NSNumber *)movementVariantId
                                 error:(PELMDaoErrorBlk)errorBlk;

- (RMovementVariant *)movementVariantForMovementVariantId:(NSNumber *)movementVariantId
                                                    error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterMovementVariant:(RMovementVariant *)movementVariant
                               error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User Settings

- (RUserSettings *)masterUserSettingsWithId:(NSNumber *)userSettingsId error:(PELMDaoErrorBlk)errorBlk;

- (RUserSettings *)masterUserSettingsWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (RUserSettings *)masterUserSettingsWithGlobalId:(NSString *)globalId
                                               db:(FMDatabase *)db
                                            error:(PELMDaoErrorBlk)errorBlk;

- (RUserSettings *)userSettingsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk;

- (RUserSettings *)markUserSettingsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForUserSettings:(RUserSettings *)userSettings
                     httpRespCode:(NSNumber *)httpRespCode
                        errorMask:(NSNumber *)errorMask
                          retryAt:(NSDate *)retryAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedUserSettings:(RUserSettings *)userSettings
                                         forUser:(PELMUser *)user
                         writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                           error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUserSettings:(RUserSettings *)userSettings
                       forUser:(PELMUser *)user
       writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Sets

- (RSet *)setWithCorrelationGuid:(NSString *)correlationGuid error:(PELMDaoErrorBlk)errorBlk;

- (RSet *)masterSetWithId:(NSNumber *)setId error:(PELMDaoErrorBlk)errorBlk;

- (RSet *)masterSetWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numSetsForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numSyncedImportedSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSDate *)mostRecentSetDateForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                             since:(NSDate *)since
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                         pageSize:(NSInteger)pageSize
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                         pageSize:(NSInteger)pageSize
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewSet:(RSet *)set forUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewSets:(NSArray *)sets
            forUser:(PELMUser *)user
              error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateSet:(RSet *)set
                           forUser:(PELMUser *)user
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)saveSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markSetsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForSet:(RSet *)set
            httpRespCode:(NSNumber *)httpRespCode
               errorMask:(NSNumber *)errorMask
                 retryAt:(NSDate *)retryAt
                   error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterSet:(RSet *)set
                 forUser:(PELMUser *)user
 writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterSet:(RSet *)set
              forUser:(PELMUser *)user
writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewSet:(RSet *)set
                            forUser:(PELMUser *)user
            writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedSet:(RSet *)set
                                forUser:(PELMUser *)user
                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numSetsWithUuid:(NSString *)uuid
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Body Measurement Logs

- (RBodyMeasurementLog *)mostRecentBmlWithNonNilWeightForUser:(PELMUser *)user
                                                        error:(PELMDaoErrorBlk)errorBlk;

- (RBodyMeasurementLog *)masterBmlWithId:(NSNumber *)bmlId error:(PELMDaoErrorBlk)errorBlk;

- (RBodyMeasurementLog *)masterBmlWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numBmlsWithNonNilBodyWeightForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numBmlsWithNonNilBodyWeightForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numSyncedImportedBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingBmlsForUser:(PELMUser *)user pageSize:(NSInteger)pageSize error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)descendingBmlsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk;

- (RBodyMeasurementLog *)nearestBmlWithNonNilBodyWeightToDate:(NSDate *)nearestTo
                                                         user:(PELMUser *)user
                                                        error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)unsyncedBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewBml:(RBodyMeasurementLog *)bml forUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewBmls:(NSArray *)bmls forUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewAndSyncImmediateBml:(RBodyMeasurementLog *)bml
                           forUser:(PELMUser *)user
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)saveBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markBmlsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForBml:(RBodyMeasurementLog *)bml
            httpRespCode:(NSNumber *)httpRespCode
               errorMask:(NSNumber *)errorMask
                 retryAt:(NSDate *)retryAt
                   error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewMasterBml:(RBodyMeasurementLog *)bml
                 forUser:(PELMUser *)user
 writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterBml:(RBodyMeasurementLog *)bml
              forUser:(PELMUser *)user
writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForNewBml:(RBodyMeasurementLog *)bml
                            forUser:(PELMUser *)user
            writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                              error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUpdatedBml:(RBodyMeasurementLog *)bml
                                forUser:(PELMUser *)user
                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                  error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numBmlsWithUuid:(NSString *)uuid
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Chart Config

- (RChartConfig *)chartConfigWithChartId:(NSString *)chartId user:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteChartConfigsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteChartConfigsByCategory:(RChartConfigCategory)category user:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteChartConfigByChartId:(NSString *)chartId user:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (PELMSaveNewOrExistingCode)saveNewOrExistingByChartIdChartConfig:(RChartConfig *)chartConfig
                                                           forUser:(PELMUser *)user
                                                             error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Chart Cache

- (void)deleteChartCacheForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteChartCacheForUser:(PELMUser *)user
                       category:(RChartConfigCategory)category
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)saveLineChartDataCacheWithChartData:(LineChartData *)chartData
                                    chartId:(NSString *)chartId
                              chartConfigId:(NSNumber *)chartConfigId
                                   category:(RChartConfigCategory)category
                                aggregateBy:(RChartConfigAggregateBy)aggregateBy
                            xaxisLabelCount:(NSInteger)xaxisLabelCount
                                   maxValue:(NSDecimalNumber *)maxValue
                                       user:(PELMUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk;

- (RLineChartDataCache *)lineChartDataCacheForChartId:(NSString *)chartId
                                        chartConfigId:(NSNumber *)chartConfigId
                                                 user:(PELMUser *)user
                                                error:(PELMDaoErrorBlk)errorBlk;

@end
