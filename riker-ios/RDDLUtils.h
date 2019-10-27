//
//  RDDLUtils.h
//

//##############################################################################
// Body Segment (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_BODY_SEGMENT;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_BODYSEG_NAME;

//##############################################################################
// Muscle Group (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MUSCLE_GROUP;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MUSCLE_GROUP_BODY_SEGMENT_ID;
FOUNDATION_EXPORT NSString * const COL_MUSCLE_GROUP_NAME;
FOUNDATION_EXPORT NSString * const COL_MUSCLE_GROUP_ABBREV_NAME;

//##############################################################################
// Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MUSCLE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MUSCLE_MG_ID;
FOUNDATION_EXPORT NSString * const COL_MUSCLE_CANONICAL_NAME;
FOUNDATION_EXPORT NSString * const COL_MUSCLE_ABBREV_CANONICAL_NAME;

//##############################################################################
// Muscle Alias (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MUSCLE_ALIAS;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MUSCLE_ALIAS_MUSCLE_ID;
FOUNDATION_EXPORT NSString * const COL_MUSCLE_ALIAS_ALIAS;

//##############################################################################
// Movement (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MOVEMENT;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_CANONICAL_NAME;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_IS_BODY_LIFT;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_VARIANT_MASK;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_SORT_ORDER;

//##############################################################################
// Movement Variant (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MOVEMENT_VARIANT;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_VARIANT_NAME;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_VARIANT_ABBREV_NAME;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_VARIANT_DESCRIPTION;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_VARIANT_SORT_ORDER;

//##############################################################################
// Movement Primary Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID;

//##############################################################################
// Movement Secondary Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID;

//##############################################################################
// Movement Alias (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_MOVEMENT_ALIAS;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_ALIAS_MOVEMENT_ID;
FOUNDATION_EXPORT NSString * const COL_MOVEMENT_ALIAS_ALIAS;

//##############################################################################
// Origination Device (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_ORIGINATION_DEVICE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_ORIG_DEVICE_NAME;
FOUNDATION_EXPORT NSString * const COL_ORIG_DEVICE_ICON_IMAGE_NAME;
FOUNDATION_EXPORT NSString * const COL_ORIG_DEVICE_HAS_LOCAL_IMAGE;

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
FOUNDATION_EXPORT NSString * const COL_ORIGINATION_DEVICE_ID;
FOUNDATION_EXPORT NSString * const COL_IMPORTED_AT;

//##############################################################################
// User Settings Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_USER_SETTINGS;
FOUNDATION_EXPORT NSString * const TBL_MAIN_USER_SETTINGS;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_USER_SETTINGS_WEIGHT_UOM;
FOUNDATION_EXPORT NSString * const COL_USER_SETTINGS_SIZE_UOM;
FOUNDATION_EXPORT NSString * const COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT;

//##############################################################################
// Set Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_SET;
FOUNDATION_EXPORT NSString * const TBL_MAIN_SET;
FOUNDATION_EXPORT NSString * const TBL_SET;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_SET_MOVEMENT_ID;
FOUNDATION_EXPORT NSString * const COL_SET_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSString * const COL_SET_NUM_REPS;
FOUNDATION_EXPORT NSString * const COL_SET_WEIGHT;
FOUNDATION_EXPORT NSString * const COL_SET_WEIGHT_UOM;
FOUNDATION_EXPORT NSString * const COL_SET_NEGATIVES;
FOUNDATION_EXPORT NSString * const COL_SET_TO_FAILURE;
FOUNDATION_EXPORT NSString * const COL_SET_LOGGED_AT;
FOUNDATION_EXPORT NSString * const COL_SET_IGNORE_TIME;
FOUNDATION_EXPORT NSString * const COL_SET_CORRELATION_GUID;
FOUNDATION_EXPORT NSString * const COL_SET_UUID;

//##############################################################################
// Body Measurement Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_MASTER_BODY_MEASUREMENT_LOG;
FOUNDATION_EXPORT NSString * const TBL_MAIN_BODY_MEASUREMENT_LOG;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_BML_BODY_WEIGHT;
FOUNDATION_EXPORT NSString * const COL_BML_BODY_WEIGHT_UOM;
FOUNDATION_EXPORT NSString * const COL_BML_ARM_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_CALF_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_WAIST_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_THIGH_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_NECK_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_FOREARM_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_CHEST_SIZE;
FOUNDATION_EXPORT NSString * const COL_BML_SIZE_UOM;
FOUNDATION_EXPORT NSString * const COL_BML_LOGGED_AT;
FOUNDATION_EXPORT NSString * const COL_BML_UUID;

//##############################################################################
// Chart
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_CHART;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CHART_CHART_ID; // alpha-numeric chart identifier string (not its PK column...PK column is COL_LOCAL_ID)
FOUNDATION_EXPORT NSString * const COL_CHART_CATEGORY;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_ID; // FK to chart_config's 'LOCAL_ID' column (not its 'chart_id' column)
FOUNDATION_EXPORT NSString * const COL_CHART_AGGREGATE_BY;
FOUNDATION_EXPORT NSString * const COL_CHART_XAXIS_LABEL_COUNT;
FOUNDATION_EXPORT NSString * const COL_CHART_MAX_VALUE;

