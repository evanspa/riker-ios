//
//  RSelectScreen.m
//  riker-ios
//
//  Created by PEVANS on 2/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSelectScreen.h"
#import "RAppNotificationNames.h"
#import "RScreenToolkit.h"
#import "PEUIToolkit.h"
#import "AppDelegate.h"
#import "PEUtils.h"
#import "RCoordinatorDao.h"
#import "PELocalDao.h"
#import "RUtils.h"
#import "RBodySegment.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"
#import "RUIUtils.h"
@import Firebase;
#import "RMovementSearchResultCell.h"
#import "RMovementSearchResult.h"
#import "RMovement.h"
#import "RMovementVariant.h"

@implementation RSelectScreen {
  PEUIToolkit *_uitoolkit;
  NSString *_title;
  NSArray *(^_itemsFetcher)(void);
  NSString *(^_titleForSelectButtons)(id);
  void(^_actionOnSelect)(UIViewController *, id);
  BOOL _cancellable;
  NSArray *_breadcrumbs;
  UIColor *_colorForLastButton;
  BOOL _isMovementSelection;
  NSMutableArray *_movementSearchResults;
  id<RCoordinatorDao> _coordDao;
  PELMDaoErrorBlk _errorBlk;
  RScreenToolkit *_screenToolkit;
  CGFloat _movementSearchBarVPadding;
}

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit
               coordDao:(id<RCoordinatorDao>)coordDao
          screenToolkit:(RScreenToolkit *)screenToolkit
                  title:(NSString *)title
            breadcrumbs:(NSArray *)breadcrumbs
           itemsFetcher:(NSArray *(^)(void))itemsFetcher
  titleForSelectButtons:(NSString *(^)(id))titleForSelectButtons
         actionOnSelect:(void(^)(UIViewController *, id))actionOnSelect
            cancellable:(BOOL)cancellable
     colorForLastButton:(UIColor *)colorForLastButton
    isMovementSelection:(BOOL)isMovementSelection
movementSearchBarVPadding:(CGFloat)movementSearchBarVPadding {
  self = [super initWithRequireRepaintNotifications:@[RChangelogDownloadedNotification]
                                        screenTitle:title];
  if (self) {
    _uitoolkit = uitoolkit;
    _title = title;
    _breadcrumbs = breadcrumbs;
    _itemsFetcher = itemsFetcher;
    _titleForSelectButtons = titleForSelectButtons;
    _actionOnSelect = actionOnSelect;
    _cancellable = cancellable;
    _colorForLastButton = colorForLastButton;
    _isMovementSelection = isMovementSelection;
    _movementSearchResults = [NSMutableArray array];
    _coordDao = coordDao;
    _screenToolkit = screenToolkit;
    _movementSearchBarVPadding = movementSearchBarVPadding;
  }
  return self;
}

#pragma mark - Cancel

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  if (_cancellable) {
    UINavigationItem *navItem = [self navigationItem];
    [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel)]];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [RUIUtils movementSearchBarViewDidLoadHandlerWithController:self
                                        movementSearchResults:_movementSearchResults];
}

#pragma mark - Helpers

