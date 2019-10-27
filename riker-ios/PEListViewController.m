//
//  PEListViewController.m
//

#import "PEListViewController.h"
#import "NSString+RAdditions.h"
#import "PEUIUtils.h"
#import "PEUtils.h"
#import "PELMNotificationUtils.h"
#import "PELMIdentifiable.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSMutableArray+PEAdditions.h"
#import "UIScrollView+PEAdditions.h"
#import "RAppNotificationNames.h"
#import "RLogging.h"
#import "RUtils.h"
#import "AppDelegate.h"
#import "RUIUtils.h"
@import Firebase;

@interface PEListViewController () <JGActionSheetDelegate>
@end

@implementation PEListViewController {
  Class _classOfDataSourceObjects;
  NSString *_title;
  PETableCellContentViewStyler _tableCellStyler;
  PEItemSelectedAction _itemSelectedAction;
  id<PELMIdentifiable> _initialSelectedItem;
  void (^_addItemAction)(PEListViewController *, PEItemAddedBlk);
  NSString *_cellIdentifier;
  PEPageLoaderBlk _pageLoaderBlk;
  PEDetailViewMaker _detailViewMaker;
  PEUIToolkit *_uitoolkit;
  NSIndexPath *_indexPathOfRemovedEntity;
  PEDoesEntityBelongToListView _doesEntityBelongToThisListView;
  PEWouldBeIndexOfEntity _wouldBeIndexOfEntity;
  BOOL _isPaginatedDataSource;
  PEIsLoggedInBlk _isUserLoggedIn;
  PEIsBadAccountBlk _isBadAccount;
  PEIsAuthenticatedBlk _isAuthenticatedBlk;
  PEItemChildrenCounter _itemChildrenCounter;
  PEItemChildrenMsgsBlk _itemChildrenMsgsBlk;
  PEItemDeleter _itemDeleter;
  PEItemLocalDeleter _itemLocalDeleter;
  BOOL _isEntityType;
  PEViewDidAppearBlk _viewDidAppearBlk;
  NSString *_entityAddedNotificationName;
  NSString *_entityUpdatedNotificationName;
  NSString *_entityRemovedNotificationName;
  UITableViewStyle _tableViewStyle;
  NSMutableArray *(^_rowsInSection)(NSInteger, id);
  NSString *(^_titleForHeaderInSection)(NSInteger, id);
  id(^_dataObjectAccessor)(NSIndexPath *, id);
  BOOL _cancellable;
  CGFloat(^_cellHeightBlk)(id);
  UIInterfaceOrientation _currentOrientation;
  BOOL _needsRepaint;
  CGFloat _tableViewVpadding;
  BOOL _moreToLoad;
  CGFloat _heightForTableViewFooter;
}

#pragma mark - Initializers

- (id)initWithClassOfDataSourceObjects:(Class)classOfDataSourceObjects
                                 title:(NSString *)title
                 isPaginatedDataSource:(BOOL)isPaginatedDataSource
                       tableCellStyler:(PETableCellContentViewStyler)tableCellStyler
                    itemSelectedAction:(PEItemSelectedAction)itemSelectedAction
                   initialSelectedItem:(id)initialSelectedItem
                         addItemAction:(void(^)(PEListViewController *, PEItemAddedBlk))addItemActionBlk
                        cellIdentifier:(NSString *)cellIdentifier
                        initialObjects:(NSArray *)initialObjects
                            pageLoader:(PEPageLoaderBlk)pageLoaderBlk
                         cellHeightBlk:(CGFloat(^)(id))cellHeightBlk
                       detailViewMaker:(PEDetailViewMaker)detailViewMaker
                             uitoolkit:(PEUIToolkit *)uitoolkit
        doesEntityBelongToThisListView:(PEDoesEntityBelongToListView)doesEntityBelongToThisListView
                  wouldBeIndexOfEntity:(PEWouldBeIndexOfEntity)wouldBeIndexOfEntity
                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticatedBlk
                        isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                          isBadAccount:(PEIsBadAccountBlk)isBadAccount
                   itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                   itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                           itemDeleter:(PEItemDeleter)itemDeleter
                      itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
                          isEntityType:(BOOL)isEntityType
                      viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
           entityAddedNotificationName:(NSString *)entityAddedNotificationName
         entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
         entityRemovedNotificationName:(NSString *)entityRemovedNotificationName
                        tableViewStyle:(UITableViewStyle)tableViewStyle
                         rowsInSection:(NSMutableArray *(^)(NSInteger, id))rowsInSection
               titleForHeaderInSection:(NSString *(^)(NSInteger, id))titleForHeaderInSection
                    dataObjectAccessor:(id(^)(NSIndexPath *, id))dataObjectAccessor
                           cancellable:(BOOL)cancellable {
  NSAssert(!(detailViewMaker && initialSelectedItem), @"detailViewMaker and initialSelectedItem cannot BOTH be provided");
  NSAssert(!(detailViewMaker && itemSelectedAction), @"detailViewMaker and itemSelectedAction cannot BOTH be provided");
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _classOfDataSourceObjects = classOfDataSourceObjects;
    _title = title;
    _isPaginatedDataSource = isPaginatedDataSource;    
    _tableCellStyler = tableCellStyler;
    _itemSelectedAction = itemSelectedAction;
    _initialSelectedItem = initialSelectedItem;
    _addItemAction = addItemActionBlk;
    _cellIdentifier = cellIdentifier;
    _pageLoaderBlk = pageLoaderBlk;
    _detailViewMaker = detailViewMaker;
    _uitoolkit = uitoolkit;
    _indexPathOfRemovedEntity = nil;
    _doesEntityBelongToThisListView = doesEntityBelongToThisListView;
    _wouldBeIndexOfEntity = wouldBeIndexOfEntity;
    _isAuthenticatedBlk = isAuthenticatedBlk;
    _isUserLoggedIn = isUserLoggedIn;
    _isBadAccount = isBadAccount;
    _itemChildrenCounter = itemChildrenCounter;
    _itemChildrenMsgsBlk = itemChildrenMsgsBlk;
    _itemDeleter = itemDeleter;
    _itemLocalDeleter = itemLocalDeleter;
    _isEntityType = isEntityType;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityAddedNotificationName = entityAddedNotificationName;
    _entityUpdatedNotificationName = entityUpdatedNotificationName;
    _entityRemovedNotificationName = entityRemovedNotificationName;
    _tableViewStyle = tableViewStyle;
    _rowsInSection = rowsInSection;
    _titleForHeaderInSection = titleForHeaderInSection;
    _dataObjectAccessor = dataObjectAccessor;
    _cancellable = cancellable;
    _cellHeightBlk = cellHeightBlk;
    _makeAndRenderContentDelay = [[NSDecimalNumber alloc] initWithFloat:0.10];
  }
  return self;
}