//##############################################################################
// Chart Pie Slice
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_CHART_PIE_SLICE;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CHART_PIE_SLICE_CHART_ID; // FK to "chart" cache table/COL_LOCAL_ID column)
FOUNDATION_EXPORT NSString * const COL_CHART_PIE_SLICE_VALUE;

//##############################################################################
// Chart Time Series
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_CHART_TIME_SERIES;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_CHART_ID; // FK to "chart" cache table/COL_LOCAL_ID column
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_ENTITY_LMID;
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_LABEL;

//##############################################################################
// Chart Time Series Data Point
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_CHART_TIME_SERIES_DATA_POINT;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID; // FK to "chart" cache table/COL_LOCAL_ID column
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID;
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_DATA_POINT_DATE;
FOUNDATION_EXPORT NSString * const COL_CHART_TIME_SERIES_DATA_POINT_VALUE;

//##############################################################################
// Chart Config
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_CHART_CONFIG;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_CHART_ID; // this is the alpha-numberic chart identifier (not FK to "chart" cache table)
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_CATEGORY;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_START_DATE;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_END_DATE;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_BOUNDED_END_DATE;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_AGGREGATE_BY;
FOUNDATION_EXPORT NSString * const COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS;

//##############################################################################
// Search Ads Attribution
//##############################################################################
// ----Table names--------------------------------------------------------------
FOUNDATION_EXPORT NSString * const TBL_IAD_ATTRIBUTION;
// ----Columns------------------------------------------------------------------
FOUNDATION_EXPORT NSString * const COL_IAD_RIKER_SERVER_ID;
FOUNDATION_EXPORT NSString * const COL_IAD_ATTRIBUTION;
FOUNDATION_EXPORT NSString * const COL_IAD_ORG_NAME;
FOUNDATION_EXPORT NSString * const COL_IAD_CAMPAIGN_ID;
FOUNDATION_EXPORT NSString * const COL_IAD_CAMPAIGN_NAME;
FOUNDATION_EXPORT NSString * const COL_IAD_PURCHASE_DATE;
FOUNDATION_EXPORT NSString * const COL_IAD_CONVERSION_DATE;
FOUNDATION_EXPORT NSString * const COL_IAD_CONVERSION_TYPE;
FOUNDATION_EXPORT NSString * const COL_IAD_CLICK_DATE;
FOUNDATION_EXPORT NSString * const COL_IAD_ADGROUP_ID;
FOUNDATION_EXPORT NSString * const COL_IAD_ADGROUP_NAME;
FOUNDATION_EXPORT NSString * const COL_IAD_KEYWORD;
FOUNDATION_EXPORT NSString * const COL_IAD_KEYWORD_MATCHTYPE;
FOUNDATION_EXPORT NSString * const COL_IAD_CREATIVESET_ID;
FOUNDATION_EXPORT NSString * const COL_IAD_CREATIVESET_NAME;
FOUNDATION_EXPORT NSString * const COL_IAD_SYNCED_AT;
FOUNDATION_EXPORT NSString * const COL_IAD_ASSOCIATED_TO_SERVER_USER_AT;

@interface RDDLUtils : NSObject

#pragma mark - reference entities

+ (NSString *)masterBodySegmentDDL;
+ (NSString *)masterMuscleGroupDDL;
+ (NSString *)masterMuscleDDL;
+ (NSString *)masterMuscleAliasDDL;
+ (NSString *)masterMovementDDL;
+ (NSString *)masterMovementVariantDDL;
+ (NSString *)masterMovementPrimaryMuscleDDL;
+ (NSString *)masterMovementSecondaryMuscleDDL;
+ (NSString *)masterMovementAliasDDL;
+ (NSString *)masterOriginationDeviceDDL;

#pragma mark - Chart Entity

+ (NSString *)chartDDL;

#pragma mark - Chart Pie Slice Entity

+ (NSString *)chartPieSliceDDL;

#pragma mark - Chart Time Series Entity

+ (NSString *)chartTimeSeriesDDL;

#pragma mark - Chart Time Series Data Point Entity

+ (NSString *)chartTimeSeriesDataPointDDL;

#pragma mark - Chart Config Entity

+ (NSString *)chartConfigDDL;

#pragma mark - Master and Main Set entities

+ (NSString *)masterSetDDL;
+ (NSString *)mainSetDDL;

#pragma mark - Master and Main Body Measurement Log entities

+ (NSString *)masterBodyMeasurementLogDDL;
+ (NSString *)mainBodyMeasurementLogDDL;

# pragma mark - Master and Main User entities

+ (NSString *)masterUserDDL;
+ (NSString *)mainUserDDL;
+ (NSString *)mainUserUniqueIndex1;

# pragma mark - Master and Main User Settings entities

+ (NSString *)masterUserSettingsDDL;
+ (NSString *)mainUserSettingsDDL;

@end
