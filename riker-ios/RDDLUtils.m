//
//  RDDLUtils.m
//

#import "PELMDDL.h"

#import "RDDLUtils.h"

//##############################################################################
// Body Segment (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_BODY_SEGMENT = @"master_body_segment";
// ----Columns------------------------------------------------------------------
NSString * const COL_BODYSEG_NAME = @"name";

//##############################################################################
// Muscle Group (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MUSCLE_GROUP = @"master_muscle_group";
// ----Columns------------------------------------------------------------------
NSString * const COL_MUSCLE_GROUP_BODY_SEGMENT_ID = @"body_segment_id";
NSString * const COL_MUSCLE_GROUP_NAME = @"name";
NSString * const COL_MUSCLE_GROUP_ABBREV_NAME = @"abbrev_name";

//##############################################################################
// Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MUSCLE = @"master_muscle";
// ----Columns------------------------------------------------------------------
NSString * const COL_MUSCLE_MG_ID = @"muscle_group_id";
NSString * const COL_MUSCLE_CANONICAL_NAME = @"canonical_name";
NSString * const COL_MUSCLE_ABBREV_CANONICAL_NAME = @"abbrev_canonical_name";

//##############################################################################
// Muscle Alias (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MUSCLE_ALIAS = @"master_muscle_alias";
// ----Columns------------------------------------------------------------------
NSString * const COL_MUSCLE_ALIAS_MUSCLE_ID = @"muscle_id";
NSString * const COL_MUSCLE_ALIAS_ALIAS = @"alias";

//##############################################################################
// Movement (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MOVEMENT = @"master_movement";
// ----Columns------------------------------------------------------------------
NSString * const COL_MOVEMENT_CANONICAL_NAME = @"canonical_name";
NSString * const COL_MOVEMENT_IS_BODY_LIFT = @"is_body_lift";
NSString * const COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT = @"percentage_of_body_weight";
NSString * const COL_MOVEMENT_VARIANT_MASK = @"variant_mask";
NSString * const COL_MOVEMENT_SORT_ORDER = @"sort_order";

//##############################################################################
// Movement Variant (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MOVEMENT_VARIANT = @"master_movement_variant";
// ----Columns------------------------------------------------------------------
NSString * const COL_MOVEMENT_VARIANT_NAME = @"name";
NSString * const COL_MOVEMENT_VARIANT_ABBREV_NAME = @"abbrev_name";
NSString * const COL_MOVEMENT_VARIANT_DESCRIPTION = @"description";
NSString * const COL_MOVEMENT_VARIANT_SORT_ORDER = @"sort_order";

//##############################################################################
// Movement Primary Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE = @"master_movement_primary_muscle";
// ----Columns------------------------------------------------------------------
NSString * const COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID = @"movement_id";
NSString * const COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID = @"muscle_id";

//##############################################################################
// Movement Secondary Muscle (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE = @"master_movement_secondary_muscle";
// ----Columns------------------------------------------------------------------
NSString * const COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID = @"movement_id";
NSString * const COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID = @"muscle_id";

//##############################################################################
// Movement Alias (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_MOVEMENT_ALIAS = @"master_movement_alias";
// ----Columns------------------------------------------------------------------
NSString * const COL_MOVEMENT_ALIAS_MOVEMENT_ID = @"movement_id";
NSString * const COL_MOVEMENT_ALIAS_ALIAS = @"alias";

//##############################################################################
// Origination Device (master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_ORIGINATION_DEVICE = @"master_origination_device";
// ----Columns------------------------------------------------------------------
NSString * const COL_ORIG_DEVICE_NAME = @"name";
NSString * const COL_ORIG_DEVICE_ICON_IMAGE_NAME = @"icon_image_name";
NSString * const COL_ORIG_DEVICE_HAS_LOCAL_IMAGE = @"has_local_image";

//##############################################################################
// Shared columns
//##############################################################################
// ----Columns common to both main and master entities--------------------------
NSString * const COL_ORIGINATION_DEVICE_ID = @"origination_device_id";
NSString * const COL_IMPORTED_AT = @"imported_at";

