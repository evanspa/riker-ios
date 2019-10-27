//
//  NSHTTPURLResponse+HCAdditions.m
//

#import "NSHTTPURLResponse+HCAdditions.h"

@implementation NSHTTPURLResponse (HCAdditions)

#pragma mark - NSObject protocol

- (NSString *)description {
  NSString *desc = [NSString stringWithFormat:@"Status code: [%ld].  \
Headers: [", (long)[self statusCode]];
  NSDictionary *headers = [self allHeaderFields];
  __block NSString *headersStr = @"";
  __block int count = 0;
  [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (count > 0) {
      headersStr = [NSString stringWithFormat:@"%@, ", headersStr];
    }
    headersStr = [NSString stringWithFormat:@"%@{%@ : %@}", headersStr, key, obj];
    count++;
  }];
  return [NSString stringWithFormat:@"%@%@].", desc, headersStr];
}

@end
