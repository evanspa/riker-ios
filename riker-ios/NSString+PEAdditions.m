//
// NSString+PEAdditions.m
//

#import "NSString+PEAdditions.h"

@implementation NSString (PEAdditions)

- (BOOL)isBlank {
  return [[self stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0;
}

- (NSString *)nonBreaking {
  return [self stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
}

@end
