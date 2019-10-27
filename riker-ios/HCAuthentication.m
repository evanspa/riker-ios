//
//  HCAuthentication.m
//

#import "HCAuthentication.h"

@implementation HCAuthentication

#pragma mark - Initializers

- (id)initWithAuthScheme:(NSString *)authScheme
                   realm:(NSString *)realm
              authParams:(NSDictionary *)authParams {
  self = [super initWithAuthScheme:authScheme authParams:authParams];
  if (self) {
    _realm = realm;
  }
  return self;
}

#pragma mark - Equality

- (BOOL)isEqualToAuthentication:(HCAuthentication *)auth {
  if (!auth) {
    return NO;
  }
  BOOL haveEqualSchemes = [[self authScheme] isEqualToString:[auth authScheme]];
  BOOL haveEqualRealms = [[self realm] isEqualToString:[auth realm]];
  BOOL haveEqualParams = [self authParams] == [auth authParams] ||
    [[self authParams] isEqualToDictionary:[auth authParams]];
  return haveEqualSchemes && haveEqualRealms && haveEqualParams;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[HCAuthentication class]]) {
    return NO;
  }
  return [self isEqualToAuthentication:(HCAuthentication *)object];
}

- (NSUInteger)hash {
  return [[self authScheme] hash] ^ [[self realm] hash] ^ [[self authParams] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Authentication scheme: [%@], realm: [%@], \
auth params: [%@]", [self authScheme], [self realm], [self authParams]];
}


#pragma mark - Factory Functions

+ (HCAuthentication *)authWithScheme:(NSString *)authScheme
                               realm:(NSString *)realm {
  return [[HCAuthentication alloc] initWithAuthScheme:authScheme
                                                realm:realm
                                           authParams:nil];
}

+ (HCAuthentication *)authWithScheme:(NSString *)authScheme {
  return [HCAuthentication authWithScheme:authScheme realm:nil];
}

@end
