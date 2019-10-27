//
//  RLocalDaoImpl.m
//  riker-ios
//
//  Created by PEVANS on 10/24/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RLocalDaoImpl.h"

#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CHCSVParser/CHCSVParser.h>
#import <DateTools/DateTools.h>
#import "AppDelegate.h"
#import <PINCache/PINCache.h>
#import "NSDate+RAdditions.h"

#import "RKnownMediaTypes.h"
#import "PEUtils.h"
#import "NSString+PEAdditions.h"
#import "HCMediaType.h"
#import "PELMDDL.h"
#import "PELMUtils.h"
#import "PELMDefs.h"
#import "PELMNotificationUtils.h"
#import "PELMUser.h"

#import "RUtils.h"
#import "RDDLUtils.h"
#import "RLogging.h"

#import "RChangeLog.h"
#import "RUserSettings.h"
#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMuscleAlias.h"
#import "RMovement.h"
#import "RMovementAlias.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"
#import "RErrorDomainsAndCodes.h"
#import "RWatchUtils.h"
#import "RMovementSearchResult.h"
#import "RChartConfig.h"
#import "RLineChartDataCache.h"
@import Charts;
#import "LineChartDataSet+RAdditions.h"
@import Firebase;
#import "RAppNotificationNames.h"

typedef void(^RAddColumnBlk)(NSString *, NSString *, NSString *);

// this should always be 1 higher than our most recent available set of
// schema updates, as represented by the applyVersion<#>SchemaEditsWithDb:error:
// function with the highest "<#>" value
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 1;  // submitted to App Store on 06/23/2017
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 2;  // submitted to App Store on 06/27/2017
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 3;  // submitted to App Store on 07/06/2017
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 4;  // submitted to App Store on 08/28/2017 (build 1.7-b23)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 5;  // submitted to App Store on 09/23/2017 (build 1.8-b43)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 6;  // submitted to App Store on 10/09/2017 (build 1.9-b68)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 7;  // submitted to App Store on 11/12/2017 (build 1.14-b5)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 8;  // submitted to App Store on 11/28/2017 (build 1.15-b23)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 9;  // submitted to App Store on 12/30/2017 (build 1.19-b13)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 10; // submitted to App Store on 01/19/2018 (build 1.23-b18)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 11; // submitted to App Store on 02/21/2018 (build 1.24-b72)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 12; // submitted to App Store on 04/09/2018 (build 1.27-b5)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 13; // submitted to App Store on 07/14/2018 (build 1.35-b6)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 14; // submitted to App Store on 09/30/2018 (build 1.36-b82)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 15; // submitted to App Store on 11/18/2018 (build 1.37-b23)
//uint32_t const R_REQUIRED_SCHEMA_VERSION = 16; // submitted to App Store on 03/08/2019 (build 1.42-b66)
uint32_t const R_REQUIRED_SCHEMA_VERSION = 17;   // submitted to App Store on TBD (build 1.44-b12)

NSInteger const MUSCLE_ID_DELTS_REAR  = 1;
NSInteger const MUSCLE_ID_DELTS_FRONT = 2;
NSInteger const MUSCLE_ID_DELTS_SIDE  = 3;
NSInteger const MUSCLE_ID_BACK_UPPER  = 5;
NSInteger const MUSCLE_ID_BACK_LOWER  = 6;
NSInteger const MUSCLE_ID_CHEST_UPPER = 8;
NSInteger const MUSCLE_ID_CHEST_LOWER = 9;
NSInteger const MUSCLE_ID_ABS_UPPER   = 11;
NSInteger const MUSCLE_ID_ABS_LOWER   = 12;
NSInteger const MUSCLE_ID_SERRATUS    = 13;
NSInteger const MUSCLE_ID_QUADS       = 14;
NSInteger const MUSCLE_ID_HAMS        = 15;
NSInteger const MUSCLE_ID_CALFS       = 16;
NSInteger const MUSCLE_ID_BICEPS      = 18;
NSInteger const MUSCLE_ID_FOREARMS    = 19;
NSInteger const MUSCLE_ID_TRAPS       = 20;
NSInteger const MUSCLE_ID_GLUTES      = 21;
NSInteger const MUSCLE_ID_TRICEP_LAT  = 22;
NSInteger const MUSCLE_ID_TRICEP_LONG = 23;
NSInteger const MUSCLE_ID_TRICEP_MED  = 24;
NSInteger const MUSCLE_ID_OBLIQUES    = 25;
NSInteger const MUSCLE_ID_HIP_ABDUCTORS = 26;
NSInteger const MUSCLE_ID_HIP_FLEXORS = 27;

@implementation RLocalDaoImpl

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath {
  self = [super initWithSqliteDataFilePath:sqliteDataFilePath];
  if (self) {
  }
  return self;
}

#pragma mark - Initialize Database

- (void)initializeDatabaseWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                           error:(PELMDaoErrorBlk)errorBlk {
  __block uint32_t currentSchemaVersion;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    currentSchemaVersion = [db userVersion];
  }];
  DDLogInfo(@"in RLocalDao/initializeDatabaseWithError:, currentSchemaVersion: %d.  Required schema version: %d.", currentSchemaVersion, R_REQUIRED_SCHEMA_VERSION);
  void (^appliedUpdatesDebugLogger)(NSInteger) = ^(NSInteger version) {
    DDLogInfo(@"in RLocalDao/initializeDatabaseWithError:, applied schema updates for version %ld.", (long)version);
  };
  NSInteger versionApplied = currentSchemaVersion;
  NSMutableArray *changesForWatchPush = [NSMutableArray array];
  switch (currentSchemaVersion) {
    case 0: // will occur on very first startup of the app on user's device
      if ([self applyVersion0SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 1:
      if ([self applyVersion1SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 2:
      if ([self applyVersion2SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 3:
      if ([self applyVersion3SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 4:
      if ([self applyVersion4SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 5:
      if ([self applyVersion5SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 6:
      if ([self applyVersion6SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 7:
      if ([self applyVersion7SchemaEditsWithError:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 8:
      if ([self applyVersion8SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 9:
      if ([self applyVersion9SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 10:
      if ([self applyVersion10SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 11:
      if ([self applyVersion11SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 12:
      if ([self applyVersion12SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 13:
      if ([self applyVersion13SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 14:
      if ([self applyVersion14SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 15:
      if ([self applyVersion15SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case 16:
      if ([self applyVersion16SchemaEditsWithSqliteDataFilePath:sqliteDataFilePath error:errorBlk]) [changesForWatchPush addObject:@(1)];
      appliedUpdatesDebugLogger(versionApplied++);
      // fall-through to apply "next" schema updates
    case R_REQUIRED_SCHEMA_VERSION:
      // great, nothing needed to do except update the db's schema version
      [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db setUserVersion:R_REQUIRED_SCHEMA_VERSION];
      }];
      break;
  }
  if (changesForWatchPush.count > 0) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:RSendAllDataToAppleWatchNotification
                                                          object:nil];
    });
  }
}

#pragma mark - Schema version: FUTURE VERSION

#pragma mark - Schema edits, version: 16

// submitted to App Store on TBD (build 1.44-b12)
- (BOOL)applyVersion16SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  // This is the first version of the app where we are pushing the 'all data' to Apple Watch as part of an
  // app update.  This returning 'YES' will ensure that every user will get the watch data-push on this update.
  return YES;
}

#pragma mark - Schema edits, version: 15

// submitted to App Store on 03/08/2019 (build 1.42-b66)
- (BOOL)applyVersion15SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = 'core' where %@ = %ld", TBL_MASTER_MUSCLE_GROUP, COL_MUSCLE_GROUP_NAME, COL_LOCAL_ID, (long)CORE_MG_ID]
                         db:db
                      error:errorBlk];
        RMuscleGroupInserter insMuscleGroup = [self makeMuscleGroupInserterWithDb:db errorBlk:errorBlk];
        RMuscleInserter insMuscle = [self makeMuscleInserterWithDb:db errorBlk:errorBlk];
        insMuscleGroup(@(LOWER_BODY_SEGMENT_ID), @(HIP_ABDUCTORS_MG_ID), @"hip abductors", nil);
        insMuscleGroup(@(LOWER_BODY_SEGMENT_ID), @(HIP_FLEXORS_MG_ID), @"hip flexors", nil);
        insMuscle(@(CORE_MG_ID), @(MUSCLE_ID_OBLIQUES), @"obliques", nil);
        insMuscle(@(HIP_ABDUCTORS_MG_ID), @(MUSCLE_ID_HIP_ABDUCTORS), @"hip abductors", nil);
        insMuscle(@(HIP_FLEXORS_MG_ID), @(MUSCLE_ID_HIP_FLEXORS), @"hip flexors", nil);
        RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
        RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
        NSInteger movementId = 125; // fyi, dumbbell rotational punch is ID 124 (current max movement ID)
        // new movements
        insMovementImp(@(movementId++), // id
                       @"high twist", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_OBLIQUES), // primary muscles
                         @(MUSCLE_ID_ABS_UPPER)],
                       @[], // secondary muscles
                       @[]); // aliases
        insMovementImp(@(movementId++), // id
                       @"low twist", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_OBLIQUES), // primary muscles
                         @(MUSCLE_ID_ABS_LOWER)],
                       @[], // secondary muscles
                       @[]); // aliases
        insMovementImp(@(movementId++), // id
                       @"close-grip pulldown", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID),
                         @(MACHINE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                         @(MUSCLE_ID_BACK_LOWER)],
                       @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                       @[]); // aliases
        
        NSInteger movementAliasId = 61; // ('60' is the current max ID in alias table - 'rear lateral raises')
        NSInteger movAlias1 = movementAliasId++;
        insMovementImp(@(movementId++), // id
                       @"delt flys", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID),
                         @(MACHINE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_DELTS_REAR)], // primary muscles
                       @[@(MUSCLE_ID_BACK_UPPER)], // secondary muscles
                       @[@[@(movAlias1), @"rear flys"], // aliases
                         @[@(movementAliasId++), @"rear delt flys"]]);
        insMovementImp(@(movementId++), // id
                       @"hip abduction", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_HIP_ABDUCTORS)], // primary muscles
                       @[], // secondary muscles
                       @[]); // aliases
        insMovementImp(@(movementId++), // id
                       @"hip flexor", // canonical name
                       NO, // is body lift
                       nil, // % of body weight
                       @[@(CABLE_MOVEMENT_VARIANT_ID)], // variants
                       @[@(MUSCLE_ID_HIP_FLEXORS)], // primary muscles
                       @[], // secondary muscles
                       @[]); // aliases
        [self clearChartCacheWithDb:db errorBlk:errorBlk];
    }];
    return YES;
}

#pragma mark - Schema edits, version: 14

// submitted to App Store on 11/18/2018 (build 1.37-b23)
- (BOOL)applyVersion14SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:@"drop table if exists iad_attribution"
                     db:db
                  error:errorBlk];
  }];
  [self transformToLocalOnlyUserWithError:errorBlk]; // removing account capability from Riker
  return NO;
}

#pragma mark - Schema edits, version: 13

// submitted to App Store on 09/30/2018 (build 1.36-b82)
- (BOOL)applyVersion13SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[NSString stringWithFormat:@"alter table %@ add column %@ integer null", TBL_MASTER_USER, COL_USR_FACEBOOK_USER_ID]
                     db:db
                  error:errorBlk];
    [PELMUtils doUpdate:[NSString stringWithFormat:@"alter table %@ add column %@ integer not null default 0", TBL_MASTER_USER, COL_USR_HAS_PASSWORD]
                     db:db
                  error:errorBlk];
    // toggle on if the user currently has an account (no social logins yet, so must have a password)
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = 1 where %@ is not null", TBL_MASTER_USER, COL_USR_HAS_PASSWORD, COL_GLOBAL_ID]
                     db:db
                  error:errorBlk];
  }];
  return NO;
}

#pragma mark - Schema edits, version: 12

// submitted to App Store on 07/14/2018 (build 1.35-b6)
- (BOOL)applyVersion12SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    //[PELMUtils doUpdate:[RDDLUtils iadAttributionDDL] db:db error:errorBlk]; // got rid of this in version 14
  }];
  return NO;
}

#pragma mark - Schema edits, version: 11

// submitted to App Store on 04/09/2018 (build 1.27-b5)
- (BOOL)applyVersion11SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    NSInteger movementId = 124; // fyi, step-up is ID 123 (current max movement ID)
    // new movements
    insMovementImp(@(movementId++), // id
                   @"dumbbell rotational punch", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variants
                   @[@(MUSCLE_ID_DELTS_REAR), // primary muscles
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_SERRATUS)],
                   @[], // secondary muscles
                   @[]); // aliases
  }];
  return YES;
}

#pragma mark - Schema edits, version: 10

// submitted to App Store on 02/21/2018 (build 1.24-b72)
- (BOOL)applyVersion10SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                  error:(PELMDaoErrorBlk)errorBlk {
  // clear the cache because now the database will be the storage medium for chart cache
  [[PINCache sharedCache] removeAllObjects];
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[RDDLUtils chartDDL] db:db error:errorBlk];
    [PELMUtils doUpdate:[RDDLUtils chartPieSliceDDL] db:db error:errorBlk];
    [PELMUtils doUpdate:[RDDLUtils chartTimeSeriesDDL] db:db error:errorBlk];
    [PELMUtils doUpdate:[RDDLUtils chartTimeSeriesDataPointDDL] db:db error:errorBlk];
  }];
  return NO;
}

#pragma mark - Schema edits, version: 9

// submitted to App Store on 01/19/2018 (build 1.23-b18)
- (BOOL)applyVersion9SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                 error:(PELMDaoErrorBlk)errorBlk {
  // clear the cache because now the database will be the storage medium for
  // chart configs
  [[PINCache sharedCache] removeAllObjects];
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[RDDLUtils chartConfigDDL] db:db error:errorBlk];
    [PELMUtils doUpdate:[PELMDDL indexDDLForEntity:TBL_CHART_CONFIG
                                            unique:NO
                                            column:COL_CHART_CONFIG_CATEGORY
                                         indexName:@"idx_chart_config_category"] db:db error:errorBlk];
  }];
  return NO;
}

#pragma mark - Schema edits, version: 8

// submitted to App Store on 12/30/2017 (build 1.19-b13)
- (BOOL)applyVersion8SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                 error:(PELMDaoErrorBlk)errorBlk {
  // So we can't use self.databaseQueue, because self.databaseQueue already has
  // enabled FKs (and from testing, once the FKs are enabled using the pragma
  // statement, they cannot seem to be turned off...weird...so we need to create
  // a fresh database queue directly).
  FMDatabaseQueue *databaseQueue = [FMDatabaseQueue databaseQueueWithPath:sqliteDataFilePath];
  [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [db executeQuery:@"PRAGMA foreign_keys = OFF"]; // this is needed to make our fixes
    PELMDaoErrorBlk errorBlk = [RUtils localSaveErrorHandlerMaker]();
    void (^dropTable)(NSString *) = ^(NSString *table) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"drop table if exists %@", table] db:db error:errorBlk];
    };
    void (^dropRelTable)(NSString *) = ^(NSString *table) {
      dropTable([NSString stringWithFormat:@"%@_rel", table]);
    };
    // drop all the relation tables
    dropRelTable(@"main_set");
    dropRelTable(@"master_set");
    dropRelTable(@"main_user");
    dropRelTable(@"master_user");
    dropRelTable(@"main_user_settings");
    dropRelTable(@"master_user_settings");
    dropRelTable(@"main_body_measurement_log");
    dropRelTable(@"master_body_measurement_log");
    
    void (^dropNotNullConstraints)(NSString *, NSString *) = ^(NSString *table, NSString *tableCreateDDL) {
      NSString *tmpTable = [NSString stringWithFormat:@"tmp_%@", table];
      [PELMUtils doUpdate:[NSString stringWithFormat:@"alter table %@ rename to %@", table, tmpTable]
                       db:db
                    error:errorBlk];
      NSString *newTableCreateDDL = [tableCreateDDL stringByReplacingOccurrencesOfString:@"global_identifier TEXT UNIQUE NOT NULL" withString:@"global_identifier TEXT UNIQUE NULL"];
      newTableCreateDDL = [newTableCreateDDL stringByReplacingOccurrencesOfString:@"media_type TEXT NOT NULL" withString:@"media_type TEXT NULL"];
      newTableCreateDDL = [newTableCreateDDL stringByReplacingOccurrencesOfString:@"created_at INTEGER NOT NULL" withString:@"created_at INTEGER NULL"];
      newTableCreateDDL = [newTableCreateDDL stringByReplacingOccurrencesOfString:@"updated_at INTEGER NOT NULL" withString:@"updated_at INTEGER NULL"];
      [PELMUtils doUpdate:newTableCreateDDL
                       db:db
                    error:errorBlk];
      [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ select * from %@", table, tmpTable]
                       db:db
                    error:errorBlk];
      dropTable(tmpTable);
    };
    
    // remove non-null contrainst from global_identifier columns
    dropNotNullConstraints(TBL_MASTER_USER, [RDDLUtils masterUserDDL]);
    dropNotNullConstraints(TBL_MASTER_USER_SETTINGS, [RDDLUtils masterUserSettingsDDL]);
    dropNotNullConstraints(TBL_MASTER_SET, [RDDLUtils masterSetDDL]);
    dropNotNullConstraints(TBL_MASTER_BODY_MEASUREMENT_LOG, [RDDLUtils masterBodyMeasurementLogDDL]);
    
    // add main-specific columns to master tables
    void (^addColumn)(NSString *, NSString *, NSString *) = ^(NSString *table, NSString *column, NSString *type) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"alter table %@ add column %@ %@", table, column, type] db:db error:errorBlk];
    };
    void (^addIntegerColumn)(NSString *, NSString *) = ^(NSString *table, NSString *column) {
        //[PELMUtils doUpdate:[NSString stringWithFormat:@"alter table %@ add column %@ integer", table, column] db:db error:errorBlk];
      addColumn(table, column, @"integer");
    };
    void (^addAllIntegerColumns)(NSString *) = ^(NSString *table) {
      addIntegerColumn(table, COL_SYNC_IN_PROGRESS);
      addIntegerColumn(table, COL_SYNCED);
      addIntegerColumn(table, COL_SYNC_HTTP_RESP_CODE);
      addIntegerColumn(table, COL_SYNC_ERR_MASK);
      addIntegerColumn(table, COL_SYNC_RETRY_AT);
    };
    addAllIntegerColumns(TBL_MASTER_SET);
    addAllIntegerColumns(TBL_MASTER_BODY_MEASUREMENT_LOG);
    addAllIntegerColumns(TBL_MASTER_USER_SETTINGS);
    addAllIntegerColumns(TBL_MASTER_USER);
    [PELMUtils doUpdate:[PELMDDL indexDDLForEntity:TBL_MASTER_SET
                                            unique:YES
                                            column:COL_SET_CORRELATION_GUID
                                         indexName:@"uidx_set_correlation_guid"] db:db error:errorBlk];
    addColumn(TBL_MASTER_SET, COL_SET_UUID, @"text");
    [PELMUtils doUpdate:[PELMDDL indexDDLForEntity:TBL_MASTER_SET
                                            unique:YES
                                            column:COL_SET_UUID
                                         indexName:@"uidx_set_guid"] db:db error:errorBlk];
    addColumn(TBL_MASTER_BODY_MEASUREMENT_LOG, COL_BML_UUID, @"text");
    [PELMUtils doUpdate:[PELMDDL indexDDLForEntity:TBL_MASTER_BODY_MEASUREMENT_LOG
                                            unique:YES
                                            column:COL_BML_UUID
                                         indexName:@"uidx_bml_guid"] db:db error:errorBlk];
    // need to move main records to master tables
    void (^processMainEntities)(NSString *, NSString *, PELMEntityFromResultSetBlk, NSString *, NSArray *(^)(id), void(^)(id)) = ^(NSString *mainTable, NSString *masterTable, PELMEntityFromResultSetBlk mainRsConverter, NSString *updateStmt, NSArray *(^argsArrayBlk)(id entity), void(^masterInserter)(id entity)) {
      NSArray *mainEntities = [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@", mainTable]
                                                 argsArray:@[]
                                               rsConverter:mainRsConverter
                                                        db:db
                                                     error:errorBlk];
      for (RSet *mainEntity in mainEntities) {
        if (mainEntity.globalIdentifier) {
          // update/overwrite associated master row
          mainEntity.localMasterIdentifier = [PELMUtils numberFromTable:masterTable
                                                           selectColumn:COL_LOCAL_ID
                                                            whereColumn:COL_GLOBAL_ID
                                                             whereValue:mainEntity.globalIdentifier
                                                                     db:db
                                                                  error:errorBlk];
          mainEntity.synced = YES;
          NSNumber *editInProgressNum = [PELMUtils numberFromTable:mainTable
                                                      selectColumn:COL_EDIT_IN_PROGRESS
                                                       whereColumn:COL_GLOBAL_ID
                                                        whereValue:mainEntity.globalIdentifier
                                                                db:db
                                                             error:errorBlk];
          if (editInProgressNum && editInProgressNum.boolValue) {
            mainEntity.synced = NO;
          }
          [PELMUtils doUpdate:updateStmt
                    argsArray:argsArrayBlk(mainEntity)
                           db:db
                        error:errorBlk];
        } else {
          // insert up into master table
          mainEntity.synced = NO;
          masterInserter(mainEntity);
        }
      }
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = 1 where %@ is null", masterTable, COL_SYNCED, COL_SYNCED] db:db error:errorBlk];
    };
    processMainEntities(TBL_MAIN_USER,
                        TBL_MASTER_USER,
                        ^(FMResultSet *rs){return [self mainUserFromResultSet:rs];},
                        [self updateStmtForMasterUser],
                        ^(PELMUser *mainUser) {return [self updateArgsForMasterUser:mainUser];},
                        ^(PELMUser *mainUser) {[self insertIntoMasterUser:mainUser db:db error:errorBlk];});
    PELMUser *user = [self userWithDb:db error:errorBlk];
    processMainEntities(TBL_MAIN_USER_SETTINGS,
                        TBL_MASTER_USER_SETTINGS,
                        ^(FMResultSet *rs){return [self mainUserSettingsFromResultSet:rs];},
                        [self updateStmtForMasterUserSettings],
                        ^(RUserSettings *mainUserSettings) {return [self updateArgsForMasterUserSettings:mainUserSettings];},
                        ^(RUserSettings *mainUserSettings) {[self insertIntoMasterUserSettings:mainUserSettings forUser:user db:db error:errorBlk];});
    processMainEntities(TBL_MAIN_SET,
                        TBL_MASTER_SET,
                        ^(FMResultSet *rs){return [self mainSetFromResultSet:rs];},
                        [self updateStmtForMasterSet],
                        ^(RSet *mainSet) {return [self updateArgsForMasterSet:mainSet];},
                        ^(RSet *mainSet) {[self insertIntoMasterSet:mainSet forUser:user db:db error:errorBlk];});
    processMainEntities(TBL_MAIN_BODY_MEASUREMENT_LOG,
                        TBL_MASTER_BODY_MEASUREMENT_LOG,
                        ^(FMResultSet *rs){return [self mainBmlFromResultSet:rs];},
                        [self updateStmtForMasterBml],
                        ^(RBodyMeasurementLog *mainBml) {return [self updateArgsForMasterBml:mainBml];},
                        ^(RBodyMeasurementLog *mainBml) {[self insertIntoMasterBml:mainBml forUser:user db:db error:errorBlk];});
    // drop main tables
    dropTable(@"main_set");
    dropTable(@"main_body_measurement_log");
    dropTable(@"main_user_settings");
    dropTable(@"main_user");
  }];
  return NO;
}

#pragma mark - Schema edits, version: 7

// submitted to App Store on 11/28/2017 (build 1.15-b23)
- (BOOL)applyVersion7SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
    // no database updates to do...but need to clear cache...
    [[PINCache sharedCache] removeAllObjects];
    return NO;
}

#pragma mark - Schema edits, version: 6

// submitted to App Store on 10/09/2017 (build 1.9-b68)
- (BOOL)applyVersion6SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    // nothing
  }];
  return NO;
}

#pragma mark - Schema edits, version: 5

// submitted to App Store on 10/09/2017 (build 1.9-b68)
- (BOOL)applyVersion5SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    NSInteger movementId = 112; // fyi, high rows is ID 111 (current max movement ID)
    // new movements
    insMovementImp(@(movementId++), // id
                   @"rear delt machine", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID)], // variants
                   @[@(MUSCLE_ID_DELTS_REAR)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"calf press", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID),  // variants
                     @(SLED_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_CALFS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"burpee", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.85"], // % of body weight
                   @[], // variants
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_CALFS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"close-grip push-up", // canonical name
                   YES, // is body lift movement?
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_TRICEP_LAT), // primary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG)],
                   @[@(MUSCLE_ID_CHEST_UPPER), // secondary muscles
                     @(MUSCLE_ID_CHEST_LOWER)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hang power clean", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER), // secondary muscles
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"JM press", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CURL_BAR_MOVEMENT_VARIANT_ID),  // variant masks
                     @(BARBELL_MOVEMENT_VARIANT_ID),
                     @(SMITH_MACHINE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"pike press", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variants
                   @[@(MUSCLE_ID_DELTS_FRONT)], // primary muscles
                   @[@(MUSCLE_ID_TRICEP_MED), // secondary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_CHEST_UPPER)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"pike push-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variants
                   @[@(MUSCLE_ID_CHEST_UPPER)], // primary muscles
                   @[@(MUSCLE_ID_TRICEP_MED), // secondary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_DELTS_FRONT)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"rear lunges", // canonical name
                   NO, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(BODY_MOVEMENT_VARIANT_ID),
                     @(DUMBBELL_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_GLUTES), // primary muscles
                     @(MUSCLE_ID_QUADS)],
                   @[@(MUSCLE_ID_HAMS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"seated calf raises", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID)], // variants
                   @[@(MUSCLE_ID_CALFS)], //primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"side lunges", // canonical name
                   NO, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(BODY_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_GLUTES), // primary muscles
                     @(MUSCLE_ID_QUADS)],
                   @[@(MUSCLE_ID_HAMS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"step-up", // canonical name
                   NO, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(BODY_MOVEMENT_VARIANT_ID),
                     @(DUMBBELL_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_GLUTES), // primary muscles
                     @(MUSCLE_ID_QUADS)],
                   @[@(MUSCLE_ID_HAMS)], // secondary muscles
                   @[]); // aliases
    
    // fixes, updates, etc
    void (^update)(NSString *, NSString *, NSString *, NSInteger) = ^(NSString *tbl, NSString *updateCol, NSString *newVal, NSInteger idVal) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?", tbl, updateCol, COL_LOCAL_ID]
                argsArray:@[newVal, @(idVal)]
                       db:db
                    error:errorBlk];
    };
    update(TBL_MASTER_MOVEMENT, COL_MOVEMENT_CANONICAL_NAME, @"calf raises", 36);
    update(TBL_MASTER_MUSCLE_GROUP, COL_MUSCLE_GROUP_NAME, @"calfs", 7);
    update(TBL_MASTER_MUSCLE, COL_MUSCLE_CANONICAL_NAME, @"calfs", 16);
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1506103951000 / 1000.0)]; // Friday, September 22, 2017 2:12:31 PM GMT-04:00 DST
    RMovementAliasInserter insAlias = [self makeMovementAliasInserterWithCreatedAt:createdAt db:db errorBlk:errorBlk];
    NSInteger movementAliasId = 57; // ('56' is the current max ID in alias table - 'chest press')
    insAlias(37, movementAliasId++, @"bicep curls"); // new alias for 'curls' (mov ID = 37)
    insAlias(62, movementAliasId++, @"squat clean"); // new alias for 'clean' (mov ID = 62)
    insAlias(70, movementAliasId++, @"RDL"); // new alias for 'Romanian deadlift' (mov ID = 70)
    insAlias(24, movementAliasId++, @"rear lateral raises"); // new alias for 'bent-over laterals' (mov ID = 24)
  }];
  return YES;
}

#pragma mark - Schema edits, version: 4 (new movements and some updates)

