//
// PEUIUtils.m
//

#import "PEUtils.h"
#import "PEUIUtils.h"
#import "NSString+PEAdditions.h"
#import "PEObjcCommonsConstantsInternal.h"
#import "UIControl+BlocksKit.h"
#import "UIView+PERoundify.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "PESingleValueTableViewDataSourceDelegate.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "UIColor+RAdditions.h"

typedef JGActionSheetSection *(^PEAlertSectionMaker)(void);

CGFloat const IPHONE_5_PORTRAIT_WIDTH       = 320.0;
CGFloat const IPHONE_5_PORTRAIT_HEIGHT      = 568.0;

CGFloat const IPHONE_6_PORTRAIT_WIDTH       = 375.0;
CGFloat const IPHONE_6_PORTRAIT_HEIGHT      = 667.0;

CGFloat const IPHONE_6_PLUS_PORTRAIT_WIDTH  = 414.0;
CGFloat const IPHONE_6_PLUS_PORTRAIT_HEIGHT = 736.0;

CGFloat const IPHONE_XS_MAX_XR_PORTRAIT_WIDTH  = 414.0;
CGFloat const IPHONE_XS_MAX_XR_PORTRAIT_HEIGHT = 896.0;

CGFloat const IPAD_PRO_12IN_PORTRAIT_WIDTH  = 1024.0;
CGFloat const IPAD_PRO_12IN_PORTRAIT_HEIGHT = 1366.0;

CGFloat const IPAD_ALERT_PANEL_EXTRA_WIDTH = 150.0;

#define IDIOM UI_USER_INTERFACE_IDIOM()
#define IPAD  UIUserInterfaceIdiomPad

@implementation PEUIUtils

#pragma mark - Helpers

+ (UIFont *)fontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                   font:(UIFont *)font
                              fontMaker:(UIFont *(^)(void))fontMaker {
  if (font.pointSize > maxAllowedPointSize) {
    font = fontMaker();
  }
  return font;
}

+ (UIFont *)fontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                   font:(UIFont *)font {
  return [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                           font:font
                                      fontMaker:^{ return [UIFont systemFontOfSize:maxAllowedPointSize]; }];
}

+ (UIFont *)boldFontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                       font:(UIFont *)font {
  return [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                           font:font
                                      fontMaker:^{ return [UIFont boldSystemFontOfSize:maxAllowedPointSize]; }];
}

+ (UIFont *)italicFontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                         font:(UIFont *)font {
  return [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                           font:font
                                      fontMaker:^{ return [UIFont italicSystemFontOfSize:maxAllowedPointSize]; }];
}

+ (NSDictionary *)paragraphBeforeSpacingAttrs {
  return [PEUIUtils attrsWithPpBeforeSpacing:[PEUIUtils valueIfiPhone5Width:7.5 iphone6Width:10.0 iphone6PlusWidth:14.0 ipad:20.0]];
}

+ (BOOL)isIpad {
  return IDIOM == IPAD;
}

+ (BOOL)isIphoneX {
  if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
    switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
      case 2436:
        return YES;
    }
  }
  return NO;
}

+ (BOOL)isPortraitMode {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  return orientation == UIInterfaceOrientationPortrait;
}

+ (UIFont *)infoIconFont {  
  return [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:18.0 iphone6Width:26.0 iphone6PlusWidth:30.0 ipad:38.0]
                                               font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                                                                                              iphone6Width:UIFontTextStyleSubheadline
                                                                                                          iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                      ipad:UIFontTextStyleBody]]];
}

+ (UIFont *)actionButtonFont {
  return [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:30.0 iphone6PlusWidth:30.0 ipad:34.0]
                                               font:[PEUIUtils boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                                                              iphone6Width:UIFontTextStyleBody
                                                                                                          iphone6PlusWidth:UIFontTextStyleTitle3
                                                                                                                      ipad:UIFontTextStyleTitle3]]];
}

+ (CGFloat)actionButtonVpadding {
  return [PEUIUtils valueIfiPhone5Width:25.0 iphone6Width:28.0 iphone6PlusWidth:32.0 ipad:38.0];
}

+ (CGFloat)actionButtonHpadding {
  return [PEUIUtils valueIfiPhone5Width:30.0 iphone6Width:32.0 iphone6PlusWidth:34.0 ipad:40.0];
}

+ (UIFont *)actionCancelButtonFont {
  return [PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0]
                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                                                            iphone6Width:UIFontTextStyleSubheadline
                                                                                                        iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                    ipad:UIFontTextStyleBody]]];
}

+ (CGFloat)actionCancelButtonVpadding {
  return [PEUIUtils valueIfiPhone5Width:14.0 iphone6Width:16.0 iphone6PlusWidth:18.0 ipad:26.0];
}

+ (CGFloat)actionCancelButtonHpadding {
  return [PEUIUtils valueIfiPhone5Width:20.0 iphone6Width:22.0 iphone6PlusWidth:24.0 ipad:32.0];
}

+ (CGFloat)availableWidthForAlertPanelRelativeToView:(UIView *)relativeToView {
  CGFloat viewWidth = relativeToView.frame.size.width;
  return [PEUIUtils valueIfiPhone5Width:viewWidth
                           iphone6Width:viewWidth
                       iphone6PlusWidth:viewWidth
                                   ipad:IPHONE_5_PORTRAIT_WIDTH + IPAD_ALERT_PANEL_EXTRA_WIDTH];
}

+ (void)styleViewForIpad:(UIView *)view {
  if ([PEUIUtils isIpad]) {
    view.layer.cornerRadius = 5.0;
    [view setClipsToBounds:YES];
    [PEUIUtils applyBorderToView:view
                       withColor:[UIColor lightGrayColor] //rikerAppBlack]
                           width:0.50];
  }
}

+ (UIFontTextStyle)subheadlineFontTextStyle {
  return [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleSubheadline
                                   iphone6Width:UIFontTextStyleSubheadline
                               iphone6PlusWidth:UIFontTextStyleSubheadline
                                           ipad:UIFontTextStyleBody];
}

+ (UIFontTextStyle)bodyFontTextStyle {
  return [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                   iphone6Width:UIFontTextStyleBody
                               iphone6PlusWidth:UIFontTextStyleBody
                                           ipad:UIFontTextStyleTitle3];
}

+ (UIFontTextStyle)captionFontTextStyle {
  return [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption1
                                   iphone6Width:UIFontTextStyleCaption1
                               iphone6PlusWidth:UIFontTextStyleCaption1
                                           ipad:UIFontTextStyleSubheadline];
}

+ (UIFontTextStyle)userAccountInfoFontTextStyle {
  return [PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                   iphone6Width:UIFontTextStyleTitle3
                               iphone6PlusWidth:UIFontTextStyleTitle3
                                           ipad:UIFontTextStyleTitle3];
}

+ (CGFloat)heightForUserAccountTextfields {
  return ([PEUIUtils sizeOfText:@"" withFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]]].height +
          [PEUIUtils valueIfiPhone5Width:27.0
                            iphone6Width:27.0
                        iphone6PlusWidth:28.5 // smaller than iphone 6 because iphone 6 gets smaller 'subheadline' font
                                    ipad:40.0
                             ipadPro12in:45.0]);
  
}

+ (CGFloat)widthOfForContent {
  return [PEUIUtils valueIfiPhone5Width:1.0
                           iphone6Width:1.0
                       iphone6PlusWidth:1.0
                                   ipad:0.75
                            ipadPro12in:0.70];
}

+ (CGFloat)iphoneXSafeInsetsSide {
  if (@available(iOS 11.0, *)) {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
      return [[UIApplication sharedApplication] delegate].window.safeAreaInsets.right;
    }
  }
  return 0.0;
}

+ (CGFloat)valueIfiPhoneXSMaxOrXrInPortrait:(CGFloat)xsMaxXrValue
                                      other:(CGFloat)otherValue {
  BOOL isPortrait = [PEUIUtils isPortraitMode];
  if (isPortrait) {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    if (width == IPHONE_XS_MAX_XR_PORTRAIT_WIDTH && height == IPHONE_XS_MAX_XR_PORTRAIT_HEIGHT) {
      return xsMaxXrValue;
    }
  }
  return otherValue;
}

+ (CGFloat)valueIfiPhone5Width:(CGFloat)fiveValue
                  iphone6Width:(CGFloat)sixValue
              iphone6PlusWidth:(CGFloat)sixPlusValue
                          ipad:(CGFloat)ipadValue {
  return [PEUIUtils valueIfiPhone5Width:fiveValue
                           iphone6Width:sixValue
                       iphone6PlusWidth:sixPlusValue
                                   ipad:ipadValue
                            ipadPro12in:ipadValue];
}

+ (CGFloat)valueIfiPhone5Width:(CGFloat)fiveValue
                  iphone6Width:(CGFloat)sixValue
              iphone6PlusWidth:(CGFloat)sixPlusValue
                          ipad:(CGFloat)ipadValue
                   ipadPro12in:(CGFloat)ipadPro12inValue {
  CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
  BOOL isPortrait = [PEUIUtils isPortraitMode];
  if (width >= (isPortrait ? IPAD_PRO_12IN_PORTRAIT_WIDTH : IPAD_PRO_12IN_PORTRAIT_HEIGHT)) {
    return ipadPro12inValue;
  }
  if ([PEUIUtils isIpad]) {
    return ipadValue;
  } else {
    if (width <= (isPortrait ? IPHONE_5_PORTRAIT_WIDTH : IPHONE_5_PORTRAIT_HEIGHT)) {
      return fiveValue;
    }
    if (width <= (isPortrait ? IPHONE_6_PORTRAIT_WIDTH : IPHONE_6_PORTRAIT_HEIGHT)) {
      return sixValue;
    }
    return sixPlusValue;
  }
}

+ (id)objIfiPhone5Width:(id)fiveValue
           iphone6Width:(id)sixValue
       iphone6PlusWidth:(id)sixPlusValue
                   ipad:(id)ipadValue {
  return [PEUIUtils objIfiPhone5Width:fiveValue
                         iphone6Width:sixValue
                     iphone6PlusWidth:sixPlusValue
                                 ipad:ipadValue
                          ipadPro12in:ipadValue];
}

+ (id)objIfiPhone5Width:(id)fiveValue
           iphone6Width:(id)sixValue
       iphone6PlusWidth:(id)sixPlusValue
                   ipad:(id)ipadValue
            ipadPro12in:(id)ipadPro12inValue {
  CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
  BOOL isPortrait = [PEUIUtils isPortraitMode];
  if (width >= (isPortrait ? IPAD_PRO_12IN_PORTRAIT_WIDTH : IPAD_PRO_12IN_PORTRAIT_HEIGHT)) {
    return ipadPro12inValue;
  }
  if ([PEUIUtils isIpad]) {
    return ipadValue;
  } else {
    if (width <= (isPortrait ? IPHONE_5_PORTRAIT_WIDTH : IPHONE_5_PORTRAIT_HEIGHT)) {
      return fiveValue;
    }
    if (width <= (isPortrait ? IPHONE_6_PORTRAIT_WIDTH : IPHONE_6_PORTRAIT_HEIGHT)) {
      return sixValue;
    }
    return sixPlusValue;
  }
}

+ (UIFontTextStyle)fontTextStyleIfiPhone5Width:(UIFontTextStyle)fiveValue
                                  iphone6Width:(UIFontTextStyle)sixValue
                              iphone6PlusWidth:(UIFontTextStyle)sixPlusValue
                                          ipad:(UIFontTextStyle)ipadValue {
  return [PEUIUtils fontTextStyleIfiPhone5Width:fiveValue
                                   iphone6Width:sixValue
                               iphone6PlusWidth:sixPlusValue
                                           ipad:ipadValue
                                    ipadPro12in:ipadValue];
}

+ (UIFontTextStyle)fontTextStyleIfiPhone5Width:(UIFontTextStyle)fiveValue
                                  iphone6Width:(UIFontTextStyle)sixValue
                              iphone6PlusWidth:(UIFontTextStyle)sixPlusValue
                                          ipad:(UIFontTextStyle)ipadValue
                                   ipadPro12in:(UIFontTextStyle)ipadPro12inValue {
  CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
  BOOL isPortrait = [PEUIUtils isPortraitMode];
  if (width >= (isPortrait ? IPAD_PRO_12IN_PORTRAIT_WIDTH : IPAD_PRO_12IN_PORTRAIT_HEIGHT)) {
    return ipadPro12inValue;
  }
  if ([PEUIUtils isIpad]) {
    return ipadValue;
  } else {
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    if (width <= (isPortrait ? IPHONE_5_PORTRAIT_WIDTH : IPHONE_5_PORTRAIT_HEIGHT)) {
      return fiveValue;
    }
    if (width >= (isPortrait ? IPHONE_6_PLUS_PORTRAIT_WIDTH : IPHONE_6_PLUS_PORTRAIT_HEIGHT)) {
      return sixPlusValue;
    }
    return sixValue;
  }
}

+ (void)execBlockIfiPhone5Width:(void(^)(void))fiveBlk
                   iphone6Width:(void(^)(void))sixBlk
               iphone6PlusWidth:(void(^)(void))sixPlusBlk
                           ipad:(void(^)(void))ipadBlk {
  if ([PEUIUtils isIpad]) {
    ipadBlk();
  } else {
    BOOL isPortrait = [PEUIUtils isPortraitMode];
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    if (width <= (isPortrait ? IPHONE_5_PORTRAIT_WIDTH : IPHONE_5_PORTRAIT_HEIGHT)) {
      fiveBlk();
    } else if (width >= (isPortrait ? IPHONE_6_PLUS_PORTRAIT_WIDTH : IPHONE_6_PLUS_PORTRAIT_HEIGHT)) {
      sixPlusBlk();
    } else {
      sixBlk();
    }
  }
}

#pragma mark - Validation Utils

+ (PEMessageCollector)newTfCannotBeEmptyBlkForMsgs:(NSMutableArray *)errMsgs
                                       entityPanel:(UIView *)entityPanel {
  return ^(NSUInteger tag, NSString *errMsg) {
    if ([[PEUIUtils stringFromTextFieldWithTag:tag fromView:entityPanel] isBlank]) {
      [errMsgs addObject:errMsg];
    }
  };
}

+ (PEMessageCollector)newTfCannotBeZeroBlkForMsgs:(NSMutableArray *)errMsgs
                                      entityPanel:(UIView *)entityPanel {
  return ^(NSUInteger tag, NSString *errMsg) {
    NSString *val = [PEUIUtils stringFromTextFieldWithTag:tag fromView:entityPanel];
    if (![val isBlank]) {
      NSNumber *numVal = [PEUtils nullSafeNumberFromString:val];
      if (numVal.floatValue == 0.0) {
        [errMsgs addObject:errMsg];
      }
    }
  };
}

#pragma mark - Offline Mode Helpers

+ (void)bringOfflineModeViewsToFrontForController:(UIViewController *)controller {
  UIView *thinBar = [controller.view viewWithTag:158];
  UILabel *label = [controller.view viewWithTag:159];
  if (thinBar) {
    [controller.view bringSubviewToFront:thinBar];
  }
  if (label) {
    [controller.view bringSubviewToFront:label];
  }
}

+ (UIView *)offlineModeLabelWithController:(UIViewController *)controller {
  return [controller.view viewWithTag:159];
}

+ (UIView *)offlineModeBarWithController:(UIViewController *)controller {
  return [controller.view viewWithTag:158];
}

+ (void)addOfflineModeBarToController:(UIViewController *)controller animate:(BOOL)animate {
  UIView *thinBar = [controller.view viewWithTag:158];
  UILabel *label = [controller.view viewWithTag:159];
  BOOL addThinBar = NO;
  if (!thinBar) {
    addThinBar = YES;
    thinBar = [PEUIUtils panelWithWidthOf:1.0 relativeToView:controller.view fixedHeight:3.0];
    [thinBar setBackgroundColor:[UIColor carrotColor]];
    [thinBar setTag:158];
    [PEUIUtils placeView:thinBar
                 atTopOf:controller.view
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:[PEUIUtils vpaddingForTopOfController:controller]
                hpadding:0.0];
    [controller.view bringSubviewToFront:thinBar];
  }
  if (!label) {
    label = [PEUIUtils labelWithKey:@"  OFFLINE MODE ENABLED  "
                               font:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                    backgroundColor:[UIColor carrotColor]
                          textColor:[UIColor whiteColor]
                verticalTextPadding:3.0];
    [label setUserInteractionEnabled:NO];
    [label setTag:159];
    [PEUIUtils placeView:label
                 atTopOf:controller.view
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:[PEUIUtils vpaddingForTopOfController:controller]
                hpadding:0.0];
    [controller.view bringSubviewToFront:label];
    if (animate) {
      [PEUIUtils popAnimateView:label
                        scaleUp:1.1
                      scaleDown:0.9
                scaleUpDuration:0.15
              scaleDownDuration:0.10
          scaleIdentityDuration:0.10
                     completion:^{
                       /*if (addThinBar) {
                        [PEUIUtils placeView:thinBar
                        atTopOf:controller.view
                        withAlignment:PEUIHorizontalAlignmentTypeLeft
                        vpadding:[PEUIUtils vpaddingForTopOfController:controller]
                        hpadding:0.0];
                        [controller.view bringSubviewToFront:thinBar];
                        }*/
                     }];
    }
  }
}

+ (void)removeOfflineModeBarFromController:(UIViewController *)controller animated:(BOOL)animated {
  UIView *thinBar = [controller.view viewWithTag:158];
  UILabel *label = [controller.view viewWithTag:159];
  if (label) {
    if (animated) {
      [PEUIUtils popAnimateView:label
                        scaleUp:1.1
                      scaleDown:0.9
                scaleUpDuration:0.15
              scaleDownDuration:0.10
          scaleIdentityDuration:0.10
                     completion:^{
                       [thinBar removeFromSuperview];
                       [label removeFromSuperview];
                     }];
    } else {
      [thinBar removeFromSuperview];
      [label removeFromSuperview];
    }
  }
}

#pragma mark - Position Utils

+ (CGFloat)vpaddingForTopOfController:(UIViewController *)controller {
  CGFloat vpadding = 0.0;
  if (controller.navigationController &&
      !controller.navigationController.navigationBar.hidden &&
      ![controller isKindOfClass:[PEAddViewEditController class]] // I have no clue why this check is needed :)
      ) {
    vpadding = controller.navigationController.navigationBar.frame.size.height;
    if ([PEUIUtils isPortraitMode] || [PEUIUtils isIpad]) {
      // 20.0 (or 45.0-ish) = statusBarFrame height.  The reason for hard-coding it and not using
      // the actual height is because when there's a phone call or hotspot connection
      // active, the statusBarFrame's height grows to 40.0; but since we don't care about
      // that, we just have to hardcode to 20.0
      if ([PEUIUtils isIphoneX]) {
        vpadding += 44.0;
      } else {
        vpadding += 20.0;
      }
    } else {
      vpadding = 32.0;
    }
  }
  return vpadding;
}

+ (void)setFrameX:(CGFloat)xcoord andY:(CGFloat)ycoord ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame =
  CGRectMake(xcoord, ycoord, frame.size.width, frame.size.height);
  [view setFrame:newFrame];
}

+ (void)setFrameOrigin:(CGPoint)origin ofView:(UIView *)view {
  [PEUIUtils setFrameX:origin.x andY:origin.y ofView:view];
}

+ (void)setFrameX:(CGFloat)xcoord ofView:(UIView *)view {
  [PEUIUtils setFrameX:xcoord andY:view.frame.origin.y ofView:view];
}

