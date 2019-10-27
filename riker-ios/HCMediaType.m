//
//  HCMediaType.m
//

#import "HCMediaType.h"
#import "PEUtils.h"

@implementation HCMediaType

#pragma mark - Initializers

- (id)initWithType:(NSString *)type subType:(NSString *)subType {
  return [self initWithType:type subType:subType version:nil format:nil];
}

- (id)initWithType:(NSString *)type
           subType:(NSString *)subType
           version:(NSString *)version
            format:(NSString *)format {
  self = [super init];
  if (self) {
    _type = type;
    _subType = subType;
    _version = version;
    _format = format;
  }
  return self;
}

#pragma mark - Factory Functions

+ (HCMediaType *)MediaTypeFromString:(NSString *)mediaTypeStr {
  NSArray *comps = [mediaTypeStr componentsSeparatedByString:@"/"];
  NSString *type = nil;
  NSString *subType = nil;
  if (comps) {
    if ([comps count] >= 1) {
      type = [comps firstObject];
      if ([comps count] >= 2) {
        subType = [comps objectAtIndex:1];
      }
    }
  }
  return [[HCMediaType alloc] initWithType:type subType:subType];
}

#pragma mark - Equality

- (BOOL)isEqualToMediaType:(HCMediaType *)mediaType {
  if (!mediaType) {
    return NO;
  }
  BOOL haveEqualTypes = [PEUtils nilSafeIs:[self type] equalTo:[mediaType type]]; //[[self type] isEqualToString:[mediaType type]];
  BOOL haveEqualSubTypes = [PEUtils nilSafeIs:[self subType] equalTo:[mediaType subType]]; //[[self subType] isEqualToString:[mediaType subType]];
  return haveEqualTypes && haveEqualSubTypes;
}

#pragma mark - NSObject

- (NSString *)description {
  NSString *description = [NSString stringWithFormat:@"%@/%@", _type, _subType];
  if (_version) {
    description = [description stringByAppendingFormat:@"-v%@", _version];
  }
  if (_format) {
    description = [description stringByAppendingFormat:@"+%@", _format];
  }
  return description;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[HCMediaType class]]) {
    return NO;
  }
  return [self isEqualToMediaType:(HCMediaType *)object];
}

- (NSUInteger)hash {
  return [[self type] hash] ^ [[self subType] hash];
}

@end