// submitted to App Store on 09/23/2017 (as part of build 1.8-b43)
- (BOOL)applyVersion4SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    // new movements first...
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    NSInteger movementId = 103; // fyi, hanging serratus crunches is ID 102 (current max movement ID)
    NSInteger movementAliasId = 51; // ('50' is the current max ID in alias table - 'body weight squats')
    insMovementImp(@(movementId++), // id
                   @"landmine press", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_CHEST_LOWER), // primary muscles
                     @(MUSCLE_ID_CHEST_UPPER)],
                   @[@(MUSCLE_ID_TRICEP_LAT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_SERRATUS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"landmine squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_HAMS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"barbell thruster", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS), // primary muscles
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_BACK_UPPER)],
                   @[@(MUSCLE_ID_TRICEP_LAT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"landmine thruster", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS), // primary muscles
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_BACK_UPPER)],
                   @[@(MUSCLE_ID_TRICEP_LAT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"rotational single-arm press", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_GLUTES), // primary muscles
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_DELTS_REAR)],
                   @[], // secondary muscles
                   @[@[@(movementAliasId++), @"landmine rotational single-arm press"]]); // aliases
    NSInteger movAlias1 = movementAliasId++;
    NSInteger movAlias2 = movementAliasId++;
    insMovementImp(@(movementId++), // id
                   @"landmine anti-rotations", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_ABS_LOWER), // primary muscles
                     @(MUSCLE_ID_ABS_UPPER)],
                   @[], // secondary muscles
                   @[@[@(movAlias1), @"landmine 180s"], // aliases
                     @[@(movAlias2), @"landmine twists"],
                     @[@(movementAliasId++), @"landmine rotations"]]);
    insMovementImp(@(movementId++), // id
                   @"single-arm landmine row", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BACK_LOWER)],
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[@[@(movementAliasId++), @"Meadows row"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"typewriter push-up", // canonical name
                   YES, // is body lift movement?
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_CHEST_UPPER), // primary muscles
                     @(MUSCLE_ID_CHEST_LOWER)],
                   @[@(MUSCLE_ID_DELTS_FRONT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_SERRATUS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"high rows", // canonical name
                   NO, // is body lift movement?
                   nil, // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BACK_LOWER)],
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[]); // aliases
    
    // and now the updates...
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1506103951000 / 1000.0)]; // Friday, September 22, 2017 2:12:31 PM GMT-04:00 DST
    RMovementAliasInserter insAlias = [self makeMovementAliasInserterWithCreatedAt:createdAt db:db errorBlk:errorBlk];
    insAlias(0, movementAliasId++, @"chest press"); // new alias for 'bench press' (mov ID = 0)
    RMovementVariantMaskUpdater movVariantUpdater = [self makeMovementVariantMaskUpdaterWithDb:db errorBlk:errorBlk];
    movVariantUpdater(9, @[@(CABLE_MOVEMENT_VARIANT_ID), @(MACHINE_MOVEMENT_VARIANT_ID)]); // pulldowns
    movVariantUpdater(30, @[@(CURL_BAR_MOVEMENT_VARIANT_ID), @(DUMBBELL_MOVEMENT_VARIANT_ID)]); // skull crushers
    movVariantUpdater(8, @[@(BODY_MOVEMENT_VARIANT_ID), @(MACHINE_MOVEMENT_VARIANT_ID)]); // wide grip dips
    movVariantUpdater(27, @[@(BODY_MOVEMENT_VARIANT_ID), @(MACHINE_MOVEMENT_VARIANT_ID)]); // dips
  }];
  return YES;
}

#pragma mark - Schema edits, version: 3 (new movements and some updates)

// submitted to App Store on 08/28/2017 (as part of build 1.7-b23)
- (BOOL)applyVersion3SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    // add uuid columns
    [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT NULL", TBL_MAIN_SET, COL_SET_UUID]
                     db:db
                  error:errorBlk];
    [PELMUtils doUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT NULL", TBL_MAIN_BODY_MEASUREMENT_LOG, COL_SET_UUID]
                     db:db
                  error:errorBlk];
    // updates, fixes etc
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1502813170482 / 1000.0)]; // Tuesday, August 15, 2017 12:06:10.482 PM GMT-04:00 DST
    RMovementAliasInserter insAlias = [self makeMovementAliasInserterWithCreatedAt:createdAt db:db errorBlk:errorBlk];
    RSecondaryMovementInserter insSecondaryMov = [self makeSecondaryMovementInserterWithDb:db errorBlk:errorBlk];
    NSInteger movementAliasId = 48; // ('47' is the current max ID in alias table)
    // updates, fixes, etc
    insAlias(33, movementAliasId++, @"back squats"); // squats
    insAlias(33, movementAliasId++, @"barbell full squats");
    insSecondaryMov(33, MUSCLE_ID_GLUTES);
    insSecondaryMov(33, MUSCLE_ID_HAMS);
    insSecondaryMov(56, MUSCLE_ID_GLUTES); // box squats
    insSecondaryMov(56, MUSCLE_ID_HAMS);
    insSecondaryMov(58, MUSCLE_ID_HAMS); // hack squats
    insSecondaryMov(59, MUSCLE_ID_GLUTES); // split squats
    insSecondaryMov(59, MUSCLE_ID_HAMS);
    insSecondaryMov(60, MUSCLE_ID_GLUTES); // overhead squats
    insSecondaryMov(60, MUSCLE_ID_HAMS);
    insSecondaryMov(66, MUSCLE_ID_GLUTES); // jump squats
    insSecondaryMov(66, MUSCLE_ID_HAMS);
    // new movements
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    NSInteger movementId = 94; // current max movement ID in prod database is 93 ('grippers' movement)
    insMovementImp(@(movementId++), // id
                   @"power cleans", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_BACK_UPPER),
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_QUADS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"bent-over two-dumbbell rows", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_BACK_UPPER)], // primary muscles
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"air squats", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_HAMS)],
                   @[@[@(movementAliasId++), @"body weight squats"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"Zercher squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(SMITH_MACHINE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_HAMS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"dead-stop push-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_CHEST_LOWER), // primary muscles
                     @(MUSCLE_ID_CHEST_UPPER),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_SERRATUS),
                     @(MUSCLE_ID_TRAPS)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"plank push-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.64"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_CHEST_LOWER), // primary muscles
                     @(MUSCLE_ID_CHEST_UPPER),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_ABS_LOWER),
                     @(MUSCLE_ID_ABS_UPPER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"pullovers", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(CABLE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_CHEST_LOWER), // primary muscles
                     @(MUSCLE_ID_CHEST_UPPER),
                     @(MUSCLE_ID_SERRATUS)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"rope pulls", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_SERRATUS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hanging serratus crunches", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.50"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_SERRATUS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
  }];
  return YES;
}

#pragma mark - Schema edits, version: 2 (fixes and new movements)

- (BOOL)applyVersion2SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    /* First, the fixes: */
    // fix typo in name (id = 39); it's supposed to be 'pull-ups'
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_CANONICAL_NAME,
                         COL_LOCAL_ID]
              argsArray:@[@"pull-ups", @(39)]
                     db:db
                  error:errorBlk];
    // fix typo in name (id = 75); it's supposed to be 'inverted row'
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_CANONICAL_NAME,
                         COL_LOCAL_ID]
              argsArray:@[@"inverted row", @(75)]
                     db:db
                  error:errorBlk];
    // fix lunges movement (id = 55); it's supposed to have a 0.75 % of body-weight
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
                         COL_LOCAL_ID]
              argsArray:@[[NSDecimalNumber decimalNumberWithString:@"0.75"], @(55)]
                     db:db
                  error:errorBlk];
    // fix calve raises movement (id = 36); it's supposed to have a 1.0 % of body-weight
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
                         COL_LOCAL_ID]
              argsArray:@[[NSDecimalNumber decimalNumberWithString:@"1.0"], @(36)]
                     db:db
                  error:errorBlk];
    // fix jump squat movement (id = 66); it's supposed to have a 0.50 % of body-weight,
    // true body lift and variant mask of 0.
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ?, %@ = ?, %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
                         COL_MOVEMENT_IS_BODY_LIFT,
                         COL_MOVEMENT_VARIANT_MASK,
                         COL_LOCAL_ID]
              argsArray:@[[NSDecimalNumber decimalNumberWithString:@"0.50"],
                          @(YES),
                          @(0),
                          @(66)]
                     db:db
                  error:errorBlk];
    // fix hang snatch (id = 68); should have quads as an additional secondary muscle
    [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ (%@, %@) values (?, ?)",
                         TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                         COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID,
                         COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID]
              argsArray:@[@(68),
                          @(MUSCLE_ID_QUADS)]
                     db:db
                  error:errorBlk];

    /* And now, the new stuff: */
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    NSInteger movementId = 88; // current max movement ID in prod database is 87 ('high pull' movement)
    insMovementImp(@(movementId++), // id
                   @"reverse pushdowns", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"rope pushdowns", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"overhead extensions", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"overhead rope extensions", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"bench dips", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_TRICEP_MED), // primary muscles
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_LAT)],
                   @[], // secondary muscles
                   @[@[@(45), @"tricep bench dips"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"grippers", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_FOREARMS)], // primary muscles
                   @[], // secondary muscles
                   @[@[@(46), @"Captains of Crush Grippers"],
                     @[@(47), @"hand grippers"]]); // aliases
  }];
  [[PINCache sharedCache] removeAllObjects];
  return YES;
}

#pragma mark - Schema edits, version: 1 (colossal fuck up fix)

- (BOOL)applyVersion1SchemaEditsWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
                                                 error:(PELMDaoErrorBlk)errorBlk {
  // FYI, this is a big fucking bug/data fixing update.  Thank god you found it
  // soon.  We have a duplicate crunches movement (IDs 42 and 44).  42 is the
  // correct one.  44 should be a different movement altogether (which it is on
  // the server).  Bad fuck up.

  // So we can't use self.databaseQueue, because self.databaseQueue already has
  // enabled FKs (and from testing, once the FKs are enabled using the pragma
  // statement, they cannot seem to be turned off...weird...so we need to create
  // a fresh database queue directly).
  FMDatabaseQueue *databaseQueue = [FMDatabaseQueue databaseQueueWithPath:sqliteDataFilePath];
  [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [db executeQuery:@"PRAGMA foreign_keys = OFF"]; // this is needed to make our fixes
    ROriginationDeviceInserter insOriginationDevice = [self makeOrigDeviceInserterWithDb:db errorBlk:errorBlk];
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_ANDROID), @"Android", @"orig-device-android");
    NSNumber *nowNum = [PEUtils millisecondsFromDate:[NSDate date]];
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ?, %@ = ?, %@ = ? where %@ = ?",
                         TBL_MASTER_ORIGINATION_DEVICE,
                         COL_ORIG_DEVICE_NAME,
                         COL_ORIG_DEVICE_ICON_IMAGE_NAME,
                         COL_UPDATED_AT,
                         COL_LOCAL_ID]
              argsArray:@[@"Android Wear",
                          @"orig-device-android-wear",
                          nowNum,
                          @(ORIGINATION_DEVICE_ID_ANDROID_WEAR)]
                     db:db
                  error:errorBlk];
    // this is an incidental fix (not part of colossal fuck up; just fixing a typo)
    // This typo does not occur on the server.
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT_ALIAS,
                         COL_MOVEMENT_ALIAS_ALIAS,
                         COL_LOCAL_ID]
              argsArray:@[@"chest dips", @(12)]
                     db:db
                  error:errorBlk];
    // this is an improvement; making 'smith machine' a valid variant for calve raises (not
    // part of the colossal fuck up).
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ?, %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_VARIANT_MASK,
                         COL_UPDATED_AT,
                         COL_LOCAL_ID]
              argsArray:@[@(140), nowNum, @(36)]
                     db:db
                  error:errorBlk];
    // Okay, now let's fix the duplicate "crunches" movement problem.  What a PITA.
    // Need to do the following: (1) update all sets with duplicated crunches movement
    // ID (44) to correct crunches movement ID (42), and then (2) delete movement ID 44,
    // and finally, (3) need to fix the movements with IDs 45 - 88.  Each of these movements
    // need their ID decremented.  And of course, before we can do that, we need to update
    // any sets that have any of these movement IDs.  Here we go.  Steps (2) and (3) are
    // only needed if user hasn't created a Riker account (if user created a Riker
    // account, they would have gotten their movements fixed by the first full server
    // response automatically).
    void (^fixSets)(NSInteger, NSInteger) = ^ (NSInteger oldMovementId, NSInteger newMovementId) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                           TBL_MASTER_SET,
                           COL_SET_MOVEMENT_ID,
                           COL_SET_MOVEMENT_ID]
                argsArray:@[@(newMovementId), @(oldMovementId)]
                       db:db
                    error:errorBlk];
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                           TBL_MAIN_SET,
                           COL_SET_MOVEMENT_ID,
                           COL_SET_MOVEMENT_ID]
                argsArray:@[@(newMovementId), @(oldMovementId)]
                       db:db
                    error:errorBlk];
    };
    void (^delete)(NSString *, NSString *, NSInteger) = ^ (NSString *tbl, NSString *col, NSInteger movementId) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ?", tbl, col]
                argsArray:@[@(movementId)]
                       db:db
                    error:errorBlk];
    };
    NSString *canonicalNameAtId44 = [PELMUtils stringFromTable:TBL_MASTER_MOVEMENT
                                                  selectColumn:COL_MOVEMENT_CANONICAL_NAME
                                                   whereColumn:COL_LOCAL_ID
                                                    whereValue:@(44)
                                                            db:db
                                                         error:errorBlk];
    // First we fix any sets (in both master and main) to use the correct crunches movement ID.
    NSInteger duplicateCrunchesMovId = 44;
    fixSets(duplicateCrunchesMovId, 42); // 42 is correct 'crunches' movement ID; 44 is the duplicate version
    if ([canonicalNameAtId44 isEqualToString:@"crunches"]) {
      // User has not ever logged in, and therefore did not get all of their
      // movements auto-fixed from server-response.  So first we delete the duplicate crunches movement.
      delete(TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,   COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID, duplicateCrunchesMovId);
      delete(TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE, COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID, duplicateCrunchesMovId);
      delete(TBL_MASTER_MOVEMENT_ALIAS,            COL_MOVEMENT_ALIAS_MOVEMENT_ID, duplicateCrunchesMovId);
      delete(TBL_MASTER_MOVEMENT,                  COL_LOCAL_ID, duplicateCrunchesMovId);
      // Decrement the ID of all subsequent movements (IDs 45 - 88).
      for (NSInteger idValToFix = 45; idValToFix <= 88; idValToFix++) {
        NSInteger newMovementId = idValToFix - 1;
        fixSets(idValToFix, newMovementId);
        void (^updateMovDep)(NSString *, NSString *) = ^ (NSString *tbl, NSString *col) {
          [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?", tbl, col, col]
                    argsArray:@[@(newMovementId), @(idValToFix)]
                           db:db
                        error:errorBlk];
        };
        updateMovDep(TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,   COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID);
        updateMovDep(TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE, COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID);
        updateMovDep(TBL_MASTER_MOVEMENT_ALIAS,            COL_MOVEMENT_ALIAS_MOVEMENT_ID);
        [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ?, %@ = ? where %@ = ?",
                             TBL_MASTER_MOVEMENT,
                             COL_LOCAL_ID,
                             COL_GLOBAL_ID,
                             COL_LOCAL_ID]
                  argsArray:@[@(newMovementId),
                              [NSString stringWithFormat:@"%@/riker/d/movements/%@", GLOBAL_IDENTIFIER_PREFIX, @(newMovementId)],
                              @(idValToFix)]
                         db:db
                      error:errorBlk];
      }
    } else {
      // User has logged in and has gotten their (most) movements auto-fixed.  Just
      // need to delete movement ID 88 (which is now a duplicate of ID 87 - 'high pull')
      // and fix any sets.
      NSInteger duplicateHighPullMovId = 88;
      fixSets(duplicateHighPullMovId, 87); // 87 is the now correct ID for 'high pull'
      delete(TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,   COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID, duplicateHighPullMovId);
      delete(TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE, COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID, duplicateHighPullMovId);
      delete(TBL_MASTER_MOVEMENT_ALIAS,            COL_MOVEMENT_ALIAS_MOVEMENT_ID, duplicateHighPullMovId);
      delete(TBL_MASTER_MOVEMENT,                  COL_LOCAL_ID, duplicateHighPullMovId);
    }
  }];
  [[PINCache sharedCache] removeAllObjects];
  return YES;
}

#pragma mark - Schema edits, version: 0 (initial schema version)

