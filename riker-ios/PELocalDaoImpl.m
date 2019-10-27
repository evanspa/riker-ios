//
// PELocalDao.m
//

#import "PELocalDaoImpl.h"
#import <FMDB/FMDatabase.h>
#import "PELMDDL.h"
#import "PEUtils.h"
#import "HCMediaType.h"
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabase.h>
#import "PELMMainSupport.h"
#import "PELMUser.h"
#import "PEChangelog.h"

@implementation PELocalDaoImpl {
  FMDatabaseQueue *_databaseQueue;
  PELMUtils *_localModelUtils;
}

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath {
  return [self initWithDatabaseQueue:[FMDatabaseQueue databaseQueueWithPath:sqliteDataFilePath]];
}

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue {
  self = [super init];
  if (self) {
    _databaseQueue = databaseQueue;
    _localModelUtils = [[PELMUtils alloc] initWithDatabaseQueue:_databaseQueue];
    [_databaseQueue inDatabase:^(FMDatabase *db) {
      // for some reason, this has to be done in a "inDatabase" block for it to
      // work.  I guess we'll just assume that FKs are enabled as a universal
      // truth of the system, regardless of 'required schema version' val.
      [db executeUpdate:@"PRAGMA foreign_keys = ON"];
    }];
  }
  return self;
}

#pragma mark - Master Entity Table Names

- (NSArray *)masterEntityTableNames { return @[]; }

#pragma mark - Pre-Delete User Hook

- (PEUserDbOpBlk)preDeleteUserHookDeleteSettings:(BOOL)deleteSettings { return nil; } // meant to be overridden

#pragma mark - Post-Local-Save New User Hook

- (PEUserDbOpBlk)postSaveNewUserHookWithUserSettingsMtVersion:(NSString *)mtVersion { return nil; }

#pragma mark - Post-Deep Save User Hook

- (PEUserDbOpBlk)postDeepSaveUserHookIsAccountCreation:(BOOL)isAccountCreation { return nil; }

#pragma mark - Entity Table Names (child -> parent order)

- (NSArray *)entityTableNamesChildToParentOrder { return @[]; }

#pragma mark - Getters

- (PELMUtils *)localModelUtils { return _localModelUtils; }

- (FMDatabaseQueue *)databaseQueue { return _databaseQueue; }

#pragma mark - System Functions

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error {
  NSMutableArray *tables = [NSMutableArray arrayWithObject:TBL_MASTER_USER];
  [tables addObjectsFromArray:[[[self entityTableNamesChildToParentOrder] reverseObjectEnumerator] allObjects]];
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    for (NSString *entityTableName in tables) {
      [PELMUtils cancelSyncInProgressForEntityTable:entityTableName db:db error:error];
    }
  }];
}

#pragma mark - User Operations

- (void)transformToLocalOnlyUserWithError:(PELMDaoErrorBlk)errorBlk {} // meant to be overridden

- (void)saveNewRemoteUser:(PELMUser *)newRemoteUser
       andLinkToLocalUser:(PELMUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk {
  newRemoteUser.localMasterIdentifier = localUser.localMasterIdentifier;
  newRemoteUser.synced = YES;
  [PELMUtils doUpdate:[self updateStmtForMasterUser] argsArray:[self updateArgsForMasterUser:newRemoteUser] db:db error:errorBlk];
  if (!preserveExistingLocalEntities) {
    PEUserDbOpBlk preDeleteUserHook = [self preDeleteUserHookDeleteSettings:NO];
    if (preDeleteUserHook) {
      preDeleteUserHook(localUser, db, errorBlk);
    }
  }
}

- (void)deepSaveNewRemoteUser:(PELMUser *)remoteUser
           andLinkToLocalUser:(PELMUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
            isAccountCreation:(BOOL)isAccountCreation
                        error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewRemoteUser:remoteUser
         andLinkToLocalUser:localUser
preserveExistingLocalEntities:preserveExistingLocalEntities
                         db:db
                      error:errorBlk];
    PEUserDbOpBlk postDeepSaveUserHook = [self postDeepSaveUserHookIsAccountCreation:isAccountCreation];
    if (postDeepSaveUserHook) {
      postDeepSaveUserHook(remoteUser, db, errorBlk);
    }
  }];
}

- (void)deleteUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self deleteUser:user db:db error:errorBlk];
  }];
}

