//
//  RKnownMediaTypes.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RKnownMediaTypes.h"

#import "HCMediaType.h"

NSString * const RApplicationType = @"application/";
NSString * const RApplicationSubtypePrefix = @"vnd.riker.";
NSString * const RJsonSubtypePostfix = @"+json";

NSString * (^RMtBuilder)(NSString *, NSString *) = ^NSString *(NSString *mtId, NSString *version) {
  return [NSString stringWithFormat:@"%@%@%@-v%@%@", RApplicationType, RApplicationSubtypePrefix, mtId, version, RJsonSubtypePostfix];
};

@implementation RKnownMediaTypes

+ (HCMediaType *)apiMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"api", version)];
}

+ (HCMediaType *)changelogMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"changelog", version)];
}

+ (HCMediaType *)stripeTokenMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"stripetoken", version)];
}

+ (HCMediaType *)userMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"user", version)];
}

+ (HCMediaType *)userSettingsMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"usersettings", version)];
}

+ (HCMediaType *)setMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"set", version)];
}

+ (HCMediaType *)bodyMeasurementLogMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"bodyjournallog", version)];
}

+ (HCMediaType *)bodySegmentMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"bodysegment", version)];
}

+ (HCMediaType *)muscleGroupMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"musclegroup", version)];
}

+ (HCMediaType *)muscleMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"muscle", version)];
}

+ (HCMediaType *)muscleAliasMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"musclealias", version)];
}

+ (HCMediaType *)movementMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"movement", version)];
}

+ (HCMediaType *)movementAliasMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"movementalias", version)];
}

+ (HCMediaType *)movementVariantMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"movementvariant", version)];
}

+ (HCMediaType *)originationDeviceMediaTypeWithVersion:(NSString *)version {
  return [HCMediaType MediaTypeFromString:RMtBuilder(@"originationdevice", version)];
}

@end
