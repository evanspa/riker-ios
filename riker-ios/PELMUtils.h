//
//  PELMUtils.h
//

@import Foundation;
#import "PELMDefs.h"

@class FMDatabase;
@class FMDatabaseQueue;
@class FMResultSet;
@class HCAuthentication;

@class PELMModelSupport;
@class PELMMainSupport;
@class PELMMasterSupport;

FOUNDATION_EXPORT NSString * const GLOBAL_IDENTIFIER_PREFIX;

@interface PELMUtils : NSObject

#pragma mark - Initializers

- (id)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue;

#pragma mark - Completion Handler Makers

+ (PELMRemoteMasterCompletionHandler)complHandlerToFlushUnsyncedChangesToEntity:(PELMMainSupport *)entity
                                                            remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                                              entityNotFoundBlk:(void(^)(void))entityNotFoundBlk
                                              markAsSyncCompleteForNewEntityBlk:(void(^)(id))markAsSyncCompleteForNewEntityBlk
                                         markAsSyncCompleteForExistingEntityBlk:(void(^)(id))markAsSyncCompleteForExistingEntityBlk
                                                                newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk;

+ (PELMRemoteMasterCompletionHandler)complHandlerToDeleteEntity:(PELMMainSupport *)entity
                                            remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                              entityNotFoundBlk:(void(^)(void))entityNotFoundBlk                                              
                                               deleteSuccessBlk:(void(^)(void))deleteSuccessBlk
                                                newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk;

+ (PELMRemoteMasterCompletionHandler)complHandlerToFetchEntityWithGlobalId:(NSString *)globalId
                                                       remoteStoreErrorBlk:(void(^)(NSError *, NSNumber *))remoteStoreErrorBlk
                                                         entityNotFoundBlk:(void(^)(void))entityNotFoundBlk
                                                          fetchCompleteBlk:(void(^)(id))fetchCompleteBlk
                                                           newAuthTokenBlk:(void(^)(NSString *))newAuthTokenBlk;

+ (void)cancelSyncInProgressForEntityTable:(NSString *)entityTable
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)error;

#pragma mark - Result Set Helpers

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs columnName:(NSString *)columnName;

+ (NSNumber *)numberFromResultSet:(FMResultSet *)rs columnIndex:(int)columnIndex;

+ (NSDecimalNumber *)decimalNumberFromResultSet:(FMResultSet *)rs columnName:(NSString *)columnName;

+ (NSDate *)dateFromResultSet:(FMResultSet *)rs columnName:(NSString *)columnName;

+ (BOOL)boolFromResultSet:(FMResultSet *)rs columnName:(NSString *)columnName boolIfNull:(BOOL)boolIfNull;

#pragma mark - Properties

@property (nonatomic, readonly) FMDatabaseQueue *databaseQueue;

#pragma mark - Utils

+ (NSArray *)numberArrayFromQuery:(NSString *)query
                             args:(NSArray *)args
                               db:(FMDatabase *)db
                            error:(PELMDaoErrorBlk)errorBlk;

+ (PELMCannotBe)makeCannotBe;

+ (PELMOrNil)makeOrNil;

- (void)cancelSyncForEntity:(PELMMainSupport *)entity
               httpRespCode:(NSNumber *)httpRespCode
                  errorMask:(NSNumber *)errorMask
                    retryAt:(NSDate *)retryAt
                 updateStmt:(NSString *)updateStmt
              updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                      error:(PELMDaoErrorBlk)errorBlk;

- (void)saveEntity:(PELMMainSupport *)entity
        updateStmt:(NSString *)updateStmt
     updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
             error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingEntity:(PELMMainSupport *)entity
                     updateStmt:(NSString *)updateStmt
                  updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
                          error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingImmediateSyncEntity:(PELMMainSupport *)entity
                                  updateStmt:(NSString *)updateStmt
                               updateArgsBlk:(NSArray *(^)(id))updateArgsBlk
                                       error:(PELMDaoErrorBlk)errorBlk;

