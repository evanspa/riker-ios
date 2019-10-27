//
//  RAbstractChartsPreviewController.h
//  Riker
//
//  Created by PEVANS on 10/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"
#import "RAbstractChartController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;

@interface RAbstractChartsPreviewController : RAbstractChartController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
               userSettingsBlk:(RUserSettingsBlk)userSettingsBlk
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
                   screenTitle:(NSString *)screenTitle
                          user:(PELMUser *)user
       entitiesAndRawDataCache:(NSMutableDictionary *)entitiesAndRawDataCache;

#pragma mark - Chart Loading

- (RChartDataFetchMode)fetchMode;

#pragma mark - Properties

@property (nonatomic) NSMutableArray *chartAndLoaderTuplesArray;
@property (nonatomic) NSMutableDictionary *chartAndLoaderTuples;
@property (nonatomic) PEUIToolkit *uitoolkit;
@property (nonatomic) RScreenToolkit *screenToolkit;
@property (nonatomic) RPanelToolkit *panelToolkit;
@property (nonatomic) RUserSettingsBlk userSettingsBlk;
@property (nonatomic) BOOL isRepaintDueToNonDataChange;
@property (nonatomic) UIView *yourContentPanel;
@property (nonatomic) BOOL maintenanceNoticeAdded;
@property (nonatomic) BOOL unAckdUpcomingMaintenanceNoticeAdded;
@property (nonatomic) BOOL adjustedViewsForOfflineMode;
@property (nonatomic) NSMutableArray *movementSearchResults;

#pragma mark - Scroll Helpers

- (void)configureJumpToButton:(UIButton *)jumpToButton
                 contentPanel:(UIView *)contentPanel
                 headingPanel:(UIView *)headingPanel;

- (void)scrollToTop;

@end
