//
//  PELMUtils.m
//

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>
#import <DateTools/DateTools.h>
@import Crashlytics;

#import "HCResource.h"
#import "HCMediaType.h"
#import "HCRelation.h"
#import "PEUtils.h"

#import "PELMUtils.h"
#import "PELMDDL.h"
#import "PELMNotificationUtils.h"
#import "PELMMainSupport.h"
#import "PELMNotificationNames.h"
#import "PELMUser.h"

#ifdef RIKER_DEV
NSString * const GLOBAL_IDENTIFIER_PREFIX = @"https://dev.rikerapp.com";
#else
NSString * const GLOBAL_IDENTIFIER_PREFIX = @"https://www.rikerapp.com";
#endif

PELMMainSupport * (^toMainSupport)(FMResultSet *, NSString *, NSDictionary *) = ^PELMMainSupport *(FMResultSet *rs, NSString *mainTable, NSDictionary *relations) {
  return [[PELMMainSupport alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                        localMasterIdentifier:nil // NA (this is a master entity-only column)
                                             globalIdentifier:[rs stringForColumn:COL_GLOBAL_ID]
                                                    mediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_MEDIA_TYPE]]
                                                    relations:relations
                                                    createdAt:nil // NA (this is a master entity-only column)
                                                    deletedAt:nil // NA (this is a master entity-only column)
                                                    updatedAt:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_MASTER_UPDATED_AT]
                                         dateCopiedFromMaster:[PELMUtils dateFromResultSet:rs columnName:COL_MAN_DT_COPIED_DOWN_FROM_MASTER]
                                               editInProgress:NO // NA
                                               syncInProgress:[rs boolForColumn:COL_SYNC_IN_PROGRESS]
                                                       synced:[rs boolForColumn:COL_SYNCED]
                                                    editCount:[rs intForColumn:COL_EDIT_COUNT]
                                             syncHttpRespCode:[rs objectForColumn:COL_SYNC_HTTP_RESP_CODE]
                                                  syncErrMask:[rs objectForColumn:COL_SYNC_ERR_MASK]
                                                  syncRetryAt:[PELMUtils dateFromResultSet:rs columnName:COL_SYNC_RETRY_AT]];
};

@implementation PELMUtils

#pragma mark - Initializers

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
  self = [super init];
  if (self) {
    _databaseQueue = databaseQueue;
  }
  return self;
}

#pragma mark - Notifications

+ (void)postDbUpdateNotification {
  [[NSNotificationCenter defaultCenter] postNotificationName:PELMNotificationDbUpdate object:self];
}

#pragma mark - Completion Handler Makers

+ (PELMRemoteMasterCompletionHandler)complHandlerToFlushUnsyncedChangesToEntity:(PELMMainSupport *)entity
                                                            remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                                              entityNotFoundBlk:(void(^)(void))entityNotFoundBlk
                                              markAsSyncCompleteForNewEntityBlk:(void(^)(id))markAsSyncCompleteForNewEntityBlk
                                         markAsSyncCompleteForExistingEntityBlk:(void(^)(id))markAsSyncCompleteForExistingEntityBlk
                                                                newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk {
  void (^successfulSync)(PELMMainSupport *, BOOL) = ^(PELMMainSupport *respEntity, BOOL wasPut) {
    if (respEntity) {
      NSString *unsyncedEntityGlobalId = [entity globalIdentifier];
      [entity overwrite:respEntity];
      if (wasPut) {
        // we do this because, in an HTTP PUT, the typical response is 200,
        // and, with 200, the "location" header is usually absent; this means
        // that the entity parsed from the response will have its 'globalIdentifier'
        // property empty.  Well, we want to keep our existing global identity
        // property, so, we have to re-set it onto unsyncedEntity after doing
        // the "overwrite" step above
        [entity setGlobalIdentifier:unsyncedEntityGlobalId];
      }
    }
    if (wasPut) {
      markAsSyncCompleteForExistingEntityBlk(entity);
    } else {
      markAsSyncCompleteForNewEntityBlk(entity);
    }
  };
  return ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
           NSDate *lastModified, BOOL gone, BOOL notFound, BOOL movedPermanently,
           BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    newAuthTokenBlk(newAuthTkn);
    if (gone) {
      entityNotFoundBlk(); // weird - this should not happen on a POST
    } else if (notFound) {
      entityNotFoundBlk(); // weird - this should not happen on a POST
    } else if (notModified) {
      // this is only relevant on a GET
    } else if (err) {
      if (httpResp) { // will deduce that error is from server
        remoteStoreErrorBlk(err, [NSNumber numberWithInteger:[httpResp statusCode]]);
      } else {  // will deduce that error is connecton-related
        remoteStoreErrorBlk(err, nil);
      }
    } else {
      successfulSync(resourceModel, httpResp.statusCode == 200); // 200 = PUT, 201 = POST
    }
  };
}

