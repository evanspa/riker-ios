//
//  ROriginationDevice.m
//  riker-ios
//
//  Created by PEVANS on 10/18/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "ROriginationDevice.h"
#import "PEUtils.h"
#import "RDDLUtils.h"

@implementation ROriginationDevice

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name
                      iconImageName:(NSString *)iconImageName
                      hasLocalImage:(BOOL)hasLocalImage {
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
    _iconImageName = iconImageName;
    _hasLocalImage = hasLocalImage;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  ROriginationDevice *copy =
  [[ROriginationDevice alloc] initWithLocalMasterIdentifier:[self localMasterIdentifier]
                                           globalIdentifier:[self globalIdentifier]
                                                  mediaType:[self mediaType]
                                                  relations:nil
                                                  createdAt:[self createdAt]
                                                  deletedAt:[self deletedAt]
                                                  updatedAt:[self updatedAt]
                                                       name:[self name]
                                              iconImageName:[self iconImageName]
                                              hasLocalImage:[self hasLocalImage]];
  return copy;
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(ROriginationDevice *)originationDevice {
  [self setName:originationDevice.name];
  [self setIconImageName:originationDevice.iconImageName];
  [self setHasLocalImage:originationDevice.hasLocalImage];
}

- (void)overwrite:(ROriginationDevice *)originationDevice {
  [super overwrite:originationDevice];
  [self overwriteDomainProperties:originationDevice];
}

#pragma mark - Equality

- (BOOL)isEqualToOriginationDevice:(ROriginationDevice *)originationDevice {
  if (!originationDevice) { return NO; }
  if ([super isEqualToMasterSupport:originationDevice]) {
    return [PEUtils isStringProperty:@selector(name) equalFor:self and:originationDevice] &&
    [PEUtils isStringProperty:@selector(iconImageName) equalFor:self and:originationDevice];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[ROriginationDevice class]]) { return NO; }
  return [self isEqualToOriginationDevice:object];
}

- (NSUInteger)hash {
  return [super hash] ^ [[self name] hash] ^ [[self iconImageName] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, name: %@, icon image name: %@, has local image: %@",
          [super description],
          _name,
          _iconImageName,
          [PEUtils yesNoFromBool:_hasLocalImage]];
}

@end
