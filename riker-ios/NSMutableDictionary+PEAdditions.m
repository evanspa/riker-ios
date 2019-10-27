//
// NSMutableDictionary+PEAdditions.m
//

#import "NSMutableDictionary+PEAdditions.h"
#import "NSString+PEAdditions.h"
#import "PEUtils.h"
#import "NSDate+RAdditions.h"

@implementation NSMutableDictionary (PEAdditions)

- (void)setObjectIfNotNull:(id)object forKey:(id<NSCopying>)key {
  if (object) {
    [self setObject:object forKey:key];
  }
}

- (void)setStringIfNotBlank:(NSString *)strValue forKey:(id<NSCopying>)key {
  if (strValue && ![strValue isBlank]) {
    [self setObject:strValue forKey:key];
  }
}

- (void)nullSafeSetObject:(id)object forKey:(id<NSCopying>)key {
  if (object) {
    [self setObject:object forKey:key];
  } else {
    [self setObject:[NSNull null] forKey:key];
  }
}

- (void)setMillisecondsSince1970FromDate:(NSDate *)date forKey:(id<NSCopying>)key {
  if (![PEUtils isNil:date]) {    
    NSDecimalNumber *numTime = [date toUnixTime];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.maximumFractionDigits = 0;
    NSString *numTimeStr = [numberFormatter stringFromNumber:numTime];
    [self setObject:numTimeStr forKey:key];
  }
}

@end
