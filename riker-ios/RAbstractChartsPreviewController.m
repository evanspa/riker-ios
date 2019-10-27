//
//  RAbstractChartsPreviewController.m
//  Riker
//
//  Created by PEVANS on 10/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RAbstractChartsPreviewController.h"
@import Firebase;
#import <QuartzCore/QuartzCore.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import <DateTools/DateTools.h>
#import <SVPullToRefresh/UIScrollView+SVPullToRefresh.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "RLocalDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "PELMUser.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RLogging.h"
#import "RUIUtils.h"
#import "PEUtils.h"
#import "PELocalDao.h"
#import "RPanelToolkit.h"
#import "RAppNotificationNames.h"
#import "RSelectScreen.h"
#import "RBodySegment.h"
#import "RPanelToolkit.h"
#import "RUserSettings.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"
#import "RMovement.h"
#import "RMuscleGroup.h"
#import "RMuscle.h"
#import "RMovementVariant.h"
#import "NSString+RAdditions.h"
#import "RUtils.h"
#import "RChartStrengthRawData.h"
#import "RDateValueFormatter.h"
#import "RNumberValueFormatter.h"
#import "RPercentageFormatter.h"
#import "RChartConfig.h"
#import "RChartFilterScreen.h"
#import "RNormalizedTimeSeriesTupleCollection.h"
#import "RNormalizedLineChartDataEntry.h"
#import "RChartBodyRawData.h"
#import "RChartsListController.h"
#import "RWatchUtils.h"
@import StoreKit;
#import "RChartAndLoaderTuple.h"
#import "PEUtils.h"
#import "RChartIdPrefixes.h"