+ (PELMRemoteMasterCompletionHandler)complHandlerToDeleteEntity:(PELMMainSupport *)entity
                                            remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                              entityNotFoundBlk:(void(^)(void))entityNotFoundBlk
                                               deleteSuccessBlk:(void(^)(void))deleteSuccessBlk
                                                newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *globalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    newAuthTokenBlk(newAuthTkn);
    if (movedPermanently) {
      [entity setGlobalIdentifier:globalId];
    } else if (gone) {
      entityNotFoundBlk();
    } else if (notFound) {
      entityNotFoundBlk();
    } else if (notModified) {
      // should not happen since we're doing a DELETE
    } else if (err) {
      if (httpResp) { // will deduce that error is from server
        remoteStoreErrorBlk(err, [NSNumber numberWithInteger:[httpResp statusCode]]);
      } else {  // will deduce that error is connecton-related
        remoteStoreErrorBlk(err, nil);
      }
    } else {
      deleteSuccessBlk();
    }
  };
  return remoteStoreComplHandler;
}

+ (PELMRemoteMasterCompletionHandler)complHandlerToFetchEntityWithGlobalId:(NSString *)globalId
                                                       remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                                         entityNotFoundBlk:(void(^)(void))entityNotFoundBlk
                                                          fetchCompleteBlk:(void(^)(id))fetchCompleteBlk
                                                           newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  ^(NSString *newAuthTkn, NSString *relativeGlobalId, id resourceModel, NSDictionary *rels,
    NSDate *lastModified, BOOL gone, BOOL notFound, BOOL movedPermanently,
    BOOL notModified, NSError *err, NSHTTPURLResponse *httpResp) {
    newAuthTokenBlk(newAuthTkn);
    if (movedPermanently) { // this block will get executed again
      // ?
    } else if (gone) {
      entityNotFoundBlk();
    } else if (notFound) {
      entityNotFoundBlk();
    } else if (err) {
      if (httpResp) { // will deduce that error is from server
        remoteStoreErrorBlk(err, [NSNumber numberWithInteger:[httpResp statusCode]]);
      } else {  // will deduce that error is connecton-related
        remoteStoreErrorBlk(err, nil);
      }
    } else {
      [resourceModel setGlobalIdentifier:globalId];
      fetchCompleteBlk(resourceModel);
    }
  };
  return remoteStoreComplHandler;
}

+ (void)cancelSyncInProgressForEntityTable:(NSString *)entityTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)error {
  [db executeUpdate:[NSString stringWithFormat:@"UPDATE %@ SET %@ = 0", entityTable, COL_SYNC_IN_PROGRESS]];
  [PELMUtils postDbUpdateNotification];
}

#pragma mark - Result Set Helpers

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs
                       columnName:(NSString *)columnName {
  return [PEUtils nullSafeNumberFromString:[rs stringForColumn:columnName]];
}

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs
                      columnIndex:(int)columnIndex {
  return [PEUtils nullSafeNumberFromString:[rs stringForColumnIndex:columnIndex]];
}

+ (NSDecimalNumber *)decimalNumberFromResultSet:(FMResultSet *)rs
                                     columnName:(NSString *)columnName {
  return [PEUtils nullSafeDecimalNumberFromString:[rs stringForColumn:columnName]];
}

+ (NSDecimalNumber *)decimalNumberFromResultSet:(FMResultSet *)rs
                                    columnIndex:(int)columnIndex {
  return [PEUtils nullSafeDecimalNumberFromString:[rs stringForColumnIndex:columnIndex]];
}

+ (NSDate *)dateFromResultSet:(FMResultSet *)rs
                    isNullBlk:(BOOL(^)(FMResultSet *))isNullBlk
           doubleForColumnBlk:(double(^)(FMResultSet *))doubleForColumnBlk {
  NSDate *date = nil;
  if (!isNullBlk(rs)) {
    date = [NSDate dateWithTimeIntervalSince1970:(doubleForColumnBlk(rs) / 1000.0)];
  }
  return date;
}

+ (NSDate *)dateFromResultSet:(FMResultSet *)rs
                  columnIndex:(int)columnIndex {
  return [PELMUtils dateFromResultSet:rs
                            isNullBlk:^ BOOL (FMResultSet *rs) { return [rs columnIndexIsNull:columnIndex]; }
                   doubleForColumnBlk:^ double (FMResultSet *rs) { return [rs doubleForColumnIndex:columnIndex]; }];
}

+ (NSDate *)dateFromResultSet:(FMResultSet *)rs
                   columnName:(NSString *)columnName {
  return [PELMUtils dateFromResultSet:rs
                            isNullBlk:^ BOOL (FMResultSet *rs) { return [rs columnIsNull:columnName]; }
                   doubleForColumnBlk:^ double (FMResultSet *rs) { return [rs doubleForColumn:columnName]; }];
}

