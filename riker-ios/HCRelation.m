//
//  HCRelation.m
//

#import "HCRelation.h"
#import "HCResource.h"

@implementation HCRelation {
  NSString *_name;
  HCResource *_subject;
  HCResource *_target;
}

#pragma mark - Initializers

- (id)initWithName:(NSString *)name
   subjectResource:(HCResource *)subject
    targetResource:(HCResource *)target {
  self = [super init];
  if (self) {
    _name = name;
    _subject = subject;
    _target = target;
  }
  return self;
}

#pragma mark - Equality

- (BOOL)isEqualToRelation:(HCRelation *)relation {
  if (!relation) {
    return NO;
  }
  BOOL haveEqualNames = [[self name] isEqualToString:[relation name]];
  BOOL haveEqualSubjects = [[self subject] isEqualToResource:[relation subject]];
  BOOL haveEqualTargets = [[self target] isEqualToResource:[relation target]];
  return haveEqualNames && haveEqualSubjects && haveEqualTargets;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[HCRelation class]]) {
    return NO;
  }
  return [self isEqualToRelation:(HCRelation *)object];
}

- (NSUInteger)hash {
  return [[self name] hash] ^ [[self subject] hash] ^ [[self target] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"name: [%@], subject resource: [%@], \
target resource: [%@]", _name, _subject, _target];
}

@end
