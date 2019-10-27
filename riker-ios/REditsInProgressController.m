//
//  REditsInProgressController.m
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "REditsInProgressController.h"
#import "RCoordinatorDao.h"
#import "PEUIToolkit.h"
#import "RScreenToolkit.h"
#import "AppDelegate.h"
#import "RUtils.h"
#import "RUIUtils.h"
#import "UIColor+RAdditions.h"
#import "RMovement.h"
#import "PELMUser.h"
#import "PELocalDao.h"
#import "RAppNotificationNames.h"
@import Firebase;

@implementation REditsInProgressController {
  id<RCoordinatorDao> _coordDao;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:@[RAppReauthReqdNotification,
                                                      RAppReauthNotification]
                                        screenTitle:@"Unsynced Edits"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

#pragma mark - Helpers

- (UIView *)paddedEipsInfoMessageRelativeToView:(UIView *)relativeToView {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"From here you can drill into all of your items that have unsynced edits."
                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:relativeToView.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (UIView *)syncAllInfoMessageRelativeToView:(UIView *)relativeToView {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"This action will upload all your unsynced edits to your account."
                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:relativeToView.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (UIView *)cannotSyncAllWhileUnauthInfoMessageRelativeToView:(UIView *)relativeToView {
  CGFloat leftPadding = 8.0;
  UILabel *infoMsgLabel =
  [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"You are not currently authenticated.  This action is disabled.  To re-authenticate, head over to the %@ tab."
                                                             textToAccent:@"Account"
                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                    backgroundColor:[UIColor clearColor]
                          textColor:[UIColor darkGrayColor]
                verticalTextPadding:3.0
                         fitToWidth:relativeToView.frame.size.width - (leftPadding + 3.0)];
  return [PEUIUtils leftPadView:infoMsgLabel padding:leftPadding];
}

- (UIView *)paddedNoEipsInfoMessageRelativeToView:(UIView *)relativeToView {
  CGFloat sideMargin = [PEUIUtils valueIfiPhone5Width:15.0 iphone6Width:15.0 iphone6PlusWidth:18.0 ipad:25.0];
  UILabel *infoMsgLabel = [PEUIUtils labelWithKey:@"You currently have no unsynced items."
                                             font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle1]
                                  backgroundColor:[UIColor clearColor]
                                        textColor:[UIColor darkGrayColor]
                              verticalTextPadding:3.0
                                       fitToWidth:relativeToView.frame.size.width - (sideMargin * 2)];
  UIImageView *largeGreenCheckmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green-filled-checkmark-large"]];
  return [PEUIUtils panelWithColumnOfViews:@[infoMsgLabel, largeGreenCheckmark]
               verticalPaddingBetweenViews:25.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeCenter];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0];
  PELMDaoErrorBlk errorBlk = [RUtils localFetchErrorHandlerMaker]();
  PELMUser *user = (PELMUser *)[_coordDao userWithError:errorBlk];
  NSInteger numEipSets = [_coordDao numUnsyncedSetsForUser:user];
  NSInteger numEipBmls = [_coordDao numUnsyncedBmlsForUser:user];
  NSInteger numEipUserSettings = [_coordDao numUnsyncedSettingsForUser:user];
  NSInteger totalNumEips = numEipSets + numEipBmls + numEipUserSettings;
  NSInteger totalNumSyncNeeded = [_coordDao totalNumSyncNeededEntitiesForUser:user];
  UIColor *eipBadgeColor = [UIColor orangeColor];
  UIColor *eipBadgeTextColor = [UIColor blackColor];
  UIButton *setsButton = nil;
  if (numEipSets > 0) {
    setsButton = [PEUIUtils buttonWithLabel:@"Sets"
                                   badgeNum:numEipSets
                                 badgeColor:eipBadgeColor
                             badgeTextColor:eipBadgeTextColor
                          addDisclosureIcon:YES
                                    handler:^{
                                      UIViewController *setsController =
                                      [_screenToolkit newViewUnsyncedSetsScreenMakerWithMovementsBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao movementsWithError:errorBlk]];}
                                                                              allMovementVariantsBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao movementVariantsWithError:errorBlk]];}
                                                                                 movementVariantsBlk:^(RMovement *movement) {
                                                                                   NSArray *movementVariants = [_coordDao movementVariantsWithError:errorBlk];
                                                                                   return [RUtils dictFromMasterEntitiesArray:[RUtils filterMovementVariants:movementVariants usingMask:movement.variantMask.integerValue]];
                                                                                 }
                                                                               originationDevicesBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:errorBlk]];}
                                                                       mostRecentBmlWithNonNilWeight:[_coordDao mostRecentBmlWithNonNilWeightForUser:user error:errorBlk]]();
                                      [PEUIUtils displayController:setsController
                                                    fromController:self
                                                          animated:YES]; }
                                  uitoolkit:_uitoolkit
                             relativeToView:contentPanel];
  }
  UIButton *bmlsButton = nil;
  if (numEipBmls > 0) {
    NSString *bmlTitleAbbrev = @"Body Logs";
    NSString *bmlTitle = @"Body Logs";
    bmlsButton = [PEUIUtils buttonWithLabel:[PEUIUtils objIfiPhone5Width:bmlTitleAbbrev
                                                            iphone6Width:bmlTitleAbbrev
                                                        iphone6PlusWidth:bmlTitle
                                                                    ipad:bmlTitle]
                                   badgeNum:numEipBmls
                                 badgeColor:eipBadgeColor
                             badgeTextColor:eipBadgeTextColor
                          addDisclosureIcon:YES
                                    handler:^{
                                      [PEUIUtils displayController:[_screenToolkit newViewUnsyncedBmlsScreenMakerWithOriginationDevicesBlk:^{return [RUtils dictFromMasterEntitiesArray:[_coordDao originationDevicesWithError:[RUtils localFetchErrorHandlerMaker]()]];}]()
                                                    fromController:self
                                                          animated:YES];
                                    }
                                  uitoolkit:_uitoolkit
                             relativeToView:contentPanel];
  }
  UIButton *userSettingsButton = nil;
  if (numEipUserSettings > 0) {
    PELMUser *user = (PELMUser *)[_coordDao userWithError:[RUtils localFetchErrorHandlerMaker]()];
    userSettingsButton = [PEUIUtils buttonWithLabel:@"Profile and Settings"
                                           badgeNum:numEipUserSettings
                                         badgeColor:eipBadgeColor
                                     badgeTextColor:eipBadgeTextColor
                                  addDisclosureIcon:YES
                                            handler:^{
                                              if ([APP userSettingsOpenFromSettingsScreen]) {
                                                NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
                                                [desc appendAttributedString:[[NSAttributedString alloc] initWithString:@"It looks like you've already got your Profile and Settings open from the "]];
                                                [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ tab.\n\nHead over to the "
                                                                                                      textToAccent:@"Settings"
                                                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
                                                [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"%@ tab to get to your unsynced Profile and Settings."
                                                                                                      textToAccent:@"Settings"
                                                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
                                                [PEUIUtils showWarningAlertWithMsgs:nil
                                                                              title:@"Profile and Settings already open."
                                                                   alertDescription:desc
                                                                descLblHeightAdjust:0.0
                                                                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                        buttonTitle:@"Okay"
                                                                       buttonAction:^{}
                                                                     relativeToView:self.tabBarController.view];
                                              } else {
                                                [APP setUserSettingsOpenFromUnsyncedEditsScreen:YES];
                                                RUserSettings *userSettings = [_coordDao userSettingsForUser:user error:[RUtils localFetchErrorHandlerMaker]()];
                                                [PEUIUtils displayController:[_screenToolkit newUserSettingsDetailScreenMakerWithSettings:userSettings]()
                                                              fromController:self
                                                                    animated:YES];
                                              }
                                            }
                                          uitoolkit:_uitoolkit
                                     relativeToView:contentPanel];
  }
  UIButton *syncAllButton = nil;
  if (totalNumSyncNeeded > 0) {
    syncAllButton = [PEUIUtils buttonWithLabel:@"Upload All"
                                      badgeNum:totalNumSyncNeeded
                                    badgeColor:[UIColor rikerAppBlack]
                                badgeTextColor:[UIColor whiteColor]
                             addDisclosureIcon:NO
                                       handler:^{
                                         [RUtils logEvent:@"upload_all_clicked"];
                                         [RUtils syncAllWithCoordinatorDao:_coordDao
                                                             uiInteraction:YES
                                                                controller:self];
                                       }
                                     uitoolkit:_uitoolkit
                                relativeToView:contentPanel];
  }
  // place the views
  UIView *messagePanel;
  PEUIHorizontalAlignmentType messagePanelHAlignment;
  if (totalNumEips > 0) {
    messagePanel = [self paddedEipsInfoMessageRelativeToView:contentPanel];
    messagePanelHAlignment = PEUIHorizontalAlignmentTypeLeft;
  } else {
    messagePanel = [self paddedNoEipsInfoMessageRelativeToView:contentPanel];
    messagePanelHAlignment = PEUIHorizontalAlignmentTypeCenter;
  }
  [PEUIUtils placeView:messagePanel
               atTopOf:contentPanel
         withAlignment:messagePanelHAlignment
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = messagePanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  UIView *topView = messagePanel;
  CGFloat vpadding = [PEUIUtils valueIfiPhone5Width:7.0 iphone6Width:7.0 iphone6PlusWidth:10.0 ipad:25.0];
  if (setsButton) {
    [PEUIUtils placeView:setsButton
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    topView = setsButton;
    totalHeight += setsButton.frame.size.height + vpadding;
  }
  if (bmlsButton) {
    [PEUIUtils placeView:bmlsButton
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    topView = bmlsButton;
    totalHeight += bmlsButton.frame.size.height + vpadding;
  }
  if (userSettingsButton) {
    [PEUIUtils placeView:userSettingsButton
                   below:topView
                    onto:contentPanel
           withAlignment:PEUIHorizontalAlignmentTypeCenter
 alignmentRelativeToView:contentPanel
                vpadding:vpadding
                hpadding:0.0];
    topView = userSettingsButton;
    totalHeight += userSettingsButton.frame.size.height + vpadding;
  }
  if (totalNumSyncNeeded > 0) {
    vpadding = [PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:25.0 iphone6PlusWidth:30.0 ipad:45.0];
    if ([APP doesUserHaveValidAuthToken]) {
      [PEUIUtils placeView:syncAllButton
                     below:topView
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeCenter
   alignmentRelativeToView:contentPanel
                  vpadding:vpadding
                  hpadding:0.0];
      totalHeight += syncAllButton.frame.size.height + vpadding;
      UIView *syncAllMessage = [self syncAllInfoMessageRelativeToView:contentPanel];
      [PEUIUtils placeView:syncAllMessage
                     below:syncAllButton
                      onto:contentPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:5.0
                  hpadding:0.0];
      topView = syncAllMessage;
      totalHeight += syncAllMessage.frame.size.height + 5.0;
    } else {
      NSString *labelText = @"Upload All";
      UIFont *labelFont = _uitoolkit.fontForButtonsBlk();
      UILabel *cannotUploadLabel = [PEUIUtils labelWithKey:labelText
                                                    font:labelFont
                                         backgroundColor:[UIColor clearColor]
                                               textColor:[UIColor grayColor]
                                     verticalTextPadding:_uitoolkit.verticalPaddingForButtons];
      CGSize textSize = [PEUIUtils sizeOfText:labelText withFont:labelFont];
      UIView *cannotUploadPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentPanel fixedHeight:textSize.height + _uitoolkit.verticalPaddingForButtons];
      [cannotUploadPanel setBackgroundColor:[UIColor whiteColor]];
      [PEUIUtils styleViewForIpad:cannotUploadPanel];
      [PEUIUtils placeView:cannotUploadLabel inMiddleOf:cannotUploadPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
      UIView *badge = [PEUIUtils badgeForNum:totalNumSyncNeeded color:[UIColor rikerAppBlack] badgeTextColor:[UIColor whiteColor]];
      UIImageView *warningIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning-icon"]];
      UIView *cannotUploadMsgPanel = [self cannotSyncAllWhileUnauthInfoMessageRelativeToView:contentPanel];
      [PEUIUtils placeView:warningIcon inMiddleOf:cannotUploadPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:15.0];
      [PEUIUtils placeView:badge toTheRightOf:warningIcon onto:cannotUploadPanel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
      [PEUIUtils placeView:cannotUploadPanel below:topView onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:35.0 hpadding:0.0];
      totalHeight += cannotUploadPanel.frame.size.height + 35.0;
      [PEUIUtils placeView:cannotUploadMsgPanel below:cannotUploadPanel onto:contentPanel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:4.0 hpadding:0.0];
      totalHeight += cannotUploadMsgPanel.frame.size.height + 4.0;
      topView = cannotUploadMsgPanel;
    }
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(entityAddedNotification:)
                                               name:REntityAddedNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [APP setUserSettingsOpenFromUnsyncedEditsScreen:NO];
}

#pragma mark - Entity Added notification

- (void)entityAddedNotification:(NSNotification *)notification {
  [self setNeedsRepaint:YES];
  [self viewDidAppear:YES];
}

@end
