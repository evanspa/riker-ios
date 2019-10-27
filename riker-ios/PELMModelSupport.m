//
//  PELMModelSupport.m
//

#import "PELMModelSupport.h"
#import "PEUtils.h"
#import "HCRelation.h"
#import "HCMediaType.h"
#import "PELMUtils.h"

@implementation PELMModelSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations {
  self = [super init];
  if (self) {
    _localMasterIdentifier = localMasterIdentifier;
    _globalIdentifier = globalIdentifier;
    _mediaType = mediaType;
  }
  return self;
}

#pragma mark - Methods

- (NSNumber *)localMainIdentifier {
  return _localMasterIdentifier;
}

- (void)overwrite:(PELMModelSupport *)entity {
  [self setGlobalIdentifier:[entity globalIdentifier]];
  [self setMediaType:[entity mediaType]];
}

#pragma mark - PELMIdentifiable Protocol

- (BOOL)doesHaveEqualIdentifiers:(id<PELMIdentifiable>)entity {
  if (_globalIdentifier && [entity globalIdentifier]) {
    return ([_globalIdentifier isEqualToString:[entity globalIdentifier]]);
  } else if (_localMasterIdentifier && [entity localMasterIdentifier]) {
    return ([_localMasterIdentifier isEqualToNumber:[entity localMasterIdentifier]]);
  }
  return NO;
}

#pragma mark - Equality

- (BOOL)isEqualToModelSupport:(PELMModelSupport *)modelSupport {
  if (!modelSupport) { return NO; }
  BOOL hasEqualGlobalIds =
    [PEUtils isString:[self globalIdentifier] equalTo:[modelSupport globalIdentifier]];
  BOOL hasEqualMediaTypes = [PEUtils nilSafeIs:[self mediaType] equalTo:[modelSupport mediaType]];
  return hasEqualGlobalIds && hasEqualMediaTypes;
}

#pragma mark - NSObject

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[PELMModelSupport class]]) { return NO; }
  return [self isEqualToModelSupport:object];
}

- (NSUInteger)hash {
  return [[self globalIdentifier] hash] ^
    [[self localMainIdentifier] hash] ^
    [[self localMasterIdentifier] hash] ^
    [[self mediaType] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"type: [%@], memory address: [%p], \
local master ID: [%@], global ID: [%@], media type: [%@]",
          NSStringFromClass([self class]), self, _localMasterIdentifier,
          _globalIdentifier, [_mediaType description]];
}

@end