//##############################################################################
// User Settings Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_USER_SETTINGS = @"master_user_settings";
NSString * const TBL_MAIN_USER_SETTINGS = @"main_user_settings";
// ----Columns------------------------------------------------------------------
NSString * const COL_USER_SETTINGS_WEIGHT_UOM = @"weight_uom";
NSString * const COL_USER_SETTINGS_SIZE_UOM = @"size_uom";
NSString * const COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT = @"weight_inc_dec_amount";

//##############################################################################
// Set Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_SET = @"master_set";
NSString * const TBL_MAIN_SET = @"main_set";
NSString * const TBL_SET = @"set";
// ----Columns------------------------------------------------------------------
NSString * const COL_SET_MOVEMENT_ID = @"movement_id";
NSString * const COL_SET_MOVEMENT_VARIANT_ID = @"movement_variant_id";
NSString * const COL_SET_NUM_REPS = @"num_reps";
NSString * const COL_SET_WEIGHT = @"weight";
NSString * const COL_SET_WEIGHT_UOM = @"weight_uom";
NSString * const COL_SET_NEGATIVES = @"negatives";
NSString * const COL_SET_TO_FAILURE = @"to_failure";
NSString * const COL_SET_LOGGED_AT = @"logged_at";
NSString * const COL_SET_IGNORE_TIME = @"ignore_time";
NSString * const COL_SET_CORRELATION_GUID = @"correlation_guid";
NSString * const COL_SET_UUID = @"uuid";

//##############################################################################
// Body Measurement Log Entity (main and master)
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_MASTER_BODY_MEASUREMENT_LOG = @"master_body_measurement_log";
NSString * const TBL_MAIN_BODY_MEASUREMENT_LOG = @"main_body_measurement_log";
// ----Columns------------------------------------------------------------------
NSString * const COL_BML_BODY_WEIGHT = @"body_weight";
NSString * const COL_BML_BODY_WEIGHT_UOM = @"body_weight_uom";
NSString * const COL_BML_ARM_SIZE = @"arm_size";
NSString * const COL_BML_CALF_SIZE = @"calf_size";
NSString * const COL_BML_WAIST_SIZE = @"waist_size";
NSString * const COL_BML_THIGH_SIZE = @"thigh_size";
NSString * const COL_BML_NECK_SIZE = @"neck_size";
NSString * const COL_BML_FOREARM_SIZE = @"forearm_size";
NSString * const COL_BML_CHEST_SIZE = @"chest_size";
NSString * const COL_BML_SIZE_UOM = @"size_uom";
NSString * const COL_BML_LOGGED_AT = @"logged_at";
NSString * const COL_BML_UUID = @"uuid";

//##############################################################################
// Chart
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_CHART = @"chart";
// ----Columns------------------------------------------------------------------
NSString * const COL_CHART_CHART_ID = @"chart_id"; // alpha-numeric chart identifier string (not its PK column...PK column is COL_LOCAL_ID)
NSString * const COL_CHART_CATEGORY = @"category";
NSString * const COL_CHART_CONFIG_ID = @"chart_config_id"; // FK to chart_config's 'LOCAL_ID' column (not its 'chart_id' column)
NSString * const COL_CHART_AGGREGATE_BY = @"aggregate_by";
NSString * const COL_CHART_XAXIS_LABEL_COUNT = @"xaxis_label_count";
NSString * const COL_CHART_MAX_VALUE = @"max_value";

//##############################################################################
// Chart Pie Slice
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_CHART_PIE_SLICE = @"chart_pie_slice";
// ----Columns------------------------------------------------------------------
NSString * const COL_CHART_PIE_SLICE_CHART_ID = @"chart_id"; // FK to "chart" cache table/COL_LOCAL_ID column
NSString * const COL_CHART_PIE_SLICE_VALUE = @"value";

//##############################################################################
// Chart Time Series
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_CHART_TIME_SERIES = @"chart_time_series";
// ----Columns------------------------------------------------------------------
NSString * const COL_CHART_TIME_SERIES_CHART_ID = @"chart_id"; // FK to "chart" cache table/COL_LOCAL_ID column
NSString * const COL_CHART_TIME_SERIES_ENTITY_LMID = @"entity_lmid";
NSString * const COL_CHART_TIME_SERIES_LABEL = @"label";