+ (void)setFrameY:(CGFloat)ycoord ofView:(UIView *)view {
  [PEUIUtils setFrameX:view.frame.origin.x andY:ycoord ofView:view];
}

+ (void)adjustXOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameX:([view frame].origin.x + adjust) ofView:view];
}

+ (void)adjustYOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameY:([view frame].origin.y + adjust) ofView:view];
}

+ (void)adjustHeightOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameHeight:([view frame].size.height + adjust) ofView:view];
}

+ (void)adjustWidthOfView:(UIView *)view withValue:(CGFloat)adjust {
  [PEUIUtils setFrameWidth:([view frame].size.width + adjust) ofView:view];
}

+ (CGFloat)XForWidth:(CGFloat)width
       withAlignment:(PEUIHorizontalAlignmentType)alignment
      relativeToView:(UIView *)relativeToView
            hpadding:(CGFloat)hpadding {
  switch (alignment) {
  case PEUIHorizontalAlignmentTypeLeft:
    return relativeToView.frame.origin.x + hpadding;
  case PEUIHorizontalAlignmentTypeRight:
    return ((relativeToView.frame.size.width - width) +
            relativeToView.frame.origin.x) - hpadding;
  default: // center
    return relativeToView.frame.origin.x -
      ((width - relativeToView.frame.size.width) / 2);
  }
}

+ (CGFloat)YForHeight:(CGFloat)height
        withAlignment:(PEUIVerticalAlignmentType)alignment
       relativeToView:(UIView *)relativeToView
             vpadding:(CGFloat)vpadding {
  switch (alignment) {
  case PEUIVerticalAlignmentTypeTop:
    return relativeToView.frame.origin.y + vpadding;
  case PEUIVerticalAlignmentTypeBottom:
    return ((relativeToView.frame.size.height - height) +
            relativeToView.frame.origin.y) - vpadding;
  default: // center
    return relativeToView.frame.origin.y -
      ((height - relativeToView.frame.size.height) / 2);
  }
}

+ (CGPoint)pointToTheRightOf:(UIView *)view
               withAlignment:(PEUIVerticalAlignmentType)alignment
     alignmentRelativeToView:(UIView *)alignmentRelativeToView
                    hpadding:(CGFloat)hpadding
                forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake(viewRect.origin.x + viewRect.size.width + hpadding,
                     [PEUIUtils YForHeight:size.height
                             withAlignment:alignment
                            relativeToView:alignmentRelativeToView
                                  vpadding:0]);
}

+ (CGPoint)pointToTheLeftOf:(UIView *)view
              withAlignment:(PEUIVerticalAlignmentType)alignment
    alignmentRelativeToView:(UIView *)alignmentRelativeToView
                   hpadding:(CGFloat)hpadding
               forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake(viewRect.origin.x - (size.width + hpadding),
                     [PEUIUtils YForHeight:size.height
                             withAlignment:alignment
                            relativeToView:alignmentRelativeToView
                                  vpadding:0]);
}

+ (CGPoint)pointAbove:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake([PEUIUtils XForWidth:size.width
                            withAlignment:alignment
                           relativeToView:alignmentRelativeToView
                                 hpadding:hpadding],
                     viewRect.origin.y - (size.height + vpadding));
}

+ (CGPoint)pointBelow:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size {
  CGRect viewRect = [view frame];
  return CGPointMake([PEUIUtils XForWidth:size.width
                            withAlignment:alignment
                           relativeToView:alignmentRelativeToView
                                 hpadding:hpadding],
                     viewRect.origin.y + (viewRect.size.height + vpadding));
}

#pragma mark - Dimension Utils

+ (CGFloat)heightForText:(NSString *)text forWidth:(CGFloat)width {
  NSMutableAttributedString *attrStr =
    [[NSMutableAttributedString alloc] initWithString:text];
  CGRect bounds =
    [attrStr boundingRectWithSize:CGSizeMake(width * 0.5, 0)
                          options:(NSLineBreakByWordWrapping |
                                   NSStringDrawingUsesLineFragmentOrigin)
                          context:nil];
  return bounds.size.height;
}

+ (CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font {
  NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
  CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : font,
                                               NSParagraphStyleAttributeName : paragraphStyle}];
  return CGSizeMake(textSize.width, textSize.height);
}

+ (CGFloat)widthWidestAmong:(NSArray *)views {
  __block CGFloat largestWidth = 0;
  [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
      if (obj.frame.size.width > largestWidth) {
        largestWidth = obj.frame.size.width;
      }
    }];
  return largestWidth;
}

+ (CGFloat)heightHighestAmong:(NSArray *)views {
  __block CGFloat largestHeight = 0;
  [views enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
    if (obj.frame.size.height > largestHeight) {
      largestHeight = obj.frame.size.height;
    }
  }];
  return largestHeight;
}

#pragma mark - View Movement

+ (void)positionView:(UIView *)view
             atTopOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        vpadding)
                     ofView:view];
}

+ (void)positionView:(UIView *)view
          atBottomOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        [PEUIUtils YForHeight:[view frame].size.height
                                                withAlignment:PEUIVerticalAlignmentTypeBottom
                                               relativeToView:ontoView
                                                     vpadding:vpadding])
                     ofView:view];
}

+ (void)positionView:(UIView *)view
          inMiddleOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                               withAlignment:alignment
                                              relativeToView:ontoView
                                                    hpadding:hpadding],
                                        [PEUIUtils YForHeight:[view frame].size.height
                                                withAlignment:PEUIVerticalAlignmentTypeMiddle
                                               relativeToView:ontoView
                                                     vpadding:0])
                     ofView:view];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
                 and:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
                andYCoord:bottomView.frame.origin.y
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
           andYCoord:(CGFloat)bottomYCoord
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
                andYCoord:bottomYCoord
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
             andView:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:topYCoordinate
                andYCoord:bottomView.frame.origin.y
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
           andYCoord:(CGFloat)bottomYCoordinate
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin: CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                                                withAlignment:alignment
                                               relativeToView:ontoView
                                                     hpadding:hpadding],
                                         topYCoordinate -
                                         (([view frame].size.height - (bottomYCoordinate - topYCoordinate)) / 2))
                     ofView:view];
}

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                    below:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointBelow:relativeTo
                                    withAlignment:alignment
                          alignmentRelativeToView:alignmentRelativeToView
                                         vpadding:vpadding
                                         hpadding:hpadding
                                     forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
                    above:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointAbove:relativeTo
                                    withAlignment:alignment
                          alignmentRelativeToView:alignmentRelativeToView
                                         vpadding:vpadding
                                         hpadding:hpadding
                                     forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
              toTheLeftOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointToTheLeftOf:relativeTo
                                          withAlignment:alignment
                                alignmentRelativeToView:alignmentRelativeToView
                                               hpadding:hpadding
                                           forBoxOfSize:[view frame].size]
                     ofView:view];
}

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding {
  [PEUIUtils positionView:view
             toTheRightOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:relativeTo
                 hpadding:hpadding];
}

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding {
  [PEUIUtils setFrameOrigin:[PEUIUtils pointToTheRightOf:relativeTo
                                           withAlignment:alignment
                                 alignmentRelativeToView:alignmentRelativeToView
                                                hpadding:hpadding
                                            forBoxOfSize:[view frame].size]
                     ofView:view];
}

#pragma mark - View Placement

+ (void)placeView:(UIView *)view
          atTopOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                  atTopOf:ontoView
            withAlignment:alignment
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
       atBottomOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
               atBottomOf:ontoView
            withAlignment:alignment
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
       inMiddleOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
               inMiddleOf:ontoView
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
              and:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
             andYCoord:bottomView.frame.origin.y
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
        andYCoord:(CGFloat)bottomYCoord
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:(topView.frame.origin.y + topView.frame.size.height)
             andYCoord:bottomYCoord
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
          andView:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                  onto:ontoView
 inMiddleBetweenYCoord:topYCoordinate
             andYCoord:bottomView.frame.origin.y
         withAlignment:alignment
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
        andYCoord:(CGFloat)bottomYCoordinate
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                     onto:ontoView
    inMiddleBetweenYCoord:topYCoordinate
                andYCoord:bottomYCoordinate
            withAlignment:alignment
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                 below:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                    below:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
                 above:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
                    above:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 vpadding:vpadding
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
           toTheLeftOf:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
              toTheLeftOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding {
  [PEUIUtils placeView:view
          toTheRightOf:relativeTo
                  onto:ontoView
         withAlignment:alignment
alignmentRelativeToView:relativeTo
              hpadding:hpadding];
}

+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding {
  [ontoView addSubview:view];
  [PEUIUtils positionView:view
             toTheRightOf:relativeTo
                     onto:ontoView
            withAlignment:alignment
  alignmentRelativeToView:alignmentRelativeToView
                 hpadding:hpadding];
}

#pragma mark - Animations

+ (void)popAnimateView:(UIView *)sender
               scaleUp:(CGFloat)scaleUp
             scaleDown:(CGFloat)scaleDown
       scaleUpDuration:(CGFloat)scaleUpDuration
     scaleDownDuration:(CGFloat)scaleDownDuration
 scaleIdentityDuration:(CGFloat)scaleIdentityDuration
            completion:(void(^)(void))completion {
  UIView * btn = (UIView *)sender;
  [UIView animateWithDuration:scaleUpDuration animations:^{ // 0.20
    btn.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleUp, scaleUp); //1.4, 1.4); // scales up the view of button
  } completion:^(BOOL finished) {
    [UIView animateWithDuration:scaleDownDuration animations:^{ // 0.15
      btn.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleDown, scaleDown); //0.7, 0.7);// scales down the view of button
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:scaleIdentityDuration animations:^{ // 0.15
        btn.transform = CGAffineTransformIdentity; // at the end sets the original identity of the button
        if (completion) {
          completion();
        }
      }];
    }];
  }];
}

+ (void)placeAndAnimateView:(UIView *)view
              fromTopOfView:(UIView *)relativeTo
                    downToY:(CGFloat)downToY
              withAlignment:(PEUIHorizontalAlignmentType)alignment
                   hpadding:(CGFloat)hpadding
                   duration:(NSTimeInterval)duration
            fadeOutDuration:(NSTimeInterval)fadeOutDuration {
  [PEUIUtils placeView:view
                 above:relativeTo
                  onto:relativeTo
         withAlignment:alignment
              vpadding:0
              hpadding:0];
  [UIView animateWithDuration:duration
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
    CGPoint destPoint =
      CGPointMake([PEUIUtils XForWidth:[view frame].size.width
                         withAlignment:alignment
                        relativeToView:relativeTo
                              hpadding:hpadding], downToY);
    [PEUIUtils setFrameOrigin:destPoint ofView:view]; }
                   completion:^(BOOL finished) {
                     [UIView animateWithDuration:fadeOutDuration
                                           delay:0.0f
                                         options:UIViewAnimationOptionCurveEaseInOut
                                      animations:^{
                       [view setAlpha:0.0f]; }
                                      completion:^(BOOL finished){ [view removeFromSuperview]; }]; }];
}

#pragma mark - View Sizing

+ (void)setFrameWidth:(CGFloat)width ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, width,
                               frame.size.height);
  [view setFrame:newFrame];
}

+ (void)setFrameWidthOfView:(UIView *)view
                    ofWidth:(CGFloat)percentage
                 relativeTo:(UIView *)relativeToView {
  [PEUIUtils setFrameWidth:([relativeToView frame].size.width * percentage)
                    ofView:view];
}

+ (void)setFrameHeight:(CGFloat)height ofView:(UIView *)view {
  CGRect frame = [view frame];
  CGRect newFrame =
    CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height);
  [view setFrame:newFrame];
}

+ (void)setFrameHeightOfView:(UIView *)view
                    ofHeight:(CGFloat)percentage
                  relativeTo:(UIView *)relativeToView {
  [PEUIUtils setFrameHeight:([relativeToView frame].size.height * percentage)
                     ofView:view];
}

+ (void)adjustHeightToFitSubviewsForView:(UIView *)panel
                           bottomPadding:(CGFloat)bottomPadding {
  NSArray *subviews = [panel subviews];
  CGRect boundingRect = CGRectZero;
  for (UIView *view in subviews) {
    boundingRect = CGRectUnion(boundingRect, view.frame);
  }
  [PEUIUtils setFrameHeight:(boundingRect.size.height + bottomPadding)
                     ofView:panel];
}

#pragma mark - View Controller Commons

+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController {
  return [PEUIUtils navigationControllerWithController:viewController
                                   navigationBarHidden:YES];
}

+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController
                                           navigationBarHidden:(BOOL)navigationBarHidden {
  UINavigationController *navCtrl =
    [[UINavigationController alloc] initWithRootViewController:viewController];
  [navCtrl setNavigationBarHidden:navigationBarHidden];
  return navCtrl;
}

+ (void)displayController:(UIViewController *)controller
           fromController:(UIViewController *)fromController
                 animated:(BOOL)animated {
  UINavigationController *fromControllerParentNavCtrl = [fromController navigationController];
  if (fromControllerParentNavCtrl) {
    [fromControllerParentNavCtrl pushViewController:controller animated:animated];
  } else {
    [fromController presentViewController:controller animated:animated completion:nil];
  }
}

+ (UINavigationController *)navControllerWithRootController:(UIViewController *)viewController
                                        navigationBarHidden:(BOOL)navigationBarHidden
                                            tabBarItemTitle:(NSString *)tabBarItemTitle
                                            tabBarItemImage:(UIImage *)tabBarItemImage
                                    tabBarItemSelectedImage:(UIImage *)tabBarItemSelectedImage {
  UINavigationController *navCtrl =
    [PEUIUtils navigationControllerWithController:viewController
                              navigationBarHidden:navigationBarHidden];
  UITabBarItem *tabBarItem =
  [[UITabBarItem alloc] initWithTitle:tabBarItemTitle
                                image:tabBarItemImage
                        selectedImage:tabBarItemSelectedImage];
  if (!tabBarItemTitle) {
    // http://stackoverflow.com/questions/16285205/moving-uitabbaritem-image-down
    tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
  }
  [navCtrl setTabBarItem:tabBarItem];
  return navCtrl;
}

#pragma mark - Color Utils

+ (UIImage *)imageWithColor:(UIColor *)color {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (void)applyBorderToView:(UIView *)view
                withColor:(UIColor *)color {
  [PEUIUtils applyBorderToView:view withColor:color width:1.0];
}

+ (void)applyBorderToView:(UIView *)view
                withColor:(UIColor *)color
                    width:(CGFloat)width {
  view.layer.borderColor = color.CGColor;
  view.layer.borderWidth = width;
}

#pragma mark - Attributed Text

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                        templateTextColor:(UIColor *)templateTextColor
                                         templateTextFont:(UIFont *)templateTextFont
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor
                             additionalTemplateAttributes:(NSDictionary *)additionalTemplateAttributes {
  NSMutableDictionary *templateAttrs = [NSMutableDictionary dictionary];
  if (templateTextFont) {
    [templateAttrs setObject:templateTextFont forKey:NSFontAttributeName];
  }
  if (templateTextColor) {
    [templateAttrs setObject:templateTextColor forKey:NSForegroundColorAttributeName];
  }
  if (additionalTemplateAttributes) {
    [templateAttrs addEntriesFromDictionary:additionalTemplateAttributes];
  }
  NSMutableDictionary *accentAttrs = [NSMutableDictionary dictionary];
  if (accentTextFont) {
    [accentAttrs setObject:accentTextFont forKey:NSFontAttributeName];
  }
  if (accentTextColor) {
    [accentAttrs setObject:accentTextColor forKey:NSForegroundColorAttributeName];
  }
  NSString *text = [NSString stringWithFormat:templateText, textToAccent];
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
  [attributedText setAttributes:templateAttrs range:NSMakeRange(0, text.length)];
  if (textToAccent) {
    NSRange accentRange = [text rangeOfString:textToAccent];
    if (accentRange.length > 0) {
      [attributedText setAttributes:accentAttrs range:accentRange];
    }
  }
  return attributedText;
}

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                        templateTextColor:(UIColor *)templateTextColor
                                         templateTextFont:(UIFont *)templateTextFont
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor {
  return [PEUIUtils attributedTextWithTemplate:templateText
                             templateTextColor:templateTextColor
                              templateTextFont:templateTextFont
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:accentTextColor
                  additionalTemplateAttributes:nil];
}

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor {
  return [PEUIUtils attributedTextWithTemplate:templateText
                             templateTextColor:nil
                              templateTextFont:nil
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:accentTextColor];
}

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont {
  return [PEUIUtils attributedTextWithTemplate:templateText
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:nil];
}

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                                    attrs:(NSDictionary *)attrs {
  return [PEUIUtils attributedTextWithTemplate:templateText
                             templateTextColor:nil
                              templateTextFont:nil
                                  textToAccent:textToAccent
                                accentTextFont:accentTextFont
                               accentTextColor:nil
                  additionalTemplateAttributes:attrs];
}

+ (NSMutableDictionary *)attrsWithPpBeforeSpacing:(CGFloat)beforeSpacing {
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.paragraphSpacingBefore = beforeSpacing;
  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  attrs[NSParagraphStyleAttributeName] = ps;
  return attrs;
}

+ (NSMutableDictionary *)attrsWithLineSpacing:(CGFloat)lineSpacing {
  NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
  ps.lineSpacing = lineSpacing;
  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  attrs[NSParagraphStyleAttributeName] = ps;
  return attrs;
}

#pragma mark - Text Truncation

+ (NSString *)truncatedTextForText:(NSString *)text
                              font:(UIFont *)font
                    availableWidth:(CGFloat)availableWidth {
  CGFloat wouldBeWidthOfValueLabel = [PEUIUtils sizeOfText:text withFont:font].width;
  CGFloat widthOfElipses = [PEUIUtils sizeOfText:@"..." withFont:font].width;
  if (wouldBeWidthOfValueLabel > availableWidth) {
    if ([text length] > 0) {
      NSDecimalNumber *avgWidthPerLetter = [[[NSDecimalNumber alloc] initWithFloat:wouldBeWidthOfValueLabel] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithInteger:[text length]]];
      NSInteger availableWidthMinusElipses = availableWidth - widthOfElipses;
      NSDecimalNumber *allowedNumLetters = [[[NSDecimalNumber alloc] initWithInteger:(availableWidth - widthOfElipses)] decimalNumberByDividingBy:avgWidthPerLetter];
      allowedNumLetters = [allowedNumLetters decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                                                               scale:0
                                                                                                                                    raiseOnExactness:NO
                                                                                                                                     raiseOnOverflow:NO
                                                                                                                                    raiseOnUnderflow:NO
                                                                                                                                 raiseOnDivideByZero:NO]];
      if (availableWidthMinusElipses > 0) {
        if (allowedNumLetters.integerValue > 0) {
          if (allowedNumLetters.integerValue <= text.length) {
            text = [[text substringToIndex:(allowedNumLetters.integerValue - 1)] stringByAppendingString:@"..."];
          }
        }
      } else {
        text = @"...";
      }
    }
  }
  return text;
}

#pragma mark - Label maker helper

+ (UILabel *)emptyLabelWithFont:(UIFont *)font
                backgroundColor:(UIColor *)backgroundColor
                      textColor:(UIColor *)textColor
            verticalTextPadding:(CGFloat)verticalTextPadding
                          width:(CGFloat)width
                         height:(CGFloat)height {
  UILabel *label =
    [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height + verticalTextPadding)];
  [label setNumberOfLines:0];
  [label setBackgroundColor:backgroundColor];
  [label setLineBreakMode:NSLineBreakByWordWrapping];
  [label setTextColor:textColor];
  [label setFont:font];
  return label;
}