- (void)deleteUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  PEUserDbOpBlk preDeleteHook = [self preDeleteUserHookDeleteSettings:YES];
  if (preDeleteHook) {
    preDeleteHook(user, db, errorBlk);
  }
  [PELMUtils deleteEntity:user
                    table:TBL_MASTER_USER
                       db:db
                    error:errorBlk];
}

- (NSDate *)mostRecentMasterUpdateForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  __block NSDate *overallMostRecent = nil;
  [self.databaseQueue inDatabase:^(FMDatabase *db) {
    NSDate *(^mostRecentDate)(NSString *) = ^ NSDate * (NSString *table) {
      return [PELMUtils maxDateFromTable:table
                              dateColumn:COL_UPDATED_AT
                             whereColumn:COL_MASTER_USER_ID
                              whereValue:user.localMasterIdentifier
                                      db:db
                                   error:errorBlk];
    };
    overallMostRecent = [PELMUtils maxDateFromTable:TBL_MASTER_USER
                                         dateColumn:COL_UPDATED_AT
                                        whereColumn:COL_LOCAL_ID
                                         whereValue:user.localMasterIdentifier
                                                 db:db
                                              error:errorBlk];
    NSArray *masterEntityTableNames = [self masterEntityTableNames];
    for (NSString *tableName in masterEntityTableNames) {
      overallMostRecent = [PEUtils largerOfDate:overallMostRecent
                                        andDate:mostRecentDate(tableName)];
    }
  }];
  return overallMostRecent;
}

- (PELMUser *)masterUserWithId:(NSNumber *)userId error:(PELMDaoErrorBlk)errorBlk {
  __block PELMUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_USER, COL_LOCAL_ID]
                            argsArray:@[userId]
                          rsConverter:^(FMResultSet *rs) { return [self masterUserFromResultSet:rs]; }
                                   db:db
                                error:errorBlk];
  }];
  return user;
}

- (PELMUser *)masterUserWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk {
  __block PELMUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ?", TBL_MASTER_USER, COL_GLOBAL_ID]
                            argsArray:@[globalId]
                          rsConverter:^(FMResultSet *rs) { return [self masterUserFromResultSet:rs]; }
                                   db:db
                                error:errorBlk];
  }];
  return user;
}

- (PELMUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk {
  __block PELMUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self masterUserWithDatabase:db error:errorBlk];
  }];
  return user;
}

- (PELMUser *)masterUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  NSString *userTable = TBL_MASTER_USER;
  return [PELMUtils entityFromQuery:[NSString stringWithFormat:@"SELECT * FROM %@", userTable]
                          argsArray:@[]
                        rsConverter:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
                                 db:db
                              error:errorBlk];
}

- (void)saveNewLocalUser:(PELMUser *)user
   userSettingsMtVersion:(NSString *)userSettingsMtVersion
                   error:(PELMDaoErrorBlk)errorBlk {
  [_databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    [self saveNewLocalUser:user db:db error:errorBlk];
    PEUserDbOpBlk postSaveHook = [self postSaveNewUserHookWithUserSettingsMtVersion:userSettingsMtVersion];
    if (postSaveHook) {
      postSaveHook(user, db, errorBlk);
    }
  }];
}

- (void)saveNewLocalUser:(PELMUser *)user
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk {
  [self insertIntoMasterUser:user db:db error:errorBlk];
}

- (PELMUser *)userWithError:(PELMDaoErrorBlk)errorBlk {
  __block PELMUser *user = nil;
  [_databaseQueue inDatabase:^(FMDatabase *db) {
    user = [self userWithDb:db error:errorBlk];
  }];
  return user;
}

- (PELMUser *)userWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  return [self masterUserWithDatabase:db error:errorBlk];
}

- (void)saveUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils saveEntity:user
                    updateStmt:[self updateStmtForMasterUser]
                 updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                         error:errorBlk];
}

- (void)markAsDoneEditingImmediateSyncUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingImmediateSyncEntity:user
                                              updateStmt:[self updateStmtForMasterUser]
                                           updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                                                   error:errorBlk];
}

- (void)markAsDoneEditingUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsDoneEditingEntity:user
                                 updateStmt:[self updateStmtForMasterUser]
                              updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                                      error:errorBlk];
}

