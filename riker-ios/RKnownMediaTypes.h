//
//  RKnownMediaTypes.h
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HCMediaType;

@interface RKnownMediaTypes : NSObject

+ (HCMediaType *)apiMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)changelogMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)stripeTokenMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)userMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)userSettingsMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)setMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)bodyMeasurementLogMediaTypeWithVersion:(NSString *)version;

+ (HCMediaType *)bodySegmentMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)muscleGroupMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)muscleMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)muscleAliasMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)movementMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)movementAliasMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)movementVariantMediaTypeWithVersion:(NSString *)version;
+ (HCMediaType *)originationDeviceMediaTypeWithVersion:(NSString *)version;

@end