+ (BOOL)boolFromResultSet:(FMResultSet *)rs columnName:(NSString *)columnName boolIfNull:(BOOL)boolIfNull {
  if ([rs columnIsNull:columnName]) {
    return boolIfNull;
  }
  return [rs boolForColumn:columnName];
}

#pragma mark - Utils

+ (NSArray *)numberArrayFromQuery:(NSString *)query
                             args:(NSArray *)args
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *numbers = [NSMutableArray array];
  FMResultSet *rs = [PELMUtils doQuery:query
                             argsArray:args
                                    db:db
                                 error:errorBlk];
  while ([rs next]) {
    [numbers addObject:[PELMUtils numberFromResultSet:rs columnIndex:0]];
  }
  return numbers;
}

+ (PELMCannotBe)makeCannotBe {
  return ^(BOOL invariantViolation, NSString *msg) {
    if (invariantViolation) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:msg
                                   userInfo:nil];
    }
  };
}

+ (PELMOrNil)makeOrNil {
  return ^ id (id someObj) {
    return [PEUtils orNil:someObj];
  };
}

- (void)cancelSyncForEntity:(PELMMainSupport *)entity
               httpRespCode:(NSNumber *)httpRespCode
                  errorMask:(NSNumber *)errorMask
                    retryAt:(NSDate *)retryAt
                 updateStmt:(NSString *)updateStmt
              updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                      error:(PELMDaoErrorBlk)errorBlk {
  [entity setSyncInProgress:NO];
  [entity setSyncErrMask:errorMask];
  [entity setSyncHttpRespCode:httpRespCode];
  [entity setSyncRetryAt:retryAt];
  [self doUpdateInTxn:updateStmt
            argsArray:updateArgsBlk(entity)
                error:errorBlk];
}

- (void)saveEntity:(PELMMainSupport *)entity
        updateStmt:(NSString *)updateStmt
     updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
             error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:updateStmt
              argsArray:updateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingEntity:(PELMMainSupport *)entity
                     updateStmt:(NSString *)updateStmt
                  updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
                          error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [entity setSyncHttpRespCode:nil];
    [entity setSyncErrMask:nil];
    [entity setSynced:NO];
    [PELMUtils doUpdate:updateStmt
              argsArray:updateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  }];
}

- (void)markAsDoneEditingImmediateSyncEntity:(PELMMainSupport *)entity
                                  updateStmt:(NSString *)updateStmt
                               updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
                                       error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [entity setSyncHttpRespCode:nil];
    [entity setSyncErrMask:nil];
    [entity setSyncInProgress:YES];
    [entity setSynced:NO];
    [PELMUtils doUpdate:updateStmt
              argsArray:updateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  }];
}

- (PELMSaveNewOrExistingCode)saveNewOrExistingByGlobalIdentifierEntity:(PELMMainSupport *)masterEntity
                                                           masterTable:(NSString *)masterTable
                                                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                                      masterUpdateStmt:(NSString *)masterUpdateStmt
                                                   masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                                                 error:(PELMDaoErrorBlk)errorBlk {
  __block PELMSaveNewOrExistingCode returnCode;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    returnCode = [PELMUtils saveNewOrExistingByGlobalIdentifierEntity:masterEntity
                                                          masterTable:masterTable
                                                      masterInsertBlk:masterInsertBlk
                                                     masterUpdateStmt:masterUpdateStmt
                                                  masterUpdateArgsBlk:masterUpdateArgsBlk
                                                                   db:db
                                                                error:errorBlk];
  }];
  return returnCode;
}

+ (PELMSaveNewOrExistingCode)saveNewOrExistingByGlobalIdentifierEntity:(PELMMasterSupport *)masterEntity
                                                           masterTable:(NSString *)masterTable
                                                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                                      masterUpdateStmt:(NSString *)masterUpdateStmt
                                                   masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                                                    db:(FMDatabase *)db
                                                                 error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils saveNewOrExistingEntity:masterEntity
                                masterTable:masterTable
                            masterInsertBlk:masterInsertBlk
                           masterUpdateStmt:masterUpdateStmt
                        masterUpdateArgsBlk:masterUpdateArgsBlk
                              idSearcherBlk:^ NSNumber * (NSString *masterTable, PELMMasterSupport *masterEntity) {
                                return [PELMUtils masterLocalIdFromEntityTable:masterTable
                                                              globalIdentifier:masterEntity.globalIdentifier
                                                                            db:db
                                                                         error:errorBlk];
                              }
                                         db:db
                                      error:errorBlk];
}