+ (UILabel *)emptyLabelToFitText:(NSString *)text
                            font:(UIFont *)font
        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
            additionalAttributes:(NSDictionary *)additionalAttributes
                 backgroundColor:(UIColor *)backgroundColor
                       textColor:(UIColor *)textColor
             verticalTextPadding:(CGFloat)verticalTextPadding
                      fitToWidth:(CGFloat)fitToWidth {
  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  attrs[NSFontAttributeName] = fontForHeightCalculation;
  if (additionalAttributes) {
    [attrs addEntriesFromDictionary:additionalAttributes];
  }
  CGRect rect = [text boundingRectWithSize:CGSizeMake(fitToWidth, MAXFLOAT)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:attrs
                                   context:nil];
  return [PEUIUtils emptyLabelWithFont:font
                       backgroundColor:backgroundColor
                             textColor:textColor
                   verticalTextPadding:verticalTextPadding
                                 width:rect.size.width
                                height:rect.size.height];
}

+ (UILabel *)emptyLabelToFitText:(NSString *)text
                            font:(UIFont *)font
        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                 backgroundColor:(UIColor *)backgroundColor
                       textColor:(UIColor *)textColor
             verticalTextPadding:(CGFloat)verticalTextPadding {
  CGSize textSize = [PEUIUtils sizeOfText:text withFont:fontForHeightCalculation];
  return [PEUIUtils emptyLabelWithFont:font
                       backgroundColor:backgroundColor
                             textColor:textColor
                   verticalTextPadding:verticalTextPadding
                                 width:textSize.width
                                height:textSize.height];
}

#pragma mark - Labels

+ (UIFont *)boldFontForTextStyle:(NSString *)textStyle {
  return [PEUIUtils fontForTextStyle:textStyle trait:UIFontDescriptorTraitBold];
}

+ (UIFont *)italicFontForTextStyle:(NSString *)textStyle {
  return [PEUIUtils fontForTextStyle:textStyle trait:UIFontDescriptorTraitItalic];
}

+ (UIFont *)boldItalicFontForTextStyle:(NSString *)textStyle {
  return [PEUIUtils fontForTextStyle:textStyle trait:(UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold)];
}

+ (UIFont *)fontForTextStyle:(NSString *)textStyle
                       trait:(UIFontDescriptorSymbolicTraits)trait {
  UIFontDescriptor* fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
  UIFontDescriptor* boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:trait];
  return [UIFont fontWithDescriptor:boldFontDescriptor size:0.0];
}

+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding {
  NSString *text = LS(key);
  UILabel *label = [PEUIUtils emptyLabelToFitText:text
                                             font:font
                         fontForHeightCalculation:font
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding];
  [label setText:text];
  return label;
}

+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding
               fitToWidth:(CGFloat)fitToWidth {
  NSString *text = LS(key);
  UILabel *label = [PEUIUtils emptyLabelToFitText:text
                                             font:font
                         fontForHeightCalculation:font
                             additionalAttributes:nil
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding
                                       fitToWidth:fitToWidth];
  [label setText:text];
  return label;
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding {
  return [PEUIUtils labelWithAttributeText:attributedText
                                      font:font
                  fontForHeightCalculation:font
                           backgroundColor:backgroundColor
                                 textColor:textColor
                       verticalTextPadding:verticalTextPadding];
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding {
  UILabel *label = [PEUIUtils emptyLabelToFitText:[attributedText string]
                                             font:font
                         fontForHeightCalculation:fontForHeightCalculation
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding];
  [label setAttributedText:attributedText];
  return label;
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth {
  return [PEUIUtils labelWithAttributeText:attributedText
                                      font:font
                  fontForHeightCalculation:font
                           backgroundColor:backgroundColor
                                 textColor:textColor
                       verticalTextPadding:verticalTextPadding
                                fitToWidth:fitToWidth];
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth {
  return [PEUIUtils labelWithAttributeText:attributedText
                                      font:font
                  fontForHeightCalculation:fontForHeightCalculation
                      additionalAttributes:nil
                           backgroundColor:backgroundColor
                                 textColor:textColor
                       verticalTextPadding:verticalTextPadding
                                fitToWidth:fitToWidth];
}

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
               additionalAttributes:(NSDictionary *)additionalAttributes
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth {
  NSMutableDictionary *allAttrs = [NSMutableDictionary dictionary];
  [attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length)
                                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                  usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
                                    [allAttrs addEntriesFromDictionary:attrs];
                                  }];
  if (additionalAttributes) {
    [allAttrs addEntriesFromDictionary:additionalAttributes];
  }
  UILabel *label = [PEUIUtils emptyLabelToFitText:[attributedText string]
                                             font:font
                         fontForHeightCalculation:fontForHeightCalculation
                             additionalAttributes:allAttrs
                                  backgroundColor:backgroundColor
                                        textColor:textColor
                              verticalTextPadding:verticalTextPadding
                                       fitToWidth:fitToWidth];
  [label setAttributedText:attributedText];
  return label;
}

+ (UIView *)leftPadView:(UIView *)view
                padding:(CGFloat)padding {
  UIView *panel = [PEUIUtils panelWithFixedWidth:padding + view.frame.size.width
                                     fixedHeight:view.frame.size.height];
  UIView *paddingPanel = [PEUIUtils panelWithFixedWidth:padding fixedHeight:view.frame.size.height];
  [paddingPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:paddingPanel inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:0.0];
  [PEUIUtils placeView:view toTheRightOf:paddingPanel onto:panel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:0.0];
  return panel;
}

+ (UIView *)rightPadView:(UIView *)view padding:(CGFloat)padding {
  UIView *panel = [PEUIUtils panelWithFixedWidth:padding + view.frame.size.width
                                     fixedHeight:view.frame.size.height];
  UIView *paddingPanel = [PEUIUtils panelWithFixedWidth:padding fixedHeight:view.frame.size.height];
  [paddingPanel setBackgroundColor:[UIColor clearColor]];
  [PEUIUtils placeView:paddingPanel inMiddleOf:panel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:0.0];
  [PEUIUtils placeView:view toTheLeftOf:paddingPanel onto:panel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:0.0];
  return panel;
}

+ (void)setTextAndResize:(NSString *)text forLabel:(UILabel *)label {
  CGSize textSize = [PEUIUtils sizeOfText:text withFont:[label font]];
  [label setText:text];
  [PEUIUtils setFrameHeight:textSize.height ofView:label];
  [PEUIUtils setFrameWidth:textSize.width ofView:label];
}

+ (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor {
  CGFloat widthPadding = 30.0;
  CGFloat heightFactor = 1.45;
  UIFont* boldSubheadlineFont = [PEUIUtils boldFontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:26.0 ipad:30.0]
                                                                      font:[self boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  NSString *labelText = [NSString stringWithFormat:@"%ld", (long)num];
  UILabel *label = [PEUIUtils labelWithKey:labelText
                                      font:boldSubheadlineFont
                           backgroundColor:[UIColor clearColor]
                                 textColor:badgeTextColor
                       verticalTextPadding:0.0];
  UIView *badge = [PEUIUtils panelWithFixedWidth:label.frame.size.width + widthPadding
                                     fixedHeight:label.frame.size.height * heightFactor];
  [badge addRoundedCorners:UIRectCornerAllCorners
                 withRadii:CGSizeMake(20.0, 20.0)];
  badge.alpha = 0.8;
  badge.backgroundColor = color;
  [PEUIUtils placeView:label
            inMiddleOf:badge
         withAlignment:PEUIHorizontalAlignmentTypeCenter
              hpadding:0.0];
  return badge;
}

+ (UILabel *)labelForRecordCount:(NSInteger)recordCount {
  return [PEUIUtils labelWithKey:[PEUtils labelTextForRecordCount:recordCount]
                            font:[PEUIUtils fontWithMaxAllowedPointSize:[PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0]
                                                                   font:[UIFont preferredFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleCaption2
                                                                                                                                    iphone6Width:UIFontTextStyleCaption2
                                                                                                                                iphone6PlusWidth:UIFontTextStyleSubheadline
                                                                                                                                            ipad:UIFontTextStyleSubheadline]]]
                 backgroundColor:[UIColor clearColor]
                       textColor:[UIColor darkGrayColor]
             verticalTextPadding:0.0];
}

+ (void)placeRecordCountLabel:(UILabel *)recordCountLabel
                   ontoButton:(UIButton *)button
                     hpadding:(CGFloat)hpadding
                     vpadding:(CGFloat)vpadding {
  [PEUIUtils placeView:recordCountLabel
            atBottomOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:vpadding
              hpadding:hpadding];
}

+ (void)refreshRecordCountLabelOnButton:(UIButton *)button
                    recordCountLabelTag:(NSInteger)recordCountLabelTag
                            recordCount:(NSInteger)recordCount {
  UILabel *recordCountLabel = (UILabel *)[button viewWithTag:recordCountLabelTag];
  if (recordCountLabel) {
    [PEUIUtils setTextAndResize:[PEUtils labelTextForRecordCount:recordCount] forLabel:recordCountLabel];
  }
}

#pragma mark - Text Fields

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width {
  return [PEUIUtils textfieldWithPlaceholderTextKey:key
                                               font:font
                                    backgroundColor:backgroundColor
                                    leftViewPadding:leftViewPadding
                                         fixedWidth:width
                                       heightFactor:1.75]; // a reasonable default
}

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width
                                    heightFactor:(CGFloat)heightFactor {
  NSString *placeholderText = LS(key);
  CGFloat height = [PEUIUtils sizeOfText:placeholderText withFont:font].height *
    heightFactor;
  UITextField *tf =
    [[UITextField alloc]
      initWithFrame:CGRectMake(0, 0, width, height)];
  [tf setAutocorrectionType:UITextAutocorrectionTypeNo];
  [tf setAutocapitalizationType:UITextAutocapitalizationTypeNone];
  [tf setClearButtonMode:UITextFieldViewModeWhileEditing];
  UIView *paddingView =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, leftViewPadding, height)];
  [tf setLeftView:paddingView];
  [tf setLeftViewMode:UITextFieldViewModeAlways];
  [tf setBackgroundColor:backgroundColor];
  [tf setFont:font];
  [tf setPlaceholder:placeholderText];
  return tf;
}

+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                         ofWidth:(CGFloat)percentage
                                      relativeTo:(UIView *)relativeToView {
  CGFloat width = relativeToView.frame.size.width * percentage;
  return [PEUIUtils textfieldWithPlaceholderTextKey:key
                                               font:font
                                    backgroundColor:backgroundColor
                                    leftViewPadding:leftViewPadding
                                         fixedWidth:width];
}

+ (NSString *)stringFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view {
  return [(UITextField *)[view viewWithTag:tag] text];
}

+ (NSNumber *)numberFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view {
  return [PEUtils nullSafeNumberFromString:[(UITextField *)[view viewWithTag:tag] text]];
}

+ (NSDecimalNumber *)decimalNumberFromTextFieldWithTag:(NSInteger)tag
                                              fromView:(UIView *)view {
  return [PEUtils nullSafeDecimalNumberFromString:[(UITextField *)[view viewWithTag:tag] text]];
}

+ (void)bindToEntity:(id)entity
          withSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
   stringTransformer:(id(^)(NSString *))stringTransformer
            fromView:(UIView *)view {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  NSString *strValue = [PEUIUtils stringFromTextFieldWithTag:tfTag
                                                    fromView:view];
  [entity performSelector:setter
               withObject:stringTransformer(strValue)];
#pragma clang diagnostic pop
}

+ (void)bindToEntity:(id)entity
    withStringSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return strValue;}
                 fromView:view];
}

+ (void)bindToEntity:(id)entity
    withNumberSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return [PEUtils nullSafeNumberFromString:strValue];}
                 fromView:view];
}

+ (void)bindToEntity:(id)entity
   withDecimalSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view {
  [PEUIUtils bindToEntity:entity
               withSetter:setter
     fromTextfieldWithTag:tfTag
        stringTransformer:^id(NSString *strValue){return [PEUtils nullSafeDecimalNumberFromString:strValue];}
                 fromView:view];
}

+ (void)bindToTextControlWithTag:(NSInteger)tfTag
                        fromView:(UIView *)view
                      fromEntity:(id)entity
                      withGetter:(SEL)getter {
  UIView *textView = [view viewWithTag:tfTag];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  NSObject *val = [entity performSelector:getter];
  NSString *valStr;
  if (val && ![val isEqual:[NSNull null]]) {
    valStr = [val description];
  } else {
    valStr = @"";
  }
  [textView performSelector:@selector(setText:) withObject:valStr];
  #pragma clang diagnostic pop
}

+ (void)bindToTextControlWithTag:(NSInteger)tfTag
                        fromView:(UIView *)view
                      fromEntity:(id)entity
                withNumberGetter:(SEL)numberGetter
                       formatter:(NSNumberFormatter *)formatter {
  UIView *textView = [view viewWithTag:tfTag];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  NSObject *val = [entity performSelector:numberGetter];
  NSString *valStr;
  if (val && ![val isEqual:[NSNull null]]) {
    valStr = [formatter stringFromNumber:(NSNumber *)val];
  } else {
    valStr = @"";
  }
  [textView performSelector:@selector(setText:) withObject:valStr];
#pragma clang diagnostic pop
}

+ (void)enableControlWithTag:(NSInteger)tag
                    fromView:(UIView *)view
                      enable:(BOOL)enable {
  UIControl *control = (UIControl *)[view viewWithTag:tag];
  [control setEnabled:enable];
}

#pragma mark - Buttons

+ (UIButton *)buttonWithKey:(NSString *)key
                       font:(UIFont *)font
            backgroundColor:(UIColor *)backgroundColor
                  textColor:(UIColor *)textColor
disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
     disabledStateTextColor:(UIColor *)disabledStateTextColor
            verticalPadding:(CGFloat)verticalPadding
          horizontalPadding:(CGFloat)horizontalPadding
               cornerRadius:(CGFloat)cornerRadius
                     target:(id)target
                     action:(SEL)action {
  return [PEUIUtils buttonWithKey:key
           keyForWidthComputation:key
                             font:font
                  backgroundColor:backgroundColor
                        textColor:textColor
     disabledStateBackgroundColor:disabledStateBackgroundColor
           disabledStateTextColor:disabledStateTextColor
                  verticalPadding:verticalPadding
                horizontalPadding:horizontalPadding
                     cornerRadius:cornerRadius
                           target:target
                           action:action];
}

+ (UIButton *)buttonWithKey:(NSString *)key
     keyForWidthComputation:(NSString *)keyForWidthComputation
                       font:(UIFont *)font
            backgroundColor:(UIColor *)backgroundColor
                  textColor:(UIColor *)textColor
disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
     disabledStateTextColor:(UIColor *)disabledStateTextColor
            verticalPadding:(CGFloat)verticalPadding
          horizontalPadding:(CGFloat)horizontalPadding
               cornerRadius:(CGFloat)cornerRadius
                     target:(id)target
                     action:(SEL)action {
  NSString *titleTextForWithComputation = LS(keyForWidthComputation);
  NSString *titleText = LS(key);
  UIButton *btn = [self templateButtonWithTitleText:titleTextForWithComputation
                           fontForHeightCalculation:font
                                    backgroundColor:backgroundColor
                       disabledStateBackgroundColor:disabledStateBackgroundColor
                                    verticalPadding:verticalPadding
                                  horizontalPadding:horizontalPadding
                                       cornerRadius:cornerRadius
                                             target:target
                                             action:action];
  [btn setTitle:titleText forState:UIControlStateNormal];
  [btn setTitleColor:textColor forState:UIControlStateNormal];
  [btn setTitleColor:disabledStateTextColor forState:UIControlStateDisabled];
  [[btn titleLabel] setFont:font];
  return btn;
}

