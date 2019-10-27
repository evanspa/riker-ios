//
//  RUIUtils.m
//  riker-ios
//
//  Created by PEVANS on 10/26/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RUIUtils.h"
#import "RCoordinatorDao.h"
#import "PELocalDao.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "AppDelegate.h"
#import "ROriginationDevice.h"
#import "PEUIUtils.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"
#import "RMovementSearchResult.h"
#import "PEBaseController.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import "RMovement.h"
#import "RMovementVariant.h"
#import "RScreenToolkit.h"
#import "RSelectScreen.h"
#import "RMovementSearchResultCell.h"
@import Firebase;

NSInteger const RMOVEMENT_SEARCHBAR_TAG = 943;
NSInteger const RDIMMER_VIEW_TAG = 955;
NSInteger const RCONTENT_PANEL_TAG = 944;
NSInteger const RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG = 956;
NSInteger const RHUD_TAG = 1715;

@implementation RUIUtils

#pragma mark - Movement Search Bar Helpers

+ (void)movementSearchBarViewDidLoadHandlerWithController:(PEBaseController *)controller
                                    movementSearchResults:(NSMutableArray *)movementSearchResults {
  UITableView *movementSearchResultsTableView = [controller.view viewWithTag:RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG];
  if (movementSearchResultsTableView) {
    NSIndexPath *indexPath = [movementSearchResultsTableView indexPathForSelectedRow];
    if (indexPath) {
      [movementSearchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
  } else {
    [movementSearchResults removeAllObjects];
  }
}

+ (void)movementSearchBarTextDidChangeWithSearchBar:(UISearchBar *)searchBar
                                         searchText:(NSString *)searchText
                              movementSearchResults:(NSMutableArray *)movementSearchResults
                                           coordDao:(id<RCoordinatorDao>)coordDao
                                         controller:(PEBaseController *)controller {
  UITableView *searchResultsTableView = [controller.view viewWithTag:RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG];
  [movementSearchResults removeAllObjects];
  if ([searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
    [RUtils logEvent:kFIREventSearch params:@{kFIRParameterSearchTerm : searchText }];    
    NSArray *searchResults = [coordDao movementsWithNameOrAliasLike:searchText error:[RUtils localFetchErrorHandlerMaker]()];
    [movementSearchResults addObjectsFromArray:searchResults];
    if (searchResults && searchResults.count > 0) {
      [RUtils logEvent:kFIREventViewSearchResults params:@{kFIRParameterSearchTerm : searchText }];
    }
  }
  [searchResultsTableView reloadData];
}

+ (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
               movementSearchResults:(NSMutableArray *)movementSearchResults
                   tableViewDelegate:(id<UITableViewDelegate>)tableViewDelegate
                 tableViewDataSource:(id<UITableViewDataSource>)tableViewDataSource
                          controller:(PEBaseController *)controller {
  UIView *contentPanel = [controller.view viewWithTag:RCONTENT_PANEL_TAG];
  UIView *dimmerView = [controller.view viewWithTag:RDIMMER_VIEW_TAG];
  if (!dimmerView) {
    dimmerView = [PEUIUtils panelWithWidthOf:1.0 andHeightOf:1.0 relativeToView:controller.view];
    [dimmerView setTag:RDIMMER_VIEW_TAG];
    [dimmerView setBackgroundColor:[UIColor blackColor]];
    [dimmerView setAlpha:0.6];
    [contentPanel addSubview:dimmerView];
    [contentPanel bringSubviewToFront:searchBar];
    UITableView *searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
    [searchResultsTableView registerClass:[RMovementSearchResultCell class] forCellReuseIdentifier:@"movementSearchResultCell"];
    searchResultsTableView.delegate = tableViewDelegate;
    searchResultsTableView.dataSource = tableViewDataSource;
    [PEUIUtils setFrameWidthOfView:searchResultsTableView ofWidth:1.0 relativeTo:contentPanel];
    [searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [searchResultsTableView setTag:RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG];
    [PEUIUtils placeView:searchResultsTableView below:searchBar onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
    [contentPanel bringSubviewToFront:searchResultsTableView];
    CGFloat tableViewTargetHeight = [PEUIUtils valueIfiPhone5Width:0.45
                                                      iphone6Width:0.50
                                                  iphone6PlusWidth:0.565
                                                              ipad:0.50] * controller.view.frame.size.height;
    [UIView animateWithDuration:0.3
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       [PEUIUtils setFrameHeight:tableViewTargetHeight ofView:searchResultsTableView];
                     }
                     completion:^(BOOL finish) {
                       //if ([[controller displayPanel] isKindOfClass:[UIScrollView class]]) {
                         //[((UIScrollView *)[controller displayPanel]) setScrollEnabled:NO];
                       //}
                       [dimmerView bk_whenTapped:^{
                         [RUIUtils cancelMovementSearchWithResults:movementSearchResults controller:controller];
                       }];
                     }];
  }
}

+ (UIView *)labelsPanelForMovementSearchResult:(RMovementSearchResult *)searchResult
                                availableWidth:(CGFloat)availableWidth {  
  UIFont *font = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:34.0]
                                                       font:[PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]]];
  UILabel *canonicalNameLabel = [PEUIUtils labelWithKey:searchResult.canonicalName
                                                   font:font
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor rikerAppBlack]
                                    verticalTextPadding:0.0
                                             fitToWidth:availableWidth - 16.0];
  UILabel *aliasesLabel;
  NSMutableArray *labelViews = [NSMutableArray array];
  [labelViews addObject:canonicalNameLabel];
  NSArray *aliases = searchResult.aliases;
  if (aliases.count > 0) {
    NSMutableAttributedString *aliasesString = [[NSMutableAttributedString alloc] initWithString:@"also known as: "];
    font = [PEUIUtils italicFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:24.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0]
                                                   font:[PEUIUtils italicFontForTextStyle:[PEUIUtils captionFontTextStyle]]];
    for (NSInteger i = 0; i < aliases.count; i++) {
      [aliasesString appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                                     textToAccent:aliases[i]
                                                                   accentTextFont:font]];
      if (i + 2 < aliases.count) {
        [aliasesString appendAttributedString:AS(@", ")];
      } else if (i + 1 < aliases.count) {
        [aliasesString appendAttributedString:AS(@" and ")];
      }
    }
    aliasesLabel = [PEUIUtils labelWithAttributeText:aliasesString
                                                font:font
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor rikerAppBlack]
                                 verticalTextPadding:0.0
                                          fitToWidth:availableWidth - 24.0];
    [labelViews addObject:aliasesLabel];
  }
  return [PEUIUtils panelWithColumnOfViews:labelViews verticalPaddingBetweenViews:4.0 viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UITableViewCell *)movementSearchResultCellForIndexPath:(NSIndexPath *)indexPath
                                                tableView:(UITableView *)tableView
                                    movementSearchResults:(NSMutableArray *)movementSearchResults
                                           availableWidth:(CGFloat)availableWidth {
  RMovementSearchResult *searchResult = movementSearchResults[indexPath.row];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"movementSearchResultCell"];
  UIView *contentView = cell.contentView;
  UIView *labelsPanel = [contentView viewWithTag:10];
  [labelsPanel removeFromSuperview];
  labelsPanel = [RUIUtils labelsPanelForMovementSearchResult:searchResult availableWidth:availableWidth];
  [labelsPanel setTag:10];
  //[PEUIUtils applyBorderToView:contentView withColor:[UIColor greenColor]];
  // for some reason, the height of contentView is not getting set "in time" for the 'placeView'
  // call to know how to place labelsPanel in the middle of it, so I need to delay it ever so
  // slightly (weird)
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.025 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [PEUIUtils placeView:labelsPanel inMiddleOf:contentView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0];
  });
  return cell;
}