+ (PELMSaveNewOrExistingCode)saveNewOrExistingEntity:(PELMMasterSupport *)masterEntity
                                         masterTable:(NSString *)masterTable
                                     masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                    masterUpdateStmt:(NSString *)masterUpdateStmt
                                 masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                       idSearcherBlk:(NSNumber *(^)(NSString *, PELMMasterSupport *))idSearchBlk
                                                  db:(FMDatabase *)db
                                               error:(PELMDaoErrorBlk)errorBlk {
  NSNumber *localMasterId = idSearchBlk(masterTable, masterEntity);
  if (localMasterId) {
    masterEntity.localMasterIdentifier = localMasterId;
    NSDate *localUpdatedAt = [PELMUtils dateFromTable:masterTable
                                           dateColumn:COL_UPDATED_AT
                                          whereColumn:COL_LOCAL_ID
                                           whereValue:localMasterId
                                                   db:db
                                                error:errorBlk];
    if ([masterEntity.updatedAt isLaterThan:localUpdatedAt]) {
      [PELMUtils doUpdate:masterUpdateStmt argsArray:masterUpdateArgsBlk(masterEntity) db:db error:errorBlk];
      return PELMSaveNewOrExistingCodeDidUpdate;
    } else {
      return PELMSaveNewOrExistingCodeDidNothing;
    }
  } else {
    masterInsertBlk(masterEntity, db);
    return PELMSaveNewOrExistingCodeDidInsert;
  }
}

- (void)saveNewMasterEntity:(PELMMasterSupport *)entity
                masterTable:(NSString *)masterTable
            masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                      error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils saveNewMasterEntity:entity
                       masterTable:masterTable
                   masterInsertBlk:masterInsertBlk
                                db:db
                             error:errorBlk];
  }];
}

+ (void)saveNewMasterEntity:(PELMMasterSupport *)entity
                masterTable:(NSString *)masterTable
            masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                         db:(FMDatabase *)db
                      error:(PELMDaoErrorBlk)errorBlk {
  masterInsertBlk(entity, db);
}

- (void)markAsSyncCompleteForEntityInTxn:(PELMMainSupport *)entity
                        masterUpdateStmt:(NSString *)masterUpdateStmt
                     masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                   error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self markAsSyncCompleteForEntity:entity
                     masterUpdateStmt:masterUpdateStmt
                  masterUpdateArgsBlk:masterUpdateArgsBlk
                                   db:db
                                error:errorBlk];
  }];
}

- (void)markAsSyncCompleteForEntity:(PELMMainSupport *)entity
                   masterUpdateStmt:(NSString *)masterUpdateStmt
                masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk {
  [entity setSyncInProgress:NO];
  [entity setSynced:YES];
  [PELMUtils doUpdate:masterUpdateStmt
            argsArray:masterUpdateArgsBlk(entity)
                   db:db
                error:errorBlk];
}

+ (NSNumber *)masterLocalIdFromEntityTable:(NSString *)masterEntityTable
                          globalIdentifier:(NSString *)globalIdentifier
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils numberFromTable:masterEntityTable
                       selectColumn:COL_LOCAL_ID
                        whereColumn:COL_GLOBAL_ID
                         whereValue:globalIdentifier
                                 db:db
                              error:errorBlk];
}