#pragma mark - Helpers

- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    if (indexPath.row < _dataSource.count) {
      return _dataSource[indexPath.row];
    } else {
      return nil;
    }
  } else {
    return _dataObjectAccessor(indexPath, _dataSource);
  }
}

- (NSNumber *)indexOfEntity:(PELMMainSupport *)entity inElements:(NSArray *)elements {
  NSNumber *index = nil;
  NSUInteger dsCount = [elements count];
  for (int i = 0; i < dsCount; i++) {
    if (_isEntityType) {
      if ([entity doesHaveEqualIdentifiers:elements[i]]) {
        index = @(i);
        break;
      }
    } else {
      if ([entity isEqual:elements[i]]) {
        index = @(i);
        break;
      }
    }
  }
  return index;
}

- (NSIndexPath *)indexPathOfEntity:(PELMMainSupport *)entity {
  if (_tableViewStyle == UITableViewStylePlain) {
    NSNumber *rowIndex = [self indexOfEntity:entity inElements:_dataSource];
    if (rowIndex) {
      return [NSIndexPath indexPathForRow:rowIndex.integerValue inSection:0];
    }
  } else {
    NSUInteger numSections = [_dataSource count];
    for (int i = 0; i < numSections; i++) {
      NSArray *rows = _rowsInSection(i, _dataSource);
      NSNumber *rowIndex = [self indexOfEntity:entity inElements:rows];
      if (rowIndex) {
        return [NSIndexPath indexPathForRow:rowIndex.integerValue inSection:i];
      }
    }
  }
  return nil;
}

- (void)removeFromDataSourceAtIndexPath:(NSIndexPath *)indexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    [_dataSource removeObjectAtIndex:indexPath.row];
  } else {
    NSMutableArray *rows = _rowsInSection(indexPath.section, _dataSource);
    [rows removeObjectAtIndex:indexPath.row];
  }
}

- (BOOL)beforeAllElementsForIndexPath:(NSIndexPath *)indexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    return indexPath.row < [_dataSource count];
  } else {
    NSArray *elements = _rowsInSection(indexPath.section, _dataSource);
    return indexPath.row < [elements count];
  }
}

- (BOOL)equalToElementCountForIndexPath:(NSIndexPath *)indexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    return indexPath.row == [_dataSource count];
  } else {
    NSArray *elements = _rowsInSection(indexPath.section, _dataSource);
    return indexPath.row == [elements count];
  }
}

- (void)moveObjectFromIndexPath:(NSIndexPath *)fromIndexPath
                    toIndexPath:(NSIndexPath *)toIndexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    [_dataSource moveObjectFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
  } else {
    if (fromIndexPath.section == toIndexPath.section) {
      NSMutableArray *elements = _rowsInSection(fromIndexPath.section, _dataSource);
      [elements moveObjectFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
    } else {
      NSMutableArray *fromElements = _rowsInSection(fromIndexPath.section, _dataSource);
      id objectToMove = fromElements[fromIndexPath.row];
      [fromElements removeObjectAtIndex:fromIndexPath.row];
      NSMutableArray *toElements = _rowsInSection(toIndexPath.section, _dataSource);
      [toElements insertObject:objectToMove atIndex:toIndexPath.row];
    }
  }
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
  if (_tableViewStyle == UITableViewStylePlain) {
    [_dataSource insertObject:object atIndex:indexPath.row];
  } else {
    NSMutableArray *elements = _rowsInSection(indexPath.section, _dataSource);
    [elements insertObject:object atIndex:indexPath.row];
  }
}

- (UIView *)parentViewForAlerts {
  return [PEUIUtils parentViewForAlertsForController:self];
}

- (NSComparisonResult)compareIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath {
  if (indexPath.section < toIndexPath.section) {
    return NSOrderedAscending;
  } else if (indexPath.section > toIndexPath.section) {
    return NSOrderedAscending;
  } else { // sections are equal
    if (indexPath.row < toIndexPath.row) {
      return NSOrderedAscending;
    } else if (indexPath.row > toIndexPath.row) {
      return NSOrderedAscending;
    }
  }
  return NSOrderedSame;
}