- (PELMSaveNewOrExistingCode)saveNewOrExistingByGlobalIdentifierEntity:(PELMMainSupport *)masterEntity
                                                           masterTable:(NSString *)masterTable
                                                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                                      masterUpdateStmt:(NSString *)masterUpdateStmt
                                                   masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                                                 error:(PELMDaoErrorBlk)errorBlk;

+ (PELMSaveNewOrExistingCode)saveNewOrExistingByGlobalIdentifierEntity:(PELMMasterSupport *)masterEntity
                                                           masterTable:(NSString *)masterTable
                                                       masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                                      masterUpdateStmt:(NSString *)masterUpdateStmt
                                                   masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                                                    db:(FMDatabase *)db
                                                                 error:(PELMDaoErrorBlk)errorBlk;

+ (PELMSaveNewOrExistingCode)saveNewOrExistingEntity:(PELMMasterSupport *)masterEntity
                                         masterTable:(NSString *)masterTable
                                     masterInsertBlk:(void (^)(id, FMDatabase *))masterInsertBlk
                                    masterUpdateStmt:(NSString *)masterUpdateStmt
                                 masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                       idSearcherBlk:(NSNumber *(^)(NSString *, PELMMasterSupport *))idSearchBlk
                                                  db:(FMDatabase *)db
                                               error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForEntityInTxn:(PELMMainSupport *)entity
                        masterUpdateStmt:(NSString *)masterUpdateStmt
                     masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                   error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsSyncCompleteForEntity:(PELMMainSupport *)entity
                   masterUpdateStmt:(NSString *)masterUpdateStmt
                masterUpdateArgsBlk:(NSArray *(^)(id))masterUpdateArgsBlk
                                 db:(FMDatabase *)db
                              error:(PELMDaoErrorBlk)errorBlk;

+ (NSNumber *)masterLocalIdFromEntityTable:(NSString *)masterEntityTable
                          globalIdentifier:(NSString *)globalIdentifier
                                        db:(FMDatabase *)db
                                     error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEntitiesAsSyncInProgressUsingQuery:(NSString *)query
                                entityFromResultSet:(PELMEntityFromResultSetBlk)entityFromResultSet
                                         updateStmt:(NSString *)updateStmt
                                      updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                                          filterBlk:(BOOL(^)(PELMMainSupport *))filterBlk
                            importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                               user:(PELMUser *)user
                                      importedAtBlk:(PELMImportedAtBlk)importedAtBlk
                          hasExceededImportLimitBlk:(PELMHasExceededImportLimit)hasExceededImportLimitBlk
                                              error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)markEntitiesAsSyncInProgressInTable:(NSString *)table
                             entityFromResultSet:(PELMEntityFromResultSetBlk)entityFromResultSet
                                      updateStmt:(NSString *)updateStmt
                                   updateArgsBlk:(NSArray *(^)(PELMMainSupport *))updateArgsBlk
                         importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                            user:(PELMUser *)user
                                   importedAtBlk:(PELMImportedAtBlk)importedAtBlk
                       hasExceededImportLimitBlk:(PELMHasExceededImportLimit)hasExceededImportLimitBlk
                                           error:(PELMDaoErrorBlk)errorBlk;

+ (void)invokeError:(PELMDaoErrorBlk)errorBlk db:(FMDatabase *)db;

+ (void)deleteEntity:(PELMModelSupport *)entity
               table:(NSString *)table
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk;

+ (void)deleteFromTable:(NSString *)table
           whereColumns:(NSArray *)whereColumns
            whereValues:(NSArray *)whereValues
                     db:(FMDatabase *)db
                  error:(PELMDaoErrorBlk)errorBlk;

- (void)pruneAllSyncedFromMainTables:(NSArray *)tableNames
                               error:(PELMDaoErrorBlk)errorBlk;

+ (void)doMainInsert:(NSString *)stmt
           argsArray:(NSArray *)argsArray
              entity:(PELMMainSupport *)entity
                  db:(FMDatabase *)db
               error:(PELMDaoErrorBlk)errorBlk;