+ (UIButton *)templateButtonWithTitleText:(NSString *)titleText
                 fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                          backgroundColor:(UIColor *)backgroundColor
             disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
                          verticalPadding:(CGFloat)verticalPadding
                        horizontalPadding:(CGFloat)horizontalPadding
                             cornerRadius:(CGFloat)cornerRadius
                                   target:(id)target
                                   action:(SEL)action {
  CGSize textSize = [PEUIUtils sizeOfText:titleText withFont:fontForHeightCalculation];
  textSize = CGSizeMake(textSize.width + horizontalPadding,
                        textSize.height + verticalPadding);
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  UIImage *bgColorAsImgNormState = [PEUIUtils imageWithColor:backgroundColor];
  UIImage *bgColorAsImgDisState =
  [PEUIUtils imageWithColor:disabledStateBackgroundColor];
  [btn setBackgroundImage:bgColorAsImgNormState forState:UIControlStateNormal];
  [btn setBackgroundImage:bgColorAsImgDisState forState:UIControlStateDisabled];
  [[btn layer] setCornerRadius:cornerRadius];
  [btn setClipsToBounds:YES]; // needed for corner radius to work
  [[btn titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
  [[btn titleLabel] setTextAlignment:NSTextAlignmentCenter];
  [[btn titleLabel] setTextColor:[UIColor whiteColor]];
  [btn setFrame:CGRectMake(0, 0, textSize.width, textSize.height)];
  if (target) {
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
  }
  return btn;
}

+ (UIButton *)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle
               fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                        backgroundColor:(UIColor *)backgroundColor
           disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
                        verticalPadding:(CGFloat)verticalPadding
                      horizontalPadding:(CGFloat)horizontalPadding
                           cornerRadius:(CGFloat)cornerRadius
                                 target:(id)target
                                 action:(SEL)action {
  UIButton *btn = [self templateButtonWithTitleText:attributedTitle.string
                           fontForHeightCalculation:fontForHeightCalculation
                                    backgroundColor:backgroundColor
                       disabledStateBackgroundColor:disabledStateBackgroundColor
                                    verticalPadding:verticalPadding
                                  horizontalPadding:horizontalPadding
                                       cornerRadius:cornerRadius
                                             target:target
                                             action:action];
  [btn setAttributedTitle:attributedTitle forState:UIControlStateNormal];
  return btn;
}

+ (void)addDisclosureIndicatorToButton:(UIButton *)button {
  [PEUIUtils addDisclosureIndicatorToButton:button color:nil];
}

+ (void)addDisclosureIndicatorToButton:(UIButton *)button
                                 color:(UIColor *)color {
  [PEUIUtils addDisclosureIndicatorToButton:button
                                      color:color
                                   hpadding:[PEUIUtils valueIfiPhone5Width:20.0
                                                              iphone6Width:20.0
                                                          iphone6PlusWidth:20.0
                                                                      ipad:20.0]];
}

+ (void)addDisclosureIndicatorToButton:(UIButton *)button
                                 color:(UIColor *)color
                              hpadding:(CGFloat)hpadding {
  // hacky, but works
  UITableViewCell *disclosure = [[UITableViewCell alloc] init];
  [disclosure setBackgroundColor:[UIColor clearColor]];
  [disclosure setFrame:[button bounds]];
  [disclosure setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
  [disclosure setUserInteractionEnabled:NO];
  if (color) {
    // https://stackoverflow.com/a/36143640/1034895
    for (UIView *subview in disclosure.subviews) {
      if ([subview isMemberOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)subview;
        button.tintColor = color;
        UIImage *image = [[button backgroundImageForState:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setBackgroundImage:image forState:UIControlStateNormal];
      }
    }    
  }
  [PEUIUtils placeView:disclosure
            inMiddleOf:button
         withAlignment:PEUIHorizontalAlignmentTypeRight
              hpadding:hpadding];
}

+ (void)setBackgroundColorOfButton:(UIButton *)button
                             color:(UIColor *)color {
  UIImage *bgColorAsImgNormState = [PEUIUtils imageWithColor:color];
  [button setBackgroundImage:bgColorAsImgNormState forState:UIControlStateNormal];
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                 tagForButton:(NSNumber *)tagForButton
                  recordCount:(NSInteger)recordCount
       tagForRecordCountLabel:(NSNumber *)tagForRecordCountLabel
            addDisclosureIcon:(BOOL)addDisclosureIcon
    addlVerticalButtonPadding:(CGFloat)addlVerticalButtonPadding
 recordCountFromBottomPadding:(CGFloat)recordCountFromBottomPadding
       recordCountLeftPadding:(CGFloat)recordCountLeftPadding
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  UIButton *button = [PEUIUtils buttonWithKey:labelText
                                         font:[uitoolkit fontForButtonsBlk]()
                              backgroundColor:[UIColor whiteColor]
                                    textColor:[UIColor darkTextColor]
                 disabledStateBackgroundColor:[UIColor whiteColor]
                       disabledStateTextColor:[UIColor grayColor]
                              verticalPadding:([uitoolkit verticalPaddingForButtons] + addlVerticalButtonPadding)
                            horizontalPadding:[uitoolkit horizontalPaddingForButtons]
                                 cornerRadius:0.0
                                       target:nil
                                       action:nil];
  if (tagForButton) {
    [button setTag:[tagForButton integerValue]];
  }
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UILabel *recordCountLabel = [PEUIUtils labelForRecordCount:recordCount];
  if (tagForRecordCountLabel) {
    [recordCountLabel setTag:[tagForRecordCountLabel integerValue]];
  }
  [PEUIUtils placeRecordCountLabel:recordCountLabel
                        ontoButton:button
                          hpadding:recordCountLeftPadding
                          vpadding:recordCountFromBottomPadding];
  return button;
}

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView {
  UIButton *button = [uitoolkit systemButtonMaker](labelText, nil, nil);
  [[button layer] setCornerRadius:0.0];
  [PEUIUtils setFrameWidthOfView:button ofWidth:1.0 relativeTo:relativeToView];
  if (addDisclosureIcon) {
    [PEUIUtils addDisclosureIndicatorToButton:button];
  }
  [button bk_addEventHandler:^(id sender) {
    handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UIView *badge = [PEUIUtils badgeForNum:badgeNum color:badgeColor badgeTextColor:badgeTextColor];
  [PEUIUtils placeView:badge
            inMiddleOf:button
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:15.0];
  [PEUIUtils styleViewForIpad:button];
  return button;
}

#pragma mark - Panels

+ (void)cardifyView:(UIView *)view {
  view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
  view.layer.shadowOffset = CGSizeMake(0, 2);
  view.layer.shadowOpacity = 0.8;
  view.layer.shadowRadius = 3;
  view.layer.masksToBounds = NO;
}

+ (UIView *)displayPanelFromContentPanel:(UIView *)contentPanel
                               scrolling:(BOOL)scrolling
                        forceScrollPanel:(BOOL)forceScrollPanel
                     scrollContentOffset:(CGPoint)scrollContentOffset
                          scrollDelegate:(id<UIScrollViewDelegate>)scrollDelegate
                    delaysContentTouches:(BOOL)delaysContentTouches
                                 bounces:(BOOL)bounces
                        notScrollViewBlk:(void(^)(void))notScrollViewBlk
                              controller:(UIViewController *)controller {
  CGFloat contentPanelHeight = contentPanel.frame.size.height;
  CGFloat visibleControllerViewHeight = controller.view.frame.size.height;
  /*
   So, normally the status bar is translucent, and you're accordingly supposed
   to ignore the fact that it sits on top of the controller's view.  However,
   when there is a navigation bar present, it sits below the status bar, and as
   such, you have to take into account the status bar's height when calculating
   the total visible height of the controller's view.
   */
  if (controller.navigationController && !controller.navigationController.navigationBar.hidden) {
    visibleControllerViewHeight -= ([UIApplication sharedApplication].statusBarFrame.size.height +
                                      controller.navigationController.navigationBar.frame.size.height);
  }
  if (controller.tabBarController) {
    visibleControllerViewHeight -= controller.tabBarController.tabBar.frame.size.height;
  }
  UIScrollView *(^makeScrollView)(void) = ^UIScrollView * {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:controller.view.frame];
    [scrollView setDelegate:scrollDelegate];
    [scrollView setDelaysContentTouches:delaysContentTouches];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setBounces:bounces];
    [scrollView setContentSize:CGSizeMake(contentPanel.frame.size.width, (contentPanelHeight + (controller.view.frame.size.height / 1.5)))];
    [scrollView addSubview:contentPanel];
    [scrollView setContentOffset:scrollContentOffset animated:NO];
    [PEUIUtils setFrameWidth:contentPanel.frame.size.width ofView:scrollView];
    return scrollView;
  };
  if (forceScrollPanel) {
    return makeScrollView();
  }
  if (contentPanelHeight > visibleControllerViewHeight) {
    return makeScrollView();
  } else if ((contentPanelHeight * 2.0) <= visibleControllerViewHeight) {
    if (notScrollViewBlk) { notScrollViewBlk(); }
    return contentPanel;
  } else {
    if (scrolling) {
      return makeScrollView();
    } else {
      if (notScrollViewBlk) { notScrollViewBlk(); }
      return contentPanel;
    }
  }
}

+ (UIView *)dividerWithWidthOf:(CGFloat)widthOf
                         color:(UIColor *)color
                relativeToView:(UIView *)relativeToView {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:relativeToView fixedHeight:dividerHeight];
  [divider setBackgroundColor:color];
  return divider;
}

+ (UIView *)panelWithFixedWidth:(CGFloat)width
                    fixedHeight:(CGFloat)height {
  return [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
}

+ (UIView *)panelWithWidthOf:(CGFloat)percentage
              relativeToView:(UIView *)relativeToView
                 fixedHeight:(CGFloat)height {
  CGFloat width = relativeToView.frame.size.width * percentage;
  return [PEUIUtils panelWithFixedWidth:width fixedHeight:height];
}

+ (UIView *)panelWithWidthOf:(CGFloat)widthPercentage
                 andHeightOf:(CGFloat)heightPercentage
              relativeToView:(UIView *)relativeToView {
  CGFloat width = relativeToView.frame.size.width * widthPercentage;
  CGFloat height = relativeToView.frame.size.height * heightPercentage;
  return [PEUIUtils panelWithFixedWidth:width fixedHeight:height];
}

+ (UIView *)panelOfBrickLayedViewsFromItems:(NSArray *)items
                                  viewMaker:(UIView *(^)(NSInteger, id))viewMaker
                                  extraView:(UIView *)extraView
                             availableWidth:(CGFloat)availableWidth
                                   hpadding:(CGFloat)hpadding
                                   vpadding:(CGFloat)vpadding {
  UIView *panel = [PEUIUtils panelWithFixedWidth:availableWidth fixedHeight:0.0];
  NSInteger numItems = [items count];
  NSMutableArray *views = [NSMutableArray arrayWithCapacity:numItems];
  for (NSInteger i = 0; i < numItems; i++) {
    UIView *view = viewMaker(i, items[i]);
    [views addObject:view];
  }
  if (extraView) {
    [views addObject:extraView];
  }
  CGFloat totalHeight = 0.0;
  NSInteger numViews = views.count;
  NSInteger currentRow = 0;
  CGFloat widthOfBricks = 0.0;
  if (numViews > 0) {
    CGFloat actualAvailableWidth = availableWidth - (hpadding * 2);
    CGFloat usedWidth = 0.0;
    UIView *previousView = nil;
    for (NSInteger i = 0; i < numViews; i++) {
      UIView *view = views[i];
      if ((usedWidth + view.frame.size.width + hpadding) <= actualAvailableWidth) {
        if (previousView) {
          [PEUIUtils placeView:view toTheRightOf:previousView onto:panel withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:hpadding];
          if (view.frame.size.height > previousView.frame.size.height) {
            totalHeight += view.frame.size.height - previousView.frame.size.height;
          }
          usedWidth += view.frame.size.width + hpadding;
          if (usedWidth > widthOfBricks) {
            widthOfBricks = usedWidth;
          }
        } else {
          CGFloat topViewVPadding = currentRow > 0 ? vpadding : 0;
          [PEUIUtils placeView:view
                       atTopOf:panel
                 withAlignment:PEUIHorizontalAlignmentTypeLeft
                      vpadding:topViewVPadding
                      hpadding:0.0];
          totalHeight += view.frame.size.height + topViewVPadding;
          usedWidth = view.frame.size.width;
          if (usedWidth > widthOfBricks) {
            widthOfBricks = usedWidth;
          }
        }
      } else {
        currentRow++;
        [PEUIUtils placeView:view below:previousView onto:panel withAlignment:PEUIHorizontalAlignmentTypeLeft alignmentRelativeToView:panel vpadding:vpadding hpadding:0.0];
        totalHeight += view.frame.size.height + vpadding;
        usedWidth = view.frame.size.width;
        if (usedWidth > widthOfBricks) {
          widthOfBricks = usedWidth;
        }
      }
      previousView = view;
    }
  }
  [PEUIUtils setFrameHeight:totalHeight ofView:panel];
  [PEUIUtils setFrameWidth:widthOfBricks ofView:panel];
  return panel;
}

+ (UIView *)panelWithColumnOfViews:(NSArray *)views
       verticalPaddingBetweenViews:(CGFloat)vpadding
                    viewsAlignment:(PEUIHorizontalAlignmentType)alignment {
  UIView *panel =
    [PEUIUtils panelWithFixedWidth:[PEUIUtils widthWidestAmong:views]
                       fixedHeight:0];
  __block UIView *currentView = nil;
  __block CGFloat height = ([views count] - 1) * vpadding;
  [views enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
      if (currentView) {
        [PEUIUtils placeView:view
                       below:currentView
                        onto:panel
               withAlignment:alignment
                    vpadding:vpadding
                    hpadding:0];
      } else {
        [panel addSubview:view];
        [PEUIUtils setFrameX:[PEUIUtils XForWidth:view.frame.size.width
                                    withAlignment:alignment
                                   relativeToView:panel
                                         hpadding:0]
                      ofView:view];
      }
      currentView = view;
      height += [currentView frame].size.height;
    }];
  [PEUIUtils setFrameHeight:height ofView:panel];
  return panel;
}

+ (UIView *)panelWithRowOfViews:(NSArray *)views
  horizontalPaddingBetweenViews:(CGFloat)hpadding
                 viewsAlignment:(PEUIVerticalAlignmentType)alignment {
  UIView *panel = [PEUIUtils panelWithFixedWidth:0
                                     fixedHeight:[PEUIUtils heightHighestAmong:views]];
  __block UIView *currentView = nil;
  __block CGFloat width = ([views count] - 1) * hpadding;
  [views enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
    if (currentView) {
      [PEUIUtils placeView:view
              toTheRightOf:currentView
                      onto:panel
             withAlignment:alignment
                  hpadding:hpadding];
    } else {
      [panel addSubview:view];
      [PEUIUtils setFrameY:[PEUIUtils YForHeight:view.frame.size.height
                                   withAlignment:alignment
                                  relativeToView:panel
                                        vpadding:0]
                    ofView:view];
    }
    currentView = view;
    width += [currentView frame].size.width;
  }];
  [PEUIUtils setFrameWidth:width ofView:panel];
  return panel;
}

+ (UIView *)twoColumnViewCluster:(NSArray *)ltColViews
                 withRightColumn:(NSArray *)rtColViews
     verticalPaddingBetweenViews:(CGFloat)vpadding
 horizontalPaddingBetweenColumns:(CGFloat)hpadding {
  UIView *ltColContainerPnl =
    [PEUIUtils panelWithColumnOfViews:ltColViews
          verticalPaddingBetweenViews:vpadding
                       viewsAlignment:PEUIHorizontalAlignmentTypeRight];
  UIView *rtColContainerPnl =
    [PEUIUtils panelWithColumnOfViews:rtColViews
          verticalPaddingBetweenViews:vpadding
                       viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  UIView *mainPanel =
    [PEUIUtils panelWithFixedWidth:([ltColContainerPnl frame].size.width +
                                    [rtColContainerPnl frame].size.width +
                                    hpadding)
                       fixedHeight:(([ltColContainerPnl frame].size.height >
                                     [rtColContainerPnl frame].size.height) ?
                                    [ltColContainerPnl frame].size.height :
                                    [rtColContainerPnl frame].size.height)];
  [mainPanel addSubview:ltColContainerPnl];
  [PEUIUtils adjustYOfView:ltColContainerPnl
                 withValue:[PEUIUtils YForHeight:[ltColContainerPnl frame].size.height
                                   withAlignment:PEUIVerticalAlignmentTypeMiddle
                                  relativeToView:mainPanel
                                        vpadding:0]];
  [PEUIUtils placeView:rtColContainerPnl
          toTheRightOf:ltColContainerPnl
                  onto:mainPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:hpadding];
  return mainPanel;
}

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(UIFontTextStyle)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                              valueString:(NSString *)valueStr
                           valueTextStyle:(UIFontTextStyle)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
           minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                                 rowWidth:(CGFloat)rowWidth {
  UIView *rowPanel = [PEUIUtils panelWithFixedWidth:rowWidth fixedHeight:cellHeight];
  UILabel *label;
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
  UIFont *labelFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                        font:[UIFont preferredFontForTextStyle:labelTextStyle]];
  if ([labelStr isKindOfClass:[NSAttributedString class]]) {
    label = [PEUIUtils labelWithAttributeText:labelStr
                                         font:labelFont
                     fontForHeightCalculation:[self boldFontForTextStyle:labelTextStyle]
                              backgroundColor:[UIColor clearColor]
                                    textColor:labelTextColor
                          verticalTextPadding:0.0];
  } else {
    label = [PEUIUtils labelWithKey:labelStr
                               font:labelFont
                    backgroundColor:[UIColor clearColor]
                          textColor:labelTextColor
                verticalTextPadding:0.0];
  }
  UIFont *valueFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                                        font:[UIFont preferredFontForTextStyle:valueTextStyle]];
  CGFloat availableWidth = rowPanel.frame.size.width -
    label.frame.size.width -
    minPaddingBetweenLabelAndValue -
    labelLeftHPadding -
    valueRightHPadding;
  valueStr = [PEUIUtils truncatedTextForText:valueStr font:valueFont availableWidth:availableWidth];
  UILabel *value = [PEUIUtils labelWithKey:valueStr
                                      font:valueFont
                           backgroundColor:[UIColor clearColor]
                                 textColor:valueTextColor
                       verticalTextPadding:0.0];
  if (valueLabelTag) {
    [value setTag:[valueLabelTag integerValue]];
  }
  [PEUIUtils placeView:label inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:labelLeftHPadding];
  [PEUIUtils placeView:value inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:valueRightHPadding];
  return rowPanel;
}

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(UIFontTextStyle)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                            iconImageView:(UIImageView *)iconImageView
                              valueString:(NSString *)valueStr
                           valueTextStyle:(UIFontTextStyle)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
           minPaddingBetweenLabelAndIcon:(CGFloat)minPaddingBetweenLabelAndIcon
                                 rowWidth:(CGFloat)rowWidth
                           relativeToView:(UIView *)relativeToView {
  UIView *rowPanel = [PEUIUtils panelWithFixedWidth:rowWidth fixedHeight:cellHeight];
  UILabel *label;
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
  UIFont *labelFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:labelTextStyle]];
  if ([labelStr isKindOfClass:[NSAttributedString class]]) {
    label = [PEUIUtils labelWithAttributeText:labelStr
                                         font:labelFont
                     fontForHeightCalculation:[self boldFontForTextStyle:labelTextStyle]
                              backgroundColor:[UIColor clearColor]
                                    textColor:labelTextColor
                          verticalTextPadding:0.0];
  } else {
    label = [PEUIUtils labelWithKey:labelStr
                               font:labelFont
                    backgroundColor:[UIColor clearColor]
                          textColor:labelTextColor
                verticalTextPadding:0.0];
  }
  UIFont *valueFont = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize font:[UIFont preferredFontForTextStyle:valueTextStyle]];
  CGFloat availableWidth = rowPanel.frame.size.width -
  label.frame.size.width -
  minPaddingBetweenLabelAndIcon -
  labelLeftHPadding -
  valueRightHPadding;
  valueStr = [PEUIUtils truncatedTextForText:valueStr font:valueFont availableWidth:availableWidth];
  UILabel *value = [PEUIUtils labelWithKey:valueStr
                                      font:valueFont
                           backgroundColor:[UIColor clearColor]
                                 textColor:valueTextColor
                       verticalTextPadding:0.0];
  if (valueLabelTag) {
    [value setTag:[valueLabelTag integerValue]];
  }
  UIView *iconAndValueLabelPanel = [PEUIUtils panelWithFixedWidth:value.frame.size.width
                                                      fixedHeight:value.frame.size.height + 5.0 + iconImageView.frame.size.height];
  //[iconAndValueLabelPanel setBackgroundColor:[UIColor yellowColor]];
  [PEUIUtils placeView:iconImageView atTopOf:iconAndValueLabelPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:3.0 hpadding:0.0];
  [PEUIUtils placeView:value below:iconImageView onto:iconAndValueLabelPanel withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:2.0 hpadding:0.0];
  
  [PEUIUtils placeView:label inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:labelLeftHPadding];
  [PEUIUtils placeView:iconAndValueLabelPanel inMiddleOf:rowPanel withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:valueRightHPadding];
  return rowPanel;
}

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(UIFontTextStyle)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                            iconImageName:(NSString *)iconImageName
                              valueString:(NSString *)valueStr
                           valueTextStyle:(UIFontTextStyle)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
            minPaddingBetweenLabelAndIcon:(CGFloat)minPaddingBetweenLabelAndIcon
                                 rowWidth:(CGFloat)rowWidth
                           relativeToView:(UIView *)relativeToView {
  return [PEUIUtils labelValuePanelWithCellHeight:cellHeight
                                      labelString:labelStr
                                   labelTextStyle:labelTextStyle
                                   labelTextColor:labelTextColor
                                labelLeftHPadding:labelLeftHPadding
                                    iconImageView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:iconImageName]]
                                      valueString:valueStr
                                   valueTextStyle:valueTextStyle
                                   valueTextColor:valueTextColor
                               valueRightHPadding:valueRightHPadding
                                    valueLabelTag:valueLabelTag
                    minPaddingBetweenLabelAndIcon:minPaddingBetweenLabelAndIcon
                                         rowWidth:rowWidth
                                   relativeToView:relativeToView];
}

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(UIFontTextStyle)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                             iconImageUrl:(NSString *)iconImageUrl
                              valueString:(NSString *)valueStr
                           valueTextStyle:(UIFontTextStyle)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
            minPaddingBetweenLabelAndIcon:(CGFloat)minPaddingBetweenLabelAndIcon
                                 rowWidth:(CGFloat)rowWidth
                           relativeToView:(UIView *)relativeToView {
  UIImageView *iconImageView = [[UIImageView alloc] init];
  [iconImageView setImageWithURL:[NSURL URLWithString:iconImageUrl]];
  return [PEUIUtils labelValuePanelWithCellHeight:cellHeight
                                      labelString:labelStr
                                   labelTextStyle:labelTextStyle
                                   labelTextColor:labelTextColor
                                labelLeftHPadding:labelLeftHPadding
                                    iconImageView:iconImageView
                                      valueString:valueStr
                                   valueTextStyle:valueTextStyle
                                   valueTextColor:valueTextColor
                               valueRightHPadding:valueRightHPadding
                                    valueLabelTag:valueLabelTag
                    minPaddingBetweenLabelAndIcon:minPaddingBetweenLabelAndIcon
                                         rowWidth:rowWidth
                                   relativeToView:relativeToView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(UIFontTextStyle)labelTextStyle
                   valueTextStyle:(UIFontTextStyle)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
                         rowWidth:(CGFloat)rowWidth
                   relativeToView:(UIView *)relativeToView {
  return [PEUIUtils tablePanelWithRowData:rowData
                           withCellHeight:cellHeight
                        labelLeftHPadding:labelLeftHPadding
                       valueRightHPadding:valueRightHPadding
                           labelTextStyle:labelTextStyle
                           valueTextStyle:valueTextStyle
                           labelTextColor:labelTextColor
                           valueTextColor:valueTextColor
           minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                        includeTopDivider:includeTopDivider
                     includeBottomDivider:includeBottomDivider
                     includeInnerDividers:includeInnerDividers
                  innerDividerWidthFactor:innerDividerWidthFactor
                           dividerPadding:dividerPadding
                  rowPanelBackgroundColor:rowPanelPackgroundColor
                     panelBackgroundColor:panelBackgroundColor
                             dividerColor:dividerColor
                     footerAttributedText:nil
           footerFontForHeightCalculation:nil
                    footerVerticalPadding:0.0
                                 rowWidth:rowWidth
                                 maxWidth:relativeToView.frame.size.width
                           relativeToView:relativeToView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(UIFontTextStyle)labelTextStyle
                   valueTextStyle:(UIFontTextStyle)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                         maxWidth:(CGFloat)maxWidth
                   relativeToView:(UIView *)relativeToView {
  CGFloat maxWidthOfLabelLbl = 0.0;
  CGFloat maxWidthOfValueLbl = 0.0;
  for (NSArray *row in rowData) {
    NSString *labelStr = row[0];
    NSString *valueStr = row[1];
    CGFloat wouldBeWidthOfValueLbl = [PEUIUtils sizeOfText:valueStr
                                                  withFont:[self boldFontForTextStyle:valueTextStyle]].width;
    if (wouldBeWidthOfValueLbl > maxWidthOfValueLbl) {
      maxWidthOfValueLbl = wouldBeWidthOfValueLbl;
    }
    CGFloat wouldBeWidthOfLabelLbl = [PEUIUtils sizeOfText:labelStr
                                                  withFont:[self boldFontForTextStyle:labelTextStyle]].width;
    if (wouldBeWidthOfLabelLbl > maxWidthOfLabelLbl) {
      maxWidthOfLabelLbl = wouldBeWidthOfLabelLbl;
    }
  }
  CGFloat totalWidthNeeded = labelLeftHPadding + maxWidthOfLabelLbl + minPaddingBetweenLabelAndValue + maxWidthOfValueLbl + valueRightHPadding;
  if (totalWidthNeeded > relativeToView.frame.size.width) {
    totalWidthNeeded = relativeToView.frame.size.width;
  }
  return [self tablePanelWithRowData:rowData
                      withCellHeight:cellHeight
                   labelLeftHPadding:labelLeftHPadding
                  valueRightHPadding:valueRightHPadding
                      labelTextStyle:(UIFontTextStyle)labelTextStyle
                      valueTextStyle:(UIFontTextStyle)valueTextStyle
                      labelTextColor:labelTextColor
                      valueTextColor:valueTextColor
      minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                   includeTopDivider:includeTopDivider
                includeBottomDivider:includeBottomDivider
                includeInnerDividers:includeInnerDividers
             innerDividerWidthFactor:innerDividerWidthFactor
                      dividerPadding:dividerPadding
             rowPanelBackgroundColor:rowPanelPackgroundColor
                panelBackgroundColor:panelBackgroundColor
                        dividerColor:dividerColor
                footerAttributedText:footerAttributedText
      footerFontForHeightCalculation:footerFontForHeightCalculation
               footerVerticalPadding:footerVerticalPadding
                            rowWidth:totalWidthNeeded
                            maxWidth:maxWidth
                      relativeToView:relativeToView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                   withCellHeight:(CGFloat)cellHeight
                labelLeftHPadding:(CGFloat)labelLeftHPadding
               valueRightHPadding:(CGFloat)valueRightHPadding
                   labelTextStyle:(UIFontTextStyle)labelTextStyle
                   valueTextStyle:(UIFontTextStyle)valueTextStyle
                   labelTextColor:(UIColor *)labelTextColor
                   valueTextColor:(UIColor *)valueTextColor
   minPaddingBetweenLabelAndValue:(CGFloat)minPaddingBetweenLabelAndValue
                includeTopDivider:(BOOL)includeTopDivider
             includeBottomDivider:(BOOL)includeBottomDivider
             includeInnerDividers:(BOOL)includeInnerDividers
          innerDividerWidthFactor:(CGFloat)innerDividerWidthFactor
                   dividerPadding:(CGFloat)dividerPadding
          rowPanelBackgroundColor:(UIColor *)rowPanelPackgroundColor
             panelBackgroundColor:(UIColor *)panelBackgroundColor
                     dividerColor:(UIColor *)dividerColor
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                         rowWidth:(CGFloat)rowWidth
                         maxWidth:(CGFloat)maxWidth
                   relativeToView:(UIView *)relativeToView {
  CGFloat dividerHeight = (1.0 / [UIScreen mainScreen].scale);
  NSInteger numRows = [rowData count];
  CGFloat innerDividerPaddingFactor = includeInnerDividers ? 2.0 : 1.5;
  CGFloat panelHeight = (includeTopDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // top divider and its padding
    (includeBottomDivider ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : 0) + // bottom divider and its padding
    (numRows * cellHeight) + // cumulative cell height
    (includeInnerDividers ? ((numRows - 1) * dividerHeight) : 0) + // cumulative height of inner dividers
    ((numRows -1) * (innerDividerPaddingFactor * dividerPadding)); // cumulative height of inner divider paddings
  CGFloat panelWidth = rowWidth;
  if (rowWidth > maxWidth) {
    panelWidth = maxWidth;
  }
  UIView *panel = [PEUIUtils panelWithFixedWidth:panelWidth fixedHeight:panelHeight];
  [panel setBackgroundColor:panelBackgroundColor];
  UIView *divider = nil;
  UIView *(^makeDivider)(CGFloat) = ^ UIView * (CGFloat widthOf) {
    UIView *divider = [PEUIUtils panelWithWidthOf:widthOf relativeToView:relativeToView fixedHeight:dividerHeight];
    [divider setBackgroundColor:dividerColor];
    return divider;
  };
  UIView *topDivider = nil;
  if (includeTopDivider) {
    topDivider = makeDivider(1.0);
    [PEUIUtils placeView:topDivider atTopOf:panel withAlignment:PEUIHorizontalAlignmentTypeLeft vpadding:0.0 hpadding:0.0];
  }
  UIView *aboveRowPanel = topDivider;
  for (int i = 0; i < numRows; i++) {
    NSArray *cellData = rowData[i];
    id labelStr = cellData[0];
    NSString *valueStr = cellData[1];
    UIView *rowPanel = [PEUIUtils labelValuePanelWithCellHeight:cellHeight
                                                    labelString:labelStr
                                                 labelTextStyle:labelTextStyle
                                                 labelTextColor:labelTextColor
                                              labelLeftHPadding:labelLeftHPadding
                                                    valueString:valueStr
                                                 valueTextStyle:valueTextStyle
                                                 valueTextColor:valueTextColor
                                             valueRightHPadding:valueRightHPadding
                                                  valueLabelTag:@(i + 1)
                                 minPaddingBetweenLabelAndValue:minPaddingBetweenLabelAndValue
                                                       rowWidth:panelWidth];
    [rowPanel setBackgroundColor:rowPanelPackgroundColor];
    [PEUIUtils styleViewForIpad:rowPanel];
    if (i == 0) {
      if (includeTopDivider) {
        [PEUIUtils placeView:rowPanel
                       below:topDivider
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:(innerDividerPaddingFactor * dividerPadding)
                    hpadding:0.0];
      } else {
        [PEUIUtils placeView:rowPanel
                     atTopOf:panel
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:0.0
                    hpadding:0.0];
      }
    } else {
      [PEUIUtils placeView:rowPanel
                     below:aboveRowPanel
                      onto:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:(includeInnerDividers ? (dividerHeight + (innerDividerPaddingFactor * dividerPadding)) : (innerDividerPaddingFactor * dividerPadding))
                  hpadding:0.0];
    }
    aboveRowPanel = rowPanel;
    if (includeInnerDividers) {
      if (i + 1 < numRows) {
        divider = makeDivider(innerDividerWidthFactor);
        [PEUIUtils placeView:divider
                       below:rowPanel
                        onto:panel
               withAlignment:PEUIHorizontalAlignmentTypeRight
                    vpadding:dividerPadding
                    hpadding:0.0];
      }
    }
  }
  if (includeBottomDivider) {
    UIView *bottomDivider = makeDivider(1.0);
    if (aboveRowPanel) {
      [PEUIUtils placeView:bottomDivider
                     below:aboveRowPanel
                      onto:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:(innerDividerPaddingFactor * dividerPadding)
                  hpadding:0.0];
    } else {
      [PEUIUtils placeView:bottomDivider
                atTopOf:panel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:0.0
                  hpadding:0.0];
    }
    aboveRowPanel = bottomDivider;
  }
  if (footerAttributedText) {
    UILabel *footerLabel = [PEUIUtils labelWithAttributeText:footerAttributedText
                                                        font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                    fontForHeightCalculation:footerFontForHeightCalculation
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor darkGrayColor]
                                         verticalTextPadding:3.0
                                                  fitToWidth:(panel.frame.size.width - 8)];
    [PEUIUtils placeView:footerLabel
                   below:aboveRowPanel
                    onto:panel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:footerVerticalPadding
                hpadding:10.0];
    [PEUIUtils setFrameHeight:(panel.frame.size.height + footerVerticalPadding + footerLabel.frame.size.height) ofView:panel];
  }
  return panel;
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
  return [PEUIUtils tablePanelWithRowData:rowData
                     footerAttributedText:nil
           footerFontForHeightCalculation:nil
                    footerVerticalPadding:0.0
                                uitoolkit:uitoolkit
                               parentView:parentView];
}

+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView {
  return [PEUIUtils tablePanelWithRowData:rowData
                           withCellHeight:([PEUIUtils sizeOfText:@"" withFont:[self boldFontForTextStyle:UIFontTextStyleBody]].height + uitoolkit.verticalPaddingForButtons)
                        labelLeftHPadding:10.0
                       valueRightHPadding:12.5
                           labelTextStyle:UIFontTextStyleBody
                           valueTextStyle:UIFontTextStyleBody
                           labelTextColor:[UIColor blackColor]
                           valueTextColor:[UIColor grayColor]
           minPaddingBetweenLabelAndValue:10.0
                        includeTopDivider:NO
                     includeBottomDivider:NO
                     includeInnerDividers:NO
                  innerDividerWidthFactor:0.95
                           dividerPadding:3.5
                  rowPanelBackgroundColor:[UIColor whiteColor]
                     panelBackgroundColor:[uitoolkit colorForWindows]
                             dividerColor:nil
                     footerAttributedText:footerAttributedText
           footerFontForHeightCalculation:footerFontForHeightCalculation
                    footerVerticalPadding:footerVerticalPadding
                                 rowWidth:parentView.frame.size.width
                                 maxWidth:parentView.frame.size.width
                           relativeToView:parentView];
}


+ (UIView *)panelWithViews:(NSArray *)views
                   ofWidth:(CGFloat)percentage
      vertAlignmentOfViews:(PEUIVerticalAlignmentType)vertAlignment
       horAlignmentOfViews:(PEUIHorizontalAlignmentType)horAlignment
                relativeTo:(UIView *)relativeToView
                  vpadding:(CGFloat)vpadding
                  hpadding:(CGFloat)hpadding {
  UIView *viewHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  NSUInteger numViews = [views count];
  int tallestHeight = 0;
  if (numViews > 0) {
    UIView *view = [views objectAtIndex:0];
    [viewHolder addSubview:view];
    int runningWidth = [view frame].size.width;
    tallestHeight = [view frame].size.height;
    UIView *previousView = view;
    for (int i = 1; i < numViews; i++) {
      view = [views objectAtIndex:i];
      [PEUIUtils placeView:view
              toTheRightOf:previousView
                      onto:viewHolder
             withAlignment:vertAlignment
                  hpadding:hpadding];
      runningWidth += [view frame].size.width + hpadding;
      if ([view frame].size.height > tallestHeight) {
        tallestHeight = [view frame].size.height;
      }
      previousView = view;
    }
    [PEUIUtils setFrameWidth:runningWidth ofView:viewHolder];
    [PEUIUtils setFrameHeight:tallestHeight ofView:viewHolder];
  }
  UIView *outerPnl = [PEUIUtils panelWithWidthOf:percentage
                                  relativeToView:relativeToView
                                     fixedHeight:tallestHeight];
  [PEUIUtils placeView:viewHolder
            inMiddleOf:outerPnl
         withAlignment:horAlignment
              hpadding:0];
  return outerPnl;
}

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
               description:(NSAttributedString *)description
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
            availableWidth:(CGFloat)availableWidth {
  return [PEUIUtils panelWithMsgs:nil
                            title:title
                       titleImage:titleImage
                      description:description
              descLblHeightAdjust:descLblHeightAdjust
                footerDescription:nil
                      messageIcon:nil
            messageIconTopPadding:0.0
                   availableWidth:availableWidth];
}

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
           descriptionText:(NSString *)descriptionText
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
           instructionText:(NSString *)instructionText
            availableWidth:(CGFloat)availableWidth {
  UIFont* boldSubheadlineFont = [self boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSString *descTextWithInstructionalText = [NSString stringWithFormat:@"%@%@", descriptionText, instructionText];
  NSDictionary *attrs = @{ NSFontAttributeName : boldSubheadlineFont };
  NSMutableAttributedString *attrDescTextWithInstructionalText =
    [[NSMutableAttributedString alloc] initWithString:descTextWithInstructionalText];
  NSRange instructionTextRange  = [descTextWithInstructionalText rangeOfString:instructionText];
  if (instructionTextRange.length > 0) {
    [attrDescTextWithInstructionalText setAttributes:attrs range:instructionTextRange];
  }
  return [PEUIUtils panelWithTitle:title
                        titleImage:titleImage
                       description:attrDescTextWithInstructionalText
               descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                    availableWidth:availableWidth];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        footerDescription:(NSAttributedString *)footerDescription
              messageIcon:(UIImage *)messageIcon
    messageIconTopPadding:(CGFloat)messageIconTopPadding
           availableWidth:(CGFloat)availableWidth {
  return [PEUIUtils panelWithMsgs:msgs
                            title:title
                       titleImage:titleImage
                      description:description
              descLblHeightAdjust:descLblHeightAdjust
                footerDescription:footerDescription
                  descriptionFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                      messageIcon:messageIcon
            messageIconTopPadding:messageIconTopPadding
                   availableWidth:availableWidth];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        footerDescription:(NSAttributedString *)footerDescription
          descriptionFont:(UIFont *)descriptionFont
              messageIcon:(UIImage *)messageIcon
    messageIconTopPadding:(CGFloat)messageIconTopPadding
           availableWidth:(CGFloat)availableWidth {
  return [PEUIUtils panelWithMsgs:msgs
                            title:title
                       titleImage:titleImage
                    topRightImage:nil
                      description:description
              descLblHeightAdjust:descLblHeightAdjust
                footerDescription:footerDescription
                  descriptionFont:descriptionFont
                      messageIcon:messageIcon
            messageIconTopPadding:messageIconTopPadding
                   availableWidth:availableWidth];
}

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
            topRightImage:(UIImage *)topRightImage
              description:(NSAttributedString *)description
      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        footerDescription:(NSAttributedString *)footerDescription
          descriptionFont:(UIFont *)descriptionFont
              messageIcon:(UIImage *)messageIcon
    messageIconTopPadding:(CGFloat)messageIconTopPadding
           availableWidth:(CGFloat)availableWidth {
  UIView *contentView = [PEUIUtils panelWithFixedWidth:availableWidth * [PEUIUtils valueIfiPhone5Width:0.905 iphone6Width:0.905 iphone6PlusWidth:0.905 ipad:0.905]
                                           fixedHeight:0.0];
  UIView *topPanel;
  CGFloat topViewHeight = 0.0;
  UIFont* boldBodyFont = [self boldFontForTextStyle:[PEUIUtils fontTextStyleIfiPhone5Width:UIFontTextStyleBody
                                                                              iphone6Width:UIFontTextStyleBody
                                                                          iphone6PlusWidth:UIFontTextStyleBody
                                                                                      ipad:UIFontTextStyleTitle3]];
  if (title) {
    UILabel *(^makeTitleLabel)(CGFloat) = ^ UILabel * (CGFloat widthToFit) {
      return [PEUIUtils labelWithKey:title
                                font:boldBodyFont
                     backgroundColor:[UIColor clearColor]
                           textColor:[UIColor blackColor]
                 verticalTextPadding:0.0
                          fitToWidth:widthToFit];
    };
    if (titleImage) {
      CGFloat leftPaddingForTitleImg = 2.0;
      CGFloat paddingBetweenTitleImgAndLabel = 8.0;
      UIImageView *titleImageView = [[UIImageView alloc] initWithImage:titleImage];
      UILabel *titleLbl = makeTitleLabel(contentView.frame.size.width - titleImageView.frame.size.width - leftPaddingForTitleImg - (paddingBetweenTitleImgAndLabel * 2.0));
      topViewHeight += (titleImageView.frame.size.height > titleLbl.frame.size.height
                       ? titleImageView.frame.size.height : titleLbl.frame.size.height);
      topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
      [PEUIUtils placeView:titleImageView
                inMiddleOf:topPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:leftPaddingForTitleImg];
      [PEUIUtils placeView:titleLbl
              toTheRightOf:titleImageView
                      onto:topPanel
             withAlignment:PEUIVerticalAlignmentTypeMiddle
                  hpadding:paddingBetweenTitleImgAndLabel];
    } else {
      UILabel *titleLbl = makeTitleLabel(contentView.frame.size.width);
      topViewHeight += titleLbl.frame.size.height;
      topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
      [PEUIUtils placeView:titleLbl
                inMiddleOf:topPanel
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  hpadding:2.0];
    }
  } else {
    topPanel = [PEUIUtils panelWithFixedWidth:0.0 fixedHeight:topViewHeight];
  }
  UIFont* boldSubheadlineFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  UILabel *descriptionLbl = [PEUIUtils labelWithAttributeText:description
                                                         font:descriptionFont
                                     fontForHeightCalculation:boldSubheadlineFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0
                                                   fitToWidth:contentView.frame.size.width - [PEUIUtils valueIfiPhone5Width:5.0 iphone6Width:5.0 iphone6PlusWidth:5.0 ipad:5.0]];//35.0]];
  [PEUIUtils adjustHeightOfView:descriptionLbl withValue:descLblHeightAdjust];
  UILabel *footerDescriptionLbl = nil;
  if (footerDescription) {
    UIFont *footerFont = [PEUIUtils italicFontForTextStyle:UIFontTextStyleCaption1];
    footerDescriptionLbl = [PEUIUtils labelWithAttributeText:footerDescription
                                                        font:footerFont
                                    fontForHeightCalculation:footerFont
                                             backgroundColor:[UIColor clearColor]
                                                   textColor:[UIColor blackColor]
                                         verticalTextPadding:0.0
                                                  fitToWidth:contentView.frame.size.width - 5.0];
  }
  UIImageView *topRightImageView = nil;
  if (topRightImage) {
    topRightImageView = [[UIImageView alloc] initWithImage:topRightImage];
  }
  UIView *alertPanelsColumn = nil;
  if ([msgs count] > 0) {
    alertPanelsColumn = [PEUIUtils panelWithColumnOfViews:[PEUIUtils alertPanelsForMessages:msgs
                                                                                      width:contentView.frame.size.width
                                                                                leftImgIcon:messageIcon
                                                                      leftImgIconTopPadding:messageIconTopPadding]
                              verticalPaddingBetweenViews:3.0
                                           viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
  }
  CGFloat topPanelVpadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:3.0 iphone6PlusWidth:4.0 ipad:8.0];
  CGFloat panelsVpadding = alertPanelsColumn != nil ? 13.0 : 0.0;
  CGFloat contentViewHeight = topViewHeight + descriptionLbl.frame.size.height + alertPanelsColumn.frame.size.height;
  if (footerDescriptionLbl) {
    contentViewHeight += footerDescriptionLbl.frame.size.height + 10.0;
  }
  CGFloat descriptionVpadding = 13.0;
  contentViewHeight += topPanelVpadding + descriptionVpadding + panelsVpadding;
  // now add a little bit more height so there's some nice bottom-padding; we'll have more
  // padding for when we have no messages panel-column.
  if ([msgs count] > 0) {
    contentViewHeight += 7.5;
  } else {
    contentViewHeight += 10.0;
  }
  contentViewHeight += [PEUIUtils valueIfiPhone5Width:0.0 iphone6Width:0.0 iphone6PlusWidth:0.0 ipad:5.0]; // for some extra bottom margin
  [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
  if (topRightImageView) {
    [PEUIUtils placeView:topRightImageView atTopOf:contentView withAlignment:PEUIHorizontalAlignmentTypeRight vpadding:3.0 hpadding:3.0];
  }
  CGFloat hpadding = [PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:3.0 iphone6PlusWidth:3.5 ipad:6.0];
  [PEUIUtils placeView:topPanel
               atTopOf:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:topPanelVpadding
              hpadding:hpadding];
  [PEUIUtils placeView:descriptionLbl
                 below:topPanel
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentView
              vpadding:descriptionVpadding
              hpadding:hpadding];
  if (alertPanelsColumn) {
    [PEUIUtils placeView:alertPanelsColumn
                   below:descriptionLbl
                    onto:contentView
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:panelsVpadding
                hpadding:hpadding];
    if (footerDescriptionLbl) {
      [PEUIUtils placeView:footerDescriptionLbl
                     below:alertPanelsColumn
                      onto:contentView
             withAlignment:PEUIHorizontalAlignmentTypeLeft
   alignmentRelativeToView:contentView
                  vpadding:10.0
                  hpadding:hpadding];
    }
  }
  return contentView;
}

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                width:(CGFloat)width {
  NSMutableArray *failurePanels = [NSMutableArray arrayWithCapacity:[failures count]];
  for (NSArray *failure in failures) {
    NSString *failureTitle = failure[0];
    //BOOL isFailureFixableByUser = [failure[1] boolValue];
    NSArray *failureReasons = failure[2];
    UIView *failureReasonsPanel = [PEUIUtils panelWithColumnOfViews:[PEUIUtils alertPanelsForMessages:failureReasons
                                                                                                width:(width - (width * 0.05))
                                                                                          leftImgIcon:[UIImage imageNamed:@"black-dot"]
                                                                                leftImgIconTopPadding:6.0]
                                        verticalPaddingBetweenViews:0.0
                                                     viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    UIView *failurePanel = [PEUIUtils messagePanelWithTitle:failureTitle
                                                leftImgIcon:[UIImage imageNamed:@"red-exclamation-icon"]
                                      leftImgIconTopPadding:3.0
                                                      width:width];
    [PEUIUtils setFrameHeight:(failurePanel.frame.size.height + failureReasonsPanel.frame.size.height)
                       ofView:failurePanel];
    [PEUIUtils placeView:failureReasonsPanel
              atBottomOf:failurePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:(width * 0.05)];
    [failurePanels addObject:failurePanel];
  }
  return [PEUIUtils panelWithColumnOfViews:failurePanels
               verticalPaddingBetweenViews:1.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                          description:(NSAttributedString *)description
                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView {
  return [PEUIUtils failuresPanelWithFailures:failures
                                        title:nil
                                  description:description
                          descLblHeightAdjust:descLblHeightAdjust
                              descriptionFont:descriptionFont
                               relativeToView:relativeToView];
}



+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                title:(NSString *)title
                          description:(NSAttributedString *)description
                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView {
  UIView *contentView = [PEUIUtils panelWithMsgs:nil
                                           title:title
                                      titleImage:(title != nil ? [UIImage imageNamed:@"red-exclamation"] : nil)
                                     description:description
                             descLblHeightAdjust:descLblHeightAdjust
                               footerDescription:nil
                                 descriptionFont:descriptionFont
                                     messageIcon:nil
                           messageIconTopPadding:0.0
                                  availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]];
  UIView *failuresPanel = [PEUIUtils failuresPanelWithFailures:failures
                                                         width:contentView.frame.size.width];
  // extending the height here will give a nice bit of bottom-padding
  [PEUIUtils setFrameHeight:failuresPanel.frame.size.height + 6.5 ofView:failuresPanel];
  return [PEUIUtils panelWithColumnOfViews:@[contentView, failuresPanel]
               verticalPaddingBetweenViews:0.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UIView *)mixedResultsPanelWithSuccessMsgs:(NSArray *)successMsgs
                                       title:(NSString *)title
                                 description:(NSAttributedString *)description
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         failuresDescription:(NSAttributedString *)failuresDescription
                                    failures:(NSArray *)failures
                              relativeToView:(UIView *)relativeToView {
  UIView *successesContent = [PEUIUtils panelWithMsgs:successMsgs
                                                title:title
                                           titleImage:[UIImage imageNamed:@"warning"]
                                          description:description
                                  descLblHeightAdjust:descLblHeightAdjust
                                    footerDescription:nil
                                          messageIcon:[UIImage imageNamed:@"green-checkmark-small-icon"]
                                messageIconTopPadding:4.0
                                       availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]];
  UIView *failuresContent = [PEUIUtils failuresPanelWithFailures:failures
                                                     description:failuresDescription
                                             descLblHeightAdjust:descLblHeightAdjust
                                                 descriptionFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                                  relativeToView:relativeToView];
  return [PEUIUtils panelWithColumnOfViews:@[successesContent, failuresContent]
               verticalPaddingBetweenViews:0.0
                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
}

+ (UIView *)loginSuccessPanelWithTitle:(NSString *)title
                           description:(NSAttributedString *)description
                       descriptionFont:(UIFont *)descriptionFont
                       syncIconMessage:(NSAttributedString *)syncIconMessage
                         syncImageIcon:(UIImage *)syncImageIcon
                        relativeToView:(UIView *)relativeToView {
  UIView *contentView = [PEUIUtils panelWithWidthOf:0.905 relativeToView:relativeToView fixedHeight:0];
  UIView *topPanel;
  CGFloat topViewHeight;
  UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green-checkmark"]];
  CGFloat leftPaddingForTitleImg = 2.0;
  CGFloat paddingBetweenTitleImgAndLabel = 8.0;
  UILabel *titleLbl = [PEUIUtils labelWithKey:title
                                         font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                              backgroundColor:[UIColor clearColor]
                                    textColor:[UIColor blackColor]
                          verticalTextPadding:0.0
                                   fitToWidth:(contentView.frame.size.width - titleImageView.frame.size.width - leftPaddingForTitleImg - paddingBetweenTitleImgAndLabel)];
  topViewHeight = (titleImageView.frame.size.height > titleLbl.frame.size.height
                   ? titleImageView.frame.size.height : titleLbl.frame.size.height);
  topPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:contentView fixedHeight:topViewHeight];
  [PEUIUtils placeView:titleImageView
            inMiddleOf:topPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:leftPaddingForTitleImg];
  [PEUIUtils placeView:titleLbl
          toTheRightOf:titleImageView
                  onto:topPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:paddingBetweenTitleImgAndLabel];
  UILabel *descriptionLbl = [PEUIUtils labelWithAttributeText:description
                                                         font:descriptionFont
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor blackColor]
                                          verticalTextPadding:0.0
                                                   fitToWidth:contentView.frame.size.width];
  UILabel *syncIconMessageLbl = [PEUIUtils labelWithAttributeText:syncIconMessage
                                                             font:descriptionFont
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor blackColor]
                                              verticalTextPadding:0.0
                                                       fitToWidth:contentView.frame.size.width];
  UIImageView *syncMsgIconImageView = [[UIImageView alloc] initWithImage:syncImageIcon];
  CGFloat topPanelVpadding = 3.0;
  CGFloat contentViewHeight = topViewHeight + descriptionLbl.frame.size.height + syncIconMessageLbl.frame.size.height + syncMsgIconImageView.frame.size.height;
  CGFloat descriptionVpadding = 13.0;
  CGFloat syncIconMessageVpadding = 15.0;
  CGFloat syncMsgIconImageVpadding = 7.0;
  contentViewHeight += topPanelVpadding + descriptionVpadding + syncIconMessageVpadding + syncMsgIconImageVpadding;
  // now add a little bit more height so there's some nice bottom-padding; we'll have more
  // padding for when we have no messages panel-column.
  contentViewHeight += 5.0;
  [PEUIUtils setFrameHeight:contentViewHeight ofView:contentView];
  [PEUIUtils placeView:topPanel
               atTopOf:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:topPanelVpadding
              hpadding:0.0];
  [PEUIUtils placeView:descriptionLbl
                 below:topPanel
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:descriptionVpadding
              hpadding:3.0];
  [PEUIUtils placeView:syncIconMessageLbl
                 below:descriptionLbl
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:syncIconMessageVpadding
              hpadding:0.0];
  [PEUIUtils placeView:syncMsgIconImageView
                 below:syncIconMessageLbl
                  onto:contentView
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:syncMsgIconImageVpadding
              hpadding:7.0];
  return contentView;
}

+ (UIView *)leftPaddingMessageWithText:(NSString *)text
                        relativeToView:(UIView *)relativeToView {
  return [PEUIUtils leftPaddingMessageWithAttributedText:[[NSAttributedString alloc] initWithString:text]
                                          relativeToView:relativeToView];
}

+ (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText
                                  relativeToView:(UIView *)relativeToView {
  return [PEUIUtils leftPaddingMessageWithAttributedText:attrText
                                fontForHeightCalculation:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                          relativeToView:relativeToView];
}

+ (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText
                        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                                  relativeToView:(UIView *)relativeToView {
  CGFloat leftPadding = 8.0 + [PEUIUtils iphoneXSafeInsetsSide];
  UILabel *label = [PEUIUtils labelWithAttributeText:attrText
                                                font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                            fontForHeightCalculation:fontForHeightCalculation
                                     backgroundColor:[UIColor clearColor]
                                           textColor:[UIColor darkGrayColor]
                                 verticalTextPadding:3.0
                                          fitToWidth:relativeToView.frame.size.width - (leftPadding * 2)];
  return [PEUIUtils leftPadView:label padding:leftPadding];
}

+ (UIView *)thinHeadingPanelWithKey:(NSString *)text
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                     relativeToView:(UIView *)relativeToView {
  UILabel *headingPanelLabel = [PEUIUtils labelWithKey:text
                                                  font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleTitle3]
                                       backgroundColor:[UIColor clearColor]
                                             textColor:textColor
                                   verticalTextPadding:[PEUIUtils valueIfiPhone5Width:3.0 iphone6Width:4.0 iphone6PlusWidth:5.0 ipad:15.0]
                                            fitToWidth:relativeToView.frame.size.width - 10.0];
  UIView *headingPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:headingPanelLabel.frame.size.height + 15.0];
  [headingPanel setBackgroundColor:backgroundColor];
  [PEUIUtils placeView:headingPanelLabel inMiddleOf:headingPanel withAlignment:PEUIHorizontalAlignmentTypeCenter hpadding:0.0];
  return headingPanel;
}

+ (CGFloat)expandingInfoPanelHPadding {
  return [PEUIUtils valueIfiPhone5Width:14.0 iphone6Width:14.0 iphone6PlusWidth:16.0 ipad:25.0];
}

+ (NSArray *)expandingInfoPanelWithContentData:(NSArray *)contentData
                               additionalViews:(NSArray *)additionalViews
                             contentButtonFont:(UIFont *)contentButtonFont
                      contentButtonLabelStyler:(void(^)(UILabel *))contentButtonLabelStyler
                                     textColor:(UIColor *)textColor
                               backgroundColor:(UIColor *)backgroundColor
                              chevronImageName:(NSString *)chevronImageName
                                  contentIndex:(NSInteger)contentIndex
                                       toggles:(NSMutableDictionary *)toggles
                 baseControllerDisplayPanelBlk:(UIView *(^)(void))baseControllerDisplayPanelBlk
                         testForBelowViewsMove:(BOOL(^)(void))testForBelowViewsMove
                                    belowViews:(NSArray *)belowViews
                      indexOfFirstBelowViewBlk:(NSInteger(^)(NSInteger))indexOfFirstBelowViewBlk
                       extraContentPanelHeight:(CGFloat)extraContentPanelHeight
                                relativeToView:(UIView *)relativeToView {
  NSString *contentTitle = contentData[0];
  NSAttributedString *contentDescription;
  NSDictionary *contentDescriptionAttrs = nil;
  if ([contentData[1] isKindOfClass:[NSAttributedString class]]) {
    contentDescription = contentData[1];
  } else {
    contentDescription = contentData[1][0];
    contentDescriptionAttrs = contentData[1][1];
  }
  NSString *leftIconName = nil;
  if (contentData.count >= 3) {
    if ([PEUtils isNotNil:contentData[2]]) {
      leftIconName = contentData[2];
    }
  }
  void (^additionalActionOnDisplay)(void) = nil;
  if (contentData.count >= 4) {
    additionalActionOnDisplay = contentData[3];
  }
  UIButton *contentButton = [PEUIUtils buttonWithKey:@""
                                                font:contentButtonFont
                                     backgroundColor:backgroundColor
                                           textColor:textColor
                        disabledStateBackgroundColor:nil
                              disabledStateTextColor:nil
                                     verticalPadding:0.0
                                   horizontalPadding:10.0
                                        cornerRadius:0.0
                                              target:nil
                                              action:nil];
  [PEUIUtils setFrameWidthOfView:contentButton ofWidth:1.0 relativeTo:relativeToView];
  UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:chevronImageName]];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  CGFloat hpadding = 15.0 + iphoneXSafeInsetsSideVal;
  UIImageView *leftIcon = nil;
  if (leftIconName) {
    leftIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:leftIconName]];
  }
  CGFloat contentTitleFitToWidth = contentButton.frame.size.width - (hpadding * 2) - chevron.frame.size.width;
  if (leftIcon) {
    contentTitleFitToWidth -= (leftIcon.frame.size.width + hpadding);
  }
  UILabel *contentTitleLabel = [PEUIUtils labelWithKey:contentTitle
                                                  font:contentButtonFont
                                       backgroundColor:[UIColor clearColor]
                                             textColor:textColor
                                   verticalTextPadding:[PEUIUtils valueIfiPhone5Width:35.0 iphone6Width:35.0 iphone6PlusWidth:45.0 ipad:50.0]
                                            fitToWidth:contentTitleFitToWidth];
  contentTitleLabel.textAlignment = NSTextAlignmentCenter;
  if (contentButtonLabelStyler) {
    contentButtonLabelStyler(contentTitleLabel);
  }
  [PEUIUtils setFrameHeight:contentTitleLabel.frame.size.height ofView:contentButton];
  [PEUIUtils placeView:chevron inMiddleOf:contentButton withAlignment:PEUIHorizontalAlignmentTypeRight hpadding:hpadding];
  if (leftIcon) {
    [PEUIUtils placeView:leftIcon inMiddleOf:contentButton withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:hpadding];
    [PEUIUtils placeView:contentTitleLabel toTheRightOf:leftIcon onto:contentButton withAlignment:PEUIVerticalAlignmentTypeMiddle hpadding:10.0];
  } else {
    [PEUIUtils placeView:contentTitleLabel inMiddleOf:contentButton withAlignment:PEUIHorizontalAlignmentTypeLeft hpadding:hpadding];
  }
  [contentTitleLabel setUserInteractionEnabled:NO];
  UILabel *contentDescriptionLabel =
  [PEUIUtils labelWithAttributeText:contentDescription
                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
           fontForHeightCalculation:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
               additionalAttributes:contentDescriptionAttrs
                    backgroundColor:[UIColor clearColor]
                          textColor:textColor
                verticalTextPadding:[PEUIUtils valueIfiPhone5Width:15.0
                                                      iphone6Width:15.0
                                                  iphone6PlusWidth:20.0
                                                              ipad:25.0]
                         fitToWidth:(relativeToView.frame.size.width - [PEUIUtils valueIfiPhone5Width:28.0 iphone6Width:28.0 iphone6PlusWidth:28.0 ipad:40.0] - (iphoneXSafeInsetsSideVal * 2))];
  CGFloat panelTargetHeight;
  UIView *contentDescriptionPanel;
  NSInteger numAdditionalViews = 0;
  if (additionalViews) {
    numAdditionalViews = [additionalViews count];
    for (NSInteger i = 0; i < numAdditionalViews; i++) {
      UIView *view = additionalViews[i];
      view.alpha = 0.0;
    }
    NSMutableArray *views = [NSMutableArray array];
    [views addObject:contentDescriptionLabel];
    [views addObjectsFromArray:additionalViews];
    UIView *viewColumn = [PEUIUtils panelWithColumnOfViews:views
                               verticalPaddingBetweenViews:[PEUIUtils valueIfiPhone5Width:20.0
                                                                             iphone6Width:20.0
                                                                         iphone6PlusWidth:25.0
                                                                                     ipad:35.0]
                                            viewsAlignment:PEUIHorizontalAlignmentTypeLeft];
    panelTargetHeight = viewColumn.frame.size.height + extraContentPanelHeight;
    contentDescriptionPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:panelTargetHeight];
    [PEUIUtils placeView:viewColumn
              inMiddleOf:contentDescriptionPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:[PEUIUtils expandingInfoPanelHPadding] + iphoneXSafeInsetsSideVal];
  } else {
    panelTargetHeight = contentDescriptionLabel.frame.size.height + extraContentPanelHeight;
    contentDescriptionPanel = [PEUIUtils panelWithWidthOf:1.0 relativeToView:relativeToView fixedHeight:panelTargetHeight];
    [PEUIUtils placeView:contentDescriptionLabel
              inMiddleOf:contentDescriptionPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:[PEUIUtils expandingInfoPanelHPadding] + iphoneXSafeInsetsSideVal];
  }
  [PEUIUtils styleViewForIpad:contentDescriptionPanel];
  contentDescriptionLabel.alpha = 0.0;
  [PEUIUtils setFrameHeight:0.0 ofView:contentDescriptionPanel];
  [contentDescriptionPanel setBackgroundColor:backgroundColor];
  void(^animateContent)(NSNumber *, CGFloat) = ^(NSNumber *toggleVal, CGFloat multiplier) {
    contentDescriptionLabel.alpha = toggleVal == nil ? 1.0 : 0.0;
    for (NSInteger i = 0; i < numAdditionalViews; i++) {
      UIView *view = additionalViews[i];
      view.alpha = toggleVal == nil ? 1.0 : 0.0;
    }
    UIScrollView *displayPanel = (UIScrollView *)baseControllerDisplayPanelBlk();
    [displayPanel setContentSize:CGSizeMake(displayPanel.contentSize.width, displayPanel.contentSize.height + (panelTargetHeight * multiplier))];
  };
  void (^animateBelowViews)(CGFloat) = ^(CGFloat multiplier) {
    BOOL doBelowViewsMove = YES;
    if (testForBelowViewsMove) {
      doBelowViewsMove = testForBelowViewsMove();
    }
    if (doBelowViewsMove) {
      NSInteger numViews = belowViews.count;
      NSInteger startIndex = 0;
      if (indexOfFirstBelowViewBlk) {
        startIndex = indexOfFirstBelowViewBlk(contentIndex);
      }
      for (NSInteger i = startIndex; i < numViews; i++) {
        UIView *view = belowViews[i];
        [PEUIUtils adjustYOfView:view withValue:panelTargetHeight * multiplier];
      }
    }
  };
  void (^animateChevron)(NSNumber *) = ^(NSNumber *toggleVal) {
    chevron.transform = toggleVal == nil ? CGAffineTransformMakeRotation(M_PI/2) : CGAffineTransformMakeRotation(0);
  };
  void (^animateContentContainer)(CGFloat) = ^(CGFloat multiplier) {
    [PEUIUtils adjustHeightOfView:contentDescriptionPanel withValue:panelTargetHeight * multiplier];
    [PEUIUtils adjustHeightOfView:relativeToView withValue:panelTargetHeight * multiplier];
    [PEUIUtils adjustYOfView:contentDescriptionPanel withValue:1.0 * multiplier];
  };
  //CGFloat scrollAdjustment = [PEUIUtils valueIfiPhone5Width:-180.0 iphone6Width:-180.0 iphone6PlusWidth:-200.0];
  void (^scrollAfterAnimation)(NSNumber *) = ^(NSNumber *toggleVal){
    //UIScrollView *scrollView = (UIScrollView *)baseControllerDisplayPanelBlk();
    //if (toggleVal) {
      //[scrollView scrollRectToVisible:contentButton.frame animated:YES];
    //} else {
      //CGRect rect = contentDescriptionPanel.frame;
      //rect = CGRectMake(rect.origin.x, rect.origin.y + rect.size.height + scrollAdjustment, rect.size.width, rect.size.height);
      //[scrollView scrollRectToVisible:rect animated:YES];
    //}
  };
  [contentButton bk_addEventHandler:^(id sender) {
    NSNumber *toggleVal = toggles[@(contentIndex)];
    CGFloat multiplier;
    if (toggleVal) { // collapse
      multiplier = -1.0;
      [toggles removeObjectForKey:@(contentIndex)];
      [UIView animateWithDuration:0.20
                            delay:0
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         animateContent(toggleVal, multiplier);
                         animateChevron(toggleVal);
                         animateContentContainer(multiplier);
                         animateBelowViews(multiplier);
                       }
                       completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.35
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                            /*animateChevron(toggleVal);
                                            animateContentContainer(multiplier);
                                            animateBelowViews(multiplier);*/
                                          }
                                          completion:^(BOOL finished) {
                                            scrollAfterAnimation(toggleVal);
                                          }];
                       }];
    } else { // expand
      if (additionalActionOnDisplay) {
        additionalActionOnDisplay();
      }
      multiplier = 1.0;
      toggles[@(contentIndex)] = @(contentIndex);
      [UIView animateWithDuration:0.35
                            delay:0
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         animateContentContainer(multiplier);
                         animateBelowViews(multiplier);
                         animateChevron(toggleVal);
                       }
                       completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.25
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{ animateContent(toggleVal, multiplier); }
                                          completion:^(BOOL finished) {
                                            scrollAfterAnimation(toggleVal);
                                          }];
                       }];
    }
  } forControlEvents:UIControlEventTouchUpInside];
  [PEUIUtils styleViewForIpad:contentButton];
  return @[contentButton, contentDescriptionPanel];
}

