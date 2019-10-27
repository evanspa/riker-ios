//
//  RGeneralInfoController.h
//  riker-ios
//
//  Created by PEVANS on 3/30/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"
#import "RUtils.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;
@class RPanelToolkit;

@interface RGeneralInfoController : PELocalDataBaseController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit;

@end
