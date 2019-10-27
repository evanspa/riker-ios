//
//  PELMMainSupport.h
//

#import "PELMMasterSupport.h"

@interface PELMMainSupport : PELMMasterSupport

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
                      syncRetryAt:(NSDate *)syncRetryAt;

#pragma mark - Overwriting

- (void)overwriteReadonlyProperties:(PELMMainSupport *)entity;

- (void)overwriteDomainProperties:(PELMMainSupport *)entity;

- (void)overwrite:(PELMMainSupport *)entity;

#pragma mark - Properties

// because these user-object datums (ha!) can come back on *any* web service
// response, so we need them here in this parent class
@property (nonatomic) NSDate *verifiedAt;
@property (nonatomic) NSDate *newishMovementsAddedAt;
@property (nonatomic) NSDate *paidEnrollmentEstablishedAt;
@property (nonatomic) BOOL isPaymentPastDue;
@property (nonatomic) NSDate *paidEnrollmentCancelledAt;
@property (nonatomic) NSDate *finalFailedPaymentAttemptOccurredAt;
@property (nonatomic) NSDate *informedOfMaintenanceAt;
@property (nonatomic) NSDate *maintenanceStartsAt;
@property (nonatomic) NSNumber *maintenanceDuration;
@property (nonatomic) NSDate *validateAppStoreReceiptAt;

@property (nonatomic) NSString *currentPassword; // if entity requires user's current password to be set on it

@property (nonatomic) NSDate *dateCopiedFromMaster;
@property (nonatomic) BOOL syncInProgress;
@property (nonatomic) BOOL synced;
@property (nonatomic) NSUInteger editCount;
@property (nonatomic) NSNumber *syncHttpRespCode;
@property (nonatomic) NSNumber *syncErrMask;
@property (nonatomic) NSDate *syncRetryAt;

@property (nonatomic) NSString *uuid; // used to prevent dup-saves from Apple Watch when comm is lost

#pragma mark - Methods

- (NSUInteger)incrementEditCount;
- (NSUInteger)decrementEditCount;
- (NSDate *)maintenanceEndsAt;
- (BOOL)hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:(NSDate *)maintenanceAckAt;
- (BOOL)isInMaintenanceWindow;

#pragma mark - Equality

- (BOOL)isEqualToMainSupport:(PELMMainSupport *)mainSupport;

@end
