//
//  PELMUser.m
//

#import <DateTools/DateTools.h>
#import "PELMUser.h"
#import "PEUtils.h"
#import "PELMDDL.h"
#import "PELMNotificationNames.h"
#import "PELMUtils.h"

#import "RBodySegment.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMuscleAlias.h"
#import "RMovement.h"
#import "RMovementAlias.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"

NSString * const PELMChangelogRelation = @"changelog";
NSString * const PELMUsersRelation = @"users";
NSString * const PELMContinueWithFacebookRelation = @"continue-with-facebook";
NSString * const PELMLoginRelation = @"login";
NSString * const PELMLightLoginRelation = @"light-login";
NSString * const PELMLogoutRelation = @"logout";
NSString * const PELMLogoutAllOtherRelation = @"logout-all-other";
NSString * const PELMSendVerificationEmailRelation = @"send-verification-email";
NSString * const PELMSendPasswordResetEmailRelation = @"send-password-reset-email";
NSString * const PELMStripeTokensRelation = @"stripetokens";
NSString * const PELMSendEmailConfirmationRelation = @"send-email-confirmation";
NSString * const PELMSetsRelation = @"sets";
NSString * const PELMBmlsRelation = @"bodyjournallogs";

NSString * const PELMUserNameField = @"PELMUserNameField";
NSString * const PELMUserEmailField = @"PELMUserEmailField";
NSString * const PELMUserVerifiedAtField = @"PELMUserVerifiedAtField";

