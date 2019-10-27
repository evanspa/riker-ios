//
//  RMovementSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/22/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovementSerializer.h"
#import "RMovement.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMovementIdKey                     = @"movement/id";
NSString * const RMovementCanonicalNameKey          = @"movement/canonical-name";
NSString * const RMovementPrimaryMuscleIdsKey       = @"movement/primary-muscle-ids";
NSString * const RMovementSecondaryMuscleIdsKey     = @"movement/secondary-muscle-ids";
NSString * const RMovementVariantMaskKey            = @"movement/variant-mask";
NSString * const RMovementSortOrderKey              = @"movement/sort-order";
NSString * const RMovementIsBodyLiftKey             = @"movement/is-body-lift";
NSString * const RMovementPercentageOfBodyWeightKey = @"movement/percentage-of-body-weight";
NSString * const RMovementCreatedAtKey              = @"movement/created-at";
NSString * const RMovementDeletedAtKey              = @"movement/deleted-at";
NSString * const RMovementUpdatedAtKey              = @"movement/updated-at";

@implementation RMovementSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return nil; // not used
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  RMovement *movement =
  [[RMovement alloc] initWithLocalMasterIdentifier:resDict[RMovementIdKey]
                                  globalIdentifier:location
                                         mediaType:mediaType
                                         relations:relations
                                         createdAt:[resDict dateSince1970ForKey:RMovementCreatedAtKey]
                                         deletedAt:[resDict dateSince1970ForKey:RMovementDeletedAtKey]
                                         updatedAt:[resDict dateSince1970ForKey:RMovementUpdatedAtKey]
                                     canonicalName:resDict[RMovementCanonicalNameKey]
                                        isBodyLift:[resDict boolForKey:RMovementIsBodyLiftKey]
                            percentageOfBodyWeight:[PEUtils nullSafeDecimalNumberFromString:[resDict[RMovementPercentageOfBodyWeightKey] description]]
                                       variantMask:resDict[RMovementVariantMaskKey]
                                         sortOrder:resDict[RMovementSortOrderKey]
                                  primaryMuscleIds:resDict[RMovementPrimaryMuscleIdsKey]
                                secondaryMuscleIds:resDict[RMovementSecondaryMuscleIdsKey]];
  return movement;
}

@end
