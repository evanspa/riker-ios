//
//  PESingleValueTableViewDataSourceDelegate.h
//  riker-ios
//
//  Created by PEVANS on 11/17/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RScreenToolkit.h"

@interface PESingleValueTableViewDataSourceDelegate : NSObject
<UITableViewDataSource, UITableViewDelegate>

#pragma mark - Initializers

- (id)initWithControllerCtx:(UIViewController *)controllerCtx
          pickerScreenMaker:(UIViewController *(^)(NSString *, id, void(^)(id)))pickerScreenMaker
          pickerScreenTitle:(NSString *)pickerScreenTitle
                 fieldLabel:(NSString *)fieldLabel
        fieldValueFormatter:(id(^)(id))fieldValueFormatter
                      value:(id)value
          valuePickedAction:(void(^)(id))valuePickedAction
 displayDisclosureIndicator:(BOOL)displayDisclosureIndicator
                  labelFont:(UIFont *)labelFont
                  valueFont:(UIFont *)valueFont
               leftIconName:(NSString *(^)(void))leftIconName
             relativeToView:(UIView *)relativeToView;

#pragma mark - Properties

@property (nonatomic) UIColor *textLabelColor;

@property (nonatomic) id pickedValue;

@end
