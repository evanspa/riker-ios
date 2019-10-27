//
//  RGeneralInfoController.m
//  riker-ios
//
//  Created by PEVANS on 3/30/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RGeneralInfoController.h"
#import "RCoordinatorDao.h"
#import "PEUIToolkit.h"
#import "RPanelToolkit.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "NSString+RAdditions.h"
#import "UIColor+RAdditions.h"
#import "PELocalDao.h"
#import "PELMUser.h"
#import "PEUIUtils.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RMovement.h"
#import "PEUtils.h"
#import "RLogging.h"
@import Firebase;

@implementation RGeneralInfoController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  NSMutableDictionary *_toggles;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"General Info"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _toggles = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
}

- (void)viewDidAppear:(BOOL)animated {
  if ([self needsRepaint]) {
    [_toggles removeAllObjects];
  }
  [super viewDidAppear:animated];
}

#pragma mark - Helpers

- (UIView *)movementsButtonAndMsgRelativeToView:(UIView *)relativeToView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  ButtonMaker buttonMaker = [_uitoolkit systemButtonMaker];
  NSMutableAttributedString *attrMessage =
  [[NSMutableAttributedString  alloc] initWithString:@"From here you can browse the available movements and see how Riker maps the muscles hit by each one."];
  UIFont *fontForHeightCalculation = [UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UIView *movementsMsgPanel = [PEUIUtils leftPaddingMessageWithAttributedText:attrMessage
                                                     fontForHeightCalculation:fontForHeightCalculation
                                                               relativeToView:relativeToView];
  UIButton *movementsButton = buttonMaker(@"Movements", nil, nil);
  [[movementsButton layer] setCornerRadius:0.0];
  [movementsButton bk_addEventHandler:^(id sender) {
    UIViewController *movementsScreen =
    [_screenToolkit newMovementsScreenMakerWithTitle:@"Movements"
                                  itemSelectedAction:^(RMovement *selectedMovement, NSIndexPath *indexPath, UIViewController *controller, UITableView *tableView) {
                                    UIViewController *movementInfoScreen = [_screenToolkit newMovementInfoScreenMakerWithMovement:selectedMovement
                                                                                                            enableStartSetButtons:YES]();
                                    [self.navigationController pushViewController:movementInfoScreen animated:YES];
                                  } initialSelectedMovement:nil]();
    [self.navigationController pushViewController:movementsScreen animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils setFrameWidthOfView:movementsButton ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils addDisclosureIndicatorToButton:movementsButton];
  [PEUIUtils placeView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info-icon"]]
            inMiddleOf:movementsButton
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0 + iphoneXSafeInsetsSideVal];
  return [PEUIUtils panelWithColumnOfViews:@[movementsButton, movementsMsgPanel]
               verticalPaddingBetweenViews:4.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];    
  CGFloat headingHpadding = 15.0 + iphoneXSafeInsetsSideVal;
  UILabel *headingLabel = [PEUIUtils labelWithKey:@"From here you can learn how Riker calculates how your workouts impact the various muscles of your body, as well as dive into the details of how Riker maps the muscles hit by the available movements."
                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:0.0
                                       fitToWidth:contentPanel.frame.size.width - (headingHpadding * 2)];
  
  NSDictionary *attrs = [PEUIUtils paragraphBeforeSpacingAttrs];
  UIFont *boldFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *distDesc = [[NSMutableAttributedString alloc] init];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Every movement in Riker hits a set of muscles.  There are %@ hit and "
                                                            textToAccent:@"primary muscles"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ hit."
                                                            textToAccent:@"secondary muscles"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nFor example, the primary muscles hit with %@ are:  the upper and lower chest muscles.  The secondary muscles hit are: the three heads of the tricep muscle group."
                                                            textToAccent:@"bench press"
                                                          accentTextFont:boldFont
                                                                   attrs:attrs]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nRiker distributes %@ of the total weight lifted and reps of a set to the primary muscles hit, and distributes "
                                                            textToAccent:@"80%"
                                                          accentTextFont:boldFont
                                                                   attrs:attrs]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"the remaining %@ to the secondary muscles hit."
                                                            textToAccent:@"20%"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:ASA(@"\nIf there are multiple primary muscles and multiple secondary muscles hit, the assigned weight and reps are distributed across them evenly.", attrs)];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\nSo if you do a set of %@ on bench press, the total weight lifted is: "
                                                            textToAccent:@"10 reps of 135 lbs"
                                                          accentTextFont:boldFont
                                                                   attrs:attrs]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@.  80%% of that weight ("
                                                            textToAccent:@"1,350 lbs"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@) and 80%% of the reps ("
                                                            textToAccent:@"1,080 lbs"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@) are assigned to the primary muscles; the upper and lower chest.  Since there are 2 primary muscles hit, they are each assigned "
                                                            textToAccent:@"8 reps"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@.  The secondary muscles hit are assigned 20%% of the total weight lifted and reps ("
                                                            textToAccent:@"540 lbs and 4 reps"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@).  Since there are 3 secondary muscles hit (medial, lateral and long heads of the tricep), they are each assigned "
                                                            textToAccent:@"270 lbs and 2 reps"
                                                          accentTextFont:boldFont]];
  [distDesc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@."
                                                            textToAccent:@"90 lbs and 0.67 reps"
                                                          accentTextFont:boldFont]];
  
  UIView *movementsPanel = [self movementsButtonAndMsgRelativeToView:contentPanel];
  
  NSArray *howWeightLiftedDistributedViews =
  [PEUIUtils expandingInfoPanelWithContentData:@[@"How does Riker distribute the weight lifted, or the reps performed, of a set to the impacted muscles?",
                                                 distDesc,
                                                 @"info-icon",
                                                 ^{ [RUtils logExpandingInfoContentViewed:@"how_weight_reps_distributed"]; }]
                               additionalViews:nil
                             contentButtonFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                      contentButtonLabelStyler:^(UILabel *buttonTitleLabel) {
                        [buttonTitleLabel setTextAlignment:NSTextAlignmentLeft];
                      }
                                     textColor:[UIColor rikerAppBlack]
                               backgroundColor:[UIColor whiteColor]
                              chevronImageName:@"gray-down-chevron-small-icon"
                                  contentIndex:0
                                       toggles:_toggles
                 baseControllerDisplayPanelBlk:^UIView *{return [self displayPanel];}
                         testForBelowViewsMove:nil
                                    belowViews:@[movementsPanel]
                      indexOfFirstBelowViewBlk:nil
                       extraContentPanelHeight:0.0
                                relativeToView:contentPanel];
  UIButton *howWeightLiftedDistributedButton = howWeightLiftedDistributedViews[0];
  UIView *howWeightLiftedDistributedContentPanel = howWeightLiftedDistributedViews[1];
  // place views
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingLabel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:headingHpadding];
  totalHeight += headingLabel.frame.size.height + [RUIUtils contentPanelTopPadding];
  CGFloat vpadding = 20.0;
  [PEUIUtils placeView:howWeightLiftedDistributedButton
                 below:headingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += howWeightLiftedDistributedButton.frame.size.height + vpadding;
  [PEUIUtils placeView:howWeightLiftedDistributedContentPanel
                 below:howWeightLiftedDistributedButton
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:0.0];
  vpadding = 30.0;
  [PEUIUtils placeView:movementsPanel
                 below:howWeightLiftedDistributedContentPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:0.0];
  totalHeight += movementsPanel.frame.size.height + vpadding;
  
  // set height of contentPanel
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(YES), @(YES)];
}

@end
