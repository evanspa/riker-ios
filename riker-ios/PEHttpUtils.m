//
// PEHttpUtils.m
//

#import "PEHttpUtils.h"

@implementation PEHttpUtils

#pragma mark - Helpers

+ (NSURL *)urlFromHost:(NSString *)host
                  port:(NSUInteger)port
                scheme:(NSString *)scheme {
  NSURLComponents *components = [NSURLComponents new];
  [components setPort:[NSNumber numberWithUnsignedInteger:port]];
  [components setHost:host];
  [components setScheme:scheme];
  [components setPath:@"/"];
  return [components URL];
}

@end