- (PELMUser *)markUserAsSyncInProgressWithError:(PELMDaoErrorBlk)errorBlk {
  NSArray *userEntities = [_localModelUtils markEntitiesAsSyncInProgressInTable:TBL_MASTER_USER
                                                            entityFromResultSet:^(FMResultSet *rs){return [self masterUserFromResultSet:rs];}
                                                                     updateStmt:[self updateStmtForMasterUser]
                                                                  updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                                                        importLimitExceededMask:nil
                                                                           user:nil
                                                                  importedAtBlk:nil
                                                      hasExceededImportLimitBlk:nil
                                                                          error:errorBlk][0];
  if ([userEntities count] > 1) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"There cannot be more than 1 user entity"
                                 userInfo:nil];
  } else if ([userEntities count] == 0) {
    return nil;
  } else {
    return [userEntities objectAtIndex:0];
  }
}

- (void)cancelSyncForUser:(PELMUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
                    error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils cancelSyncForEntity:user
                           httpRespCode:httpRespCode
                              errorMask:errorMask
                                retryAt:retryAt
                             updateStmt:[self updateStmtForMasterUser]
                          updateArgsBlk:^NSArray *(PELMMainSupport *entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                                  error:errorBlk];
}

- (BOOL)saveMasterUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils doUpdateInTxn:[self updateStmtForMasterUser]
                        argsArray:[self updateArgsForMasterUser:user]
                            error:errorBlk];
  return YES;
}

- (BOOL)saveMasterUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk {
  [PELMUtils doUpdate:[self updateStmtForMasterUser]
            argsArray:[self updateArgsForMasterUser:user]
                   db:db
                error:errorBlk];
  return YES;
}

- (BOOL)saveMasterUser:(PELMUser *)user
  readOnlyFieldsEntity:(PELMMainSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk {
  [user overwriteReadonlyProperties:entity];
  [PELMUtils doUpdate:[self updateStmtForMasterUser]
            argsArray:[self updateArgsForMasterUser:user]
                   db:db
                error:errorBlk];
  return YES;
}

- (void)markAsSyncCompleteForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk {
  [_localModelUtils markAsSyncCompleteForEntityInTxn:user
                                    masterUpdateStmt:[self updateStmtForMasterUser]
                                 masterUpdateArgsBlk:^(id entity){return [self updateArgsForMasterUser:(PELMUser *)entity];}
                                               error:errorBlk];
}

- (NSInteger)numUnsyncedEntitiesForUser:(PELMUser *)user entityTable:(NSString *)entityTable {
  __block NSInteger numEntities = 0;
  if ([user localMainIdentifier]) {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
      NSString *qry = [NSString stringWithFormat:@"select count(*) from %@ where \
                       %@ = ? and \
                       %@ = 0", entityTable,
                       COL_MASTER_USER_ID,
                       COL_SYNCED];
      FMResultSet *rs = [db executeQuery:qry
                    withArgumentsInArray:@[[user localMasterIdentifier]]];
      [rs next];
      numEntities = [rs intForColumnIndex:0];
      [rs next]; // to not have 'open result set' warning
      [rs close];
    }];
  }
  return numEntities;
}

- (NSInteger)numSyncNeededEntitiesForUser:(PELMUser *)user
                  importLimitExceededMask:(NSNumber *)importLimitExceededMask
                              entityTable:(NSString *)entityTable {
  __block NSInteger numEntities = 0;
  if ([user localMainIdentifier]) {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
      NSMutableArray *args = [NSMutableArray array];
      NSMutableString *qry = [[NSMutableString alloc] init];
      [qry appendString:[NSString stringWithFormat:@"select count(*) from %@ where \
                         %@ = ? and \
                         %@ = 0 and \
                         %@ = 0 and \
                         (%@ is null or %@ <= 0",
                         entityTable,
                         COL_MASTER_USER_ID,
                         COL_SYNCED,
                         COL_SYNC_IN_PROGRESS,
                         COL_SYNC_ERR_MASK,
                         COL_SYNC_ERR_MASK]];
      [args addObject:[user localMasterIdentifier]];
      if (importLimitExceededMask) {
        [qry appendString:[NSString stringWithFormat:@" or %@ = ?)", COL_SYNC_ERR_MASK]];
        [args addObject:importLimitExceededMask];
      } else {
        [qry appendString:@")"];
      }
      FMResultSet *rs = [db executeQuery:qry withArgumentsInArray:args];
      [rs next];
      numEntities = [rs intForColumnIndex:0];
      [rs next]; // to not have 'open result set' warning
      [rs close];
    }];
  }
  return numEntities;
}

