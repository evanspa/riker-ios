//
//  RSplashController.m
//  riker-ios
//
//  Created by PEVANS on 10/29/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RSplashController.h"
#import "RCoordinatorDao.h"
#import "PELocalDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RUIUtils.h"
#import "UIColor+RAdditions.h"
#import "UIFont+RAdditions.h"
#import "RUtils.h"
#import "PELMUser.h"
@import Firebase;

@implementation RSplashController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  NSArray *_carouselViewMakers;
  NSInteger _numCarouselViewMakers;
  UIView *_dotsPanel;
  BOOL _isCarouselRemoved;
  BOOL _againMode;
  NSInteger _carouselIndex;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                     againMode:(BOOL)againMode {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Riker Splash"
                                    screenNameToLog:againMode ? @"splash_again" : @"splash"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _againMode = againMode;
    _carouselViewMakers = @[ ^UIView * { return [self rootCarouselView]; },
                              ^UIView * { return [self enterRepsCarouselView]; },
                              ^UIView * { return [self enterRepsWatchCarouselView]; },
                              ^UIView * { return [self enterBmlCarouselView]; },
                              ^UIView * { return [self enterBmlWatchCarouselView]; },
                              ^UIView * { return [self plentyOfChartsLineCarouselView]; },
                              ^UIView * { return [self plentyOfChartsPieCarouselView]; },                             
                              ^UIView * { return [self exportCarouselView]; }
                             ];
    _numCarouselViewMakers = [_carouselViewMakers count];
  }
  return self;
}

#pragma mark - Carousel View Maker Helper

- (UIView *)carouselViewWithImageName:(NSString *)imageName captionText:(NSString *)captionText {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.0 relativeToView:self.view];
  CGFloat labelHpadding = [PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:26.0 iphone6PlusWidth:32.0 ipad:125.0 ipadPro12in:220.0];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
  UILabel *label = [PEUIUtils labelWithKey:captionText
                                      font:[UIFont boldSystemFontOfSize:[PEUIUtils valueIfiPhone5Width:20.0
                                                                                          iphone6Width:22.0
                                                                                      iphone6PlusWidth:26.0
                                                                                                  ipad:30.0
                                                                                           ipadPro12in:38.0]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor whiteColor]
                       verticalTextPadding:0.0
                                fitToWidth:contentPanel.frame.size.width - (labelHpadding * 2)];
  
  // place views
  CGFloat totalHeight = 0.0;
  CGFloat vpadding = 0.0;
  [PEUIUtils placeView:imageView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += imageView.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:26.0 iphone6PlusWidth:32.0 ipad:38.0 ipadPro12in:54.0];
  [PEUIUtils placeView:label below:imageView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:labelHpadding];
  totalHeight += label.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  //[PEUIUtils applyBorderToView:contentPanel withColor:[UIColor greenColor]];
  return contentPanel;
}

#pragma mark - Carousel View Makers

- (UIView *)rootCarouselView {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:0.0 relativeToView:self.view];
  UIView *dumbbellImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[PEUIUtils objIfiPhone5Width:@"gray-dumbbell-75"
                                                                                                 iphone6Width:@"gray-dumbbell-100"
                                                                                             iphone6PlusWidth:@"gray-dumbbell-100"
                                                                                                         ipad:@"gray-dumbbell-150"]]];
  UILabel *welcome = [PEUIUtils labelWithKey:@"Welcome to"
                                        font:[UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:28.0
                                                                                        iphone6Width:30.0
                                                                                    iphone6PlusWidth:38.0
                                                                                                ipad:44.0
                                                                                         ipadPro12in:52.0]]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0];
  UIView *appName = [PEUIUtils labelWithKey:@"Riker"
                                       font:[UIFont rikerTitleFont]
                            backgroundColor:[UIColor clearColor]
                                  textColor:[UIColor whiteColor]
                        verticalTextPadding:0.0];
  NSString *catchPhrase = @"Track your strength.";
  UILabel *message = [PEUIUtils labelWithKey:catchPhrase
                                        font:[UIFont boldSystemFontOfSize:[PEUIUtils valueIfiPhone5Width:22.0
                                                                                            iphone6Width:24.0
                                                                                        iphone6PlusWidth:26.0
                                                                                                    ipad:30.0
                                                                                             ipadPro12in:38.0]]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                         verticalTextPadding:0.0
                                  fitToWidth:(0.75 * panel.frame.size.width)];
  [message setTextAlignment:NSTextAlignmentCenter];
  [panel setBackgroundColor:[UIColor clearColor]];
  CGFloat totalHeight = 0.0;
  CGFloat vpadding = 0.0;
  [PEUIUtils placeView:dumbbellImage atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += dumbbellImage.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:25.0 iphone6PlusWidth:27.0 ipad:30.0 ipadPro12in:34.0];
  [PEUIUtils placeView:welcome below:dumbbellImage onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += welcome.frame.size.height + vpadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:10.0 iphone6Width:10.0 iphone6PlusWidth:12.0 ipad:14.0 ipadPro12in:20.0];
  [PEUIUtils placeView:appName below:welcome onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += appName.frame.size.height + vpadding;
  [PEUIUtils placeView:message below:appName onto:panel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += message.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:panel];
  //[PEUIUtils applyBorderToView:panel withColor:[UIColor yellowColor]];
  return panel;
}