#pragma mark - Entity changed methods

- (BOOL)handleUpdatedEntity:(id)updatedEntity entityIndexPath:(NSIndexPath *)entityIndexPath {
  BOOL entityUpdated = NO;
  DDLogDebug(@"=== begin === in PELVC/handleUpdatedEntity: (hUE) [%@] [%p] =============================", _title, self);
  // first (1 of 2) checks of belonging - type check:
  if ([updatedEntity isKindOfClass:_classOfDataSourceObjects]) {
    // okay, check 1/2 that it belongs.  But before we do the next check, lets
    // obtain the knowledge if it's currently here or not.
    DDLogDebug(@"PELVC/hUE [%@], check 1/2 passed.", _title);
    // (we'll need these handy-dandy blocks later - sorry for the interruption)
    void (^deleteAtTableIndex)(NSIndexPath *) = ^(NSIndexPath *idx) {
      [_tableView deleteRowsAtIndexPaths:@[idx]
                        withRowAnimation:UITableViewRowAnimationFade];
    };
    void (^deleteAtIndex)(NSIndexPath *) = ^(NSIndexPath *idx) {
      [self removeFromDataSourceAtIndexPath:idx];
      deleteAtTableIndex(idx);
    };
    void (^insertAtTableIndex)(NSIndexPath *) = ^(NSIndexPath *idx) {
      [_tableView insertRowsAtIndexPaths:@[idx]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    
    // can't just do this...entityIndexPath may be for a different instance of
    // this list view controller...we can only trust that entityIndexPath is
    // for this list controller if _isTopMostListController is YES; otherwise,
    // we'll have to do linear search to find relevant entity
    NSIndexPath *indexOfExistingEntity = entityIndexPath;
    if (indexOfExistingEntity) {
      DDLogDebug(@"PELVC/hUE [%@], indexOfExistingEntity: section: [%ld], row: [%ld]", _title, (long)indexOfExistingEntity.section, (long)indexOfExistingEntity.row);
    } else {
      DDLogDebug(@"PELVC/hUE [%@], indexOfExistingEntity is nil", _title);
    }
    // Now check 2/2 that it belongs.
    BOOL doesUpdatedEntityBelong = _doesEntityBelongToThisListView(updatedEntity);
    DDLogDebug(@"PELVC/hUE [%@], doesUpdatedEntityBelong: %@", _title, [PEUtils yesNoFromBool:doesUpdatedEntityBelong]);
    if (doesUpdatedEntityBelong) {
      // (the fact we'll be taking "some sort of action" for the given
      //  updatedEntity is good enough for me to set this flag for the return value)
      entityUpdated = YES;
      // So it really does belong.  Let's figure what we need to do.  To know
      // what to do, we need to compute the updated entity's would-be index.
      NSIndexPath *wouldBeIndex = entityIndexPath; //_wouldBeIndexOfEntity(updatedEntity);
      DDLogDebug(@"PELVC/hUE [%@], wouldBeIndex: section: [%ld], row: [%ld]", _title, (long)wouldBeIndex.section, (long)wouldBeIndex.row);
      DDLogDebug(@"PELVC/hUE [%@], FYI, dataSource count: %lu", _title, (unsigned long)[_dataSource count]);
      // We need to know where the entity CURRENTLY is.  Well, is it even here?
      if (indexOfExistingEntity) {
        // It's here.  Now to see what we have to do.
        //if ([wouldBeIndex compare:indexOfExistingEntity] == NSOrderedSame) {
        if ([self compareIndexPath:wouldBeIndex toIndexPath:indexOfExistingEntity] == NSOrderedSame) {
          // No 'movement' required.  It's currently where it needs to be.  Just
          // need to reload the table view row.
          [[self dataObjectForIndexPath:indexOfExistingEntity] overwrite:updatedEntity];
          [_tableView reloadRowsAtIndexPaths:@[indexOfExistingEntity]
                            withRowAnimation:UITableViewRowAnimationAutomatic];
          DDLogDebug(@"PELVC/hUE [%@], just need to reload row index: [%ld]", _title, (long)wouldBeIndex.row);
        } else if ([self beforeAllElementsForIndexPath:wouldBeIndex]) { //(wouldBeIndex < [_dataSource count]) {
          // Move (fyi, we can't use moveRowsAtIn... because it DOESN't reload
          // the moved rows from the data source, which we need).
          [[self dataObjectForIndexPath:indexOfExistingEntity] overwrite:updatedEntity];
          [self moveObjectFromIndexPath:indexOfExistingEntity toIndexPath:wouldBeIndex];
          [_tableView beginUpdates];
          deleteAtTableIndex(indexOfExistingEntity);
          insertAtTableIndex(wouldBeIndex);
          [_tableView endUpdates];
          DDLogDebug(@"PELVC/hUE [%@], moved.", _title);
        } else {
          // wouldBeIndex is equal to or larger than _dataSource size, so we need to
          // simply delete it.  I.e., it shouldn't be visible yet.
          deleteAtIndex(indexOfExistingEntity);
          DDLogDebug(@"PELVC/hUE [%@], deleted.", _title);
        }
      } else {
        // The updated entity belongs, but is not currently here.  Should it be
        // visible?  Lets check.
        DDLogDebug(@"PELVC/hUE [%@], belongs, but is not currently here.", _title);
        if ([self beforeAllElementsForIndexPath:wouldBeIndex]) { //(wouldBeIndex < [_dataSource count]) {
          [self insertObject:updatedEntity atIndexPath:wouldBeIndex];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hUE [%@], belongs, wasn't here, but is now inserted.", _title);
        } else {
          DDLogDebug(@"PELVC/hUE [%@], belongs, wasn't here, but not taking any action because its would-be index is larger than the data source count.", _title);
        }
        // otherwise, the updatedEntity will become visible when the user scrolls
        // and older entities are loaded
      }
    } else {
      // So it doesn't belong.  If it's still here, it needs to be deleted.
      if (indexOfExistingEntity) {
        DDLogDebug(@"PELVC/hUE [%@], unbelonging entity is here at row index: [%ld].  Proceeding to delete it.", _title, (long)indexOfExistingEntity.row);
        deleteAtIndex(indexOfExistingEntity);
      }
    }
  }
  DDLogDebug(@"=== end === in PELVC/handleUpdatedEntity: (hUE) [%@] (returning: %@) ==================", _title, [PEUtils yesNoFromBool:entityUpdated]);
  return entityUpdated;
}

- (BOOL)handleRemovedEntity:(id<PELMIdentifiable>)removedEntity entityIndexPath:(NSIndexPath *)entityIndexPath {
  BOOL entityRemoved = NO;
  DDLogDebug(@"=== begin === in PELVC/handleRemovedEntity: (hRE) =============================");
  DDLogDebug(@"hRE, removedEntity's localMainIdentifier: %@", [removedEntity localMainIdentifier]);
  DDLogDebug(@"hRE, removedEntity's localMasterIdentifier: %@", [removedEntity localMasterIdentifier]);
  DDLogDebug(@"hRE, removedEntity's globalIdentifier: %@", [removedEntity globalIdentifier]);
  if ([removedEntity isKindOfClass:_classOfDataSourceObjects]) {
    if (([removedEntity localMainIdentifier] == nil) && ([removedEntity localMasterIdentifier] == nil)) {
      DDLogDebug(@"PELVC/hRE, removedEntity's IDs are nil.  So, we're going to check if any entities here match that.");
      NSUInteger dsCount = [_dataSource count];
      PELMMainSupport *entity;
      for (NSInteger i = 0; i < dsCount; i++) {
        entity = _dataSource[i]; // TODO - update to use NSIndexPath
        if ([entity localMainIdentifier] == nil && [entity localMasterIdentifier] == nil) {
          DDLogDebug(@"PELVC/hRE, entity at index [%ld] has nil IDs, so we'll remove it.", (long)i);
          [_dataSource removeObjectAtIndex:i];
          [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]
                            withRowAnimation:UITableViewRowAnimationFade];
          entityRemoved = YES;
          break;
        }
      }
      if (!entityRemoved) {
        DDLogDebug(@"PELVC/hRE, couldn't find any entities with nil IDs.");
      }
    } else {
      // Is it currently here?
      // UPDATE: 02/01/2017 - so, yeah, I think it should ALWAYS be here...
      DDLogDebug(@"PELVC/hRE, check 1/2 passed.");
      NSNumber *idxOfExistingEntity = nil;
      if (entityIndexPath) {
        DDLogDebug(@"PELVC/hRE, supplied index path is not nil.  Row: %ld", (long)entityIndexPath.row);
        idxOfExistingEntity = [NSNumber numberWithInteger:entityIndexPath.row];
      } else {
        idxOfExistingEntity = [self indexOfEntity:removedEntity inElements:_dataSource]; //[self indexPathOfEntity:removedEntity];
        if (idxOfExistingEntity) {
          DDLogDebug(@"PELVC/hRE, supplied index path is nil.  Searching for it, found it at row: %@", idxOfExistingEntity);
        } else {
          DDLogDebug(@"PELVC/hRE, supplied index path is nil.  Searching for it, but could not find it.");
        }
      }
      if (idxOfExistingEntity) {
        DDLogDebug(@"PELVC/hRE, removedEntity is here.  Proceeding to remove it.");
        [_dataSource removeObjectAtIndex:[idxOfExistingEntity integerValue]];
        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[idxOfExistingEntity integerValue] inSection:0]]
                          withRowAnimation:UITableViewRowAnimationFade];
        entityRemoved = YES;
      } else {
        DDLogDebug(@"PELVC/hRE, removedEntity is not here.");
      }
    }
  } else {
    DDLogDebug(@"PELVC/hRE, removedEntity is of a different class than the entities here.");
  }
  DDLogDebug(@"=== end === in PELVC/handleRemovedEntity: (hRE) =============================");
  return entityRemoved;
}