#pragma mark - Persistence Helpers

- (NSString *)updateStmtForMasterUser {
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
          TBL_MASTER_USER,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,
          COL_USR_NAME,
          COL_USR_EMAIL,
          COL_USR_PASSWORD_HASH,
          COL_USR_VERIFIED_AT,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_USR_LAST_CHARGE_ID,
          COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT,
          COL_USR_LATEST_STRIPE_TOKEN_ID,
          COL_USR_NEXT_INVOICE_AT,
          COL_USR_NEXT_INVOICE_AMOUNT,
          COL_USR_LAST_INVOICE_AT,
          COL_USR_LAST_INVOICE_AMOUNT,
          COL_USR_CURRENT_CARD_LAST4,
          COL_USR_CURRENT_CARD_BRAND,
          COL_USR_CURRENT_CARD_EXP_MONTH,
          COL_USR_CURRENT_CARD_EXP_YEAR,
          COL_USR_TRIAL_ENDS_AT,
          COL_USR_STRIPE_CUSTOMER_ID,
          COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT,
          COL_USR_NEW_MOVEMENTS_ADDED_AT,
          COL_USR_INFORMED_OF_MAINTENANCE_AT,
          COL_USR_MAINTENANCE_STARTS_AT,
          COL_USR_MAINTENANCE_DURATION,
          COL_USR_IS_PAYMENT_PAST_DUE,
          COL_USR_PAID_ENROLLMENT_CANCELLED_AT,
          COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT,
          COL_USR_VALIDATE_APP_STORE_RECEIPT_AT,
          COL_USR_MAX_ALLOWED_SET_IMPORT,
          COL_USR_MAX_ALLOWED_BML_IMPORT,
          COL_USR_FACEBOOK_USER_ID,
          COL_USR_HAS_PASSWORD,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterUser:(PELMUser *)user {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([user globalIdentifier]),
           orNil([[user mediaType] description]),
           orNil([PEUtils millisecondsFromDate:[user createdAt]]),
           orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
           orNil([PEUtils millisecondsFromDate:[user deletedAt]]),
           orNil([user name]),
           orNil([user email]),
           orNil([user password]),
           orNil([PEUtils millisecondsFromDate:[user verifiedAt]]),
           [NSNumber numberWithBool:[user syncInProgress]],
           [NSNumber numberWithBool:[user synced]],
           orNil([user syncHttpRespCode]),
           orNil([user syncErrMask]),
           orNil([PEUtils millisecondsFromDate:[user syncRetryAt]]),
           orNil([user lastChargeId]),
           orNil([PEUtils millisecondsFromDate:[user trialAlmostExpiredNoticeSentAt]]),
           orNil([user latestStripeTokenId]),
           orNil([PEUtils millisecondsFromDate:[user nextInvoiceAt]]),
           orNil([user nextInvoiceAmount]),
           orNil([PEUtils millisecondsFromDate:[user lastInvoiceAt]]),
           orNil([user lastInvoiceAmount]),
           orNil([user currentCardLast4]),
           orNil([user currentCardBrand]),
           orNil([user currentCardExpMonth]),
           orNil([user currentCardExpYear]),
           orNil([PEUtils millisecondsFromDate:[user trialEndsAt]]),
           orNil([user stripeCustomerId]),
           orNil([PEUtils millisecondsFromDate:[user paidEnrollmentEstablishedAt]]),
           orNil([PEUtils millisecondsFromDate:[user newishMovementsAddedAt]]),
           orNil([PEUtils millisecondsFromDate:[user informedOfMaintenanceAt]]),
           orNil([PEUtils millisecondsFromDate:[user maintenanceStartsAt]]),
           orNil([user maintenanceDuration]),
           [NSNumber numberWithBool:[user isPaymentPastDue]],
           orNil([PEUtils millisecondsFromDate:[user paidEnrollmentCancelledAt]]),
           orNil([PEUtils millisecondsFromDate:[user finalFailedPaymentAttemptOccurredAt]]),
           orNil([PEUtils millisecondsFromDate:[user validateAppStoreReceiptAt]]),
           orNil([user maxAllowedSetImport]),
           orNil([user maxAllowedBmlImport]),
           orNil([user facebookUserId]),
           [NSNumber numberWithBool:[user hasPassword]],
           [user localMasterIdentifier]];
}

