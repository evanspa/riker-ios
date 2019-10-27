//
//  RWatchUtils.h
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const RWATCHMSG_ACTION_KEY;
FOUNDATION_EXPORT NSString * const RWATCHMSG_REPLY_RESULT_STATUS_KEY;
FOUNDATION_EXPORT NSString * const RWATCHMSG_PAYLOAD_KEY;
FOUNDATION_EXPORT NSString * const RWATCHMSG_WORKOUTS_KEY;
FOUNDATION_EXPORT NSString * const RWATCHMSG_RAISE_NOTIFICATION_KEY;
FOUNDATION_EXPORT NSString * const RWATCHMSG_LOCAL_ENTITY_FILES_KEY;

typedef NS_ENUM(NSInteger, RWatchMsgAction) {
  RWatchMsgActionFetchAllIPhoneData,
  RWatchMsgActionSaveNewSets,
  RWatchMsgActionSaveNewBmls,
  RWatchMsgActionEntitySaveAck,
  RWatchMsgActionFetchAllIPhoneDataAck,
  RWatchMsgActionPushAllIPhoneData
};

typedef NS_ENUM(NSInteger, RWatchReplyResultStatus) {
  RWatchReplyResultStatusSuccess = 1,
  RWatchReplyResultStatusFailure
};

typedef NS_ENUM(NSInteger, RBmlType) {
  RBmlTypeBodyWeight,
  RBmlTypeArms,
  RBmlTypeChest,
  RBmlTypeCalves,
  RBmlTypeThighs,
  RBmlTypeForearms,
  RBmlTypeWaist,
  RBmlTypeNeck,
  RBmlTypeSeveral
};

FOUNDATION_EXPORT NSInteger const BARBELL_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const DUMBBELL_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const MACHINE_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const SMITH_MACHINE_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const CABLE_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const CURL_BAR_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const SLED_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const BODY_MOVEMENT_VARIANT_ID;
FOUNDATION_EXPORT NSInteger const KETTLEBELL_MOVEMENT_VARIANT_ID;

FOUNDATION_EXPORT NSInteger const MAX_RECENT_ENTITIES;

@interface RWatchUtils : NSObject

+ (RWatchReplyResultStatus)resultStatusFromReply:(NSDictionary *)reply;
+ (NSMutableDictionary *)payloadFromReply:(NSDictionary *)reply;
+ (NSArray *)localEntityFilesFromReply:(NSDictionary *)reply;

@end
