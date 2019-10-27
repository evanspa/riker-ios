//
//  NSURL+HCAdditions.m
//

#import "NSURL+HCAdditions.h"

@implementation NSURL (HCAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
  if (![queryString length]) {
    return self;
  }
  NSString *URLString =
    [[NSString alloc] initWithFormat:@"%@%@%@", [self absoluteString],
     [self query] ? @"&" : @"?",
      [queryString
       stringByAddingPercentEncodingWithAllowedCharacters:
        [NSCharacterSet URLQueryAllowedCharacterSet]]];
  return [NSURL URLWithString:URLString];
}

@end