- (BOOL)applyVersion0SchemaEditsWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    void (^applyDDL)(NSString *) = ^ (NSString *ddl) {
      [PELMUtils doUpdate:ddl db:db error:errorBlk];
    };
    void (^makeRelTable)(NSString *) = ^ (NSString *table) {
      applyDDL([PELMDDL relDDLForEntityTable:table]);
    };
    /* NOT USED AT THE MOMENT */
    /*void (^makeNonUniqueIndex)(NSString *, NSString *, NSString *) = ^(NSString *entity, NSString *col, NSString *name) {
     applyDDL([PELMDDL indexDDLForEntity:entity unique:NO column:col indexName:name]);
     };*/

    // ###########################################################################
    // Body Segment DDL
    // ###########################################################################
    // ------- master body segment -----------------------------------------------
    applyDDL([RDDLUtils masterBodySegmentDDL]);
    makeRelTable(TBL_MASTER_BODY_SEGMENT);

    // ###########################################################################
    // Muscle Group DDL
    // ###########################################################################
    // ------- master muscle group -----------------------------------------------
    applyDDL([RDDLUtils masterMuscleGroupDDL]);
    makeRelTable(TBL_MASTER_MUSCLE_GROUP);

    // ###########################################################################
    // Muscle DDL
    // ###########################################################################
    // ------- master muscle -----------------------------------------------------
    applyDDL([RDDLUtils masterMuscleDDL]);
    makeRelTable(TBL_MASTER_MUSCLE);

    // ###########################################################################
    // Muscle Alias DDL
    // ###########################################################################
    // ------- master muscle alias -----------------------------------------------
    applyDDL([RDDLUtils masterMuscleAliasDDL]);
    makeRelTable(TBL_MASTER_MUSCLE_ALIAS);

    // ###########################################################################
    // Movement DDL
    // ###########################################################################
    // ------- master movement ---------------------------------------------------
    applyDDL([RDDLUtils masterMovementDDL]);
    makeRelTable(TBL_MASTER_MOVEMENT);

    // ###########################################################################
    // Movement Primary Muscle DDL
    // ###########################################################################
    // ------- master movement primary muscle ------------------------------------
    applyDDL([RDDLUtils masterMovementPrimaryMuscleDDL]);

    // ###########################################################################
    // Movement Secondary Muscle DDL
    // ###########################################################################
    // ------- master movement secondary muscle ----------------------------------
    applyDDL([RDDLUtils masterMovementSecondaryMuscleDDL]);

    // ###########################################################################
    // Movement Alias DDL
    // ###########################################################################
    // ------- master movement alias ---------------------------------------------
    applyDDL([RDDLUtils masterMovementAliasDDL]);
    makeRelTable(TBL_MASTER_MOVEMENT_ALIAS);

    // ###########################################################################
    // Movement Variant DDL
    // ###########################################################################
    // ------- master movement variant -------------------------------------------
    applyDDL([RDDLUtils masterMovementVariantDDL]);
    makeRelTable(TBL_MASTER_MOVEMENT_VARIANT);

    // ###########################################################################
    // Origination Device DDL
    // ###########################################################################
    // ------- master origination device -----------------------------------------
    applyDDL([RDDLUtils masterOriginationDeviceDDL]);
    makeRelTable(TBL_MASTER_ORIGINATION_DEVICE);

    // ###########################################################################
    // User DDL
    // ###########################################################################
    // ------- master user -------------------------------------------------------
    applyDDL([RDDLUtils masterUserDDL]);
    makeRelTable(TBL_MASTER_USER);
    // ------- main vehicle ------------------------------------------------------
    applyDDL([RDDLUtils mainUserDDL]);
    applyDDL([RDDLUtils mainUserUniqueIndex1]);
    makeRelTable(TBL_MAIN_USER);

    // ###########################################################################
    // User Settings DDL
    // ###########################################################################
    // ------- master user settings ----------------------------------------------
    applyDDL([RDDLUtils masterUserSettingsDDL]);
    makeRelTable(TBL_MASTER_USER_SETTINGS);
    // ------- main user settings ------------------------------------------------
    applyDDL([RDDLUtils mainUserSettingsDDL]);
    makeRelTable(TBL_MAIN_USER_SETTINGS);

    // ###########################################################################
    // Set DDL
    // ###########################################################################
    // ------- master set --------------------------------------------------------
    applyDDL([RDDLUtils masterSetDDL]);
    makeRelTable(TBL_MASTER_SET);
    // ------- main set ----------------------------------------------------------
    applyDDL([RDDLUtils mainSetDDL]);
    makeRelTable(TBL_MAIN_SET);

    // ###########################################################################
    // Body Measurement Log DDL
    // ###########################################################################
    // ------- master body measurement log ---------------------------------------
    applyDDL([RDDLUtils masterBodyMeasurementLogDDL]);
    makeRelTable(TBL_MASTER_BODY_MEASUREMENT_LOG);
    // ------- main body measurement log -----------------------------------------
    applyDDL([RDDLUtils mainBodyMeasurementLogDDL]);
    makeRelTable(TBL_MAIN_BODY_MEASUREMENT_LOG);

    // ###########################################################################
    // Chart Cache DDL
    // ###########################################################################
    //applyDDL([RDDLUtils chartDDL]);
    //applyDDL([RDDLUtils chartDataDDL]);

    // ###########################################################################
    // Insert Origination Devices
    // ###########################################################################
    ROriginationDeviceInserter insOriginationDevice = [self makeOrigDeviceInserterWithDb:db errorBlk:errorBlk];
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_WEB),          @"Web",           @"orig-device-web");
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_PEBBLE),       @"Pebble",        @"orig-device-pebble");
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_IPHONE),       @"iPhone",        @"orig-device-iphone");
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_IPAD),         @"iPad",          @"orig-device-ipad");
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_APPLE_WATCH),  @"Apple Watch",   @"orig-device-apple-watch");
    insOriginationDevice(@(ORIGINATION_DEVICE_ID_ANDROID_WEAR), @"Android Watch", @"orig-device-android-watch");

    // ###########################################################################
    // Insert Body Segments
    // ###########################################################################
    void(^insBodySegment)(NSNumber *, NSString *) = ^(NSNumber *id, NSString *name) {
      NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1474546826849 / 1000.0)]; // Thursday, September 22, 2016 8:20:26.849 AM GMT-04:00 DST
      RBodySegment *bodySegment =
      [[RBodySegment alloc] initWithLocalMasterIdentifier:id
                                         globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/bodysegments/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                                mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.bodysegment-v0.0.1+json"]
                                                relations:nil
                                                createdAt:createdAt
                                                deletedAt:nil
                                                updatedAt:createdAt
                                                     name:name];
      [self insertIntoMasterBodySegment:bodySegment db:db error:errorBlk];
    };
    NSNumber *bodySegmentUpperId = @(UPPER_BODY_SEGMENT_ID);
    NSNumber *bodySegmentLowerId = @(LOWER_BODY_SEGMENT_ID);
    insBodySegment(bodySegmentUpperId, @"upper body");
    insBodySegment(bodySegmentLowerId, @"lower body");

    // ###########################################################################
    // Insert Muscle Groups
    // ###########################################################################
    RMuscleGroupInserter insMuscleGroup = [self makeMuscleGroupInserterWithDb:db errorBlk:errorBlk];
    insMuscleGroup(bodySegmentUpperId, @(SHOULDER_MG_ID), @"shoulders", @"delts");
    insMuscleGroup(bodySegmentUpperId, @(BACK_MG_ID),     @"back", nil);
    insMuscleGroup(bodySegmentUpperId, @(CHEST_MG_ID),    @"chest", nil);
    insMuscleGroup(bodySegmentUpperId, @(CORE_MG_ID),      @"core", nil);
    insMuscleGroup(bodySegmentLowerId, @(QUADRICEPS_MG_ID), @"quadriceps", @"quads");
    insMuscleGroup(bodySegmentLowerId, @(HAMSTRINGS_MG_ID), @"hamstrings", @"hams");
    insMuscleGroup(bodySegmentLowerId, @(CALVES_MG_ID),     @"calves", nil);
    insMuscleGroup(bodySegmentUpperId, @(TRICEP_MG_ID),   @"triceps", nil);
    insMuscleGroup(bodySegmentUpperId, @(BICEPS_MG_ID),   @"biceps", nil);
    insMuscleGroup(bodySegmentUpperId, @(FOREARMS_MG_ID), @"forearms", nil);
    insMuscleGroup(bodySegmentLowerId, @(GLUTES_MG_ID),   @"glutes", nil);

    // ###########################################################################
    // Insert Muscles
    // ###########################################################################
    RMuscleInserter insMuscle = [self makeMuscleInserterWithDb:db errorBlk:errorBlk];
    insMuscle(@(SHOULDER_MG_ID),   @(MUSCLE_ID_DELTS_REAR),  @"rear deltoids", @"rear delts");
    insMuscle(@(SHOULDER_MG_ID),   @(MUSCLE_ID_DELTS_FRONT), @"front deltoids", @"front delts");
    insMuscle(@(SHOULDER_MG_ID),   @(MUSCLE_ID_DELTS_SIDE),  @"side deltoids", @"side delts");
    insMuscle(@(BACK_MG_ID),       @(MUSCLE_ID_BACK_UPPER),  @"upper back", nil);
    insMuscle(@(BACK_MG_ID),       @(MUSCLE_ID_BACK_LOWER),  @"lower back", nil);
    insMuscle(@(CHEST_MG_ID),      @(MUSCLE_ID_CHEST_UPPER), @"upper chest", nil);
    insMuscle(@(CHEST_MG_ID),      @(MUSCLE_ID_CHEST_LOWER), @"lower chest", nil);
    insMuscle(@(CORE_MG_ID),        @(MUSCLE_ID_ABS_UPPER),   @"upper abs", nil);
    insMuscle(@(CORE_MG_ID),        @(MUSCLE_ID_ABS_LOWER),   @"lower abs", nil);
    insMuscle(@(CHEST_MG_ID),      @(MUSCLE_ID_SERRATUS),    @"serratus", nil);
    insMuscle(@(QUADRICEPS_MG_ID), @(MUSCLE_ID_QUADS),       @"quadriceps", nil);
    insMuscle(@(HAMSTRINGS_MG_ID), @(MUSCLE_ID_HAMS),        @"hamstrings", nil);
    insMuscle(@(CALVES_MG_ID),     @(MUSCLE_ID_CALFS),      @"calves", nil);
    insMuscle(@(BICEPS_MG_ID),     @(MUSCLE_ID_BICEPS),      @"biceps", nil);
    insMuscle(@(FOREARMS_MG_ID),   @(MUSCLE_ID_FOREARMS),    @"forearms", nil);
    insMuscle(@(SHOULDER_MG_ID),   @(MUSCLE_ID_TRAPS),       @"traps", nil);
    insMuscle(@(GLUTES_MG_ID),     @(MUSCLE_ID_GLUTES),      @"glutes", nil);
    insMuscle(@(TRICEP_MG_ID),     @(MUSCLE_ID_TRICEP_LAT),  @"lateral head", @"lat. head"); // tris
    insMuscle(@(TRICEP_MG_ID),     @(MUSCLE_ID_TRICEP_LONG), @"long head", @"long head"); // tris
    insMuscle(@(TRICEP_MG_ID),     @(MUSCLE_ID_TRICEP_MED),  @"medial head", @"med. head"); // tris

    // ###########################################################################
    // Insert Muscle Aliases
    // ###########################################################################
    void(^insMuscleAlias)(NSNumber *, NSNumber *, NSString *) = ^(NSNumber *muscleId, NSNumber *id, NSString *alias) {
      NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1478751944947 / 1000.0)]; // Wednesday, November 9, 2016 11:25:44.947 PM GMT-05:00
      RMuscleAlias *muscleAlias =
      [[RMuscleAlias alloc] initWithLocalMasterIdentifier:id
                                         globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/musclealiases/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                                mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.musclealias-v0.0.1+json"]
                                                relations:nil
                                                createdAt:createdAt
                                                deletedAt:nil
                                                updatedAt:createdAt
                                                 muscleId:muscleId
                                                    alias:alias];
      [self insertIntoMasterMuscleAlias:muscleAlias db:db error:errorBlk];
    };
    insMuscleAlias(@(MUSCLE_ID_DELTS_REAR),  @(3),  @"rear delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_REAR),  @(4),  @"posterior deltoids");
    insMuscleAlias(@(MUSCLE_ID_DELTS_FRONT), @(5),  @"front delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_FRONT), @(6),  @"anterior delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_SIDE),  @(7),  @"side delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_SIDE),  @(8),  @"middle delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_SIDE),  @(9),  @"outer delts");
    insMuscleAlias(@(MUSCLE_ID_DELTS_SIDE),  @(10), @"lateral deltoids");
    insMuscleAlias(@(MUSCLE_ID_BACK_UPPER),  @(13), @"upper lats");
    insMuscleAlias(@(MUSCLE_ID_BACK_LOWER),  @(14), @"lower lats");
    insMuscleAlias(@(MUSCLE_ID_CHEST_UPPER), @(17), @"upper pecs");
    insMuscleAlias(@(MUSCLE_ID_CHEST_LOWER), @(18), @"lower pecs");
    insMuscleAlias(@(MUSCLE_ID_ABS_UPPER),   @(20), @"upper abdominals");
    insMuscleAlias(@(MUSCLE_ID_ABS_LOWER),   @(21), @"lower abdominals");
    insMuscleAlias(@(MUSCLE_ID_QUADS),       @(22), @"quads");
    insMuscleAlias(@(MUSCLE_ID_HAMS),        @(23), @"hams");
    insMuscleAlias(@(MUSCLE_ID_TRAPS),       @(24), @"trapezius");
    insMuscleAlias(@(MUSCLE_ID_GLUTES),      @(25), @"butt");
    insMuscleAlias(@(MUSCLE_ID_GLUTES),      @(26), @"buttocks");
    insMuscleAlias(@(MUSCLE_ID_GLUTES),      @(27), @"gluteus maximus");

    // ###########################################################################
    // Insert Movement Variants
    // ###########################################################################
    void(^insMovementVariant)(NSNumber *, NSString *, NSString *, NSString *, NSNumber *) =
    ^(NSNumber *id, NSString *name, NSString *abbrevName, NSString *description, NSNumber *sortOrder) {
      NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1478751944947 / 1000.0)]; // Wednesday, November 9, 2016 11:25:44.947 PM GMT-05:00
      RMovementVariant *movementVariant =
      [[RMovementVariant alloc] initWithLocalMasterIdentifier:id
                                             globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/movementvariants/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                                    mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.movementvariant-v0.0.1+json"]
                                                    relations:nil
                                                    createdAt:createdAt
                                                    deletedAt:nil
                                                    updatedAt:createdAt
                                                         name:name
                                                   abbrevName:abbrevName
                                           variantDescription:description
                                                    sortOrder:sortOrder];
      [self insertIntoMasterMovementVariant:movementVariant db:db error:errorBlk];
    };
    insMovementVariant(@(BARBELL_MOVEMENT_VARIANT_ID),       @"barbell",       nil,         nil, @(0));
    insMovementVariant(@(DUMBBELL_MOVEMENT_VARIANT_ID),      @"dumbell",       nil,         nil, @(1));
    insMovementVariant(@(MACHINE_MOVEMENT_VARIANT_ID),       @"machine",       nil,         nil, @(2));
    insMovementVariant(@(SMITH_MACHINE_MOVEMENT_VARIANT_ID), @"smith machine", @"smith. m", nil, @(3));
    insMovementVariant(@(CABLE_MOVEMENT_VARIANT_ID),         @"cable",         nil,         nil, @(4));
    insMovementVariant(@(CURL_BAR_MOVEMENT_VARIANT_ID),      @"curl bar",      nil,         nil, @(5));
    insMovementVariant(@(SLED_MOVEMENT_VARIANT_ID),          @"sled",          nil,         nil, @(6));
    insMovementVariant(@(BODY_MOVEMENT_VARIANT_ID),          @"body",          nil,         @"No equipment or machine is used, just the weight of your body.", @(7));
    insMovementVariant(@(KETTLEBELL_MOVEMENT_VARIANT_ID),    @"kettlebell",    nil,         nil, @(8));

    // ###########################################################################
    // Insert Movements
    // ###########################################################################
    RMovementInserter insMovement = [self makeMovementInserterWithDb:db errorBlk:errorBlk];
    RMovementInserterImp insMovementImp = [self makeMovementInserterImpWithInserter:insMovement db:db errorBlk:errorBlk]; // improved
    insMovement(@(0),
                @"bench press",
                NO,
                nil,
                @(31),
                @(0),
                @[@(8), @(9)],
                @[@(2), @(13), @(20), @(22), @(23), @(24)],
                @[]);
    insMovement(@(1),
                @"incline bench press",
                NO,
                nil,
                @(31),
                @(1),
                @[@(8), @(2)],
                @[@(9), @(13), @(20), @(22), @(23), @(24)],
                @[]);
    insMovement(@(2),
                @"decline bench press",
                NO,
                nil,
                @(31),
                @(2),
                @[@(9)],
                @[@(8), @(2), @(13), @(20), @(22), @(23), @(24)],
                @[]);
    insMovement(@(3),
                @"flys",
                NO,
                nil,
                @(22),
                @(3),
                @[@(8), @(9)],
                @[],
                @[@[@(1), @"chest fly"], @[@(2), @"pectoral fly"], @[@(3), @"pec fly"]]);
    insMovement(@(4),
                @"incline flys",
                NO,
                nil,
                @(22),
                @(4),
                @[@(8)],
                @[],
                @[@[@(4), @"incline chest fly"], @[@(5), @"incline pectoral fly"], @[@(6), @"incline pec fly"]]);
    insMovement(@(5),
                @"decline flys",
                NO,
                nil,
                @(22),
                @(5),
                @[@(9)],
                @[],
                @[@[@(7), @"decline chest fly"], @[@(8), @"decline pectoral fly"], @[@(9), @"decline pec fly"]]);
    insMovement(@(6),
                @"push-up",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"0.64"],
                @(0),
                @(6),
                @[@(8), @(9)],
                @[@(2), @(13), @(20), @(22), @(23), @(24)],
                @[@[@(10), @"press-up"], @[@(11), @"floor dip"]]);
    insMovement(@(7),
                @"one arm push-up",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"0.64"],
                @(0),
                @(7),
                @[@(8), @(9)],
                @[@(2), @(13), @(20), @(22), @(23), @(24)],
                @[]);
    insMovement(@(8),
                @"wide grip dips",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"0.95"],
                @(0),
                @(8),
                @[@(8), @(9)],
                @[@(2), @(22), @(23), @(24)],
                @[@[@(12), @"chest deps"]]); // BUG - fixed in V1
    insMovement(@(9),
                @"pulldowns",
                NO,
                nil,
                @(16),
                @(0),
                @[@(5), @(6)],
                @[@(18)],
                @[@[@(13), @"lat pulldowns"]]);
    insMovement(@(10),
                @"rows",
                NO,
                nil,
                @(20), // variant mask
                @(1),
                @[@(5), @(6)],
                @[@(18)],
                @[]);
    insMovement(@(11),
                @"t-bar rows",
                NO,
                nil,
                @(1), // variant mask
                @(2),
                @[@(5), @(6)],
                @[@(18)],
                @[]);
    insMovement(@(12),
                @"bent-over rows",
                NO,
                nil,
                @(9), // variant mask
                @(3),
                @[@(5), @(6)],
                @[@(18)],
                @[@[@(14), @"barbell rows"]]);
    insMovement(@(13),
                @"one arm bent-over rows",
                NO,
                nil,
                @(2), // variant mask
                @(4),
                @[@(5), @(6)],
                @[@(18)],
                @[]);
    insMovement(@(14),
                @"good-mornings",
                NO,
                nil,
                @(1), // variant mask
                @(5),
                @[@(6)],
                @[@(15), @(21)],
                @[]);
    insMovement(@(15),
                @"shoulder press",
                NO,
                nil,
                @(31), // variant mask
                @(0),
                @[@(2), @(3)],
                @[@(22), @(23), @(24), @(20)],
                @[@[@(15), @"overhead press"], @[@(16), @"press behind the neck"]]);
    insMovement(@(16),
                @"Arnold press",
                NO,
                nil,
                @(2), // variant mask
                @(1),
                @[@(2), @(3)],
                @[@(22), @(23), @(24), @(20)],
                @[]);
    insMovement(@(17),
                @"military press",
                NO,
                nil,
                @(9), // variant mask
                @(2),
                @[@(2), @(3)],
                @[@(22), @(23), @(24), @(20)],
                @[@[@(17), @"front shoulder press"]]);
    insMovement(@(18),
                @"clean and press",
                NO,
                nil,
                @(1), // variant mask
                @(3),
                @[@(2), @(3)],
                @[@(22), @(23), @(24), @(20)],
                @[]);
    insMovement(@(19),
                @"push press",
                NO,
                nil,
                @(1), // variant mask
                @(4),
                @[@(2), @(3)],
                @[@(22), @(23), @(24), @(20)],
                @[]);
    insMovement(@(20),
                @"lateral raises",
                NO,
                nil,
                @(18), // variant mask
                @(5),
                @[@(3)],
                @[@(1)],
                @[]);
    insMovement(@(21),
                @"front raises",
                NO,
                nil,
                @(18), // variant mask
                @(6),
                @[@(2)],
                @[],
                @[]);
    insMovement(@(22),
                @"cross cable laterals",
                NO,
                nil,
                @(16), // variant mask
                @(7),
                @[@(1), @(3)],
                @[],
                @[]);
    insMovement(@(23),
                @"overhead laterals",
                NO,
                nil,
                @(2), // variant mask
                @(8),
                @[@(2)],
                @[@(20)],
                @[]);
    insMovement(@(24),
                @"bent-over laterals",
                NO,
                nil,
                @(18),  // variant mask
                @(9),
                @[@(1)],
                @[],
                @[@[@(18), @"reverse fly"], @[@(19), @"rear delt fly"], @[@(20), @"inverted fly"]]);
    insMovement(@(25),
                @"upright rows",
                NO,
                nil,
                @(9), // variant mask
                @(0),
                @[@(20), @(2)],
                @[],
                @[]);
    insMovement(@(26),
                @"shrugs",
                NO,
                nil,
                @(11), // variant mask
                @(1),
                @[@(20)],
                @[],
                @[]);
    insMovement(@(27),
                @"dips",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"0.95"],
                @(0), // variant mask
                @(0),
                @[@(22), @(23), @(24)],
                @[@(2), @(8), @(9)],
                @[@[@(21), @"shoulder width dips"], @[@(22), @"tricep dips"]]);
    insMovement(@(28),
                @"close-grip bench press",
                NO,
                nil,
                @(9), // variant mask
                @(1),
                @[@(22), @(23), @(24)],
                @[@(8), @(9)],
                @[]);
    insMovement(@(29),
                @"pushdowns",
                NO,
                nil,
                @(16), // variant mask
                @(2),
                @[@(22)],
                @[@(23), @(24)],
                @[@[@(23), @"press-downs"]]);
    insMovement(@(30),
                @"tricep extensions",
                NO,
                nil,
                @(32), // variant mask
                @(3),
                @[@(23)],
                @[@(22), @(24)],
                @[@[@(24), @"skull crushers"], @[@(25), @"french press"], @[@(26), @"french extensions"]]);
    insMovement(@(31),
                @"leg press",
                NO,
                nil,
                @(64), // variant mask
                @(0),
                @[@(14), @(15), @(21)],
                @[@(16)],
                @[]);
    insMovement(@(32),
                @"deadlifts",
                NO,
                nil,
                @(1), // variant mask
                @(1),
                @[@(14), @(15), @(21), @(5), @(6)],
                @[@(19), @(11), @(12)],
                @[]);
    insMovement(@(33),
                @"squats",
                NO,
                nil,
                @(9), // variant mask
                @(2),
                @[@(14)],
                @[],
                @[]);
    insMovement(@(34),
                @"leg extensions",
                NO,
                nil,
                @(4), // variant mask
                @(3),
                @[@(14)],
                @[],
                @[]);
    insMovement(@(35),
                @"wrist curls",
                NO,
                nil,
                @(51), // variant mask
                @(0),
                @[@(19)],
                @[],
                @[]);
    insMovement(@(36),
                @"calve raises",
                NO,
                nil, // BUG - fixed in V2
                @(132), // variant mask
                @(55),
                @[@(16)],
                @[],
                @[]);
    insMovement(@(37),
                @"curls",
                NO,
                nil,
                @(55), // variant mask
                @(0),
                @[@(18)],
                @[],
                @[]);
    insMovement(@(38),
                @"sit ups",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"0.50"],
                @(0), // variant mask
                @(0),
                @[@(11), @(12)],
                @[],
                @[]);
    insMovement(@(39),
                @"pull ups", // BUG - fixed in V2 (should be 'pull-ups')
                YES,
                [NSDecimalNumber decimalNumberWithString:@"1.0"],
                @(0), // variant mask
                @(6),
                @[@(5)],
                @[@(18)],
                @[@[@(27), @"chins"]]);
    insMovement(@(40),
                @"wide grip pull-ups",
                YES,
                [NSDecimalNumber decimalNumberWithString:@"1.0"],
                @(0), // variant mask
                @(7),
                @[@(5)],
                @[],
                @[@[@(28), @"wide grip chins"]]);

    /**
     Need to make sure that the order of these insMovementImp statements is the
     same order as they appear in ref_data.clj on the server.
     */
    NSInteger movementId = 41;
    insMovementImp(@(movementId++), // id
                   @"ab roller", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.50"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[@(MUSCLE_ID_BACK_UPPER), // secondary muscles
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"crunches", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.20"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"bicycle crunches", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.20"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id  (BUG (big fuck up) - fixed in V1)
                   @"crunches", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.20"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"leg raises", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.40"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"Russian twists", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.30"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"pelvic lifts", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.20"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER),
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_GLUTES)],
                   @[], // secondary muscles
                   @[@[@(29), @"pelvic tilts"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"cable crunches", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"jackknifes", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.40"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"knee raises", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.40"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[@[@(30), @"hip raises"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"V-ups", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.75"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"woodchoppers", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_ABS_UPPER), // primary muscles
                     @(MUSCLE_ID_ABS_LOWER)],
                   @[], // secondary muscles
                   @[@[@(31), @"standing cable wood chop"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"dirty dog", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.20"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_GLUTES)], // primary muscles
                   @[], // secondary muscles
                   @[@[@(32), @"hip side lifts"], @[@(33), @"fire hydrant exercise"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hip thrust", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_GLUTES)], // primary muscles
                   @[@(MUSCLE_ID_QUADS)], // secondary muscles
                   @[@[@(34), @"bridge"], @[@(35), @"weighted hip extension"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"kettlebell swing", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(KETTLEBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_ABS_UPPER),
                     @(MUSCLE_ID_ABS_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_DELTS_REAR)], // primary muscles
                   @[@(MUSCLE_ID_QUADS),
                     @(MUSCLE_ID_CHEST_UPPER),
                     @(MUSCLE_ID_CHEST_LOWER),
                     @(MUSCLE_ID_FOREARMS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"lunges", // canonical name
                   NO, // is body lift
                   nil, // % of body weight (BUG - fixed in V2)
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(BODY_MOVEMENT_VARIANT_ID),
                     @(DUMBBELL_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_GLUTES), // primary muscles
                     @(MUSCLE_ID_QUADS)],
                   @[@(MUSCLE_ID_HAMS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"box squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(SMITH_MACHINE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"front squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(SMITH_MACHINE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hack squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(SLED_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"split squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[], // secondary muscles
                   @[@[@(36), @"bulgarian split squats"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"overhead squats", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"press unders", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"clean", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER), // secondary muscles
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"clean and jerk", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_TRICEP_LAT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_ABS_UPPER),
                     @(MUSCLE_ID_ABS_LOWER),
                     @(MUSCLE_ID_FOREARMS),
                     @(MUSCLE_ID_BACK_UPPER),
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"split jerk", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_TRICEP_LAT), // secondary muscles
                     @(MUSCLE_ID_TRICEP_MED),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_ABS_UPPER),
                     @(MUSCLE_ID_ABS_LOWER),
                     @(MUSCLE_ID_FOREARMS),
                     @(MUSCLE_ID_BACK_UPPER),
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hang clean", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER), // secondary muscles
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id  // A couple BUGs in this one - fixed in V2
                   @"jump squat", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_QUADS)], // primary muscles
                   @[@(MUSCLE_ID_CALFS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"leg curl", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS)], // primary muscles
                   @[], // secondary muscles
                   @[@[@(37), @"hamstring curl"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hang snatch", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER), // secondary muscles (BUG; I'm missing quads from this list - fixed in V2)
                     @(MUSCLE_ID_BACK_LOWER),
                     @(MUSCLE_ID_DELTS_FRONT),
                     @(MUSCLE_ID_DELTS_REAR),
                     @(MUSCLE_ID_DELTS_SIDE),
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_TRAPS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"stiff legged deadlift", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS), // primary muscles
                     @(MUSCLE_ID_GLUTES)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"Romanian deadlift", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS), // primary muscles
                     @(MUSCLE_ID_GLUTES)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"sumo deadlift", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_HAMS)], // primary muscles
                   @[@(MUSCLE_ID_GLUTES), // secondary muscles
                     @(MUSCLE_ID_QUADS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"back extension", // canonical name
                   NO, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.50"], // % of body weight
                   @[@(MACHINE_MOVEMENT_VARIANT_ID), // variant masks
                     @(BODY_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_BACK_LOWER)], // primary muscles
                   @[@(MUSCLE_ID_BACK_UPPER)], // secondary muscles
                   @[@[@(38), @"hyperextension"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"chin-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"1.00"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BICEPS)],
                   @[@(MUSCLE_ID_BACK_LOWER)], // secondary muscles
                   @[@[@(39), @"chin"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"muscle-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"1.00"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BICEPS),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_MED)],
                   @[@(MUSCLE_ID_BACK_LOWER)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"inverted up", // canonical name (BUG - typo!  Fixed in V2)
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.80"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_TRAPS)],
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[@[@(40), @"supine row"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"jump shrug", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_QUADS),
                     @(MUSCLE_ID_TRAPS)],
                   @[@(MUSCLE_ID_BACK_LOWER), // secondary muscles
                     @(MUSCLE_ID_CALFS),
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_HAMS)],
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"kipping pull-ups", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"1.00"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BACK_LOWER)],
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[@[@(41), @"pull-up with kip"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"Pendlay rows", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BACK_UPPER), // primary muscles
                     @(MUSCLE_ID_BACK_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"hammer curls", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_FOREARMS)], // primary muscles
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"reverse barbell curls", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_FOREARMS)], // primary muscles
                   @[@(MUSCLE_ID_BICEPS)], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"concentration curls", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_BICEPS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"preacher curls", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID), // variant masks
                     @(CURL_BAR_MOVEMENT_VARIANT_ID),
                     @(BARBELL_MOVEMENT_VARIANT_ID),
                     @(CABLE_MOVEMENT_VARIANT_ID),
                     @(MACHINE_MOVEMENT_VARIANT_ID)],
                   @[@(MUSCLE_ID_BICEPS)], // primary muscles
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"around the worlds", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(DUMBBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_CHEST_UPPER), // primary muscles
                     @(MUSCLE_ID_CHEST_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"cable crossovers", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_CHEST_UPPER), // primary muscles
                     @(MUSCLE_ID_CHEST_LOWER)],
                   @[], // secondary muscles
                   @[]); // aliases
    insMovementImp(@(movementId++), // id
                   @"kneeling push-up", // canonical name
                   YES, // is body lift
                   [NSDecimalNumber decimalNumberWithString:@"0.40"], // % of body weight
                   @[], // variant masks
                   @[@(MUSCLE_ID_CHEST_UPPER), // primary muscles
                     @(MUSCLE_ID_CHEST_LOWER)],
                   @[@(MUSCLE_ID_DELTS_FRONT), // secondary muscles
                     @(MUSCLE_ID_SERRATUS),
                     @(MUSCLE_ID_TRAPS),
                     @(MUSCLE_ID_TRICEP_LAT),
                     @(MUSCLE_ID_TRICEP_LONG),
                     @(MUSCLE_ID_TRICEP_MED)],
                   @[@[@(42), @"kneeling press-up"], @[@(43), @"kneeling floor dip"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"face pull", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(CABLE_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_DELTS_REAR)], // primary muscles
                   @[@(MUSCLE_ID_DELTS_SIDE), // secondary muscles
                     @(MUSCLE_ID_TRAPS)],
                   @[@[@(44), @"rear delt row"]]); // aliases
    insMovementImp(@(movementId++), // id
                   @"high pull", // canonical name
                   NO, // is body lift
                   nil, // % of body weight
                   @[@(BARBELL_MOVEMENT_VARIANT_ID)], // variant masks
                   @[@(MUSCLE_ID_DELTS_REAR), // primary muscles
                     @(MUSCLE_ID_TRAPS)],
                   @[@(MUSCLE_ID_HAMS), // secondary muscles
                     @(MUSCLE_ID_GLUTES),
                     @(MUSCLE_ID_BACK_LOWER)],
                   @[]); // aliases
  }];
  return NO;
}

#pragma mark - Helpers

- (RMovementVariantMaskUpdater)makeMovementVariantMaskUpdaterWithDb:(FMDatabase *)db
                                                           errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSInteger movementId, NSArray *variants) {
    NSInteger variantsMask = 0;
    for (NSNumber *variantId in variants) {
      variantsMask |= variantId.integerValue;
    }
    [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = ? where %@ = ?",
                         TBL_MASTER_MOVEMENT,
                         COL_MOVEMENT_VARIANT_MASK,
                         COL_LOCAL_ID]
              argsArray:@[@(variantsMask), @(movementId)]
                     db:db
                  error:errorBlk];
  };
}

- (RMovementAliasInserter)makeMovementAliasInserterWithCreatedAt:(NSDate *)createdAt
                                                              db:(FMDatabase *)db
                                                        errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSInteger movementId, NSInteger aliasId, NSString *alias) {
    RMovementAlias *movementAlias =
    [[RMovementAlias alloc] initWithLocalMasterIdentifier:@(aliasId)
                                         globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/movementaliases/%ld", GLOBAL_IDENTIFIER_PREFIX, (long)aliasId]
                                                mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.movementalias-v0.0.1+json"]
                                                relations:nil
                                                createdAt:createdAt
                                                deletedAt:nil
                                                updatedAt:createdAt
                                               movementId:@(movementId)
                                                    alias:alias];
    [self insertIntoMasterMovementAlias:movementAlias db:db error:errorBlk];
  };
}

- (RSecondaryMovementInserter)makeSecondaryMovementInserterWithDb:(FMDatabase *)db
                                                         errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSInteger movementId, NSInteger muscleId) {
    [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ (%@, %@) values (?, ?)",
                         TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                         COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID,
                         COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID]
              argsArray:@[@(movementId), @(muscleId)]
                     db:db
                  error:errorBlk];
  };
}

- (RMovementInserterImp)makeMovementInserterImpWithInserter:(RMovementInserter)insMovement
                                                         db:(FMDatabase *)db
                                                   errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSNumber *id,
           NSString *canonialName,
           BOOL isBodyLift,
           NSDecimalNumber *percentageOfBodyWeight,
           NSArray *variants,
           NSArray *primaryMuscleIds,
           NSArray *secondaryMuscleIds,
           NSArray *aliases) {
    NSInteger variantsMask = 0;
    for (NSNumber *variantId in variants) {
      variantsMask |= variantId.integerValue;
    }
    insMovement(id,
                canonialName,
                isBodyLift,
                percentageOfBodyWeight,
                @(variantsMask),
                @(0),
                primaryMuscleIds,
                secondaryMuscleIds,
                aliases);
  };
}

- (RMovementInserter)makeMovementInserterWithDb:(FMDatabase *)db errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSNumber *id,
           NSString *canonialName,
           BOOL isBodyLift,
           NSDecimalNumber *percentageOfBodyWeight,
           NSNumber *variantMask,
           NSNumber *sortOrder,
           NSArray *primaryMuscleIds,
           NSArray *secondaryMuscleIds,
           NSArray *aliases) {
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1478751944947 / 1000.0)]; // Wednesday, November 9, 2016 11:25:44.947 PM GMT-05:00
    RMovement *movement =
    [[RMovement alloc] initWithLocalMasterIdentifier:id
                                    globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/movements/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                           mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.movement-v0.0.1+json"]
                                           relations:nil
                                           createdAt:createdAt
                                           deletedAt:nil
                                           updatedAt:createdAt
                                       canonicalName:canonialName
                                          isBodyLift:isBodyLift
                              percentageOfBodyWeight:percentageOfBodyWeight
                                         variantMask:variantMask
                                           sortOrder:sortOrder
                                    primaryMuscleIds:primaryMuscleIds
                                  secondaryMuscleIds:secondaryMuscleIds];
    [self insertIntoMasterMovement:movement db:db error:errorBlk];
    for (NSInteger i = 0; i < aliases.count; i++) {
      NSArray *alias = aliases[i];
      NSNumber *aliasId = alias[0];
      NSString *aliasStr = alias[1];
      RMovementAlias *movementAlias =
      [[RMovementAlias alloc] initWithLocalMasterIdentifier:aliasId
                                           globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/movementaliases/%@", GLOBAL_IDENTIFIER_PREFIX, aliasId]
                                                  mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.movementalias-v0.0.1+json"]
                                                  relations:nil
                                                  createdAt:createdAt
                                                  deletedAt:nil
                                                  updatedAt:createdAt
                                                 movementId:id
                                                      alias:aliasStr];
      [self insertIntoMasterMovementAlias:movementAlias db:db error:errorBlk];
    }
  };
}

- (ROriginationDeviceInserter)makeOrigDeviceInserterWithDb:(FMDatabase *)db errorBlk:(PELMDaoErrorBlk)errorBlk {
  return ^(NSNumber *id, NSString *name, NSString *iconImageName) {
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1474546826849 / 1000.0)]; // Thursday, September 22, 2016 8:20:26.849 AM GMT-04:00 DST
    ROriginationDevice *originationDevice =
    [[ROriginationDevice alloc] initWithLocalMasterIdentifier:id
                                             globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/originationdevices/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                                    mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.originationdevice-v0.0.1+json"]
                                                    relations:nil
                                                    createdAt:createdAt
                                                    deletedAt:nil
                                                    updatedAt:createdAt
                                                         name:name
                                                iconImageName:iconImageName
                                                hasLocalImage:YES];
    [self insertIntoMasterOriginationDevice:originationDevice db:db error:errorBlk];
  };
}

- (RMuscleGroupInserter)makeMuscleGroupInserterWithDb:(FMDatabase *)db errorBlk:(PELMDaoErrorBlk)errorBlk {
    return ^(NSNumber *bodySegmentId, NSNumber *id, NSString *name, NSString *abbrevName) {
        NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1474546826849 / 1000.0)]; // Thursday, September 22, 2016 8:20:26.849 AM GMT-04:00 DST
        RMuscleGroup *muscleGroup =
        [[RMuscleGroup alloc] initWithLocalMasterIdentifier:id
                                           globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/musclegroups/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                                  mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.musclegroup-v0.0.1+json"]
                                                  relations:nil
                                                  createdAt:createdAt
                                                  deletedAt:nil
                                                  updatedAt:createdAt
                                              bodySegmentId:bodySegmentId
                                                       name:name
                                                 abbrevName:abbrevName];
        [self insertIntoMasterMuscleGroup:muscleGroup db:db error:errorBlk];
    };
}

- (RMuscleInserter)makeMuscleInserterWithDb:(FMDatabase *)db errorBlk:(PELMDaoErrorBlk)errorBlk {
    return ^(NSNumber *mgId, NSNumber *id, NSString *name, NSString *abbrevName) {
        NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:(1474546826849 / 1000.0)]; // Thursday, September 22, 2016 8:20:26.849 AM GMT-04:00 DST
        RMuscle *muscle =
        [[RMuscle alloc] initWithLocalMasterIdentifier:id
                                      globalIdentifier:[NSString stringWithFormat:@"%@/riker/d/muscles/%@", GLOBAL_IDENTIFIER_PREFIX, id]
                                             mediaType:[HCMediaType MediaTypeFromString:@"application/vnd.riker.muscle-v0.0.1+json"]
                                             relations:nil
                                             createdAt:createdAt
                                             deletedAt:nil
                                             updatedAt:createdAt
                                         muscleGroupId:mgId
                                         canonicalName:name
                                   abbrevCanonicalName:abbrevName];
        [self insertIntoMasterMuscle:muscle db:db error:errorBlk];
    };
}

- (void)clearChartCacheWithDb:(FMDatabase *)db errorBlk:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@", TBL_CHART_TIME_SERIES_DATA_POINT] db:db error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@", TBL_CHART_TIME_SERIES] db:db error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@", TBL_CHART_PIE_SLICE] db:db error:errorBlk];
  [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@", TBL_CHART] db:db error:errorBlk];
}

#pragma mark - Export

- (void)exportWithPathToSetsFile:(NSString *)setsFile
         bodyMeasurementLogsFile:(NSString *)bodyMeasurementLogsFile
                            user:(PELMUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  [self exportWithPathToSetsFile:setsFile user:user error:errorBlk];
  [self exportWithPathToBodyMeasurementLogsFile:bodyMeasurementLogsFile user:user error:errorBlk];
}

