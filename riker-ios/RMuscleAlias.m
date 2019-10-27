//
//  RMuscleAlias.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscleAlias.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMuscleAlias

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                           muscleId:(NSNumber *)muscleId
                              alias:(NSString *)alias {
  self = [super initWithLocalMainIdentifier:nil
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _muscleId = muscleId;
    _alias = alias;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMuscleAlias *copy =
  [[RMuscleAlias alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                     globalIdentifier:[self globalIdentifier]
                                            mediaType:[self mediaType]
                                            relations:nil
                                            createdAt:[self createdAt]
                                            deletedAt:[self deletedAt]
                                            updatedAt:[self updatedAt]
                                             muscleId:[self muscleId]
                                                alias:[self alias]];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMuscleAlias *)muscleAlias {
  [self setMuscleId:muscleAlias.muscleId];
  [self setAlias:muscleAlias.alias];
}

- (void)overwrite:(RMuscleAlias *)muscleAlias {
  [super overwrite:muscleAlias];
  [self overwriteDomainProperties:muscleAlias];
}

#pragma mark - Equality

- (BOOL)isEqualToMuscleAlias:(RMuscleAlias *)muscleAlias {
  if (!muscleAlias) { return NO; }
  if ([super isEqualToMasterSupport:muscleAlias]) {
    return [PEUtils isNumProperty:@selector(muscleId) equalFor:self and:muscleAlias] &&
    [PEUtils isStringProperty:@selector(alias) equalFor:self and:muscleAlias];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMuscleAlias class]]) { return NO; }
  return [self isEqualToMuscleAlias:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self muscleId] hash] ^ [[self alias] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, alias: %@, muscle id: %@",
          [super description], _alias, _muscleId];
}


@end
