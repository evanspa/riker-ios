//
//  PELMMasterSupport.m
//

#import "PELMMasterSupport.h"
#import "PEUtils.h"

@implementation PELMMasterSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations];
  if (self) {
    _createdAt = createdAt;
    _deletedAt = deletedAt;
    _updatedAt = updatedAt;
  }
  return self;
}

#pragma mark - Methods

- (void)overwrite:(PELMMasterSupport *)entity {
  [super overwrite:entity];
  [self setCreatedAt:[entity createdAt]];
  [self setUpdatedAt:[entity updatedAt]];
  [self setDeletedAt:[entity deletedAt]];
}

#pragma mark - Equality

- (BOOL)isEqualToMasterSupport:(PELMMasterSupport *)masterSupport {
  if (!masterSupport) { return NO; }
  if ([super isEqualToModelSupport:masterSupport]) {
    return [PEUtils isDate:[self deletedAt] msprecisionEqualTo:[masterSupport deletedAt]] &&
      [PEUtils isDate:[self updatedAt] msprecisionEqualTo:[masterSupport updatedAt]] &&
      [PEUtils isDate:[self createdAt] msprecisionEqualTo:[masterSupport createdAt]];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMMasterSupport class]]) { return NO; }
  return [self isEqualToMasterSupport:object];
}

- (NSUInteger)hash {
  return [super hash] ^
    [[self deletedAt] hash] ^
    [[self updatedAt] hash] ^
    [[self createdAt] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, created-at: [{%@}, {%f}], deleted-at: [{%@}, {%f}], updated-at: [{%@}, {%f}]",
          [super description],
          _createdAt, [_createdAt timeIntervalSince1970],
          _deletedAt, [_deletedAt timeIntervalSince1970],
          _updatedAt, [_updatedAt timeIntervalSince1970]];
}

@end
