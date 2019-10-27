//
//  RAbstractStrengthChartsPreviewController.h
//  Riker
//
//  Created by PEVANS on 10/12/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RAbstractChartsPreviewController.h"

@interface RAbstractStrengthChartsPreviewController : RAbstractChartsPreviewController

#pragma mark - Properties

@property (nonatomic) NSInteger numSets;

#pragma mark - Jump To Buttons

- (NSArray *)makeJumpToButtons;

@end
