//
//  RMovementInfoController.m
//  riker-ios
//
//  Created by PEVANS on 3/31/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RMovementInfoController.h"
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
#import "RMovementVariant.h"
#import "PEUtils.h"
#import "RLogging.h"
#import "RMuscle.h"
#import "RMuscleAlias.h"
#import "RMuscleGroup.h"
#import "RMovementAlias.h"
#import "RWatchUtils.h"
@import Firebase;

@implementation RMovementInfoController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  RPanelToolkit *_panelToolkit;
  RMovement *_movement;
  BOOL _enableStartSetButtons;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                      movement:(RMovement *)movement
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit
                  panelToolkit:(RPanelToolkit *)panelToolkit
         enableStartSetButtons:(BOOL)enableStartSetButtons {
  self = [super initWithRequireRepaintNotifications:nil
                                        screenTitle:@"Movement Info"
                                    screenNameToLog:[NSString stringWithFormat:@"Movement Info - %@", movement.canonicalName]];
  if (self) {
    _coordDao = coordDao;
    _movement = movement;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _panelToolkit = panelToolkit;
    _enableStartSetButtons = enableStartSetButtons;
  }
  return self;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [RUtils logEvent:kFIREventViewItem params:@{ kFIRParameterItemCategory : @"movements",
                                               kFIRParameterItemID : _movement.localMasterIdentifier,
                                               kFIRParameterItemName : _movement.canonicalName }];
}

#pragma mark - Helpers

- (UIButton *)startSetButton {
  return [PEUIUtils buttonWithKey:@"Start Set"
                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                  backgroundColor:[UIColor bootstrapPrimary]
                        textColor:[UIColor whiteColor]
     disabledStateBackgroundColor:nil
           disabledStateTextColor:nil
                  verticalPadding:10
                horizontalPadding:15.0
                     cornerRadius:3.0
                           target:nil
                           action:nil];
}

- (UIView *)variantPanelWithMovement:(RMovement *)movement
                             variant:(RMovementVariant *)variant
                      relativeToView:(UIView *)relativeToView {
  UIView *panel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [PEUIUtils adjustWidthOfView:panel withValue:(-2 * [PEUIUtils iphoneXSafeInsetsSide])];
  [panel setBackgroundColor:[UIColor whiteColor]];
  CGFloat hpadding = 15.0;
  UILabel *variantNameLabel = [PEUIUtils labelWithKey:variant.name
                                                font:[PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor rikerAppBlack]
                                 verticalTextPadding:0.0
                                          fitToWidth:panel.frame.size.width - (hpadding * 2)];
  UIButton *startSetButton = nil;
  if (_enableStartSetButtons) {
    startSetButton = [self startSetButton];
    [startSetButton bk_addEventHandler:^(id sender) {
      UIViewController *enterRepsController
      = [_screenToolkit newEnterRepsScreenMakerWithMovement:movement
                                                    variant:variant
                                                dismissable:YES]();
      [self presentViewController:[PEUIUtils navigationControllerWithController:enterRepsController
                                                            navigationBarHidden:NO]
                         animated:YES
                       completion:nil];
    } forControlEvents:UIControlEventTouchUpInside];
  }
  // place views
  CGFloat totalHeight = 0.0;
  CGFloat vpadding = 15.0;
  [PEUIUtils placeView:variantNameLabel atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:hpadding];
  totalHeight += variantNameLabel.frame.size.height + vpadding;
  totalHeight += 15.0; // bottom margin
  [PEUIUtils setFrameHeight:totalHeight ofView:panel];
  if (startSetButton) {
    [PEUIUtils placeView:startSetButton inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:25.0];
  }
  return panel;
}