- (void)exportWithPathToSetsFile:(NSString *)setsFile
                            user:(PELMUser *)user
                           error:(PELMDaoErrorBlk)errorBlk {
  DDLogDebug(@"sets export file: [%@]", setsFile);
  NSString *(^emptyIfNil)(id) = ^NSString *(id val) {
    if ([PEUtils isNil:val]) {
      return @"";
    }
    return val;
  };
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSDictionary *originationDevices = [RUtils dictFromMasterEntitiesArray:[self originationDevicesWithDb:db error:errorBlk]];
    NSDictionary *movements = [RUtils dictFromMasterEntitiesArray:[self movementsWithNilMuscleIdsDb:db error:errorBlk]];
    NSDictionary *movementVariants = [RUtils dictFromMasterEntitiesArray:[self movementVariantsWithDb:db error:errorBlk]];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.maximumFractionDigits = 0;
    // Export the sets
    NSArray *records = [self descendingSetsForUser:user db:db error:errorBlk];
    CHCSVWriter *csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:setsFile];
    [csvWriter writeField:@"Logged"];
    [csvWriter writeField:@"Logged Unix Time"];
    [csvWriter writeField:@"Movement"];
    [csvWriter writeField:@"Movement ID"];
    [csvWriter writeField:@"Variant"];
    [csvWriter writeField:@"Variant ID"];
    [csvWriter writeField:@"Weight"];
    [csvWriter writeField:@"Weight UOM"];
    [csvWriter writeField:@"Weight UOM ID"];
    [csvWriter writeField:@"To Failure?"];
    [csvWriter writeField:@"Negatives?"];
    [csvWriter writeField:@"Ignore Time Component?"];
    [csvWriter writeField:@"Reps"];
    [csvWriter writeField:@"Origination Device"];
    [csvWriter writeField:@"Origination Device ID"];
    [csvWriter finishLine];
    for (RSet *set in records) {
      [csvWriter writeField:[PEUtils stringFromDate:set.loggedAt withPattern:DATE_PATTERN]];
      NSDecimalNumber *loggedAtTime = [set.loggedAt toUnixTime];
      NSString *loggedAtTimeStr = [numberFormatter stringFromNumber:loggedAtTime];
      [csvWriter writeField:[NSString stringWithFormat:@"'%@'", loggedAtTimeStr]];
      if (set.movementId) {
        RMovement *movement = movements[set.movementId];
        [csvWriter writeField:movement.canonicalName];
      } else {
        [csvWriter writeField:@""];
      }
      [csvWriter writeField:emptyIfNil(set.movementId)];
      if (set.movementVariantId) {
        RMovementVariant *variant = movementVariants[set.movementVariantId];
        [csvWriter writeField:variant.name];
      } else {
        [csvWriter writeField:@""];
      }
      [csvWriter writeField:emptyIfNil(set.movementVariantId)];
      [csvWriter writeField:emptyIfNil(set.weight)];
      [csvWriter writeField:emptyIfNil(set.weightUom ? [RUtils weightUnitNameForUomId:set.weightUom] : nil)];
      [csvWriter writeField:emptyIfNil(set.weightUom)];
      [csvWriter writeField:[PEUtils trueFalseFromBool:set.toFailure]];
      [csvWriter writeField:[PEUtils trueFalseFromBool:set.negatives]];
      [csvWriter writeField:[PEUtils trueFalseFromBool:set.ignoreTime]];
      [csvWriter writeField:emptyIfNil(set.numReps)];
      ROriginationDevice *originationDevice = originationDevices[set.originationDeviceId];
      [csvWriter writeField:originationDevice.name];
      [csvWriter writeField:set.originationDeviceId];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];
    [RUtils logEvent:@"sets_exported" params:@{@"num_exported" : @(records.count)}];
  }];
}

- (void)exportWithPathToBodyMeasurementLogsFile:(NSString *)bodyMeasurementLogsFile
                                           user:(PELMUser *)user
                                          error:(PELMDaoErrorBlk)errorBlk {
  DDLogDebug(@"bml export file: [%@]", bodyMeasurementLogsFile);
  NSString *(^emptyIfNil)(id) = ^NSString *(id val) {
    if ([PEUtils isNil:val]) {
      return @"";
    }
    return val;
  };
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSDictionary *originationDevices = [RUtils dictFromMasterEntitiesArray:[self originationDevicesWithDb:db error:errorBlk]];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.maximumFractionDigits = 0;
    // Export the body measurement logs
    NSArray *records = [self descendingBmlsForUser:user db:db error:errorBlk];
    CHCSVWriter *csvWriter = [[CHCSVWriter alloc] initForWritingToCSVFile:bodyMeasurementLogsFile];
    [csvWriter writeField:@"Logged"];
    [csvWriter writeField:@"Logged Unix Time"];
    [csvWriter writeField:@"Body Weight"];
    [csvWriter writeField:@"Body Weight UOM"];
    [csvWriter writeField:@"Body Weight UOM ID"];
    [csvWriter writeField:@"Calf Size"];
    [csvWriter writeField:@"Chest Size"];
    [csvWriter writeField:@"Arm Size"];
    [csvWriter writeField:@"Neck Size"];
    [csvWriter writeField:@"Waist Size"];
    [csvWriter writeField:@"Thigh Size"];
    [csvWriter writeField:@"Forearm Size"];
    [csvWriter writeField:@"Size UOM"];
    [csvWriter writeField:@"Size UOM ID"];
    [csvWriter writeField:@"Origination Device"];
    [csvWriter writeField:@"Origination Device ID"];
    [csvWriter finishLine];
    for (RBodyMeasurementLog *bml in records) {
      [csvWriter writeField:[PEUtils stringFromDate:bml.loggedAt withPattern:DATE_PATTERN]];
      NSDecimalNumber *loggedAtTime = [bml.loggedAt toUnixTime];
      NSString *loggedAtTimeStr = [numberFormatter stringFromNumber:loggedAtTime];
      [csvWriter writeField:[NSString stringWithFormat:@"'%@'", loggedAtTimeStr]];
      [csvWriter writeField:emptyIfNil(bml.bodyWeight)];
      [csvWriter writeField:emptyIfNil(bml.bodyWeightUom ? [RUtils weightUnitNameForUomId:bml.bodyWeightUom] : nil)];
      [csvWriter writeField:emptyIfNil(bml.bodyWeightUom)];
      [csvWriter writeField:emptyIfNil(bml.calfSize)];
      [csvWriter writeField:emptyIfNil(bml.chestSize)];
      [csvWriter writeField:emptyIfNil(bml.armSize)];
      [csvWriter writeField:emptyIfNil(bml.neckSize)];
      [csvWriter writeField:emptyIfNil(bml.waistSize)];
      [csvWriter writeField:emptyIfNil(bml.thighSize)];
      [csvWriter writeField:emptyIfNil(bml.forearmSize)];
      [csvWriter writeField:emptyIfNil(bml.sizeUom ? [RUtils sizeUnitNameForUomId:bml.sizeUom] : nil)];
      [csvWriter writeField:emptyIfNil(bml.sizeUom)];
      ROriginationDevice *originationDevice = originationDevices[bml.originationDeviceId];
      [csvWriter writeField:originationDevice.name];
      [csvWriter writeField:bml.originationDeviceId];
      [csvWriter finishLine];
    }
    [csvWriter closeStream];
    [RUtils logEvent:@"bmls_exported" params:@{@"num_exported" : @(records.count)}];
  }];
}

#pragma mark - Transform to Local Only User

- (void)checkLocalEntityGlobalIdsForUser:(PELMUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    void (^nullOutGlobalId)(NSString *, NSString *) = ^(NSString *tbl, NSString *globalId) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = null where %@ = ?",
                           tbl,
                           COL_GLOBAL_ID,
                           COL_GLOBAL_ID]
                argsArray:@[globalId]
                       db:db
                    error:errorBlk];
    };
    NSArray *bmls = [self descendingBmlsForUser:user db:db error:errorBlk];
    for (RBodyMeasurementLog *bml in bmls) {
      if ([PEUtils isNotNil:bml.globalIdentifier] && ![bml.globalIdentifier hasPrefix:user.globalIdentifier]) {
        nullOutGlobalId(TBL_MASTER_BODY_MEASUREMENT_LOG, bml.globalIdentifier);
      }
    }
    NSArray *sets = [self descendingSetsForUser:user db:db error:errorBlk];
    for (RSet *set in sets) {
      if ([PEUtils isNotNil:set.globalIdentifier] && ![set.globalIdentifier hasPrefix:user.globalIdentifier]) {
        nullOutGlobalId(TBL_MASTER_SET, set.globalIdentifier);
      }
    }
    RUserSettings *userSettings = [self userSettingsForUser:user db:db error:errorBlk];
    if (userSettings) {
      if ([PEUtils isNotNil:userSettings.globalIdentifier] && ![userSettings.globalIdentifier hasPrefix:user.globalIdentifier]) {
        nullOutGlobalId(TBL_MASTER_USER_SETTINGS, userSettings.globalIdentifier);
      }
    }
  }];
}

- (void)transformToLocalOnlyUserWithError:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    // now that all of our data is in their respective 'main' tables, we can
    // blow away the master rows and clear-out the masterMainIds and globalIds
    void (^makeNull)(NSString *, NSString *) = ^(NSString *tbl, NSString *col) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = null", tbl, col] db:db error:errorBlk];
    };
    void (^makeFalse)(NSString *, NSString *) = ^(NSString *tbl, NSString *col) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"update %@ set %@ = 0", tbl, col] db:db error:errorBlk];
    };
    // notice here we exclude the global ID...this way, if the user does make edits
    // to local records, and then decides to log back in again, and they sync
    // their edits, updates will be updates because the global IDs will have been
    // preserved (but we only do this for sets and bmls...user settings global ID should get null'd out)
    NSArray *colsToMakeNull = @[COL_SYNC_HTTP_RESP_CODE,
                                COL_SYNC_ERR_MASK,
                                COL_SYNC_RETRY_AT];
    NSArray *colsToMakeFalse = @[COL_SYNC_IN_PROGRESS,
                                 COL_SYNCED];
    for (NSString *col in colsToMakeNull) {
      makeNull(TBL_MASTER_USER, col);
      makeNull(TBL_MASTER_SET, col);
      makeNull(TBL_MASTER_BODY_MEASUREMENT_LOG, col);
      makeNull(TBL_MASTER_USER_SETTINGS, col);
    }
    
    // user columns
    makeNull(TBL_MASTER_USER, COL_GLOBAL_ID);
    makeNull(TBL_MASTER_USER, COL_USR_NAME);
    makeNull(TBL_MASTER_USER, COL_USR_EMAIL);
    makeNull(TBL_MASTER_USER, COL_USR_PASSWORD_HASH);
    makeNull(TBL_MASTER_USER, COL_USR_VERIFIED_AT);
    makeNull(TBL_MASTER_USER, COL_USR_LAST_CHARGE_ID);
    makeNull(TBL_MASTER_USER, COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT);
    makeNull(TBL_MASTER_USER, COL_USR_LATEST_STRIPE_TOKEN_ID);
    makeNull(TBL_MASTER_USER, COL_USR_NEXT_INVOICE_AT);
    makeNull(TBL_MASTER_USER, COL_USR_NEXT_INVOICE_AMOUNT);
    makeNull(TBL_MASTER_USER, COL_USR_LAST_INVOICE_AT);
    makeNull(TBL_MASTER_USER, COL_USR_LAST_INVOICE_AMOUNT);
    makeNull(TBL_MASTER_USER, COL_USR_CURRENT_CARD_LAST4);
    makeNull(TBL_MASTER_USER, COL_USR_CURRENT_CARD_BRAND);
    makeNull(TBL_MASTER_USER, COL_USR_CURRENT_CARD_EXP_MONTH);
    makeNull(TBL_MASTER_USER, COL_USR_CURRENT_CARD_EXP_YEAR);
    makeNull(TBL_MASTER_USER, COL_USR_TRIAL_ENDS_AT);
    makeNull(TBL_MASTER_USER, COL_USR_STRIPE_CUSTOMER_ID);
    makeNull(TBL_MASTER_USER, COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT);
    makeNull(TBL_MASTER_USER, COL_USR_NEW_MOVEMENTS_ADDED_AT);
    makeNull(TBL_MASTER_USER, COL_USR_INFORMED_OF_MAINTENANCE_AT);
    makeNull(TBL_MASTER_USER, COL_USR_MAINTENANCE_STARTS_AT);
    makeNull(TBL_MASTER_USER, COL_USR_MAINTENANCE_DURATION);
    makeFalse(TBL_MASTER_USER, COL_USR_IS_PAYMENT_PAST_DUE);
    makeNull(TBL_MASTER_USER, COL_USR_PAID_ENROLLMENT_CANCELLED_AT);
    makeNull(TBL_MASTER_USER, COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT);
    makeNull(TBL_MASTER_USER, COL_USR_VALIDATE_APP_STORE_RECEIPT_AT);

    // user settings columns
    makeNull(TBL_MASTER_USER_SETTINGS, COL_GLOBAL_ID);
    makeNull(TBL_MASTER_USER_SETTINGS, COL_UPDATED_AT);
    makeNull(TBL_MASTER_USER_SETTINGS, COL_CREATED_AT);
    makeNull(TBL_MASTER_USER_SETTINGS, COL_DELETED_DT);
    
    for (NSString *col in colsToMakeFalse) {
      makeFalse(TBL_MASTER_USER, col);
      makeFalse(TBL_MASTER_SET, col);
      makeFalse(TBL_MASTER_BODY_MEASUREMENT_LOG, col);
      makeFalse(TBL_MASTER_USER_SETTINGS, col);
    }
  }];
}

#pragma mark - PELocalDaoImpl Overrides

- (NSArray *)masterEntityTableNames {
  return @[TBL_MASTER_USER_SETTINGS,
           TBL_MASTER_SET,
           TBL_MASTER_BODY_MEASUREMENT_LOG];
}

- (PEUserDbOpBlk)preDeleteUserHookDeleteSettings:(BOOL)deleteSettings {
  return ^(PELMUser *user, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
    if (deleteSettings) {
      [self deleteUserSettings:[self userSettingsForUser:user db:db error:errorBlk] db:db error:errorBlk];
    }
    [self deleteChartConfigsForUser:user db:db error:errorBlk]; // this will also result in the chart cache being deleted
    [self deleteSetsOfUser:user db:db error:errorBlk];
    [self deleteBmlsOfUser:user db:db error:errorBlk];
  };
}

- (PEUserDbOpBlk)postSaveNewUserHookWithUserSettingsMtVersion:(NSString *)mtVersion {
  return ^(PELMUser *user, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
    [self saveNewLocalUserSettings:[RUserSettings userSettingsWithWeightUom:@(DEFAULT_WEIGHT_UNITS)
                                                                    sizeUom:@(DEFAULT_SIZE_UNITS)
                                                         weightIncDecAmount:@(DEFAULT_WEIGHT_INC_DEC_AMOUNT)
                                                                  mediaType:[RKnownMediaTypes userSettingsMediaTypeWithVersion:mtVersion]]
                           forUser:user
                                db:db
                             error:errorBlk];
  };
}

- (NSArray *)entityTableNamesChildToParentOrder {
  return @[TBL_MASTER_USER_SETTINGS, TBL_MASTER_SET, TBL_MASTER_BODY_MEASUREMENT_LOG];
}

- (PEUserDbOpBlk)postDeepSaveUserHookIsAccountCreation:(BOOL)isAccountCreation {
  return ^(PELMUser *user, FMDatabase *db, PELMDaoErrorBlk errorBlk) {
    void (^saveEntities)(NSArray *, void(^)(id)) = ^(NSArray *entities, void(^saveBlk)(id theEntity)) {
      if (entities) {
        for (id entity in entities) {
          saveBlk(entity);
        }
      }
    };
    saveEntities([user bodySegments], ^(RBodySegment *bodySegment) {
      [self saveNewOrExistingMasterBodySegment:bodySegment db:db error:errorBlk];
    });
    saveEntities([user muscleGroups], ^(RMuscleGroup *muscleGroup) {
      [self saveNewOrExistingMasterMuscleGroup:muscleGroup db:db error:errorBlk];
    });
    saveEntities([user muscles], ^(RMuscle *muscle) {
      [self saveNewOrExistingMasterMuscle:muscle db:db error:errorBlk];
    });
    saveEntities([user muscleAliases], ^(RMuscleAlias *muscleAlias) {
      [self saveNewOrExistingMasterMuscleAlias:muscleAlias db:db error:errorBlk];
    });
    saveEntities([user movements], ^(RMovement *movement) {
      [self saveNewOrExistingMasterMovement:movement db:db error:errorBlk];
    });
    saveEntities([user movementAliases], ^(RMovementAlias *movementAlias) {
      [self saveNewOrExistingMasterMovementAlias:movementAlias db:db error:errorBlk];
    });
    saveEntities([user movementVariants], ^(RMovementVariant *movementVariant) {
      [self saveNewOrExistingMasterMovementVariant:movementVariant db:db error:errorBlk];
    });
    saveEntities([user originationDevices], ^(ROriginationDevice *originationDevice) {
      [self saveNewOrExistingMasterOriginationDevice:originationDevice db:db error:errorBlk];
    });
    if (user.userSettings) {
      user.userSettings.synced = YES;
      if (isAccountCreation) {
        // we don't want to overwrite the user's locally-chosen settings data (this
        // check really only makes sense in a sign-up situation)
        RUserSettings *localSettings = [self userSettingsForUser:user db:db error:errorBlk];
        user.userSettings.weightIncDecAmount = localSettings.weightIncDecAmount;
        user.userSettings.weightUom = localSettings.weightUom;
        user.userSettings.sizeUom = localSettings.sizeUom;
      }
      [self saveNewOrExistingMasterUserSettings:user.userSettings forUser:user db:db error:errorBlk];
    }
    saveEntities([user sets], ^(RSet *set) {
      set.synced = YES;
      [self saveNewOrExistingMasterSet:set forUser:user writeUserReadonlyFields:NO db:db error:errorBlk];
    });
    saveEntities([user bodyMeasurementLogs], ^(RBodyMeasurementLog *bml) {
      bml.synced = YES;
      [self saveNewOrExistingMasterBml:bml forUser:user writeUserReadonlyFields:NO db:db error:errorBlk];
    });
  };
}

#pragma mark - Firebase User Property Logging

- (void)logFirebaseUserProperties {
  [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
    PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
    PELMUser *user = [self userWithDb:db error:errorBlk];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.appStoreReceiptDataBase64]] forName:@"is_itunes_subscriber"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.stripeCustomerId]] forName:@"is_stripe_subscriber"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.trialEndsAt]] forName:@"is_trial_account"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[user isTrialPeriodAlmostExpired]] forName:@"is_trial_almost_ended"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:user.isTrialPeriodExpired] forName:@"is_trial_account_ended"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.paidEnrollmentCancelledAt]] forName:@"paid_account_cancelled"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.verifiedAt]] forName:@"verified_email"];
    [FIRAnalytics setUserPropertyString:[PEUtils trueFalseFromBool:[PEUtils isNotNil:user.facebookUserId]] forName:@"is_facebook_user"];
    [FIRAnalytics setUserPropertyString:[NSString stringWithFormat:@"%ld", (long)[self numSetsForUser:user db:db error:errorBlk]] forName:@"num_sets"];
    [FIRAnalytics setUserPropertyString:[NSString stringWithFormat:@"%ld", (long)[self numBmlsForUser:user db:db error:errorBlk]] forName:@"num_bmls"];
    if (user.email) {
      [FIRAnalytics setUserPropertyString:user.email forName:@"email"];
    }
    if (user.globalIdentifier) {
      [FIRAnalytics setUserID:user.globalIdentifier];
    }
    RUserSettings *userSettings = [self userSettingsForUser:user db:db error:errorBlk];
    if (userSettings) {
      if (userSettings.sizeUom) {
        [FIRAnalytics setUserPropertyString:userSettings.sizeUom.description forName:@"size_units"];
      }
      if (userSettings.weightUom) {
        [FIRAnalytics setUserPropertyString:userSettings.weightUom.description forName:@"weight_units"];
      }
    }
  }];
}

#pragma mark - Unsynced and Sync-Needed Counts

- (NSInteger)numUnsyncedSettingsForUser:(PELMUser *)user {
  return [self numUnsyncedEntitiesForUser:user entityTable:TBL_MASTER_USER_SETTINGS];
}

- (NSInteger)numUnsyncedSetsForUser:(PELMUser *)user {
  return [self numUnsyncedEntitiesForUser:user entityTable:TBL_MASTER_SET];
}

- (NSInteger)numUnsyncedBmlsForUser:(PELMUser *)user {
  return [self numUnsyncedEntitiesForUser:user entityTable:TBL_MASTER_BODY_MEASUREMENT_LOG];
}

- (NSInteger)totalNumUnsyncedEntitiesForUser:(PELMUser *)user {
  return [self numUnsyncedSetsForUser:user] +
  [self numUnsyncedBmlsForUser:user] +
  [self numUnsyncedSettingsForUser:user];
}

- (NSInteger)numSyncNeededSettingsForUser:(PELMUser *)user {
  return [self numSyncNeededEntitiesForUser:user
                    importLimitExceededMask:nil
                                entityTable:TBL_MASTER_USER_SETTINGS];
}

- (NSInteger)numSyncNeededSetsForUser:(PELMUser *)user {
  return [self numSyncNeededEntitiesForUser:user
                    importLimitExceededMask:@(RSaveSetImportLimitExceeded)
                                entityTable:TBL_MASTER_SET];
}

- (NSInteger)numSyncNeededBmlsForUser:(PELMUser *)user {
  return [self numSyncNeededEntitiesForUser:user
                    importLimitExceededMask:@(RSaveBmlImportLimitExceeded)
                                entityTable:TBL_MASTER_BODY_MEASUREMENT_LOG];
}

- (NSInteger)totalNumSyncNeededEntitiesForUser:(PELMUser *)user {
  return [self numSyncNeededBmlsForUser:user] +
  [self numSyncNeededSetsForUser:user] +
  [self numSyncNeededSettingsForUser:user];
}

#pragma mark - Changelog Operations

- (NSArray *)changelogProcessorsWithUser:(PELMUser *)user
                               changelog:(PEChangelog *)changelog
                                      db:(FMDatabase *)db
                         processingBlock:(PELMProcessChangelogEntitiesBlk)processingBlk
                                errorBlk:(PELMDaoErrorBlk)errorBlk {
  RChangeLog *rchangelog = (RChangeLog *)changelog;
  return @[^{processingBlk([rchangelog bodySegments],
                           TBL_MASTER_BODY_SEGMENT,
                           nil,
                           ^(RBodySegment *bodySegment) {return [self saveNewOrExistingMasterBodySegment:bodySegment db:db error:errorBlk];},
                           CHANGELOG_DETAIL_BODY_SEGMENT);},
            ^{processingBlk([rchangelog muscleGroups],
                            TBL_MASTER_MUSCLE_GROUP,
                            nil,
                            ^(RMuscleGroup *muscleGroup) {return [self saveNewOrExistingMasterMuscleGroup:muscleGroup db:db error:errorBlk];},
                            CHANGELOG_DETAIL_MUSCLE_GROUP);},
            ^{processingBlk([rchangelog muscles],
                            TBL_MASTER_MUSCLE,
                            nil,
                            ^(RMuscle *muscle) {return [self saveNewOrExistingMasterMuscle:muscle db:db error:errorBlk];},
                            CHANGELOG_DETAIL_MUSCLE);},
            ^{processingBlk([rchangelog muscleAliases],
                            TBL_MASTER_MUSCLE_ALIAS,
                            nil,
                            ^(RMuscleAlias *muscleAlias) {return [self saveNewOrExistingMasterMuscleAlias:muscleAlias db:db error:errorBlk];},
                            CHANGELOG_DETAIL_MUSCLE_ALIAS);},
            ^{processingBlk([rchangelog movements],
                            TBL_MASTER_MOVEMENT,
                            nil,
                            ^(RMovement *movement) {return [self saveNewOrExistingMasterMovement:movement db:db error:errorBlk];},
                            CHANGELOG_DETAIL_MOVEMENT);},
            ^{processingBlk([rchangelog movementVariants],
                            TBL_MASTER_MOVEMENT_VARIANT,
                            nil,
                            ^(RMovementVariant *movementVariant) {return [self saveNewOrExistingMasterMovementVariant:movementVariant db:db error:errorBlk];},
                            CHANGELOG_DETAIL_MOVEMENT_VARIANT);},
            ^{processingBlk([rchangelog originationDevices],
                            TBL_MASTER_ORIGINATION_DEVICE,
                            nil,
                            ^(ROriginationDevice *originationDevice) {return [self saveNewOrExistingMasterOriginationDevice:originationDevice db:db error:errorBlk];},
                            CHANGELOG_DETAIL_ORIGINATION_DEVICE);},
            ^{processingBlk([rchangelog sets],
                            TBL_MASTER_SET,
                            ^(RSet *set) { [self deleteSet:set db:db error:errorBlk]; },
                            ^(RSet *set) { return [self saveNewOrExistingMasterSet:set forUser:user writeUserReadonlyFields:NO db:db error:errorBlk]; },
                            CHANGELOG_DETAIL_SET);},
            ^{processingBlk([rchangelog bodyMeasurementLogs],
                            TBL_MASTER_BODY_MEASUREMENT_LOG,
                            ^(RBodyMeasurementLog *bml) { [self deleteBml:bml db:db error:errorBlk]; },
                            ^(RBodyMeasurementLog *bml) { return [self saveNewOrExistingMasterBml:bml forUser:user writeUserReadonlyFields:NO db:db error:errorBlk]; },
                            CHANGELOG_DETAIL_BML);},
            ];
}

- (NSArray *)saveChangelog:(RChangeLog *)changelog
                   forUser:(PELMUser *)user
           userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numTotalDeletes = 0;
  __block NSInteger numTotalUpdates = 0;
  __block NSInteger numTotalInserts = 0;
  NSMutableDictionary *detailsDict = [NSMutableDictionary dictionary];
  RUserSettings *currentUserSettings = userSettingsBlk(user);
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    PELMProcessChangelogEntitiesBlk processChangelogEntities =
    ^(NSArray *entities, NSString *table, void(^deleteBlk)(id), PELMSaveNewOrExistingCode(^saveNewOrExistingBlk)(id),
      NSString *detailsKey) {
      NSInteger numEntityInserts = 0;
      NSInteger numEntityUpdates = 0;
      NSInteger numEntityDeletes = 0;
      for (PELMMasterSupport *entity in entities) {
        if ([PEUtils isNotNil:entity.deletedAt]) {
          NSNumber *masterLocalId = [PELMUtils masterLocalIdFromEntityTable:table
                                                           globalIdentifier:entity.globalIdentifier
                                                                         db:db
                                                                      error:errorBlk];
          if (![PEUtils isNil:masterLocalId]) {
            [entity setLocalMasterIdentifier:masterLocalId];
            if (deleteBlk) {
              deleteBlk(entity);
              numTotalDeletes++;
              numEntityDeletes++;
            }
          } else {
            // the entity never existed on our device (i.e., it was created and deleted
            // before it could ever be downloaded to this device)
          }
        } else {
          if ([entity isKindOfClass:[PELMMainSupport class]]) {
            ((PELMMainSupport *)entity).synced = YES;
          }
          PELMSaveNewOrExistingCode returnCode = saveNewOrExistingBlk(entity);
          switch (returnCode) {
            case PELMSaveNewOrExistingCodeDidUpdate:
              numTotalUpdates++;
              numEntityUpdates++;
              break;
            case PELMSaveNewOrExistingCodeDidInsert:
              numTotalInserts++;
              numEntityInserts++;
              break;
            case PELMSaveNewOrExistingCodeDidNothing:
              // do nothing
              break;
          }
        }
      }
      detailsDict[detailsKey] = @[@(numEntityDeletes), @(numEntityUpdates), @(numEntityInserts)];
    };
    PELMUser *updatedUser = [changelog user];
    NSInteger userUpdates = 0;
    if ([PEUtils isNotNil:updatedUser]) {
      if ([PEUtils mscompareDate:updatedUser.updatedAt toDate:user.updatedAt] == NSOrderedDescending) {
        updatedUser.synced = YES;
        updatedUser.localMasterIdentifier = user.localMasterIdentifier;
        if ([self saveMasterUser:updatedUser db:db error:errorBlk]) {
          [user overwriteDomainProperties:updatedUser];
          numTotalUpdates++;
          userUpdates++;
        }
      } else {
        // we can safely overwrite the readonly properties so we get the latest
        // maintenance-related info
        [user overwriteReadonlyProperties:updatedUser];
        [self saveMasterUser:updatedUser readOnlyFieldsEntity:updatedUser db:db error:errorBlk];
      }
    }
    detailsDict[CHANGELOG_DETAIL_USER_ACCOUNT] = @[@(0), @(userUpdates), @(0)];
    NSInteger userSettingUpdates = 0;
    RUserSettings *updatedUserSettings = [changelog userSettings];
    if ([PEUtils isNotNil:updatedUserSettings]) {
      if ([PEUtils mscompareDate:updatedUserSettings.updatedAt toDate:currentUserSettings.updatedAt] == NSOrderedDescending) {
        updatedUserSettings.synced = YES;
        if ([self saveNewOrExistingMasterUserSettings:updatedUserSettings forUser:user db:db error:errorBlk]) {
          userSettingUpdates++;
          numTotalUpdates++;
        }
      }
    }
    detailsDict[CHANGELOG_DETAIL_USER_SETTINGS] = @[@(0), @(userSettingUpdates), @(0)];
    NSArray *changelogProcessors = [self changelogProcessorsWithUser:user
                                                           changelog:changelog
                                                                  db:db
                                                     processingBlock:processChangelogEntities
                                                            errorBlk:errorBlk];
    void (^changelogProcessor)(void);
    for (changelogProcessor in changelogProcessors) {
      changelogProcessor();
    }
  }];
  return @[@(numTotalDeletes), @(numTotalUpdates), @(numTotalInserts), detailsDict];
}

