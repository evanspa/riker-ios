//
//  PELocalDataBaseController.h
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

@interface PELocalDataBaseController : PEBaseController <UIScrollViewDelegate>

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle;

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle
                                    screenNameToLog:(NSString *)screenNameToLog;

@end
