//
//  RChartFilterScreen.m
//  riker-ios
//
//  Created by PEVANS on 3/10/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RChartFilterScreen.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import <BlocksKit/UIView+BlocksKit.h>
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"
#import "RUtils.h"
#import "PEUIUtils.h"
#import "PESingleValueTableViewDataSourceDelegate.h"
#import "PEUtils.h"
#import "RUIUtils.h"
#import "RChartConfig.h"
#import "RPanelToolkit.h"
#import "RLogging.h"

@implementation RChartFilterScreen {
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  NSDateFormatter *_dateFormatter;
  RPanelToolkit *_panelToolkit;
  NSString *_mainHeadingText;
  NSString *_entityType;
  RChartConfig *_chartConfig;
  void (^_clearBlk)(void);
  void (^_doneBlk)(RChartConfig *);
  NSMutableArray *_tableViewDataSources;
  RChartConfig *_originalChartConfig;
  NSDate *_veryFirstDate;
  NSDate *_veryLastDate;
  BOOL _enableLineChartOptions;
  BOOL _enablePieChartOptions;
  NSString *_navbarTitle;
  NSString *_clearButtonTitle;
  UISwitch *_boundedEndDateSwitchView;
}

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
    mainHeadingText:(NSString *)mainHeadingText
         entityType:(NSString *)entityType