#pragma mark - Private Alert Helpers

+ (UIView *)messagePanelWithTitle:(NSString *)title
                      leftImgIcon:(UIImage *)leftImgIcon
            leftImgIconTopPadding:(CGFloat)leftImgIconTopPadding
                            width:(CGFloat)width {
  UIView *errorPanel = [PEUIUtils panelWithFixedWidth:width fixedHeight:0.0];
  UIImageView *errImgView = [[UIImageView alloc] initWithImage:leftImgIcon];
  CGFloat paddingBetweenImgAndLabel = 5.0;
  UILabel *errorMsgLbl = [PEUIUtils labelWithKey:title
                                            font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor blackColor]
                             verticalTextPadding:0.0
                                      fitToWidth:(width - (errImgView.frame.size.width + paddingBetweenImgAndLabel))];
  CGFloat frameHeight = errorMsgLbl.frame.size.height > errImgView.frame.size.height ?
    errorMsgLbl.frame.size.height : errImgView.frame.size.height;
  [PEUIUtils setFrameHeight:frameHeight ofView:errorPanel];
  [PEUIUtils placeView:errImgView
               atTopOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:leftImgIconTopPadding //6.0
              hpadding:0.0];
  [PEUIUtils placeView:errorMsgLbl
               atTopOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:0.0
              hpadding:errImgView.frame.size.width + paddingBetweenImgAndLabel];
  return errorPanel;
}

