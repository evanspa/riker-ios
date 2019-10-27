//
//  RBodySegment.m
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RBodySegment.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation RBodySegment

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name {
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
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RBodySegment *copy =
  [[RBodySegment alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                     globalIdentifier:[self globalIdentifier]
                                            mediaType:[self mediaType]
                                            relations:nil
                                            createdAt:[self createdAt]
                                            deletedAt:[self deletedAt]
                                            updatedAt:[self updatedAt]
                                                 name:_name];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RBodySegment *)bodySegment {
  [self setName:[bodySegment name]];
}

- (void)overwrite:(RBodySegment *)bodySegment {
  [super overwrite:bodySegment];
  [self overwriteDomainProperties:bodySegment];
}

#pragma mark - Equality

- (BOOL)isEqualToBodySegment:(RBodySegment *)bodySegment {
  if (!bodySegment) { return NO; }
  if ([super isEqualToMasterSupport:bodySegment]) {
    return [PEUtils isStringProperty:@selector(name) equalFor:self and:bodySegment];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RBodySegment class]]) { return NO; }
  return [self isEqualToBodySegment:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self name] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: [%@]", [super description], _name];
}

@end