//##############################################################################
// Chart Time Series Data Point
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_CHART_TIME_SERIES_DATA_POINT = @"chart_time_series_data_point";
// ----Columns------------------------------------------------------------------
NSString * const COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID = @"chart_id"; // FK to "chart" cache table/COL_LOCAL_ID column)
NSString * const COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID = @"chart_time_series_id";
NSString * const COL_CHART_TIME_SERIES_DATA_POINT_DATE = @"date";
NSString * const COL_CHART_TIME_SERIES_DATA_POINT_VALUE = @"value";

//##############################################################################
// Chart Config
//##############################################################################
// ----Table names--------------------------------------------------------------
NSString * const TBL_CHART_CONFIG = @"chart_config";
// ----Columns------------------------------------------------------------------
NSString * const COL_CHART_CONFIG_CHART_ID = @"chart_id"; // this is the alpha-numberic chart identifier (not FK to "chart" cache table)
NSString * const COL_CHART_CONFIG_CATEGORY = @"category";
NSString * const COL_CHART_CONFIG_START_DATE = @"start_date";
NSString * const COL_CHART_CONFIG_END_DATE = @"end_date";
NSString * const COL_CHART_CONFIG_BOUNDED_END_DATE = @"bounded_end_date";
NSString * const COL_CHART_CONFIG_AGGREGATE_BY = @"aggregate_by";
NSString * const COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS = @"suppress_pie_slice_labels";

@implementation RDDLUtils

#pragma mark - Chart Entity

+ (NSString *)chartDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER NOT NULL, \
          \
          %@ TEXT UNIQUE NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ REAL NOT NULL, \
          \
          FOREIGN KEY (%@) REFERENCES %@(%@), \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_CHART,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          
          COL_CHART_CHART_ID,
          COL_CHART_CATEGORY,
          COL_CHART_CONFIG_ID, // FK to chart_config's 'LOCAL_ID' column (not its 'chart_id' column)
          COL_CHART_AGGREGATE_BY,
          COL_CHART_XAXIS_LABEL_COUNT,
          COL_CHART_MAX_VALUE,
          
          COL_CHART_CONFIG_ID, TBL_CHART_CONFIG, COL_LOCAL_ID,
          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

#pragma mark - Chart Pie Slice Entity

+ (NSString *)chartPieSliceDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER NOT NULL, \
          \
          %@ INTEGER NOT NULL, \
          %@ REAL NOT NULL, \
          \
          FOREIGN KEY (%@) REFERENCES %@(%@), \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_CHART_PIE_SLICE,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          
          COL_CHART_PIE_SLICE_CHART_ID,
          COL_CHART_PIE_SLICE_VALUE,
          
          COL_CHART_PIE_SLICE_CHART_ID, TBL_CHART, COL_LOCAL_ID,
          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

#pragma mark - Chart Time Series Entity

+ (NSString *)chartTimeSeriesDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER NOT NULL, \
          \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ TEXT NOT NULL, \
          \
          FOREIGN KEY (%@) REFERENCES %@(%@), \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_CHART_TIME_SERIES,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          
          COL_CHART_TIME_SERIES_CHART_ID,
          COL_CHART_TIME_SERIES_ENTITY_LMID,
          COL_CHART_TIME_SERIES_LABEL,
          
          COL_CHART_TIME_SERIES_CHART_ID, TBL_CHART, COL_LOCAL_ID,
          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

#pragma mark - Chart Time Series Data Point Entity

+ (NSString *)chartTimeSeriesDataPointDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER NOT NULL, \
          \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ REAL NOT NULL, \
          \
          FOREIGN KEY (%@) REFERENCES %@(%@), \
          FOREIGN KEY (%@) REFERENCES %@(%@), \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_CHART_TIME_SERIES_DATA_POINT,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          
          COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID,
          COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID,
          COL_CHART_TIME_SERIES_DATA_POINT_DATE,
          COL_CHART_TIME_SERIES_DATA_POINT_VALUE,
          
          COL_CHART_TIME_SERIES_DATA_POINT_CHART_ID, TBL_CHART, COL_LOCAL_ID,
          COL_CHART_TIME_SERIES_DATA_POINT_TIME_SERIES_ID, TBL_CHART_TIME_SERIES, COL_LOCAL_ID,
          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

#pragma mark - Chart Config Entity

