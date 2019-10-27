#import "RLogging.h"

@implementation RLogging

#pragma mark - Initialization

+ (void)initializeLogging {
  [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

@end