@implementation PELMUser {
  NSMutableArray *_bodySegments;
  NSMutableArray *_muscleGroups;
  NSMutableArray *_muscles;
  NSMutableArray *_muscleAliases;
  NSMutableArray *_movements;
  NSMutableArray *_movementAliases;
  NSMutableArray *_movementVariants;
  NSMutableArray *_originationDevices;

  NSMutableArray *_sets;
  NSMutableArray *_bmls;
}

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
                      hasPassword:(BOOL)hasPassword {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _name = name;
    _email = email;
    _password = password;
    _lastChargeId = lastChargeId;
    _trialAlmostExpiredNoticeSentAt = trialAlmostExpiredNoticeSentAt;
    _latestStripeTokenId = latestStripeTokenId;
    _nextInvoiceAt = nextInvoiceAt;
    _nextInvoiceAmount = nextInvoiceAmount;
    _lastInvoiceAt = lastInvoiceAt;
    _lastInvoiceAmount = lastInvoiceAmount;
    _currentCardLast4 = currentCardLast4;
    _currentCardBrand = currentCardBrand;
    _currentCardExpYear = currentCardExpYear;
    _currentCardExpMonth = currentCardExpMonth;
    _trialEndsAt = trialEndsAt;
    _stripeCustomerId = stripeCustomerId;

    [self setVerifiedAt:verifiedAt];
    [self setPaidEnrollmentEstablishedAt:paidEnrollmentEstablishedAt];
    [self setNewishMovementsAddedAt:newishMovementsAddedAt];
    [self setInformedOfMaintenanceAt:informedOfMaintenanceAt];
    [self setMaintenanceStartsAt:maintenanceStartsAt];
    [self setMaintenanceDuration:maintenanceDuration];
    [self setIsPaymentPastDue:isPaymentPastDue];
    [self setPaidEnrollmentCancelledAt:paidEnrollmentCancelledAt];
    [self setFinalFailedPaymentAttemptOccurredAt:finalFailedPaymentAttemptOccurredAt];
    [self setValidateAppStoreReceiptAt:validateAppStoreReceiptAt];

    _maxAllowedSetImport = maxAllowedSetImport;
    _maxAllowedBmlImport = maxAllowedBmlImport;
    _facebookUserId = facebookUserId;
    _hasPassword = hasPassword;
    
    _bodySegments = [NSMutableArray array];
    _muscleGroups = [NSMutableArray array];
    _muscles = [NSMutableArray array];
    _muscleAliases = [NSMutableArray array];
    _movements = [NSMutableArray array];
    _movementAliases = [NSMutableArray array];
    _movementVariants = [NSMutableArray array];
    _originationDevices = [NSMutableArray array];
    _sets = [NSMutableArray array];
    _bmls = [NSMutableArray array];
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  PELMUser *copy
  = [[PELMUser alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                            localMasterIdentifier:[self localMasterIdentifier]
                                 globalIdentifier:[self globalIdentifier]
                                        mediaType:[self mediaType]
                                        relations:nil
                                        createdAt:[self createdAt]
                                        deletedAt:[self deletedAt]
                                        updatedAt:[self updatedAt]
                             dateCopiedFromMaster:[self dateCopiedFromMaster]
                                   editInProgress:NO
                                   syncInProgress:[self syncInProgress]
                                           synced:[self synced]
                                        editCount:[self editCount]
                                 syncHttpRespCode:[self syncHttpRespCode]
                                      syncErrMask:[self syncErrMask]
                                      syncRetryAt:[self syncRetryAt]
                                             name:_name
                                            email:_email
                                         password:_password
                                       verifiedAt:[self verifiedAt]
                                     lastChargeId:_lastChargeId
                   trialAlmostExpiredNoticeSentAt:_trialAlmostExpiredNoticeSentAt
                              latestStripeTokenId:_latestStripeTokenId
                                    nextInvoiceAt:_nextInvoiceAt
                                nextInvoiceAmount:_nextInvoiceAmount
                                    lastInvoiceAt:_lastInvoiceAt
                                lastInvoiceAmount:_lastInvoiceAmount
                                 currentCardLast4:_currentCardLast4
                                 currentCardBrand:_currentCardBrand
                               currentCardExpYear:_currentCardExpYear
                              currentCardExpMonth:_currentCardExpMonth
                                      trialEndsAt:_trialEndsAt
                                 stripeCustomerId:_stripeCustomerId
                      paidEnrollmentEstablishedAt:[self paidEnrollmentEstablishedAt]
                           newishMovementsAddedAt:[self newishMovementsAddedAt]
                           informedOfMaintenanceAt:[self informedOfMaintenanceAt]
                              maintenanceStartsAt:[self maintenanceStartsAt]
                              maintenanceDuration:[self maintenanceDuration]
                                 isPaymentPastDue:[self isPaymentPastDue]
                        paidEnrollmentCancelledAt:[self paidEnrollmentCancelledAt]
              finalFailedPaymentAttemptOccurredAt:[self finalFailedPaymentAttemptOccurredAt]
                        validateAppStoreReceiptAt:[self validateAppStoreReceiptAt]
                              maxAllowedSetImport:_maxAllowedSetImport
                              maxAllowedBmlImport:_maxAllowedBmlImport
                                   facebookUserId:_facebookUserId
                                      hasPassword:_hasPassword];
  return copy;
}

#pragma mark - Creation Functions

+ (instancetype)userWithName:(NSString *)name
                       email:(NSString *)email
                    password:(NSString *)password
                   mediaType:(HCMediaType *)mediaType {
  return [PELMUser userWithName:name
                          email:email
                       password:password
                     verifiedAt:nil
                   lastChargeId:nil
 trialAlmostExpiredNoticeSentAt:nil
            latestStripeTokenId:nil
                  nextInvoiceAt:nil
              nextInvoiceAmount:nil
                  lastInvoiceAt:nil
              lastInvoiceAmount:nil
               currentCardLast4:nil
               currentCardBrand:nil
             currentCardExpYear:nil
            currentCardExpMonth:nil
                    trialEndsAt:nil
               stripeCustomerId:nil
    paidEnrollmentEstablishedAt:nil
         newishMovementsAddedAt:nil
         informedOfMaintenanceAt:nil
            maintenanceStartsAt:nil
            maintenanceDuration:nil
               isPaymentPastDue:NO
      paidEnrollmentCancelledAt:nil
finalFailedPaymentAttemptOccurredAt:nil
      validateAppStoreReceiptAt:nil
            maxAllowedSetImport:nil
            maxAllowedBmlImport:nil
                 facebookUserId:nil
                    hasPassword:NO
               globalIdentifier:nil
                      mediaType:mediaType
                      relations:nil
                      createdAt:nil
                      deletedAt:nil
                      updatedAt:nil];
}

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
                   updatedAt:(NSDate *)updatedAt {
  return [[PELMUser alloc] initWithLocalMainIdentifier:nil
                                 localMasterIdentifier:nil
                                      globalIdentifier:globalIdentifier
                                             mediaType:mediaType
                                             relations:relations
                                             createdAt:createdAt
                                             deletedAt:deletedAt
                                             updatedAt:updatedAt
                                  dateCopiedFromMaster:nil
                                        editInProgress:NO
                                        syncInProgress:NO
                                                synced:NO
                                             editCount:0
                                      syncHttpRespCode:nil
                                           syncErrMask:nil
                                           syncRetryAt:nil
                                                  name:name
                                                 email:email
                                              password:password
                                            verifiedAt:verifiedAt
                                          lastChargeId:lastChargeId
                        trialAlmostExpiredNoticeSentAt:trialAlmostExpiredNoticeSentAt
                                   latestStripeTokenId:latestStripeTokenId
                                         nextInvoiceAt:nextInvoiceAt
                                     nextInvoiceAmount:nextInvoiceAmount
                                         lastInvoiceAt:lastInvoiceAt
                                     lastInvoiceAmount:lastInvoiceAmount
                                      currentCardLast4:currentCardLast4
                                      currentCardBrand:currentCardBrand
                                    currentCardExpYear:currentCardExpYear
                                   currentCardExpMonth:currentCardExpMonth
                                           trialEndsAt:trialEndsAt
                                      stripeCustomerId:stripeCustomerId
                           paidEnrollmentEstablishedAt:paidEnrollmentEstablishedAt
                                newishMovementsAddedAt:newishMovementsAddedAt
                                informedOfMaintenanceAt:informedOfMaintenanceAt
                                   maintenanceStartsAt:maintenanceStartsAt
                                   maintenanceDuration:maintenanceDuration
                                      isPaymentPastDue:isPaymentPastDue
                             paidEnrollmentCancelledAt:paidEnrollmentCancelledAt
                   finalFailedPaymentAttemptOccurredAt:finalFailedPaymentAttemptOccurredAt
                             validateAppStoreReceiptAt:validateAppStoreReceiptAt
                                   maxAllowedSetImport:maxAllowedSetImport
                                   maxAllowedBmlImport:maxAllowedBmlImport
                                        facebookUserId:facebookUserId
                                           hasPassword:hasPassword];
}

#pragma mark - Uris

- (NSString *)userSpecificUriWithPostfix:(NSString *)postfix {
  return [NSString stringWithFormat:@"%@/%@", self.globalIdentifier, postfix];
}

- (NSString *)stripeTokensUri {
  return [self userSpecificUriWithPostfix:@"stripetokens"];
}

- (NSString *)bmlsImportUri {
  return [self userSpecificUriWithPostfix:@"bodyjournallogsfileimport"];
}

- (NSString *)sendPasswordResetEmailUri {
  return [self userSpecificUriWithPostfix:@"send-password-reset-email"];
}

- (NSString *)sendVerificationEmailUri {
  return [self userSpecificUriWithPostfix:@"send-verification-email"];
}

- (NSString *)setsImportUri {
  return [self userSpecificUriWithPostfix:@"setsfileimport"];
}

- (NSString *)logoutAllOtherUri {
  return [self userSpecificUriWithPostfix:@"logout-all-other"];
}

- (NSString *)logoutUri {
  return [self userSpecificUriWithPostfix:@"logout"];
}

- (NSString *)changeLogUri {
  return [self userSpecificUriWithPostfix:@"changelog"];
}

- (NSString *)setsUri {
  return [self userSpecificUriWithPostfix:@"sets"];
}

- (NSString *)bmlsUri {
  return [self userSpecificUriWithPostfix:@"bodyjournallogs"];
}

#pragma mark - Methods

- (BOOL)areReadonlyPropertiesPersisted {
  return YES;
}

- (void)overwriteDomainProperties:(PELMUser *)user {
  [super overwriteDomainProperties:user];
  [self setName:[user name]];
  [self setEmail:[user email]];
  [self setPassword:[user password]];
  [self setConfirmPassword:[user confirmPassword]];
  [self setVerifiedAt:[user verifiedAt]];
  [self setHasPassword:[user hasPassword]];
  _lastChargeId = [user lastChargeId];
  _trialAlmostExpiredNoticeSentAt = [user trialAlmostExpiredNoticeSentAt];
  _latestStripeTokenId = [user latestStripeTokenId];
  _nextInvoiceAt = [user nextInvoiceAt];
  _nextInvoiceAmount = [user nextInvoiceAmount];
  _lastInvoiceAt = [user lastInvoiceAt];
  _lastInvoiceAmount = [user lastInvoiceAmount];
  _currentCardLast4 = [user currentCardLast4];
  _currentCardBrand = [user currentCardBrand];
  _currentCardExpYear = [user currentCardExpYear];
  _currentCardExpMonth = [user currentCardExpMonth];
  _trialEndsAt = [user trialEndsAt];
  _stripeCustomerId = [user stripeCustomerId];
  _maxAllowedSetImport = [user maxAllowedSetImport];
  _maxAllowedBmlImport = [user maxAllowedBmlImport];
}

- (void)overwrite:(PELMUser *)user {
  [super overwrite:user];
  [self overwriteDomainProperties:user];
}

- (void)addSet:(RSet *)set {
  [_sets addObject:set];
}

- (NSArray *)sets {
  return _sets;
}

- (void)addBodyMeasurementLog:(RBodyMeasurementLog *)bodyMeasurementLog {
  [_bmls addObject:bodyMeasurementLog];
}

- (NSArray *)bodyMeasurementLogs {
  return _bmls;
}

#pragma mark - Getters

- (BOOL)hasPaidAccount {
  return [PEUtils isNotNil:[self paidEnrollmentEstablishedAt]];
}

- (BOOL)hasPaidIapAccount {
  return [self hasPaidAccount] && [PEUtils isNotNil:[self validateAppStoreReceiptAt]];
}

- (BOOL)hasCancelledPaidAccount {
  return [PEUtils isNotNil:[self paidEnrollmentCancelledAt]];
}

- (BOOL)hasLapsedPaidAccount {
  return [PEUtils isNotNil:[self finalFailedPaymentAttemptOccurredAt]];
}

- (BOOL)hasTrialAccount {
  return [PEUtils isNotNil:_trialEndsAt] && ![self hasPaidAccount] && ![self hasCancelledPaidAccount] && ![self hasLapsedPaidAccount];
}

- (BOOL)isTrialPeriodExpired {
  if ([self hasTrialAccount]) {
    return [_trialEndsAt isEarlierThan:[NSDate date]];
  }
  return NO;
}

- (BOOL)isTrialPeriodAlmostExpired {
  if (![self isTrialPeriodExpired]) {
    return [[_trialEndsAt dateBySubtractingDays:5] isEarlierThan:[NSDate date]];
  }
  return NO;
}

- (BOOL)isBadAccount {
  return [self isTrialPeriodExpired] ||
    [self hasLapsedPaidAccount] ||
    [self hasCancelledPaidAccount];
}

- (NSNumber *)userIdPartFromGlobalIdentifier {
  NSString *globalIdentifier = [self globalIdentifier];
  if (globalIdentifier) {
    return [[[NSNumberFormatter alloc] init] numberFromString:[globalIdentifier lastPathComponent]];
  }
  return nil;
}

#pragma mark - Ref Data

- (void)addBodySegment:(RBodySegment *)bodySegment {
  [_bodySegments addObject:bodySegment];
}

- (NSArray *)bodySegments {
  return _bodySegments;
}

- (void)addMuscleGroup:(RMuscleGroup *)muscleGroup {
  [_muscleGroups addObject:muscleGroup];
}

- (NSArray *)muscleGroups {
  return _muscleGroups;
}

- (void)addMuscle:(RMuscle *)muscle {
  [_muscles addObject:muscle];
}

- (NSArray *)muscles {
  return _muscles;
}

- (void)addMuscleAlias:(RMuscleAlias *)muscleAlias {
  [_muscleAliases addObject:muscleAlias];
}

- (NSArray *)muscleAliases {
  return _muscleAliases;
}

- (void)addMovement:(RMovement *)movement {
  [_movements addObject:movement];
}

- (NSArray *)movements {
  return _movements;
}

- (void)addMovementAlias:(RMovementAlias *)movementAlias {
  [_movementAliases addObject:movementAlias];
}

- (NSArray *)movementAliases {
  return _movementAliases;
}

- (void)addMovementVariant:(RMovementVariant *)movementVariant {
  [_movementVariants addObject:movementVariant];
}

- (NSArray *)movementVariants {
  return _movementVariants;
}

- (void)addOriginationDevice:(ROriginationDevice *)originationDevice {
  [_originationDevices addObject:originationDevice];
}

- (NSArray *)originationDevices {
  return _originationDevices;
}

#pragma mark - Equality

- (BOOL)isEqualToUser:(PELMUser *)user {
  if (!user) { return NO; }
  if ([super isEqualToMainSupport:user]) {
    return [PEUtils isString:[self name] equalTo:[user name]] &&
    [PEUtils isString:[self email] equalTo:[user email]] &&
    [PEUtils isString:[self password] equalTo:[user password]] &&
    [PEUtils isDate:[self verifiedAt] equalTo:[user verifiedAt]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMUser class]]) { return NO; }
  return [self isEqualToUser:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self name] hash] ^
  [[self email] hash] ^
  [[self password] hash] ^
  [[self verifiedAt] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@], email: [%@], password: [%@], verified-at: [%@], maxAllowedSetImport: [%@], maxAllowedBmlImport: [%@], lastChargeId: [%@], trialAlmostExpiredNoticeSentAt: [%@], latestStripeTokenId: [%@], nextInvoiceAt: [%@], nextInvoiceAmount: [%@], lastInvoiceAt: [%@], lastInvoiceAmount: [%@], currentCardLast4: [%@], currentCardBrand: [%@], currentCardExpYear: [%@], currentCardExpMonth: [%@], trialEndsAt: [%@], stripeCustomerId: [%@], paidEnrollmentEstablishedAt: [%@], newishMovementsAddedAt: [%@], informedOfMaintenanceAt: [%@], maintenanceStartsAt: [%@], maintenanceDuration: [%@], isPaymentPastDue: [%@], paidEnrollmentCancelledAt: [%@], finalFailedPaymentAttemptOccurredAt: [%@]",
          [super description],
          _name,
          _email,
          _password,
          [self verifiedAt],
          _maxAllowedSetImport,
          _maxAllowedBmlImport,
          _lastChargeId,
          _trialAlmostExpiredNoticeSentAt,
          _latestStripeTokenId,
          _nextInvoiceAt,
          _nextInvoiceAmount,
          _lastInvoiceAt,
          _lastInvoiceAmount,
          _currentCardLast4,
          _currentCardBrand,
          _currentCardExpYear,
          _currentCardExpMonth,
          _trialEndsAt,
          _stripeCustomerId,
          [self paidEnrollmentEstablishedAt],
          [self newishMovementsAddedAt],
          [self informedOfMaintenanceAt],
          [self maintenanceStartsAt],
          [self maintenanceDuration],
          [PEUtils yesNoFromBool:[self isPaymentPastDue]],
          [self paidEnrollmentCancelledAt],
          [self finalFailedPaymentAttemptOccurredAt]];
}

@end
