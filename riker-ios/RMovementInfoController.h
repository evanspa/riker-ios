//
//  RMovementInfoController.h
//  riker-ios
//
//  Created by PEVANS on 3/31/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;
@class RMovement;

@interface RMovementInfoController : PELocalDataBaseController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                      movement:(RMovement *)movement
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
         enableStartSetButtons:(BOOL)enableStartSetButtons;

@end