+ (NSArray *)alertPanelsForMessages:(NSArray *)messages
                              width:(CGFloat)width
                        leftImgIcon:(UIImage *)leftImgIcon
              leftImgIconTopPadding:(CGFloat)leftImgIconTopPadding {
  NSMutableArray *alertPanels = [NSMutableArray arrayWithCapacity:[messages count]];
  for (NSString *message in messages) {
    UIView *errorPanel = [PEUIUtils messagePanelWithTitle:message
                                              leftImgIcon:leftImgIcon
                                    leftImgIconTopPadding:leftImgIconTopPadding
                                                    width:width];
    [alertPanels addObject:errorPanel];
  }
  return alertPanels;
}

#pragma mark - Bundle Image Fetch

+ (UIImage *)bundleImageWithName:(NSString *)imageName {
  UIImage *image;
  if (PE_IS_IOS8_OR_GREATER) {
    NSBundle *mainBundle = [NSBundle bundleForClass:[PEUIUtils class]];
    NSBundle *resourcesBundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"PEObjc-Commons" ofType:@"bundle"]];
    if (resourcesBundle == nil) {
      resourcesBundle = mainBundle;
    }
    image = [UIImage imageNamed:imageName inBundle:resourcesBundle compatibleWithTraitCollection:nil];
  } else {
    image = [UIImage imageNamed:[NSString stringWithFormat:@"PEObjc-Commons.bundle/%@", imageName]];
  }
  return image;
}

