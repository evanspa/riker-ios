//
//  RMuscleGroup.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscleGroup.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RMuscleGroup

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      bodySegmentId:(NSNumber *)bodySegmentId
                               name:(NSString *)name
                         abbrevName:(NSString *)abbrevName {
  self = [super initWithLocalMainIdentifier:nil
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt];
  if (self) {
    _bodySegmentId = bodySegmentId;
    _name = name;
    _abbrevName = abbrevName;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RMuscleGroup *copy =
  [[RMuscleGroup alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                     globalIdentifier:[self globalIdentifier]
                                            mediaType:[self mediaType]
                                            relations:nil
                                            createdAt:[self createdAt]
                                            deletedAt:[self deletedAt]
                                            updatedAt:[self updatedAt]
                                        bodySegmentId:_bodySegmentId
                                                 name:_name
                                           abbrevName:_abbrevName];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMuscleGroup *)muscleGroup {
  [self setBodySegmentId:[muscleGroup bodySegmentId]];
  [self setName:[muscleGroup name]];
  [self setAbbrevName:[muscleGroup abbrevName]];
}

- (void)overwrite:(RMuscleGroup *)muscleGroup {
  [super overwrite:muscleGroup];
  [self overwriteDomainProperties:muscleGroup];
}

#pragma mark - Equality

- (BOOL)isEqualToMuscleGroup:(RMuscleGroup *)muscleGroup {
  if (!muscleGroup) { return NO; }
  if ([super isEqualToMasterSupport:muscleGroup]) {
    return [PEUtils isStringProperty:@selector(name) equalFor:self and:muscleGroup] &&
    [PEUtils isStringProperty:@selector(abbrevName) equalFor:self and:muscleGroup] &&
    [PEUtils isNumProperty:@selector(bodySegmentId) equalFor:self and:muscleGroup];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RMuscleGroup class]]) { return NO; }
  return [self isEqualToMuscleGroup:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self name] hash] ^ [[self bodySegmentId] hash] ^ [[self abbrevName] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: %@, abbrevName: %@, body segment id: %@",
          [super description], _name, _abbrevName, _bodySegmentId];
}

@end