+ (void)didSelectMovementSearchResultRowWithResults:(NSMutableArray *)movementSearchResults
                                          indexPath:(NSIndexPath *)indexPath
                                      screenToolkit:(RScreenToolkit *)screenToolkit
                                          uitoolkit:(PEUIToolkit *)uitoolkit
                                           coordDao:(id<RCoordinatorDao>)coordDao
                                  nextScreenAsModal:(BOOL)nextScreenAsModal
                                         controller:(PEBaseController *)controller {
  RMovementSearchResult *searchResult = movementSearchResults[indexPath.row];
  void(^launchEnterReps)(RMovementVariant *, BOOL, UIViewController *) = ^(RMovementVariant *variant, BOOL asModal, UIViewController *parentController) {
    RMovement *movement = [[RMovement alloc] init];
    movement.localMasterIdentifier = searchResult.id;
    movement.canonicalName = searchResult.canonicalName;
    movement.variantMask = searchResult.variantMask;
    movement.isBodyLift = searchResult.isBodyLift;
    movement.percentageOfBodyWeight = searchResult.percentageOfBodyWeight;    
    UIViewController *enterReps = [screenToolkit newEnterRepsScreenMakerWithMovement:movement
                                                                             variant:variant
                                                                         dismissable:YES]();
    if (asModal) {
      [[parentController navigationController] presentViewController:[PEUIUtils navigationControllerWithController:enterReps
                                                                                               navigationBarHidden:NO]
                                                      animated:YES
                                                    completion:nil];
    } else {
      [[parentController navigationController] pushViewController:enterReps animated:YES];
    }
  };
  if (searchResult.variantMask && searchResult.variantMask.integerValue != 0) {
    NSArray *variants = [coordDao movementVariantsForMovementVariantMask:searchResult.variantMask error:[RUtils localFetchErrorHandlerMaker]()];
    if (variants.count > 1) {
      RSelectScreen *selectVariant =
      [[RSelectScreen alloc] initWithUitoolkit:uitoolkit
                                      coordDao:coordDao
                                 screenToolkit:screenToolkit
                                         title:@"Select Movement Variant"
                                   breadcrumbs:@[searchResult.canonicalName]
                                  itemsFetcher:^{ return variants; }
                         titleForSelectButtons:^(RMovementVariant *variant) { return variant.name; }
                                actionOnSelect:^(UIViewController *controller, RMovementVariant *variant) {
                                  launchEnterReps(variant, NO, controller);
                                }
                                   cancellable:YES
                            colorForLastButton:nil
                           isMovementSelection:NO
                     movementSearchBarVPadding:0.0];
      if (nextScreenAsModal) {
        [[controller navigationController] presentViewController:[PEUIUtils navigationControllerWithController:selectVariant
                                                                                           navigationBarHidden:NO]
                                                        animated:YES
                                                      completion:nil];
      } else {
        [controller.navigationController pushViewController:selectVariant animated:YES];
      }
    } else {
      launchEnterReps(variants[0], nextScreenAsModal, controller);
    }
  } else {
    launchEnterReps(nil, nextScreenAsModal, controller);
  }
}