#pragma mark - Tables

+ (id)valueForSingleTableViewWithTag:(NSInteger)tag panel:(UIView *)panel {
  UITableView *tableView = (UITableView *)[panel viewWithTag:tag];
  PESingleValueTableViewDataSourceDelegate *ds =
  (PESingleValueTableViewDataSourceDelegate *)[tableView dataSource];
  return ds.pickedValue;
}

+ (void)setValueForSingleTableViewWithTag:(NSInteger)tag
                                    panel:(UIView *)panel
                                    value:(id)value {
  UITableView *tableView = (UITableView *)[panel viewWithTag:tag];
  PESingleValueTableViewDataSourceDelegate *ds =
  (PESingleValueTableViewDataSourceDelegate *)[tableView dataSource];
  [ds setPickedValue:value];
  [tableView reloadData];
}

+ (UITableView *)makeTableViewWithTag:(NSNumber *)tag
                            numFields:(NSInteger)numFields
              dataSourceDelegateMaker:(id(^)(UITableView *))dataSourceDelegateMaker
                       relativeToView:(UIView *)relativeToView
                 parentViewController:(UIViewController *)parentViewController {
  // 08/20/2017 - so I just learned that I cannot use the tag to find an existing
  // table to reuse.  The reason for this is that a device rotation may have
  // occured, and so I cannot rely on the existing table view being correct; i.e.
  // the existing table view may be sized for portrait, but the device is now in
  // landscape; so I cannot use that table view.  Therefore, I should always create
  // a new table view.  For simplicity, I'm not going to change the params of this
  // method...the "tag" param will just go unused.
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
  tableView.tableFooterView.hidden = YES;
  tableView.tableHeaderView.hidden = YES;
  [tableView setScrollEnabled:NO];
  if (tag) {
    [tableView setTag:[tag integerValue]];
  }
  [PEUIUtils setFrameWidthOfView:tableView ofWidth:1.0 relativeTo:relativeToView];
  [PEUIUtils setFrameHeight:((numFields * [PEUIUtils sizeOfText:@""
                                                       withFont:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]].height) +
                             [PEUIUtils valueIfiPhone5Width:29.0
                                               iphone6Width:29.0
                                           iphone6PlusWidth:33.0
                                                       ipad:39.0])
                     ofView:tableView];
  [PEUIUtils styleViewForIpad:tableView];
  id ds = dataSourceDelegateMaker(tableView);
  tableView.sectionHeaderHeight = 2.0;
  tableView.sectionFooterHeight = 2.0;
  [tableView setDataSource:ds];
  [tableView setDelegate:ds];
  return tableView;
}

#pragma mark - Alert Section Makers

+ (JGActionSheetSection *)alertSectionWithTitle:(NSString *)title
                                     titleImage:(UIImage *)titleImage
                               alertDescription:(NSAttributedString *)alertDescription
                            descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                 relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:titleImage
                                                              description:alertDescription
                                                      descLblHeightAdjust:descLblHeightAdjust
                                                           availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)alertSectionWithMsgs:(NSArray *)msgs
                                         title:(NSString *)title
                                    titleImage:(UIImage *)titleImage
                              alertDescription:(NSAttributedString *)alertDescription
                           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:titleImage
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"black-dot"]
                                                   messageIconTopPadding:6.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)warningAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"warning"]
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"black-dot"]
                                                   messageIconTopPadding:6.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)successAlertSectionWithTitle:(NSString *)title
                                      alertDescription:(NSAttributedString *)alertDescription
                                   descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                        relativeToView:(UIView *)relativeToView {
  return [PEUIUtils successAlertSectionWithMsgs:nil
                                          title:title
                               alertDescription:alertDescription
                            descLblHeightAdjust:descLblHeightAdjust
                                 relativeToView:relativeToView];
}

+ (JGActionSheetSection *)offlineModeEnabledAlertSectionWithTitle:(NSString *)title
                                                 alertDescription:(NSAttributedString *)alertDescription
                                              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                   relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:@[[alertDescription string]]
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"offline"]
                                                             description:[[NSAttributedString alloc] initWithString:@"You are in offline mode."]
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:[[NSAttributedString alloc] initWithString:@"It has not yet been synced to your account."]
                                                             messageIcon:[UIImage imageNamed:@"green-checkmark-small-icon"]
                                                   messageIconTopPadding:4.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)recordSavedWhileUnauthAlertSectionWithTitle:(NSString *)title
                                                     alertDescription:(NSAttributedString *)alertDescription
                                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                       relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:@[[alertDescription string]]
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"warning"]
                                                             description:[[NSAttributedString alloc] initWithString:@"You are not currently authenticated."]
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:[[NSAttributedString alloc] initWithString:@"It has not yet been synced to your account."]
                                                             messageIcon:[UIImage imageNamed:@"green-checkmark-small-icon"]
                                                   messageIconTopPadding:4.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)recordSavedWhileBadAccountAlertSectionWithTitle:(NSString *)title
                                                         alertDescription:(NSAttributedString *)alertDescription
                                                      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                           relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:@[[alertDescription string]]
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"warning"]
                                                             description:[[NSAttributedString alloc] initWithString:@"Your account has a problem with it (expired trial or closed account)."]
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:[[NSAttributedString alloc] initWithString:@"It has not been synced to your account."]
                                                             messageIcon:[UIImage imageNamed:@"green-checkmark-small-icon"]
                                                   messageIconTopPadding:4.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:[UIImage imageNamed:@"info"]
                                                              description:alertDescription
                                                      descLblHeightAdjust:descLblHeightAdjust
                                                           availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                               alertDescriptionText:(NSString *)alertDescriptionText
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    instructionText:(NSString *)instructionText
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithTitle:title
                                                               titleImage:[UIImage imageNamed:@"info"]
                                                          descriptionText:alertDescriptionText
                                                      descLblHeightAdjust:descLblHeightAdjust
                                                          instructionText:instructionText
                                                           availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)infoAlertSectionWithMsgs:(NSArray *)msgs
                                             title:(NSString *)title
                                  alertDescription:(NSAttributedString *)alertDescription
                               descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"info"]
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"black-dot"]
                                                   messageIconTopPadding:6.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)successAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"green-checkmark"]
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"green-checkmark-small-icon"]
                                                   messageIconTopPadding:4.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)waitAlertSectionWithMsgs:(NSArray *)msgs
                                             title:(NSString *)title
                                  alertDescription:(NSAttributedString *)alertDescription
                               descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"wait"]
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"black-dot"]
                                                   messageIconTopPadding:6.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)errorAlertSectionWithMsgs:(NSArray *)msgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                     relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils panelWithMsgs:msgs
                                                                   title:title
                                                              titleImage:[UIImage imageNamed:@"red-exclamation"]
                                                             description:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                       footerDescription:nil
                                                             messageIcon:[UIImage imageNamed:@"red-x-small-icon"]
                                                   messageIconTopPadding:3.0
                                                          availableWidth:[PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]];
}

+ (JGActionSheetSection *)dangerAlertSectionWithTitle:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView {
  return [PEUIUtils alertSectionWithTitle:title
                               titleImage:[UIImage imageNamed:@"red-exclamation"]
                         alertDescription:alertDescription
                      descLblHeightAdjust:descLblHeightAdjust
                           relativeToView:relativeToView];
}

+ (JGActionSheetSection *)questionAlertSectionWithTitle:(NSString *)title
                                       alertDescription:(NSAttributedString *)alertDescription
                                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                         relativeToView:(UIView *)relativeToView {
  return [PEUIUtils alertSectionWithTitle:title
                               titleImage:[UIImage imageNamed:@"info"]
                         alertDescription:alertDescription
                      descLblHeightAdjust:descLblHeightAdjust
                           relativeToView:relativeToView];
}

+ (JGActionSheetSection *)multiErrorAlertSectionWithFailures:(NSArray *)failures
                                                       title:(NSString *)title
                                            alertDescription:(NSAttributedString *)alertDescription
                                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                              relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils failuresPanelWithFailures:failures
                                                                               title:title
                                                                         description:alertDescription
                                                                 descLblHeightAdjust:descLblHeightAdjust
                                                                     descriptionFont:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                                      relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)mixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                                            title:(NSString *)title
                                                 alertDescription:(NSAttributedString *)alertDescription
                                              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                              failuresDescription:(NSAttributedString *)failuresDescription
                                                         failures:(NSArray *)failures
                                                   relativeToView:(UIView *)relativeToView {
  return [JGActionSheetSection sectionWithTitle:nil
                                        message:nil
                                    contentView:[PEUIUtils mixedResultsPanelWithSuccessMsgs:successMsgs
                                                                                      title:title
                                                                                description:alertDescription
                                                                        descLblHeightAdjust:descLblHeightAdjust
                                                                        failuresDescription:failuresDescription
                                                                                   failures:failures
                                                                             relativeToView:relativeToView]];
}

+ (JGActionSheetSection *)becameUnauthenticatedSectionRelativeToView:(UIView *)relativeToView {
  NSAttributedString *attrBecameUnauthMessage =
  [PEUIUtils attributedTextWithTemplate:@"So it appears you're no longer authenticated.  To re-authenticate, head over to:\n\n%@."
                           textToAccent:@"Account \u2794 Re-authenticate"
                         accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
  return [PEUIUtils warningAlertSectionWithMsgs:nil
                                          title:@"Authentication failure."
                               alertDescription:attrBecameUnauthMessage
                            descLblHeightAdjust:0.0
                                 relativeToView:relativeToView];
}

+ (JGActionSheetSection *)receivedNotPermittedSectionRelativeToView:(UIView *)relativeToView {
  NSMutableAttributedString *mutableAttrMessage = [[NSMutableAttributedString alloc] init];
  [mutableAttrMessage appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"This is usually due to an expired trial account or closed account subscription.  To fix your account, head over to the %@ tab and "
                                                                      textToAccent:@"Account"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  [mutableAttrMessage appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"tap %@ to refresh your account status."
                                                                      textToAccent:@"Synchronize Your Account"
                                                                    accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]];
  return [PEUIUtils warningAlertSectionWithMsgs:nil
                                          title:@"Operation not permitted."
                               alertDescription:mutableAttrMessage
                            descLblHeightAdjust:0.0
                                 relativeToView:relativeToView];
}

#pragma mark - Showing Alert Helpers

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView
                 contentSections:(NSArray *)contentSections {
  NSMutableArray *buttonTitles = [NSMutableArray array];
  [buttonTitles addObject:buttonTitle];
  BOOL notNilAddlButtonTitle = [PEUtils isNotNil:addlButtonTitle];
  if (notNilAddlButtonTitle) {
    [buttonTitles addObject:addlButtonTitle];
  }
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:buttonTitles
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  if (notNilAddlButtonTitle) {
    [buttonsSection setButtonStyle:addlButtonStyle forButtonAtIndex:buttonTitles.count - 1];
  }
  NSMutableArray *sections = [NSMutableArray array];
  if (contentSections) {
    [sections addObjectsFromArray:contentSections];
  }
  [sections addObject:buttonsSection];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
  if (!addlButtonAction) {
    alertSheet.outsidePressBlock = ^(JGActionSheet *sheet) {
      if (buttonAction) { buttonAction(); }
      [sheet dismissAnimated:YES];
    };
  }
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    [sheet dismissAnimated:YES];
    switch ([indexPath row]) {
      case 0:
        if (buttonAction) { buttonAction(); }
        break;
      case 1:
        if (addlButtonAction) { addlButtonAction(); }
      default:
        break;
    }
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView
             contentSectionMaker:(PEAlertSectionMaker)contentSectionMaker
       additionalContentSections:(NSArray *)additionalContentSections {
  NSMutableArray *contentSections = [NSMutableArray array];
  [contentSections addObject:contentSectionMaker()];
  if (additionalContentSections) {
    [contentSections addObjectsFromArray:additionalContentSections];
  }
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:addlButtonTitle
                     addlButtonAction:addlButtonAction
                      addlButtonStyle:addlButtonStyle
                       relativeToView:relativeToView
                      contentSections:contentSections];
}

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView
             contentSectionMaker:(PEAlertSectionMaker)contentSectionMaker
        additionalContentSection:(JGActionSheetSection *)additionalContentSection {
  [self showAlertWithButtonTitle:buttonTitle
                        topInset:topInset
                    buttonAction:buttonAction
                 addlButtonTitle:addlButtonTitle
                addlButtonAction:addlButtonAction
                 addlButtonStyle:addlButtonStyle
                  relativeToView:relativeToView
             contentSectionMaker:contentSectionMaker
       additionalContentSections:(additionalContentSection != nil ? @[additionalContentSection] : nil)];
}

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView
             contentSectionMaker:(PEAlertSectionMaker)contentSectionMaker {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:addlButtonTitle
                     addlButtonAction:addlButtonAction
                      addlButtonStyle:addlButtonStyle
                       relativeToView:relativeToView
                  contentSectionMaker:contentSectionMaker
             additionalContentSection:nil];
}

