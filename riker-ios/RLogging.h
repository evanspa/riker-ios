#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef RIKER_DEV
  static const DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
  static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@interface RLogging : NSObject

#pragma mark - Initialization

+ (void)initializeLogging;

@end
