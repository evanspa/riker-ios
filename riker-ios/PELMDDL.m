//
//  PELMDDL.m
//

#import "PELMDDL.h"

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
NSString * const COL_LOCAL_ID = @"id";
NSString * const COL_MAIN_USER_ID = @"main_user_id";
NSString * const COL_MASTER_USER_ID = @"master_user_id";
NSString * const COL_GLOBAL_ID = @"global_identifier";
NSString * const COL_MEDIA_TYPE = @"media_type";
NSString * const COL_REL_NAME = @"name";
NSString * const COL_REL_URI = @"uri";
NSString * const COL_REL_MEDIA_TYPE = @"media_type";
// ----Common master columns----------------------------------------------------
NSString * const COL_CREATED_AT = @"created_at";
NSString * const COL_UPDATED_AT = @"updated_at";
NSString * const COL_DELETED_DT = @"deleted_date";
// ----Common main columns------------------------------------------------------
NSString * const COL_MAN_MASTER_UPDATED_AT = @"master_updated_at";
NSString * const COL_MAN_DT_COPIED_DOWN_FROM_MASTER = @"date_copied_down_from_master";
NSString * const COL_EDIT_IN_PROGRESS = @"edit_in_progress";
NSString * const COL_SYNC_IN_PROGRESS = @"sync_in_progress";
NSString * const COL_SYNCED = @"synced";
NSString * const COL_EDIT_COUNT = @"edit_count";
NSString * const COL_SYNC_HTTP_RESP_CODE = @"sync_http_resp_code";
NSString * const COL_SYNC_ERR_MASK = @"sync_http_resp_err_mask";
NSString * const COL_SYNC_RETRY_AT = @"sync_http_resp_retry_at";

//##############################################################################
// User Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_USER = @"master_user";
NSString * const TBL_MAIN_USER = @"main_user";
// ----Columns------------------------------------------------------------------
NSString * const COL_USR_NAME = @"name";
NSString * const COL_USR_EMAIL = @"email";
NSString * const COL_USR_PASSWORD_HASH = @"password_hash";
NSString * const COL_USR_VERIFIED_AT = @"verified_at";
NSString * const COL_USR_LAST_CHARGE_ID = @"last_charge_id";
NSString * const COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT = @"trial_almost_expired_notice_sent_at";
NSString * const COL_USR_LATEST_STRIPE_TOKEN_ID = @"latest_stripe_token_id";
NSString * const COL_USR_NEXT_INVOICE_AT = @"next_invoice_at";
NSString * const COL_USR_NEXT_INVOICE_AMOUNT = @"next_invoice_amount";
NSString * const COL_USR_LAST_INVOICE_AT = @"last_invoice_at";
NSString * const COL_USR_LAST_INVOICE_AMOUNT = @"last_invoice_amount";
NSString * const COL_USR_CURRENT_CARD_LAST4 = @"current_card_last4";
NSString * const COL_USR_CURRENT_CARD_BRAND = @"current_card_brand";
NSString * const COL_USR_CURRENT_CARD_EXP_MONTH = @"current_card_exp_month";
NSString * const COL_USR_CURRENT_CARD_EXP_YEAR = @"current_card_exp_year";
NSString * const COL_USR_TRIAL_ENDS_AT = @"trial_ends_at";
NSString * const COL_USR_STRIPE_CUSTOMER_ID = @"stripe_customer_id";
NSString * const COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT = @"paid_enrollment_established_at";
NSString * const COL_USR_NEW_MOVEMENTS_ADDED_AT = @"new_movements_added_at";
NSString * const COL_USR_INFORMED_OF_MAINTENANCE_AT = @"informed_of_maintenance_at";
NSString * const COL_USR_MAINTENANCE_STARTS_AT = @"maintenance_starts_at";
NSString * const COL_USR_MAINTENANCE_DURATION = @"maintenance_duration";
NSString * const COL_USR_IS_PAYMENT_PAST_DUE = @"is_payment_past_due";
NSString * const COL_USR_PAID_ENROLLMENT_CANCELLED_AT = @"paid_enrollment_cancelled_at";
NSString * const COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT = @"final_failed_payment_attempt_occurred_at";
NSString * const COL_USR_VALIDATE_APP_STORE_RECEIPT_AT = @"validate_app_store_receipt_at";
NSString * const COL_USR_MAX_ALLOWED_SET_IMPORT = @"max_allowed_set_import";
NSString * const COL_USR_MAX_ALLOWED_BML_IMPORT = @"max_allowed_bml_import";
NSString * const COL_USR_FACEBOOK_USER_ID = @"facebook_user_id";
NSString * const COL_USR_HAS_PASSWORD = @"has_password";

@implementation PELMDDL

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                         column:(NSString *)column
                      indexName:(NSString *)indexName {
  return [PELMDDL indexDDLForEntity:entity
                             unique:unique
                            columns:@[column]
                          indexName:indexName];
}

+ (NSString *)indexDDLForEntity:(NSString *)entity
                         unique:(BOOL)unique
                        columns:(NSArray *)columns
                      indexName:(NSString *)indexName {
  NSMutableString *idxDdl =
    [NSMutableString stringWithFormat:@"CREATE %@INDEX IF NOT EXISTS %@ ON %@ (",
     (unique ? @"UNIQUE " : @""),
     indexName,
     entity];
  NSUInteger numColumns = [columns count];
  for (int i = 0; i < numColumns; i++) {
    [idxDdl appendFormat:@"%@", [columns objectAtIndex:i]];
    if ((i + 1) < numColumns) {
      [idxDdl appendString:@", "];
    }
  }
  [idxDdl appendString:@")"];
  return idxDdl;
}

+ (NSString *)relTableForEntityTable:(NSString *)entityTable {
  return [NSString stringWithFormat:@"%@_rel", entityTable];
}

+ (NSString *)relFkColumnForEntityTable:(NSString *)entityTable
                         entityPkColumn:(NSString *)entityPkColumn {
  return [NSString stringWithFormat:@"%@_%@", entityTable, entityPkColumn];
}

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable
               entityPkColumn:(NSString *)entityPkColumn {
  NSString *relTableName = [PELMDDL relTableForEntityTable:entityTable];
  NSString *fkColumn = [PELMDDL relFkColumnForEntityTable:entityTable
                                           entityPkColumn:entityPkColumn];
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@))", relTableName,
          COL_LOCAL_ID,       // col1
          fkColumn,           // col2
          COL_REL_NAME,       // col3
          COL_REL_URI,        // col4
          COL_REL_MEDIA_TYPE, // col5
          fkColumn,           // fk1, col1
          entityTable,             // fk1, tbl-ref
          entityPkColumn];    // fk1, tbl-ref col1
}

+ (NSString *)relDDLForEntityTable:(NSString *)entityTable {
  return [PELMDDL relDDLForEntityTable:entityTable entityPkColumn:COL_LOCAL_ID];
}

@end
