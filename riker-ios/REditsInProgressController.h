//
//  REditsInProgressController.h
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELocalDataBaseController.h"

@protocol RCoordinatorDao;
@class PEUIToolkit;
@class RScreenToolkit;

@interface REditsInProgressController : PELocalDataBaseController

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit;

@end
