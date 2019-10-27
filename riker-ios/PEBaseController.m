//
//  PEBaseController.m
//

#import "PEBaseController.h"
#import "PEUIUtils.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RAppNotificationNames.h"
#import <FlatUIKit/UIColor+FlatUI.h>

@implementation PEBaseController {
  NSArray *_requireRepaintNotifications;  
  UIInterfaceOrientation _currentOrientation;
  NSDecimalNumber *_makeAndRenderContentDelay;
}

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
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _requireRepaintNotifications = notifications;
    _screenTitle = screenTitle;
    _screenNameToLog = screenNameToLog;
    _delaysContentTouches = YES;
  }
  return self;
}

#pragma mark - Dynamic Type Support

- (void)changeTextSize:(NSNotification *)notification {
  _needsRepaint = YES;
  [self viewDidAppear:YES];
}

#pragma mark - Device Rotation notification

- (void)deviceRotated:(NSNotification *)notification {
  // For some reason, I need to have a delay here or the value of 'newOrientation'
  // will be old (for some reason, after a rotate, the value of [UIApplication sharedApplication].statusBarOrientation
  // takes a bit of time to actually reflect the new orientation).  So far, I'm only
  // seeing this delay on iPad, FYI.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (_currentOrientation == newOrientation) {
      return;
    }
    _currentOrientation = newOrientation;
    _needsRepaint = YES;
    [self willRepaintDueToRotate];
    // we only want the currently-visible controller's viewDidAppear to be invoked
    if (self.isViewLoaded && self.view.window) { // http://stackoverflow.com/a/2777460/1034895
      [self viewDidAppear:YES];
      MBProgressHUD *hud = [self.view viewWithTag:RHUD_TAG];
      if (hud && !hud.isHidden) {
        [self.view bringSubviewToFront:hud];
      }
    }
  });
}

- (void)willRepaintDueToRotate {} // to be overridden in subclasses as needed

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  _scrollContentOffset = [scrollView contentOffset];
}

#pragma mark - Enable User Interaction

