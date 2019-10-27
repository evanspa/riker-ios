//
//  HCCharset.m
//

#import "HCCharset.h"

@implementation HCCharset {
  NSStringEncoding _encoding;
  NSString *_description;
}

#pragma mark - Initializers

- (id)initWithEncoding:(NSStringEncoding)encoding
           description:(NSString *)description {
  self = [super init];
  if (self) {
    _encoding = encoding;
    _description = description;
  }
  return self;
}

#pragma mark - NSObject

- (NSString *)description {
  return _description;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[HCCharset class]]) {
    return NO;
  }
  return [self isEqualToCharset:(HCCharset *)object];
}

- (NSUInteger)hash {
  return [self encoding];
}

#pragma mark - Equality

- (BOOL)isEqualToCharset:(HCCharset *)charset {
  if (!charset) {
    return NO;
  }
  return [self encoding] == [charset encoding];
}

#pragma mark - Class methods

+ (HCCharset *)UTF8 {
  return [[HCCharset alloc] initWithEncoding:NSUTF8StringEncoding description:@"UTF-8"];
}

+ (HCCharset *)Latin1 {
  return [[HCCharset alloc] initWithEncoding:NSISOLatin1StringEncoding description:@"ISO-8859-1"];
}

@end