- (BOOL)handleAddedEntity:(id)addedEntity {
  BOOL entityAdded = NO;
  DDLogDebug(@"=== begin === in PELVC/handleAddedEntity: (hAE)");
  if ([addedEntity isKindOfClass:_classOfDataSourceObjects]) {
    DDLogDebug(@"PELVC/hAE, check 1/2 passed.");
    BOOL doesEntityBelong = _doesEntityBelongToThisListView(addedEntity);
    DDLogDebug(@"PELVC/hAE, doesEntityBelong: %d", doesEntityBelong);
    if (doesEntityBelong) {
      void (^insertAtTableIndex)(NSIndexPath *) = ^(NSIndexPath *index) {
        [_tableView insertRowsAtIndexPaths:@[index]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
      };
      // So it belongs.  But, should we take any action?  I.e., we need to compute
      // its would-be index to see if it should even be visible given the current
      // state of the table view.  But even before that, we should check to see
      // if it's already here!
      // UPDATE - 02/01/2017 - I don't think it's possible that it already be here...
      // maybe this was possible when you originally did background processing of
      // syncing and whatnot...but....no, shouldn't be possible as of this writing
      NSNumber *indexOfExistingEntity = nil; // [self indexOfEntity:addedEntity inElements:_dataSource];
      DDLogDebug(@"PELVC/hUA, idxOfExistingEntity: %@", indexOfExistingEntity);
      if (indexOfExistingEntity) {
        DDLogDebug(@"PELVC/hUA, the entity is already here.  Taking no action then.");
      } else {
        // for simplicity, just put it in the first row position...
        NSIndexPath *wouldBeIndex = [NSIndexPath indexPathForRow:0 inSection:0]; //_wouldBeIndexOfEntity(addedEntity);
        DDLogDebug(@"PELVC/hAE, wouldBeIndex: %@", wouldBeIndex);
        DDLogDebug(@"PELVC/hAE, FYI, dataSource count: %lu", (unsigned long)[_dataSource count]);
        if ([self equalToElementCountForIndexPath:wouldBeIndex]) { //(wouldBeIndex == [_dataSource count]) {
          // Add (i.e., append to the end of the data source).
          [_dataSource addObject:addedEntity];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hAE, appended entity.");
          entityAdded = YES;
        } else if ([self beforeAllElementsForIndexPath:wouldBeIndex]) { //(wouldBeIndex < [_dataSource count]) {
          // Insert.
          [self insertObject:addedEntity atIndexPath:wouldBeIndex];
          insertAtTableIndex(wouldBeIndex);
          DDLogDebug(@"PELVC/hAE, inserted entity.");
          entityAdded = YES;
        } else {
          // wouldBeIndex is larger than _dataSource size, so we needn't take
          // action.  I.e., it shouldn't be visible yet.
          DDLogDebug(@"PELVC/hAE, no action taken.");
        }
      }
    }
  } else {
    DDLogDebug(@"PELVC/hAE, addedEntity is of a different class than the entities here.");
  }
  DDLogDebug(@"=== end === in PELVC/handleAddedEntity: (hAE)");
  return entityAdded;
}

#pragma mark - Updated entity notification handler

- (void)updatedEntity:(NSNotification *)notification {
  id entity = notification.userInfo[@"entity"];
  NSIndexPath *indexPath = notification.userInfo[@"indexPath"];
  [self handleUpdatedEntity:entity entityIndexPath:indexPath];
}

#pragma mark - Added entity notification handler

- (void)addedEntity:(NSNotification *)notification {
  id entity = notification.userInfo[@"entity"];
  [self handleAddedEntity:entity];
}

#pragma mark - Removed entity notification handler

- (void)removedEntity:(NSNotification *)notification {
  if (notification.userInfo) {
    id entity = notification.userInfo[@"entity"];
    NSIndexPath *indexPath = notification.userInfo[@"indexPath"];
    [self handleRemovedEntity:entity entityIndexPath:indexPath];
  }
}

#pragma mark - Offline notification handlers

- (void)offlineModeToggledOn:(NSNotification *)notification {
  [PEUIUtils addOfflineModeBarToController:self animate:YES];
}

- (void)offlineModeToggledOff:(NSNotification *)notification {
  [PEUIUtils removeOfflineModeBarFromController:self animated:YES];
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
    // for some strange fucking reason, after a rotation, I need to adjust the vpadding and footer height to make things look right
    _tableViewVpadding = [PEUIUtils valueIfiPhone5Width:_currentOrientation == UIInterfaceOrientationPortrait ? 95.0 : 45
                                           iphone6Width:_currentOrientation == UIInterfaceOrientationPortrait ? 95.0 : 50
                                       iphone6PlusWidth:_currentOrientation == UIInterfaceOrientationPortrait ? 95.0 : 60
                                                   ipad:90.0];
    _heightForTableViewFooter = 125.0;
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

#pragma mark - Notification observing setup

- (void)initializeNotificationObserving {
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(addedEntity:)
                             name:_entityAddedNotificationName
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(updatedEntity:)
                             name:_entityUpdatedNotificationName
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(removedEntity:)
                             name:_entityRemovedNotificationName
                           object:nil];
}

#pragma mark - NSObject

- (void)dealloc {
  _tableView.delegate = nil; // http://stackoverflow.com/a/8381334/1034895
}

#pragma mark - HUD

- (void)bringHudToFront {
  if (_hud) {
    [self.view bringSubviewToFront:_hud];
  }
}

- (void)showHud {
  [self showHudWithLabelText:nil mode:MBProgressHUDModeIndeterminate];
}

- (void)showHudWithLabelText:(NSString *)labelText mode:(MBProgressHUDMode)mode {
  if (!_hud) {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.tag = RHUD_TAG;
    _hud.mode = mode;
    if (labelText) {
      _hud.label.text = labelText;
    }
    _hud.delegate = self;
  }
}

- (void)hideHud {
  if (_hud) {
    [_hud hideAnimated:YES];
    _hud = nil;
  }
}

#pragma mark - View Controller Lifecycle

- (void)createAndPlaceTableView {
  _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:_tableViewStyle];
  [PEUIUtils setFrameWidthOfView:_tableView ofWidth:[PEUIUtils widthOfForContent] relativeTo:[self view]];
  [PEUIUtils setFrameHeightOfView:_tableView ofHeight:1.0 relativeTo:[self view]];
  [_tableView setDataSource:self];
  [_tableView setDelegate:self];
  [PEUIUtils placeView:_tableView
               atTopOf:self.view
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              vpadding:_tableViewVpadding
              hpadding:0.0];
  [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:_cellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_needsRepaint) {
    [_tableView removeFromSuperview];
    [self createAndPlaceTableView];
    [PEUIUtils removeOfflineModeBarFromController:self animated:NO];
    if ([APP offlineMode]) {
      [PEUIUtils addOfflineModeBarToController:self animate:NO];
    }
  }
  // this is okay from a perf standpoint, because, so far (as of 02/01/2017),
  // the _initialSelectedItem is only supplied for small data sets
  if (_initialSelectedItem) {
    NSIndexPath *index = [self indexPathOfEntity:_initialSelectedItem];
    if (index) {
      [_tableView scrollToRowAtIndexPath:index
                        atScrollPosition:UITableViewScrollPositionMiddle
                                animated:YES];
    }
  }
  if (!_hasScreenNameBeenLogged) {
    [RUtils logScreen:_title fromController:self];
    _hasScreenNameBeenLogged = YES;
  }
  if ([_tableView indexPathForSelectedRow]) {
    [_tableView reloadRowsAtIndexPaths:@[[_tableView indexPathForSelectedRow]]
                      withRowAnimation:UITableViewRowAnimationFade];
    
  }
  if (_viewDidAppearBlk) {
    _viewDidAppearBlk(self);
  }
  _needsRepaint = NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _moreToLoad = YES;
  _tableViewVpadding = 15.0;
  _heightForTableViewFooter = 50.0;
  _currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
  [RUIUtils styleNavbarForController:self];
  UINavigationItem *navItem = [self navigationItem];
  [self setTitle:_title];
  [navItem setTitle:_title];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  [self createAndPlaceTableView];
  self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
  [self showHud];
  if (_addItemAction) {
    [navItem setRightBarButtonItem:
     [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
      target:self
      action:@selector(addItem)]];
  }
  if (_isEntityType) {
    [self initializeNotificationObserving];
  }
  if (_cancellable) {
    UINavigationItem *navItem = [self navigationItem];
    [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel)]];
  }
  if ([APP offlineMode]) {
    [PEUIUtils addOfflineModeBarToController:self animate:NO];
  }
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
  dispatch_async( dispatch_get_global_queue(0, 0), ^{
    _dataSource = [NSMutableArray arrayWithArray:_pageLoaderBlk(nil)];
    dispatch_async(dispatch_get_main_queue(), ^{
      [_tableView reloadData];      
      [self hideHud];
    });
  });
}

