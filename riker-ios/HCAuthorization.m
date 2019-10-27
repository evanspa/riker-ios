//
//  HCAuthorization.m
//

#import "HCAuthorization.h"

@implementation HCAuthorization

#pragma mark - Initializers

- (id)initWithAuthScheme:(NSString *)authScheme
              authParams:(NSDictionary *)authParams {
  self = [super init];
  if (self) {
    _authScheme = authScheme;
    _authParams = authParams;
  }
  return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAuthorization:(HCAuthorization *)auth {
  if (!auth) {
    return NO;
  }
  BOOL haveEqualSchemes = [[self authScheme] isEqualToString:[auth authScheme]];
  BOOL haveEqualParams = [[self authParams] isEqualToDictionary:[auth authParams]];
  return haveEqualSchemes && haveEqualParams;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[HCAuthorization class]]) {
    return NO;
  }
  return [self isEqualToAuthorization:(HCAuthorization *)object];
}

- (NSUInteger)hash {
  return [[self authScheme] hash] ^ [[self authParams] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Authorization scheme: [%@], auth \
params: [%@]", [self authScheme], [self authParams]];
}

#pragma mark - Factory Functions

+ (HCAuthorization *)authWithScheme:(NSString *)authScheme
                singleAuthParamName:(NSString *)paramName
                     authParamValue:(NSString *)paramValue {
  return [[HCAuthorization alloc]
          initWithAuthScheme:authScheme
                  authParams:[NSMutableDictionary
                              dictionaryWithObject:paramValue
                                           forKey:paramName]];
}

@end
