//
//  PEChangelog.m
//

#import "PEChangelog.h"

@implementation PEChangelog {
  PELMUser *_user;
}

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt {
  if (self) {
    _updatedAt = updatedAt;
  }
  return self;
}

#pragma mark - Creation Functions

+ (PEChangelog *)changelogOfClass:(Class)clazz
                    withUpdatedAt:(NSDate *)updatedAt {
  return [[clazz alloc] initWithUpdatedAt:updatedAt];
}

#pragma mark - Methods

- (void)setUser:(PELMUser *)user {
  _user = user;
}

- (PELMUser *)user {
  return _user;
}

@end