+ (UIView *)viewForMovementSearchResultsHeaderWithTableView:(UITableView *)tableView
                                      movementSearchResults:(NSMutableArray *)movementSearchResults
                                                 controller:(PEBaseController *)controller {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *headerView = [PEUIUtils panelWithWidthOf:1.0
                                    relativeToView:tableView
                                       fixedHeight:[RUIUtils heightForMovementSearchResultsHeader]];
  [headerView setBackgroundColor:[UIColor whiteColor]];
  NSInteger numResults = movementSearchResults.count;
  UIFont *font = [PEUIUtils italicFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:23.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:32.0]
                                                         font: [PEUIUtils italicFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  NSNumberFormatter *formatter = [NSNumberFormatter new];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  UILabel *label = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"%@ result%@", [formatter stringFromNumber:@(numResults)], numResults > 1 || numResults == 0 ? @"s" : @""]
                                      font:font
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor rikerAppBlack]
                       verticalTextPadding:0.0];  
  font = [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:34.0]
                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  UIButton *cancelButton = [PEUIUtils buttonWithKey:@"cancel search"
                                               font:font
                                    backgroundColor:[UIColor rikerAppBlack]
                                          textColor:[UIColor whiteColor]
                       disabledStateBackgroundColor:nil
                             disabledStateTextColor:nil
                                    verticalPadding:12.0
                                  horizontalPadding:18.0
                                       cornerRadius:3.0
                                             target:nil
                                             action:nil];
  [cancelButton bk_addEventHandler:^(id sender) {
    [RUIUtils cancelMovementSearchWithResults:movementSearchResults controller:controller];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils placeView:label inMiddleOf:headerView withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:8.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils placeView:cancelButton inMiddleOf:headerView withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:8.0 + iphoneXSafeInsetsSideVal];
  return headerView;
}