- (NSArray *)markEntitiesAsSyncInProgressUsingQuery:(NSString *)query
                                entityFromResultSet:(PELMEntityFromResultSetBlk)entityFromResultSet
                                         updateStmt:(NSString *)updateStmt
                                      updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                                          filterBlk:(BOOL(^)(PELMMainSupport *))filterBlk
                            importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                               user:(PELMUser *)user
                                      importedAtBlk:(PELMImportedAtBlk)importedAtBlk
                          hasExceededImportLimitBlk:(PELMHasExceededImportLimit)hasExceededImportLimitBlk
                                              error:(PELMDaoErrorBlk)errorBlk {
  void (^markSyncInProgressAction)(PELMMainSupport *, FMDatabase *) = ^ (PELMMainSupport *entity, FMDatabase *db) {
    [entity setSyncInProgress:YES];
    [PELMUtils doUpdate:updateStmt
              argsArray:updateArgsBlk(entity)
                     db:db
                  error:errorBlk];
  };
  BOOL isUserVerified = NO;
  if (user) {
    isUserVerified = [PEUtils isNotNil:user.verifiedAt];
  }
  BOOL allowedToSyncImport = YES;
  if (!isUserVerified) {
    allowedToSyncImport = NO;
  }
  BOOL importLimitExceeded = NO;
  if (hasExceededImportLimitBlk) {
    importLimitExceeded = hasExceededImportLimitBlk(user);
  }
  __block NSArray *resultEntities = nil;
  NSMutableArray *entitesToSync = [NSMutableArray array];
  __block NSInteger numImportedEntitiesNotSyncedDueToNotAllowed = 0;
  __block NSInteger numImportedEntitiesNotSyncedDueToMaxExceeded = 0;
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    resultEntities =
    [PELMUtils entitiesFromQuery:query
                       argsArray:@[user.localMasterIdentifier]
                     rsConverter:entityFromResultSet
                              db:db
                           error:errorBlk];
    for (PELMMainSupport *entity in resultEntities) {
      BOOL isNewImport = NO;
      if ([PEUtils isNil:entity.globalIdentifier] &&
          [PEUtils isNotNil:importedAtBlk] &&
          [PEUtils isNotNil:importedAtBlk(entity)]) {
        isNewImport = YES;
      }
      if (isNewImport && !allowedToSyncImport) {
        numImportedEntitiesNotSyncedDueToNotAllowed++;
      } else if (isNewImport && importLimitExceeded) {
        numImportedEntitiesNotSyncedDueToMaxExceeded++;
      }
      if ((!isNewImport || allowedToSyncImport) &&
          (!isNewImport || !importLimitExceeded) &&
          (([entity syncErrMask] == nil) ||
           ([entity syncErrMask].integerValue <= 0) || // less than zero means it represents a system connectivity-related issue (thus temporary); zero occurs if no explicit err-mask header was in response
           ([entity syncErrMask].integerValue == importLimitExceededMask.integerValue)) && // so if user got their limit bumped by admin, we don't want this particular err code to prevent a re-attempt at syncing
          (([entity syncHttpRespCode] == nil) ||
           ([entity syncHttpRespCode].integerValue == 401) ||
           ([entity syncHttpRespCode].integerValue == 403) ||
           ([entity syncHttpRespCode].integerValue == 409) ||
           ([entity syncHttpRespCode].integerValue == 422 && !importLimitExceeded) ||
           ([entity syncHttpRespCode].integerValue == 503) ||
           ([entity syncHttpRespCode].integerValue == 502) ||
           ([entity syncHttpRespCode].integerValue == 504) ||
           ([entity syncHttpRespCode].integerValue == 500)) && // each of these err codes can be temporary, so even if the previous sync attempt yielded one of these, we can still try again on the next attempt
          (([entity syncRetryAt] == nil) ||
           ([[NSDate date] compare:[entity syncRetryAt]] == NSOrderedDescending))) {
            if (filterBlk) {
              if (filterBlk(entity)) {
                markSyncInProgressAction(entity, db);
                [entitesToSync addObject:entity];
              }
            } else {
              markSyncInProgressAction(entity, db); // no filter provided, therefore we do action
              [entitesToSync addObject:entity];
            }
          }
    }
  }];
  return @[entitesToSync,
           @(numImportedEntitiesNotSyncedDueToNotAllowed),
           @(numImportedEntitiesNotSyncedDueToMaxExceeded)];
}

- (NSArray *)markEntitiesAsSyncInProgressInTable:(NSString *)table
                             entityFromResultSet:(PELMEntityFromResultSetBlk)entityFromResultSet
                                      updateStmt:(NSString *)updateStmt
                                   updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                         importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                            user:(PELMUser *)user
                                   importedAtBlk:(PELMImportedAtBlk)importedAtBlk
                       hasExceededImportLimitBlk:(PELMHasExceededImportLimit)hasExceededImportLimitBlk
                                           error:(PELMDaoErrorBlk)errorBlk {
  return [self markEntitiesAsSyncInProgressUsingQuery:[NSString stringWithFormat:@"select * from %@ where (%@ is null or %@ = 0) and (%@ is null or %@ = 0) and %@ = ?",
                                                       table,
                                                       COL_SYNCED,
                                                       COL_SYNCED,
                                                       COL_SYNC_IN_PROGRESS,
                                                       COL_SYNC_IN_PROGRESS,
                                                       COL_MASTER_USER_ID]
                                  entityFromResultSet:entityFromResultSet
                                           updateStmt:updateStmt
                                        updateArgsBlk:updateArgsBlk
                                            filterBlk:nil
                              importLimitExceededMask:importLimitExceededMask
                                                 user:user
                                        importedAtBlk:importedAtBlk
                            hasExceededImportLimitBlk:hasExceededImportLimitBlk
                                                error:errorBlk];
}

+ (void)invokeError:(PELMDaoErrorBlk)errorBlk db:(FMDatabase *)db {
  [[Crashlytics sharedInstance] recordError:db.lastError];
  errorBlk([db lastError], [db lastErrorCode], [db lastErrorMessage]);
}

+ (void)deleteEntity:(PELMModelSupport *)entity
               table:(NSString *)table
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  [self deleteFromEntityTable:table
              localIdentifier:[entity localMasterIdentifier]
                           db:db
                        error:errorBlk];
}

+ (void)deleteFromEntityTable:(NSString *)entityTable
              localIdentifier:(NSNumber *)localIdentifier
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  if (localIdentifier) {
    [PELMUtils deleteFromTable:entityTable
                  whereColumns:@[COL_LOCAL_ID]
                   whereValues:@[localIdentifier]
                            db:db
                         error:errorBlk];
  }
}

