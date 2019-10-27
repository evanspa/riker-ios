//
//  PEBaseController.h
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "RUIUtils.h"

@interface PEBaseController : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate>

#pragma mark - Initializers

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle;

- (instancetype)initWithRequireRepaintNotifications:(NSArray *)notifications
                                        screenTitle:(NSString *)screenTitle
                                    screenNameToLog:(NSString *)screenNameToLog;

#pragma mark - Properties

@property (nonatomic) UIView *displayPanel;

@property (nonatomic) CGPoint scrollContentOffset;

@property (nonatomic) BOOL needsRepaint;

@property (nonatomic) BOOL scrollToTopOnRepaint;

@property (nonatomic) BOOL delaysContentTouches;

@property (nonatomic) NSString *screenTitle;

@property (nonatomic) NSString *screenNameToLog;

@property (nonatomic) BOOL hasScreenNameBeenLogged;

@property (nonatomic) BOOL usesScrollView;

#pragma mark - Enable User Interaction

- (REnableUserInteractionBlk)makeUserEnabledBlock;

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel;

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset;

#pragma mark - Device Rotation notification

- (void)willRepaintDueToRotate;

@end
