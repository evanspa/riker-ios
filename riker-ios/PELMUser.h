//
//  PELMUser.h
//

@import Foundation;
#import "PELMMainSupport.h"

@class RBodySegment;
@class RMuscleGroup;
@class RMuscle;
@class RMuscleAlias;
@class RMovement;
@class RMovementAlias;
@class RMovementVariant;
@class ROriginationDevice;

@class RSet;
@class RBodyMeasurementLog;
@class RUserSettings;
@class STPToken;

FOUNDATION_EXPORT NSString * const PELMChangelogRelation;
FOUNDATION_EXPORT NSString * const PELMUsersRelation;
FOUNDATION_EXPORT NSString * const PELMContinueWithFacebookRelation;
FOUNDATION_EXPORT NSString * const PELMLoginRelation;
FOUNDATION_EXPORT NSString * const PELMLightLoginRelation;
FOUNDATION_EXPORT NSString * const PELMLogoutRelation;
FOUNDATION_EXPORT NSString * const PELMLogoutAllOtherRelation;
FOUNDATION_EXPORT NSString * const PELMSendVerificationEmailRelation;
FOUNDATION_EXPORT NSString * const PELMSendPasswordResetEmailRelation;
FOUNDATION_EXPORT NSString * const PELMStripeTokensRelation;
FOUNDATION_EXPORT NSString * const PELMSendEmailConfirmationRelation;
FOUNDATION_EXPORT NSString * const PELMSetsRelation;
FOUNDATION_EXPORT NSString * const PELMBmlsRelation;

FOUNDATION_EXPORT NSString * const PELMUserNameField;
FOUNDATION_EXPORT NSString * const PELMUserEmailField;
FOUNDATION_EXPORT NSString * const PELMUserVerifiedAtField;

@interface PELMUser : PELMMainSupport <NSCopying>

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
                             name:(NSString *)name
                            email:(NSString *)email
                         password:(NSString *)password
                       verifiedAt:(NSDate *)verifiedAt
                     lastChargeId:(NSString *)lastChargeId
   trialAlmostExpiredNoticeSentAt:(NSDate *)trialAlmostExpiredNoticeSentAt
              latestStripeTokenId:(NSString *)latestStripeTokenId
                    nextInvoiceAt:(NSDate *)nextInvoiceAt
                nextInvoiceAmount:(NSNumber *)nextInvoiceAmount
                    lastInvoiceAt:(NSDate *)lastInvoiceAt
                lastInvoiceAmount:(NSNumber *)lastInvoiceAmount
                 currentCardLast4:(NSString *)currentCardLast4
                 currentCardBrand:(NSString *)currentCardBrand
               currentCardExpYear:(NSNumber *)currentCardExpYear
              currentCardExpMonth:(NSNumber *)currentCardExpMonth
                      trialEndsAt:(NSDate *)trialEndsAt
                 stripeCustomerId:(NSString *)stripeCustomerId
      paidEnrollmentEstablishedAt:(NSDate *)paidEnrollmentEstablishedAt
           newishMovementsAddedAt:(NSDate *)newishMovementsAddedAt
           informedOfMaintenanceAt:(NSDate *)informedOfMaintenanceAt
              maintenanceStartsAt:(NSDate *)maintenanceStartsAt
              maintenanceDuration:(NSNumber *)maintenanceDuration
                 isPaymentPastDue:(BOOL)isPaymentPastDue
        paidEnrollmentCancelledAt:(NSDate *)paidEnrollmentCancelledAt
finalFailedPaymentAttemptOccurredAt:(NSDate *)finalFailedPaymentAttemptOccurredAt
        validateAppStoreReceiptAt:(NSDate *)validateAppStoreReceiptAt
              maxAllowedSetImport:(NSNumber *)maxAllowedSetImport
              maxAllowedBmlImport:(NSNumber *)maxAllowedBmlImport
                   facebookUserId:(NSString *)facebookUserId
                      hasPassword:(BOOL)hasPassword;

#pragma mark - Creation Functions

+ (instancetype)userWithName:(NSString *)name
                       email:(NSString *)email
                    password:(NSString *)password
                   mediaType:(HCMediaType *)mediaType;

+ (instancetype)userWithName:(NSString *)name
                       email:(NSString *)email
                    password:(NSString *)password
                  verifiedAt:(NSDate *)verifiedAt
                lastChargeId:(NSString *)lastChargeId
trialAlmostExpiredNoticeSentAt:(NSDate *)trialAlmostExpiredNoticeSentAt
         latestStripeTokenId:(NSString *)latestStripeTokenId
               nextInvoiceAt:(NSDate *)nextInvoiceAt
           nextInvoiceAmount:(NSNumber *)nextInvoiceAmount
               lastInvoiceAt:(NSDate *)lastInvoiceAt
           lastInvoiceAmount:(NSNumber *)lastInvoiceAmount
            currentCardLast4:(NSString *)currentCardLast4
            currentCardBrand:(NSString *)currentCardBrand
          currentCardExpYear:(NSNumber *)currentCardExpYear
         currentCardExpMonth:(NSNumber *)currentCardExpMonth
                 trialEndsAt:(NSDate *)trialEndsAt
            stripeCustomerId:(NSString *)stripeCustomerId
 paidEnrollmentEstablishedAt:(NSDate *)paidEnrollmentEstablishedAt
      newishMovementsAddedAt:(NSDate *)newishMovementsAddedAt
      informedOfMaintenanceAt:(NSDate *)informedOfMaintenanceAt
         maintenanceStartsAt:(NSDate *)maintenanceStartsAt
         maintenanceDuration:(NSNumber *)maintenanceDuration
            isPaymentPastDue:(BOOL)isPaymentPastDue
   paidEnrollmentCancelledAt:(NSDate *)paidEnrollmentCancelledAt
