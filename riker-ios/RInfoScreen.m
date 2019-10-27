//
//  RInfoScreen.m
//  riker-ios
//
//  Created by PEVANS on 12/21/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RInfoScreen.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "UIColor+RAdditions.h"
#import "RUIUtils.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "RUtils.h"
@import Firebase;

@implementation RInfoScreen {
  NSString *_title;
  NSString *_heading;
  NSArray *_sections;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  NSMutableDictionary *_toggles;
  NSMutableArray *_allViews;
  NSInteger _numSections;
  void(^_viewDidLoadBlk)(void);
}

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
            heading:(NSString *)heading
           sections:(NSArray *)sections
          uitoolkit:(PEUIToolkit *)uitoolkit
      screenToolkit:(RScreenToolkit *)screenToolkit
     viewDidLoadBlk:(void(^)(void))viewDidLoadBlk {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:title];
  if (self) {
    _title = title;
    _heading = heading;
    _sections = sections;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _numSections = _sections.count;
    _toggles = [NSMutableDictionary dictionaryWithCapacity:_numSections];
    _allViews = [NSMutableArray arrayWithCapacity:_numSections * 2];
    _viewDidLoadBlk = viewDidLoadBlk;
  }
  return self;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  UILabel *headingLabel = nil;
  if (_heading) {
    headingLabel = [PEUIUtils labelWithKey:_heading
                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                                       iphone6Width:UIFontTextStyleTitle3
                                                                                                   iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                               ipad:UIFontTextStyleTitle1]]
                           backgroundColor:[UIColor clearColor]
                                 textColor:[UIColor whiteColor] //[UIColor rikerAppBlack]
                       verticalTextPadding:15.0
                                fitToWidth:contentPanel.frame.size.width - 16.0 - (iphoneXSafeInsetsSideVal * 2)];
  }
  // place views
  CGFloat totalHeight = 0.0;
  UIView *topView = nil;
  if (headingLabel) {
    [PEUIUtils placeView:headingLabel
                 atTopOf:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:[RUIUtils contentPanelTopPadding]
                hpadding:8.0 + iphoneXSafeInsetsSideVal];
    totalHeight += headingLabel.frame.size.height + [RUIUtils contentPanelTopPadding];
    topView = headingLabel;
  }
  NSInteger contentIndex = 0;
  CGFloat initialExtraVPadding = [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:5.0 iphone6PlusWidth:10.0 ipad:15.0];
  CGFloat extraVPadding = [PEUIUtils valueIfiPhone5Width:0.0 iphone6Width:0.0 iphone6PlusWidth:10.0 ipad:15.0];
  for (NSArray *contentData in _sections) {
    NSArray *views = [PEUIUtils expandingInfoPanelWithContentData:contentData
                                                  additionalViews:nil
                                                contentButtonFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                                                                            iphone6Width:UIFontTextStyleSubheadline
                                                                                                                        iphone6PlusWidth:UIFontTextStyleBody
                                                                                                                                    ipad:UIFontTextStyleTitle3]]
                                         contentButtonLabelStyler:nil
                                                        textColor:[UIColor rikerAppBlack]
                                                  backgroundColor:[UIColor whiteColor]
                                                 chevronImageName:@"gray-down-chevron-small-icon"
                                                     contentIndex:contentIndex
                                                          toggles:_toggles
                                    baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                                            testForBelowViewsMove:^BOOL{ return (contentIndex + 1) < _numSections; }
                                                       belowViews:_allViews
                                         indexOfFirstBelowViewBlk:^NSInteger(NSInteger contentIndex){return (contentIndex + 1)*2;}
                                          extraContentPanelHeight:[PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:5.0 iphone6PlusWidth:8.0 ipad:20.0]
                                                   relativeToView:contentPanel];
    UIView *contentButton = views[0];
    UIView *contentDescriptionPanel = views[1];
    [_allViews addObject:contentButton];
    [_allViews addObject:contentDescriptionPanel];
    if (topView) {
      [PEUIUtils placeView:contentButton
                     below:topView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
   alignmentRelativeToView:contentPanel
                  vpadding:10.0 + initialExtraVPadding + extraVPadding
                  hpadding:0.0];
    } else {
      [PEUIUtils placeView:contentButton
                   atTopOf:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeCenter
                  vpadding:[RUIUtils contentPanelTopPadding]
                  hpadding:0.0];
    }
    totalHeight += contentButton.frame.size.height + 25.0;
    [PEUIUtils placeView:contentDescriptionPanel
                   below:contentButton
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    topView = contentDescriptionPanel;
    contentIndex++;
    initialExtraVPadding = 0.0;
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO), @(YES)];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  //[[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[self view] setBackgroundColor:[UIColor rikerAppBlack]];
  if (_viewDidLoadBlk) {
    _viewDidLoadBlk();
  }
}

@end