+ (CGFloat)topInsetForAlertsWithController:(UIViewController *)controller {
  /*if (controller.navigationController.navigationBarHidden) {
    return 0.0;
  }
  return 70.0;*/
  return 0.0; // I can't remember why I'd ever want the '70.0' top inset
}

+ (UIView *)parentViewForAlertsForController:(UIViewController *)controller {
  if (controller.tabBarController) {
    return controller.tabBarController.view;
  } else if (controller.navigationController) {
    return controller.navigationController.view;
  }
  return controller.view;
}

#pragma mark - Showing Alerts

+ (void)showAlertWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
          alertDescription:(NSAttributedString *)alertDescription
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                  topInset:(CGFloat)topInset
               buttonTitle:(NSString *)buttonTitle
              buttonAction:(void(^)(void))buttonAction
            relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils alertSectionWithTitle:title
                                                                      titleImage:titleImage
                                                                alertDescription:alertDescription
                                                             descLblHeightAdjust:descLblHeightAdjust
                                                                  relativeToView:relativeToView]; }];
}

+ (void)showConfirmAlertWithTitle:(NSString *)title
                       titleImage:(UIImage *)titleImage
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         topInset:(CGFloat)topInset
                  okayButtonTitle:(NSString *)okayButtonTitle
                 okayButtonAction:(void(^)(void))okayButtonAction
                  okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
                cancelButtonTitle:(NSString *)cancelButtonTitle
               cancelButtonAction:(void(^)(void))cancelButtonAction
                 cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showConfirmAlertWithTitle:title
                            titleImage:titleImage
                      alertDescription:alertDescription
                   descLblHeightAdjust:descLblHeightAdjust
                              topInset:topInset
                       okayButtonTitle:okayButtonTitle
                      okayButtonAction:okayButtonAction
                       okayButtonStyle:okayButtonStyle
                     cancelButtonTitle:cancelButtonTitle
                    cancelButtonAction:cancelButtonAction
                      cancelButtonSyle:cancelButtonStyle
            secondaryCancelButtonTitle:nil
           secondaryCancelButtonAction:nil
             secondaryCancelButtonSyle:0
                        relativeToView:relativeToView];
}

+ (void)showConfirmAlertWithTitle:(NSString *)title
                       titleImage:(UIImage *)titleImage
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         topInset:(CGFloat)topInset
                  okayButtonTitle:(NSString *)okayButtonTitle
                 okayButtonAction:(void(^)(void))okayButtonAction
                  okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
                cancelButtonTitle:(NSString *)cancelButtonTitle
               cancelButtonAction:(void(^)(void))cancelButtonAction
                 cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
       secondaryCancelButtonTitle:(NSString *)secondaryCancelButtonTitle
      secondaryCancelButtonAction:(void(^)(void))secondaryCancelButtonAction
        secondaryCancelButtonSyle:(JGActionSheetButtonStyle)secondaryCancelButtonStyle
                   relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithTitle:title
                                                               titleImage:titleImage
                                                         alertDescription:alertDescription
                                                      descLblHeightAdjust:descLblHeightAdjust
                                                           relativeToView:relativeToView];
  NSMutableArray *buttonTitles = [NSMutableArray arrayWithObjects:okayButtonTitle, cancelButtonTitle, nil];
  if (secondaryCancelButtonTitle) {
    [buttonTitles addObject:secondaryCancelButtonTitle];
  }
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:buttonTitles
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  alertSheet.outsidePressBlock = ^(JGActionSheet *sheet) {
    // do nothing; confirm dialog should require explicit user input
  };
  [buttonsSection setButtonStyle:okayButtonStyle forButtonAtIndex:0];
  [buttonsSection setButtonStyle:cancelButtonStyle forButtonAtIndex:1];
  if (buttonTitles.count > 2) {
    [buttonsSection setButtonStyle:secondaryCancelButtonStyle forButtonAtIndex:2];
  }
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction();
        break;
      case 1:  // cancel
        if (cancelButtonAction) { cancelButtonAction(); }
        break;
      case 2: // secondary cancel
        if (secondaryCancelButtonAction) { secondaryCancelButtonAction(); }
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showConfirmAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                      titleImage:(UIImage *)titleImage
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                 okaybuttonTitle:(NSString *)okayButtonTitle
                okaybuttonAction:(void(^)(void))okayButtonAction
                 okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
               cancelButtonTitle:(NSString *)cancelButtonTitle
              cancelButtonAction:(void(^)(void))cancelButtonAction
                cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
                  relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils alertSectionWithMsgs:msgs
                                                                   title:title
                                                              titleImage:titleImage
                                                        alertDescription:alertDescription
                                                     descLblHeightAdjust:descLblHeightAdjust
                                                          relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[okayButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  alertSheet.outsidePressBlock = ^(JGActionSheet *sheet) {
    // do nothing; confirm dialog should require explicit user input
  };
  [buttonsSection setButtonStyle:okayButtonStyle forButtonAtIndex:0];
  [buttonsSection setButtonStyle:cancelButtonStyle forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction();
        break;
      case 1:  // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showWarningConfirmAlertWithTitle:(NSString *)title
                        alertDescription:(NSAttributedString *)alertDescription
                     descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                topInset:(CGFloat)topInset
                         okayButtonTitle:(NSString *)okayButtonTitle
                        okayButtonAction:(void(^)(void))okayButtonAction
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                      cancelButtonAction:(void(^)(void))cancelButtonAction
                          relativeToView:(UIView *)relativeToView {
  [self showConfirmAlertWithTitle:title
                       titleImage:[UIImage imageNamed:@"warning"]
                 alertDescription:alertDescription
              descLblHeightAdjust:descLblHeightAdjust
                         topInset:topInset
                  okayButtonTitle:okayButtonTitle
                 okayButtonAction:okayButtonAction
                  okayButtonStyle:JGActionSheetButtonStyleRed
                cancelButtonTitle:cancelButtonTitle
               cancelButtonAction:cancelButtonAction
                 cancelButtonSyle:JGActionSheetButtonStyleDefault
                   relativeToView:relativeToView];
}

+ (void)showWarningConfirmAlertWithMsgs:(NSArray *)msgs
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                               topInset:(CGFloat)topInset
                        okayButtonTitle:(NSString *)okayButtonTitle
                       okayButtonAction:(void(^)(void))okayButtonAction
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                     cancelButtonAction:(void(^)(void))cancelButtonAction
                         relativeToView:(UIView *)relativeToView {
  [self showConfirmAlertWithMsgs:msgs
                           title:title
                      titleImage:[UIImage imageNamed:@"warning"]
                alertDescription:alertDescription
             descLblHeightAdjust:descLblHeightAdjust
                        topInset:topInset
                 okaybuttonTitle:okayButtonTitle
                okaybuttonAction:okayButtonAction
                 okayButtonStyle:JGActionSheetButtonStyleRed
               cancelButtonTitle:cancelButtonTitle
              cancelButtonAction:cancelButtonAction
                cancelButtonSyle:JGActionSheetButtonStyleDefault
                  relativeToView:relativeToView];
}

+ (void)showWarningAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  return [PEUIUtils showWarningAlertWithMsgs:msgs
                                       title:title
                            alertDescription:alertDescription
                         descLblHeightAdjust:descLblHeightAdjust
                                    topInset:topInset
                                 buttonTitle:buttonTitle
                                buttonAction:buttonAction
                             addlButtonTitle:nil
                            addlButtonAction:nil
                             addlButtonStyle:0
                              relativeToView:relativeToView];
}

+ (void)showWarningAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:addlButtonTitle
                     addlButtonAction:addlButtonAction
                      addlButtonStyle:addlButtonStyle
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils warningAlertSectionWithMsgs:msgs
                                                                                 title:title
                                                                      alertDescription:alertDescription
                                                                   descLblHeightAdjust:descLblHeightAdjust
                                                                        relativeToView:relativeToView]; }];
}

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showSuccessAlertWithTitle:title
                      alertDescription:alertDescription
                   descLblHeightAdjust:descLblHeightAdjust
              additionalContentSection:nil
                              topInset:topInset
                           buttonTitle:buttonTitle
                          buttonAction:buttonAction
                        relativeToView:relativeToView];
}

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        additionalContentSections:(NSArray *)additionalContentSections
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils successAlertSectionWithMsgs:nil
                                                                                 title:title
                                                                      alertDescription:alertDescription
                                                                   descLblHeightAdjust:descLblHeightAdjust
                                                                        relativeToView:relativeToView]; }
            additionalContentSections:additionalContentSections];
}

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
         additionalContentSection:(JGActionSheetSection *)additionalContentSection
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils successAlertSectionWithTitle:title
                                                                       alertDescription:alertDescription
                                                                    descLblHeightAdjust:descLblHeightAdjust
                                                                         relativeToView:relativeToView]; }
             additionalContentSection:additionalContentSection];
}

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showSuccessAlertWithMsgs:msgs
                                title:title
                     alertDescription:alertDescription
                  descLblHeightAdjust:descLblHeightAdjust
             additionalContentSection:nil
                             topInset:topInset
                          buttonTitle:buttonTitle
                         buttonAction:buttonAction
                       relativeToView:relativeToView];
}

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
       additionalContentSections:(NSArray *)additionalContentSections
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils successAlertSectionWithMsgs:msgs
                                                                                 title:title
                                                                      alertDescription:alertDescription
                                                                   descLblHeightAdjust:descLblHeightAdjust
                                                                        relativeToView:relativeToView]; }
            additionalContentSections:additionalContentSections];
}

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        additionalContentSection:(JGActionSheetSection *)additionalContentSection
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showSuccessAlertWithMsgs:msgs
                                title:title
                     alertDescription:alertDescription
                  descLblHeightAdjust:descLblHeightAdjust
            additionalContentSections:(additionalContentSection != nil ? @[additionalContentSection] : nil)
                             topInset:topInset
                          buttonTitle:buttonTitle
                         buttonAction:buttonAction
                       relativeToView:relativeToView];
}

+ (void)showOfflineModeEnabledAlertWithTitle:(NSString *)title
                            alertDescription:(NSAttributedString *)alertDescription
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    topInset:(CGFloat)topInset
                                 buttonTitle:(NSString *)buttonTitle
                                buttonAction:(void(^)(void))buttonAction
                              relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils offlineModeEnabledAlertSectionWithTitle:title
                                                                                  alertDescription:alertDescription
                                                                               descLblHeightAdjust:descLblHeightAdjust
                                                                                    relativeToView:relativeToView]; }];
}

+ (void)recordSavedWhileUnauthAlertWithTitle:(NSString *)title
                            alertDescription:(NSAttributedString *)alertDescription
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    topInset:(CGFloat)topInset
                                 buttonTitle:(NSString *)buttonTitle
                                buttonAction:(void(^)(void))buttonAction
                              relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils recordSavedWhileUnauthAlertSectionWithTitle:title
                                                                                      alertDescription:alertDescription
                                                                                   descLblHeightAdjust:descLblHeightAdjust
                                                                                        relativeToView:relativeToView]; }];
}

+ (void)recordSavedWhileBadAccountAlertWithTitle:(NSString *)title
                                alertDescription:(NSAttributedString *)alertDescription
                             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                        topInset:(CGFloat)topInset
                                     buttonTitle:(NSString *)buttonTitle
                                    buttonAction:(void(^)(void))buttonAction
                                  relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils recordSavedWhileBadAccountAlertSectionWithTitle:title
                                                                                          alertDescription:alertDescription
                                                                                       descLblHeightAdjust:descLblHeightAdjust
                                                                                            relativeToView:relativeToView]; }];
}

+ (void)showInfoAlertWithTitle:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
     additionalContentSections:(NSArray *)additionalContentSections
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils infoAlertSectionWithTitle:title
                                                                    alertDescription:alertDescription
                                                                 descLblHeightAdjust:descLblHeightAdjust
                                                                      relativeToView:relativeToView]; }
            additionalContentSections:additionalContentSections];
}

+ (void)showInfoAlertWithTitle:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      topInset:(CGFloat)topInset
               okayButtonTitle:(NSString *)okayButtonTitle
              okayButtonAction:(void(^)(void))okayButtonAction
               okayButtonStyle:(JGActionSheetButtonStyle)okayButtonStyle
             cancelButtonTitle:(NSString *)cancelButtonTitle
            cancelButtonAction:(void(^)(void))cancelButtonAction
              cancelButtonSyle:(JGActionSheetButtonStyle)cancelButtonStyle
                relativeToView:(UIView *)relativeToView {
  JGActionSheetSection *contentSection = [PEUIUtils infoAlertSectionWithTitle:title
                                                             alertDescription:alertDescription
                                                          descLblHeightAdjust:descLblHeightAdjust
                                                               relativeToView:relativeToView];
  JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                        message:nil
                                                                   buttonTitles:@[okayButtonTitle, cancelButtonTitle]
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
  alertSheet.outsidePressBlock = ^(JGActionSheet *sheet) {
    cancelButtonAction();
    [sheet dismissAnimated:YES];
  };
  [buttonsSection setButtonStyle:okayButtonStyle forButtonAtIndex:0];
  [buttonsSection setButtonStyle:cancelButtonStyle forButtonAtIndex:1];
  [alertSheet setInsets:UIEdgeInsetsMake(topInset, 0.0f, 0.0f, 0.0f)];
  [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
    switch (indexPath.row) {
      case 0:  // okay
        okayButtonAction();
        break;
      case 1:  // cancel
        cancelButtonAction();
        break;
    }
    [sheet dismissAnimated:YES];
  }];
  [alertSheet showInView:relativeToView animated:YES];
}

+ (void)showInstructionalAlertWithTitle:(NSString *)title
                   alertDescriptionText:(NSString *)alertDescriptionText
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        instructionText:(NSString *)instructionText
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils infoAlertSectionWithTitle:title
                                                                alertDescriptionText:alertDescriptionText
                                                                 descLblHeightAdjust:descLblHeightAdjust
                                                                     instructionText:instructionText
                                                                      relativeToView:relativeToView]; }];
}

+ (void)showWaitAlertWithMsgs:(NSArray *)msgs
                        title:(NSString *)title
             alertDescription:(NSAttributedString *)alertDescription
          descLblHeightAdjust:(CGFloat)descLblHeightAdjust
    additionalContentSections:(NSArray *)additionalContentSections
                     topInset:(CGFloat)topInset
                  buttonTitle:(NSString *)buttonTitle
                 buttonAction:(void(^)(void))buttonAction
               relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils waitAlertSectionWithMsgs:msgs
                                                                              title:title
                                                                   alertDescription:alertDescription
                                                                descLblHeightAdjust:descLblHeightAdjust
                                                                     relativeToView:relativeToView]; }
            additionalContentSections:additionalContentSections];
}

+ (void)showErrorAlertWithMsgs:(NSArray *)msgs
                         title:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils errorAlertSectionWithMsgs:msgs
                                                                               title:title
                                                                    alertDescription:alertDescription
                                                                 descLblHeightAdjust:descLblHeightAdjust
                                                                      relativeToView:relativeToView]; }];
}

+ (void)showErrorAlertWithMsgs:(NSArray *)msgs
                         title:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
     additionalContentSections:(NSArray *)additionalContentSections
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils errorAlertSectionWithMsgs:msgs
                                                                               title:title
                                                                    alertDescription:alertDescription
                                                                 descLblHeightAdjust:descLblHeightAdjust
                                                                      relativeToView:relativeToView]; }
            additionalContentSections:additionalContentSections];
}

+ (void)showMultiErrorAlertWithFailures:(NSArray *)failures
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils multiErrorAlertSectionWithFailures:failures
                                                                                        title:title
                                                                             alertDescription:alertDescription
                                                                          descLblHeightAdjust:descLblHeightAdjust
                                                                               relativeToView:relativeToView]; }];
}

+ (void)showMultiErrorAlertWithFailures:(NSArray *)failures
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
               additionalContentSection:(JGActionSheetSection *)additionalContentSection
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils multiErrorAlertSectionWithFailures:failures
                                                                                        title:title
                                                                             alertDescription:alertDescription
                                                                          descLblHeightAdjust:descLblHeightAdjust
                                                                               relativeToView:relativeToView]; }
             additionalContentSection:additionalContentSection];
}

+ (void)showMixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                failuresDescription:(NSAttributedString *)failuresDescription
                                           failures:(NSArray *)failures
                                           topInset:(CGFloat)topInset
                                        buttonTitle:(NSString *)buttonTitle
                                       buttonAction:(void(^)(void))buttonAction
                                     relativeToView:(UIView *)relativeToView {
  [PEUIUtils showAlertWithButtonTitle:buttonTitle
                             topInset:topInset
                         buttonAction:buttonAction
                      addlButtonTitle:nil
                     addlButtonAction:nil
                      addlButtonStyle:0
                       relativeToView:relativeToView
                  contentSectionMaker:^{ return [PEUIUtils mixedResultsAlertSectionWithSuccessMsgs:successMsgs
                                                                                             title:title
                                                                                  alertDescription:alertDescription
                                                                               descLblHeightAdjust:descLblHeightAdjust
                                                                               failuresDescription:failuresDescription
                                                                                          failures:failures
                                                                                    relativeToView:relativeToView]; }];
}

+ (void)showAlertForNSURLErrorCode:(NSInteger)errorCode
                             title:(NSString *)title
                          topInset:(CGFloat)topInset
                       buttonTitle:(NSString *)buttonTitle
                      buttonAction:(void(^)(void))buttonAction
                    relativeToView:(UIView *)relativeToView {
  NSMutableArray *errMsgs = [NSMutableArray arrayWithCapacity:1];
  switch (errorCode) {
  case NSURLErrorTimedOut:
    [errMsgs addObject:LS(@"nsurlerr.timeout")];
    break;
  case NSURLErrorCannotConnectToHost:
    [errMsgs addObject:LS(@"nsurlerr.serverdown")];
    break;
  case NSURLErrorNetworkConnectionLost:
    [errMsgs addObject:LS(@"nsurlerr.inetconnlost")];
    break;
  case NSURLErrorDNSLookupFailed:
    [errMsgs addObject:LS(@"nsurlerr.dnslkupfailed")];
    break;
  case NSURLErrorNotConnectedToInternet:
    [errMsgs addObject:LS(@"nsurlerr.noinetconn")];
    break;
  default:
    [errMsgs addObject:LS(@"nsurlerr.unknownerr")];
    break;
  }
  [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                title:title
                     alertDescription:[[NSAttributedString alloc] initWithString:@"There was a problem communicating with the server.  The error is as follows:"]
                  descLblHeightAdjust:0
                             topInset:topInset
                          buttonTitle:buttonTitle
                         buttonAction:buttonAction
                       relativeToView:relativeToView];
}

@end