- (UIView *)enterRepsCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-enter-reps-250"
                                                         iphone6Width:@"carousel-enter-reps-250"
                                                     iphone6PlusWidth:@"carousel-enter-reps-310"
                                                                 ipad:@"carousel-enter-reps-350"
                                                          ipadPro12in:@"carousel-enter-reps-500"]
                             captionText:@"Record your sets."];
}

- (UIView *)enterRepsWatchCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-enter-reps-watch-180"
                                                         iphone6Width:@"carousel-enter-reps-watch-180"
                                                     iphone6PlusWidth:@"carousel-enter-reps-watch-180"
                                                                 ipad:@"carousel-enter-reps-watch-270"
                                                          ipadPro12in:@"carousel-enter-reps-watch-360"]
                             captionText:@"From your Watch, too."];
}

- (UIView *)enterBmlCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-enter-bml-250"
                                                         iphone6Width:@"carousel-enter-bml-250"
                                                     iphone6PlusWidth:@"carousel-enter-bml-310"
                                                                 ipad:@"carousel-enter-bml-350"
                                                          ipadPro12in:@"carousel-enter-bml-500"]
                             captionText:@"Track that your body is heading in the right direction."];
}

- (UIView *)enterBmlWatchCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-enter-bml-watch-180"
                                                         iphone6Width:@"carousel-enter-bml-watch-180"
                                                     iphone6PlusWidth:@"carousel-enter-bml-watch-180"
                                                                 ipad:@"carousel-enter-bml-watch-270"
                                                          ipadPro12in:@"carousel-enter-bml-watch-360"]
                             captionText:@"From there too."];
}

- (UIView *)plentyOfChartsLineCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-charts-line-250"
                                                         iphone6Width:@"carousel-charts-line-250"
                                                     iphone6PlusWidth:@"carousel-charts-line-310"
                                                                 ipad:@"carousel-charts-line-350"
                                                          ipadPro12in:@"carousel-charts-line-500"]
                             captionText:@"Plenty of charts to visualize your progress over time."];
}

- (UIView *)plentyOfChartsPieCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-charts-pie-250"
                                                         iphone6Width:@"carousel-charts-pie-250"
                                                     iphone6PlusWidth:@"carousel-charts-pie-310"
                                                                 ipad:@"carousel-charts-pie-350"
                                                          ipadPro12in:@"carousel-charts-pie-500"]
                             captionText:@"Pie charts too."];
}

- (UIView *)exportCarouselView {
  return [self carouselViewWithImageName:[PEUIUtils objIfiPhone5Width:@"carousel-export-250"
                                                         iphone6Width:@"carousel-export-250"
                                                     iphone6PlusWidth:@"carousel-export-310"
                                                                 ipad:@"carousel-export-350"
                                                          ipadPro12in:@"carousel-export-500"]
                             captionText:@"It's your data.  Export it to CSV."];
}

#pragma mark - iCarousel Data Source

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
  return _carouselViewMakers.count;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(nullable UIView *)view {
  UIView *(^viewMaker)(void) = _carouselViewMakers[index];
  return viewMaker();
}

#pragma mark - iCarousel Delegate

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
  _carouselIndex = carousel.currentItemIndex;
  [self refreshDotsPanelWithCarousel:carousel contentPanel:carousel.superview vpadding:[self dotsPanelVpadding]];
}

#pragma mark - Helpers

- (UIView *)newWhiteDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:[PEUIUtils objIfiPhone5Width:@"white-dot-6"
                                                                                iphone6Width:@"white-dot-6"
                                                                            iphone6PlusWidth:@"white-dot-6"
                                                                                        ipad:@"white-dot-12"]]];
}

- (UIView *)newGrayDot {
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:[PEUIUtils objIfiPhone5Width:@"gray-dot-6"
                                                                                iphone6Width:@"gray-dot-6"
                                                                            iphone6PlusWidth:@"gray-dot-6"
                                                                                        ipad:@"gray-dot-12"]]];
}

- (CGFloat)dotsPanelVpadding {
  return [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:28.0 ipadPro12in:38.0];
}