#pragma mark - Movements and Settings for Watch

- (NSMutableDictionary *)movementsAndSettingsForWatchWithUser:(PELMUser *)user
                                                 userSettings:(RUserSettings *)userSettings
                                                        error:(PELMDaoErrorBlk)errorBlk {
  NSMutableDictionary *movementsAndSettings = [[NSMutableDictionary alloc] init];
  NSDecimalNumber *nowNum = [[NSDate date] toUnixTime];
  movementsAndSettings[@"loaded-at-unix-time"] = nowNum;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSArray *bodySegments = [self bodySegmentsWithDb:db error:errorBlk];
    NSInteger numBodySegments = bodySegments.count;
    NSMutableArray *minifiedBodySegments = [NSMutableArray arrayWithCapacity:numBodySegments];
    NSMutableDictionary *muscleGroupsByBodySegment = [NSMutableDictionary dictionaryWithCapacity:numBodySegments];
    movementsAndSettings[@"muscle-groups"] = muscleGroupsByBodySegment;
    NSMutableDictionary *movementsByMuscleGroup = [NSMutableDictionary dictionary];
    movementsAndSettings[@"movements"] = movementsByMuscleGroup;
    NSMutableDictionary *variantsByMovement = [NSMutableDictionary dictionary];
    movementsAndSettings[@"movement-variants"] = variantsByMovement;
    movementsAndSettings[@"weight-uom-id"] = userSettings.weightUom;
    movementsAndSettings[@"weight-uom-name"] = [RUtils weightUnitNameForUomId:userSettings.weightUom];
    movementsAndSettings[@"size-uom-id"] = userSettings.sizeUom;
    movementsAndSettings[@"size-uom-name"] = [RUtils sizeUnitNameForUomId:userSettings.sizeUom];
    movementsAndSettings[@"inc-dec-weight-amount"] = userSettings.weightIncDecAmount;
    RBodyMeasurementLog *bml = [self mostRecentBmlWithNonNilWeightForUser:user db:db error:errorBlk];
    if (bml) {
      movementsAndSettings[@"body-weight"] = bml.bodyWeight;
      movementsAndSettings[@"body-weight-uom-name"] = [RUtils weightUnitNameForUomId:bml.bodyWeightUom];
      movementsAndSettings[@"converted-body-weight"] = [RUtils weightValueWithValue:bml.bodyWeight currentWeightUomId:bml.bodyWeightUom targetWeightUomId:userSettings.weightUom];
    }
    for (NSInteger i = 0; i < numBodySegments; i++) {
      RBodySegment *bodySegment = bodySegments[i];
      NSNumber *bodySegmentId = bodySegment.localMasterIdentifier;
      [minifiedBodySegments addObject:@{@"id": bodySegmentId, @"name": bodySegment.name}];
      NSArray *muscleGroups = [self muscleGroupsForBodySegmentId:bodySegmentId db:db error:errorBlk];
      NSInteger numMuscleGroups = muscleGroups.count;
      NSMutableArray *minifiedMuscleGroups = [NSMutableArray arrayWithCapacity:numMuscleGroups];
      for (NSInteger j = 0; j < numMuscleGroups; j++) {
        RMuscleGroup *muscleGroup = muscleGroups[j];
        NSNumber *mgId = muscleGroup.localMasterIdentifier;
        [minifiedMuscleGroups addObject:@{@"id": mgId, @"name": muscleGroup.name}];
        NSArray *movements = [self movementsForMuscleGroupId:mgId db:db error:errorBlk];
        NSInteger numMovements = movements.count;
        NSMutableArray *minifiedMovements = [NSMutableArray arrayWithCapacity:numMovements];
        for (NSInteger m = 0; m < numMovements; m++) {
          RMovement *movement = movements[m];
          NSArray *variants = [self movementVariantsForMovementVariantMask:movement.variantMask db:db error:errorBlk];
          NSInteger numVariants = variants.count;
          NSMutableArray *minifiedVariants = [NSMutableArray arrayWithCapacity:numVariants];
          for (NSInteger v = 0; v < numVariants; v++) {
            RMovementVariant *variant = variants[v];
            [minifiedVariants addObject:@{@"id": variant.localMasterIdentifier, @"name": variant.name}];
          }
          variantsByMovement[movement.localMasterIdentifier.description] = minifiedVariants;
          NSMutableDictionary *minifiedMovement =
          [[NSMutableDictionary alloc] initWithDictionary:@{@"id": movement.localMasterIdentifier,
                                                            @"is-body-lift": @(movement.isBodyLift),
                                                            @"name": movement.canonicalName,
                                                            @"variant-count": @(numVariants)}];
          if (movement.percentageOfBodyWeight) {
            minifiedMovement[@"percentage-of-body-weight"] = movement.percentageOfBodyWeight;
          }
          [minifiedMovements addObject:minifiedMovement];
        }
        movementsByMuscleGroup[mgId.description] = minifiedMovements;
      }
      muscleGroupsByBodySegment[bodySegmentId.description] = minifiedMuscleGroups;
    }
    movementsAndSettings[@"body-segments"] = minifiedBodySegments;
  }];
  return movementsAndSettings;
}

#pragma mark - Body Segments

- (NSArray *)bodySegmentsWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bodySegments;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bodySegments = [self bodySegmentsWithDb:db error:errorBlk];
  }];
  return bodySegments;
}

- (NSArray *)bodySegmentsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *bodySegments = [NSMutableArray array];
  FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC", TBL_MASTER_BODY_SEGMENT, COL_BODYSEG_NAME]
                             argsArray:@[]
                                    db:db
                                 error:errorBlk];
  while ([rs next]) {
    [bodySegments addObject:[self bodySegmentFromResultSet:rs]];
  }
  [rs close];
  return bodySegments;
}

- (RBodySegment *)bodySegmentFromResultSet:(FMResultSet *)rs {
  return [[RBodySegment alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                            globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                   mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                   relations:nil
                                                   createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                   deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                   updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                                        name:[rs stringForColumn:COL_BODYSEG_NAME]];
}

- (void)insertIntoMasterBodySegment:(RBodySegment *)bodySegment
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?)", TBL_MASTER_BODY_SEGMENT,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_BODYSEG_NAME];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([bodySegment localMasterIdentifier]),
                              orNil([bodySegment globalIdentifier]),
                              orNil([[bodySegment mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[bodySegment createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[bodySegment updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[bodySegment deletedAt]]),
                              
                              orNil([bodySegment name])]
                     entity:bodySegment
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterBodySegment {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_BODY_SEGMENT,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_BODYSEG_NAME,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterBodySegment:(RBodySegment *)bodySegment {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([bodySegment globalIdentifier]),
           orNil([[bodySegment mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[bodySegment createdAt]]),
           orNil([PEUtils millisecondsFromDate:[bodySegment updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[bodySegment deletedAt]]),
           orNil([bodySegment name]),
           [bodySegment localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterBodySegment:(RBodySegment *)bodySegment
                                                             db:(FMDatabase *)db
                                                          error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:bodySegment
                                           masterTable:TBL_MASTER_BODY_SEGMENT
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterBodySegment:(RBodySegment *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterBodySegment]
                                   masterUpdateArgsBlk:^NSArray * (RBodySegment *theBodySegment) { return [self updateArgsForMasterBodySegment:theBodySegment]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Muscle Groups

- (NSArray *)muscleGroupsWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *muscleGroups;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    muscleGroups = [self muscleGroupsWithDb:db error:errorBlk];
  }];
  return muscleGroups;
}

- (NSArray *)muscleGroupsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ ASC",
                                       TBL_MASTER_MUSCLE_GROUP,
                                       COL_MUSCLE_GROUP_NAME]
                            argsArray:@[]
                          rsConverter:^(FMResultSet *rs){return [self muscleGroupFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)muscleGroupsForBodySegmentId:(NSNumber *)bodySegmentId
                                    error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *muscleGroups;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    muscleGroups = [self muscleGroupsForBodySegmentId:bodySegmentId db:db error:errorBlk];
  }];
  return muscleGroups;
}

- (NSArray *)muscleGroupsForBodySegmentId:(NSNumber *)bodySegmentId
                                       db:(FMDatabase *)db
                                    error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *muscleGroups = [NSMutableArray array];
  FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ ASC",
                                        TBL_MASTER_MUSCLE_GROUP, COL_MUSCLE_GROUP_BODY_SEGMENT_ID, COL_MUSCLE_GROUP_NAME]
                             argsArray:@[bodySegmentId]
                                    db:db
                                 error:errorBlk];
  while ([rs next]) {
    [muscleGroups addObject:[self muscleGroupFromResultSet:rs]];
  }
  [rs close];
  return muscleGroups;
}

- (NSArray *)muscleGroupsAndMovementsWithError:(PELMDaoErrorBlk)errorBlk {
  NSMutableDictionary *mgsAndMovsDict = [NSMutableDictionary new];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs =
    [PELMUtils doQuery:@"\
     select distinct mov.id as movement_id, mov.sort_order, mov.percentage_of_body_weight, mov.global_identifier, mov.variant_mask, \
     mov.canonical_name, mov.is_body_lift, mg.id as muscle_group_id, mg.name as muscle_group_name \
     from master_movement mov, master_movement_primary_muscle mpm, master_muscle m, master_muscle_group mg \
     where mov.id = mpm.movement_id and mpm.muscle_id = m.id and m.muscle_group_id = mg.id order by mov.canonical_name collate nocase asc"
             argsArray:@[]
                    db:db
                 error:errorBlk];
    while ([rs next]) {
      NSNumber *mgId = [rs objectForColumn:@"muscle_group_id"];
      NSMutableDictionary *mgNameAndMovs = mgsAndMovsDict[mgId];
      NSMutableArray *movements;
      if (mgNameAndMovs == nil) {
        mgNameAndMovs = [NSMutableDictionary new];
        [mgNameAndMovs setObject:[rs objectForColumn:@"muscle_group_name"]
                          forKey:@"mg_name"];
        movements = [NSMutableArray array];
        [mgNameAndMovs setObject:movements forKey:@"movs"];
        [mgsAndMovsDict setObject:mgNameAndMovs forKey:mgId];
      } else {
        movements = mgNameAndMovs[@"movs"];
      }
      RMovement *movement =
      [[RMovement alloc] initWithLocalMasterIdentifier:[rs objectForColumn:@"movement_id"]
                                      globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                             mediaType:nil
                                             relations:nil
                                             createdAt:nil
                                             deletedAt:nil
                                             updatedAt:nil
                                         canonicalName:[rs objectForColumn:@"canonical_name"]
                                            isBodyLift:[PELMUtils boolFromResultSet:rs columnName:COL_MOVEMENT_IS_BODY_LIFT boolIfNull:NO]
                                percentageOfBodyWeight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT]
                                           variantMask:[PELMUtils numberFromResultSet:rs columnName:COL_MOVEMENT_VARIANT_MASK]
                                             sortOrder:[PELMUtils numberFromResultSet:rs columnName:COL_MOVEMENT_SORT_ORDER]
                                      primaryMuscleIds:nil
                                    secondaryMuscleIds:nil];
      [movements addObject:movement];
    }
  }];
  NSArray *mgsAndMovs = [mgsAndMovsDict allValues];
  mgsAndMovs = [mgsAndMovs sortedArrayUsingComparator:^NSComparisonResult(NSDictionary * _Nonnull obj1, NSDictionary * _Nonnull obj2) {
    NSString *obj1MgName = obj1[@"mg_name"];
    NSString *obj2MgName = obj2[@"mg_name"];
    return [obj1MgName compare:obj2MgName];
  }];
  return mgsAndMovs;
}

- (RMuscleGroup *)muscleGroupFromResultSet:(FMResultSet *)rs {
  return [[RMuscleGroup alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                            globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                   mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                   relations:nil
                                                   createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                   deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                   updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                               bodySegmentId:[rs objectForColumn:COL_MUSCLE_GROUP_BODY_SEGMENT_ID]
                                                        name:[rs stringForColumn:COL_MUSCLE_GROUP_NAME]
                                                  abbrevName:[rs stringForColumn:COL_MUSCLE_GROUP_ABBREV_NAME]];
}

- (void)insertIntoMasterMuscleGroup:(RMuscleGroup *)muscleGroup
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_MUSCLE_GROUP,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MUSCLE_GROUP_BODY_SEGMENT_ID,
                    COL_MUSCLE_GROUP_NAME,
                    COL_MUSCLE_GROUP_ABBREV_NAME];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([muscleGroup localMasterIdentifier]),
                              orNil([muscleGroup globalIdentifier]),
                              orNil([[muscleGroup mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[muscleGroup createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscleGroup updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscleGroup deletedAt]]),
                              
                              orNil([muscleGroup bodySegmentId]),
                              orNil([muscleGroup name]),
                              orNil([muscleGroup abbrevName])]
                     entity:muscleGroup
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterMuscleGroup {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MUSCLE_GROUP,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MUSCLE_GROUP_BODY_SEGMENT_ID,
          COL_MUSCLE_GROUP_NAME,
          COL_MUSCLE_GROUP_ABBREV_NAME,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMuscleGroup:(RMuscleGroup *)muscleGroup {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([muscleGroup globalIdentifier]),
           orNil([[muscleGroup mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[muscleGroup createdAt]]),
           orNil([PEUtils millisecondsFromDate:[muscleGroup updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[muscleGroup deletedAt]]),
           orNil([muscleGroup bodySegmentId]),
           orNil([muscleGroup name]),
           orNil([muscleGroup abbrevName]),
           [muscleGroup localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMuscleGroup:(RMuscleGroup *)muscleGroup
                                                             db:(FMDatabase *)db
                                                          error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:muscleGroup
                                           masterTable:TBL_MASTER_MUSCLE_GROUP
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMuscleGroup:(RMuscleGroup *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMuscleGroup]
                                   masterUpdateArgsBlk:^NSArray * (RMuscleGroup *theMuscleGroup) { return [self updateArgsForMasterMuscleGroup:theMuscleGroup]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Muscle

- (NSArray *)musclesWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *muscles;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    muscles = [self musclesWithDb:db error:errorBlk];
  }];
  return muscles;
}

- (NSArray *)musclesWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", TBL_MASTER_MUSCLE]
                            argsArray:@[]
                          rsConverter:^(FMResultSet *rs){return [self muscleFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)primaryMusclesForMovementId:(NSNumber *)movementId
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *muscles;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    muscles = [self primaryMusclesForMovementId:movementId db:db error:errorBlk];
  }];
  return muscles;
}

- (NSArray *)primaryMusclesForMovementId:(NSNumber *)movementId
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ where %@ in (select %@ from %@ where %@ = ?)",
                                       TBL_MASTER_MUSCLE,
                                       COL_LOCAL_ID,
                                       COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID,
                                       TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,
                                       COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID]
                            argsArray:@[movementId]
                          rsConverter:^(FMResultSet *rs){return [self muscleFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)secondaryMusclesForMovementId:(NSNumber *)movementId
                                     error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *muscles;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    muscles = [self secondaryMusclesForMovementId:movementId db:db error:errorBlk];
  }];
  return muscles;
}

- (NSArray *)secondaryMusclesForMovementId:(NSNumber *)movementId
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ where %@ in (select %@ from %@ where %@ = ?)",
                                       TBL_MASTER_MUSCLE,
                                       COL_LOCAL_ID,
                                       COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID,
                                       TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                                       COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID]
                            argsArray:@[movementId]
                          rsConverter:^(FMResultSet *rs){return [self muscleFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)musclesForMuscleGroupId:(NSNumber *)muscleGroupId
                               error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *muscles = [NSMutableArray array];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ ASC",
                                          TBL_MASTER_MUSCLE, COL_MUSCLE_MG_ID, COL_MUSCLE_CANONICAL_NAME]
                               argsArray:@[muscleGroupId]
                                      db:db
                                   error:errorBlk];
    while ([rs next]) {
      [muscles addObject:[self muscleFromResultSet:rs]];
    }
    [rs close];
  }];
  return muscles;
}

- (RMuscle *)muscleFromResultSet:(FMResultSet *)rs {
  return [[RMuscle alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                       globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                              mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                              relations:nil
                                              createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                              deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                              updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                          muscleGroupId:[rs objectForColumn:COL_MUSCLE_MG_ID]
                                          canonicalName:[rs stringForColumn:COL_MUSCLE_CANONICAL_NAME]
                                    abbrevCanonicalName:[rs stringForColumn:COL_MUSCLE_ABBREV_CANONICAL_NAME]];
}

- (void)insertIntoMasterMuscle:(RMuscle *)muscle
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_MUSCLE,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MUSCLE_MG_ID,
                    COL_MUSCLE_CANONICAL_NAME,
                    COL_MUSCLE_ABBREV_CANONICAL_NAME];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([muscle localMasterIdentifier]),
                              orNil([muscle globalIdentifier]),
                              orNil([[muscle mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[muscle createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscle updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscle deletedAt]]),
                              
                              orNil([muscle muscleGroupId]),
                              orNil([muscle canonicalName]),
                              orNil([muscle abbrevCanonicalName])]
                     entity:muscle
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterMuscle {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MUSCLE,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MUSCLE_MG_ID,
          COL_MUSCLE_CANONICAL_NAME,
          COL_MUSCLE_ABBREV_CANONICAL_NAME,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMuscle:(RMuscle *)muscle {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([muscle globalIdentifier]),
           orNil([[muscle mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[muscle createdAt]]),
           orNil([PEUtils millisecondsFromDate:[muscle updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[muscle deletedAt]]),
           orNil([muscle muscleGroupId]),
           orNil([muscle canonicalName]),
           orNil([muscle abbrevCanonicalName]),
           [muscle localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMuscle:(RMuscle *)muscle
                                                        db:(FMDatabase *)db
                                                     error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:muscle
                                           masterTable:TBL_MASTER_MUSCLE
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMuscle:(RMuscle *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMuscle]
                                   masterUpdateArgsBlk:^NSArray * (RMuscle *theMuscle) { return [self updateArgsForMasterMuscle:theMuscle]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Muscle Alias

- (NSArray *)muscleAliasesForMuscleId:(NSNumber *)muscleId
                                error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *muscleAliases = [NSMutableArray array];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ ASC",
                                          TBL_MASTER_MUSCLE_ALIAS,
                                          COL_MUSCLE_ALIAS_MUSCLE_ID,
                                          COL_MUSCLE_ALIAS_ALIAS]
                               argsArray:@[muscleId]
                                      db:db
                                   error:errorBlk];
    while ([rs next]) {
      [muscleAliases addObject:[self muscleAliasFromResultSet:rs]];
    }
    [rs close];
  }];
  return muscleAliases;
}

- (RMuscleAlias *)muscleAliasFromResultSet:(FMResultSet *)rs {
  return [[RMuscleAlias alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                            globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                   mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                   relations:nil
                                                   createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                   deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                   updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                                    muscleId:[rs objectForColumn:COL_MUSCLE_ALIAS_MUSCLE_ID]
                                                       alias:[rs stringForColumn:COL_MUSCLE_ALIAS_ALIAS]];
}

- (void)insertIntoMasterMuscleAlias:(RMuscleAlias *)muscleAlias
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?)", TBL_MASTER_MUSCLE_ALIAS,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MUSCLE_ALIAS_MUSCLE_ID,
                    COL_MUSCLE_ALIAS_ALIAS];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([muscleAlias localMasterIdentifier]),
                              orNil([muscleAlias globalIdentifier]),
                              orNil([[muscleAlias mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[muscleAlias createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscleAlias updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[muscleAlias deletedAt]]),
                              
                              orNil([muscleAlias muscleId]),
                              orNil([muscleAlias alias])]
                     entity:muscleAlias
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterMuscleAlias {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MUSCLE_ALIAS,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MUSCLE_ALIAS_MUSCLE_ID,
          COL_MUSCLE_ALIAS_ALIAS,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMuscleAlias:(RMuscleAlias *)muscleAlias {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([muscleAlias globalIdentifier]),
           orNil([[muscleAlias mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[muscleAlias createdAt]]),
           orNil([PEUtils millisecondsFromDate:[muscleAlias updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[muscleAlias deletedAt]]),
           orNil([muscleAlias muscleId]),
           orNil([muscleAlias alias]),
           [muscleAlias localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMuscleAlias:(RMuscleAlias *)muscleAlias
                                                             db:(FMDatabase *)db
                                                          error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:muscleAlias
                                           masterTable:TBL_MASTER_MUSCLE_ALIAS
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMuscleAlias:(RMuscleAlias *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMuscleAlias]
                                   masterUpdateArgsBlk:^NSArray * (RMuscleAlias *theMuscleAlias) { return [self updateArgsForMasterMuscleAlias:theMuscleAlias]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Movements

- (NSArray *)movementsWithNameOrAliasLike:(NSString *)searchText error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *results = [NSMutableArray array];
  NSMutableDictionary *movements = [NSMutableDictionary dictionary];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSString *qry =
    [NSString stringWithFormat:@"select m.id, m.canonical_name, m.variant_mask, ma.alias, m.is_body_lift, m.percentage_of_body_weight from %@ m left outer join %@ ma on ma.movement_id = m.id where m.canonical_name like '%%%@%%' or ma.alias like '%%%@%%'",
     TBL_MASTER_MOVEMENT,
     TBL_MASTER_MOVEMENT_ALIAS,
     searchText,
     searchText];
    FMResultSet *rs = [PELMUtils doQuery:qry argsArray:@[] db:db error:errorBlk];
    while ([rs next]) {
      NSNumber *movementId = [PELMUtils numberFromResultSet:rs columnIndex:0];
      RMovementSearchResult *result = movements[movementId];
      if (!result) {
        result = [[RMovementSearchResult alloc] init];
        result.canonicalName = [rs stringForColumnIndex:1];
        result.id = movementId;
        result.variantMask = [PELMUtils numberFromResultSet:rs columnIndex:2];
        result.isBodyLift = [PELMUtils boolFromResultSet:rs columnName:@"is_body_lift" boolIfNull:NO];
        result.percentageOfBodyWeight = [PELMUtils decimalNumberFromResultSet:rs columnName:@"percentage_of_body_weight"];
        movements[movementId] = result;
        [results addObject:result];
      }
      NSString *alias = [rs stringForColumnIndex:3];
      if (alias) {
        [result.aliases addObject:alias];
      }
    }
    [rs close];
  }];
  return results;
}

- (NSArray *)movementsWithNilMuscleIdsWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *entities = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    entities = [self movementsWithNilMuscleIdsDb:db error:errorBlk];
  }];
  return entities;
}

- (NSArray *)movementsWithNilMuscleIdsDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", TBL_MASTER_MOVEMENT]
                            argsArray:@[]
                          rsConverter:^(FMResultSet *rs){return [self movementWithNilMuscleIdsFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)movementsWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *entities = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    entities = [self movementsDb:db error:errorBlk];
  }];
  return entities;
}

- (NSArray *)movementsDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *movements = [self movementsWithNilMuscleIdsDb:db error:errorBlk];
  for (RMovement *movement in movements) {
    movement.primaryMuscleIds =
    [PELMUtils numberArrayFromQuery:[NSString stringWithFormat:@"select %@ from %@ where %@ = ?",
                                     COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID,
                                     TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,
                                     COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID]
                               args:@[movement.localMasterIdentifier]
                                 db:db
                              error:errorBlk];
    movement.secondaryMuscleIds =
    [PELMUtils numberArrayFromQuery:[NSString stringWithFormat:@"select %@ from %@ where %@ = ?",
                                     COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID,
                                     TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                                     COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID]
                               args:@[movement.localMasterIdentifier]
                                 db:db
                              error:errorBlk];
  }
  return movements;
}

- (NSArray *)movementsForMuscleGroupId:(NSNumber *)muscleGroupId
                                 error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *movements;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    movements = [self movementsForMuscleGroupId:muscleGroupId db:db error:errorBlk];
  }];
  return movements;
}

- (NSArray *)movementsForMuscleGroupId:(NSNumber *)muscleGroupId
                                    db:(FMDatabase *)db
                                 error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *movements = [NSMutableArray array];
  FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"select distinct mov.* from %@ mov, %@ m, %@ mpm where mov.id = mpm.movement_id and m.id = mpm.muscle_id and m.muscle_group_id = ? order by mov.canonical_name collate nocase asc",
                                        TBL_MASTER_MOVEMENT,
                                        TBL_MASTER_MUSCLE,
                                        TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE
                                        ]
                             argsArray:@[muscleGroupId]
                                    db:db
                                 error:errorBlk];
  while ([rs next]) {
    [movements addObject:[self movementWithNilMuscleIdsFromResultSet:rs]];
  }
  [rs close];
  return movements;
}

- (NSString *)canonicalNameForMovementId:(NSNumber *)movementId
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils stringFromTable:TBL_MASTER_MOVEMENT
                                  selectColumn:COL_MOVEMENT_CANONICAL_NAME
                                   whereColumn:COL_LOCAL_ID
                                    whereValue:movementId
                                         error:errorBlk];
}

- (RMovement *)movementForMovementId:(NSNumber *)movementId
                               error:(PELMDaoErrorBlk)errorBlk {
  NSArray *oneOrEmpty = [self.localModelUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_MOVEMENT,
                                                                 COL_LOCAL_ID]
                                                      argsArray:@[movementId]
                                                    rsConverter:^(FMResultSet *rs){return [self movementWithNilMuscleIdsFromResultSet:rs];}
                                                          error:errorBlk];
  if (oneOrEmpty.count == 0) {
    return nil;
  }
  return oneOrEmpty[0];
}

- (void)saveNewMasterMovement:(RMovement *)movement
                        error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
    [self insertIntoMasterMovement:movement db:db error:errorBlk];
  }];
}

- (RMovement *)movementWithNilMuscleIdsFromResultSet:(FMResultSet *)rs {
  return [[RMovement alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                         globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                relations:nil
                                                createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                            canonicalName:[rs stringForColumn:COL_MOVEMENT_CANONICAL_NAME]
                                               isBodyLift:[PELMUtils boolFromResultSet:rs columnName:COL_MOVEMENT_IS_BODY_LIFT boolIfNull:NO]
                                   percentageOfBodyWeight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT]
                                              variantMask:[PELMUtils numberFromResultSet:rs columnName:COL_MOVEMENT_VARIANT_MASK]
                                                sortOrder:[PELMUtils numberFromResultSet:rs columnName:COL_MOVEMENT_SORT_ORDER]
                                         primaryMuscleIds:nil
                                       secondaryMuscleIds:nil];
}

- (void)insertIntoMasterMovement:(RMovement *)movement
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_MOVEMENT,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MOVEMENT_CANONICAL_NAME,
                    COL_MOVEMENT_IS_BODY_LIFT,
                    COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
                    COL_MOVEMENT_VARIANT_MASK,
                    COL_MOVEMENT_SORT_ORDER];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([movement localMasterIdentifier]),
                              orNil([movement globalIdentifier]),
                              orNil([[movement mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[movement createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[movement updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[movement deletedAt]]),
                              
                              orNil([movement canonicalName]),
                              [NSNumber numberWithBool:movement.isBodyLift],
                              orNil([movement percentageOfBodyWeight]),
                              orNil(movement.variantMask),
                              orNil(movement.sortOrder)]
                     entity:movement
                         db:db
                      error:errorBlk];
  [self insertMasterPrimarySecondaryMusclesForMovement:movement db:db error:errorBlk];
}