+ (void)deleteFromTable:(NSString *)table
           whereColumns:(NSArray *)whereColumns
            whereValues:(NSArray *)whereValues
                     db:(FMDatabase *)db
                  error:(PELMDaoErrorBlk)errorBlk {
  NSMutableString *stmt = [NSMutableString stringWithFormat:@"DELETE FROM %@", table];
  NSUInteger numColumns = [whereColumns count];
  if (numColumns > 0) {
    [stmt appendString:@" WHERE "];
  }
  for (int i = 0; i < numColumns; i++) {
    [stmt appendFormat:@"%@ = ?", [whereColumns objectAtIndex:i]];
    if ((i + 1) < numColumns) {
      [stmt appendString:@" AND "];
    }
  }
  [self doUpdate:stmt argsArray:whereValues db:db error:errorBlk];
}

- (void)deleteFromTableInTxn:(NSString *)table
                whereColumns:(NSArray *)whereColumns
                 whereValues:(NSArray *)whereValues
                       error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils deleteFromTable:table
                  whereColumns:whereColumns
                   whereValues:whereValues
                            db:db
                         error:errorBlk];
  }];
}

+ (void)deleteFromTables:(NSArray *)tables
            whereColumns:(NSArray *)whereColumns
             whereValues:(NSArray *)whereValues
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  for (NSString *table in tables) {
    [self deleteFromTable:table
             whereColumns:whereColumns
              whereValues:whereValues
                       db:db
                    error:errorBlk];
  }
}

- (void)deleteFromTablesInTxn:(NSArray *)tables
                 whereColumns:(NSArray *)whereColumns
                  whereValues:(NSArray *)whereValues
                        error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils deleteFromTables:tables
                   whereColumns:whereColumns
                    whereValues:whereValues
                             db:db
                          error:errorBlk];
  }];
}

- (void)pruneAllSyncedFromMainTables:(NSArray *)tableNames
                               error:(PELMDaoErrorBlk)errorBlk {
  NSString *entityKey = @"entity";
  NSString *tableKey = @"table";
  NSMutableArray *syncedEntitiesDicts = [NSMutableArray array];
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    for (NSString *table in tableNames) {
      FMResultSet *rs =
      [PELMUtils doQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = 1", table, COL_SYNCED]
               argsArray:@[]
                      db:db
                   error:errorBlk];
      while ([rs next]) {
        [syncedEntitiesDicts addObject:[NSDictionary dictionaryWithObjects:@[toMainSupport(rs, table, nil), table] forKeys:@[entityKey, tableKey]]];
      }
      [rs close];
    }
  }];
  for (NSDictionary *syncedEntityDict in syncedEntitiesDicts) {
    PELMMainSupport *syncedEntity = [syncedEntityDict objectForKey:entityKey];
    if ([syncedEntity localMainIdentifier]) { // it shouldn't be possible for localMainIdentifier to be nil here, but, just 'cause
      NSString *table = [syncedEntityDict objectForKey:tableKey];
      [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {        
        [PELMUtils doUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", table, COL_LOCAL_ID]
                  argsArray:@[[syncedEntity localMainIdentifier]]
                         db:db
                      error:^ (NSError *err, int code, NSString *msg) {
                        *rollback = YES;
                        errorBlk(err, code, msg);
                      }];
      }];
    }
  }
}

+ (void)doMainInsert:(NSString *)stmt
           argsArray:(NSArray *)argsArray
              entity:(PELMMainSupport *)entity
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  [self doInsert:stmt
       argsArray:argsArray
          entity:entity
      idAssigner:^(PELMModelSupport *entity, NSNumber *newId) { [entity setLocalMasterIdentifier:newId]; }
              db:db
           error:errorBlk];
}

+ (void)doMasterInsert:(NSString *)stmt
             argsArray:(NSArray *)argsArray
                entity:(PELMModelSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  [self doInsert:stmt
       argsArray:argsArray
          entity:entity
      idAssigner:^(PELMModelSupport *entity, NSNumber *newId) { [entity setLocalMasterIdentifier:newId]; }
              db:db
           error:errorBlk];
}

+ (void)doInsert:(NSString *)stmt
       argsArray:(NSArray *)argsArray
          entity:(PELMModelSupport *)entity
      idAssigner:(void(^)(PELMModelSupport *, NSNumber *))idAssigner
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk {
  if ([db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    if (entity) {
      idAssigner(entity, [NSNumber numberWithLongLong:[db lastInsertRowId]]);
    }
    [PELMUtils postDbUpdateNotification];
  } else {
    [self invokeError:errorBlk db:db];
  }
}

+ (void)doUpdate:(NSString *)stmt
             db:(FMDatabase *)db
          error:(PELMDaoErrorBlk)errorBlk {
  [self doUpdate:stmt argsArray:nil db:db error:errorBlk];
}

+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk {
  if ([db executeUpdate:stmt withArgumentsInArray:argsArray]) {
    [PELMUtils postDbUpdateNotification];
  } else {
    [self invokeError:errorBlk db:db];
  }
}

- (void)doUpdateInTxn:(NSString *)stmt
            argsArray:(NSArray *)argsArray
                error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [PELMUtils doUpdate:stmt argsArray:argsArray db:db error:errorBlk];
  }];
}

