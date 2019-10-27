//
// PELocalDao.h
//

@import Foundation;
#import "PELocalDao.h"

typedef void (^PEUserDbOpBlk)(PELMUser *, FMDatabase *, PELMDaoErrorBlk);

@interface PELocalDaoImpl : NSObject <PELocalDao>

#pragma mark - Master Entity Table Names

- (NSArray *)masterEntityTableNames;

#pragma mark - Pre-Local-Delete User Hook

- (PEUserDbOpBlk)preDeleteUserHookDeleteSettings:(BOOL)deleteSettings;

#pragma mark - Post-Local-Save New User Hook

- (PEUserDbOpBlk)postSaveNewUserHookWithUserSettingsMtVersion:(NSString *)mtVersion;

#pragma mark - Post-Deep Save User Hook

- (PEUserDbOpBlk)postDeepSaveUserHookIsAccountCreation:(BOOL)isAccountCreation;

#pragma mark - Entity Table Names (child -> parent order)

- (NSArray *)entityTableNamesChildToParentOrder;

@end