+ (NSString *)chartConfigDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
          %@ INTEGER PRIMARY KEY, \
          %@ INTEGER NOT NULL, \
          %@ TEXT UNIQUE, \
          %@ TEXT, \
          %@ INTEGER, \
          %@ INTEGER, \
          %@ INTEGER, \
          \
          %@ TEXT UNIQUE NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER, \
          \
          %@ INTEGER, \
          %@ INTEGER, \
          %@ INTEGER, \
          %@ INTEGER, \
          %@ INTEGER, \
          %@ INTEGER, \
          \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_CHART_CONFIG,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_CHART_CONFIG_CHART_ID,
          COL_CHART_CONFIG_CATEGORY,
          COL_CHART_CONFIG_START_DATE,
          COL_CHART_CONFIG_END_DATE,
          COL_CHART_CONFIG_BOUNDED_END_DATE,
          COL_CHART_CONFIG_AGGREGATE_BY,
          COL_CHART_CONFIG_SUPPRESS_PIE_SLICE_LABELS,
          COL_IMPORTED_AT,

          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,

          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

#pragma mark - Master Body Segment entities

+ (NSString *)masterBodySegmentDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL)", TBL_MASTER_BODY_SEGMENT,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_BODYSEG_NAME];
}

#pragma mark - Master Muscle Group entities

+ (NSString *)masterMuscleGroupDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ TEXT NULL, \
%@ INTEGER NOT NULL, \
\
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_MUSCLE_GROUP,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MUSCLE_GROUP_NAME,
          COL_MUSCLE_GROUP_ABBREV_NAME,
          COL_MUSCLE_GROUP_BODY_SEGMENT_ID,
          COL_MUSCLE_GROUP_BODY_SEGMENT_ID, TBL_MASTER_BODY_SEGMENT, COL_LOCAL_ID];
}

#pragma mark - Master Muscle entities

+ (NSString *)masterMuscleDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ TEXT NULL, \
%@ INTEGER NOT NULL, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_MUSCLE,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MUSCLE_CANONICAL_NAME,
          COL_MUSCLE_ABBREV_CANONICAL_NAME,
          COL_MUSCLE_MG_ID,
          COL_MUSCLE_MG_ID, TBL_MASTER_MUSCLE_GROUP, COL_LOCAL_ID];
}

#pragma mark - Master Muscle Alias entities

+ (NSString *)masterMuscleAliasDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_MUSCLE_ALIAS,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MUSCLE_ALIAS_ALIAS,
          COL_MUSCLE_ALIAS_MUSCLE_ID,
          COL_MUSCLE_ALIAS_MUSCLE_ID, TBL_MASTER_MUSCLE, COL_LOCAL_ID];
}

#pragma mark - Master Movement entities

+ (NSString *)masterMovementDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL)", TBL_MASTER_MOVEMENT,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MOVEMENT_CANONICAL_NAME,
          COL_MOVEMENT_IS_BODY_LIFT,
          COL_MOVEMENT_PERCENTAGE_OF_BODY_WEIGHT,
          COL_MOVEMENT_VARIANT_MASK,
          COL_MOVEMENT_SORT_ORDER];
}

#pragma mark - Master Movement Variant entities

+ (NSString *)masterMovementVariantDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ TEXT NULL, \
%@ TEXT NULL, \
%@ INTEGER NOT NULL)", TBL_MASTER_MOVEMENT_VARIANT,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MOVEMENT_VARIANT_NAME,
          COL_MOVEMENT_VARIANT_ABBREV_NAME,
          COL_MOVEMENT_VARIANT_DESCRIPTION,
          COL_MOVEMENT_VARIANT_SORT_ORDER];
}

#pragma mark - Master Movement Primary Muscle entities

+ (NSString *)masterMovementPrimaryMuscleDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
PRIMARY KEY (%@, %@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))",
          TBL_MASTER_MOVEMENT_PRIMARY_MUSCLE,
          COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID,
          COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID,
          COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID, COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID,
          COL_MOVEMENT_PRIMARY_MUSCLE_MUSCLE_ID, TBL_MASTER_MUSCLE, COL_LOCAL_ID,
          COL_MOVEMENT_PRIMARY_MUSCLE_MOVEMENT_ID, TBL_MASTER_MOVEMENT, COL_LOCAL_ID];
}