finalFailedPaymentAttemptOccurredAt:(NSDate *)finalFailedPaymentAttemptOccurredAt
   validateAppStoreReceiptAt:(NSDate *)validateAppStoreReceiptAt
         maxAllowedSetImport:(NSNumber *)maxAllowedSetImport
         maxAllowedBmlImport:(NSNumber *)maxAllowedBmlImport
              facebookUserId:(NSString *)facebookUserId
                 hasPassword:(BOOL)hasPassword
            globalIdentifier:(NSString *)globalIdentifier
                   mediaType:(HCMediaType *)mediaType
                   relations:(NSDictionary *)relations
                   createdAt:(NSDate *)createdAt
                   deletedAt:(NSDate *)deletedAt
                   updatedAt:(NSDate *)updatedAt;

#pragma mark - Uris

- (NSString *)stripeTokensUri;
- (NSString *)bmlsImportUri;
- (NSString *)sendPasswordResetEmailUri;
- (NSString *)sendVerificationEmailUri;
- (NSString *)setsImportUri;
- (NSString *)logoutAllOtherUri;
- (NSString *)logoutUri;
- (NSString *)changeLogUri;
- (NSString *)setsUri;
- (NSString *)bmlsUri;

#pragma mark - Methods

- (void)overwrite:(PELMUser *)user;

- (void)addSet:(RSet *)set;
- (NSArray *)sets;

- (void)addBodyMeasurementLog:(RBodyMeasurementLog *)bodyMeasurementLog;
- (NSArray *)bodyMeasurementLogs;

#pragma mark - Properties

@property (nonatomic) RUserSettings *userSettings;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *confirmPassword;
@property (nonatomic) NSString *lastChargeId;
@property (nonatomic) NSDate *trialAlmostExpiredNoticeSentAt;
@property (nonatomic) NSString *latestStripeTokenId;
@property (nonatomic) NSDate *nextInvoiceAt;
@property (nonatomic) NSNumber *nextInvoiceAmount;
@property (nonatomic) NSDate *lastInvoiceAt;
@property (nonatomic) NSNumber *lastInvoiceAmount;
@property (nonatomic) NSString *currentCardLast4;
@property (nonatomic) NSString *currentCardBrand;
@property (nonatomic) NSNumber *currentCardExpYear;
@property (nonatomic) NSNumber *currentCardExpMonth;
@property (nonatomic) NSDate *trialEndsAt;
@property (nonatomic) NSString *stripeCustomerId;
@property (nonatomic) NSNumber *cancelSubscription;
@property (nonatomic) NSString *paidEnrollmentCancelledReason;
@property (nonatomic) STPToken *stripeToken;
@property (nonatomic) NSString *appStoreReceiptDataBase64;
@property (nonatomic) NSNumber *maxAllowedSetImport;
@property (nonatomic) NSNumber *maxAllowedBmlImport;
@property (nonatomic) NSString *facebookUserId;
@property (nonatomic) BOOL hasPassword;

#pragma mark - Getters

- (BOOL)hasPaidAccount;
- (BOOL)hasPaidIapAccount;
- (BOOL)hasCancelledPaidAccount;
- (BOOL)hasLapsedPaidAccount;
- (BOOL)hasTrialAccount;
- (BOOL)isTrialPeriodExpired;
- (BOOL)isTrialPeriodAlmostExpired;
- (BOOL)isBadAccount;
- (NSNumber *)userIdPartFromGlobalIdentifier;

#pragma mark - Ref Data

- (void)addBodySegment:(RBodySegment *)bodySegment;
- (NSArray *)bodySegments;

- (void)addMuscleGroup:(RMuscleGroup *)muscleGroup;
- (NSArray *)muscleGroups;

- (void)addMuscle:(RMuscle *)muscle;
- (NSArray *)muscles;

- (void)addMuscleAlias:(RMuscleAlias *)muscleAlias;
- (NSArray *)muscleAliases;

- (void)addMovement:(RMovement *)movement;
- (NSArray *)movements;

- (void)addMovementAlias:(RMovementAlias *)movementAlias;
- (NSArray *)movementAliases;

- (void)addMovementVariant:(RMovementVariant *)movementVariant;
- (NSArray *)movementVariants;

- (void)addOriginationDevice:(ROriginationDevice *)originationDevice;
- (NSArray *)originationDevices;

#pragma mark - Equality

- (BOOL)isEqualToUser:(PELMUser *)user;

@end
