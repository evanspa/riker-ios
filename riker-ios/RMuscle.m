//
//  RMuscle.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscle.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMuscle

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      muscleGroupId:(NSNumber *)muscleGroupId
                      canonicalName:(NSString *)canonicalName
                abbrevCanonicalName:(NSString *)abbrevCanonicalName {
  self = [super initWithLocalMainIdentifier:nil
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _muscleGroupId = muscleGroupId;
    _canonicalName = canonicalName;
    _abbrevCanonicalName = abbrevCanonicalName;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMuscle *copy =
  [[RMuscle alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                globalIdentifier:[self globalIdentifier]
                                       mediaType:[self mediaType]
                                       relations:nil
                                       createdAt:[self createdAt]
                                       deletedAt:[self deletedAt]
                                       updatedAt:[self updatedAt]
                                   muscleGroupId:[self muscleGroupId]
                                   canonicalName:[self canonicalName]
                             abbrevCanonicalName:[self abbrevCanonicalName]];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMuscle *)muscle {
  [self setMuscleGroupId:muscle.muscleGroupId];
  [self setCanonicalName:muscle.canonicalName];
  [self setAbbrevCanonicalName:muscle.abbrevCanonicalName];
}

- (void)overwrite:(RMuscle *)muscle {
  [super overwrite:muscle];
  [self overwriteDomainProperties:muscle];
}

#pragma mark - Equality

- (BOOL)isEqualToMuscle:(RMuscle *)muscle {
  if (!muscle) { return NO; }
  if ([super isEqualToMasterSupport:muscle]) {
    return [PEUtils isNumProperty:@selector(muscleGroupId) equalFor:self and:muscle] &&
    [PEUtils isStringProperty:@selector(abbrevCanonicalName) equalFor:self and:muscle] &&
    [PEUtils isStringProperty:@selector(canonicalName) equalFor:self and:muscle];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMuscle class]]) { return NO; }
  return [self isEqualToMuscle:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self muscleGroupId] hash] ^ [[self canonicalName] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, canonical name: %@, abbrev canonical name: %@, muscle group id: %@",
          [super description], _canonicalName, _abbrevCanonicalName, _muscleGroupId];
}


@end
