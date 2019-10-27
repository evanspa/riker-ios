//
//  RWatchUtils.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RWatchUtils.h"

NSString * const RWATCHMSG_ACTION_KEY = @"RWATCHMSG_ACTION_KEY";
NSString * const RWATCHMSG_REPLY_RESULT_STATUS_KEY = @"RWATCHMSG_REPLY_RESULT_STATUS_KEY";
NSString * const RWATCHMSG_PAYLOAD_KEY = @"RWATCHMSG_PAYLOAD_KEY";
NSString * const RWATCHMSG_RAISE_NOTIFICATION_KEY = @"RWATCHMSG_RAISE_NOTIFICATION_KEY";
NSString * const RWATCHMSG_LOCAL_ENTITY_FILES_KEY = @"RWATCHMSG_LOCAL_ENTITY_FILES_KEY";

NSInteger const BARBELL_MOVEMENT_VARIANT_ID       = 1;
NSInteger const DUMBBELL_MOVEMENT_VARIANT_ID      = 2;
NSInteger const MACHINE_MOVEMENT_VARIANT_ID       = 4;
NSInteger const SMITH_MACHINE_MOVEMENT_VARIANT_ID = 8;
NSInteger const CABLE_MOVEMENT_VARIANT_ID         = 16;
NSInteger const CURL_BAR_MOVEMENT_VARIANT_ID      = 32;
NSInteger const SLED_MOVEMENT_VARIANT_ID          = 64;
NSInteger const BODY_MOVEMENT_VARIANT_ID          = 128;
NSInteger const KETTLEBELL_MOVEMENT_VARIANT_ID    = 256;

NSInteger const MAX_RECENT_ENTITIES = 10;

@implementation RWatchUtils

+ (RWatchReplyResultStatus)resultStatusFromReply:(NSDictionary *)reply {
  return ((NSNumber *)reply[RWATCHMSG_REPLY_RESULT_STATUS_KEY]).integerValue;
}

+ (NSMutableDictionary *)payloadFromReply:(NSDictionary *)reply {
  return reply[RWATCHMSG_PAYLOAD_KEY];
}

+ (NSArray *)localEntityFilesFromReply:(NSDictionary *)reply {
  return reply[RWATCHMSG_LOCAL_ENTITY_FILES_KEY];
}

@end