- (void)insertMasterPrimarySecondaryMusclesForMovement:(RMovement *)movement
                                                    db:(FMDatabase *)db
                                                 error:(PELMDaoErrorBlk)errorBlk {
  // Insert primary muscle IDs
  NSArray *muscleIds = movement.primaryMuscleIds;
  NSString *primaryMuscleInsert = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (?, ?)",
                                   TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,
                                   COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID,
                                   COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID];
  for (NSNumber *muscleId in muscleIds) {
    [PELMUtils doMasterInsert:primaryMuscleInsert
                    argsArray:@[muscleId, movement.localMasterIdentifier]
                       entity:nil
                           db:db
                        error:errorBlk];
  }
  // Insert secondary muscle IDs
  muscleIds = movement.secondaryMuscleIds;
  NSString *secondaryMuscleInsert = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (?, ?)",
                                     TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                                     COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID,
                                     COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID];
  for (NSNumber *muscleId in muscleIds) {
    [PELMUtils doMasterInsert:secondaryMuscleInsert
                    argsArray:@[muscleId, movement.localMasterIdentifier]
                       entity:nil
                           db:db
                        error:errorBlk];
  }
}

- (NSString *)updateStmtForMasterMovement {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MOVEMENT,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MOVEMENT_CANONICAL_NAME,
          COL_MOVEMENT_IS_BODY_LIFT,
          COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
          COL_MOVEMENT_VARIANT_MASK,
          COL_MOVEMENT_SORT_ORDER,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMovement:(RMovement *)movement {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([movement globalIdentifier]),
           orNil([[movement mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[movement createdAt]]),
           orNil([PEUtils millisecondsFromDate:[movement updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[movement deletedAt]]),
           orNil([movement canonicalName]),
           [NSNumber numberWithBool:movement.isBodyLift],
           orNil([movement percentageOfBodyWeight]),
           orNil(movement.variantMask),
           orNil(movement.sortOrder),
           [movement localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMovement:(RMovement *)movement
                                                          db:(FMDatabase *)db
                                                       error:(PELMDaoErrorBlk)errorBlk {
  PELMSaveNewOrExistingCode code =
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:movement
                                           masterTable:TBL_MASTER_MOVEMENT
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMovement:(RMovement *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMovement]
                                   masterUpdateArgsBlk:^NSArray * (RMovement *theMovement) { return [self updateArgsForMasterMovement:theMovement]; }
                                                    db:db
                                                 error:errorBlk];
  if (code == PELMSaveNewOrExistingCodeDidUpdate) {
    [db executeUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ?",
                       TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,
                       COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID]
 withArgumentsInArray:@[movement.localMasterIdentifier]];
    [db executeUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ?",
                       TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
                       COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID]
 withArgumentsInArray:@[movement.localMasterIdentifier]];
    [self insertMasterPrimarySecondaryMusclesForMovement:movement db:db error:errorBlk];
  }
  return code;
}

#pragma mark - Movement Alias

- (NSArray *)movementAliasesForMovementId:(NSNumber *)movementId
                                    error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *movementAliases = [NSMutableArray array];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    FMResultSet *rs = [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ ASC",
                                          TBL_MASTER_MOVEMENT_ALIAS,
                                          COL_MOVEMENT_ALIAS_MOVEMENT_ID,
                                          COL_MOVEMENT_ALIAS_ALIAS]
                               argsArray:@[movementId]
                                      db:db
                                   error:errorBlk];
    while ([rs next]) {
      [movementAliases addObject:[self movementAliasFromResultSet:rs]];
    }
    [rs close];
  }];
  return movementAliases;
}

- (RMovementAlias *)movementAliasFromResultSet:(FMResultSet *)rs {
  return [[RMovementAlias alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                              globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                     mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                     relations:nil
                                                     createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                     deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                     updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                                    movementId:[rs objectForColumn:COL_MOVEMENT_ALIAS_MOVEMENT_ID]
                                                         alias:[rs stringForColumn:COL_MOVEMENT_ALIAS_ALIAS]];
}

- (void)insertIntoMasterMovementAlias:(RMovementAlias *)movementAlias
                                   db:(FMDatabase *)db
                                error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?)", TBL_MASTER_MOVEMENT_ALIAS,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MOVEMENT_ALIAS_MOVEMENT_ID,
                    COL_MOVEMENT_ALIAS_ALIAS];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([movementAlias localMasterIdentifier]),
                              orNil([movementAlias globalIdentifier]),
                              orNil([[movementAlias mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[movementAlias createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[movementAlias updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[movementAlias deletedAt]]),
                              
                              orNil([movementAlias movementId]),
                              orNil([movementAlias alias])]
                     entity:movementAlias
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterMovementAlias {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MOVEMENT_ALIAS,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MOVEMENT_ALIAS_MOVEMENT_ID,
          COL_MOVEMENT_ALIAS_ALIAS,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMovementAlias:(RMovementAlias *)movementAlias {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([movementAlias globalIdentifier]),
           orNil([[movementAlias mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[movementAlias createdAt]]),
           orNil([PEUtils millisecondsFromDate:[movementAlias updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[movementAlias deletedAt]]),
           orNil([movementAlias movementId]),
           orNil([movementAlias alias]),
           [movementAlias localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMovementAlias:(RMovementAlias *)movementAlias
                                                               db:(FMDatabase *)db
                                                            error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:movementAlias
                                           masterTable:TBL_MASTER_MOVEMENT_ALIAS
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMovementAlias:(RMovementAlias *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMovementAlias]
                                   masterUpdateArgsBlk:^NSArray * (RMovementAlias *theMovementAlias) { return [self updateArgsForMasterMovementAlias:theMovementAlias]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Movement Variant

- (NSArray *)movementVariantsWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *entities = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    entities = [self movementVariantsWithDb:db error:errorBlk];
  }];
  return entities;
}

- (NSArray *)movementVariantsForMovementVariantMask:(NSNumber *)variantMask
                                              error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *variants;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    variants = [self movementVariantsForMovementVariantMask:variantMask db:db error:errorBlk];
  }];
  return variants;
}

- (NSArray *)movementVariantsForMovementVariantMask:(NSNumber *)variantMask
                                                 db:(FMDatabase *)db
                                              error:(PELMDaoErrorBlk)errorBlk {
  NSArray *allVariants = [self movementVariantsWithDb:db error:errorBlk];
  NSMutableArray *variants = [NSMutableArray array];
  if (variantMask) {
    NSInteger variantMaskInteger = variantMask.integerValue;
    for (RMovementVariant *variant in allVariants) {
      if (variantMaskInteger & variant.localMasterIdentifier.integerValue) {
        [variants addObject:variant];
      }
    }
  }
  return variants;
}

- (NSArray *)movementVariantsWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ ASC",
                                       TBL_MASTER_MOVEMENT_VARIANT,
                                       COL_MOVEMENT_VARIANT_SORT_ORDER]
                            argsArray:@[]
                          rsConverter:^(FMResultSet *rs){return [self movementVariantFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSString *)nameForMovementVariantId:(NSNumber *)movementVariantId
                                 error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils stringFromTable:TBL_MASTER_MOVEMENT_VARIANT
                                  selectColumn:COL_MOVEMENT_VARIANT_NAME
                                   whereColumn:COL_LOCAL_ID
                                    whereValue:movementVariantId
                                         error:errorBlk];
}

- (RMovementVariant *)movementVariantForMovementVariantId:(NSNumber *)movementVariantId
                                                    error:(PELMDaoErrorBlk)errorBlk {
  NSArray *oneOrEmpty = [self.localModelUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_MOVEMENT_VARIANT,
                                                                 COL_LOCAL_ID]
                                                      argsArray:@[movementVariantId]
                                                    rsConverter:^(FMResultSet *rs){return [self movementVariantFromResultSet:rs];}
                                                          error:errorBlk];
  if (oneOrEmpty.count == 0) {
    return nil;
  }
  return oneOrEmpty[0];
}

- (void)saveNewMasterMovementVariant:(RMovementVariant *)movementVariant
                               error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
    [self insertIntoMasterMovementVariant:movementVariant db:db error:errorBlk];
  }];
}

- (RMovementVariant *)movementVariantFromResultSet:(FMResultSet *)rs {
  return [[RMovementVariant alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                                globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                       mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                       relations:nil
                                                       createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                       deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                       updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                                            name:[rs objectForColumn:COL_MOVEMENT_VARIANT_NAME]
                                                      abbrevName:[rs objectForColumn:COL_MOVEMENT_VARIANT_ABBREV_NAME]
                                              variantDescription:[rs stringForColumn:COL_MOVEMENT_VARIANT_DESCRIPTION]
                                                       sortOrder:[rs objectForColumn:COL_MOVEMENT_VARIANT_SORT_ORDER]];
}

- (void)insertIntoMasterMovementVariant:(RMovementVariant *)movementVariant
                                     db:(FMDatabase *)db
                                  error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_MOVEMENT_VARIANT,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_MOVEMENT_VARIANT_NAME,
                    COL_MOVEMENT_VARIANT_ABBREV_NAME,
                    COL_MOVEMENT_VARIANT_DESCRIPTION,
                    COL_MOVEMENT_VARIANT_SORT_ORDER];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([movementVariant localMasterIdentifier]),
                              orNil([movementVariant globalIdentifier]),
                              orNil([[movementVariant mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[movementVariant createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[movementVariant updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[movementVariant deletedAt]]),
                              
                              orNil([movementVariant name]),
                              orNil([movementVariant abbrevName]),
                              orNil([movementVariant description]),
                              orNil([movementVariant sortOrder])]
                     entity:movementVariant
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterMovementVariant {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_MOVEMENT_VARIANT,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_MOVEMENT_VARIANT_NAME,
          COL_MOVEMENT_VARIANT_ABBREV_NAME,
          COL_MOVEMENT_VARIANT_DESCRIPTION,
          COL_MOVEMENT_VARIANT_SORT_ORDER,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterMovementVariant:(RMovementVariant *)movementVariant {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([movementVariant globalIdentifier]),
           orNil([[movementVariant mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[movementVariant createdAt]]),
           orNil([PEUtils millisecondsFromDate:[movementVariant updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[movementVariant deletedAt]]),
           orNil([movementVariant name]),
           orNil([movementVariant abbrevName]),
           orNil([movementVariant description]),
           orNil([movementVariant sortOrder]),
           [movementVariant localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterMovementVariant:(RMovementVariant *)movementVariant
                                                                 db:(FMDatabase *)db
                                                              error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:movementVariant
                                           masterTable:TBL_MASTER_MOVEMENT_VARIANT
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterMovementVariant:(RMovementVariant *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterMovementVariant]
                                   masterUpdateArgsBlk:^NSArray * (RMovementVariant *theMovementVariant) { return [self updateArgsForMasterMovementVariant:theMovementVariant]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - Origination Devices

- (NSArray *)originationDevicesWithError:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *entities = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    entities = [self originationDevicesWithDb:db error:errorBlk];
  }];
  return entities;
  
}

- (NSArray *)originationDevicesWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", TBL_MASTER_ORIGINATION_DEVICE]
                            argsArray:@[]
                          rsConverter:^(FMResultSet *rs){return [self originationDeviceFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (ROriginationDevice *)originationDeviceWithId:(NSNumber *)originationDeviceId
                                          error:(PELMDaoErrorBlk)errorBlk {
  NSArray *oneOrEmpty = [self.localModelUtils entitiesFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_ORIGINATION_DEVICE,
                                                                 COL_LOCAL_ID]
                                                      argsArray:@[originationDeviceId]
                                                    rsConverter:^(FMResultSet *rs){return [self originationDeviceFromResultSet:rs];}
                                                          error:errorBlk];
  if (oneOrEmpty.count == 0) {
    return nil;
  }
  return oneOrEmpty[0];
}

- (ROriginationDevice *)originationDeviceFromResultSet:(FMResultSet *)rs {
  return [[ROriginationDevice alloc] initWithLocalMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                                  globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                         mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                         relations:nil
                                                         createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                         deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                         updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                                              name:[rs stringForColumn:COL_ORIG_DEVICE_NAME]
                                                     iconImageName:[rs stringForColumn:COL_ORIG_DEVICE_ICON_IMAGE_NAME]
                                                     hasLocalImage:[PELMUtils boolFromResultSet:rs columnName:COL_ORIG_DEVICE_HAS_LOCAL_IMAGE boolIfNull:NO]];
}

- (void)insertIntoMasterOriginationDevice:(ROriginationDevice *)originationDevice
                                       db:(FMDatabase *)db
                                    error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_ORIGINATION_DEVICE,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_ORIG_DEVICE_NAME,
                    COL_ORIG_DEVICE_HAS_LOCAL_IMAGE,
                    COL_ORIG_DEVICE_ICON_IMAGE_NAME];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([originationDevice localMasterIdentifier]),
                              orNil([originationDevice globalIdentifier]),
                              orNil([[originationDevice mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[originationDevice createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[originationDevice updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[originationDevice deletedAt]]),
                              
                              orNil([originationDevice name]),
                              [NSNumber numberWithBool:[originationDevice hasLocalImage]],
                              orNil([originationDevice iconImageName])]
                     entity:originationDevice
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterOriginationDevice {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_ORIGINATION_DEVICE,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_ORIG_DEVICE_NAME,
          COL_ORIG_DEVICE_ICON_IMAGE_NAME,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterOriginationDevice:(ROriginationDevice *)originationDevice {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([originationDevice globalIdentifier]),
           orNil([[originationDevice mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[originationDevice createdAt]]),
           orNil([PEUtils millisecondsFromDate:[originationDevice updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[originationDevice deletedAt]]),
           orNil([originationDevice name]),
           orNil([originationDevice iconImageName]),
           [originationDevice localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterOriginationDevice:(ROriginationDevice *)originationDevice
                                                                   db:(FMDatabase *)db
                                                                error:(PELMDaoErrorBlk)errorBlk {
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:originationDevice
                                           masterTable:TBL_MASTER_ORIGINATION_DEVICE
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterOriginationDevice:(ROriginationDevice *)entity db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterOriginationDevice]
                                   masterUpdateArgsBlk:^NSArray * (ROriginationDevice *theOriginationDevice) { return [self updateArgsForMasterOriginationDevice:theOriginationDevice]; }
                                                    db:db
                                                 error:errorBlk];
}

#pragma mark - User Settings

- (RUserSettings *)masterUserSettingsWithId:(NSNumber *)userSettingsId error:(PELMDaoErrorBlk)errorBlk {
  NSString *userSettingsTable = TBL_MASTER_USER_SETTINGS;
  __block RUserSettings *userSettings = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    userSettings = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", userSettingsTable, COL_LOCAL_ID]
                                    argsArray:@[userSettingsId]
                                  rsConverter:^(FMResultSet *rs) { return [self masterUserSettingsFromResultSet:rs]; }
                                           db:db
                                        error:errorBlk];
  }];
  return userSettings;
}

- (RUserSettings *)masterUserSettingsWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  __block RUserSettings *userSettings = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    userSettings = [self masterUserSettingsWithGlobalId:globalId db:db error:errorBlk];
  }];
  return userSettings;
}

- (RUserSettings *)masterUserSettingsWithGlobalId:(NSString *)globalId
                                               db:(FMDatabase *)db
                                            error:(PELMDaoErrorBlk)errorBlk {
  NSString *table = TBL_MASTER_USER_SETTINGS;
  RUserSettings *userSettings = nil;
  userSettings = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", table, COL_GLOBAL_ID]
                                  argsArray:@[globalId]
                                rsConverter:^(FMResultSet *rs) { return [self masterUserSettingsFromResultSet:rs]; }
                                         db:db
                                      error:errorBlk];
  return userSettings;
}

- (void)saveNewLocalUserSettings:(RUserSettings *)userSettings
                         forUser:(PELMUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterUserSettings:userSettings forUser:user db:db error:errorBlk];
}

- (RUserSettings *)userSettingsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block RUserSettings *userSettings = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    userSettings = [self userSettingsForUser:user db:db error:errorBlk];
  }];
  return userSettings;
}

- (RUserSettings *)userSettingsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *oneOrEmpty = [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ?",
                                                      TBL_MASTER_USER_SETTINGS,
                                                      COL_MASTER_USER_ID]
                                           argsArray:@[user.localMasterIdentifier]
                                         rsConverter:^(FMResultSet *rs){return [self masterUserSettingsFromResultSet:rs];}
                                                  db:db
                                               error:errorBlk];
  if (oneOrEmpty.count > 0) {
    return oneOrEmpty[0];
  }
  return nil;
}

- (void)deleteUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    [self deleteUserSettings:userSettings db:db error:errorBlk];
  }];
}

- (void)deleteUserSettings:(RUserSettings *)userSettings db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:userSettings
                    table:TBL_MASTER_USER_SETTINGS
                       db:db
                    error:errorBlk];
}

- (RUserSettings *)mainUserSettingsFromResultSet:(FMResultSet *)rs {
  return [[RUserSettings alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                      localMasterIdentifier:nil // NA (this is a master store-only column)
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                  createdAt:nil // NA (this is a master store-only column)
                                                  deletedAt:nil // NA (this is a master store-only column)
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                       dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                             editInProgress:[rs boolForColumn:COL_EDIT_IN_PROGRESS]
                                             syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                     synced:[rs boolForColumn:COL_SYNCED]
                                                  editCount:[rs intForColumn:COL_EDIT_COUNT]
                                           syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                                syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                                syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                                  weightUom:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_WEIGHT_UOM]
                                                    sizeUom:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_SIZE_UOM]
                                         weightIncDecAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT]];
}

- (RUserSettings *)masterUserSettingsFromResultSet:(FMResultSet *)rs {
  return [[RUserSettings alloc] initWithLocalMainIdentifier:nil // NA
                                      localMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                           globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                  mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                  relations:nil
                                                  createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                  deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                  updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                       dateCopiedFromMaster:nil // NA
                                             editInProgress:NO // NA
                                             syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                     synced:[rs boolForColumn:COL_SYNCED]
                                                  editCount:0   // NA
                                           syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                                syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                                syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                                  weightUom:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_WEIGHT_UOM]
                                                    sizeUom:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_SIZE_UOM]
                                         weightIncDecAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT]];
}

- (void)insertIntoMasterUserSettings:(RUserSettings *)userSettings
                             forUser:(PELMUser *)user
                                  db:(FMDatabase *)db
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_USER_SETTINGS,
                    COL_MASTER_USER_ID,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    COL_USER_SETTINGS_WEIGHT_UOM,
                    COL_USER_SETTINGS_SIZE_UOM,
                    COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT,
                    COL_SYNC_IN_PROGRESS,
                    COL_SYNCED,
                    COL_SYNC_HTTP_RESP_CODE,
                    COL_SYNC_ERR_MASK,
                    COL_SYNC_RETRY_AT];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([userSettings localMasterIdentifier]),
                              orNil([userSettings globalIdentifier]),
                              orNil([[userSettings mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[userSettings createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[userSettings updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[userSettings deletedAt]]),
                              orNil([userSettings weightUom]),
                              orNil([userSettings sizeUom]),
                              orNil([userSettings weightIncDecAmount]),
                              [NSNumber numberWithBool:[userSettings syncInProgress]],
                              [NSNumber numberWithBool:[userSettings synced]],
                              orNil([userSettings syncHttpRespCode]),
                              orNil([userSettings syncErrMask]),
                              orNil([PEUtils millisecondsFromDate:[userSettings syncRetryAt]])]
                     entity:userSettings
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterUserSettings {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          \
          WHERE %@ = ?",
          TBL_MASTER_USER_SETTINGS,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          
          COL_USER_SETTINGS_WEIGHT_UOM,
          COL_USER_SETTINGS_SIZE_UOM,
          COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT,
          
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterUserSettings:(RUserSettings *)userSettings {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([userSettings globalIdentifier]),
           orNil([[userSettings mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[userSettings createdAt]]),
           orNil([PEUtils millisecondsFromDate:[userSettings updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[userSettings deletedAt]]),
           orNil([userSettings weightUom]),
           orNil([userSettings sizeUom]),
           orNil([userSettings weightIncDecAmount]),
           [NSNumber numberWithBool:[userSettings syncInProgress]],
           [NSNumber numberWithBool:[userSettings synced]],
           orNil([userSettings syncHttpRespCode]),
           orNil([userSettings syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[userSettings syncRetryAt]]),
           [userSettings localMasterIdentifier]];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterUserSettings:(RUserSettings *)userSettings
                                                         forUser:(PELMUser *)user
                                                              db:(FMDatabase *)db
                                                           error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingEntity:userSettings
                                masterTable:TBL_MASTER_USER_SETTINGS
                            masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterUserSettings:(RUserSettings *)entity forUser:user db:db error:errorBlk];}
                           masterUpdateStmt:[self updateStmtForMasterUserSettings]
                        masterUpdateArgsBlk:^NSArray * (RUserSettings *theUserSettings) { return [self updateArgsForMasterUserSettings:theUserSettings]; }
                              idSearcherBlk:^ NSNumber * (NSString *masterTable, PELMMasterSupport *masterEntity) {
                                return @([PELMUtils intFromQuery:[NSString stringWithFormat:@"select %@ from %@ where %@ = ?",
                                                                  COL_LOCAL_ID,
                                                                  TBL_MASTER_USER_SETTINGS,
                                                                  COL_MASTER_USER_ID]
                                                            args:@[user.localMasterIdentifier]
                                                              db:db]);
                              }
                                         db:db
                                      error:errorBlk];
}

- (RUserSettings *)markUserSettingsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  NSArray *userSettingsEntities = [self.localModelUtils markEntitiesAsSyncInProgressInTable:TBL_MASTER_USER_SETTINGS
                                                                        entityFromResultSet:^(FMResultSet *rs){return [self masterUserSettingsFromResultSet:rs];}
                                                                                 updateStmt:[self updateStmtForMasterUserSettings]
                                                                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                                                                    importLimitExceededMask:nil
                                                                                       user:user
                                                                              importedAtBlk:nil
                                                                  hasExceededImportLimitBlk:nil
                                                                                      error:errorBlk][0];
  if ([userSettingsEntities count] > 1) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"There cannot be more than 1 user settings entity"
                                 userInfo:nil];
  } else if ([userSettingsEntities count] == 0) {
    return nil;
  } else {
    return [userSettingsEntities objectAtIndex:0];
  }
}

- (void)cancelSyncForUserSettings:(RUserSettings *)userSettings
                     httpRespCode:(NSNumber *)httpRespCode
                        errorMask:(NSNumber *)errorMask
                          retryAt:(NSDate *)retryAt
                            error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:userSettings
                               httpRespCode:httpRespCode
                                  errorMask:errorMask
                                    retryAt:retryAt
                                 updateStmt:[self updateStmtForMasterUserSettings]
                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                                      error:errorBlk];
}

- (void)markAsSyncCompleteForUpdatedUserSettings:(RUserSettings *)userSettings
                                         forUser:(PELMUser *)user
                         writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                           error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self.localModelUtils markAsSyncCompleteForEntity:userSettings
                                     masterUpdateStmt:[self updateStmtForMasterUserSettings]
                                  masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                                                   db:db
                                                error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:userSettings db:db error:errorBlk];
    }
  }];
}

- (void)saveUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveEntity:userSettings
                        updateStmt:[self updateStmtForMasterUserSettings]
                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                             error:errorBlk];
}

- (void)markAsDoneEditingUserSettings:(RUserSettings *)userSettings error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:userSettings
                                     updateStmt:[self updateStmtForMasterUserSettings]
                                  updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                                          error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncUserSettings:(RUserSettings *)userSettings
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:userSettings
                                                  updateStmt:[self updateStmtForMasterUserSettings]
                                               updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUserSettings:(RUserSettings *)entity];}
                                                       error:errorBlk];
}

- (BOOL)saveMasterUserSettings:(RUserSettings *)userSettings
                       forUser:(PELMUser *)user
       writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL didDatabaseUpdate = NO;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[self updateStmtForMasterUserSettings]
              argsArray:[self updateArgsForMasterUserSettings:userSettings]
                     db:db
                  error:errorBlk];
    didDatabaseUpdate = YES;
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:userSettings db:db error:errorBlk];
    }
  }];
  return didDatabaseUpdate;
}

#pragma mark - Set

- (RSet *)setWithCorrelationGuid:(NSString *)correlationGuid error:(PELMDaoErrorBlk)errorBlk {
  __block RSet *set = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    set = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_SET, COL_SET_CORRELATION_GUID]
                           argsArray:@[correlationGuid]
                         rsConverter:^(FMResultSet *rs) { return [self masterSetFromResultSet:rs]; }
                                  db:db
                               error:errorBlk];
  }];
  return set;
}

- (RSet *)masterSetWithId:(NSNumber *)setId error:(PELMDaoErrorBlk)errorBlk {
  NSString *setTable = TBL_MASTER_SET;
  __block RSet *set = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    set = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", setTable, COL_LOCAL_ID]
                           argsArray:@[setId]
                         rsConverter:^(FMResultSet *rs) { return [self masterSetFromResultSet:rs]; }
                                  db:db
                               error:errorBlk];
  }];
  return set;
}

- (RSet *)masterSetWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  __block RSet *set = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    set = [self masterSetWithGlobalId:globalId db:db error:errorBlk];
  }];
  return set;
}

- (RSet *)masterSetWithGlobalId:(NSString *)globalId
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk {
  NSString *setTable = TBL_MASTER_SET;
  RSet *set = nil;
  set = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", setTable, COL_GLOBAL_ID]
                         argsArray:@[globalId]
                       rsConverter:^(FMResultSet *rs) { return [self masterSetFromResultSet:rs]; }
                                db:db
                             error:errorBlk];
  return set;
}

- (void)deleteSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteSet:set db:db error:errorBlk];
  }];
}

- (void)deleteSet:(RSet *)set db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:set
                    table:TBL_MASTER_SET
                       db:db
                    error:errorBlk];
}

- (NSInteger)numSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numSets = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numSets = [self numSetsForUser:user db:db error:errorBlk];
  }];
  return numSets;
}

- (NSInteger)numSetsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ = ?",
                                  TBL_MASTER_SET, COL_MASTER_USER_ID]
                            args:@[user.localMasterIdentifier]
                              db:db];
}

- (NSInteger)numSetsForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numSets = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numSets = [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ > ? and %@ = ?",
                                       TBL_MASTER_SET, COL_SET_LOGGED_AT, COL_MASTER_USER_ID]
                                 args:@[[PEUtils millisecondsFromDate:loggedSince], user.localMasterIdentifier]
                                   db:db];
  }];
  return numSets;
}

- (NSInteger)numSyncedImportedSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numSets = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numSets = [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ is not null and %@ = 1 and %@ is not null and %@ = ?",
                                       TBL_MASTER_SET, COL_GLOBAL_ID, COL_SYNCED, COL_IMPORTED_AT, COL_MASTER_USER_ID]
                                 args:@[user.localMasterIdentifier]
                                   db:db];
  }];
  return numSets;
}

- (NSDate *)mostRecentSetDateForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSDate *date = nil;
  [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
    date = [self mostRecentSetDateForUser:user db:db error:errorBlk];
  }];
  return date;
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self descendingSetsForUser:user db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                         pageSize:(NSInteger)pageSize
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user pageSize:pageSize db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                         pageSize:(NSInteger)pageSize
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user afterLoggedAt:afterLoggedAt pageSize:pageSize db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self descendingSetsForUser:user pageSize:pageSize db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                             since:(NSDate *)since
                             error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self descendingSetsForUser:user since:since db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self descendingSetsForUser:user beforeLoggedAt:beforeLoggedAt pageSize:pageSize db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user afterLoggedAt:afterLoggedAt db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user onOrAfterLoggedAt:onOrAfterLoggedAt onOrBeforeLoggedAt:onOrBeforeLoggedAt db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user onOrAfterLoggedAt:onOrAfterLoggedAt db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingSetsForUser:user db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)unsyncedSetsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self unsyncedSetsForUser:user db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)unsyncedSetsForUser:(PELMUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ = 0 order by %@ desc",
                                       TBL_MASTER_SET,
                                       COL_MASTER_USER_ID,
                                       COL_SYNCED,
                                       COL_SET_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (void)saveNewSet:(RSet *)set
           forUser:(PELMUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewSet:set forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewSets:(NSArray *)sets
            forUser:(PELMUser *)user
              error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    for (RSet *set in sets) {
      [self saveNewSet:set forUser:user db:db error:errorBlk];
    }
  }];
}

- (void)saveNewAndSyncImmediateSet:(RSet *)set
                           forUser:(PELMUser *)user
                             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [set setSyncInProgress:YES];
    [self saveNewSet:set forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewSet:(RSet *)set
           forUser:(PELMUser *)user
                db:(FMDatabase *)db
             error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterSet:set forUser:user db:db error:errorBlk];
}

- (void)saveSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveEntity:set
                        updateStmt:[self updateStmtForMasterSet]
                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                             error:errorBlk];
}

- (void)markAsDoneEditingSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:set
                                     updateStmt:[self updateStmtForMasterSet]
                                  updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                          error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncSet:(RSet *)set error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:set
                                                  updateStmt:[self updateStmtForMasterSet]
                                               updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                                       error:errorBlk];
}