@implementation RAbstractChartsPreviewController {
  id<RCoordinatorDao> _coordDao;
  NSInteger _numSets;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                   screenTitle:(NSString *)screenTitle
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache {
  self = [super initWithStoreCoordinator:coordDao
                         userSettingsBlk:userSettingsBlk
                               uitoolkit:uitoolkit
                           screenToolkit:screenToolkit
                            panelToolkit:panelToolkit
                             screenTitle:screenTitle
                                    user:user
                 entitiesAndRawDataCache:entitiesAndRawDataCache];
  if (self) {
    _coordDao = coordDao;
    _userSettingsBlk = userSettingsBlk;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _isRepaintDueToNonDataChange = NO;
    _movementSearchResults = [NSMutableArray array];
    self.calcPercentages = YES;
    self.calcAverages = YES;
  }
  return self;
}

#pragma mark - Chart Loading

- (RChartDataFetchMode)fetchMode {
  // override in subclasses
  return 0;
}

#pragma mark - Your Strength Content

- (UIView *)yourContentRelativeToView:(UIView *)relativeToView {
  // to be overridden in sub-classes
  return nil;
}

#pragma mark - Movement Search Results - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [RUIUtils heightForMovementSearchResultsHeader];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return [RUIUtils heightForMovementSearchResultsFooter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  RMovementSearchResult *searchResult = _movementSearchResults[indexPath.row];
  return [RUIUtils heightForCellForSearchResult:searchResult
                                 availableWidth:self.view.frame.size.width * [PEUIUtils widthOfForContent]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return [RUIUtils viewForMovementSearchResultsHeaderWithTableView:tableView movementSearchResults:_movementSearchResults controller:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [RUIUtils didSelectMovementSearchResultRowWithResults:_movementSearchResults
                                              indexPath:indexPath
                                          screenToolkit:_screenToolkit
                                              uitoolkit:_uitoolkit
                                               coordDao:_coordDao
                                      nextScreenAsModal:YES
                                             controller:self];
}

#pragma mark - Movement Search Results - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  return _movementSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [RUIUtils movementSearchResultCellForIndexPath:indexPath
                                              tableView:tableView
                                  movementSearchResults:_movementSearchResults
                                         availableWidth:self.view.frame.size.width * [PEUIUtils widthOfForContent]];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [RUIUtils searchBarTextDidBeginEditing:searchBar
                   movementSearchResults:_movementSearchResults
                       tableViewDelegate:self
                     tableViewDataSource:self
                              controller:self];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  [RUIUtils movementSearchBarTextDidChangeWithSearchBar:searchBar
                                             searchText:searchText
                                  movementSearchResults:_movementSearchResults
                                               coordDao:_coordDao
                                             controller:self];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent]
                                      relativeToView:self.view
                                         fixedHeight:0.0];
  // because none of the charts we display on the home page feature individual
  // muscles, we don't need to load the muscles and muscle colors (although
  // we do on the charts list screen)
  [self configureColors];
  // make views
  UIView *subContentPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
  CGFloat totalHeightSubContent = 0.0;
  UIView *mainContentPanel = nil;
  if (_isRepaintDueToNonDataChange) {
    // only skip main panel re-gen if this repaint was due to user changing the
    // status of the segmented control, or some other non-data change, such
    // as displaying offline mode banner or maintenance banner (and of course the
    // panels are not currently null)
    if (_yourContentPanel == nil) {
      _yourContentPanel = [self yourContentRelativeToView:contentPanel];
    }
  } else {
    _yourContentPanel = [self yourContentRelativeToView:contentPanel];
  }
  mainContentPanel = _yourContentPanel;
  CGFloat vpadding;
  // place movements search bar
  [subContentPanel setTag:RCONTENT_PANEL_TAG];
  UISearchBar *movementSearchBar = [RUIUtils movementSearchBarWithDelegate:self relativeToView:subContentPanel];
  vpadding = -2.0;
  [PEUIUtils placeView:movementSearchBar atTopOf:subContentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeightSubContent += movementSearchBar.frame.size.height + vpadding;
  // place views
  vpadding = [PEUIUtils valueIfiPhone5Width:0.0 iphone6Width:0.0 iphone6PlusWidth:0.0 ipad:3.0];
  [PEUIUtils placeView:mainContentPanel
                 below:movementSearchBar
                  onto:subContentPanel
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:vpadding
              hpadding:0.0];
  totalHeightSubContent += mainContentPanel.frame.size.height + vpadding;
  // set height and place sub-content panel
  [PEUIUtils setFrameHeight:totalHeightSubContent ofView:subContentPanel];
  CGFloat topViewVpadding;
  CGFloat (^adjustForOfflineMode)(UIView *, CGFloat) = ^CGFloat (UIView *view, CGFloat addlAdjust) {
    UIView *offlineLabel = [PEUIUtils offlineModeLabelWithController:self];
    if (offlineLabel) {
      _adjustedViewsForOfflineMode = YES;
      CGFloat adjustment = offlineLabel.frame.size.height + addlAdjust;
      [PEUIUtils adjustYOfView:view withValue:adjustment];
      return adjustment;
    }
    return 0.0;
  };
  if ([user isInMaintenanceWindow]) {
    UIView *topView = [RPanelToolkit maintenanceInProgressNavbarPanelForUser:user relativeToView:contentPanel controller:self];
    topViewVpadding = 0.0;
    _maintenanceNoticeAdded = YES;
    _unAckdUpcomingMaintenanceNoticeAdded = NO;
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:topView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(topView, 0.0);
    totalHeight += topView.frame.size.height + topViewVpadding;
    [PEUIUtils placeView:subContentPanel below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
    totalHeight += subContentPanel.frame.size.height + 0.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  } else if ([user hasUnAckdUpcomingMaintenanceWithLastMaintenanceAckAt:[APP maintenanceAckAt]]) {
    UIView *topView = [RPanelToolkit upcomingMaintenanceNavbarPanelForUser:user
                                                            relativeToView:contentPanel
                                                                controller:self
                                                       navBannerRemovedBlk:^(CGFloat bannerPanelHeight) {
                                                         [UIView animateWithDuration:0.25
                                                                               delay:0.00
                                                                             options:UIViewAnimationOptionCurveEaseInOut
                                                                          animations:^{
                                                                            [PEUIUtils adjustYOfView:subContentPanel withValue:(-1 * bannerPanelHeight)];
                                                                          }
                                                                          completion:nil];
                                                         _unAckdUpcomingMaintenanceNoticeAdded = NO;
                                                       }];
    _maintenanceNoticeAdded = NO;
    _unAckdUpcomingMaintenanceNoticeAdded = YES;
    topViewVpadding = 0.0;
    CGFloat totalHeight = 0.0;
    [PEUIUtils placeView:topView atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(topView, 0.0);
    totalHeight += topView.frame.size.height + topViewVpadding;
    [PEUIUtils placeView:subContentPanel below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
    totalHeight += subContentPanel.frame.size.height + 0.0;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  } else {
    _maintenanceNoticeAdded = NO;
    _unAckdUpcomingMaintenanceNoticeAdded = NO;
    CGFloat totalHeight = 0.0;
    topViewVpadding = 2.5;
    [PEUIUtils placeView:subContentPanel atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:topViewVpadding hpadding:0.0];
    totalHeight += adjustForOfflineMode(subContentPanel, -1.0);
    totalHeight += subContentPanel.frame.size.height + topViewVpadding;
    [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  }
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Notification handlers

- (void)indicateChartHardForcedReloadNeeded:(NSNotification *)notification {
  [super indicateChartHardForcedReloadNeeded:notification];
}

#pragma mark - Device Rotation

- (void)willRepaintDueToRotate {
  [super willRepaintDueToRotate];
  _yourContentPanel = nil;
}

#pragma mark - Chart Settings Notification Handling

- (void)chartSettingsClearedNotification:(NSNotification *)notification {
  [super chartSettingsClearedNotification:notification];
  NSDictionary *userInfo = notification.userInfo;
  RChartConfigCategory chartConfigCategory = ((NSNumber *)userInfo[@"chartCategory"]).integerValue;
  if (chartConfigCategory == [self chartConfigCategory]) {
    [self.coordDao deleteChartConfigByChartId:userInfo[@"chartId"] user:self.user error:[RUtils localSaveErrorHandlerMaker]()];
  }
}

- (void)chartSettingsDoneNotification:(NSNotification *)notification {
  NSDictionary *userInfo = notification.userInfo;
  RChartConfigCategory chartConfigCategory = ((NSNumber *)userInfo[@"chartCategory"]).integerValue;
  if (chartConfigCategory == [self chartConfigCategory]) {
    NSString *chartId = userInfo[@"chartId"];
    [self.coordDao saveNewOrExistingByChartIdChartConfig:userInfo[@"chartConfig"] forUser:self.user error:[RUtils localSaveErrorHandlerMaker]()];
    [self chartSettingsDidChangeForChartId:chartId];
  }
}

#pragma mark - Chart Config Helpers

- (void)chartSettingsDidChangeForChartId:(NSString *)chartId {
  RChartAndLoaderTuple *chartAndLoaderTuple = _chartAndLoaderTuples[chartId];
  if (chartAndLoaderTuple) { // is strength chart (because it's not null)
    [self settingsDidChangeForChartAndLoaderTuple:chartAndLoaderTuple fetchMode:[self fetchMode]];
  }
}

#pragma mark - Chart Loading

- (void)loadChartsWithCompletion:(void(^)(void))completion
       showAlertIfAlreadyLoading:(BOOL)showAlertIfAlreadyLoading
                        headless:(BOOL)headless
                 calcPercentages:(BOOL)calcPercentages
                    calcAverages:(BOOL)calcAverages {
  // to be overridden in sub-classes
}

#pragma mark - Scroll Helpers

- (void)configureJumpToButton:(UIButton *)jumpToButton
                 contentPanel:(UIView *)contentPanel
                 headingPanel:(UIView *)headingPanel {
  [jumpToButton bk_addEventHandler:^(id sender) {
    CGFloat finalScrollToY = headingPanel.frame.origin.y + contentPanel.frame.origin.y;
    [UIScrollView animateWithDuration:0.3
                           animations:^(void) { [((UIScrollView *)self.displayPanel) setContentOffset:CGPointMake(0.0, finalScrollToY - [PEUIUtils valueIfiPhoneXSMaxOrXrInPortrait:24.0 other:0.0])]; }
                           completion:nil];
  } forControlEvents:UIControlEventTouchUpInside];
}

- (void)scrollToTop {
  [UIScrollView animateWithDuration:0.3
                         animations:^(void) {
                           [((UIScrollView *)self.displayPanel) setContentOffset:CGPointMake(0.0, 0.0 - [PEUIUtils valueIfiPhoneXSMaxOrXrInPortrait:24.0 other:0.0])];
                         }
                         completion:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  UIBarButtonItem *goUpButton =
  [[UIBarButtonItem alloc] initWithTitle:@"Up" style:UIBarButtonItemStylePlain target:self action:@selector(scrollToTop)];
  [navItem setRightBarButtonItem:goUpButton];
}

- (void)viewDidAppear:(BOOL)animated {
  void (^triggerRepaint)(void) = ^{
    _isRepaintDueToNonDataChange = YES;
    self.needsRepaint = YES;
    [APP refreshTabs];
  };
  if ([APP offlineMode]) { // because we don't want the search bar to be covered by the offline mode bar
    if (!_adjustedViewsForOfflineMode) {
      triggerRepaint();
    }
  } else { // offline mode was turned off
    if (_adjustedViewsForOfflineMode) {
      triggerRepaint();
      _adjustedViewsForOfflineMode = NO;
    }
  }
  [super viewDidAppear:animated];
  [RUIUtils movementSearchBarViewDidLoadHandlerWithController:self
                                        movementSearchResults:_movementSearchResults];
}

@end