#pragma mark - Master Movement Secondary Muscle entities

+ (NSString *)masterMovementSecondaryMuscleDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
PRIMARY KEY (%@, %@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))",
          TBL_MASTER_MOVEMENT_SECONDARY_MUSCLE,
          COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID,
          COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID,
          COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID, COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID,
          COL_MOVEMENT_SECONDARY_MUSCLE_MUSCLE_ID, TBL_MASTER_MUSCLE, COL_LOCAL_ID,
          COL_MOVEMENT_SECONDARY_MUSCLE_MOVEMENT_ID, TBL_MASTER_MOVEMENT, COL_LOCAL_ID];
}

#pragma mark - Master Movement Alias entities

+ (NSString *)masterMovementAliasDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
          %@ INTEGER PRIMARY KEY, \
          %@ TEXT    UNIQUE NOT NULL, \
          %@ TEXT    NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER NOT NULL, \
          %@ INTEGER, \
          \
          %@ INTEGER NOT NULL, \
          %@ TEXT NOT NULL, \
          FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_MOVEMENT_ALIAS,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_MOVEMENT_ALIAS_MOVEMENT_ID,
          COL_MOVEMENT_ALIAS_ALIAS,
          COL_MOVEMENT_ALIAS_MOVEMENT_ID, TBL_MASTER_MOVEMENT, COL_LOCAL_ID];
}

#pragma mark - Master Origination Device entities

+ (NSString *)masterOriginationDeviceDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(\
%@ INTEGER PRIMARY KEY, \
%@ TEXT    UNIQUE NOT NULL, \
%@ TEXT    NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ TEXT NOT NULL)", TBL_MASTER_ORIGINATION_DEVICE,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_ORIG_DEVICE_NAME,
          COL_ORIG_DEVICE_HAS_LOCAL_IMAGE,
          COL_ORIG_DEVICE_ICON_IMAGE_NAME];
}

#pragma mark - Master and Main Set entities

+ (NSString *)masterSetDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ INTEGER, \
%@ INTEGER NOT NULL, \
%@ REAL NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
%@ TEXT, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
\
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_SET,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_SET_MOVEMENT_ID,
          COL_SET_MOVEMENT_VARIANT_ID,
          COL_SET_NUM_REPS,
          COL_SET_WEIGHT,
          COL_SET_WEIGHT_UOM,
          COL_SET_NEGATIVES,
          COL_SET_TO_FAILURE,
          COL_SET_LOGGED_AT,
          COL_SET_IGNORE_TIME,
          COL_ORIGINATION_DEVICE_ID,
          COL_IMPORTED_AT,
          COL_SET_CORRELATION_GUID,
          COL_SET_MOVEMENT_ID,         TBL_MASTER_MOVEMENT,           COL_LOCAL_ID,
          COL_ORIGINATION_DEVICE_ID,   TBL_MASTER_ORIGINATION_DEVICE, COL_LOCAL_ID,
          COL_SET_MOVEMENT_VARIANT_ID, TBL_MASTER_MOVEMENT_VARIANT,   COL_LOCAL_ID,

          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

+ (NSString *)mainSetDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ INTEGER, \
%@ INTEGER NOT NULL, \
%@ REAL NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
%@ TEXT, \
\
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
\
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@), \
\
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_SET,
          COL_LOCAL_ID,
          COL_MAIN_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_MAN_MASTER_UPDATED_AT,
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER,

          COL_SET_MOVEMENT_ID,
          COL_SET_MOVEMENT_VARIANT_ID,
          COL_SET_NUM_REPS,
          COL_SET_WEIGHT,
          COL_SET_WEIGHT_UOM,
          COL_SET_NEGATIVES,
          COL_SET_TO_FAILURE,
          COL_SET_LOGGED_AT,
          COL_SET_IGNORE_TIME,
          COL_ORIGINATION_DEVICE_ID,
          COL_IMPORTED_AT,
          COL_SET_CORRELATION_GUID,

          COL_EDIT_IN_PROGRESS,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_EDIT_COUNT,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,

          COL_SET_MOVEMENT_ID,         TBL_MASTER_MOVEMENT,           COL_LOCAL_ID,
          COL_ORIGINATION_DEVICE_ID,   TBL_MASTER_ORIGINATION_DEVICE, COL_LOCAL_ID,
          COL_SET_MOVEMENT_VARIANT_ID, TBL_MASTER_MOVEMENT_VARIANT,   COL_LOCAL_ID,

          COL_MAIN_USER_ID,            TBL_MAIN_USER,          COL_LOCAL_ID];
}