- (NSArray *)markSetsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInTable:TBL_MASTER_SET
                                               entityFromResultSet:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                                        updateStmt:[self updateStmtForMasterSet]
                                                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                           importLimitExceededMask:@(RSaveSetImportLimitExceeded)
                                                              user:user
                                                     importedAtBlk:^NSDate * (RSet *set) { return set.importedAt; }
                                         hasExceededImportLimitBlk:^BOOL (PELMUser *user) {
                                           NSNumber *maxAllowedSetImport = [user maxAllowedSetImport];
                                           if (maxAllowedSetImport) {
                                             return [self numSyncedImportedSetsForUser:user
                                                                                 error:[RUtils localFetchErrorHandlerMaker]()] >= maxAllowedSetImport.integerValue;
                                           }
                                           return NO;
                                         }
                                                             error:errorBlk];
}

- (void)cancelSyncForSet:(RSet *)set
            httpRespCode:(NSNumber *)httpRespCode
               errorMask:(NSNumber *)errorMask
                 retryAt:(NSDate *)retryAt
                   error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:set
                               httpRespCode:httpRespCode
                                  errorMask:errorMask
                                    retryAt:retryAt
                                 updateStmt:[self updateStmtForMasterSet]
                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                      error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterSet:(RSet *)set
                                                forUser:(PELMUser *)user
                                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                                     db:(FMDatabase *)db
                                                  error:(PELMDaoErrorBlk)errorBlk {
  PELMSaveNewOrExistingCode returnCode =
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:set
                                           masterTable:TBL_MASTER_SET
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterSet:(RSet *)entity forUser:user db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterSet]
                                   masterUpdateArgsBlk:^NSArray * (RSet *theSet) { return [self updateArgsForMasterSet:theSet]; }
                                                    db:db
                                                 error:errorBlk];
  if (writeUserReadonlyFields) {
    [self saveMasterUser:user readOnlyFieldsEntity:set db:db error:errorBlk];
  }
  return returnCode;
}

- (void)saveNewMasterSet:(RSet *)set
                 forUser:(PELMUser *)user
 writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self insertIntoMasterSet:set forUser:user db:db error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:set db:db error:errorBlk];
    }
  }];
}

- (BOOL)saveMasterSet:(RSet *)set
              forUser:(PELMUser *)user
writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL didDatabaseUpdate = NO;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[self updateStmtForMasterSet]
              argsArray:[self updateArgsForMasterSet:set]
                     db:db
                  error:errorBlk];
    didDatabaseUpdate = YES;
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:set db:db error:errorBlk];
    }
  }];
  return didDatabaseUpdate;
}

- (void)markAsSyncCompleteForNewSet:(RSet *)set
                            forUser:(PELMUser *)user
            writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                              error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self.localModelUtils markAsSyncCompleteForEntity:set
                                     masterUpdateStmt:[self updateStmtForMasterSet]
                                  masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                                   db:db
                                                error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:set db:db error:errorBlk];
    }
  }];
}

- (void)markAsSyncCompleteForUpdatedSet:(RSet *)set
                                forUser:(PELMUser *)user
                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self.localModelUtils markAsSyncCompleteForEntity:set
                                     masterUpdateStmt:[self updateStmtForMasterSet]
                                  masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterSet:(RSet *)entity];}
                                                   db:db
                                                error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:set db:db error:errorBlk];
    }
  }];
}

- (NSInteger)numSetsWithUuid:(NSString *)uuid
                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numSets = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numSets = [PELMUtils numRowsFromTable:TBL_MASTER_SET
                                  equalTo:uuid
                            equalToColumn:COL_SET_UUID
                                       db:db
                                    error:errorBlk];
  }];
  return numSets;
}

- (RSet *)mainSetFromResultSet:(FMResultSet *)rs {
  return [[RSet alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                             localMasterIdentifier:nil // NA (this is a master store-only column)
                                  globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                         mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                         relations:nil
                                         createdAt:nil // NA (this is a master store-only column)
                                         deletedAt:nil // NA (this is a master store-only column)
                                         updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                              dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                    editInProgress:[rs boolForColumn:COL_EDIT_IN_PROGRESS]
                                    syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                            synced:[rs boolForColumn:COL_SYNCED]
                                         editCount:[rs intForColumn:COL_EDIT_COUNT]
                                  syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                       syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                       syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                           numReps:[PELMUtils numberFromResultSet:rs columnName:COL_SET_NUM_REPS]
                                            weight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_SET_WEIGHT]
                                         weightUom:[PELMUtils numberFromResultSet:rs columnName:COL_SET_WEIGHT_UOM]
                                         negatives:[rs boolForColumn:COL_SET_NEGATIVES]
                                         toFailure:[rs boolForColumn:COL_SET_TO_FAILURE]
                                          loggedAt:[PELMUtils dateFromResultSet:rs columnName:COL_SET_LOGGED_AT]
                                        ignoreTime:[rs boolForColumn:COL_SET_IGNORE_TIME]
                                        movementId:[PELMUtils numberFromResultSet:rs columnName:COL_SET_MOVEMENT_ID]
                                 movementVariantId:[PELMUtils numberFromResultSet:rs columnName:COL_SET_MOVEMENT_VARIANT_ID]
                               originationDeviceId:[PELMUtils numberFromResultSet:rs columnName:COL_ORIGINATION_DEVICE_ID]
                                        importedAt:[PELMUtils dateFromResultSet:rs columnName:COL_IMPORTED_AT]
                                   correlationGuid:[rs stringForColumn:COL_SET_CORRELATION_GUID]];
}

- (RSet *)masterSetFromResultSet:(FMResultSet *)rs {
  return [[RSet alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                             localMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                  globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                         mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                         relations:nil
                                         createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                         deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                         updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                              dateCopiedFromMaster:nil // NA
                                    editInProgress:NO // NA
                                    syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                            synced:[rs boolForColumn:COL_SYNCED]
                                         editCount:0   // NA
                                  syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                       syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                       syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                           numReps:[PELMUtils numberFromResultSet:rs columnName:COL_SET_NUM_REPS]
                                            weight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_SET_WEIGHT]
                                         weightUom:[PELMUtils numberFromResultSet:rs columnName:COL_SET_WEIGHT_UOM]
                                         negatives:[rs boolForColumn:COL_SET_NEGATIVES]
                                         toFailure:[rs boolForColumn:COL_SET_TO_FAILURE]
                                          loggedAt:[PELMUtils dateFromResultSet:rs columnName:COL_SET_LOGGED_AT]
                                        ignoreTime:[rs boolForColumn:COL_SET_IGNORE_TIME]
                                        movementId:[PELMUtils numberFromResultSet:rs columnName:COL_SET_MOVEMENT_ID]
                                 movementVariantId:[PELMUtils numberFromResultSet:rs columnName:COL_SET_MOVEMENT_VARIANT_ID]
                               originationDeviceId:[PELMUtils numberFromResultSet:rs columnName:COL_ORIGINATION_DEVICE_ID]
                                        importedAt:[PELMUtils dateFromResultSet:rs columnName:COL_IMPORTED_AT]
                                   correlationGuid:[rs stringForColumn:COL_SET_CORRELATION_GUID]];
}

- (NSDate *)mostRecentSetDateForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils maxDateFromTable:TBL_MASTER_SET
                          dateColumn:COL_SET_LOGGED_AT
                         whereColumn:nil
                          whereValue:nil
                                  db:db
                               error:errorBlk];
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at desc, updated_at desc",
                                       TBL_MASTER_SET, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user pageSize:(NSInteger)pageSize db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at asc, updated_at asc limit %ld",
                                       TBL_MASTER_SET, COL_MASTER_USER_ID, (long)pageSize]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user pageSize:(NSInteger)pageSize db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at desc, updated_at desc limit %ld",
                                       TBL_MASTER_SET, COL_MASTER_USER_ID, (long)pageSize]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at asc", TBL_MASTER_SET, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at > ? order by logged_at asc", TBL_MASTER_SET, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:afterLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at >= ? AND logged_at <= ? order by logged_at asc", TBL_MASTER_SET, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier,
                                        [PEUtils millisecondsFromDate:onOrAfterLoggedAt],
                                        [PEUtils millisecondsFromDate:onOrBeforeLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at >= ? order by logged_at asc",
                                       TBL_MASTER_SET,
                                       COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier,
                                        [PEUtils millisecondsFromDate:onOrAfterLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                             since:(NSDate *)since
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at > ? order by logged_at desc", TBL_MASTER_SET, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:since]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingSetsForUser:(PELMUser *)user
                    afterLoggedAt:(NSDate *)afterLoggedAt
                         pageSize:(NSInteger)pageSize
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at > ? order by logged_at asc limit %ld",
                                       TBL_MASTER_SET, COL_MASTER_USER_ID, (long)pageSize]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:afterLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)descendingSetsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and logged_at < ? order by logged_at desc limit %ld",
                                       TBL_MASTER_SET, COL_MASTER_USER_ID, (long)pageSize]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:beforeLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterSetFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (void)deleteSetsOfUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *sets = [self descendingSetsForUser:user db:db error:errorBlk];
  for (RSet *set in sets) {
    [self deleteSet:set db:db error:errorBlk];
  }
}

- (void)insertIntoMasterSet:(RSet *)set
                    forUser:(PELMUser *)user
                         db:(FMDatabase *)db
                      error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_SET,
                    COL_MASTER_USER_ID,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_SET_MOVEMENT_ID,
                    COL_SET_MOVEMENT_VARIANT_ID,
                    COL_SET_NUM_REPS,
                    COL_SET_WEIGHT,
                    COL_SET_WEIGHT_UOM,
                    COL_SET_NEGATIVES,
                    COL_SET_TO_FAILURE,
                    COL_SET_LOGGED_AT,
                    COL_SET_IGNORE_TIME,
                    COL_ORIGINATION_DEVICE_ID,
                    
                    COL_SYNC_IN_PROGRESS,
                    COL_SYNCED,
                    COL_SYNC_HTTP_RESP_CODE,
                    COL_SYNC_ERR_MASK,
                    COL_SYNC_RETRY_AT,
                    COL_SET_CORRELATION_GUID,
                    COL_SET_UUID,
                    
                    COL_IMPORTED_AT,
                    COL_SET_CORRELATION_GUID];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([set localMasterIdentifier]),
                              orNil([set globalIdentifier]),
                              orNil([[set mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[set createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[set updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[set deletedAt]]),
                              
                              orNil([set movementId]),
                              orNil([set movementVariantId]),
                              orNil([set numReps]),
                              orNil([set weight]),
                              orNil([set weightUom]),
                              [NSNumber numberWithBool:[set negatives]],
                              [NSNumber numberWithBool:[set toFailure]],
                              orNil([PEUtils millisecondsFromDate:[set loggedAt]]),
                              [NSNumber numberWithBool:[set ignoreTime]],
                              orNil([set originationDeviceId]),
                              [NSNumber numberWithBool:[set syncInProgress]],
                              [NSNumber numberWithBool:[set synced]],
                              orNil([set syncHttpRespCode]),
                              orNil([set syncErrMask]),
                              orNil([PEUtils millisecondsFromDate:[set syncRetryAt]]),
                              orNil([set correlationGuid]),
                              orNil([set uuid]),
                              orNil([PEUtils millisecondsFromDate:[set importedAt]]),
                              orNil([set correlationGuid])]
                     entity:set
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterSet {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_SET,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_SET_MOVEMENT_ID,
          COL_SET_MOVEMENT_VARIANT_ID,
          COL_SET_NUM_REPS,
          COL_SET_WEIGHT,
          COL_SET_WEIGHT_UOM,
          COL_SET_NEGATIVES,
          COL_SET_TO_FAILURE,
          COL_SET_LOGGED_AT,
          COL_SET_IGNORE_TIME,
          COL_ORIGINATION_DEVICE_ID,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_SET_CORRELATION_GUID,
          COL_SET_UUID,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterSet:(RSet *)set {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([set globalIdentifier]),
           orNil([[set mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[set createdAt]]),
           orNil([PEUtils millisecondsFromDate:[set updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[set deletedAt]]),
           orNil([set movementId]),
           orNil([set movementVariantId]),
           orNil([set numReps]),
           orNil([set weight]),
           orNil([set weightUom]),
           [NSNumber numberWithBool:[set negatives]],
           [NSNumber numberWithBool:[set toFailure]],
           orNil([PEUtils millisecondsFromDate:[set loggedAt]]),
           [NSNumber numberWithBool:[set ignoreTime]],
           orNil([set originationDeviceId]),
           [NSNumber numberWithBool:[set syncInProgress]],
           [NSNumber numberWithBool:[set synced]],
           orNil([set syncHttpRespCode]),
           orNil([set syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[set syncRetryAt]]),
           orNil([set correlationGuid]),
           orNil([set uuid]),
           [set localMasterIdentifier]];
}

#pragma mark - Body Measurement Log

- (RBodyMeasurementLog *)mostRecentBmlWithNonNilWeightForUser:(PELMUser *)user
                                                        error:(PELMDaoErrorBlk)errorBlk {
  __block RBodyMeasurementLog *bml;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bml = [self mostRecentBmlWithNonNilWeightForUser:user db:db error:errorBlk];
  }];
  return bml;
}

- (RBodyMeasurementLog *)mostRecentBmlWithNonNilWeightForUser:(PELMUser *)user
                                                           db:(FMDatabase *)db
                                                        error:(PELMDaoErrorBlk)errorBlk {
  NSArray *bmls = [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ is not null order by %@ desc",
                                                TBL_MASTER_BODY_MEASUREMENT_LOG,
                                                COL_MASTER_USER_ID,
                                                COL_BML_BODY_WEIGHT,
                                                COL_BML_LOGGED_AT]
                                    numAllowed:@(1)
                                     argsArray:@[user.localMasterIdentifier]
                                   rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                            db:db
                                         error:errorBlk];
  if ([PEUtils isNotNil:bmls] && bmls.count >= 1) {
    return bmls[0];
  }
  return nil;
}

- (RBodyMeasurementLog *)masterBmlWithId:(NSNumber *)bmlId error:(PELMDaoErrorBlk)errorBlk {
  NSString *bmlTable = TBL_MASTER_BODY_MEASUREMENT_LOG;
  __block RBodyMeasurementLog *bml = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bml = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", bmlTable, COL_LOCAL_ID]
                           argsArray:@[bmlId]
                         rsConverter:^(FMResultSet *rs) { return [self masterBmlFromResultSet:rs]; }
                                  db:db
                               error:errorBlk];
  }];
  return bml;
}

- (RBodyMeasurementLog *)masterBmlWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  __block RBodyMeasurementLog *bml = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bml = [self masterBmlWithGlobalId:globalId db:db error:errorBlk];
  }];
  return bml;
}

- (RBodyMeasurementLog *)masterBmlWithGlobalId:(NSString *)globalId
                                            db:(FMDatabase *)db
                                         error:(PELMDaoErrorBlk)errorBlk {
  NSString *bmlTable = TBL_MASTER_BODY_MEASUREMENT_LOG;
  RBodyMeasurementLog *bml = nil;
  bml = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", bmlTable, COL_GLOBAL_ID]
                         argsArray:@[globalId]
                       rsConverter:^(FMResultSet *rs) { return [self masterBmlFromResultSet:rs]; }
                                db:db
                             error:errorBlk];
  return bml;
}

- (void)deleteBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteBml:bml db:db error:errorBlk];
  }];
}

- (void)deleteBml:(RBodyMeasurementLog *)bml db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils deleteEntity:bml
                    table:TBL_MASTER_BODY_MEASUREMENT_LOG
                       db:db
                    error:errorBlk];
}

- (NSInteger)numBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numBmls = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numBmls = [self numBmlsForUser:user db:db error:errorBlk];
  }];
  return numBmls;
}

- (NSInteger)numBmlsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils numRowsFromTable:TBL_MASTER_BODY_MEASUREMENT_LOG db:db error:errorBlk];
}

- (NSInteger)numBmlsWithNonNilBodyWeightForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numBmls = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numBmls = [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ = ? and %@ is not null",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_BODY_WEIGHT]
                                 args:@[user.localMasterIdentifier]
                                   db:db];
  }];
  return numBmls;
}

- (NSInteger)numBmlsWithNonNilBodyWeightForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numBmls = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numBmls = [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ = ? and %@ is not null and %@ > ?",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_BODY_WEIGHT,
                                       COL_BML_LOGGED_AT]
                                 args:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:loggedSince]]
                                   db:db];
  }];
  return numBmls;
}

- (NSInteger)numSyncedImportedBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numBmls = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numBmls = [PELMUtils intFromQuery:[NSString stringWithFormat:@"select count(*) from %@ where %@ = ? and %@ is not null and %@ is not null",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_GLOBAL_ID,
                                       COL_IMPORTED_AT]
                                 args:@[user.localMasterIdentifier]
                                   db:db];
  }];
  return numBmls;
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self descendingBmlsForUser:user db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user pageSize:(NSInteger)pageSize error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self descendingBmlsForUser:user pageSize:pageSize db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                             error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self descendingBmlsForUser:user beforeLoggedAt:beforeLoggedAt pageSize:pageSize db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self ascendingBmlsForUser:user db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self ascendingBmlsWithNonNilBodyWeightForUser:user db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self ascendingBmlsWithNonNilBodyWeightForUser:user loggedSince:loggedSince db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingBmlsForUser:user onOrAfterLoggedAt:onOrAfterLoggedAt onOrBeforeLoggedAt:onOrBeforeLoggedAt db:db error:errorBlk];
  }];
  return sets;
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                            error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *sets = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    sets = [self ascendingBmlsForUser:user onOrAfterLoggedAt:onOrAfterLoggedAt db:db error:errorBlk];
  }];
  return sets;
}

- (RBodyMeasurementLog *)nearestBmlWithNonNilBodyWeightToDate:(NSDate *)nearestTo
                                                         user:(PELMUser *)user
                                                        error:(PELMDaoErrorBlk)errorBlk {
  __block RBodyMeasurementLog *bml = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bml = [self nearestBmlWithNonNilBodyWeightToDate:nearestTo user:user db:db error:errorBlk];
  }];
  return bml;
}

- (RBodyMeasurementLog *)nearestBmlWithNonNilBodyWeightToDate:(NSDate *)nearestTo
                                                         user:(PELMUser *)user
                                                           db:(FMDatabase *)db
                                                        error:(PELMDaoErrorBlk)errorBlk {
  RBodyMeasurementLog *nearestBml = nil;
  NSArray *bmlsLeadingUpTo = [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ is not null and %@ <= ? order by %@ desc",
                                                           TBL_MASTER_BODY_MEASUREMENT_LOG,
                                                           COL_MASTER_USER_ID,
                                                           COL_BML_BODY_WEIGHT,
                                                           COL_BML_LOGGED_AT,
                                                           COL_BML_LOGGED_AT]
                                               numAllowed:@(1)
                                                argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:nearestTo]]
                                              rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                                       db:db
                                                    error:errorBlk];
  NSArray *bmlsAfter = [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ is not null and %@ >= ? order by %@ desc",
                                                     TBL_MASTER_BODY_MEASUREMENT_LOG,
                                                     COL_MASTER_USER_ID,
                                                     COL_BML_BODY_WEIGHT,
                                                     COL_BML_LOGGED_AT,
                                                     COL_BML_LOGGED_AT]
                                         numAllowed:@(1)
                                          argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:nearestTo]]
                                        rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                                 db:db
                                              error:errorBlk];
  if (bmlsLeadingUpTo.count > 0) {
    if (bmlsAfter.count > 0) {
      NSDate *nearestLeadingUpToDate = ((RBodyMeasurementLog *)[bmlsLeadingUpTo lastObject]).loggedAt;
      NSDate *nearestAfterDate = ((RBodyMeasurementLog *)[bmlsAfter firstObject]).loggedAt;
      if ([nearestLeadingUpToDate secondsEarlierThan:nearestTo] < [nearestAfterDate secondsFrom:nearestTo]) {
        nearestBml = [bmlsLeadingUpTo lastObject];
      } else {
        nearestBml = [bmlsAfter firstObject];
      }
    } else {
      nearestBml = [bmlsLeadingUpTo lastObject];
    }
  } else if (bmlsAfter.count > 0) {
    nearestBml = [bmlsAfter firstObject];
  }
  return nearestBml;
}

- (NSArray *)unsyncedBmlsForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *bmls = @[];
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    bmls = [self unsyncedBmlsForUser:user db:db error:errorBlk];
  }];
  return bmls;
}

- (NSArray *)unsyncedBmlsForUser:(PELMUser *)user
                              db:(FMDatabase *)db
                           error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ = 0 order by %@ desc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_SYNCED,
                                       COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (void)saveNewBml:(RBodyMeasurementLog *)bml
           forUser:(PELMUser *)user
             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewBml:bml forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewBmls:(NSArray *)bmls forUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    for (RBodyMeasurementLog *bml in bmls) {
      [self saveNewBml:bml forUser:user db:db error:errorBlk];
    }
  }];
}

- (void)saveNewAndSyncImmediateBml:(RBodyMeasurementLog *)bml
                           forUser:(PELMUser *)user
                             error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [bml setSyncInProgress:YES];
    [self saveNewBml:bml forUser:user db:db error:errorBlk];
  }];
}

- (void)saveNewBml:(RBodyMeasurementLog *)bml
           forUser:(PELMUser *)user
                db:(FMDatabase *)db
             error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterBml:bml forUser:user db:db error:errorBlk];
}

- (void)saveBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils saveEntity:bml
                        updateStmt:[self updateStmtForMasterBml]
                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                             error:errorBlk];
}

- (void)markAsDoneEditingBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingEntity:bml
                                     updateStmt:[self updateStmtForMasterBml]
                                  updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                          error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncBml:(RBodyMeasurementLog *)bml error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils markAsDoneEditingImmediateSyncEntity:bml
                                                  updateStmt:[self updateStmtForMasterBml]
                                               updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                                       error:errorBlk];
}

- (NSArray *)markBmlsAsSyncInProgressForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  return [self.localModelUtils markEntitiesAsSyncInProgressInTable:TBL_MASTER_BODY_MEASUREMENT_LOG
                                               entityFromResultSet:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                                        updateStmt:[self updateStmtForMasterBml]
                                                     updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                           importLimitExceededMask:@(RSaveBmlImportLimitExceeded)
                                                              user:user
                                                     importedAtBlk:^NSDate * (RBodyMeasurementLog *bml) { return bml.importedAt; }
                                         hasExceededImportLimitBlk:^BOOL (PELMUser *user) {
                                           NSNumber *maxAllowedBmlImport = [user maxAllowedBmlImport];
                                           if (maxAllowedBmlImport) {
                                             return [self numSyncedImportedBmlsForUser:user
                                                                                 error:[RUtils localFetchErrorHandlerMaker]()] >= maxAllowedBmlImport.integerValue;
                                           }
                                           return NO;
                                         }
                                                             error:errorBlk];
}

- (void)cancelSyncForBml:(RBodyMeasurementLog *)bml
            httpRespCode:(NSNumber *)httpRespCode
               errorMask:(NSNumber *)errorMask
                 retryAt:(NSDate *)retryAt
                   error:(PELMDaoErrorBlk)errorBlk {
  [self.localModelUtils cancelSyncForEntity:bml
                               httpRespCode:httpRespCode
                                  errorMask:errorMask
                                    retryAt:retryAt
                                 updateStmt:[self updateStmtForMasterBml]
                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                      error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingMasterBml:(RBodyMeasurementLog *)bml
                                                forUser:(PELMUser *)user
                                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                                     db:(FMDatabase *)db
                                                  error:(PELMDaoErrorBlk)errorBlk {
  PELMSaveNewOrExistingCode returnCode =
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:bml
                                           masterTable:TBL_MASTER_BODY_MEASUREMENT_LOG
                                       masterInsertBlk:^(id entity, FMDatabase *db){[self insertIntoMasterBml:(RBodyMeasurementLog *)entity forUser:user db:db error:errorBlk];}
                                      masterUpdateStmt:[self updateStmtForMasterBml]
                                   masterUpdateArgsBlk:^NSArray * (RBodyMeasurementLog *theBml) { return [self updateArgsForMasterBml:theBml]; }
                                                    db:db
                                                 error:errorBlk];
  if (writeUserReadonlyFields) {
    [self saveMasterUser:user readOnlyFieldsEntity:bml db:db error:errorBlk];
  }
  return returnCode;
}

- (void)saveNewMasterBml:(RBodyMeasurementLog *)bml
                 forUser:(PELMUser *)user
 writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self insertIntoMasterBml:bml forUser:user db:db error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:bml db:db error:errorBlk];
    }
  }];
}

- (BOOL)saveMasterBml:(RBodyMeasurementLog *)bml
              forUser:(PELMUser *)user
writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                error:(PELMDaoErrorBlk)errorBlk {
  __block BOOL didDatabaseUpdate = NO;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:[self updateStmtForMasterBml]
              argsArray:[self updateArgsForMasterBml:bml]
                     db:db
                  error:errorBlk];
    didDatabaseUpdate = YES;
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:bml db:db error:errorBlk];
    }
  }];
  return didDatabaseUpdate;
}

- (void)markAsSyncCompleteForNewBml:(RBodyMeasurementLog *)bml
                            forUser:(PELMUser *)user
            writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                              error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self.localModelUtils markAsSyncCompleteForEntity:bml
                                     masterUpdateStmt:[self updateStmtForMasterBml]
                                  masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                                   db:db
                                                error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:bml db:db error:errorBlk];
    }
  }];
}

- (void)markAsSyncCompleteForUpdatedBml:(RBodyMeasurementLog *)bml
                                forUser:(PELMUser *)user
                writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                  error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self.localModelUtils markAsSyncCompleteForEntity:bml
                                     masterUpdateStmt:[self updateStmtForMasterBml]
                                  masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterBml:(RBodyMeasurementLog *)entity];}
                                                   db:db
                                                error:errorBlk];
    if (writeUserReadonlyFields) {
      [self saveMasterUser:user readOnlyFieldsEntity:bml db:db error:errorBlk];
    }
  }];
}

- (NSInteger)numBmlsWithUuid:(NSString *)uuid
                       error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numBmls = 0;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    numBmls = [PELMUtils numRowsFromTable:TBL_MASTER_BODY_MEASUREMENT_LOG
                                  equalTo:uuid
                            equalToColumn:COL_BML_UUID
                                       db:db
                                    error:errorBlk];
  }];
  return numBmls;
}

- (RBodyMeasurementLog *)mainBmlFromResultSet:(FMResultSet *)rs {
  return [[RBodyMeasurementLog alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                            localMasterIdentifier:nil // NA (this is a master store-only column)
                                                 globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                        mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                        relations:nil
                                                        createdAt:nil // NA (this is a master store-only column)
                                                        deletedAt:nil // NA (this is a master store-only column)
                                                        updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                             dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                                   editInProgress:[rs boolForColumn:COL_EDIT_IN_PROGRESS]
                                                   syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                           synced:[rs boolForColumn:COL_SYNCED]
                                                        editCount:[rs intForColumn:COL_EDIT_COUNT]
                                                 syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                                      syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                                      syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                                       bodyWeight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_BODY_WEIGHT]
                                                    bodyWeightUom:[PELMUtils numberFromResultSet:rs columnName:COL_BML_BODY_WEIGHT_UOM]
                                                          armSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_ARM_SIZE]
                                                         calfSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_CALF_SIZE]
                                                        chestSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_CHEST_SIZE]
                                                          sizeUom:[PELMUtils numberFromResultSet:rs columnName:COL_BML_SIZE_UOM]
                                                         neckSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_NECK_SIZE]
                                                        waistSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_WAIST_SIZE]
                                                        thighSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_THIGH_SIZE]
                                                      forearmSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_FOREARM_SIZE]
                                                         loggedAt:[PELMUtils dateFromResultSet:rs columnName:COL_BML_LOGGED_AT]
                                              originationDeviceId:[PELMUtils numberFromResultSet:rs columnName:COL_ORIGINATION_DEVICE_ID]
                                                       importedAt:[PELMUtils dateFromResultSet:rs columnName:COL_IMPORTED_AT]];
}