- (NSString *)updateStmtForMasterUserReadonlyFields {
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
          %@ = ? \
          WHERE %@ = ?",
          TBL_MASTER_USER,
          COL_GLOBAL_ID,
          COL_USR_VERIFIED_AT,
          COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT,
          COL_USR_NEW_MOVEMENTS_ADDED_AT,
          COL_USR_INFORMED_OF_MAINTENANCE_AT,
          COL_USR_MAINTENANCE_STARTS_AT,
          COL_USR_MAINTENANCE_DURATION,
          COL_USR_IS_PAYMENT_PAST_DUE,
          COL_USR_PAID_ENROLLMENT_CANCELLED_AT,
          COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT,
          COL_USR_VALIDATE_APP_STORE_RECEIPT_AT,
          COL_LOCAL_ID];
}

- (NSArray *)updateArgsForMasterUserReadonlyFields:(PELMUser *)user {
  PELMOrNil orNil = [PELMUtils makeOrNil];
  return @[orNil([user globalIdentifier]),
           orNil([PEUtils millisecondsFromDate:[user verifiedAt]]),
           orNil([PEUtils millisecondsFromDate:[user paidEnrollmentEstablishedAt]]),
           orNil([PEUtils millisecondsFromDate:[user newishMovementsAddedAt]]),
           orNil([PEUtils millisecondsFromDate:[user informedOfMaintenanceAt]]),
           orNil([PEUtils millisecondsFromDate:[user maintenanceStartsAt]]),
           orNil([user maintenanceDuration]),
           [NSNumber numberWithBool:[user isPaymentPastDue]],
           orNil([PEUtils millisecondsFromDate:[user paidEnrollmentCancelledAt]]),
           orNil([PEUtils millisecondsFromDate:[user finalFailedPaymentAttemptOccurredAt]]),
           orNil([PEUtils millisecondsFromDate:[user validateAppStoreReceiptAt]]),
           [user localMasterIdentifier]];
}

