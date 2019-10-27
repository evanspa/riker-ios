//
//  RUIUtils.h
//  riker-ios
//
//  Created by PEVANS on 10/26/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEUIDefs.h"
#import "PEUIUtils.h"
#import "RCoordinatorDao.h"
#import "RUtils.h"

FOUNDATION_EXPORT NSInteger const RMOVEMENT_SEARCHBAR_TAG;
FOUNDATION_EXPORT NSInteger const RDIMMER_VIEW_TAG;
FOUNDATION_EXPORT NSInteger const RCONTENT_PANEL_TAG;
FOUNDATION_EXPORT NSInteger const RMOVEMENT_SEARCH_RESULTS_TABLE_VIEW_TAG;
FOUNDATION_EXPORT NSInteger const RHUD_TAG;

@class ROriginationDevice;
@class RMovementSearchResult;
@class PEBaseController;
@class RScreenToolkit;

@interface RUIUtils : NSObject

#pragma mark - Movement Search Bar Helpers

+ (void)movementSearchBarViewDidLoadHandlerWithController:(PEBaseController *)controller
                                    movementSearchResults:(NSMutableArray *)movementSearchResults;

+ (void)movementSearchBarTextDidChangeWithSearchBar:(UISearchBar *)searchBar
                                         searchText:(NSString *)searchText
                              movementSearchResults:(NSMutableArray *)movementSearchResults
                                           coordDao:(id<RCoordinatorDao>)coordDao
                                         controller:(PEBaseController *)controller;

+ (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
               movementSearchResults:(NSMutableArray *)movementSearchResults
                   tableViewDelegate:(id<UITableViewDelegate>)tableViewDelegate
                 tableViewDataSource:(id<UITableViewDataSource>)tableViewDataSource
                          controller:(PEBaseController *)controller;

+ (UITableViewCell *)movementSearchResultCellForIndexPath:(NSIndexPath *)indexPath
                                                tableView:(UITableView *)tableView
                                    movementSearchResults:(NSMutableArray *)movementSearchResults
                                           availableWidth:(CGFloat)availableWidth;

+ (void)didSelectMovementSearchResultRowWithResults:(NSMutableArray *)movementSearchResults
                                          indexPath:(NSIndexPath *)indexPath
                                      screenToolkit:(RScreenToolkit *)screenToolkit
                                          uitoolkit:(PEUIToolkit *)uitoolkit
                                           coordDao:(id<RCoordinatorDao>)coordDao
                                  nextScreenAsModal:(BOOL)nextScreenAsModal
                                         controller:(PEBaseController *)controller;

+ (UIView *)viewForMovementSearchResultsHeaderWithTableView:(UITableView *)tableView
                                      movementSearchResults:(NSMutableArray *)movementSearchResults
                                                 controller:(PEBaseController *)controller;

+ (void)cancelMovementSearchWithResults:(NSMutableArray *)movementSearchResults
                             controller:(PEBaseController *)controller;

+ (CGFloat)heightForMovementSearchResultsHeader;

+ (CGFloat)heightForMovementSearchResultsFooter;

+ (CGFloat)heightForCellForSearchResult:(RMovementSearchResult *)searchResult
                         availableWidth:(CGFloat)availableWidth;

+ (UISearchBar *)movementSearchBarWithDelegate:(id<UISearchBarDelegate>)delegate relativeToView:(UIView *)relativeToView;

#pragma mark - Helpers

+ (UIFont *)rikerSupportEmailFont;

+ (void)styleNavbarForController:(UIViewController *)controller;

+ (UIColor *)navbarTextTintColor;

+ (CGFloat)contentPanelTopPadding;

+ (NSMutableArray *)couldNotSyncImportedRecordsAlertSectionsWith:(NSInteger)numImportedSetsNotSyncedDueToNotAllowed
                        numImportedSetsNotSyncedDueToMaxExceeded:(NSInteger)numImportedSetsNotSyncedDueToMaxExceeded
                         numImportedBmlsNotSyncedDueToNotAllowed:(NSInteger)numImportedBmlsNotSyncedDueToNotAllowed
                        numImportedBmlsNotSyncedDueToMaxExceeded:(NSInteger)numImportedBmlsNotSyncedDueToMaxExceeded
                                                      controller:(UIViewController *)controller;

+ (UIView *)headerPanelWithText:(NSString *)headerText relativeToView:(UIView *)relativeToView;

+ (REnableUserInteractionBlk)makeUserEnabledBlockForController:(UIViewController *)controller;

+ (UIImageView *)imageViewForOriginationDevice:(ROriginationDevice *)originationDevice;

@end