- (RBodyMeasurementLog *)masterBmlFromResultSet:(FMResultSet *)rs {
  return [[RBodyMeasurementLog alloc] initWithLocalMainIdentifier:nil // NA
                                            localMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                                 globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                        mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                        relations:nil
                                                        createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                        deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                        updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                             dateCopiedFromMaster:nil // NA
                                                   editInProgress:NO // NA
                                                   syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                           synced:[rs boolForColumn:COL_SYNCED]
                                                        editCount:0   //
                                                 syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                                      syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                                      syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                                       bodyWeight:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_BODY_WEIGHT]
                                                    bodyWeightUom:[PELMUtils numberFromResultSet:rs columnName:COL_BML_BODY_WEIGHT_UOM]
                                                          armSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_ARM_SIZE]
                                                         calfSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_CALF_SIZE]
                                                        chestSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_CHEST_SIZE]
                                                          sizeUom:[PELMUtils numberFromResultSet:rs columnName:COL_BML_SIZE_UOM]
                                                         neckSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_NECK_SIZE]
                                                        waistSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_WAIST_SIZE]
                                                        thighSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_THIGH_SIZE]
                                                      forearmSize:[PELMUtils decimalNumberFromResultSet:rs columnName:COL_BML_FOREARM_SIZE]
                                                         loggedAt:[PELMUtils dateFromResultSet:rs columnName:COL_BML_LOGGED_AT]
                                              originationDeviceId:[PELMUtils numberFromResultSet:rs columnName:COL_ORIGINATION_DEVICE_ID]
                                                       importedAt:[PELMUtils dateFromResultSet:rs columnName:COL_IMPORTED_AT]];
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at desc, updated_at desc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG, COL_MASTER_USER_ID]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user pageSize:(NSInteger)pageSize db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by logged_at desc, updated_at desc limit %ld",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG, COL_MASTER_USER_ID, (long)pageSize]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)descendingBmlsForUser:(PELMUser *)user
                    beforeLoggedAt:(NSDate *)beforeLoggedAt
                          pageSize:(NSInteger)pageSize
                                db:(FMDatabase *)db
                             error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ < ? order by %@ desc limit %ld",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_LOGGED_AT,
                                       COL_BML_LOGGED_AT,
                                       (long)pageSize]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:beforeLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? order by %@ asc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG, COL_MASTER_USER_ID, COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ is not null order by %@ asc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_BODY_WEIGHT,
                                       COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingBmlsWithNonNilBodyWeightForUser:(PELMUser *)user loggedSince:(NSDate *)loggedSince db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ is not null and %@ > ? order by %@ asc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_BODY_WEIGHT,
                                       COL_BML_LOGGED_AT,
                                       COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier, [PEUtils millisecondsFromDate:loggedSince]]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
               onOrBeforeLoggedAt:(NSDate *)onOrBeforeLoggedAt
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ >= ? AND %@ <= ? order by %@ asc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_LOGGED_AT,
                                       COL_BML_LOGGED_AT,
                                       COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier,
                                        [PEUtils millisecondsFromDate:onOrAfterLoggedAt],
                                        [PEUtils millisecondsFromDate:onOrBeforeLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (NSArray *)ascendingBmlsForUser:(PELMUser *)user
                onOrAfterLoggedAt:(NSDate *)onOrAfterLoggedAt
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:[NSString stringWithFormat:@"select * from %@ where %@ = ? and %@ >= ? order by %@ asc",
                                       TBL_MASTER_BODY_MEASUREMENT_LOG,
                                       COL_MASTER_USER_ID,
                                       COL_BML_LOGGED_AT,
                                       COL_BML_LOGGED_AT]
                            argsArray:@[user.localMasterIdentifier,
                                        [PEUtils millisecondsFromDate:onOrAfterLoggedAt]]
                          rsConverter:^(FMResultSet *rs){return [self masterBmlFromResultSet:rs];}
                                   db:db
                                error:errorBlk];
}

- (void)deleteBmlsOfUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSArray *bmls = [self descendingBmlsForUser:user db:db error:errorBlk];
  for (RBodyMeasurementLog *bml in bmls) {
    [self deleteBml:bml db:db error:errorBlk];
  }
}

- (void)insertIntoMasterBml:(RBodyMeasurementLog *)bml
                    forUser:(PELMUser *)user
                         db:(FMDatabase *)db
                      error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_MASTER_BODY_MEASUREMENT_LOG,
                    COL_MASTER_USER_ID,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_BML_LOGGED_AT,
                    COL_BML_BODY_WEIGHT,
                    COL_BML_BODY_WEIGHT_UOM,
                    COL_BML_ARM_SIZE,
                    COL_BML_CALF_SIZE,
                    COL_BML_CHEST_SIZE,
                    COL_BML_NECK_SIZE,
                    COL_BML_WAIST_SIZE,
                    COL_BML_THIGH_SIZE,
                    COL_BML_FOREARM_SIZE,
                    COL_BML_SIZE_UOM,
                    COL_ORIGINATION_DEVICE_ID,
                    
                    COL_SYNC_IN_PROGRESS,
                    COL_SYNCED,
                    COL_SYNC_HTTP_RESP_CODE,
                    COL_SYNC_ERR_MASK,
                    COL_SYNC_RETRY_AT,
                    COL_BML_UUID,
                    
                    COL_IMPORTED_AT];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([bml localMasterIdentifier]),
                              orNil([bml globalIdentifier]),
                              orNil([[bml mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[bml createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[bml updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[bml deletedAt]]),
                              
                              orNil([PEUtils millisecondsFromDate:[bml loggedAt]]),
                              orNil([bml bodyWeight]),
                              orNil([bml bodyWeightUom]),
                              orNil([bml armSize]),
                              orNil([bml calfSize]),
                              orNil([bml chestSize]),
                              orNil([bml neckSize]),
                              orNil([bml waistSize]),
                              orNil([bml thighSize]),
                              orNil([bml forearmSize]),
                              orNil([bml sizeUom]),
                              orNil([bml originationDeviceId]),
                              [NSNumber numberWithBool:[bml syncInProgress]],
                              [NSNumber numberWithBool:[bml synced]],
                              orNil([bml syncHttpRespCode]),
                              orNil([bml syncErrMask]),
                              orNil([PEUtils millisecondsFromDate:[bml syncRetryAt]]),
                              orNil([bml uuid]),
                              orNil([PEUtils millisecondsFromDate:[bml importedAt]])]
                     entity:bml
                         db:db
                      error:errorBlk];
}

- (NSString *)updateStmtForMasterBml {
  return [NSString stringWithFormat:@"UPDATE %@ set \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_BODY_MEASUREMENT_LOG,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_BML_LOGGED_AT,
          COL_BML_BODY_WEIGHT,
          COL_BML_BODY_WEIGHT_UOM,
          COL_BML_ARM_SIZE,
          COL_BML_CALF_SIZE,
          COL_BML_CHEST_SIZE,
          COL_BML_NECK_SIZE,
          COL_BML_WAIST_SIZE,
          COL_BML_THIGH_SIZE,
          COL_BML_FOREARM_SIZE,
          COL_BML_SIZE_UOM,
          COL_ORIGINATION_DEVICE_ID,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_BML_UUID,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterBml:(RBodyMeasurementLog *)bml {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([bml globalIdentifier]),
           orNil([[bml mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[bml createdAt]]),
           orNil([PEUtils millisecondsFromDate:[bml updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[bml deletedAt]]),
           orNil([PEUtils millisecondsFromDate:[bml loggedAt]]),
           orNil([bml bodyWeight]),
           orNil([bml bodyWeightUom]),
           orNil([bml armSize]),
           orNil([bml calfSize]),
           orNil([bml chestSize]),
           orNil([bml neckSize]),
           orNil([bml waistSize]),
           orNil([bml thighSize]),
           orNil([bml forearmSize]),
           orNil([bml sizeUom]),
           orNil([bml originationDeviceId]),
           [NSNumber numberWithBool:[bml syncInProgress]],
           [NSNumber numberWithBool:[bml synced]],
           orNil([bml syncHttpRespCode]),
           orNil([bml syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[bml syncRetryAt]]),
           orNil([bml uuid]),
           [bml localMasterIdentifier]];
}

#pragma mark - Chart Config

- (RChartConfig *)chartConfigWithChartId:(NSString *)chartId
                                    user:(PELMUser *)user
                                   error:(PELMDaoErrorBlk)errorBlk {
  __block RChartConfig *chartConfig = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    chartConfig = [self chartConfigWithChartId:chartId user:user db:db error:errorBlk];
  }];
  return chartConfig;
}

- (RChartConfig *)chartConfigWithChartId:(NSString *)chartId
                                    user:(PELMUser *)user
                                      db:(FMDatabase *)db
                                   error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? and %@ = ?",
                                     TBL_CHART_CONFIG,
                                     COL_CHART_CONFIG_CHART_ID,
                                     COL_MASTER_USER_ID]
                          argsArray:@[chartId, user.localMasterIdentifier]
                        rsConverter:^(FMResultSet *rs) { return [self chartConfigFromResultSet:rs]; }
                                 db:db
                              error:errorBlk];
}

- (void)deleteChartConfigsByCategory:(RChartConfigCategory)category
                                user:(PELMUser *)user
                               error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteChartConfigsByCategory:category user:user db:db error:errorBlk];
  }];
}

- (void)deleteChartConfigsForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
   [self deleteChartCacheForUser:user db:db error:errorBlk];
  [PELMUtils deleteFromTable:TBL_CHART_CONFIG
                whereColumns:@[COL_MASTER_USER_ID]
                 whereValues:@[user.localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)deleteChartConfigsByCategory:(RChartConfigCategory)category user:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [self deleteChartCacheForUser:user category:category db:db error:errorBlk];
  [PELMUtils deleteFromTable:TBL_CHART_CONFIG
                whereColumns:@[COL_CHART_CONFIG_CATEGORY, COL_MASTER_USER_ID]
                 whereValues:@[@(category), user.localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (void)deleteChartConfigByChartId:(NSString *)chartId user:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteChartConfigByChartId:chartId user:user db:db error:errorBlk];
  }];
}

- (void)deleteChartConfigByChartId:(NSString *)chartId user:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [self deleteChartCacheForUser:user chartId:chartId db:db error:errorBlk];
  [PELMUtils deleteFromTable:TBL_CHART_CONFIG
                whereColumns:@[COL_CHART_CONFIG_CHART_ID, COL_MASTER_USER_ID]
                 whereValues:@[chartId, user.localMasterIdentifier]
                          db:db
                       error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingByChartIdChartConfig:(RChartConfig *)chartConfig
                                                           forUser:(PELMUser *)user
                                                             error:(PELMDaoErrorBlk)errorBlk {
  __block PELMSaveNewOrExistingCode returnVal;
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnVal = [self saveNewOrExistingByChartIdChartConfig:chartConfig forUser:user db:db error:errorBlk];
  }];
  return returnVal;
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingByChartIdChartConfig:(RChartConfig *)chartConfig
                                                           forUser:(PELMUser *)user
                                                                db:(FMDatabase *)db
                                                             error:(PELMDaoErrorBlk)errorBlk {
  [self deleteChartCacheForUser:user chartId:chartConfig.chartId db:db error:errorBlk];
  return
  [PELMUtils saveNewOrExistingEntity:chartConfig
                         masterTable:TBL_CHART_CONFIG
                     masterInsertBlk:^(RChartConfig *theChartConfig, FMDatabase *db) {
                       [self insertIntoChartConfig:theChartConfig forUser:user db:db error:errorBlk];
                     }
                    masterUpdateStmt:[self updateStmtForChartConfig]
                 masterUpdateArgsBlk:^NSArray * (RChartConfig *theChartConfig) {
                   return [self updateArgsForChartConfig:theChartConfig];
                 }
                       idSearcherBlk:^ NSNumber * (NSString *table, PELMMasterSupport *masterEntity) {
                         return [PELMUtils numberFromTable:table
                                              selectColumn:COL_LOCAL_ID
                                               whereColumn:COL_CHART_CONFIG_CHART_ID
                                                whereValue:((RChartConfig *)masterEntity).chartId
                                                        db:db
                                                     error:errorBlk];
                       }
                                  db:db
                               error:errorBlk];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingByGlobalIdentifierChartConfig:(RChartConfig *)chartConfig
                                                                    forUser:(PELMUser *)user
                                                                         db:(FMDatabase *)db
                                                                      error:(PELMDaoErrorBlk)errorBlk {
  [self deleteChartCacheForUser:user chartId:chartConfig.chartId db:db error:errorBlk];
  return
  [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:chartConfig
                                           masterTable:TBL_CHART_CONFIG
                                       masterInsertBlk:^(RChartConfig *theChartConfig, FMDatabase *db) {
                                         [self insertIntoChartConfig:theChartConfig forUser:user db:db error:errorBlk];
                                       }
                                      masterUpdateStmt:[self updateStmtForChartConfig]
                                   masterUpdateArgsBlk:^NSArray * (RChartConfig *theChartConfig) {
                                     return [self updateArgsForChartConfig:theChartConfig];
                                   }
                                                    db:db
                                                 error:errorBlk];
}

- (NSString *)updateStmtForChartConfig {
  return [NSString stringWithFormat:@"UPDATE %@ SET \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ?, \
          %@ = ? \
          WHERE %@ = ?", TBL_CHART_CONFIG,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          
          COL_CHART_CONFIG_CHART_ID,
          COL_CHART_CONFIG_CATEGORY,
          COL_CHART_CONFIG_START_DATE,
          COL_CHART_CONFIG_END_DATE,
          COL_CHART_CONFIG_BOUNDED_END_DATE,
          COL_CHART_CONFIG_AGGREGATE_BY,
          COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS,
          
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForChartConfig:(RChartConfig *)chartConfig {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([chartConfig globalIdentifier]),
           orNil([[chartConfig mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[chartConfig createdAt]]),
           orNil([PEUtils millisecondsFromDate:[chartConfig updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[chartConfig deletedAt]]),
           orNil([chartConfig chartId]),
           @(chartConfig.category),
           orNil([PEUtils millisecondsFromDate:[chartConfig startDate]]),
           orNil([PEUtils millisecondsFromDate:[chartConfig endDate]]),
           [NSNumber numberWithBool:[chartConfig boundedEndDate]],
           orNil([chartConfig aggregateBy]),
           [NSNumber numberWithBool:[chartConfig suppressPieSliceLabels]],
           [NSNumber numberWithBool:[chartConfig syncInProgress]],
           [NSNumber numberWithBool:[chartConfig synced]],
           orNil([chartConfig syncHttpRespCode]),
           orNil([chartConfig syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[chartConfig syncRetryAt]]),
           [chartConfig localMasterIdentifier]];
}

- (void)insertIntoChartConfig:(RChartConfig *)chartConfig
                      forUser:(PELMUser *)user
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (\
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    \
                    %@, \
                    %@, \
                    %@, \
                    %@, \
                    %@) VALUES (\
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    \
                    ?, \
                    ?, \
                    ?, \
                    ?, \
                    ?)", TBL_CHART_CONFIG,
                    COL_MASTER_USER_ID,
                    COL_LOCAL_ID,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    
                    COL_CHART_CONFIG_CHART_ID,
                    COL_CHART_CONFIG_CATEGORY,
                    COL_CHART_CONFIG_START_DATE,
                    COL_CHART_CONFIG_END_DATE,
                    COL_CHART_CONFIG_BOUNDED_END_DATE,
                    COL_CHART_CONFIG_AGGREGATE_BY,
                    COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS,
                    COL_IMPORTED_AT,
                    
                    COL_SYNC_IN_PROGRESS,
                    COL_SYNCED,
                    COL_SYNC_HTTP_RESP_CODE,
                    COL_SYNC_ERR_MASK,
                    COL_SYNC_RETRY_AT];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user localMasterIdentifier]),
                              orNil([chartConfig localMasterIdentifier]),
                              orNil([chartConfig globalIdentifier]),
                              orNil([[chartConfig mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[chartConfig createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[chartConfig updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[chartConfig deletedAt]]),
                              
                              orNil([chartConfig chartId]),
                              @(chartConfig.category),
                              orNil([PEUtils millisecondsFromDate:[chartConfig startDate]]),
                              orNil([PEUtils millisecondsFromDate:[chartConfig endDate]]),
                              [NSNumber numberWithBool:[chartConfig boundedEndDate]],
                              orNil([chartConfig aggregateBy]),
                              [NSNumber numberWithBool:[chartConfig suppressPieSliceLabels]],
                              orNil([PEUtils millisecondsFromDate:[chartConfig importedAt]]),
                              
                              [NSNumber numberWithBool:[chartConfig syncInProgress]],
                              [NSNumber numberWithBool:[chartConfig synced]],
                              orNil([chartConfig syncHttpRespCode]),
                              orNil([chartConfig syncErrMask]),
                              orNil([PEUtils millisecondsFromDate:[chartConfig syncRetryAt]])]
                     entity:chartConfig
                         db:db
                      error:errorBlk];
}

- (RChartConfig *)chartConfigFromResultSet:(FMResultSet *)rs {
  return [[RChartConfig alloc] initWithLocalMainIdentifier:nil // NA (this is a main store-only column)
                                     localMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                          globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                 mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                 relations:nil
                                                 createdAt:[PELMUtils dateFromResultSet:rs columnName:COL_CREATED_AT]
                                                 deletedAt:[PELMUtils dateFromResultSet:rs columnName:COL_DELETED_DT]
                                                 updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_UPDATED_AT]
                                      dateCopiedFromMaster:nil // NA
                                            editInProgress:NO // NA
                                            syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                    synced:[rs boolForColumn:COL_SYNCED]
                                                 editCount:0   // NA
                                          syncHttpRespCode:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_HTTP_RESP_CODE]
                                               syncErrMask:[PELMUtils numberFromResultSet:rs columnName:COL_SYNC_ERR_MASK]
                                               syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]
                                                   chartId:[rs stringForColumn:COL_CHART_CONFIG_CHART_ID]
                                                  category:[rs intForColumn:COL_CHART_CONFIG_CATEGORY]
                                                 startDate:[PELMUtils dateFromResultSet:rs columnName:COL_CHART_CONFIG_START_DATE]
                                                   endDate:[PELMUtils dateFromResultSet:rs columnName:COL_CHART_CONFIG_END_DATE]
                                            boundedEndDate:[PELMUtils boolFromResultSet:rs columnName:COL_CHART_CONFIG_BOUNDED_END_DATE boolIfNull:NO]
                                    aggregateBy:[PELMUtils numberFromResultSet:rs columnName:COL_CHART_CONFIG_AGGREGATE_BY]
                                    suppressPieSliceLabels:[PELMUtils boolFromResultSet:rs columnName:COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS boolIfNull:NO]
                                                importedAt:[PELMUtils dateFromResultSet:rs columnName:COL_CHART_CONFIG_END_DATE]];
}

#pragma mark - Chart Cache

- (void)deleteChartCacheForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteChartCacheForUser:user db:db error:errorBlk];
  }];
}

- (void)deleteChartCacheForUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  void (^deleteChartData)(NSString *) = ^(NSString *table) {
    [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ?", table, COL_MASTER_USER_ID]
              argsArray:@[user.localMasterIdentifier]
                     db:db
                  error:errorBlk];
  };
  deleteChartData(TBL_CHART_TIME_SERIES_DATA_POINT);
  deleteChartData(TBL_CHART_TIME_SERIES);
  deleteChartData(TBL_CHART);
}

- (void)deleteChartCacheForUser:(PELMUser *)user
                        chartId:(NSString *)chartId
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk {
  NSNumber *chartLocalId = [PELMUtils numberFromTable:TBL_CHART
                                         selectColumn:COL_LOCAL_ID
                                          whereColumn:COL_CHART_CHART_ID
                                           whereValue:chartId
                                                   db:db
                                                error:errorBlk];
  if (chartLocalId) {
    NSArray *argsArray = @[user.localMasterIdentifier, chartLocalId];
    void (^deleteChartData)(NSString *, NSString *) = ^(NSString *table, NSString *chartLocalIdCol) {
      [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ? and %@ = ?",
                           table,
                           COL_MASTER_USER_ID,
                           chartLocalIdCol]
                argsArray:argsArray
                       db:db
                    error:errorBlk];
    };
    deleteChartData(TBL_CHART_TIME_SERIES_DATA_POINT, COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID);
    deleteChartData(TBL_CHART_TIME_SERIES, COL_CHART_TIME_SERIES_CHART_ID);
    deleteChartData(TBL_CHART, COL_LOCAL_ID);
  }
}

- (void)deleteChartCacheForUser:(PELMUser *)user
                       category:(RChartConfigCategory)category
                             db:(FMDatabase *)db
                          error:(PELMDaoErrorBlk)errorBlk {
  NSArray *chartLocalIds =
  [PELMUtils numberArrayFromQuery:[NSString stringWithFormat:@"select %@ from %@ where %@ = ? and %@ = ?",
                                   COL_LOCAL_ID, TBL_CHART, COL_MASTER_USER_ID, COL_CHART_CATEGORY]
                             args:@[user.localMasterIdentifier, @(category)]
                               db:db
                            error:errorBlk];
  NSInteger numChartLocalIds = chartLocalIds.count;
  if (numChartLocalIds > 0) {
    NSMutableString *chartLocalIdsStr = [[NSMutableString alloc] init];
    for (int i = 0; i < numChartLocalIds; i++) {
      [chartLocalIdsStr appendFormat:@"%@", chartLocalIds[i]];
      if (i + 1 < numChartLocalIds) {
        [chartLocalIdsStr appendString:@","];
      }
    }
    NSArray *argsArray = @[user.localMasterIdentifier];
    void (^deleteChartData)(NSString *, NSString *) = ^(NSString *table, NSString *chartLocalIdCol) {      
      [PELMUtils doUpdate:[NSString stringWithFormat:@"delete from %@ where %@ = ? and %@ in (%@)",
                           table,
                           COL_MASTER_USER_ID,
                           chartLocalIdCol,
                           chartLocalIdsStr]
                argsArray:argsArray
                       db:db
                    error:errorBlk];
    };
    deleteChartData(TBL_CHART_TIME_SERIES_DATA_POINT, COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID);
    deleteChartData(TBL_CHART_TIME_SERIES, COL_CHART_TIME_SERIES_CHART_ID);
    deleteChartData(TBL_CHART, COL_LOCAL_ID);
  }
}

- (void)saveLineChartDataCacheWithChartData:(LineChartData *)lineChartData
                                    chartId:(NSString *)chartId
                              chartConfigId:(NSNumber *)chartConfigId
                                   category:(RChartConfigCategory)category
                                aggregateBy:(RChartConfigAggregateBy)aggregateBy
                            xaxisLabelCount:(NSInteger)xaxisLabelCount
                                   maxValue:(NSDecimalNumber *)maxValue
                                       user:(PELMUser *)user
                                      error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteChartCacheForUser:user chartId:chartId db:db error:errorBlk];
    PELMOrNil orNil = [PELMUtils makeOrNil];
    [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ (%@, %@, %@, %@, %@, %@, %@) values (?, ?, ?, ?, ?, ?, ?)",
                         TBL_CHART,
                         COL_MASTER_USER_ID,
                         COL_CHART_CHART_ID,
                         COL_CHART_CATEGORY,
                         COL_CHART_CONFIG_ID,
                         COL_CHART_AGGREGATE_BY,
                         COL_CHART_XAXIS_LABEL_COUNT,
                         COL_CHART_MAX_VALUE]
              argsArray:@[user.localMasterIdentifier, chartId, @(category), orNil(chartConfigId), @(aggregateBy), @(xaxisLabelCount), maxValue]
                     db:db
                  error:errorBlk];
    NSNumber *chartLocalId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
    NSArray *dataSets = lineChartData.dataSets;
    NSInteger numDataSets = dataSets.count;
    for (int i = 0; i < numDataSets; i++) {
      LineChartDataSet *dataSet = dataSets[i];
      [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ (%@, %@, %@, %@) values (?, ?, ?, ?)",
                           TBL_CHART_TIME_SERIES,
                           COL_MASTER_USER_ID,
                           COL_CHART_TIME_SERIES_CHART_ID,
                           COL_CHART_TIME_SERIES_LABEL,
                           COL_CHART_TIME_SERIES_ENTITY_LMID]
                argsArray:@[user.localMasterIdentifier, chartLocalId, dataSet.label, dataSet.entityLocalMasterIdentifier]
                       db:db
                    error:errorBlk];
      NSNumber *dataSetLocalId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
      NSArray *chartDataEntryValues = dataSet.values;
      NSInteger numValues = chartDataEntryValues.count;
      for (int j = 0; j < numValues; j++) {
        ChartDataEntry *dataEntry = chartDataEntryValues[j];
        [PELMUtils doUpdate:[NSString stringWithFormat:@"insert into %@ (%@, %@, %@, %@, %@) values (?, ?, ?, ?, ?)",
                             TBL_CHART_TIME_SERIES_DATA_POINT,
                             COL_MASTER_USER_ID,
                             COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID,
                             COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID,
                             COL_CHART_TIME_SERIES_DATA_POINT_DATE,
                             COL_CHART_TIME_SERIES_DATA_POINT_VALUE]
                  argsArray:@[user.localMasterIdentifier,
                              chartLocalId,
                              dataSetLocalId,
                              @(dataEntry.x),
                              @(dataEntry.y)]
                         db:db
                      error:errorBlk];
      }
    }
  }];
  DDLogInfo(@"Chart cache saved for chart ID: [%@]", chartId);
}

- (RLineChartDataCache *)lineChartDataCacheForChartId:(NSString *)chartId
                                        chartConfigId:(NSNumber *)chartConfigId
                                                 user:(PELMUser *)user
                                                error:(PELMDaoErrorBlk)errorBlk {
  __block RLineChartDataCache *lineChartDataCache = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSMutableArray *queryArgs = [NSMutableArray arrayWithCapacity:3];
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendFormat:@"select * from %@ where %@ = ? and %@ = ?", TBL_CHART, COL_MASTER_USER_ID, COL_CHART_CHART_ID];
    [queryArgs addObject:user.localMasterIdentifier];
    [queryArgs addObject:chartId];
    if (chartConfigId) {
      [query appendFormat:@" and %@ = ?", COL_CHART_CONFIG_ID];
      [queryArgs addObject:chartConfigId];
    }
    FMResultSet *rs = [PELMUtils doQuery:query argsArray:queryArgs db:db error:errorBlk];
    NSNumber *chartLocalId;
    while ([rs next]) {
      lineChartDataCache = [[RLineChartDataCache alloc] init];
      chartLocalId = [PELMUtils numberFromResultSet:rs columnName:COL_LOCAL_ID];
      lineChartDataCache.lineChartData = [[LineChartData alloc] init];
      lineChartDataCache.maxValue = [PELMUtils decimalNumberFromResultSet:rs columnName:COL_CHART_MAX_VALUE];
      lineChartDataCache.xaxisLabelCount = [rs intForColumn:COL_CHART_XAXIS_LABEL_COUNT];
      lineChartDataCache.aggregateBy = [rs intForColumn:COL_CHART_AGGREGATE_BY];
    }
    [rs close];
    if (lineChartDataCache) {
      NSMutableArray *dataSets = [NSMutableArray array];
      rs = [PELMUtils doQuery:[NSString stringWithFormat:@"select %@, %@, %@ from %@ where %@ = ?",
                               COL_LOCAL_ID,
                               COL_CHART_TIME_SERIES_ENTITY_LMID,
                               COL_CHART_TIME_SERIES_LABEL,
                               TBL_CHART_TIME_SERIES,
                               COL_CHART_TIME_SERIES_CHART_ID]
                    argsArray:@[chartLocalId]
                           db:db
                        error:errorBlk];
      while ([rs next]) {
        LineChartDataSet *dataSet = [[LineChartDataSet alloc] init];
        dataSet.localId = [PELMUtils numberFromResultSet:rs columnName:COL_LOCAL_ID];
        dataSet.label = [rs stringForColumn:COL_CHART_TIME_SERIES_LABEL];
        dataSet.entityLocalMasterIdentifier = [PELMUtils numberFromResultSet:rs columnName:COL_CHART_TIME_SERIES_ENTITY_LMID];
        [dataSets addObject:dataSet];
      }
      [rs close];
      for (LineChartDataSet *dataSet in dataSets) {
        NSMutableArray *dataPoints = [NSMutableArray array];
        rs = [PELMUtils doQuery:[NSString stringWithFormat:@"select %@, %@ from %@ where %@ = ? order by %@ asc",
                                 COL_CHART_TIME_SERIES_DATA_POINT_DATE,
                                 COL_CHART_TIME_SERIES_DATA_POINT_VALUE,
                                 TBL_CHART_TIME_SERIES_DATA_POINT,
                                 COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID,
                                 COL_CHART_TIME_SERIES_DATA_POINT_DATE]
                      argsArray:@[dataSet.localId]
                             db:db
                          error:errorBlk];
        while ([rs next]) {
          [dataPoints addObject:[[ChartDataEntry alloc] initWithX:[rs doubleForColumn:COL_CHART_TIME_SERIES_DATA_POINT_DATE]
                                                                y:[rs doubleForColumn:COL_CHART_TIME_SERIES_DATA_POINT_VALUE]]];
        }
        [rs close];
        [dataSet setValues:dataPoints];
      }
      [lineChartDataCache.lineChartData setDataSets:dataSets];
    }
  }];
  return lineChartDataCache;
}

@end