#pragma mark - Master and Main Body Measurement Log entities

+ (NSString *)masterBodyMeasurementLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ REAL, \
%@ INTEGER, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ INTEGER, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_BODY_MEASUREMENT_LOG,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_BML_LOGGED_AT,
          COL_BML_BODY_WEIGHT,
          COL_BML_BODY_WEIGHT_UOM,
          COL_BML_ARM_SIZE,
          COL_BML_CALF_SIZE,
          COL_BML_CHEST_SIZE,
          COL_BML_NECK_SIZE,
          COL_BML_WAIST_SIZE,
          COL_BML_THIGH_SIZE,
          COL_BML_FOREARM_SIZE,
          COL_BML_SIZE_UOM,
          COL_ORIGINATION_DEVICE_ID,
          COL_IMPORTED_AT,
          COL_ORIGINATION_DEVICE_ID, TBL_MASTER_ORIGINATION_DEVICE, COL_LOCAL_ID,

          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

+ (NSString *)mainBodyMeasurementLogDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ REAL, \
%@ INTEGER, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ REAL, \
%@ INTEGER, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@), \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_BODY_MEASUREMENT_LOG,
          COL_LOCAL_ID,
          COL_MAIN_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_MAN_MASTER_UPDATED_AT,
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER,

          COL_BML_LOGGED_AT,
          COL_BML_BODY_WEIGHT,
          COL_BML_BODY_WEIGHT_UOM,
          COL_BML_ARM_SIZE,
          COL_BML_CALF_SIZE,
          COL_BML_CHEST_SIZE,
          COL_BML_NECK_SIZE,
          COL_BML_WAIST_SIZE,
          COL_BML_THIGH_SIZE,
          COL_BML_FOREARM_SIZE,
          COL_BML_SIZE_UOM,
          COL_ORIGINATION_DEVICE_ID,
          COL_IMPORTED_AT,

          COL_EDIT_IN_PROGRESS,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_EDIT_COUNT,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_ORIGINATION_DEVICE_ID, TBL_MASTER_ORIGINATION_DEVICE, COL_LOCAL_ID,
          COL_MAIN_USER_ID, TBL_MAIN_USER, COL_LOCAL_ID];
}

# pragma mark - Master and Main User entities

+ (NSString *)masterUserDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER)", TBL_MASTER_USER,
          COL_LOCAL_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_USR_NAME,
          COL_USR_EMAIL,
          COL_USR_PASSWORD_HASH,
          COL_USR_VERIFIED_AT,
          COL_USR_LAST_CHARGE_ID,
          COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT,
          COL_USR_LATEST_STRIPE_TOKEN_ID,
          COL_USR_NEXT_INVOICE_AT,
          COL_USR_NEXT_INVOICE_AMOUNT,
          COL_USR_LAST_INVOICE_AT,
          COL_USR_LAST_INVOICE_AMOUNT,
          COL_USR_CURRENT_CARD_LAST4,
          COL_USR_CURRENT_CARD_BRAND,
          COL_USR_CURRENT_CARD_EXP_MONTH,
          COL_USR_CURRENT_CARD_EXP_YEAR,
          COL_USR_TRIAL_ENDS_AT,
          COL_USR_STRIPE_CUSTOMER_ID,
          COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT,
          COL_USR_NEW_MOVEMENTS_ADDED_AT,
          COL_USR_INFORMED_OF_MAINTENANCE_AT,
          COL_USR_MAINTENANCE_STARTS_AT,
          COL_USR_MAINTENANCE_DURATION,
          COL_USR_IS_PAYMENT_PAST_DUE,
          COL_USR_PAID_ENROLLMENT_CANCELLED_AT,
          COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT,
          COL_USR_VALIDATE_APP_STORE_RECEIPT_AT,
          COL_USR_MAX_ALLOWED_SET_IMPORT,
          COL_USR_MAX_ALLOWED_BML_IMPORT];
}

