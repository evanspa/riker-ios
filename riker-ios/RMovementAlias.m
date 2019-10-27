//
//  RMovementAlias.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovementAlias.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMovementAlias

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                         movementId:(NSNumber *)movementId
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
    _movementId = movementId;
    _alias = alias;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMovementAlias *copy =
  [[RMovementAlias alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                       globalIdentifier:[self globalIdentifier]
                                              mediaType:[self mediaType]
                                              relations:nil
                                              createdAt:[self createdAt]
                                              deletedAt:[self deletedAt]
                                              updatedAt:[self updatedAt]
                                             movementId:[self movementId]
                                                  alias:[self alias]];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMovementAlias *)movementAlias {
  [self setMovementId:movementAlias.movementId];
  [self setAlias:movementAlias.alias];
}

- (void)overwrite:(RMovementAlias *)movementAlias {
  [super overwrite:movementAlias];
  [self overwriteDomainProperties:movementAlias];
}

#pragma mark - Equality

- (BOOL)isEqualToMovementAlias:(RMovementAlias *)movementAlias {
  if (!movementAlias) { return NO; }
  if ([super isEqualToMasterSupport:movementAlias]) {
    return [PEUtils isStringProperty:@selector(alias) equalFor:self and:movementAlias] &&
    [PEUtils isNumProperty:@selector(movementId) equalFor:self and:movementAlias];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMovementAlias class]]) { return NO; }
  return [self isEqualToMovementAlias:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self alias] hash] ^ [[self movementId] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, alias: %@, movement id: %@",
          [super description], _alias, _movementId];
}


@end
