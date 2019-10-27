//
//  RSelectScreen.h
//  riker-ios
//
//  Created by PEVANS on 2/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEBaseController.h"
#import "RCoordinatorDao.h"

@class RScreenToolkit;
@class PEUIToolkit;

@interface RSelectScreen : PEBaseController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

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
movementSearchBarVPadding:(CGFloat)movementSearchBarVPadding;

@end
