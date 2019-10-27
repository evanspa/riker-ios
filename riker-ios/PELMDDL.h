//
//  PELocalModelDDL.h
//

@import Foundation;

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
FOUNDATION_EXPORT NSString * const COL_LOCAL_ID;
FOUNDATION_EXPORT NSString * const COL_MAIN_USER_ID;
FOUNDATION_EXPORT NSString * const COL_MASTER_USER_ID;
FOUNDATION_EXPORT NSString * const COL_GLOBAL_ID;
FOUNDATION_EXPORT NSString * const COL_MEDIA_TYPE;
FOUNDATION_EXPORT NSString * const COL_REL_NAME;
FOUNDATION_EXPORT NSString * const COL_REL_URI;
FOUNDATION_EXPORT NSString * const COL_REL_MEDIA_TYPE;
// ----Common master columns----------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CREATED_AT;
FOUNDATION_EXPORT NSString * const COL_UPDATED_AT;
FOUNDATION_EXPORT NSString * const COL_DELETED_DT;
// ----Common main columns------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MAN_MASTER_UPDATED_AT;
FOUNDATION_EXPORT NSString * const COL_MAN_DT_COPIED_DOWN_FROM_MASTER;
FOUNDATION_EXPORT NSString * const COL_EDIT_IN_PROGRESS;
FOUNDATION_EXPORT NSString * const COL_SYNC_IN_PROGRESS;
FOUNDATION_EXPORT NSString * const COL_SYNCED;
FOUNDATION_EXPORT NSString * const COL_EDIT_COUNT;
FOUNDATION_EXPORT NSString * const COL_SYNC_HTTP_RESP_CODE;
FOUNDATION_EXPORT NSString * const COL_SYNC_ERR_MASK;
FOUNDATION_EXPORT NSString * const COL_SYNC_RETRY_AT;

//##############################################################################
// User Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_USER;
FOUNDATION_EXPORT NSString * const TBL_MAIN_USER;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_USR_NAME;
FOUNDATION_EXPORT NSString * const COL_USR_EMAIL;
FOUNDATION_EXPORT NSString * const COL_USR_PASSWORD_HASH;
FOUNDATION_EXPORT NSString * const COL_USR_VERIFIED_AT;
FOUNDATION_EXPORT NSString * const COL_USR_LAST_CHARGE_ID;
FOUNDATION_EXPORT NSString * const COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT;
FOUNDATION_EXPORT NSString * const COL_USR_LATEST_STRIPE_TOKEN_ID;
FOUNDATION_EXPORT NSString * const COL_USR_NEXT_INVOICE_AT;
FOUNDATION_EXPORT NSString * const COL_USR_NEXT_INVOICE_AMOUNT;
FOUNDATION_EXPORT NSString * const COL_USR_LAST_INVOICE_AT;
FOUNDATION_EXPORT NSString * const COL_USR_LAST_INVOICE_AMOUNT;
FOUNDATION_EXPORT NSString * const COL_USR_CURRENT_CARD_LAST4;
FOUNDATION_EXPORT NSString * const COL_USR_CURRENT_CARD_BRAND;
FOUNDATION_EXPORT NSString * const COL_USR_CURRENT_CARD_EXP_MONTH;
FOUNDATION_EXPORT NSString * const COL_USR_CURRENT_CARD_EXP_YEAR;
FOUNDATION_EXPORT NSString * const COL_USR_TRIAL_ENDS_AT;
FOUNDATION_EXPORT NSString * const COL_USR_STRIPE_CUSTOMER_ID;
FOUNDATION_EXPORT NSString * const COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT;
FOUNDATION_EXPORT NSString * const COL_USR_NEW_MOVEMENTS_ADDED_AT;
FOUNDATION_EXPORT NSString * const COL_USR_INFORMED_OF_MAINTENANCE_AT;
FOUNDATION_EXPORT NSString * const COL_USR_MAINTENANCE_STARTS_AT;
FOUNDATION_EXPORT NSString * const COL_USR_MAINTENANCE_DURATION;
FOUNDATION_EXPORT NSString * const COL_USR_IS_PAYMENT_PAST_DUE;
FOUNDATION_EXPORT NSString * const COL_USR_PAID_ENROLLMENT_CANCELLED_AT;
FOUNDATION_EXPORT NSString * const COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT;
FOUNDATION_EXPORT NSString * const COL_USR_VALIDATE_APP_STORE_RECEIPT_AT;
FOUNDATION_EXPORT NSString * const COL_USR_MAX_ALLOWED_SET_IMPORT;
FOUNDATION_EXPORT NSString * const COL_USR_MAX_ALLOWED_BML_IMPORT;
FOUNDATION_EXPORT NSString * const COL_USR_FACEBOOK_USER_ID;
FOUNDATION_EXPORT NSString * const COL_USR_HAS_PASSWORD;

@interface PELMDDL : NSObject

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                         column:(NSString *)column
                      indexName:(NSString *)indexName;

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                        columns:(NSArray *)columns
                      indexName:(NSString *)indexName;

+ (NSString *)relTableForEntityTable:(NSString *)entityTable;

+ (NSString *)relFkColumnForEntityTable:(NSString *)entityTable
                         entityPkColumn:(NSString *)entityPkColumn;

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable
                    entityPkColumn:(NSString *)entityPkColumn;

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable;

@end