+ (NSString *)mainUserDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
\
%@ TEXT, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
\
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_USER,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_MAN_MASTER_UPDATED_AT,
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER,

          COL_USR_NAME,
          COL_USR_EMAIL,
          COL_USR_PASSWORD_HASH,
          COL_USR_VERIFIED_AT,
          COL_USR_LAST_CHARGE_ID,
          COL_USR_TRIAL_ALMOST_EXPIRED_NOTICE_SENT_AT,
          COL_USR_LATEST_STRIPE_TOKEN_ID,
          COL_USR_NEXT_INVOICE_AT,
          COL_USR_NEXT_INVOICE_AMOUNT,
          COL_USR_LAST_INVOICE_AT,
          COL_USR_LAST_INVOICE_AMOUNT,
          COL_USR_CURRENT_CARD_LAST4,
          COL_USR_CURRENT_CARD_BRAND,
          COL_USR_CURRENT_CARD_EXP_MONTH,
          COL_USR_CURRENT_CARD_EXP_YEAR,
          COL_USR_TRIAL_ENDS_AT,
          COL_USR_STRIPE_CUSTOMER_ID,
          COL_USR_PAID_ENROLLMENT_ESTABLISHED_AT,
          COL_USR_NEW_MOVEMENTS_ADDED_AT,
          COL_USR_INFORMED_OF_MAINTENANCE_AT,
          COL_USR_MAINTENANCE_STARTS_AT,
          COL_USR_MAINTENANCE_DURATION,
          COL_USR_IS_PAYMENT_PAST_DUE,
          COL_USR_PAID_ENROLLMENT_CANCELLED_AT,
          COL_USR_FINAL_FAILED_PAYMENT_ATTEMPT_OCCURRED_AT,
          COL_USR_VALIDATE_APP_STORE_RECEIPT_AT,
          COL_USR_MAX_ALLOWED_SET_IMPORT,
          COL_USR_MAX_ALLOWED_BML_IMPORT,

          COL_EDIT_IN_PROGRESS,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_EDIT_COUNT,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

+ (NSString *)mainUserUniqueIndex1 {
  return [PELMDDL indexDDLForEntity:TBL_MAIN_USER
                             unique:YES
                             column:COL_MASTER_USER_ID
                          indexName:@"uidx_main_user"];
}

# pragma mark - Master and Main User Settings entities

+ (NSString *)masterUserSettingsDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE NOT NULL, \
%@ TEXT NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
\
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MASTER_USER_SETTINGS,
          COL_LOCAL_ID,
          COL_MASTER_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_CREATED_AT,
          COL_UPDATED_AT,
          COL_DELETED_DT,

          COL_USER_SETTINGS_WEIGHT_UOM,
          COL_USER_SETTINGS_SIZE_UOM,
          COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT,

          COL_MASTER_USER_ID, TBL_MASTER_USER, COL_LOCAL_ID];
}

+ (NSString *)mainUserSettingsDDL {
  return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\
%@ INTEGER PRIMARY KEY, \
%@ INTEGER NOT NULL, \
%@ TEXT UNIQUE, \
%@ TEXT, \
%@ INTEGER, \
%@ INTEGER, \
\
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
%@ INTEGER NOT NULL, \
\
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
%@ INTEGER, \
FOREIGN KEY (%@) REFERENCES %@(%@))", TBL_MAIN_USER_SETTINGS,
          COL_LOCAL_ID,
          COL_MAIN_USER_ID,
          COL_GLOBAL_ID,
          COL_MEDIA_TYPE,
          COL_MAN_MASTER_UPDATED_AT,
          COL_MAN_DT_COPIED_DOWN_FROM_MASTER,

          COL_USER_SETTINGS_WEIGHT_UOM,
          COL_USER_SETTINGS_SIZE_UOM,
          COL_USER_SETTINGS_WEIGHT_INC_DEC_AMOUNT,

          COL_EDIT_IN_PROGRESS,
          COL_SYNC_IN_PROGRESS,
          COL_SYNCED,
          COL_EDIT_COUNT,
          COL_SYNC_HTTP_RESP_CODE,
          COL_SYNC_ERR_MASK,
          COL_SYNC_RETRY_AT,
          COL_MAIN_USER_ID, TBL_MAIN_USER, COL_LOCAL_ID];
}

@end
