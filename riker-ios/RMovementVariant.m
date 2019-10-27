//
//  RMovementVariant.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovementVariant.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMovementVariant

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name
                         abbrevName:(NSString *)abbrevName
                 variantDescription:(NSString *)variantDescription
                          sortOrder:(NSNumber *)sortOrder {
  self = [super initWithLocalMainIdentifier:nil
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _name = name;
    _abbrevName = abbrevName;
    _variantDescription = variantDescription;
    _sortOrder = sortOrder;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMovementVariant *copy =
  [[RMovementVariant alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                         globalIdentifier:[self globalIdentifier]
                                                mediaType:[self mediaType]
                                                relations:nil
                                                createdAt:[self createdAt]
                                                deletedAt:[self deletedAt]
                                                updatedAt:[self updatedAt]
                                                     name:[self name]
                                               abbrevName:[self abbrevName]
                                       variantDescription:[self variantDescription]
                                                sortOrder:[self sortOrder]];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMovementVariant *)movementVariant {
  [self setName:movementVariant.name];
  [self setAbbrevName:movementVariant.abbrevName];
  [self setVariantDescription:movementVariant.description];
  [self setSortOrder:movementVariant.sortOrder];
}

- (void)overwrite:(RMovementVariant *)movementVariant {
  [super overwrite:movementVariant];
  [self overwriteDomainProperties:movementVariant];
}

#pragma mark - Equality

- (BOOL)isEqualToMovementVariant:(RMovementVariant *)movementVariant {
  if (!movementVariant) { return NO; }
  if ([super isEqualToMasterSupport:movementVariant]) {
    return [PEUtils isStringProperty:@selector(name) equalFor:self and:movementVariant] &&
    [PEUtils isStringProperty:@selector(abbrevName) equalFor:self and:movementVariant] &&
    [PEUtils isStringProperty:@selector(description) equalFor:self and:movementVariant] &&
    [PEUtils isNumProperty:@selector(sortOrder) equalFor:self and:movementVariant];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMovementVariant class]]) { return NO; }
  return [self isEqualToMovementVariant:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self name] hash] ^ [[self description] hash] ^ [self.sortOrder hash] ^ [self.abbrevName hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: %@, abbrevName: %@, description: %@, sort order: %@",
          [super description], _name, _abbrevName, _variantDescription, _sortOrder];
}

@end