- (void)refreshDotsPanelWithCarousel:(iCarousel *)carousel
                        contentPanel:(UIView *)contentPanel
                            vpadding:(CGFloat)vpadding {
  if (_dotsPanel) {
    [_dotsPanel removeFromSuperview];
  }
  NSMutableArray *dotImageViews = [NSMutableArray array];
  NSInteger currentWhiteDotIndex = carousel.currentItemIndex;
  for (int i = 0; i < _numCarouselViewMakers; i++) {
    if (i == currentWhiteDotIndex) {
      [dotImageViews addObject:[self newWhiteDot]];
    } else {
      [dotImageViews addObject:[self newGrayDot]];
    }
  }
  _dotsPanel = [PEUIUtils panelWithViews:dotImageViews
                                 ofWidth:1.0
                    vertAlignmentOfViews:PEUIVerticalAlignmentTypeMiddle
                     horAlignmentOfViews:PEUIHorizontalAlignmentTypeCenter
                              relativeTo:self.view
                                vpadding:0.0
                                hpadding:[PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:7.0 iphone6PlusWidth:10.0 ipad:15.0 ipadPro12in:20.0]];
  //[PEUIUtils applyBorderToView:carousel withColor:[UIColor yellowColor]];
  //[PEUIUtils applyBorderToView:_dotsPanel withColor:[UIColor greenColor]];
  [PEUIUtils placeView:_dotsPanel
                 below:carousel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  iCarousel *carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  [carousel setDataSource:self];
  [carousel setDelegate:self];
  [carousel setCurrentItemIndex:_carouselIndex];
  [PEUIUtils setFrameWidthOfView:carousel ofWidth:1.0 relativeTo:contentPanel];
  if ([PEUIUtils isPortraitMode] || [PEUIUtils isIpad]) {
    [PEUIUtils setFrameHeightOfView:carousel
                           ofHeight:[PEUIUtils valueIfiPhone5Width:0.65
                                                      iphone6Width:0.65
                                                  iphone6PlusWidth:0.65
                                                              ipad:0.65
                                                       ipadPro12in:0.65]
                         relativeTo:self.view];
  } else {
    [PEUIUtils setFrameHeightOfView:carousel
                           ofHeight:[PEUIUtils valueIfiPhone5Width:1.1
                                                      iphone6Width:1.1
                                                  iphone6PlusWidth:1.1
                                                              ipad:1.1
                                                       ipadPro12in:1.1]
                         relativeTo:self.view];
  }
  [carousel setPagingEnabled:YES];
  [carousel setBounceDistance:0.25];
  [carousel setTag:1];
  _isCarouselRemoved = NO;
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:25.0
                                       iphone6Width:25.0
                                   iphone6PlusWidth:25.0
                                               ipad:100.0
                                        ipadPro12in:120.0];
  [PEUIUtils placeView:carousel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  CGFloat totalHeight = carousel.frame.size.height + vpadding;
  vpadding = [self dotsPanelVpadding];
  [self refreshDotsPanelWithCarousel:carousel contentPanel:contentPanel vpadding:vpadding];
  totalHeight += _dotsPanel.frame.size.height + vpadding;
  UIButton *(^button)(NSString *, id, SEL) = ^UIButton *(NSString *title, id target, SEL sel) {
    UIButton *btn = [PEUIUtils buttonWithKey:title
                                        font:[UIFont boldSystemFontOfSize:[PEUIUtils valueIfiPhone5Width:30.0
                                                                                            iphone6Width:32.0
                                                                                        iphone6PlusWidth:34.0
                                                                                                    ipad:36.0
                                                                                             ipadPro12in:44.0]]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor whiteColor]
                disabledStateBackgroundColor:nil
                      disabledStateTextColor:nil
                             verticalPadding:[PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:20.0 iphone6PlusWidth:30.0 ipad:45.0]
                           horizontalPadding:0.0
                                cornerRadius:7.0
                                      target:target
                                      action:sel];
    [PEUIUtils setFrameWidthOfView:btn ofWidth:0.85 relativeTo:contentPanel];
    [btn setBackgroundImage:[UIImage imageNamed:@"riker-black-1-pixel"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"gray-1-pixel"] forState:UIControlStateHighlighted];
    [PEUIUtils applyBorderToView:btn withColor:[UIColor whiteColor] width:[PEUIUtils valueIfiPhone5Width:1.25
                                                                                            iphone6Width:1.35
                                                                                        iphone6PlusWidth:1.5
                                                                                                    ipad:1.75
                                                                                             ipadPro12in:2.5]];
    return btn;
  };
  NSString *goButtonTitle = @"Go";
  UIButton *startUsing = button(goButtonTitle, self, @selector(startUsing));
  [PEUIUtils addDisclosureIndicatorToButton:startUsing];
  vpadding = [PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:27.0 iphone6PlusWidth:29.0 ipad:35.0 ipadPro12in:47.0];
  [PEUIUtils placeView:startUsing
                 below:_dotsPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += startUsing.frame.size.height + vpadding;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(NO), @(YES)];
}

#pragma mark - Dismiss

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view setBackgroundColor:[UIColor rikerAppBlack]];
  [[self.navigationController navigationBar] setHidden:!_againMode];
  if (_againMode) {
    UINavigationItem *navItem = [self navigationItem];
    UIBarButtonItem *dismissBtn =
    [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [navItem setLeftBarButtonItem:dismissBtn];
  }
  _carouselIndex = 0;
}

- (void)startUsing {
  if (_againMode) {
    [self dismiss];
  } else {
    [APP setExperiencedSplashScreenAt:[NSDate date]];
    UITabBarController *tabBarController =
    (UITabBarController *)[_screenToolkit newTabBarHomeLandingScreenMakerIsLoggedIn:NO]();
    PELMUser *user = [_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    [APP setUser:user tabBarController:tabBarController];
    [[self navigationController] pushViewController:tabBarController animated:YES];
  }
}

@end