+ (void)cancelMovementSearchWithResults:(NSMutableArray *)movementSearchResults
                             controller:(PEBaseController *)controller {
  [movementSearchResults removeAllObjects];
  UIView *dimmerView = [controller.view viewWithTag:RDIMMER_VIEW_TAG];
  UIView *searchResultsTableView = [controller.view viewWithTag:RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG];
  UISearchBar *searchBar = [controller.view viewWithTag:RMOVEMENT_SEARCHBAR_TAG];
  [UIView animateWithDuration:0.3
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     [PEUIUtils setFrameHeight:0.0 ofView:searchResultsTableView];
                     dimmerView.alpha = 0.0;
                   }
                   completion:^(BOOL finished) {
                     [searchResultsTableView removeFromSuperview];
                     [dimmerView removeFromSuperview];
                     searchBar.text = @"";
                     [searchBar resignFirstResponder];
                     if ([[controller displayPanel] isKindOfClass:[UIScrollView class]]) {
                       [((UIScrollView *)[controller displayPanel]) setScrollEnabled:YES];
                     }
                   }];
}

+ (CGFloat)heightForMovementSearchResultsHeader {
  return [PEUIUtils valueIfiPhone5Width:56.0 iphone6Width:56.0 iphone6PlusWidth:58.0 ipad:66.0];
}

+ (CGFloat)heightForMovementSearchResultsFooter {
  return [PEUIUtils valueIfiPhone5Width:6.0 iphone6Width:8.0 iphone6PlusWidth:10.0 ipad:14.0];
}

+ (CGFloat)heightForCellForSearchResult:(RMovementSearchResult *)searchResult
                         availableWidth:(CGFloat)availableWidth {
  UIView *labelsPanel = [RUIUtils labelsPanelForMovementSearchResult:searchResult availableWidth:availableWidth];
  return labelsPanel.frame.size.height + 40.0;  
}

+ (UISearchBar *)movementSearchBarWithDelegate:(id<UISearchBarDelegate>)delegate relativeToView:(UIView *)relativeToView {
  UISearchBar *movementSearchBar = [[UISearchBar alloc] init];
  movementSearchBar.tag = RMOVEMENT_SEARCHBAR_TAG;
  movementSearchBar.delegate = delegate;
  movementSearchBar.placeholder = @"search all movements";
  movementSearchBar.keyboardType = UIKeyboardTypeAlphabet;
  movementSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [PEUIUtils setFrameWidthOfView:movementSearchBar ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils setFrameHeight:[PEUIUtils valueIfiPhone5Width:50.0 iphone6Width:55.0 iphone6PlusWidth:60.0 ipad:60.0]
                     ofView:movementSearchBar];
  return movementSearchBar;
}

#pragma mark - Helpers

+ (UIFont *)rikerSupportEmailFont {
  return [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:34.0 iphone6PlusWidth:34.0 ipad:38.0]
                                               font:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
}

+ (void)styleNavbarForController:(UIViewController *)controller {
  [controller.navigationController.navigationBar setBarTintColor:[UIColor rikerAppBlack]];
  [controller.navigationController.navigationBar
   setTitleTextAttributes:@{NSForegroundColorAttributeName : [RUIUtils navbarTextTintColor]}];
}

+ (UIColor *)navbarTextTintColor {
  return [UIColor cloudsColor];
}

+ (CGFloat)contentPanelTopPadding {
  return [PEUIUtils valueIfiPhone5Width:25.0
                           iphone6Width:25.0
                       iphone6PlusWidth:30.0
                                   ipad:40.0];
}