+ (void)doMasterInsert:(NSString *)stmt
             argsArray:(NSArray *)argsArray
                entity:(PELMModelSupport *)entity
                    db:(FMDatabase *)db
                 error:(PELMDaoErrorBlk)errorBlk;

+ (void)doUpdate:(NSString *)stmt
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk;

+ (void)doUpdate:(NSString *)stmt
       argsArray:(NSArray *)argsArray
              db:(FMDatabase *)db
           error:(PELMDaoErrorBlk)errorBlk;

- (void)doUpdateInTxn:(NSString *)stmt
            argsArray:(NSArray *)argsArray
                error:(PELMDaoErrorBlk)errorBlk;

+ (FMResultSet *)doQuery:(NSString *)query
               argsArray:(NSArray *)argsArray
                      db:(FMDatabase *)db
                   error:(PELMDaoErrorBlk)errorBlk;

+ (id)entityFromQuery:(NSString *)query
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk;

+ (id)entityFromQuery:(NSString *)query
            argsArray:(NSArray *)argsArray
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                   db:(FMDatabase *)db
                error:(PELMDaoErrorBlk)errorBlk;

- (id)entityFromQuery:(NSString *)query
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk;

- (id)entityFromQuery:(NSString *)query
            argsArray:(NSArray *)argsArray
          rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                error:(PELMDaoErrorBlk)errorBlk;

- (NSArray *)entitiesFromQuery:(NSString *)query
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                         error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)entitiesFromQuery:(NSString *)query
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk;

+ (NSArray *)entitiesFromQuery:(NSString *)query
                    numAllowed:(NSNumber *)numAllowed
                     argsArray:(NSArray *)argsArray
                   rsConverter:(PELMEntityFromResultSetBlk)rsConverter
                            db:(FMDatabase *)db
                         error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Helpers

+ (NSDate *)maxDateFromTable:(NSString *)table
                  dateColumn:(NSString *)dateColumn
                 whereColumn:(NSString *)whereColumn
                  whereValue:(id)whereValue
                          db:(FMDatabase *)db
                       error:(PELMDaoErrorBlk)errorBlk;

+ (NSDate *)dateFromTable:(NSString *)table
               dateColumn:(NSString *)dateColumn
              whereColumn:(NSString *)whereColumn
               whereValue:(id)whereValue
                       db:(FMDatabase *)db
                    error:(PELMDaoErrorBlk)errorBlk;

+ (NSDate *)dateFromQuery:(NSString *)query
                     args:(NSArray *)args
                       db:(FMDatabase *)db;

- (NSDate *)dateFromQuery:(NSString *)query
                     args:(NSArray *)args;

- (NSInteger)intFromQuery:(NSString *)query
                     args:(NSArray *)args;

+ (NSInteger)intFromQuery:(NSString *)query
                     args:(NSArray *)args
                       db:(FMDatabase *)db;

- (NSNumber *)numberFromQuery:(NSString *)query
                         args:(NSArray *)args;

+ (NSNumber *)numberFromQuery:(NSString *)query
                         args:(NSArray *)args
                           db:(FMDatabase *)db;

- (NSInteger)numRowsFromTable:(NSString *)table
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSInteger)numRowsFromTable:(NSString *)table
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSInteger)numRowsFromTable:(NSString *)table
                        since:(NSDate *)since
                  sinceColumn:(NSString *)sinceColumn
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSInteger)numRowsFromTable:(NSString *)table
                      equalTo:(NSString *)equalTo
                equalToColumn:(NSString *)equalToColumn
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSNumber *)numberFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

- (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                        error:(PELMDaoErrorBlk)errorBlk;

+ (NSString *)stringFromTable:(NSString *)table
                 selectColumn:(NSString *)selectColumn
                  whereColumn:(NSString *)whereColumn
                   whereValue:(id)whereValue
                           db:(FMDatabase *)db
                        error:(PELMDaoErrorBlk)errorBlk;

@end
