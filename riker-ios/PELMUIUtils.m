//
//  PELMUIUtils.m
//

#import "PELMUIUtils.h"
#import "PEUIUtils.h"
#import <FlatUIKit/UIColor+FlatUI.h>
#import "PELMMainSupport.h"
#import "RUtils.h"

@implementation PELMUIUtils

+ (PETableCellContentViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                       subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                   subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                 isLoggedIn:(BOOL)isLoggedIn
                                               isEntityType:(BOOL)isEntityType {
  return [self syncViewStylerWithTitleBlk:nil
                                titleFont:nil
                         smallSubTitleBlk:nil
                       rightSideViewMaker:nil
                   alwaysTopifyTitleLabel:NO
                                uitoolkit:uitoolkit
                     subtitleLeftHPadding:subtitleLeftHPadding
                 subtitleFitToWidthFactor:subtitleFitToWidthFactor
                               isLoggedIn:isLoggedIn
                             isEntityType:isEntityType
                  importLimitExceededMask:nil
    importedNotAllowedUnverifiedEmailMask:nil];
}

+ (PETableCellContentViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                                                 titleFont:(UIFont *)titleFont
                                          smallSubTitleBlk:(NSString *(^)(id))smallSubTitleBlk
                                        rightSideViewMaker:(UIView *(^)(id))rightSideViewMaker
                                    alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                                 uitoolkit:(PEUIToolkit *)uitoolkit
                                      subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                  subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                isLoggedIn:(BOOL)isLoggedIn
                                              isEntityType:(BOOL)isEntityType
                                   importLimitExceededMask:(NSNumber *)importLimitExceededMask
                     importedNotAllowedUnverifiedEmailMask:(NSNumber *)importedNotAllowedUnverifiedEmailMask {
  NSInteger titleTag = 89;
  NSInteger subtitleTag = 90;
  NSInteger warningIconTag = 91;
  NSInteger rightSideViewTag = 92;
  NSInteger smallSubTitleTag = 93;
  CGFloat vpaddingForTopifiedTitleToFitNeedFixIcon = 8.0;
  CGFloat vpaddingForTopifiedTitleToFitSubtitle = 11.0;
  void (^removeView)(NSInteger, UIView *) = ^(NSInteger tag, UIView *view) {
    [[view viewWithTag:tag] removeFromSuperview];
  };
  NSString * (^truncatedTitleText)(id) = ^NSString *(id dataObject) {
    NSInteger maxLength = (NSInteger)[PEUIUtils valueIfiPhone5Width:35
                                                       iphone6Width:37
                                                   iphone6PlusWidth:40
                                                               ipad:80];
    NSString *title = titleBlk(dataObject);
    if ([title length] > maxLength) {
      title = [[title substringToIndex:maxLength] stringByAppendingString:@"..."];
    }
    return title;
  };
  return ^(UITableViewCell *cell, UIView *view, id dataObject) {
    removeView(titleTag, view);
    removeView(subtitleTag, view);
    removeView(warningIconTag, view);
    removeView(rightSideViewTag, view);
    removeView(smallSubTitleTag, view);
    PELMMainSupport *entity = (PELMMainSupport *)dataObject;
    NSString *smallSubTitleMsg = nil;
    if (smallSubTitleBlk) {
      smallSubTitleMsg = smallSubTitleBlk(entity);
    }
    NSString *subTitleMsg = nil;
    BOOL syncWarningNeedsFix = NO;
    BOOL syncWarningTemporary = NO;
    CGFloat vpaddingForTopification = vpaddingForTopifiedTitleToFitSubtitle;
    if (isEntityType) {
      if (isLoggedIn) {
        if ([entity syncInProgress]) {
          subTitleMsg = @"syncing";
        } else {//else if ([entity globalIdentifier]) {
          if ([entity syncErrMask] && ([entity syncErrMask].integerValue > 0)) {
            syncWarningNeedsFix = YES;
            if (importLimitExceededMask && [importLimitExceededMask isEqualToNumber:[entity syncErrMask]]) {
              subTitleMsg = @"import limit exceeded";
            } else if (importedNotAllowedUnverifiedEmailMask && [importedNotAllowedUnverifiedEmailMask isEqualToNumber:[entity syncErrMask]]) {
              subTitleMsg = @"import not allowed - unverified email";
            } else {
              subTitleMsg = @"needs fixing";
            }
            vpaddingForTopification = vpaddingForTopifiedTitleToFitNeedFixIcon;
          } else if (!entity.synced) {
            subTitleMsg = @"sync needed";
          }
        }
      }
    }
    
    // place title label
    UILabel *titleLabel = nil;
    if (titleBlk) {
      titleLabel = [uitoolkit tableCellTitleMaker](truncatedTitleText(entity), view.frame.size.width);
      if (titleFont) {
        [titleLabel setFont:titleFont];
      }
      [titleLabel setTag:titleTag];
      CGFloat hpadding = [PEUIUtils valueIfiPhone5Width:10.0
                                           iphone6Width:15.0
                                       iphone6PlusWidth:20.0
                                                   ipad:20.0];            
      if (subTitleMsg && smallSubTitleMsg) {
        [PEUIUtils placeView:titleLabel
                     atTopOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:vpaddingForTopification
                    hpadding:hpadding];
      } else {
        [PEUIUtils placeView:titleLabel
                  inMiddleOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    hpadding:hpadding];
        if (smallSubTitleMsg) {
          [PEUIUtils adjustYOfView:titleLabel withValue:-5.0];
        } else if (subTitleMsg) {
          [PEUIUtils adjustYOfView:titleLabel withValue:-8.0];
        }
      }
    }
    
    // place right side view
    if (rightSideViewMaker) {
      UIView *rightSideView = rightSideViewMaker(dataObject);
      [rightSideView setTag:rightSideViewTag];      
      [PEUIUtils placeView:rightSideView
                inMiddleOf:view
             withAlignment:PEUIHorizontalAlignmentTypeRight
                  hpadding:[PEUIUtils valueIfiPhone5Width:0.0
                                             iphone6Width:8.0
                                         iphone6PlusWidth:10.0
                                                     ipad:10.0] + [PEUIUtils iphoneXSafeInsetsSide]];
    }
    UIView *subTitleTopView = titleLabel;
    // place small subtitle label
    if (smallSubTitleMsg) {
      UILabel *smallSubTitleLabel = [PEUIUtils labelWithKey:smallSubTitleMsg
                                                       font:[UIFont systemFontOfSize:[PEUIUtils valueIfiPhone5Width:8.0
                                                                                                       iphone6Width:9.0
                                                                                                   iphone6PlusWidth:10.0
                                                                                                               ipad:14.0]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor grayColor]
                                        verticalTextPadding:3.0];
      [smallSubTitleLabel setTag:smallSubTitleTag];
      [PEUIUtils placeView:smallSubTitleLabel
                     below:titleLabel
                      onto:view
             withAlignment:PEUIHorizontalAlignmentTypeLeft
                  vpadding:4.0
                  hpadding:0.0];
      subTitleTopView = smallSubTitleLabel;
    }
    
    // place subtitle label
    if (subTitleMsg) {
      UIColor *textColor = [UIColor grayColor];
      UILabel *subtitleLabel;
      if (syncWarningNeedsFix) {
        textColor = [UIColor sunflowerColor];
        UIImage *syncWarningIcon = [UIImage imageNamed:@"warning-icon"];
        UIImageView *syncWarningIconView = [[UIImageView alloc] initWithImage:syncWarningIcon];
        [syncWarningIconView setTag:warningIconTag];
        [PEUIUtils placeView:syncWarningIconView
                  atBottomOf:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:4.0
                    hpadding:subtitleLeftHPadding];
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg,
                                                           (subtitleFitToWidthFactor * view.frame.size.width)
                                                           - (syncWarningIconView.frame.size.width + 2.0));
        [PEUIUtils placeView:subtitleLabel
                toTheRightOf:syncWarningIconView
                        onto:view
               withAlignment:PEUIVerticalAlignmentTypeMiddle
                    hpadding:2.0];
      } else {
        if (syncWarningTemporary) {
          textColor = [UIColor sunflowerColor];
        }
        subtitleLabel = [uitoolkit tableCellSubtitleMaker](subTitleMsg,
                                                           (subtitleFitToWidthFactor * view.frame.size.width)
                                                           - subtitleLeftHPadding);
        [PEUIUtils placeView:subtitleLabel
                       below:subTitleTopView
                        onto:view
               withAlignment:PEUIHorizontalAlignmentTypeLeft
                    vpadding:4.0
                    hpadding:0.0];
      }
      [subtitleLabel setTextColor:textColor];
      [subtitleLabel setTag:subtitleTag];
    }
  };
}


@end
