//
//  PELMMainSupport.m
//

#import <DateTools/DateTools.h>
#import "PELMMainSupport.h"
#import "PEUtils.h"

@implementation PELMMainSupport

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
                      syncRetryAt:(NSDate *)syncRetryAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _dateCopiedFromMaster = dateCopiedFromMaster;
    _syncInProgress = syncInProgress;
    _synced = synced;
    _editCount = editCount;
    _syncHttpRespCode = syncHttpRespCode;
    _syncErrMask = syncErrMask;
    _syncRetryAt = syncRetryAt;
  }
  return self;
}

#pragma mark - Overwriting

- (void)overwriteReadonlyProperties:(PELMMainSupport *)entity {
  [self setPaidEnrollmentEstablishedAt:[entity paidEnrollmentEstablishedAt]];
  [self setNewishMovementsAddedAt:[entity newishMovementsAddedAt]];
  [self setInformedOfMaintenanceAt:[entity informedOfMaintenanceAt]];
  [self setMaintenanceStartsAt:[entity maintenanceStartsAt]];
  [self setMaintenanceDuration:[entity maintenanceDuration]];
  [self setIsPaymentPastDue:[entity isPaymentPastDue]];
  [self setPaidEnrollmentCancelledAt:[entity paidEnrollmentCancelledAt]];
  [self setFinalFailedPaymentAttemptOccurredAt:[entity finalFailedPaymentAttemptOccurredAt]];
  [self setValidateAppStoreReceiptAt:[entity validateAppStoreReceiptAt]];
}

- (void)overwriteDomainProperties:(PELMMainSupport *)entity {
  [self overwriteReadonlyProperties:entity];
}

- (void)overwrite:(PELMMainSupport *)entity {
  [super overwrite:entity];
  [self setDateCopiedFromMaster:[entity dateCopiedFromMaster]];
  [self setSyncInProgress:[entity syncInProgress]];
  [self setSynced:[entity synced]];
  [self setEditCount:[entity editCount]];
  [self setSyncHttpRespCode:[entity syncHttpRespCode]];
  [self setSyncErrMask:[entity syncErrMask]];
  [self setSyncRetryAt:[entity syncRetryAt]];
}

#pragma mark - Methods

- (NSUInteger)incrementEditCount {
  _editCount++;
  return _editCount;
}

- (NSUInteger)decrementEditCount {
  _editCount--;
  return _editCount;
}

- (NSDate *)maintenanceEndsAt {
  if (_maintenanceStartsAt && _maintenanceDuration) {
    return [_maintenanceStartsAt dateByAddingMinutes:_maintenanceDuration.integerValue];
  }
  return nil;
}

- (BOOL)hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:(NSDate *)maintenanceAckAt {
  NSDate *now = [NSDate date];
  return _maintenanceStartsAt &&
  _maintenanceDuration &&
  _informedOfMaintenanceAt &&
  [now isEarlierThan:_maintenanceStartsAt] &&
  ![now isLaterThan:[self maintenanceEndsAt]] &&
    ([PEUtils isNil:maintenanceAckAt] ||
     [maintenanceAckAt isEarlierThan:_informedOfMaintenanceAt]);
}

- (BOOL)isInMaintenanceWindow {
  NSDate *now = [NSDate date];
  return _maintenanceStartsAt &&
  _maintenanceDuration &&
  [now isLaterThanOrEqualTo:_maintenanceStartsAt] &&
  [now isEarlierThanOrEqualTo:[self maintenanceEndsAt]];
}

#pragma mark - Equality

- (BOOL)isEqualToMainSupport:(PELMMainSupport *)mainSupport {
  if (!mainSupport) { return NO; }
  if ([super isEqualToMasterSupport:mainSupport]) {
    BOOL hasEqualCopyFromMasterDates = [PEUtils isDate:[self dateCopiedFromMaster]
                                    msprecisionEqualTo:[mainSupport dateCopiedFromMaster]];
    BOOL hasEqualSyncRetryAtDates = [PEUtils isDate:[self syncRetryAt]
                                 msprecisionEqualTo:[mainSupport syncRetryAt]];
    return hasEqualCopyFromMasterDates &&
      ([self syncInProgress] == [mainSupport syncInProgress]) &&
      [PEUtils isNumber:[self syncHttpRespCode] equalTo:[mainSupport syncHttpRespCode]] &&
      [PEUtils isNumber:[self syncErrMask] equalTo:[mainSupport syncErrMask]] &&
      hasEqualSyncRetryAtDates;
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMMainSupport class]]) { return NO; }
  return [self isEqualToMainSupport:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self dateCopiedFromMaster] hash] ^
    [[NSNumber numberWithBool:[self syncInProgress]] hash] ^
    [[NSNumber numberWithBool:[self synced]] hash] ^
    [_syncHttpRespCode hash] ^
    [_syncErrMask hash] ^
    [_syncRetryAt hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, date copied from master: [{%@}, {%f}], \
sync in progress: [%@], \
synced: [%@], edit count: [%lu], \
sync HTTP resp code: [%@], sync err mask: [%@], sync retry at: [%@]",
          [super description],
          _dateCopiedFromMaster,
          [_dateCopiedFromMaster timeIntervalSince1970],
          [PEUtils trueFalseFromBool:_syncInProgress],
          [PEUtils trueFalseFromBool:_synced],
          (unsigned long)_editCount,
          _syncHttpRespCode,
          _syncErrMask,
          _syncRetryAt];
}

@end