- (void)insertIntoMasterUser:(PELMUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk {
  NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, \
%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, \
?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    TBL_MASTER_USER,
                    COL_GLOBAL_ID,
                    COL_MEDIA_TYPE,
                    COL_CREATED_AT,
                    COL_UPDATED_AT,
                    COL_DELETED_DT,
                    COL_USR_NAME,
                    COL_USR_EMAIL,
                    COL_USR_PASSWORD_HASH,
                    COL_USR_VERIFIED_AT,
                    COL_SYNC_IN_PROGRESS,
                    COL_SYNCED,
                    COL_SYNC_HTTP_RESP_CODE,
                    COL_SYNC_ERR_MASK,
                    COL_SYNC_RETRY_AT,
                    COL_USR_LAST_CHARGE_ID,
                    COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT,
                    COL_USR_LATEST_STRIPE_TOKEN_ID,
                    COL_USR_NEXT_INVOICE_AT,
                    COL_USR_NEXT_INVOICE_AMOUNT,
                    COL_USR_LAST_INVOICE_AT,
                    COL_USR_LAST_INVOICE_AMOUNT,
                    COL_USR_CURRENT_CARD_LAST4,
                    COL_USR_CURRENT_CARD_BRAND,
                    COL_USR_CURRENT_CARD_EXP_MONTH,
                    COL_USR_CURRENT_CARD_EXP_YEAR,
                    COL_USR_TRIAL_ENDS_AT,
                    COL_USR_STRIPE_CUSTOMER_ID,
                    COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT,
                    COL_USR_NEW_MOVEMENTS_ADDED_AT,
                    COL_USR_INFORMED_OF_MAINTENANCE_AT,
                    COL_USR_MAINTENANCE_STARTS_AT,
                    COL_USR_MAINTENANCE_DURATION,
                    COL_USR_IS_PAYMENT_PAST_DUE,
                    COL_USR_PAID_ENROLLMENT_CANCELLED_AT,
                    COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT,
                    COL_USR_VALIDATE_APP_STORE_RECEIPT_AT,
                    COL_USR_MAX_ALLOWED_SET_IMPORT,
                    COL_USR_MAX_ALLOWED_BML_IMPORT,
                    COL_USR_FACEBOOK_USER_ID,
                    COL_USR_HAS_PASSWORD];
  PELMOrNil orNil = [PELMUtils makeOrNil];
  [PELMUtils doMasterInsert:stmt
                  argsArray:@[orNil([user globalIdentifier]),
                              orNil([[user mediaType] description]),
                              orNil([PEUtils millisecondsFromDate:[user createdAt]]),
                              orNil([PEUtils millisecondsFromDate:[user updatedAt]]),
                              orNil([PEUtils millisecondsFromDate:[user deletedAt]]),
                              orNil([user name]),
                              orNil([user email]),
                              orNil([user password]),
                              orNil([PEUtils millisecondsFromDate:[user verifiedAt]]),
                              [NSNumber numberWithBool:[user syncInProgress]],
                              [NSNumber numberWithBool:[user synced]],
                              orNil([user syncHttpRespCode]),
                              orNil([user syncErrMask]),
                              orNil([PEUtils millisecondsFromDate:[user syncRetryAt]]),
                              orNil([user lastChargeId]),
                              orNil([PEUtils millisecondsFromDate:[user trialAlmostExpiredNoticeSentAt]]),
                              orNil([user latestStripeTokenId]),
                              orNil([PEUtils millisecondsFromDate:[user nextInvoiceAt]]),
                              orNil([user nextInvoiceAmount]),
                              orNil([PEUtils millisecondsFromDate:[user lastInvoiceAt]]),
                              orNil([user lastInvoiceAmount]),
                              orNil([user currentCardLast4]),
                              orNil([user currentCardBrand]),
                              orNil([user currentCardExpMonth]),
                              orNil([user currentCardExpYear]),
                              orNil([PEUtils millisecondsFromDate:[user trialEndsAt]]),
                              orNil([user stripeCustomerId]),
                              orNil([PEUtils millisecondsFromDate:[user paidEnrollmentEstablishedAt]]),
                              orNil([PEUtils millisecondsFromDate:[user newishMovementsAddedAt]]),
                              orNil([PEUtils millisecondsFromDate:[user informedOfMaintenanceAt]]),
                              orNil([PEUtils millisecondsFromDate:[user maintenanceStartsAt]]),
                              orNil([user maintenanceDuration]),
                              [NSNumber numberWithBool:[user isPaymentPastDue]],
                              orNil([PEUtils millisecondsFromDate:[user paidEnrollmentCancelledAt]]),
                              orNil([PEUtils millisecondsFromDate:[user finalFailedPaymentAttemptOccurredAt]]),
                              orNil([PEUtils millisecondsFromDate:[user validateAppStoreReceiptAt]]),
                              orNil([user maxAllowedSetImport]),
                              orNil([user maxAllowedBmlImport]),
                              orNil([user facebookUserId]),
                              [NSNumber numberWithBool:[user hasPassword]]]
                     entity:user
                         db:db
                      error:errorBlk];
}

#pragma mark - Result Set -> User Helpers

- (PELMUser *)mainUserFromResultSet:(FMResultSet *)rs {
  return [[PELMUser alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
                                 localMasterIdentifier:[rs objectForColumn:COL_LOCAL_ID]
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
                                                  name:[rs stringForColumn:COL_USR_NAME]
                                                 email:[rs stringForColumn:COL_USR_EMAIL]
                                              password:[rs stringForColumn:COL_USR_PASSWORD_HASH]
                                            verifiedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_VERIFIED_AT]
                                          lastChargeId:[rs stringForColumn:COL_USR_LAST_CHARGE_ID]
                        trialAlmostExpiredNoticeSentAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT]
                                   latestStripeTokenId:[rs stringForColumn:COL_USR_LATEST_STRIPE_TOKEN_ID]
                                         nextInvoiceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_NEXT_INVOICE_AT]
                                     nextInvoiceAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USR_NEXT_INVOICE_AMOUNT]
                                         lastInvoiceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_LAST_INVOICE_AT]
                                     lastInvoiceAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USR_LAST_INVOICE_AMOUNT]
                                      currentCardLast4:[rs stringForColumn:COL_USR_CURRENT_CARD_LAST4]
                                      currentCardBrand:[rs stringForColumn:COL_USR_CURRENT_CARD_BRAND]
                                    currentCardExpYear:[PELMUtils numberFromResultSet:rs columnName:COL_USR_CURRENT_CARD_EXP_YEAR]
                                   currentCardExpMonth:[PELMUtils numberFromResultSet:rs columnName:COL_USR_CURRENT_CARD_EXP_MONTH]
                                           trialEndsAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_TRIAL_ENDS_AT]
                                      stripeCustomerId:[rs stringForColumn:COL_USR_STRIPE_CUSTOMER_ID]
                           paidEnrollmentEstablishedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT]
                                newishMovementsAddedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_NEW_MOVEMENTS_ADDED_AT]
                                informedOfMaintenanceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_INFORMED_OF_MAINTENANCE_AT]
                                   maintenanceStartsAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_MAINTENANCE_STARTS_AT]
                                   maintenanceDuration:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAINTENANCE_DURATION]
                                      isPaymentPastDue:[rs boolForColumn:COL_USR_IS_PAYMENT_PAST_DUE]
                             paidEnrollmentCancelledAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_PAID_ENROLLMENT_CANCELLED_AT]
                   finalFailedPaymentAttemptOccurredAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT]
                             validateAppStoreReceiptAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_VALIDATE_APP_STORE_RECEIPT_AT]
                                   maxAllowedSetImport:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAX_ALLOWED_SET_IMPORT]
                                   maxAllowedBmlImport:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAX_ALLOWED_BML_IMPORT]
                                        facebookUserId:[rs stringForColumn:COL_USR_FACEBOOK_USER_ID]
                                           hasPassword:[rs boolForColumn:COL_USR_HAS_PASSWORD]];
}