+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:argsArray];
  if (!rs) {
    [self invokeError:errorBlk db:db];
  }
  return rs;
}

+ (id)entityFromQuery:(NSString *)query
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  return [self entityFromQuery:query
                     argsArray:@[]
                   rsConverter:rsConverter
                            db:db
                         error:errorBlk];
}

+ (id)entityFromQuery:(NSString *)query
            argsArray:(NSArray *)argsArray
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk {
  id entity = nil;
  FMResultSet *rs = [self doQuery:query argsArray:argsArray db:db error:errorBlk];
  if (rs) {
    while ([rs next]) {
      entity = rsConverter(rs);
    }
    [rs close];
  }  
  return entity;
}

- (id)entityFromQuery:(NSString *)query
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk {
  return [self entityFromQuery:query
                     argsArray:@[]
                   rsConverter:rsConverter
                         error:errorBlk];
}

- (id)entityFromQuery:(NSString *)query
            argsArray:(NSArray *)argsArray
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk {
  __block id entity = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    entity = [PELMUtils entityFromQuery:query
                              argsArray:argsArray
                            rsConverter:rsConverter
                                     db:db
                                  error:errorBlk];
  }];
  return entity;
}

- (NSArray *)entitiesFromQuery:(NSString *)query
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                         error:(PELMDaoErrorBlk)errorBlk {
  __block NSArray *entities = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    entities = [PELMUtils entitiesFromQuery:query
                                  argsArray:argsArray
                                rsConverter:rsConverter
                                         db:db
                                      error:errorBlk];
  }];
  return entities;
}

+ (NSArray *)entitiesFromQuery:(NSString *)query
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils entitiesFromQuery:query
                           numAllowed:nil
                            argsArray:argsArray
                          rsConverter:rsConverter
                                   db:db
                                error:errorBlk];
}

+ (NSArray *)entitiesFromQuery:(NSString *)query
                    numAllowed:(NSNumber *)numAllowed
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk {
  NSMutableArray *entities = [NSMutableArray array];
  NSString *theQuery = query;
  if ([PEUtils isNotNil:numAllowed]) {
    theQuery = [NSString stringWithFormat:@"%@ limit %@", query, numAllowed];
  }
  FMResultSet *rs = [self doQuery:theQuery argsArray:argsArray db:db error:errorBlk];
  while ([rs next]) {
    [entities addObject:rsConverter(rs)];
  }
  return entities;
}

#pragma mark - Result set -> Model helpers (private)

+ (HCRelation *)relationFromResultSet:(FMResultSet *)rs
                 subjectResourceModel:(PELMModelSupport *)subjectResourceModel {
  HCResource *subjectResource =
  [[HCResource alloc]
   initWithMediaType:[subjectResourceModel mediaType]
   uri:[NSURL URLWithString:[subjectResourceModel globalIdentifier]]];
  HCResource *targetResource =
  [[HCResource alloc]
   initWithMediaType:[HCMediaType MediaTypeFromString:[rs stringForColumn:COL_REL_MEDIA_TYPE]]
   uri:[NSURL URLWithString:[rs stringForColumn:COL_REL_URI]]];
  return [[HCRelation alloc]
          initWithName:[rs stringForColumn:COL_REL_NAME]
          subjectResource:subjectResource
          targetResource:targetResource];
}

#pragma mark - Helpers

+ (NSDate *)maxDateFromTable:(NSString *)table
                  dateColumn:(NSString *)dateColumn
                 whereColumn:(NSString *)whereColumn
                  whereValue:(id)whereValue
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  NSDate *date = nil;
  NSString *query = [NSString stringWithFormat:@"SELECT MAX(%@) FROM %@", dateColumn, table];
  if (whereColumn) {
    query = [NSString stringWithFormat:@"%@ WHERE %@ = ?", query, whereColumn];
  }
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:[PEUtils isNotNil:whereValue] ? @[whereValue] : @[]];
  while ([rs next]) {
    date = [PELMUtils dateFromResultSet:rs columnIndex:0];
  }
  [rs close];
  return date;
}

+ (NSDate *)dateFromTable:(NSString *)table
               dateColumn:(NSString *)dateColumn
              whereColumn:(NSString *)whereColumn
               whereValue:(id)whereValue
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils dateFromQuery:[NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", dateColumn, table, whereColumn]
                             args:@[whereValue]
                               db:db];
}

+ (NSDate *)dateFromQuery:(NSString *)query args:(NSArray *)args db:(FMDatabase *)db {
  NSDate *date = nil;
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:args];
  while ([rs next]) {
    date = [PELMUtils dateFromResultSet:rs columnIndex:0];
  }
  [rs close];
  return date;
}

- (NSDate *)dateFromQuery:(NSString *)query args:(NSArray *)args {
  __block NSDate *date = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:args];
    while ([rs next]) {
      date = [PELMUtils dateFromResultSet:rs columnIndex:0];
    }
    [rs close];
  }];
  return date;
}