+ (NSMutableArray *)couldNotSyncImportedRecordsAlertSectionsWith:(NSInteger)numImportedSetsNotSyncedDueToNotAllowed
                        numImportedSetsNotSyncedDueToMaxExceeded:(NSInteger)numImportedSetsNotSyncedDueToMaxExceeded
                         numImportedBmlsNotSyncedDueToNotAllowed:(NSInteger)numImportedBmlsNotSyncedDueToNotAllowed
                        numImportedBmlsNotSyncedDueToMaxExceeded:(NSInteger)numImportedBmlsNotSyncedDueToMaxExceeded
                                                      controller:(UIViewController *)controller {
  NSMutableArray *notImportedSections = [NSMutableArray array];
  void(^addNotAllowedSection)(NSInteger, NSString *) = ^(NSInteger numNotAllowed, NSString *entityType) {
    NSString *pluralSuffix = numNotAllowed > 1 ? @"s" : @"";
    if (numNotAllowed > 0) {
      NSNumberFormatter *formatter = [NSNumberFormatter new];
      [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
      [notImportedSections addObject:[PEUIUtils warningAlertSectionWithMsgs:nil
                                                                      title:[NSString stringWithFormat:@"Imported %@%@ not synced.", entityType, pluralSuffix]
                                                           alertDescription:[PEUIUtils attributedTextWithTemplate:@"Your %@ could not be synced.  You need to have a verified email address in order to sync imported records."
                                                                                                     textToAccent:[NSString stringWithFormat:@"%@ imported %@%@", [formatter stringFromNumber:@(numNotAllowed)], entityType, pluralSuffix]
                                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                        descLblHeightAdjust:0.0
                                                             relativeToView:[PEUIUtils parentViewForAlertsForController:controller]]];
    }
  };
  void(^addMaxExceededSection)(NSInteger, NSString *) = ^(NSInteger numMaxExceeded, NSString *entityType) {
    if (numMaxExceeded > 0) {
      NSNumberFormatter *formatter = [NSNumberFormatter new];
      [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
      NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
      NSString *pluralSuffix = numMaxExceeded > 1 ? @"s" : @"";
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Your %@ could not be synced.  Import limit exceeded.  Contact Riker support at "
                                                            textToAccent:[NSString stringWithFormat:@"%@ imported %@%@", [formatter stringFromNumber:@(numMaxExceeded)], entityType, pluralSuffix]
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ and we'll try to help you out."
                                                            textToAccent:[APP rikerSupportEmail]
                                                          accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      [notImportedSections addObject:[PEUIUtils warningAlertSectionWithMsgs:nil
                                                                      title:[NSString stringWithFormat:@"Imported %@%@ not synced.", entityType, pluralSuffix]
                                                           alertDescription:desc
                                                        descLblHeightAdjust:0.0
                                                             relativeToView:[PEUIUtils parentViewForAlertsForController:controller]]];
    }
  };
  addNotAllowedSection(numImportedSetsNotSyncedDueToNotAllowed, @"set");
  addMaxExceededSection(numImportedSetsNotSyncedDueToMaxExceeded, @"set");
  addNotAllowedSection(numImportedBmlsNotSyncedDueToNotAllowed, @"body log");
  addMaxExceededSection(numImportedBmlsNotSyncedDueToMaxExceeded, @"body log");
  return notImportedSections;
}

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView {
  return [PEUIUtils leftPadView:[PEUIUtils labelWithKey:headerText
                                                   font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                        backgroundColor:[UIColor clearColor]
                                              textColor:[UIColor darkGrayColor]
                                    verticalTextPadding:3.0
                                             fitToWidth:relativeToView.frame.size.width - 15.0]
                        padding:8.0];
}

+ (REnableUserInteractionBlk)makeUserEnabledBlockForController:(UIViewController *)controller {
  return ^(BOOL enable) {
    UINavigationItem *navigationItem = controller.navigationItem;
    if (navigationItem) {
      UIBarButtonItem *leftBarButtonItem = navigationItem.leftBarButtonItem;
      if (leftBarButtonItem) {
        leftBarButtonItem.enabled = enable;
      }
      UIBarButtonItem *rightBarButtonItem = navigationItem.rightBarButtonItem;
      if (rightBarButtonItem) {
        rightBarButtonItem.enabled = enable;
      }
      [navigationItem setHidesBackButton:!enable animated:YES];
    }
    UITabBarController *tabBarController = controller.tabBarController;
    if (tabBarController) {
      UITabBar *tabBar = tabBarController.tabBar;
      if (tabBar) {
        [tabBar setUserInteractionEnabled:enable];
      }
    }
  };
}

+ (UIImageView *)imageViewForOriginationDevice:(ROriginationDevice *)originationDevice {
  UIImageView *origDeviceImageView = nil;
  if (originationDevice.hasLocalImage) {
    origDeviceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:originationDevice.iconImageName]];
    //NSLog(@"origDeivieImgView w: %f, h: %f", origDeviceImageView.frame.size.width, origDeviceImageView.frame.size.height);
  } else {
    origDeviceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 17.5)];
    [origDeviceImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@.png", [APP urlForImageName:originationDevice.iconImageName]]]];
  }
  return origDeviceImageView;
}

@end