#pragma mark - Cancel

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if ([scrollView isAtBottom]) {
    [self addRowsToBottom];
  }
}

#pragma mark - Initial Selected Item

- (NSArray *)truncateInitialSelectedItemFromItems:(NSArray *)items {
  if (_initialSelectedItem) {
    NSMutableArray *mutableItems = [items mutableCopy];
    NSInteger numItems = [items count];
    for (NSInteger i = 0; i < numItems; i++) {
      if ([_initialSelectedItem doesHaveEqualIdentifiers:items[i]]) {
        [mutableItems removeObjectAtIndex:i];
        break;
      }
    }
    return mutableItems;
  }
  return items;
}

#pragma mark - Adding an item

- (void)addItem {
  PEItemAddedBlk itemAddedBlk = ^(PEAddViewEditController *addViewEditCtrl, id newItem) {
      [[addViewEditCtrl navigationController] dismissViewControllerAnimated:YES
                                                                 completion:^{ [APP refreshTabs]; }];
  };
  _addItemAction(self, itemAddedBlk);
}

#pragma mark - Loading items to bottom of table (infinite scrolling)

- (void)addRowsToBottom {
  if (_isPaginatedDataSource && _moreToLoad) {
    if (!_hud || _hud.isHidden) {
      NSUInteger dataSourceCount = [_dataSource count];
      [self showHud];
      if (dataSourceCount > 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
          id lastItem = [_dataSource lastObject];
          NSArray *nextPage = [self truncateInitialSelectedItemFromItems:_pageLoaderBlk(lastItem)];
          NSUInteger nextPageCount = [nextPage count];
          _moreToLoad = nextPageCount > 0;
          dispatch_async(dispatch_get_main_queue(), ^{
            if (nextPageCount > 0) {
              [_tableView beginUpdates];
              [_dataSource addObjectsFromArray:nextPage];
              NSMutableArray *indexPathsAdded = [NSMutableArray arrayWithCapacity:nextPageCount];
              for (int i = 0; i < nextPageCount; i++) {
                [indexPathsAdded addObject:[NSIndexPath indexPathForRow:(dataSourceCount + i)
                                                              inSection:0]];
              }
              [_tableView insertRowsAtIndexPaths:indexPathsAdded
                                withRowAnimation:UITableViewRowAnimationTop];
              [_tableView endUpdates];
            }
            [self hideHud];
          });
        });
      } else {
        [self hideHud];
      }
    }
  }
}