- (PELMUser *)masterUserFromResultSet:(FMResultSet *)rs {
  return [[PELMUser alloc] initWithLocalMainIdentifier:[rs objectForColumn:COL_LOCAL_ID]
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
                                                  name:[rs stringForColumn:COL_USR_NAME]
                                                 email:[rs stringForColumn:COL_USR_EMAIL]
                                              password:[rs stringForColumn:COL_USR_PASSWORD_HASH]
                                            verifiedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_VERIFIED_AT]
                                          lastChargeId:[rs stringForColumn:COL_USR_LAST_CHARGE_ID]
                        trialAlmostExpiredNoticeSentAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT]
                                   latestStripeTokenId:[rs stringForColumn:COL_USR_LATEST_STRIPE_TOKEN_ID]
                                         nextInvoiceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_NEXT_INVOICE_AT]
                                     nextInvoiceAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USR_NEXT_INVOICE_AMOUNT]
                                         lastInvoiceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_LAST_INVOICE_AT]
                                     lastInvoiceAmount:[PELMUtils numberFromResultSet:rs columnName:COL_USR_LAST_INVOICE_AMOUNT]
                                      currentCardLast4:[rs stringForColumn:COL_USR_CURRENT_CARD_LAST4]
                                      currentCardBrand:[rs stringForColumn:COL_USR_CURRENT_CARD_BRAND]
                                    currentCardExpYear:[PELMUtils numberFromResultSet:rs columnName:COL_USR_CURRENT_CARD_EXP_YEAR]
                                   currentCardExpMonth:[PELMUtils numberFromResultSet:rs columnName:COL_USR_CURRENT_CARD_EXP_MONTH]
                                           trialEndsAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_TRIAL_ENDS_AT]
                                      stripeCustomerId:[rs stringForColumn:COL_USR_STRIPE_CUSTOMER_ID]
                           paidEnrollmentEstablishedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT]
                                newishMovementsAddedAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_NEW_MOVEMENTS_ADDED_AT]
                                informedOfMaintenanceAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_INFORMED_OF_MAINTENANCE_AT]
                                   maintenanceStartsAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_MAINTENANCE_STARTS_AT]
                                   maintenanceDuration:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAINTENANCE_DURATION]
                                      isPaymentPastDue:[rs boolForColumn:COL_USR_IS_PAYMENT_PAST_DUE]
                             paidEnrollmentCancelledAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_PAID_ENROLLMENT_CANCELLED_AT]
                   finalFailedPaymentAttemptOccurredAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT]
                             validateAppStoreReceiptAt:[PELMUtils dateFromResultSet:rs columnName:COL_USR_VALIDATE_APP_STORE_RECEIPT_AT]
                                   maxAllowedSetImport:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAX_ALLOWED_SET_IMPORT]
                                   maxAllowedBmlImport:[PELMUtils numberFromResultSet:rs columnName:COL_USR_MAX_ALLOWED_BML_IMPORT]
                                        facebookUserId:[rs stringForColumn:COL_USR_FACEBOOK_USER_ID]
                                           hasPassword:[rs boolForColumn:COL_USR_HAS_PASSWORD]];
}

@end
