//
//  PELocalDataBaseController.m
//

#import "PELocalDataBaseController.h"
#import "PELMNotificationNames.h"

@implementation PELocalDataBaseController

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle {
  return [self initWithRequireRepaintNotifications:notifications
                                       screenTitle:screenTitle
                                   screenNameToLog:screenTitle];
}

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle
                                    screenNameToLog:(NSString *)screenNameToLog {
  NSMutableArray *repaintNotifications = [NSMutableArray array];
  if (notifications) {
    [repaintNotifications addObjectsFromArray:notifications];
  }
  [repaintNotifications addObject:PELMNotificationDbUpdate];
  return [super initWithRequireRepaintNotifications:repaintNotifications
                                        screenTitle:screenTitle
                                    screenNameToLog:screenNameToLog];
}

@end
