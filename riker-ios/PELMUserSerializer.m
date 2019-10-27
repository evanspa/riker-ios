//
//  RUserSerializer.m
//

#import "PELMUserSerializer.h"
#import "PELMUser.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "NSDictionary+PEAdditions.h"
#import "HCUtils.h"

NSString * const RUserFullnameKey                   = @"user/name";
NSString * const RUserEmailKey                      = @"user/email";
NSString * const RUserPasswordKey                   = @"user/password";
NSString * const RUserCurrentPasswordKey            = @"user/current-password";
NSString * const RUserVerifiedAtKey                 = @"user/verified-at";
NSString * const RUserCreatedAtKey                  = @"user/created-at";
NSString * const RUserUpdatedAtKey                  = @"user/updated-at";
NSString * const RUserDeletedAtKey                  = @"user/deleted-at";
NSString * const RUserLastChargeIdKey               = @"user/last-charge-id";
NSString * const RUserTrialAlmostExpNoticeSentAtKey = @"user/trial-almost-expired-notice-sent-at";
NSString * const RUserLatestStripeTokenIdKey        = @"user/latest-stripe-token-id";
NSString * const RUserNextInvoiceAtKey              = @"user/next-invoice-at";
NSString * const RUserNextInvoiceAmountKey          = @"user/next-invoice-amount";
NSString * const RUserLastInvoiceAtKey              = @"user/last-invoice-at";
NSString * const RUserLastInvoiceAmountKey          = @"user/last-invoice-amount";
NSString * const RUserCurrentCardLast4Key           = @"user/current-card-last4";
NSString * const RUserCurrentCardBrandKey           = @"user/current-card-brand";
NSString * const RUserCurrentCardExpYearKey         = @"user/current-card-exp-year";
NSString * const RUsercurrentCardExpMonthKey        = @"user/current-card-exp-month";
NSString * const RUserTrialEndsAtKey                = @"user/trial-ends-at";
NSString * const RUserStripeCustomerIdKey           = @"user/stripe-customer-id";
NSString * const RUserPaidEnrollmentEstAtKey        = @"user/paid-enrollment-established-at";
NSString * const RUserNewMovementsAddedAtKey        = @"user/new-movements-added-at";
NSString * const RUserInformedOfMaintenanceAtKey    = @"user/informed-of-maintenance-at";
NSString * const RUserMaintenanceStartsAtKey        = @"user/maintenance-starts-at";
NSString * const RUserMaintenanceDurationKey        = @"user/maintenance-duration";
NSString * const RUserIsPaymentPastDueKey           = @"user/is-payment-past-due";
NSString * const RUserPaidEnrollmentCancelledAtKey  = @"user/paid-enrollment-cancelled-at";
NSString * const RUserFinalFailedPaymentAttemptOccurredAt = @"user/final-failed-payment-attempt-occurred-at";
NSString * const RUserCancelSubscriptionKey         = @"user/cancel-subscription";
NSString * const RUserPaidEnrollmentCancelledReasonKey = @"user/paid-enrollment-cancelled-reason";
NSString * const RUserAppStoreReceiptDataBase64Key  = @"user/app-store-receipt-data-base64";
NSString * const RUserValidateAppStoreReceiptAtKey  = @"user/validate-app-store-receipt-at";
NSString * const RUserMaxAllowedSetImportKey        = @"user/max-allowed-set-import";
NSString * const RUserMaxAllowedBmlImportKey        = @"user/max-allowed-bml-import";
NSString * const RUserFacebookUserIdKey             = @"user/facebook-user-id";
NSString * const RUserHasPasswordKey                = @"user/has-password";

