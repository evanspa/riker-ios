//
//  PESingleValueTableViewDataSourceDelegate.m
//  riker-ios
//
//  Created by PEVANS on 11/17/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PESingleValueTableViewDataSourceDelegate.h"
#import "PEUIUtils.h"
#import "PEUtils.h"
#import "RUtils.h"

@implementation PESingleValueTableViewDataSourceDelegate {
  UIViewController *_controllerCtx;
  UIViewController *(^_pickerScreenMaker)(NSString *, id, void(^)(id));
  NSString *_pickerScreenTitle;
  NSString *_fieldLabel;
  NSString *(^_fieldValueFormatter)(id);
  void(^_valuePickedAction)(id);
  BOOL _displayDisclosureIndicator;
  UIFont *_labelFont;
  UIFont *_valueFont;
  NSString *(^_leftIconName)(void);
  UIView *_relativeToView;
}

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
             relativeToView:(UIView *)relativeToView {
  self = [super init];
  if (self) {
    _controllerCtx = controllerCtx;
    _pickerScreenMaker = pickerScreenMaker;
    _pickerScreenTitle = pickerScreenTitle;
    _fieldLabel = fieldLabel;
    _fieldValueFormatter = fieldValueFormatter;
    _pickedValue = value;
    _valuePickedAction = valuePickedAction;
    _displayDisclosureIndicator = displayDisclosureIndicator;
    _labelFont = labelFont;
    _valueFont = valueFont;
    _leftIconName = leftIconName;
    _relativeToView = relativeToView;
    _textLabelColor = [UIColor blackColor];
  }
  return self;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [PEUIUtils displayController:_pickerScreenMaker(_pickerScreenTitle, _pickedValue, ^(id pickedVal) {
    _pickedValue = pickedVal;
    _valuePickedAction(pickedVal);
  })
                fromController:_controllerCtx
                      animated:YES];  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return CGFLOAT_MIN;
}

- (CGFloat)heightForTableCell {
  return [PEUIUtils sizeOfText:@""
                             withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height +
  + [PEUIUtils valueIfiPhone5Width:25.0
                      iphone6Width:25.0
                  iphone6PlusWidth:30.0
                              ipad:40.0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self heightForTableCell];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
  [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
  UIView *contentView = [cell contentView];
  [PEUIUtils setFrameHeight:[self heightForTableCell] ofView:contentView];
  NSString *leftIconName = nil;
  if (_leftIconName) {
    leftIconName = _leftIconName();
  }
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
  UILabel *textLabel = [PEUIUtils labelWithKey:_fieldLabel
                                          font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                 font:_labelFont != nil ? _labelFont : [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                               backgroundColor:[UIColor clearColor]
                                     textColor:_textLabelColor
                           verticalTextPadding:0.0];
  CGFloat hpadding = [PEUIUtils valueIfiPhone5Width:15.0
                                       iphone6Width:15.0
                                   iphone6PlusWidth:20.0
                                               ipad:20.0];
  UIImageView *leftIconImageView = nil;
  if (leftIconName) {
    leftIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:leftIconName]];
    [PEUIUtils placeView:leftIconImageView
              inMiddleOf:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:hpadding];
    [PEUIUtils placeView:textLabel
            toTheRightOf:leftIconImageView
                    onto:contentView
           withAlignment:PEUIVerticalAlignmentTypeMiddle
                hpadding:10.0];
  } else {
    [PEUIUtils placeView:textLabel
              inMiddleOf:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:hpadding];
  }
  UILabel *detailTextLabel = [cell detailTextLabel];
  if (_valueFont) {
    _valueFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:_valueFont];
    [detailTextLabel setFont:_valueFont];
  }
  UIFont *valueFont = _valueFont;
  NSString *fieldValueStr;
  id fieldValue = _fieldValueFormatter(_pickedValue);
  if ([fieldValue isKindOfClass:[NSString class]]) {
    fieldValueStr = (NSString *)fieldValue;
  } else if ([fieldValue isKindOfClass:[NSArray class]]) {
    NSArray *fieldValuesArray = (NSArray *)fieldValue;
    fieldValueStr = fieldValuesArray[0];
    UIColor *fieldValueColor = fieldValuesArray[1];
    if (fieldValuesArray.count >= 3) {
      valueFont = fieldValuesArray[2];
    }
    [detailTextLabel setTextColor:fieldValueColor];
  }
  CGFloat availableWidth = _relativeToView.frame.size.width;
  availableWidth -= (textLabel.frame.origin.x + textLabel.frame.size.width + (hpadding * 2) + (_displayDisclosureIndicator ? 15.0 : 0));
  valueFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                font:_valueFont != nil ? _valueFont : [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  [detailTextLabel setText:[PEUIUtils truncatedTextForText:fieldValueStr
                                                      font:valueFont
                                            availableWidth:availableWidth]];
  [detailTextLabel setFont:valueFont];
  if (_displayDisclosureIndicator) {
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  } else {
    [cell setAccessoryType:UITableViewCellAccessoryNone];
  }
  return cell;
}

@end
