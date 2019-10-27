//
// PELocalDao.h
//

#import "PELMUtils.h"
@class FMDatabase;
@class FMDatabaseQueue;
@class PELMUser;
@class PEChangelog;

typedef void (^PELMProcessChangelogEntitiesBlk)(NSArray *,
                                                NSString *,
                                                void(^)(id),
                                                PELMSaveNewOrExistingCode(^)(id),
                                                NSString *);

@protocol PELocalDao <NSObject>

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath;

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue;

#pragma mark - Getters

- (PELMUtils *)localModelUtils;

- (FMDatabaseQueue *)databaseQueue;

#pragma mark - System Functions

- (void)globalCancelSyncInProgressWithError:(PELMDaoErrorBlk)error;

#pragma mark - User Operations

- (void)transformToLocalOnlyUserWithError:(PELMDaoErrorBlk)errorBlk;

- (void)deepSaveNewRemoteUser:(PELMUser *)remoteUser
           andLinkToLocalUser:(PELMUser *)localUser
preserveExistingLocalEntities:(BOOL)preserveExistingLocalEntities
            isAccountCreation:(BOOL)isAccountCreation
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSDate *)mostRecentMasterUpdateForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithId:(NSNumber *)userId error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithGlobalId:(NSString *)globalId error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithError:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)masterUserWithDatabase:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)saveNewLocalUser:(PELMUser *)user
   userSettingsMtVersion:(NSString *)userSettingsMtVersion
                   error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)userWithError:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)userWithDb:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (void)saveUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (PELMUser *)markUserAsSyncInProgressWithError:(PELMDaoErrorBlk)errorBlk;

- (void)cancelSyncForUser:(PELMUser *)user
             httpRespCode:(NSNumber *)httpRespCode
                errorMask:(NSNumber *)errorMask
                  retryAt:(NSDate *)retryAt
                    error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(PELMUser *)user db:(FMDatabase *)db error:(PELMDaoErrorBlk)errorBlk;

- (BOOL)saveMasterUser:(PELMUser *)user
  readOnlyFieldsEntity:(PELMMainSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForUser:(PELMUser *)user error:(PELMDaoErrorBlk)errorBlk;

- (NSInteger)numUnsyncedEntitiesForUser:(PELMUser *)user entityTable:(NSString *)entityTable;

- (NSInteger)numSyncNeededEntitiesForUser:(PELMUser *)user
                  importLimitExceededMask:(NSNumber *)importLimitExceededMask
                              entityTable:(NSString *)entityTable;

#pragma mark - Persistence Helpers

- (NSString *)updateStmtForMasterUser;

- (NSArray *)updateArgsForMasterUser:(PELMUser *)user;

- (NSString *)updateStmtForMasterUserReadonlyFields;

- (NSArray *)updateArgsForMasterUserReadonlyFields:(PELMUser *)user;

- (void)insertIntoMasterUser:(PELMUser *)user
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Result Set -> User Helpers

- (PELMUser *)mainUserFromResultSet:(FMResultSet *)rs;

- (PELMUser *)masterUserFromResultSet:(FMResultSet *)rs;

@end