enableLineChartOptions:(BOOL)enableLineChartOptions
enablePieChartOptions:(BOOL)enablePieChartOptions
      veryFirstDate:(NSDate *)veryFirstDate
       veryLastDate:(NSDate *)veryLastDate
        chartConfig:(RChartConfig *)chartConfig
   clearButtonTitle:(NSString *)clearButtonTitle
           clearBlk:(void(^)(void))clearBlk
            doneBlk:(void(^)(RChartConfig *))doneBlk
          uitoolkit:(PEUIToolkit *)uitoolkit
      screenToolkit:(RScreenToolkit *)screenToolkit
       panelToolkit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:title];
  if (self) {
    _navbarTitle = title;
    _mainHeadingText = mainHeadingText;
    _entityType = entityType;
    _enableLineChartOptions = enableLineChartOptions;
    _enablePieChartOptions = enablePieChartOptions;
    _veryFirstDate = veryFirstDate;
    _veryLastDate = veryLastDate;
    _chartConfig = chartConfig;
    _clearButtonTitle = clearButtonTitle;
    _doneBlk = doneBlk;
    _clearBlk = clearBlk;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _tableViewDataSources = [NSMutableArray array];
    _originalChartConfig = [chartConfig copy];
  }
  return self;  
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  
  // create views
  CGFloat labelHpadding = 10.0 + [PEUIUtils iphoneXSafeInsetsSide];
  UILabel *heading = [PEUIUtils labelWithKey:_mainHeadingText
                                        font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor rikerAppBlack]
                         verticalTextPadding:5.0
                                  fitToWidth:contentPanel.frame.size.width - (labelHpadding * 2)];
  CGFloat msgLabelHpadding = 8.0 + [PEUIUtils iphoneXSafeInsetsSide];
  UILabel *veryFirstDateLabel = nil;
  if (_veryFirstDate) {
    veryFirstDateLabel =
    [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"Your first %@ was logged on: %%@", _entityType]
                                                               textToAccent:[PEUtils stringFromDate:_veryFirstDate withPattern:DATE_PATTERN]
                                                             accentTextFont:[PEUIUtils italicFontForTextStyle:UIFontTextStyleCaption2]]
                                 font:[PEUIUtils italicFontForTextStyle:UIFontTextStyleCaption2]
                      backgroundColor:[UIColor clearColor]
                            textColor:[UIColor rikerAppBlack]
                  verticalTextPadding:1.5
                           fitToWidth:contentPanel.frame.size.width - (msgLabelHpadding * 2)];
  }
  UITableView *startDateTableView =
  [PEUIUtils makeTableViewWithTag:nil
                        numFields:1
          dataSourceDelegateMaker:^(UITableView *tableView) {
            return
            [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:self
                                                                  pickerScreenMaker:^(NSString *title, NSDate *startDate, void(^valPickedAction)(id)) {
                                                                    return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                         initialSelectedDate:startDate
                                                                                                              datePickerMode:UIDatePickerModeDate
                                                                                                         logDatePickedAction:valPickedAction]();
                                                                  }
                                                                  pickerScreenTitle:@"Range start date"
                                                                         fieldLabel:@"Range start date"
                                                                fieldValueFormatter:^(NSDate *startDate) {
                                                                  return [PEUtils stringFromDate:startDate withPattern:DATE_PATTERN];
                                                                }
                                                                              value:_chartConfig.startDate
                                                                  valuePickedAction:^(NSDate *startDate) {
                                                                    _chartConfig.startDate = startDate;
                                                                    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                  }
                                                         displayDisclosureIndicator:YES
                                                                          labelFont:nil
                                                                          valueFont:nil
                                                                       leftIconName:nil
                                                                     relativeToView:contentPanel];
          }
                   relativeToView:contentPanel
             parentViewController:self];
  [PEUIUtils styleViewForIpad:startDateTableView];
  [_tableViewDataSources addObject:startDateTableView.dataSource];
  UILabel *startDateMsgLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"Only include %@s that were logged on or after this date.", _entityType]
                                                  font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:[UIColor darkGrayColor]
                                   verticalTextPadding:3.0
                                            fitToWidth:contentPanel.frame.size.width - (msgLabelHpadding * 2)];
  UILabel *veryLastDateLabel = nil;
  if (_veryLastDate && _chartConfig.boundedEndDate) {
    veryLastDateLabel =
    [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"Your most recent %@ was logged on: %%@", _entityType]
                                                               textToAccent:[PEUtils stringFromDate:_veryLastDate withPattern:DATE_PATTERN]
                                                             accentTextFont:[PEUIUtils italicFontForTextStyle:UIFontTextStyleCaption2]]
                                 font:[PEUIUtils italicFontForTextStyle:UIFontTextStyleCaption2]
                      backgroundColor:[UIColor clearColor]
                            textColor:[UIColor rikerAppBlack]
                  verticalTextPadding:1.5
                           fitToWidth:contentPanel.frame.size.width - (msgLabelHpadding * 2)];
  }
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  _boundedEndDateSwitchView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  _boundedEndDateSwitchView.on = _chartConfig.boundedEndDate;
  UIView *boundedEndDateSwitchPanel = [PEUIUtils panelWithWidthOf:1.0
                                                   relativeToView:contentPanel
                                                      fixedHeight:[RPanelToolkit rowDataCellHeightWithFontTextStyle:[PEUIUtils subheadlineFontTextStyle]
                                                                                                          uitoolkit:_uitoolkit]];
  [boundedEndDateSwitchPanel setBackgroundColor:[UIColor whiteColor]];
  UILabel *boundedEndDateSwitchLabel = [PEUIUtils labelWithKey:@"Bounded end date?"
                                                          font:[PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                                                                 font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                               backgroundColor:[UIColor clearColor]
                                                     textColor:[_uitoolkit colorForTableCellTitles]
                                           verticalTextPadding:3.0];
  [PEUIUtils placeView:boundedEndDateSwitchLabel
            inMiddleOf:boundedEndDateSwitchPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:[_uitoolkit leftViewPaddingForTextfields] + iphoneXSafeInsetsSideVal];
  [PEUIUtils placeView:_boundedEndDateSwitchView
            inMiddleOf:boundedEndDateSwitchPanel
         withAlignment:PEUIHorizontalAlignmentTypeRight
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  [PEUIUtils styleViewForIpad:boundedEndDateSwitchPanel];
  UITableView *endDateTableView = nil;
  if (_chartConfig.boundedEndDate) {
    endDateTableView =
    [PEUIUtils makeTableViewWithTag:nil
                          numFields:1
            dataSourceDelegateMaker:^(UITableView *tableView) {
              return
              [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:self
                                                                    pickerScreenMaker:^(NSString *title, NSDate *endDate, void(^valPickedAction)(id)) {
                                                                      return [_screenToolkit newDatePickerScreenMakerWithTitle:title
                                                                                                           initialSelectedDate:endDate
                                                                                                                datePickerMode:UIDatePickerModeDate
                                                                                                           logDatePickedAction:valPickedAction]();
                                                                    }
                                                                    pickerScreenTitle:@"Range end date"
                                                                           fieldLabel:@"Range end date"
                                                                  fieldValueFormatter:^(NSDate *endDate) {
                                                                    return [PEUtils stringFromDate:endDate withPattern:DATE_PATTERN];
                                                                  }
                                                                                value:_chartConfig.endDate
                                                                    valuePickedAction:^(NSDate *endDate) {
                                                                      _chartConfig.endDate = endDate;
                                                                      [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                       withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                    }
                                                           displayDisclosureIndicator:YES
                                                                            labelFont:nil
                                                                            valueFont:nil
                                                                         leftIconName:nil
                                                                       relativeToView:contentPanel];
            }
                     relativeToView:contentPanel
               parentViewController:self];
    [PEUIUtils styleViewForIpad:endDateTableView];
    [_tableViewDataSources addObject:endDateTableView.dataSource];
  }
  [_boundedEndDateSwitchView bk_addEventHandler:^(id sender) {
    _chartConfig.boundedEndDate = _boundedEndDateSwitchView.on;
    [self setNeedsRepaint:YES];
    [self viewDidAppear:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *endDateMsgLabel = nil;
  if (_chartConfig.boundedEndDate) {
    endDateMsgLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"Only include %@s that were logged on or before this date.", _entityType]
                                         font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor darkGrayColor]
                          verticalTextPadding:3.0
                                   fitToWidth:contentPanel.frame.size.width - (msgLabelHpadding * 2)];
  }
  UITableView *aggregateByTableView = nil;
  UILabel *aggregateByMsgLabel = nil;
  if (_enableLineChartOptions) {
    aggregateByTableView = [PEUIUtils makeTableViewWithTag:nil
                                        numFields:1
                          dataSourceDelegateMaker:^(UITableView *tableView) {
                            return
                            [[PESingleValueTableViewDataSourceDelegate alloc] initWithControllerCtx:self
                                                                                  pickerScreenMaker:^(NSString *title, NSNumber *aggregateBy, void(^valPickedAction)(id)) {
                                                                                    NSArray *initialSelectedItem = @[aggregateBy, [RChartConfig nameForAggregateByValue:[aggregateBy integerValue]]];
                                                                                    return [_screenToolkit newChartConfigAggregateBySelectionScreenMakerWithItemSelectedAction:^(NSArray *aggregateByTuple, NSIndexPath *indexPath, UIViewController *viewCtrlr, UITableView *tableView) {
                                                                                      valPickedAction(aggregateByTuple[0]);
                                                                                      [[viewCtrlr navigationController] popViewControllerAnimated:YES];
                                                                                    }
                                                                                                                                                 initialSelectedAggregateByVal:initialSelectedItem]();
                                                                                  }
                                                                                  pickerScreenTitle:@"Aggregate by"
                                                                                         fieldLabel:@"Aggregate by"
                                                                                fieldValueFormatter:^(NSNumber *aggregateBy) {
                                                                                  return [RChartConfig nameForAggregateByValue:aggregateBy.integerValue];
                                                                                }
                                                                                              value:_chartConfig.aggregateBy
                                                                                  valuePickedAction:^(NSNumber *aggregateBy) {
                                                                                    _chartConfig.aggregateBy = aggregateBy;
                                                                                    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                                  }
                                                                         displayDisclosureIndicator:YES
                                                                                          labelFont:nil
                                                                                          valueFont:nil
                                                                                       leftIconName:nil
                                                                                     relativeToView:contentPanel];
                          }
                                   relativeToView:contentPanel
                             parentViewController:self];
    [PEUIUtils styleViewForIpad:aggregateByTableView];
    [_tableViewDataSources addObject:aggregateByTableView.dataSource];
    aggregateByMsgLabel = [PEUIUtils labelWithKey:[NSString stringWithFormat:@"How your %@ data should be aggregated.", _entityType]
                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:contentPanel.frame.size.width - (msgLabelHpadding * 2)];
  }
  UIView *suppressPieSliceLabelsPanel = nil;
  UILabel *suppressPieSliceLabelsDescLabel = nil;
  if (_enablePieChartOptions) {
    UISwitch *suppressPieSliceLabelsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [suppressPieSliceLabelsSwitch setOn:_chartConfig.suppressPieSliceLabels];
    [suppressPieSliceLabelsSwitch bk_addEventHandler:^(id sender) {
      _chartConfig.suppressPieSliceLabels = suppressPieSliceLabelsSwitch.on;
    } forControlEvents:UIControlEventTouchUpInside];
    UILabel *suppressPieSliceLabelsLabel = [PEUIUtils labelWithKey:@"Suppress pie slice labels"
                                                              font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0]
                                                                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                   backgroundColor:[UIColor clearColor]
                                                         textColor:[UIColor blackColor]
                                               verticalTextPadding:3.0];
    suppressPieSliceLabelsDescLabel = [PEUIUtils labelWithAttributeText:AS(@"Pie slice labels may become difficult to read or obscure the view of small slices.  This option prevents the labels from displaying.")
                                                                            font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                        fontForHeightCalculation:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                 backgroundColor:[UIColor clearColor]
                                                                       textColor:[UIColor darkGrayColor]
                                                             verticalTextPadding:0.0
                                                                      fitToWidth:contentPanel.frame.size.width - 15.0 - ([PEUIUtils iphoneXSafeInsetsSide] * 2)];
    suppressPieSliceLabelsPanel = [PEUIUtils panelWithWidthOf:1.0
                                               relativeToView:contentPanel
                                                  fixedHeight:(suppressPieSliceLabelsLabel.frame.size.height + [_uitoolkit verticalPaddingForButtons])];
    [suppressPieSliceLabelsPanel setBackgroundColor:[UIColor whiteColor]];
    [PEUIUtils placeView:suppressPieSliceLabelsLabel
              inMiddleOf:suppressPieSliceLabelsPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:15.0 + [PEUIUtils iphoneXSafeInsetsSide]];
    [PEUIUtils placeView:suppressPieSliceLabelsSwitch
              inMiddleOf:suppressPieSliceLabelsPanel
           withAlignment:PEUIHorizontalAlignmentTypeRight
                hpadding:15.0 + [PEUIUtils iphoneXSafeInsetsSide]];
    [PEUIUtils styleViewForIpad:suppressPieSliceLabelsPanel];
  }
  UIButton *clearButton = nil;
  if (_clearButtonTitle) {
    clearButton = [PEUIUtils buttonWithKey:_clearButtonTitle
                                      font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:34.0]
                                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]]
                           backgroundColor:[UIColor bootstrapPrimary]
                                 textColor:[UIColor whiteColor]
              disabledStateBackgroundColor:nil
                    disabledStateTextColor:nil
                           verticalPadding:24.0
                         horizontalPadding:26.0
                              cornerRadius:3.0
                                    target:nil
                                    action:nil];
    [clearButton bk_addEventHandler:^(id sender) {
      [self clear];
    } forControlEvents:UIControlEventTouchUpInside];
  }
  
  // place views
  UIView *topView;
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:heading
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:labelHpadding];
  totalHeight += heading.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding;
  vpadding = 20.0;
  topView = heading;
  if (veryFirstDateLabel) {
    [PEUIUtils placeView:veryFirstDateLabel
                   below:heading
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += veryFirstDateLabel.frame.size.height + vpadding;
    vpadding = 2.0;
    topView = veryFirstDateLabel;
  }
  [PEUIUtils placeView:startDateTableView
                 below:topView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += startDateTableView.frame.size.height + vpadding;
  vpadding = 0.0;
  [PEUIUtils placeView:startDateMsgLabel
                 below:startDateTableView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:msgLabelHpadding];
  totalHeight += startDateMsgLabel.frame.size.height + vpadding;
  vpadding = 15.0;
  topView = startDateMsgLabel;
  
  [PEUIUtils placeView:boundedEndDateSwitchPanel
                 below:startDateMsgLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += boundedEndDateSwitchPanel.frame.size.height + vpadding;
  topView = boundedEndDateSwitchPanel;
  if (veryLastDateLabel) {
    [PEUIUtils placeView:veryLastDateLabel
                   below:boundedEndDateSwitchPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += veryLastDateLabel.frame.size.height + vpadding;
    vpadding = 2.0;
    topView = veryLastDateLabel;
  }
  if (endDateTableView) {
    [PEUIUtils placeView:endDateTableView
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeight += endDateTableView.frame.size.height + vpadding;
    vpadding = 0.0;
    topView = endDateTableView;
  }
  if (endDateMsgLabel) {
    [PEUIUtils placeView:endDateMsgLabel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += endDateMsgLabel.frame.size.height + vpadding;
    topView = endDateMsgLabel;
  }
  if (_enableLineChartOptions) {
    vpadding = 15.0;
    [PEUIUtils placeView:aggregateByTableView
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeight += aggregateByTableView.frame.size.height + vpadding;
    vpadding = 0.0;
    [PEUIUtils placeView:aggregateByMsgLabel
                   below:aggregateByTableView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += aggregateByMsgLabel.frame.size.height + vpadding;
    topView = aggregateByMsgLabel;
  }
  if (_enablePieChartOptions) {
    vpadding = 15.0;
    [PEUIUtils placeView:suppressPieSliceLabelsPanel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    totalHeight += suppressPieSliceLabelsPanel.frame.size.height + vpadding;
    vpadding = 4.0;
    [PEUIUtils placeView:suppressPieSliceLabelsDescLabel
                   below:suppressPieSliceLabelsPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += suppressPieSliceLabelsDescLabel.frame.size.height + vpadding;
    topView = suppressPieSliceLabelsDescLabel;
  }
  if (clearButton) {
    vpadding = 18.0;
    [PEUIUtils placeView:clearButton
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:msgLabelHpadding];
    totalHeight += clearButton.frame.size.height + vpadding;
  }  
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Done and clear-or-cancel

- (void)done {
  if (_boundedEndDateSwitchView.on && [_chartConfig.endDate compare:_chartConfig.startDate] == NSOrderedAscending) {
    [PEUIUtils showWarningAlertWithMsgs:nil
                                  title:@"Oops."
                       alertDescription:[PEUIUtils attributedTextWithTemplate:@"The %@ cannot be earlier than the Range start date."
                                                                 textToAccent:@"Range end date"
                                                               accentTextFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleSubheadline]]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{}
                         relativeToView:[PEUIUtils parentViewForAlertsForController:self]];
  } else {
    _chartConfig.updatedAt = [NSDate date];
    _doneBlk(_chartConfig);
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)clear {
   _clearBlk();
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  DDLogDebug(@"chart ID: [%@]", _chartConfig.chartId);
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  if (_navbarTitle) {
    [navItem setTitle:_navbarTitle];
  } else {
    [navItem setTitle:@"All Charts Config"];
  }
  UIBarButtonItem *cancelButton =
  [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                   style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(cancel)];
  UIBarButtonItem *doneButton =
  [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                   style:UIBarButtonItemStyleDone
                                  target:self
                                  action:@selector(done)];
  [navItem setLeftBarButtonItem:cancelButton];
  [navItem setRightBarButtonItem:doneButton];
}

@end
