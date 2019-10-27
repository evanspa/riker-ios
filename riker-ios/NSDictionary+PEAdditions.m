//
//  NSDictionary+PEAdditions.m
//

#import "NSDictionary+PEAdditions.h"
#import "PEUtils.h"

@implementation NSDictionary (PEAdditions)

- (NSDate *)dateSince1970ForKey:(NSString *)key {
  NSDate *date = nil;
  NSNumber *dateNum = [self objectForKey:key];
  if (![PEUtils isNil:dateNum]) {
    date = [NSDate dateWithTimeIntervalSince1970:([dateNum doubleValue] / 1000.0)];
  }
  return date;
}

- (BOOL)boolForKey:(NSString *)key {
  return [self boolForKey:key defaultBool:NO];
}

- (NSDecimalNumber *)decimalNumberForKey:(NSString *)key {
  id object = [self objectForKey:key];
  if (![PEUtils isNil:object]) {
    return [NSDecimalNumber decimalNumberWithString:[object description]];
  }
  return nil;
}

- (NSNumber *)numberFromBoolForKey:(NSString *)key {
  id object = [self objectForKey:key];
  if (![PEUtils isNil:object]) {
    return [NSNumber numberWithBool:[object boolValue]];
  }
  return nil;
}

- (BOOL)boolForKey:(NSString *)key defaultBool:(BOOL)defaultBool {
  id object = [self objectForKey:key];
  if (![PEUtils isNil:object]) {
    return [object boolValue];
  }
  return defaultBool;
}

@end