- (UIView *)makeSeparatorRelativeToView:(UIView *)relativeToView {
  UIView *separator = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:2.0];
  [separator setBackgroundColor:[UIColor colorWithRed:(0xE2 / 255.0)
                                                green:(0xE6 / 255.0)
                                                 blue:(0xE7 / 255.0)
                                                alpha:1.0]];
  return separator;
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
                                      nextScreenAsModal:NO
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
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  [contentPanel setTag:RCONTENT_PANEL_TAG];
  // create views
  NSArray *items = _itemsFetcher();
  NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:items.count];
  NSInteger itemCount = items.count;
  UIFont *buttonFont = [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:38.0]
                                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                                                                          iphone6Width:UIFontTextStyleSubheadline
                                                                                                                      iphone6PlusWidth:UIFontTextStyleBody
                                                                                                                                  ipad:UIFontTextStyleTitle3]]];
  CGFloat buttonVPadding = [PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:26.0 iphone6PlusWidth:30.0 ipad:38.0];
  UIColor *buttonTextColor = [UIColor whiteColor];
  for (NSInteger i = 0; i < itemCount; i++) {
    id item = items[i];
    UIColor *buttonColor = [UIColor bootstrapPrimary];
    if (_colorForLastButton != nil && (i + 1 == itemCount)) {
      buttonColor = _colorForLastButton;
    }
    UIButton *button = [PEUIUtils buttonWithKey:_titleForSelectButtons(item)
                                           font:buttonFont
                                backgroundColor:buttonColor
                                      textColor:buttonTextColor
                   disabledStateBackgroundColor:nil
                         disabledStateTextColor:nil
                                verticalPadding:buttonVPadding
                              horizontalPadding:0.0
                                   cornerRadius:3.0
                                         target:nil
                                         action:nil];
    [button bk_addEventHandler:^(id sender) {
      _actionOnSelect(self, item);
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils setFrameWidthOfView:button ofWidth:0.75 relativeTo:contentPanel];
    [buttons addObject:button];
  }
  CGFloat (^adjustForOfflineMode)(UIView *, CGFloat) = ^CGFloat (UIView *view, CGFloat addlAdjust) {
    UIView *offlineLabel = [PEUIUtils offlineModeLabelWithController:self];
    if (offlineLabel) {
      CGFloat adjustment = offlineLabel.frame.size.height + addlAdjust;
      [PEUIUtils adjustYOfView:view withValue:adjustment];
      return adjustment;
    }
    return 0.0;
  };
  UIView *buttonsPanel = [PEUIUtils panelWithColumnOfViews:buttons verticalPaddingBetweenViews:15.0 viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
  CGFloat totalHeight = 0.0;
  UISearchBar *movementSearchBar = [RUIUtils movementSearchBarWithDelegate:self relativeToView:contentPanel];
  CGFloat vpadding = _movementSearchBarVPadding;
  [PEUIUtils placeView:movementSearchBar atTopOf:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:vpadding hpadding:0.0];
  totalHeight += adjustForOfflineMode(movementSearchBar, 0.0);
  totalHeight += movementSearchBar.frame.size.height + vpadding;
  UILabel *headingLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"  %@  ", _title]
                                             font:[PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:38.0 iphone6Width:40.0 iphone6PlusWidth:40.0 ipad:48.0]
                                                                                        font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                                                                                                       iphone6Width:UIFontTextStyleSubheadline
                                                                                                                                                   iphone6PlusWidth:UIFontTextStyleBody
                                                                                                                                                               ipad:UIFontTextStyleTitle3]]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:12.0
                                       fitToWidth:contentPanel.frame.size.width - 38.0 - (iphoneXSafeInsetsSideVal * 2)];
  UIView *headingPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:headingLabel.frame.size.height * 1.25];
  [PEUIUtils adjustWidthOfView:headingPanel withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [headingPanel setBackgroundColor:[UIColor whiteColor]];
  headingPanel.layer.cornerRadius = 3.0;
  [PEUIUtils placeView:headingLabel inMiddleOf:headingPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0];
  CGFloat headingPanelHpadding = 15.0 + iphoneXSafeInsetsSideVal;
  vpadding = [PEUIUtils valueIfiPhone5Width:8.0 iphone6Width:10.0 iphone6PlusWidth:12.0 ipad:18.0];
  [PEUIUtils placeView:headingPanel below:movementSearchBar onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:headingPanelHpadding];
  totalHeight += headingPanel.frame.size.height + vpadding;
  CGFloat brickPadding = [PEUIUtils valueIfiPhone5Width:1.5 iphone6Width:2.0 iphone6PlusWidth:3.0 ipad:5.0];
  UIView *breadcrumbsPanel =
  [PEUIUtils panelOfBrickLayedViewsFromItems:_breadcrumbs
                                   viewMaker:^UIView * (NSInteger i, NSString *breadcrumb) {
                                     UILabel *label =
                                     [PEUIUtils labelWithKey:[NSString stringWithFormat:@"  %@  ", [breadcrumb lowercaseString]]
                                                        font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:32.0 ipad:36.0]
                                                                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                                                                                                                                                iphone6Width:UIFontTextStyleCaption1
                                                                                                                                                            iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                                                                        ipad:UIFontTextStyleBody]]]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor whiteColor]
                                         verticalTextPadding:8.0];
                                     UIView *labelPanel = [PEUIUtils panelWithWidthOf:1.25 andHeightOf:1.10 relativeToView:label];
                                     [labelPanel setBackgroundColor:[UIColor bootstrapPrimarySemiClear]];
                                     labelPanel.layer.cornerRadius = 3.0;
                                     [PEUIUtils placeView:label inMiddleOf:labelPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
                                     return labelPanel;
                                   }
                                   extraView:nil
                              availableWidth:contentPanel.frame.size.width - (headingPanelHpadding * 2.0)
                                    hpadding:brickPadding
                                    vpadding:brickPadding];
  UIView *separator = [self makeSeparatorRelativeToView:contentPanel];
  UIView *movementNotFoundPanel = nil;
  if (_isMovementSelection) {
    movementNotFoundPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:0.0];
    CGFloat leftHpadding = 8.0;
    UILabel *cantFindMovementLabel = [PEUIUtils labelWithAttributeText:AS(@"Can't find your movement?  Drop us a line and we'll get it added:")
                                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                       backgroundColor:[UIColor clearColor]
                                                             textColor:[UIColor darkGrayColor]
                                                   verticalTextPadding:3.0
                                                            fitToWidth:(movementNotFoundPanel.frame.size.width - leftHpadding - 10.0)];
    UIButton *rikerSupportEmailLabel = [PEUIUtils buttonWithKey:[APP rikerSupportEmail]
                                                           font:[RUIUtils rikerSupportEmailFont]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor bootstrapPrimary]
                                   disabledStateBackgroundColor:[UIColor clearColor]
                                         disabledStateTextColor:[UIColor clearColor]
                                                verticalPadding:3.0
                                              horizontalPadding:0.0
                                                   cornerRadius:0.0
                                                         target:nil
                                                         action:nil];
    [rikerSupportEmailLabel bk_addEventHandler:^(id sender) {
      [RUtils contactRikerSupport];
    } forControlEvents:UIControlEventTouchUpInside];
    CGFloat movementNotFoundPanelHeight = 0.0;
    [PEUIUtils placeView:cantFindMovementLabel atTopOf:movementNotFoundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:leftHpadding];
    movementNotFoundPanelHeight += cantFindMovementLabel.frame.size.height;
    [PEUIUtils placeView:rikerSupportEmailLabel below:cantFindMovementLabel onto:movementNotFoundPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
    movementNotFoundPanelHeight += rikerSupportEmailLabel.frame.size.height + 4.0;
    [PEUIUtils setFrameHeight:movementNotFoundPanelHeight ofView:movementNotFoundPanel];
  }
  
  // place views
  [PEUIUtils placeView:breadcrumbsPanel below:headingPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:1.5 hpadding:0.0];
  totalHeight += breadcrumbsPanel.frame.size.height + brickPadding;
  vpadding = [PEUIUtils valueIfiPhone5Width:12.0 iphone6Width:15.0 iphone6PlusWidth:20.0 ipad:25.0];
  [PEUIUtils placeView:separator below:breadcrumbsPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += separator.frame.size.height + vpadding;
  [PEUIUtils placeView:buttonsPanel below:separator onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
  totalHeight += buttonsPanel.frame.size.height + vpadding;
  if (movementNotFoundPanel) {
    vpadding = 50.0;
    separator = [self makeSeparatorRelativeToView:contentPanel];
    [PEUIUtils placeView:separator below:buttonsPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
    totalHeight += separator.frame.size.height + vpadding;
    vpadding = [PEUIUtils valueIfiPhone5Width:12.0 iphone6Width:15.0 iphone6PlusWidth:20.0 ipad:25.0];
    [PEUIUtils placeView:movementNotFoundPanel below:separator onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeCenter alignmentRelativeToView:contentPanel vpadding:vpadding hpadding:0.0];
    totalHeight += movementNotFoundPanel.frame.size.height + vpadding;
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO), @(YES)];
}

@end
