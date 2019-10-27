//
//  NSURLRequest+HCAdditions.m
//

#import "NSURLRequest+HCAdditions.h"

@implementation NSURLRequest (HCAdditions)

#pragma mark - NSObject protocol

- (NSString *)description {
  NSString *desc = [NSString stringWithFormat:@"Method: [%@].  \
URL: [%@].  Headers: [", [self HTTPMethod], [self URL]];
  NSDictionary *headers = [self allHTTPHeaderFields];
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
