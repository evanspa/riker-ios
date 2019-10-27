//
//  REnterRepsScreen.h
//  riker-ios
//
//  Created by PEVANS on 2/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PEBaseController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RUserSettings;
@class RMovement;
@class RMovementVariant;
@class PELMUser;

@interface REnterRepsScreen : PEBaseController <MBProgressHUDDelegate>

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                   breadcrumbs:(NSArray *)breadcrumbs
                   dismissable:(BOOL)dismissable
               userSettingsBlk:(RUserSettings *(^)(PELMUser *))userSettingsBlk
                      movement:(RMovement *)movement
               movementVariant:(RMovementVariant *)movementVariant
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                   panelTookit:(RPanelToolkit *)panelToolkit;

@end