#pragma mark - JGActionSheetDelegate and Alert-related Helpers

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

#pragma mark - Do Deletion

- (void)deleteItem:(PELMMainSupport *)item forRowAtIndexPath:(NSIndexPath *)indexPath {
  void (^doLocalDelete)(void) = ^{
    [_tableView beginUpdates];
    _itemLocalDeleter(self, item, indexPath);
    [_dataSource removeObjectAtIndex:indexPath.row];
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_tableView endUpdates];
    [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                        object:self
                                                      userInfo:nil];
  };
  void (^postDeleteAttemptActivities)(void) = ^{
    [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
  };
  void (^doDeleteWithChildrenConfirm)(void(^)(void)) = ^(void(^deleter)(void)) {
    if (_itemChildrenCounter) {
      NSInteger numChildren = _itemChildrenCounter(item);
      if (numChildren > 0) {
        [PEUIUtils showWarningConfirmAlertWithMsgs:_itemChildrenMsgsBlk(item)
                                             title:@"Are you sure?"
                                  alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\
Deleting this %@ will result in the following child-records being deleted.\n\nAre you sure you want to continue?", [_title lowercaseString]]]
                               descLblHeightAdjust:0.0
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                   okayButtonTitle:@"Yes, delete."
                                  okayButtonAction:^{deleter();}
                                 cancelButtonTitle:@"No, cancel."
                                cancelButtonAction:^{
                                  postDeleteAttemptActivities();
                                  [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                }
                                    relativeToView:[self parentViewForAlerts]];
      } else {
        deleter();
      }
    } else {
      deleter();
    }
  };
  if ([item globalIdentifier] && [APP isUserLoggedIn]) {
    if (_isAuthenticatedBlk() && !_isBadAccount()) {
      __block MBProgressHUD *HUD = nil;
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      NSMutableArray *errorsForDelete = [NSMutableArray array];
      // The meaning of the elements of the arrays found within errorsForDelete:
      //
      // errorsForDelete[*][0]: Error title (string)
      // errorsForDelete[*][1]: Is error user-fixable (bool)
      // errorsForDelete[*][2]: An NSArray of sub-error messages (strings)
      // errorsForDelete[*][3]: Is error type server busy (bool)
      // errorsForDelete[*][4]: Is error conflict-type (bool) - NA!
      // errorsForDelete[*][5]: Latest entity for conflict error - NA!
      // errorsForDelete[*][6]: Entity not found (bool)
      //
      NSMutableArray *successMessageTitlesForDelete = [NSMutableArray array];
      __block BOOL receivedAuthReqdErrorOnDeleteAttempt = NO;
      __block BOOL receivedForbiddenErrorOnDeleteAttempt = NO;
      void(^immediateDelDone)(NSString *) = ^(NSString *mainMsgTitle) {
        if ([errorsForDelete count] == 0) { // success
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideAnimated:YES];
            [PEUIUtils showSuccessAlertWithTitle:[successMessageTitlesForDelete[0] sentenceCase]
                                alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForDelete[0]]
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      [_tableView beginUpdates];
                                      [_dataSource removeObjectAtIndex:indexPath.row];
                                      [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                      [_tableView endUpdates];
                                      postDeleteAttemptActivities();
                                      [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                                          object:self
                                                                                        userInfo:nil];
                                    }
                                  relativeToView:[self parentViewForAlerts]];
          });
        } else { // error
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideAnimated:YES afterDelay:0];
            if ([errorsForDelete[0][3] boolValue]) { // server is busy
              [PEUIUtils showWaitAlertWithMsgs:nil
                                         title:@"Busy with maintenance."
                              alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try this operation again later."]
                           descLblHeightAdjust:0.0
                     additionalContentSections:nil
                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                   buttonTitle:@"Okay."
                                  buttonAction:^{
                                    postDeleteAttemptActivities();
                                    [_tableView reloadRowsAtIndexPaths:@[indexPath]
                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                  }
                                relativeToView:[self parentViewForAlerts]];
            } else if ([errorsForDelete[0][6] boolValue]) { // not found
              [PEUIUtils showInfoAlertWithTitle:@"Already deleted."
                               alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\
It looks like this %@ was already deleted from a different device. \
It has now been removed from this device.", [_title lowercaseString]]]
                            descLblHeightAdjust:0.0
                      additionalContentSections:nil
                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                    buttonTitle:@"Okay."
                                   buttonAction:^{
                                     doLocalDelete();
                                     postDeleteAttemptActivities();
                                   }
                                 relativeToView:[self parentViewForAlerts]];
            } else { // any other error type
              NSString *title;
              NSString *message;
              NSArray *subErrors = errorsForDelete[0][2];
              if ([subErrors count] > 1) {
                message = [NSString stringWithFormat:@"There were problems deleting your %@ from the server.  The errors are as follows:", [_title lowercaseString]];
                title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
              } else {
                message = [NSString stringWithFormat:@"There was a problem deleting your %@ from the server.  The error is as follows:", [_title lowercaseString]];
                title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
              }
              NSMutableArray *sections = [NSMutableArray array];
              [sections addObject:[PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                 title:title
                                                      alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                   descLblHeightAdjust:0.0
                                                        relativeToView:self.view]];
              if (receivedAuthReqdErrorOnDeleteAttempt) {
                [sections addObject:[PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              if (receivedForbiddenErrorOnDeleteAttempt) {
                [sections addObject:[PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                    message:nil
                                                                               buttonTitles:@[@"Okay."]
                                                                                buttonStyle:JGActionSheetButtonStyleDefault];
              [sections addObject:buttonsSection];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *btnIndexPath) {
                postDeleteAttemptActivities();
                [sheet dismissAnimated:YES];
                if (receivedAuthReqdErrorOnDeleteAttempt) {
                  [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                      object:nil
                                                                    userInfo:nil];
                }
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
              }];
              [alertSheet showInView:[self parentViewForAlerts] animated:YES];
            }
          });
        }
      };
      void(^delNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Not found."]],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:YES]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                              NSString *mainMsgTitle,
                                                              NSString *recordTitle) {
        [successMessageTitlesForDelete addObject:[NSString stringWithFormat:@"%@ deleted.", recordTitle]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSDate *retryAfter) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                     [NSNumber numberWithBool:YES],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^delServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Temporary server error."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^delServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSArray *computedErrMsgs) {
        BOOL isErrorUserFixable = YES;
        if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
          computedErrMsgs = @[@"Unknown server error."];
          isErrorUserFixable = NO;
        }
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:isErrorUserFixable],
                                     computedErrMsgs,
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        receivedAuthReqdErrorOnDeleteAttempt = YES;
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Authentication required."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        receivedForbiddenErrorOnDeleteAttempt = YES;
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Not permitted."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^deleteRemoteItem)(void) = ^{
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.tag = RHUD_TAG;
        HUD.delegate = self;
        HUD.label.text = @"Deleting from server...";
        [errorsForDelete removeAllObjects];
        [successMessageTitlesForDelete removeAllObjects];
        receivedAuthReqdErrorOnDeleteAttempt = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          _itemDeleter(self,
                       item,
                       indexPath,
                       delNotFoundBlk,
                       delSuccessBlk,
                       delRetryAfterBlk,
                       delServerTempError,
                       delServerError,
                       delAuthReqdBlk,
                       delForbiddenBlk);
        });
      };
      doDeleteWithChildrenConfirm(deleteRemoteItem);
    } else {
      if (!_isAuthenticatedBlk()) {
        [PEUIUtils showWarningAlertWithMsgs:@[]
                                      title:@"Oops"
                           alertDescription:[PEUIUtils attributedTextWithTemplate:@"You cannot delete anything because you're no longer authenticated.  To re-authenticate, head over to:\n\n%@."
                                                                     textToAccent:@"Account \u2794 Re-authenticate"
                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                               }
                             relativeToView:[self parentViewForAlerts]];
        
      } else { // must be bad account
        [PEUIUtils showWarningAlertWithMsgs:@[]
                                      title:@"Oops"
                           alertDescription:[PEUIUtils attributedTextWithTemplate:@"You cannot delete anything because your account is in a bad state.\n\nThis is usually due to an expired trial account, closed account subscription or lapsed payment.  To fix your account, head over to:\n\n%@."
                                                                     textToAccent:@"Account \u2794 Status"
                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                        descLblHeightAdjust:0.0
                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                buttonTitle:@"Okay."
                               buttonAction:^{
                                 [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                               }
                             relativeToView:[self parentViewForAlerts]];
      }
    }
  } else {
    doDeleteWithChildrenConfirm(^{
      dispatch_async(dispatch_get_main_queue(), ^{
        doLocalDelete();
        postDeleteAttemptActivities();
      });
    });
  }
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return _itemDeleter != nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    if (_itemDeleter) {
      id item = [self dataObjectForIndexPath:indexPath];
      [self deleteItem:item forRowAtIndexPath:indexPath];
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (_itemSelectedAction) {
    _itemSelectedAction([self dataObjectForIndexPath:indexPath], indexPath, self, tableView);
  } else if (_detailViewMaker) {
    [PEUIUtils displayController:_detailViewMaker(self, [self dataObjectForIndexPath:indexPath], indexPath, ^(id dataObject, NSIndexPath *indexRow) {})
                  fromController:self
                        animated:YES];
  } else {
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return _cellHeightBlk([self dataObjectForIndexPath:indexPath]);
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
  id dataObject = [self dataObjectForIndexPath:indexPath];
  _tableCellStyler(cell, [cell contentView], dataObject);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return [PEUIUtils panelWithFixedWidth:self.view.frame.size.width fixedHeight:50.0];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return _heightForTableViewFooter;
}

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForHeaderInSection:(NSInteger)section {
  return [self tableView:tableView heightForFooterInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
  view.tintColor = [UIColor clearColor];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (_tableViewStyle == UITableViewStylePlain) {
    return 1;
  } else {
    return [_dataSource count];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (_tableViewStyle == UITableViewStylePlain) {
    return [_dataSource count];
  } else {
    return _rowsInSection(section, _dataSource).count;
  }
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
  if (_tableViewStyle == UITableViewStylePlain) {
    return nil;
  } else {
    return _titleForHeaderInSection(section, _dataSource);
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  id<PELMIdentifiable> dataObject = [self dataObjectForIndexPath:indexPath];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier forIndexPath:indexPath];
  if (_detailViewMaker) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  }
  if (_initialSelectedItem) {
    if (_isEntityType) {
      if ([_initialSelectedItem doesHaveEqualIdentifiers:dataObject]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
      } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
      }
    } else {
      if ([_initialSelectedItem isEqual:dataObject]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
      } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
      }
    }
  }
  return cell;
}

@end