- (REnableUserInteractionBlk)makeUserEnabledBlock {
  return ^(BOOL enable) {
    [[[self navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:enable];
  };
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel { return nil; }

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset {
  _scrollContentOffset = CGPointMake(0.0, 0.0);
}

#pragma mark - Hide Keyboard

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - Notification Observing

- (void)requireRepaint:(NSNotification *)notification {
  _needsRepaint = YES;
}

- (void)offlineModeToggledOn:(NSNotification *)notification {
  [PEUIUtils addOfflineModeBarToController:self animate:YES];
}

- (void)offlineModeToggledOff:(NSNotification *)notification {
  [PEUIUtils removeOfflineModeBarFromController:self animated:YES];
}

#pragma mark - Display Panel

- (UIView *)makeDisplayPanelWithContentPanel:(UIView *)contentPanel
                               withScrolling:(BOOL)scrolling
                            forceScrollPanel:(BOOL)forceScrollPanel {
  return [PEUIUtils displayPanelFromContentPanel:contentPanel
                                       scrolling:scrolling
                                forceScrollPanel:forceScrollPanel
                             scrollContentOffset:_scrollContentOffset
                                  scrollDelegate:self
                            delaysContentTouches:YES
                                         bounces:YES
                                notScrollViewBlk:^{ [self resetScrollOffset]; }
                                      controller:self];
}

- (void)placeDisplayPanelWithCentering:(BOOL)centering {
  void (^placeOnTop)(void) = ^{
    [PEUIUtils placeView:_displayPanel
                 atTopOf:self.view
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:[PEUIUtils vpaddingForTopOfController:self]
                hpadding:0.0];
  };
  if ([_displayPanel isKindOfClass:[UIScrollView class]]) {
    placeOnTop();
    UIScrollView *displayPanelScrollView = (UIScrollView *)_displayPanel;
    [displayPanelScrollView setDelaysContentTouches:_delaysContentTouches];
    [displayPanelScrollView setShowsVerticalScrollIndicator:NO];
  } else {
    if (centering && ![PEUIUtils isIpad]) {
      if (self.navigationController && !self.navigationController.navigationBar.hidden) {
        if (self.tabBarController) {
          [PEUIUtils placeView:_displayPanel
                          onto:self.view
               inMiddleBetween:self.navigationController.navigationBar
                           and:self.tabBarController.tabBar
                 withAlignment:PEUIHorizontalAlignmentTypeCenter
                      hpadding:0.0];
        } else {
          [PEUIUtils placeView:_displayPanel
                          onto:self.view
               inMiddleBetween:self.navigationController.navigationBar
                     andYCoord:self.view.frame.size.height
                 withAlignment:PEUIHorizontalAlignmentTypeCenter
                      hpadding:0.0];
        }
      } else if (self.tabBarController) {
        [PEUIUtils placeView:_displayPanel
                        onto:self.view
       inMiddleBetweenYCoord:self.view.frame.origin.y
                     andView:self.tabBarController.tabBar
               withAlignment:PEUIHorizontalAlignmentTypeCenter
                    hpadding:0.0];
      } else {
        [PEUIUtils placeView:_displayPanel
                  inMiddleOf:self.view
               withAlignment:PEUIHorizontalAlignmentTypeCenter
                    hpadding:0.0];
      }
    } else {
      placeOnTop();
    }
  }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  _currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
  [[self navigationItem] setTitle:_screenTitle];
  [RUIUtils styleNavbarForController:self];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceRotated:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(offlineModeToggledOn:)
                                               name:ROfflineModeToggledOnNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(offlineModeToggledOff:)
                                               name:ROfflineModeToggledOffNotification
                                             object:nil];
  if (_requireRepaintNotifications) {
    for (NSString *notificationName in _requireRepaintNotifications) {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(requireRepaint:)
                                                   name:notificationName
                                                 object:nil];
    }
  }
  UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [gestureRecognizer setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:gestureRecognizer];
  if ([APP offlineMode]) {
    [PEUIUtils addOfflineModeBarToController:self animate:NO];
  }
  NSArray *content = [self makeContentWithOldContentPanel:nil];
  UIView *contentPanel = content[0];
  BOOL scrolling = [(NSNumber *)content[1] boolValue];
  BOOL center = [(NSNumber *) content[2] boolValue];
  BOOL forceScrollPanel = NO;
  if (content.count > 3) {
    forceScrollPanel = [(NSNumber *)content[3] boolValue];
  }
  _displayPanel = [self makeDisplayPanelWithContentPanel:contentPanel
                                           withScrolling:scrolling
                                        forceScrollPanel:forceScrollPanel];
  [self placeDisplayPanelWithCentering:center];
  _needsRepaint = NO;
  [PEUIUtils bringOfflineModeViewsToFrontForController:self];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (!_hasScreenNameBeenLogged) {
    [RUtils logScreen:_screenNameToLog fromController:self];
    _hasScreenNameBeenLogged = YES;
  }
  //NSLog(@"inside PEBaseController, viewDidAppear, _needsRepaint: %d, ctrl: %@", _needsRepaint, NSStringFromClass(self.class));
  if (_needsRepaint) {
    [PEUIUtils removeOfflineModeBarFromController:self animated:NO];
    if ([APP offlineMode]) {
      [PEUIUtils addOfflineModeBarToController:self animate:NO];
    }
    NSArray *content = [self makeContentWithOldContentPanel:_displayPanel];
    [_displayPanel removeFromSuperview];
    UIView *contentPanel = content[0];
    BOOL scrolling = [(NSNumber *)content[1] boolValue];
    BOOL center = [(NSNumber *) content[2] boolValue];
    BOOL forceScrollPanel = NO;
    if (content.count > 3) {
      forceScrollPanel = [(NSNumber *)content[3] boolValue];
    }
    _displayPanel = [self makeDisplayPanelWithContentPanel:contentPanel
                                             withScrolling:scrolling
                                          forceScrollPanel:forceScrollPanel];
    [self placeDisplayPanelWithCentering:center];
    _usesScrollView = [_displayPanel isKindOfClass:[UIScrollView class]];
    if (_scrollToTopOnRepaint && _usesScrollView) {
      UIScrollView *displayPanelAsScrollView = (UIScrollView *)_displayPanel;
      [displayPanelAsScrollView setDelaysContentTouches:_delaysContentTouches];
      [displayPanelAsScrollView setContentOffset:CGPointMake(0, -displayPanelAsScrollView.contentInset.top)
                                        animated:YES];
    }
    _needsRepaint = NO;
  }
  [PEUIUtils bringOfflineModeViewsToFrontForController:self];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  WCSession *session = [WCSession defaultSession];
  session.delegate = APP; // re-assign back to app delegate
}

@end