- (NSInteger)intFromQuery:(NSString *)query args:(NSArray *)args {
  __block NSInteger num = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    num = [PELMUtils intFromQuery:query args:args db:db];
  }];
  return num;
}

+ (NSInteger)intFromQuery:(NSString *)query args:(NSArray *)args db:(FMDatabase *)db {
  NSInteger num = 0;
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:args];
  while ([rs next]) {
    num = [rs intForColumnIndex:0];
  }
  [rs close];
  return num;
}

- (NSNumber *)numberFromQuery:(NSString *)query args:(NSArray *)args {
  __block NSNumber *num = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    num = [PELMUtils numberFromQuery:query args:args db:db];
  }];
  return num;
}

+ (NSNumber *)numberFromQuery:(NSString *)query args:(NSArray *)args db:(FMDatabase *)db {
  NSNumber *num = nil;
  FMResultSet *rs = [db executeQuery:query withArgumentsInArray:args];
  while ([rs next]) {
    if (![rs columnIndexIsNull:0]) {
      num = @([rs intForColumnIndex:0]);
    }
  }
  [rs close];
  return num;
}

- (NSInteger)numRowsFromTable:(NSString *)table
                        error:(PELMDaoErrorBlk)errorBlk {
  __block NSInteger numEntities = 0;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    numEntities = [PELMUtils numRowsFromTable:table db:db error:errorBlk];
  }];
  return numEntities;
}

+ (NSInteger)numRowsFromTable:(NSString *)table
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils intFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", table]
                            args:@[]
                              db:db];
}

+ (NSInteger)numRowsFromTable:(NSString *)table
                        since:(NSDate *)since
                  sinceColumn:(NSString *)sinceColumn
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils intFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ > ?", table, sinceColumn]
                            args:@[@([PEUtils millisecondsFromDate:since].integerValue)]
                              db:db];
}

+ (NSInteger)numRowsFromTable:(NSString *)table
                      equalTo:(NSString *)equalTo
                equalToColumn:(NSString *)equalToColumn
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils intFromQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ = ?", table, equalToColumn]
                            args:@[equalTo]
                              db:db];
}

- (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils numberFromTable:table
                           selectColumn:selectColumn
                            whereColumn:whereColumn
                             whereValue:whereValue
                                     db:db
                                  error:errorBlk];
  }];
  return value;
}

+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [PELMUtils valueFromTable:table
                      selectColumn:selectColumn
                       whereColumn:whereColumn
                        whereValue:whereValue
                       rsExtractor:^id(FMResultSet *rs, NSString *selectColum){return [NSNumber numberWithInt:[rs intForColumn:selectColumn]];}
                                db:db
                             error:errorBlk];
}

- (NSNumber *)boolFromTable:(NSString *)table
               selectColumn:(NSString *)selectColumn
                whereColumn:(NSString *)whereColumn
                 whereValue:(id)whereValue
                      error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils boolFromTable:table
                         selectColumn:selectColumn
                          whereColumn:whereColumn
                           whereValue:whereValue
                                   db:db
                                error:errorBlk];
  }];
  return value;
}

+ (NSNumber *)boolFromTable:(NSString *)table
               selectColumn:(NSString *)selectColumn
                whereColumn:(NSString *)whereColumn
                 whereValue:(id)whereValue
                         db:(FMDatabase *)db
                      error:(PELMDaoErrorBlk)errorBlk {
  id (^rsExtractor)(FMResultSet *, NSString *) = ^ id (FMResultSet *rs, NSString *selectColum) {
    return [NSNumber numberWithBool:[rs boolForColumn:selectColum]];
  };
  return [self valueFromTable:table
                 selectColumn:selectColumn
                  whereColumn:whereColumn
                   whereValue:whereValue
                  rsExtractor:rsExtractor
                           db:db
                        error:errorBlk];
}



- (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk {
  __block id value = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    value =  [PELMUtils stringFromTable:table
                           selectColumn:selectColumn
                            whereColumn:whereColumn
                             whereValue:whereValue
                                     db:db
                                  error:errorBlk];
  }];
  return value;
}

+ (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk {
  return [self valueFromTable:table
                 selectColumn:selectColumn
                  whereColumn:whereColumn
                   whereValue:whereValue
                  rsExtractor:^id(FMResultSet *rs,NSString *selectColum){return [rs stringForColumn:selectColumn];}
                           db:db
                        error:errorBlk];
}

+ (id)valueFromTable:(NSString *)table
        selectColumn:(NSString *)selectColumn
         whereColumn:(NSString *)whereColumn
          whereValue:(id)whereValue
         rsExtractor:(id(^)(FMResultSet *, NSString *))rsExtractor
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk {
  id value = nil;
  FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ?", selectColumn, table, whereColumn]
                withArgumentsInArray:@[whereValue]];
  while ([rs next]) {
    value = rsExtractor(rs, selectColumn);
  }
  [rs close];
  return value;
}

@end