- (UIView *)musclePanelWithMuscle:(RMuscle *)muscle
                 muscleGroupsDict:(NSDictionary *)muscleGroupsDict
                   relativeToView:(UIView *)relativeToView {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  RMuscleGroup *muscleGroup = muscleGroupsDict[muscle.muscleGroupId];
  UIView *musclePanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:0.0];
  [PEUIUtils adjustWidthOfView:musclePanel withValue:(-2 * iphoneXSafeInsetsSideVal)];
  [musclePanel setBackgroundColor:[UIColor whiteColor]];
  CGFloat hpadding = 15.0;
  UILabel *muscleNameLabel = [PEUIUtils labelWithKey:muscle.canonicalName
                                                font:[PEUIUtils boldFontForTextStyle:[PEUIUtils bodyFontTextStyle]]
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor rikerAppBlack]
                                 verticalTextPadding:0.0
                                          fitToWidth:musclePanel.frame.size.width - (hpadding * 2)];
  UILabel *muscleGroupLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"muscle group: %@"
                                                                                         textToAccent:muscleGroup.name
                                                                                       accentTextFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                                      accentTextColor:[UIColor blackColor]]
                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor rikerAppBlack]
                                            verticalTextPadding:0.0
                                                     fitToWidth:musclePanel.frame.size.width - (hpadding * 2)];
  NSArray *muscleAliases = [_coordDao muscleAliasesForMuscleId:muscle.localMasterIdentifier error:errorBlk];
  NSInteger numMuscleAliases = muscleAliases.count;
  NSMutableString *muscleAliasesString = nil;
  if (numMuscleAliases > 0) {
    muscleAliasesString = [NSMutableString string];
    for (NSInteger i = 0; i < numMuscleAliases; i++) {
      RMuscleAlias *alias = muscleAliases[i];
      [muscleAliasesString appendString:alias.alias];
      if (i + 1 < numMuscleAliases) {
        [muscleAliasesString appendString:@", "];
      }
    }
  }
  UILabel *muscleAliasesLabel = nil;
  if (muscleAliasesString) {
    muscleAliasesLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"%@: %%@", numMuscleAliases > 1 ? @"aliases" : @"alias"]
                                                                                    textToAccent:muscleAliasesString
                                                                                  accentTextFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                                 accentTextColor:[UIColor blackColor]]
                                                      font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                           backgroundColor:[UIColor clearColor]
                                                 textColor:[UIColor rikerAppBlack]
                                       verticalTextPadding:0.0
                                                fitToWidth:musclePanel.frame.size.width - (hpadding * 2)];
  }
  // place views
  CGFloat totalHeight = 0.0;
  CGFloat vpadding = 15.0;
  [PEUIUtils placeView:muscleNameLabel atTopOf:musclePanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:hpadding];
  totalHeight += muscleNameLabel.frame.size.height + vpadding;
  vpadding = 8.0;
  [PEUIUtils placeView:muscleGroupLabel below:muscleNameLabel onto:musclePanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
  totalHeight += muscleGroupLabel.frame.size.height + vpadding;
  if (muscleAliasesLabel) {
    vpadding = 4.0;
    [PEUIUtils placeView:muscleAliasesLabel below:muscleGroupLabel onto:musclePanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:vpadding hpadding:0.0];
    totalHeight += muscleAliasesLabel.frame.size.height + vpadding;
  }
  totalHeight += 15.0; // bottom margin
  [PEUIUtils setFrameHeight:totalHeight ofView:musclePanel];
  return musclePanel;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  NSDictionary *muscleGroupsDict = [RUtils dictFromMasterEntitiesArray:[_coordDao muscleGroupsWithError:errorBlk]];
  CGFloat headingHpadding = 15.0 + iphoneXSafeInsetsSideVal;
  UILabel *headingLabel = [PEUIUtils labelWithKey:_movement.canonicalName
                                             font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleTitle3
                                                                                                            iphone6Width:UIFontTextStyleTitle3
                                                                                                        iphone6PlusWidth:UIFontTextStyleTitle2
                                                                                                                    ipad:UIFontTextStyleTitle1]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor rikerAppBlack]
                              verticalTextPadding:5.0
                                       fitToWidth:contentPanel.frame.size.width - (headingHpadding * 2)];
  NSArray *variants = nil;
  BOOL hasVariants = _movement.variantMask && _movement.variantMask.integerValue != 0;
  if (hasVariants) {
    variants = [_coordDao movementVariantsForMovementVariantMask:_movement.variantMask error:errorBlk];
  }
  UIButton *startSetButton = nil;
  if (_enableStartSetButtons) {
    startSetButton = [self startSetButton];
    [startSetButton bk_addEventHandler:^(id sender) {
      UIViewController *controller;
      if (hasVariants) {
        controller = [_screenToolkit newSelectMovementVariantScreenMakerWithBodySegmentName:nil
                                                                                muscleGroup:nil
                                                                                   movement:_movement
                                                                                cancellable:YES
                                                                       enterRepsDismissable:YES]();
      } else {
        controller = [_screenToolkit newEnterRepsScreenMakerWithMovement:_movement
                                                                 variant:nil
                                                             dismissable:YES]();
      }
      [self presentViewController:[PEUIUtils navigationControllerWithController:controller
                                                            navigationBarHidden:NO]
                         animated:YES
                       completion:nil];
    } forControlEvents:UIControlEventTouchUpInside];
  }
  CGFloat leftHpadding = 8.0 + iphoneXSafeInsetsSideVal;
  UILabel *(^theFollowingEntitiesLabel)(NSInteger, NSString *, NSString *) = ^UILabel * (NSInteger numEntities, NSString *prefix, NSString *entityType) {    
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"The following "];
    [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ the ", numEntities > 1 ? @"are" : @"is"]]];
    NSString *muscleType = [NSString stringWithFormat:@"%@%@", entityType, numEntities > 1 ? @"s" : @""];
    [attrStr appendAttributedString:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"%%@ %@ the ", prefix]
                                                             textToAccent:muscleType
                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
    [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ movement", _movement.canonicalName]]];
    return [PEUIUtils labelWithAttributeText:attrStr
                                        font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                             backgroundColor:[UIColor clearColor]
                                   textColor:[UIColor rikerAppBlack]
                         verticalTextPadding:5.0
                                  fitToWidth:contentPanel.frame.size.width - (leftHpadding * 2)];
  };
  UIView *(^musclesPanel)(NSArray *) = ^UIView * (NSArray *muscles) {
    NSMutableArray *musclePanels = [NSMutableArray arrayWithCapacity:muscles.count];
    for (RMuscle *muscle in muscles) {
      [musclePanels addObject:[self musclePanelWithMuscle:muscle
                                         muscleGroupsDict:muscleGroupsDict
                                           relativeToView:contentPanel]];
    }
    return [PEUIUtils panelWithColumnOfViews:musclePanels
                 verticalPaddingBetweenViews:2.0
                              viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  };
  UILabel *bodyLiftLabel = nil;
  if (_movement.isBodyLift) {
    NSDecimalNumber *weightPercentage = _movement.percentageOfBodyWeight;
    if (!weightPercentage) {
      weightPercentage = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    }
    bodyLiftLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"%@ is a body-lift movement that Riker estimates to use %%@ of your body weight.", [_movement.canonicalName sentenceCase]]
                                                                               textToAccent:[NSString stringWithFormat:@"%@%%", [weightPercentage decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]]]
                                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                 font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                      backgroundColor:[UIColor clearColor]
                                            textColor:[UIColor rikerAppBlack]
                                  verticalTextPadding:0.0
                                           fitToWidth:contentPanel.frame.size.width - (leftHpadding * 2)];
  } else if (hasVariants) {
    for (RMovementVariant *variant in variants) {
      if (variant.localMasterIdentifier.integerValue == BODY_MOVEMENT_VARIANT_ID) {
        NSDecimalNumber *weightPercentage = _movement.percentageOfBodyWeight;
        if (!weightPercentage) {
          weightPercentage = [NSDecimalNumber decimalNumberWithString:@"1.0"];
        }
        bodyLiftLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:[NSString stringWithFormat:@"%@ has a body-lift variant.  When using this variant, Riker estimates that %%@ of your body weight is used.", [_movement.canonicalName sentenceCase]]
                                                                                   textToAccent:[NSString stringWithFormat:@"%@%%", [weightPercentage decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]]]
                                                                                 accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                     font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                          backgroundColor:[UIColor clearColor]
                                                textColor:[UIColor rikerAppBlack]
                                      verticalTextPadding:0.0
                                               fitToWidth:contentPanel.frame.size.width - (leftHpadding * 2)];
        break;
      }
    }
  }
  UILabel *movementAliasesLabel = nil;
  NSArray *movementAliases = [_coordDao movementAliasesForMovementId:_movement.localMasterIdentifier error:errorBlk];
  if (movementAliases.count > 0) {
    NSMutableAttributedString *aliases = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ is also known by the following name%@: ", _movement.canonicalName.sentenceCase, movementAliases.count > 1 ? @"s" : @""]];
    for (NSInteger i = 0; i < movementAliases.count; i++) {
      RMovementAlias *movementAlias = movementAliases[i];
      [aliases appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@"
                                                               textToAccent:movementAlias.alias
                                                             accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
      if (i + 2 < movementAliases.count) {
        [aliases appendAttributedString:AS(@", ")];
      } else if (i + 1 < movementAliases.count) {
        [aliases appendAttributedString:AS(@" and ")];
      }
    }
    [aliases appendAttributedString:AS(@".")];
    movementAliasesLabel = [PEUIUtils labelWithAttributeText:aliases
                                                        font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor rikerAppBlack]
                                         verticalTextPadding:0.0
                                                  fitToWidth:contentPanel.frame.size.width - (leftHpadding * 2)];
  }
  
  NSArray *primaryMuscles = [_coordDao primaryMusclesForMovementId:_movement.localMasterIdentifier error:errorBlk];
  UIView *primaryMusclesPanel = musclesPanel(primaryMuscles);
  UILabel *primaryMusclesHeadingLabel = theFollowingEntitiesLabel(primaryMuscles.count, @"hit by", @"primary muscle");

  NSArray *secondaryMuscles = [_coordDao secondaryMusclesForMovementId:_movement.localMasterIdentifier error:errorBlk];
  UIView *secondaryMusclesPanel = nil;
  UILabel *secondaryMusclesHeadingLabel = nil;
  if (secondaryMuscles.count > 0) {
    secondaryMusclesPanel = musclesPanel(secondaryMuscles);
    secondaryMusclesHeadingLabel = theFollowingEntitiesLabel(secondaryMuscles.count, @"hit by", @"secondary muscle");
  }
  
  UIView *variantsLabel = nil;
  UIView *variantsPanel = nil;
  if (hasVariants) {
    variantsLabel = theFollowingEntitiesLabel(variants.count, @"available for", @"variant");
    NSMutableArray *variantPanels = [NSMutableArray arrayWithCapacity:variants.count];
    for (RMovementVariant *variant in variants) {
      [variantPanels addObject:[self variantPanelWithMovement:_movement
                                                      variant:variant
                                               relativeToView:contentPanel]];
    }
    variantsPanel = [PEUIUtils panelWithColumnOfViews:variantPanels
                          verticalPaddingBetweenViews:2.0
                                       viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  }
  
  // place views
  CGFloat totalHeight = 0.0;
  [PEUIUtils placeView:headingLabel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:headingHpadding];
  totalHeight += headingLabel.frame.size.height + [RUIUtils contentPanelTopPadding];
  UIView *topView = headingLabel;
  CGFloat vpadding = 15.0;
  if (startSetButton) {
    [PEUIUtils placeView:startSetButton
                   below:headingLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:leftHpadding];
    totalHeight += startSetButton.frame.size.height + vpadding;
    topView = startSetButton;
  }
  if (bodyLiftLabel) {
    [PEUIUtils placeView:bodyLiftLabel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:leftHpadding];
    totalHeight += bodyLiftLabel.frame.size.height + vpadding;
    topView = bodyLiftLabel;
  }
  if (movementAliasesLabel) {
    [PEUIUtils placeView:movementAliasesLabel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:leftHpadding];
    totalHeight += movementAliasesLabel.frame.size.height + vpadding;
    topView = movementAliasesLabel;
  }
  [PEUIUtils placeView:primaryMusclesHeadingLabel
                 below:topView
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:leftHpadding];
  totalHeight += primaryMusclesHeadingLabel.frame.size.height + vpadding;
  vpadding = 4.0;
  [PEUIUtils placeView:primaryMusclesPanel
                 below:primaryMusclesHeadingLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:vpadding
              hpadding:iphoneXSafeInsetsSideVal];
  totalHeight += primaryMusclesPanel.frame.size.height + vpadding;
  topView = primaryMusclesPanel;
  if (secondaryMusclesHeadingLabel) {
    vpadding = 15.0;
    [PEUIUtils placeView:secondaryMusclesHeadingLabel
                   below:primaryMusclesPanel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:leftHpadding];
    totalHeight += secondaryMusclesHeadingLabel.frame.size.height + vpadding;
    vpadding = 4.0;
    [PEUIUtils placeView:secondaryMusclesPanel
                   below:secondaryMusclesHeadingLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:iphoneXSafeInsetsSideVal];
    totalHeight += secondaryMusclesPanel.frame.size.height + vpadding;
    topView = secondaryMusclesPanel;
  }
  if (variantsLabel) {
    vpadding = 15.0;
    [PEUIUtils placeView:variantsLabel
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:leftHpadding];
    totalHeight += variantsLabel.frame.size.height + vpadding;
    vpadding = 4.0;
    [PEUIUtils placeView:variantsPanel
                   below:variantsLabel
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:iphoneXSafeInsetsSideVal];
    totalHeight += variantsPanel.frame.size.height + vpadding;
    topView = variantsPanel;
  }
  
  // set height of contentPanel
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(YES), @(YES)];
}

@end
