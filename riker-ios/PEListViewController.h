//
//  PEListViewController.h
//

#import <UIKit/UIKit.h>
#import "PEUIDefs.h"
#import "PEAddViewEditController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@class PEListViewController;

@interface PEListViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate, MBProgressHUDDelegate>

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
                       isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
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
                           cancellable:(BOOL)cancellable;

#pragma mark - Properties

@property (nonatomic, readonly) NSMutableArray *dataSource;

@property (nonatomic) BOOL hasScreenNameBeenLogged;

@property (nonatomic) UITableView *tableView;

@property (nonatomic) MBProgressHUD *hud;

@property (nonatomic) NSDecimalNumber *makeAndRenderContentDelay;

@end
