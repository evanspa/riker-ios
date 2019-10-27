//
//  RMovement.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovement.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMovement

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      canonicalName:(NSString *)canonicalName
                         isBodyLift:(BOOL)isBodyLift
             percentageOfBodyWeight:(NSDecimalNumber *)percentageOfBodyWeight
                        variantMask:(NSNumber *)variantMask
                          sortOrder:(NSNumber *)sortOrder
                   primaryMuscleIds:(NSArray *)primaryMuscleIds
                 secondaryMuscleIds:(NSArray *)secondaryMuscleIds {
  self = [super initWithLocalMainIdentifier:nil
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _canonicalName = canonicalName;
    _isBodyLift = isBodyLift;
    _percentageOfBodyWeight = percentageOfBodyWeight;
    _variantMask = variantMask;
    _sortOrder = sortOrder;
    _primaryMuscleIds = primaryMuscleIds;
    _secondaryMuscleIds = secondaryMuscleIds;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMovement *copy =
  [[RMovement alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                  globalIdentifier:[self globalIdentifier]
                                         mediaType:[self mediaType]
                                         relations:nil
                                         createdAt:[self createdAt]
                                         deletedAt:[self deletedAt]
                                         updatedAt:[self updatedAt]
                                     canonicalName:self.canonicalName
                                        isBodyLift:self.isBodyLift
                            percentageOfBodyWeight:self.percentageOfBodyWeight
                                       variantMask:self.variantMask
                                         sortOrder:self.sortOrder
                                  primaryMuscleIds:self.primaryMuscleIds
                                secondaryMuscleIds:self.secondaryMuscleIds];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMovement *)movement {
  [self setCanonicalName:movement.canonicalName];
  [self setIsBodyLift:movement.isBodyLift];
  [self setPercentageOfBodyWeight:movement.percentageOfBodyWeight];
  [self setVariantMask:movement.variantMask];
  [self setSortOrder:movement.sortOrder];
  [self setPrimaryMuscleIds:movement.primaryMuscleIds];
  [self setSecondaryMuscleIds:movement.secondaryMuscleIds];
}

- (void)overwrite:(RMovement *)movement {
  [super overwrite:movement];
  [self overwriteDomainProperties:movement];
}

#pragma mark - Equality

- (BOOL)isEqualToMovement:(RMovement *)movement {
  if (!movement) { return NO; }
  if ([super isEqualToMasterSupport:movement]) {
    return [PEUtils isStringProperty:@selector(canonicalName) equalFor:self and:movement] &&
    [PEUtils isBoolProperty:@selector(isBodyLift) equalFor:self and:movement] &&
    [PEUtils isNumProperty:@selector(percentageOfBodyWeight) equalFor:self and:movement] &&
    [PEUtils isNumProperty:@selector(variantMask) equalFor:self and:movement] &&
    [PEUtils isNumProperty:@selector(sortOrder) equalFor:self and:movement];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMovement class]]) { return NO; }
  return [self isEqualToMovement:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self canonicalName] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, canonical name: %@, \
is body lift: %@, percentage of body lift: %@, variant mask: %@, sort order: %@",
          [super description],
          _canonicalName,
          [PEUtils yesNoFromBool:_isBodyLift],
          _percentageOfBodyWeight,
          _variantMask,
          _sortOrder];
}


@end