@implementation PELMUserSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMUser *user = (PELMUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict nullSafeSetObject:[user currentPassword] forKey:RUserCurrentPasswordKey];
  [userDict setStringIfNotBlank:[user password] forKey:RUserPasswordKey];
  if (user.cancelSubscription && user.cancelSubscription.boolValue) {
    [userDict setObject:[NSNumber numberWithBool:YES] forKey:RUserCancelSubscriptionKey];
    [userDict setStringIfNotBlank:user.paidEnrollmentCancelledReason forKey:RUserPaidEnrollmentCancelledReasonKey];
    // that's right, we don't transmit the email if the user is cancelling their
    // account subscription
  } else {
    [userDict nullSafeSetObject:[user email] forKey:RUserEmailKey];
  }
  [userDict setStringIfNotBlank:user.appStoreReceiptDataBase64 forKey:RUserAppStoreReceiptDataBase64Key];
  [userDict setObjectIfNotNull:user.facebookUserId forKey:RUserFacebookUserIdKey];
  return userDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [PELMUser userWithName:[resDict objectForKey:RUserFullnameKey]
                          email:[resDict objectForKey:RUserEmailKey]
                       password:[resDict objectForKey:RUserPasswordKey]
                     verifiedAt:[resDict dateSince1970ForKey:RUserVerifiedAtKey]
                   lastChargeId:resDict[RUserLastChargeIdKey]
 trialAlmostExpiredNoticeSentAt:[resDict dateSince1970ForKey:RUserTrialAlmostExpNoticeSentAtKey]
            latestStripeTokenId:resDict[RUserLatestStripeTokenIdKey]
                  nextInvoiceAt:[resDict dateSince1970ForKey:RUserNextInvoiceAtKey]
              nextInvoiceAmount:resDict[RUserNextInvoiceAmountKey]
                  lastInvoiceAt:[resDict dateSince1970ForKey:RUserLastInvoiceAtKey]
              lastInvoiceAmount:resDict[RUserLastInvoiceAmountKey]
               currentCardLast4:resDict[RUserCurrentCardLast4Key]
               currentCardBrand:resDict[RUserCurrentCardBrandKey]
             currentCardExpYear:resDict[RUserCurrentCardExpYearKey]
            currentCardExpMonth:resDict[RUsercurrentCardExpMonthKey]
                    trialEndsAt:[resDict dateSince1970ForKey:RUserTrialEndsAtKey]
               stripeCustomerId:resDict[RUserStripeCustomerIdKey]
    paidEnrollmentEstablishedAt:[resDict dateSince1970ForKey:RUserPaidEnrollmentEstAtKey]
         newishMovementsAddedAt:[resDict dateSince1970ForKey:RUserNewMovementsAddedAtKey]
         informedOfMaintenanceAt:[resDict dateSince1970ForKey:RUserInformedOfMaintenanceAtKey]
            maintenanceStartsAt:[resDict dateSince1970ForKey:RUserMaintenanceStartsAtKey]
            maintenanceDuration:resDict[RUserMaintenanceDurationKey]
               isPaymentPastDue:[resDict boolForKey:RUserIsPaymentPastDueKey]
      paidEnrollmentCancelledAt:[resDict dateSince1970ForKey:RUserPaidEnrollmentCancelledAtKey]
finalFailedPaymentAttemptOccurredAt:[resDict dateSince1970ForKey:RUserFinalFailedPaymentAttemptOccurredAt]
      validateAppStoreReceiptAt:[resDict dateSince1970ForKey:RUserValidateAppStoreReceiptAtKey]
            maxAllowedSetImport:resDict[RUserMaxAllowedSetImportKey]
            maxAllowedBmlImport:resDict[RUserMaxAllowedBmlImportKey]
                 facebookUserId:resDict[RUserFacebookUserIdKey]
                    hasPassword:[resDict[RUserHasPasswordKey] boolValue]
               globalIdentifier:location
                      mediaType:mediaType
                      relations:relations
                      createdAt:[resDict dateSince1970ForKey:RUserCreatedAtKey]
                      deletedAt:[resDict dateSince1970ForKey:RUserDeletedAtKey]
                      updatedAt:[resDict dateSince1970ForKey:RUserUpdatedAtKey]];
}

+ (void)populateUserFieldsOn:(PELMMainSupport *)entity fromDictionary:(NSDictionary *)resDict {
  [entity setVerifiedAt:[resDict dateSince1970ForKey:RUserVerifiedAtKey]];
  [entity setNewishMovementsAddedAt:[resDict dateSince1970ForKey:RUserNewMovementsAddedAtKey]];
  [entity setPaidEnrollmentEstablishedAt:[resDict dateSince1970ForKey:RUserPaidEnrollmentEstAtKey]];
  [entity setIsPaymentPastDue:[resDict boolForKey:RUserIsPaymentPastDueKey]];
  [entity setPaidEnrollmentCancelledAt:[resDict dateSince1970ForKey:RUserPaidEnrollmentCancelledAtKey]];
  [entity setFinalFailedPaymentAttemptOccurredAt:[resDict dateSince1970ForKey:RUserFinalFailedPaymentAttemptOccurredAt]];
  [entity setValidateAppStoreReceiptAt:[resDict dateSince1970ForKey:RUserValidateAppStoreReceiptAtKey]];
  [entity setInformedOfMaintenanceAt:[resDict dateSince1970ForKey:RUserInformedOfMaintenanceAtKey]];
  [entity setMaintenanceStartsAt:[resDict dateSince1970ForKey:RUserMaintenanceStartsAtKey]];
  [entity setMaintenanceDuration:resDict[RUserMaintenanceDurationKey]];
}

@end
