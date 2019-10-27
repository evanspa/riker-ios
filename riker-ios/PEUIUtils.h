//
// PEUIUtils.h
//

#import <Foundation/Foundation.h>
#import "PEUIToolkit.h"
#import "JGActionSheet.h"

/** Horizontal alignment types. */
typedef NS_ENUM(NSInteger, PEUIHorizontalAlignmentType) {
  PEUIHorizontalAlignmentTypeLeft,
  PEUIHorizontalAlignmentTypeRight,
  PEUIHorizontalAlignmentTypeCenter
};

/** Vertical alignment types. */
typedef NS_ENUM(NSInteger, PEUIVerticalAlignmentType) {
  PEUIVerticalAlignmentTypeTop,
  PEUIVerticalAlignmentTypeBottom,
  PEUIVerticalAlignmentTypeMiddle
};

/**
 *  Collects the given message associated with a UI input control with a the given
 *  tag.
 */
typedef void (^PEMessageCollector)(NSUInteger, NSString *);

FOUNDATION_EXPORT CGFloat const IPAD_ALERT_PANEL_EXTRA_WIDTH;

/** A collection of UI helper functions. */
@interface PEUIUtils : NSObject

#pragma mark - Helpers

+ (UIFont *)fontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                   font:(UIFont *)font;

+ (UIFont *)boldFontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                       font:(UIFont *)font;

+ (UIFont *)italicFontWithMaxAllowedPointSize:(CGFloat)maxAllowedPointSize
                                         font:(UIFont *)font;

+ (NSDictionary *)paragraphBeforeSpacingAttrs;

+ (BOOL)isIpad;

+ (BOOL)isIphoneX;

+ (BOOL)isPortraitMode;

+ (UIFont *)infoIconFont;

+ (UIFont *)actionButtonFont;

+ (CGFloat)actionButtonVpadding;

+ (CGFloat)actionButtonHpadding;

+ (UIFont *)actionCancelButtonFont;

+ (CGFloat)actionCancelButtonVpadding;

+ (CGFloat)actionCancelButtonHpadding;

+ (CGFloat)availableWidthForAlertPanelRelativeToView:(UIView *)relativeToView;

+ (void)styleViewForIpad:(UIView *)view;

+ (UIFontTextStyle)subheadlineFontTextStyle;

+ (UIFontTextStyle)bodyFontTextStyle;

+ (UIFontTextStyle)captionFontTextStyle;

+ (UIFontTextStyle)userAccountInfoFontTextStyle;

+ (CGFloat)heightForUserAccountTextfields;

+ (CGFloat)widthOfForContent;

+ (CGFloat)iphoneXSafeInsetsSide;

+ (CGFloat)valueIfiPhoneXSMaxOrXrInPortrait:(CGFloat)xsMaxXrValue
                                      other:(CGFloat)otherValue;

+ (CGFloat)valueIfiPhone5Width:(CGFloat)fiveValue
                  iphone6Width:(CGFloat)sixValue
              iphone6PlusWidth:(CGFloat)sixPlusValue
                          ipad:(CGFloat)ipadValue;

+ (CGFloat)valueIfiPhone5Width:(CGFloat)fiveValue
                  iphone6Width:(CGFloat)sixValue
              iphone6PlusWidth:(CGFloat)sixPlusValue
                          ipad:(CGFloat)ipadValue
                   ipadPro12in:(CGFloat)ipadPro12inValue;

+ (id)objIfiPhone5Width:(id)fiveValue
           iphone6Width:(id)sixValue
       iphone6PlusWidth:(id)sixPlusValue
                   ipad:(id)ipadValue;

+ (id)objIfiPhone5Width:(id)fiveValue
           iphone6Width:(id)sixValue
       iphone6PlusWidth:(id)sixPlusValue
                   ipad:(id)ipadValue
            ipadPro12in:(id)ipadPro12inValue;

+ (UIFontTextStyle)fontTextStyleIfiPhone5Width:(UIFontTextStyle)fiveValue
                                  iphone6Width:(UIFontTextStyle)sixValue
                              iphone6PlusWidth:(UIFontTextStyle)sixPlusValue
                                          ipad:(UIFontTextStyle)ipadValue;

+ (UIFontTextStyle)fontTextStyleIfiPhone5Width:(UIFontTextStyle)fiveValue
                                  iphone6Width:(UIFontTextStyle)sixValue
                              iphone6PlusWidth:(UIFontTextStyle)sixPlusValue
                                          ipad:(UIFontTextStyle)ipadValue
                                   ipadPro12in:(UIFontTextStyle)ipadPro12inValue;

+ (void)execBlockIfiPhone5Width:(void(^)(void))fiveBlk
                   iphone6Width:(void(^)(void))sixBlk
               iphone6PlusWidth:(void(^)(void))sixPlusBlk
                           ipad:(void(^)(void))ipadBlk;

#pragma mark - Validation Utils

/**
 *  Returns a new message collector that will append messages to the given
 *  errMsgs collection if the tagged textfield from the given entityPanel
 *  contains an empty value.
 *  @param errMsgs     The set of error messages.
 *  @param entityPanel The view panel containing the tagged textfield.
 *  @return A new message collector.
 */
+ (PEMessageCollector)newTfCannotBeEmptyBlkForMsgs:(NSMutableArray *)errMsgs
                                       entityPanel:(UIView *)entityPanel;

+ (PEMessageCollector)newTfCannotBeZeroBlkForMsgs:(NSMutableArray *)errMsgs
                                      entityPanel:(UIView *)entityPanel;

#pragma mark - Offline Mode Helpers

+ (void)bringOfflineModeViewsToFrontForController:(UIViewController *)controller;

+ (UIView *)offlineModeLabelWithController:(UIViewController *)controller;

+ (UIView *)offlineModeBarWithController:(UIViewController *)controller;

+ (void)addOfflineModeBarToController:(UIViewController *)controller animate:(BOOL)animate;

+ (void)removeOfflineModeBarFromController:(UIViewController *)controller animated:(BOOL)animated;

#pragma mark - Position Utils

+ (CGFloat)vpaddingForTopOfController:(UIViewController *)controller;

/**
 Sets both the frame x and y-coordinates of the given view.
 @param xcoord The new frame x-coordinate.
 @param ycoord The new frame y-coordinate.
 @param view The view.
 */
+ (void)setFrameX:(CGFloat)xcoord andY:(CGFloat)ycoord ofView:(UIView *)view;

/**
 Sets both the frame x and y-coordinates of the given view using the
 given point.
 @param origin The point that should be used to set the origin (x and y
 coordinates) of the given view.
 @param view The view.
 */
+ (void)setFrameOrigin:(CGPoint)origin ofView:(UIView *)view;

/**
 Sets the frame x-coordinate of the given view.
 @param xcoord the new frame x-coordinate
 @param view the view
 */
+ (void)setFrameX:(CGFloat)xcoord ofView:(UIView *)view;

/**
 Sets the frame y-coordinate of the given view.
 @param ycoord the new frame y-coordinate
 @param view the view
 */
+ (void)setFrameY:(CGFloat)ycoord ofView:(UIView *)view;

/**
 Adds adjust to the view frame's x-coordinate.
 @param view the view whose frame should be adjusted (modified)
 @param adjust value added to the view frame's x-coordinate
 */
+ (void)adjustXOfView:(UIView *)view withValue:(CGFloat)adjust;

/**
 Adds adjust to the view frame's y-coordinate.
 @param view the view whose frame should be adjusted (modified)
 @param adjust value added to the view frame's y-coordinate
 */
+ (void)adjustYOfView:(UIView *)view withValue:(CGFloat)adjust;

+ (void)adjustHeightOfView:(UIView *)view withValue:(CGFloat)adjust;

+ (void)adjustWidthOfView:(UIView *)view withValue:(CGFloat)adjust;

/**
 Returns the x-coordinate necessary to place a theoretical view onto
 relativeToView based on the theoretical view's width for the given
 horizontal alignment.
 @param width The width of a theoretical view.
 @param alignment The desired horiztonal alignment.
 @param relativeToView The view the theoretical placement would occur on.
 @param hpadding Horizontal padding to be taken into account; this parameter is
 ignored if the alignment type is 'center'
 @return The x-coordinate of the theoretical placement.
 */
+ (CGFloat)XForWidth:(CGFloat)width
       withAlignment:(PEUIHorizontalAlignmentType)alignment
      relativeToView:(UIView *)relativeToView
            hpadding:(CGFloat)hpadding;

/**
 Returns the y-coordinate necessary to place a theoretical view onto
 relativeToView based on the theoretical view's height for the given
 vertical alignment.
 @param height The height of a theoretical view.
 @param alignment The desired vertical alignment.
 @param relativeToView The view the theoretical placement would occur on.
 @param vpadding Vertical padding to be taken into account; this parameter is
 ignored if the alignment type is 'center'
 @return The y-coordinate of the theoretical placement.
*/
+ (CGFloat)YForHeight:(CGFloat)height
        withAlignment:(PEUIVerticalAlignmentType)alignment
       relativeToView:(UIView *)relativeToView
             vpadding:(CGFloat)vpadding;

/**
 Calculates and returns the point to the right of view, with size's height
 factored into the y-coordinate.
 @param size The height of this box is used to find the proper y-coordinate to
 return.
 @param view The view serving as the neighbor for the calculated point.
 @param alignment The vertical alignment type.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param hpadding Horizontal padding to apply.
 @return The point representing a beside-to spot to the right of the view.
 */
+ (CGPoint)pointToTheRightOf:(UIView *)view
               withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
                    hpadding:(CGFloat)hpadding
                forBoxOfSize:(CGSize)size;

/**
 Calculates and returns the point to the left of view, with size's height
 factored into the y-coordinate.
 @param size The height of this box is used to find the proper y-coordinate to
 return.
 @param view The view serving as the neighbor for the calculated point.
 @param alignment The vertical alignment type.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param hpadding Horizontal padding to apply.
 @return The point representing a beside-to spot to the left of the view.
*/
+ (CGPoint)pointToTheLeftOf:(UIView *)view
              withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
                   hpadding:(CGFloat)hpadding
               forBoxOfSize:(CGSize)size;

/**
 Calculates and returns the point above view, with size factored into the x and
 y coordinates.
 @param size This box is used to find the proper x and y-coordinates to return.
 @param view The view serving as the South-neighbor for the calculated point.
 @param alignment The horizontal alignment type.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param vpadding Vertical padding to apply.
 @param hpadding Horizontal padding to apply.
 @return The point representing an above-to spot of the view.
*/
+ (CGPoint)pointAbove:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size;

/**
 Calculates and returns the point below view, with size factored into the x and
 y coordinates.
 @param size This box is used to find the proper x and y-coordinates to return.
 @param view The view serving as the North-neighbor for the calculated point.
 @param alignment The horizontal alignment type.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param vpadding Vertical padding to apply.
 @param hpadding Horizontal padding to apply.
 @return The point representing a below-to spot of the view.
*/
+ (CGPoint)pointBelow:(UIView *)view
        withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
             vpadding:(CGFloat)vpadding
             hpadding:(CGFloat)hpadding
         forBoxOfSize:(CGSize)size;

#pragma mark - Dimension Utils

/**
 Calculates and returns the height for the given text string, constrained to the
 given width.
 @param text the text-string for the calculation
 @param width the width-constraint for the calculation
 @return the calculated height
*/
+ (CGFloat)heightForText:(NSString *)text forWidth:(CGFloat)width;

/**
 Calculates and returns the size (height and width) for the given text string
 and font.
 @param text the text-string for the calculation
 @param font the font for the calculation
 @return the calculated size (height and width)
*/
+ (CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font;

/**
 Returns the value of the width of the widest view within views.
 @param views The set of views.
 @return The width of the widest view.
*/
+ (CGFloat)widthWidestAmong:(NSArray *)views;

+ (CGFloat)heightHighestAmong:(NSArray *)views;

#pragma mark - View Positioning

+ (void)positionView:(UIView *)view
             atTopOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
          atBottomOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
          inMiddleOf:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
                 and:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
     inMiddleBetween:(UIView *)topView
           andYCoord:(CGFloat)bottomYCoordinate
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
             andView:(UIView *)bottomView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
                onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
           andYCoord:(CGFloat)bottomYCoordinate
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
               below:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
               above:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            vpadding:(CGFloat)vpadding
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
         toTheLeftOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
            hpadding:(CGFloat)hpadding;

+ (void)positionView:(UIView *)view
        toTheRightOf:(UIView *)relativeTo
                onto:(UIView *)ontoView
       withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
            hpadding:(CGFloat)hpadding;

#pragma mark - View Placement

/**
 Places the given view at the top of ontoView, using the given horizontal
 alignment type.
 @param view The view to be added.
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param vpadding Vertical padding to apply between the given view and ontoView.
 @param hpadding Horizontal padding to apply between the given view and ontoView.
 */
+ (void)placeView:(UIView *)view
          atTopOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view at the bottom of ontoView, using the given horizontal
 alignment type.
 @param view The view to be added.
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param vpadding Vertical padding to apply between the given view and ontoView.
 @param hpadding Horizontal padding to apply between the given view and ontoView.
 */
+ (void)placeView:(UIView *)view
       atBottomOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view in the middle of ontoView, using the given horizontal
 alignment type.
 @param view The view to be added.
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param hpadding Horizontal padding to apply between the given view and ontoView.
 */
+ (void)placeView:(UIView *)view
       inMiddleOf:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
              and:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
  inMiddleBetween:(UIView *)topView
        andYCoord:(CGFloat)bottomYCoordinate
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
          andView:(UIView *)bottomView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

+ (void)placeView:(UIView *)view
             onto:(UIView *)ontoView
inMiddleBetweenYCoord:(CGFloat)topYCoordinate
        andYCoord:(CGFloat)bottomYCoordinate
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

/**
 Places the given view below relativeTo view on to ontoView, using the given
 horizontal alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added below (aka, the
 North-view).
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param vpadding Vertical padding to apply between the given view and
 relativeTo.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view below relativeTo view on to ontoView, using the given
 horizontal alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added below (aka, the
 North-view).
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param vpadding Vertical padding to apply between the given view and
 relativeTo.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
            below:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view above relativeTo view on to ontoView, using the given
 horizontal alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added above (aka, the
 South-view).
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param vpadding Vertical padding to apply between the given view and
 relativeTo.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view above relativeTo view on to ontoView, using the given
 horizontal alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added above (aka, the
 South-view).
 @param ontoView The view in which the given view is added.
 @param alignment The horizontal alignment type used when setting the
 x-coordinate of view's frame.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param vpadding Vertical padding to apply between the given view and
 relativeTo.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
            above:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIHorizontalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         vpadding:(CGFloat)vpadding
         hpadding:(CGFloat)hpadding;

/**
 Places the given view to the left of relativeTo view on to ontoView, using the
 given vertical alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added next to (aka, the
 East-view).
 @param ontoView The view in which the given view is added.
 @param alignment The vertical alignment type used when setting the
 y-coordinate of view's frame.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

/**
 Places the given view to the left of relativeTo view on to ontoView, using the
 given vertical alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added next to (aka, the
 East-view).
 @param ontoView The view in which the given view is added.
 @param alignment The vertical alignment type used when setting the
 y-coordinate of view's frame.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
      toTheLeftOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding;

/**
 Places the given view to the right of relativeTo view on to ontoView, using the
 given vertical alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added next to (aka, the
 West-view).
 @param ontoView The view in which the given view is added.
 @param alignment The vertical alignment type used when setting the
 y-coordinate of view's frame.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
         hpadding:(CGFloat)hpadding;

/**
 Places the given view to the right of relativeTo view on to ontoView, using the
 given vertical alignment type.
 @param view The view to be added.
 @param relativeTo The view the given view should be added next to (aka, the
 West-view).
 @param ontoView The view in which the given view is added.
 @param alignment The vertical alignment type used when setting the
 y-coordinate of view's frame.
 @param alignmentRelativeToView The view that the 'alignment' is relative to.
 @param hpadding Horizontal padding to apply between the given view and
 relativeTo.
 */
+ (void)placeView:(UIView *)view
     toTheRightOf:(UIView *)relativeTo
             onto:(UIView *)ontoView
    withAlignment:(PEUIVerticalAlignmentType)alignment
alignmentRelativeToView:(UIView *)alignmentRelativeToView
         hpadding:(CGFloat)hpadding;

#pragma mark - Animations

+ (void)popAnimateView:(UIView *)sender
               scaleUp:(CGFloat)scaleUp
             scaleDown:(CGFloat)scaleDown
       scaleUpDuration:(CGFloat)scaleUpDuration
     scaleDownDuration:(CGFloat)scaleDownDuration
 scaleIdentityDuration:(CGFloat)scaleIdentityDuration
            completion:(void(^)(void))completion;

/**
 *  Places via an animation the given view onto relativeTo view.  The view will
 *  drop downwards from the top to downToY, with a duration of duration and a
 *  fade-out duration of fadeOutDuration.
 *  @param view            The view to animate and place onto relativeTo view.
 *  @param relativeTo      The view onto which view will be placed upon.
 *  @param downToY         The Y-coordinate of where view will animate down to.
 *  @param alignment       The vertical alignment type used when setting the
 y-coordinate of view's frame.
 *  @param hpadding        Horizontal padding to apply between the given view and
 relativeTo.
 *  @param duration        The duration it takes view to animate to its resting place.
 *  @param fadeOutDuration The duration it takes view to fade-out.
 */
+ (void)placeAndAnimateView:(UIView *)view
              fromTopOfView:(UIView *)relativeTo
                    downToY:(CGFloat)downToY
              withAlignment:(PEUIHorizontalAlignmentType)alignment
                   hpadding:(CGFloat)hpadding
                   duration:(NSTimeInterval)duration
            fadeOutDuration:(NSTimeInterval)fadeOutDuration;

#pragma mark - View Sizing

/**
 Sets the frame width of the given view.
 @param width the new frame width
 @param view the view
 */
+ (void)setFrameWidth:(CGFloat)width ofView:(UIView *)view;

/**
 Sets the frame width as a percentage of the width of the given relative-to
 view.
 @param view the whose width should be set
 @param percentage the percentage of the width of the given relative-to view to
 use to set the width of the given view.
 @param relativeToView the view the percentage is based on
*/
+ (void)setFrameWidthOfView:(UIView *)view
                    ofWidth:(CGFloat)percentage
                 relativeTo:(UIView *)relativeToView;

/**
 Sets the frame height of the given view.
 @param height the new frame height
 @param view the view
*/
+ (void)setFrameHeight:(CGFloat)height ofView:(UIView *)view;

/**
 Sets the frame height as a percentage of the height of the given relative-to
 view.
 @param view the whose height should be set
 @param percentage the percentage of the height of the given relative-to view to
 use to set the height of the given view.
 @param relativeToView the view the percentage is based on
*/
+ (void)setFrameHeightOfView:(UIView *)view
                    ofHeight:(CGFloat)percentage
                  relativeTo:(UIView *)relativeToView;

/**
 Updates the height of the given view's frame to fit all of its subviews, as
 well as the specific North and South padding.
 @param panel The panel whose height should be adjusted.
 @param bottomPadding THe amount of padding to apply to the bottom of the
 computed height.
 */
+ (void)adjustHeightToFitSubviewsForView:(UIView *)panel
                           bottomPadding:(CGFloat)bottomPadding;

#pragma mark - View Controller Commons

/**
 Wraps the given view controller within a new UINavigationController.  The given
 view controller will be set as the root controller of the nav controller.
 @param viewController the view controller to be wrapped
 @return the newly-created navigation controller with viewController wrapped
         within it
 */
+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController;

/**
 *  Creates and returns a navigation controller with viewController as its root.
 *  @param viewController      The view controller to be the root controller of the
 returned navigation controller.
 *  @param navigationBarHidden Whether or not the navigation bar of the nav controller
 should be hidden.
 *  @return a new navigation controller with viewController as its root controller.
 */
+ (UINavigationController *)navigationControllerWithController:(UIViewController *)viewController
                                           navigationBarHidden:(BOOL)navigationBarHidden;

/**
 *  Displays controller from fromController.  If fromController is a navigation
 *  controller, controller will be pushed onto its stack.  Otherwise controller
 *  will simply be presented.
 *  @param controller     The controller to display.
 *  @param fromController The 'from' controller.
 *  @param animated       Whether or not to animate the displaying of the controller.
 */
+ (void)displayController:(UIViewController *)controller
           fromController:(UIViewController *)fromController
                 animated:(BOOL)animated;

/**
 *  Creates and returns a navigation controller with viewController set as its
 *  root controller, and will have a tab bar associated with it.
 *  @param viewController          The controller to be the root controller of the
 return navigation controller.
 *  @param navigationBarHidden     Whether or not the navigation bar of the nav controller
 should be hidden.
 *  @param tabBarItemTitle         The title of the single tab bar item of the
 tab bar.
 *  @param tabBarItemImage         The image of the single tab bar item.
 *  @param tabBarItemSelectedImage The selected-image of the single tab bar item.
 *  @return a new navigation controller with viewController as its root controller.
 */
+ (UINavigationController *)navControllerWithRootController:(UIViewController *)viewController
                                        navigationBarHidden:(BOOL)navigationBarHidden
                                            tabBarItemTitle:(NSString *)tabBarItemTitle
                                            tabBarItemImage:(UIImage *)tabBarItemImage
                                    tabBarItemSelectedImage:(UIImage *)tabBarItemSelectedImage;

#pragma mark - Color Utils

/**
 Creates and returns a UIImage view instance from the given color.
 @param color the color to form the basis for the generated UIImage
 @return the generated UIImage
*/
+ (UIImage *)imageWithColor:(UIColor *)color;

/**
 Applies a border to the given view in the given color of width 1.0.
 @param view the view to apply a border to
 @param color the color to use for the border
*/
+ (void)applyBorderToView:(UIView *)view withColor:(UIColor *)color;

/**
 Applies a border to the given view in the given color and width.
 @param view the view to apply a border to
 @param color the color to use for the border.
 @param width The width to use for the border.
 */
+ (void)applyBorderToView:(UIView *)view
                withColor:(UIColor *)color
                    width:(CGFloat)width;

#pragma mark - Attributed Text

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                        templateTextColor:(UIColor *)templateTextColor
                                         templateTextFont:(UIFont *)templateTextFont
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor
                             additionalTemplateAttributes:(NSDictionary *)additionalTemplateAttributes;

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                        templateTextColor:(UIColor *)templateTextColor
                                         templateTextFont:(UIFont *)templateTextFont
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor;

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                          accentTextColor:(UIColor *)accentTextColor;

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont;

+ (NSMutableAttributedString *)attributedTextWithTemplate:(NSString *)templateText
                                             textToAccent:(NSString *)textToAccent
                                           accentTextFont:(UIFont *)accentTextFont
                                                    attrs:(NSDictionary *)attrs;

+ (NSMutableDictionary *)attrsWithPpBeforeSpacing:(CGFloat)beforeSpacing;

+ (NSMutableDictionary *)attrsWithLineSpacing:(CGFloat)lineSpacing;

#pragma mark - Text Truncation

+ (NSString *)truncatedTextForText:(NSString *)text
                              font:(UIFont *)font
                    availableWidth:(CGFloat)availableWidth;

#pragma mark - Labels

+ (UIFont *)boldFontForTextStyle:(NSString *)textStyle;

+ (UIFont *)italicFontForTextStyle:(NSString *)textStyle;

+ (UIFont *)boldItalicFontForTextStyle:(NSString *)textStyle;

+ (UIFont *)fontForTextStyle:(NSString *)textStyle
                       trait:(UIFontDescriptorSymbolicTraits)trait;

/**
 Constructs and returns a UILabel with the given attributes.
 @param key Key to a localized string to use for the text of the label; if no
 localized string is found for the key, the key itself is used as the text for
 the label.
 @param font The font to use for the label text.
 @param backgroundColor The background color to use for the label.
 @param textColor The text color to use for the label.
 @param verticalTextPadding Vertical padding to apply to the label's
 frame-height.
 @return The newly constructed label.
 */
+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding;

/**
 Constructs and returns a UILabel with the given attributes.
 @param key Key to a localized string to use for the text of the label; if no
 localized string is found for the key, the key itself is used as the text for
 the label.
 @param font The font to use for the label text.
 @param backgroundColor The background color to use for the label.
 @param textColor The text color to use for the label.
 @param verticalTextPadding Vertical padding to apply to the label's
 frame-height.
 @param fitToWidth Width for label to fit.
 @return The newly constructed label.
 */
+ (UILabel *)labelWithKey:(NSString *)key
                     font:(UIFont *)font
          backgroundColor:(UIColor *)backgroundColor
                textColor:(UIColor *)textColor
      verticalTextPadding:(CGFloat)verticalTextPadding
               fitToWidth:(CGFloat)fitToWidth;

/**
 Constructs and returns a UILabel with the given attributes.
 @param attributedText The attributed string to use for the text of the label.
 @param font The font to use for the label text.
 @param backgroundColor The background color to use for the label.
 @param textColor The text color to use for the label.
 @param verticalTextPadding Vertical padding to apply to the label's
 frame-height.
 @return The newly constructed label.
 */
+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding;

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding;

/**
 Constructs and returns a UILabel with the given attributes.
 @param attributedText The attributed string to use for the text of the label.
 @param font The font to use for the label text.
 @param backgroundColor The background color to use for the label.
 @param textColor The text color to use for the label.
 @param verticalTextPadding Vertical padding to apply to the label's
 frame-height.
 @param fitToWidth Width for label to fit.
 @return The newly constructed label.
 */
+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth;

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth;

+ (UILabel *)labelWithAttributeText:(NSAttributedString *)attributedText
                               font:(UIFont *)font
           fontForHeightCalculation:(UIFont *)fontForHeightCalculation
               additionalAttributes:(NSDictionary *)additionalAttributes
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                verticalTextPadding:(CGFloat)verticalTextPadding
                         fitToWidth:(CGFloat)fitToWidth;

/**
 Left pads label by returning a panel containing a blank view of width padding,
 and view sitting next to it.
 @param view The view to left-pad.
 @param padding The padding amount.
 @return a panel containing a blank view of width padding,
 and view sitting next to it.
 */
+ (UIView *)leftPadView:(UIView *)view
                padding:(CGFloat)padding;

/**
 Right pads view by returning a panel containing a blank view of width padding,
 and view sitting next to it.
 @param view The view to right-pad.
 @param padding The padding amount.
 @return a panel containing a blank view of width padding,
 and view sitting next to it.
 */
+ (UIView *)rightPadView:(UIView *)view
                 padding:(CGFloat)padding;

/**
 *  Sets the text and resizes the given label.
 *  @param text  The new text for label.
 *  @param label The label.
 */
+ (void)setTextAndResize:(NSString *)text forLabel:(UILabel *)label;

+ (UIView *)badgeForNum:(NSInteger)num
                  color:(UIColor *)color
         badgeTextColor:(UIColor *)badgeTextColor;

+ (void)refreshRecordCountLabelOnButton:(UIButton *)button
                    recordCountLabelTag:(NSInteger)recordCountLabelTag
                            recordCount:(NSInteger)recordCount;

#pragma mark - Text Fields

/**
 Constructs and returns a UITextField with the given attributes.
 @param key Key to a localized string to use for the placeholder text of the
 textfield; if no localized string is found for the key, the key itself is used
 as the placeholder text for the textfield.
 @param font The font to use for the text inside the textfield.
 @param backgroundColor The background color to use for the textfield.
 @param leftViewPadding Padding to apply to the beginning (left) of the
 textfield.
 @param width The width to give to the textfield.
 @return The newly constructed textfield.
*/
+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width;

/**
 Constructs and returns a UITextField with the given attributes.
 @param key Key to a localized string to use for the placeholder text of the
 textfield; if no localized string is found for the key, the key itself is used
 as the placeholder text for the textfield.
 @param font The font to use for the text inside the textfield.
 @param backgroundColor The background color to use for the textfield.
 @param leftViewPadding Padding to apply to the beginning (left) of the
 textfield.
 @param width The width to give to the textfield.
 @param heightFactor The height factor.
 @return The newly constructed textfield.
 */
+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                      fixedWidth:(CGFloat)width
                                    heightFactor:(CGFloat)heightFactor;

/**
 Constructs and returns a UITextField with the given attributes.
 @param key Key to a localized string to use for the placeholder text of the
 textfield; if no localized string is found for the key, the key itself is used
 as the placeholder text for the textfield.
 @param font The font to use for the text inside the textfield.
 @param backgroundColor The background color to use for the textfield.
 @param leftViewPadding Padding to apply to the beginning (left) of the
 textfield.
 @param percentage The percentage of the width of the given relativeToView
 to make the width of the textfield.
 @param relativeToView View whose width is used to calculate the width of the
 textfield.
 @return The newly constructed textfield.
 */
+ (UITextField *)textfieldWithPlaceholderTextKey:(NSString *)key
                                            font:(UIFont *)font
                                 backgroundColor:(UIColor *)backgroundColor
                                 leftViewPadding:(CGFloat)leftViewPadding
                                         ofWidth:(CGFloat)percentage
                                      relativeTo:(UIView *)relativeToView;

/**
 *  Returns the text of the textfield found on view with the given tag.
 *  @param tag  The tag of the textfield.
 *  @param view The view the textfield is on.
 *  @return The text value of the textfield with tag value tag on view.
 */
+ (NSString *)stringFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view;

/**
 *  Returns the text of the textfield found on view with the given tag as a
 *  number value.
 *  @param tag  The tag of the textfield.
 *  @param view The view the textfield is on.
 *  @return The number value of the textfield with tag value tag on view.
 */
+ (NSNumber *)numberFromTextFieldWithTag:(NSInteger)tag
                                fromView:(UIView *)view;

/**
 *  Returns the text of the textfield found on view with the given tag as a
 *  decimal number value.
 *  @param tag  The tag of the textfield.
 *  @param view The view the textfield is on.
 *  @return The decimal number value of the textfield with tag value tag on view.
 */
+ (NSDecimalNumber *)decimalNumberFromTextFieldWithTag:(NSInteger)tag
                                              fromView:(UIView *)view;

/**
 *  Binds the value of the text contained in the textfield with tag value tag
 *  on view onto entity using setter.  stringTransformer is applied to the value
 *  before calling setter.
 *  @param entity            The entity to receive the value.
 *  @param setter            The setter to set the value on entity.
 *  @param tfTag             The tag value of the textfield.
 *  @param stringTransformer Transformer to apply to the value before calling the setter.
 *  @param view              The view containing the text field.
 */
+ (void)bindToEntity:(id)entity
          withSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
   stringTransformer:(id (^)(NSString *))stringTransformer
            fromView:(UIView *)view;

/**
 *  Binds the value of the text contained in the textfield with tag value tag
 *  on view onto entity using setter.
 *  @param entity The entity to receive the value.
 *  @param setter The setter to set the value on entity.
 *  @param tfTag  The tag value of the textfield.
 *  @param view   The view containing the text field.
 */
+ (void)bindToEntity:(id)entity
    withStringSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view;

/**
 *  Binds the value of the text as a number contained in the textfield with tag
 *  value tag on view onto entity using setter.
 *  @param entity The entity to receive the value.
 *  @param setter The setter to set the value on entity.
 *  @param tfTag  The tag value of the textfield.
 *  @param view   The view containing the text field.
 */
+ (void)bindToEntity:(id)entity
    withNumberSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view;

/**
 *  Binds the value of the text as a decimal number contained in the textfield
 *  with tag value tag on view onto entity using setter.
 *  @param entity The entity to receive the value.
 *  @param setter The setter to set the value on entity.
 *  @param tfTag  The tag value of the textfield.
 *  @param view   The view containing the text field.
 */
+ (void)bindToEntity:(id)entity
   withDecimalSetter:(SEL)setter
fromTextfieldWithTag:(NSInteger)tfTag
            fromView:(UIView *)view;

/**
 *  Binds the value of getter applied to entity onto the textfield with tag 
 *  value tag found on view.
 *  @param tfTag  The textfield to bind the value to.
 *  @param view   The view containing the textfield.
 *  @param entity The entity.
 *  @param getter The getter to apply to entity for the value.
 */
+ (void)bindToTextControlWithTag:(NSInteger)tfTag
                        fromView:(UIView *)view
                      fromEntity:(id)entity
                      withGetter:(SEL)getter;

+ (void)bindToTextControlWithTag:(NSInteger)tfTag
                        fromView:(UIView *)view
                      fromEntity:(id)entity
                withNumberGetter:(SEL)numberGetter
                       formatter:(NSNumberFormatter *)formatter;

/**
 *  Enables / disables the UIControl with tag value tag found on view based on
 *  the value of enable.
 *  @param tag    The tag value of the UIControl.
 *  @param view   The view containing the UIControl.
 *  @param enable Whether to enable or disable the UIControl.
 */
+ (void)enableControlWithTag:(NSInteger)tag
                    fromView:(UIView *)view
                      enable:(BOOL)enable;
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
                     action:(SEL)action;

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
                     action:(SEL)action;

+ (UIButton *)buttonWithAttributedTitle:(NSAttributedString *)attributedTitle
               fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                        backgroundColor:(UIColor *)backgroundColor
           disabledStateBackgroundColor:(UIColor *)disabledStateBackgroundColor
                        verticalPadding:(CGFloat)verticalPadding
                      horizontalPadding:(CGFloat)horizontalPadding
                           cornerRadius:(CGFloat)cornerRadius
                                 target:(id)target
                                 action:(SEL)action;

+ (void)addDisclosureIndicatorToButton:(UIButton *)button;

+ (void)addDisclosureIndicatorToButton:(UIButton *)button
                                 color:(UIColor *)color;

+ (void)addDisclosureIndicatorToButton:(UIButton *)button
                                 color:(UIColor *)color
                              hpadding:(CGFloat)hpadding;

+ (void)setBackgroundColorOfButton:(UIButton *)button
                             color:(UIColor *)color;

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
               relativeToView:(UIView *)relativeToView;

+ (UIButton *)buttonWithLabel:(NSString *)labelText
                     badgeNum:(NSInteger)badgeNum
                   badgeColor:(UIColor *)badgeColor
               badgeTextColor:(UIColor *)badgeTextColor
            addDisclosureIcon:(BOOL)addDisclosureIcon
                      handler:(void(^)(void))handler
                    uitoolkit:(PEUIToolkit *)uitoolkit
               relativeToView:(UIView *)relativeToView;

#pragma mark - Bundle Image Fetch

+ (UIImage *)bundleImageWithName:(NSString *)imageName;

#pragma mark - Tables

+ (id)valueForSingleTableViewWithTag:(NSInteger)tag panel:(UIView *)panel;

+ (void)setValueForSingleTableViewWithTag:(NSInteger)tag
                                    panel:(UIView *)panel
                                    value:(id)value;

+ (UITableView *)makeTableViewWithTag:(NSNumber *)tag
                            numFields:(NSInteger)numFields
              dataSourceDelegateMaker:(id(^)(UITableView *))dataSourceDelegateMaker
                       relativeToView:(UIView *)relativeToView
                 parentViewController:(UIViewController *)parentViewController;

#pragma mark - Panels

+ (void)cardifyView:(UIView *)view;

+ (UIView *)displayPanelFromContentPanel:(UIView *)contentPanel
                               scrolling:(BOOL)scrolling
                        forceScrollPanel:(BOOL)forceScrollPanel
                     scrollContentOffset:(CGPoint)scrollContentOffset
                          scrollDelegate:(id<UIScrollViewDelegate>)scrollDelegate
                    delaysContentTouches:(BOOL)delaysContentTouches
                                 bounces:(BOOL)bounces
                        notScrollViewBlk:(void(^)(void))notScrollViewBlk
                              controller:(UIViewController *)controller;

+ (UIView *)dividerWithWidthOf:(CGFloat)widthOf
                         color:(UIColor *)color
                relativeToView:(UIView *)relativeToView;

/**
 Constructs and returns a UIView with the given width and height to use for the
 view's frame dimensions.
 @param width The width to set for the view's frame.
 @param height The height to set for the view's frame.
 @return The newly constructed view.
 */
+ (UIView *)panelWithFixedWidth:(CGFloat)width
                    fixedHeight:(CGFloat)height;

/**
 Constructs and returns a UIView with dimensions based on the given parameters.
 @param percentage A percentage used to calculate the width for the view's
 frame.  The percentage will be that of the given relativeToView's frame width.
 @param relativeToView The view whose frame dimensions are used in the
 calculation of the width and height of the generated panel's frame dimensions.
 @param height The height to set for the view's frame.
 @return The newly constructed view.
*/
+ (UIView *)panelWithWidthOf:(CGFloat)percentage
              relativeToView:(UIView *)relativeToView
                 fixedHeight:(CGFloat)height;

/**
 Constructs and returns a UIView with dimensions based on the given parameters.
 @param widthPercentage A percentage used to calculate the width for the view's
 frame.  The percentage will be that of the given relativeToView's frame width.
 @param heightPercentage A percentage used to calculate the height for the
 view's frame.  The percentage will be that of the given relativeToView's frame
 height.
 @param relativeToView The view whose frame dimensions are used in the
 calculation of the width and height of the generated panel's frame dimensions.
 @return The newly constructed view.
*/
+ (UIView *)panelWithWidthOf:(CGFloat)widthPercentage
                 andHeightOf:(CGFloat)heightPercentage
              relativeToView:(UIView *)relativeToView;

+ (UIView *)panelOfBrickLayedViewsFromItems:(NSArray *)items
                                  viewMaker:(UIView *(^)(NSInteger, id))viewMaker
                                  extraView:(UIView *)extraView
                             availableWidth:(CGFloat)availableWidth
                                   hpadding:(CGFloat)hpadding
                                   vpadding:(CGFloat)vpadding;

/**
 Creates a panel (UIView) that will contain the set of given views as a single
 column of views.  The views will be aligned to each other based on the given
 horizontal alignment type parameter.  The amount of space that will appear
 between each view is based on the given vertical padding parameter.  The width
 of the panel will be the width of the widest view.  The height of the panel
 will just that to contain the columnar stacking of the views (including the
 padding).
 @param views The set of views to be added to the panel.
 @param vpadding The spacing to appear between each view.
 @param alignment The horizontal alignment that should be used by the views
 with respect to one another.
 @return A panel (UIView) that contains the given views as described.
 */
+ (UIView *)panelWithColumnOfViews:(NSArray *)views
       verticalPaddingBetweenViews:(CGFloat)vpadding
                    viewsAlignment:(PEUIHorizontalAlignmentType)alignment;

+ (UIView *)panelWithRowOfViews:(NSArray *)views
  horizontalPaddingBetweenViews:(CGFloat)hpadding
                 viewsAlignment:(PEUIVerticalAlignmentType)alignment;

/**
 Creates a panel (UIView) to contain 2 columns of views, sourced from the given
 2 arrays of views.  The left-column views will be right-justified, and the
 right-column views will be left-justified.  The spacing between the stacked
 views (on both left and right sides) can be specified, as well as the spacing
 to appear between the 2 columns.
 @param ltColViews The set of views to be stacked within the left column.
 @param rtColViews The set of views to be stacked within the right column.
 @param vpadding The amount of spacing to appear between the stacked views in
 both columns.
 @param hpadding The amount of spacing to appear between the 2 columns.
 @return The created panel.
 */
+ (UIView *)twoColumnViewCluster:(NSArray *)ltColViews
                 withRightColumn:(NSArray *)rtColViews
     verticalPaddingBetweenViews:(CGFloat)vpadding
 horizontalPaddingBetweenColumns:(CGFloat)hpadding;

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
                                 rowWidth:(CGFloat)rowWidth;

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
                           relativeToView:(UIView *)relativeToView;

+ (UIView *)labelValuePanelWithCellHeight:(CGFloat)cellHeight
                              labelString:(id)labelStr
                           labelTextStyle:(UIFontTextStyle)labelTextStyle
                           labelTextColor:(UIColor *)labelTextColor
                        labelLeftHPadding:(CGFloat)labelLeftHPadding
                             iconImageUrl:(NSString *)iconImageUrl
                              valueString:(UIFontTextStyle)valueStr
                           valueTextStyle:(UIFontTextStyle)valueTextStyle
                           valueTextColor:(UIColor *)valueTextColor
                       valueRightHPadding:(CGFloat)valueRightHPadding
                            valueLabelTag:(NSNumber *)valueLabelTag
            minPaddingBetweenLabelAndIcon:(CGFloat)minPaddingBetweenLabelAndIcon
                                 rowWidth:(CGFloat)rowWidth
                           relativeToView:(UIView *)relativeToView;

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
                           relativeToView:(UIView *)relativeToView;

/**
 Creates a panel that displays rowData as a 2-dimensional table.
 @param rowData An array of arrays.  Each array contained in rowData should 
 consist of exactly 2 elements.  The first element being a label string and the
 2nd element being the value string.
 */
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
                   relativeToView:(UIView *)relativeToView;

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
                   relativeToView:(UIView *)relativeToView;

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
                   relativeToView:(UIView *)relativeToView;

// table panel with reasonable defaults
+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView;

// table panel with reasonable defaults
+ (UIView *)tablePanelWithRowData:(NSArray *)rowData
             footerAttributedText:(NSAttributedString *)footerAttributedText
   footerFontForHeightCalculation:(UIFont *)footerFontForHeightCalculation
            footerVerticalPadding:(CGFloat)footerVerticalPadding
                        uitoolkit:(PEUIToolkit *)uitoolkit
                       parentView:(UIView *)parentView;

/**
 Creates a panel (UIView) that will contain a string of views flowing from left
 to right, with hpadding in-between them.  The string-of-views will be
 horizontally alignment using the given horAlignment, and each individual view
 will be vertically alignment to ach other using the given vertAlignment.  The
 width of the resulting panel will be the percentage specified relative to the
 given relativeTo view.
 @param views The set of views to string together.
 @param percentage A percentage used to calculate the width for the panel's
 frame.  The percentage will be that of the given relativeToView's frame width.
 @param horAlignment The horizontal alignment of the view-set on the resulting
 panel.
 @param vertAlignment The vertical alignment of the individual views relative
 to each other.
 @param relativeToView The view to which the width of the resulting panel will
 be based on.
 @param vpadding Vertical padding to apply to the resulting panel.
 @param hpadding Horizontal padding to apply to the resulting panel.
 @return A new panel (UIView) that contains the given views strung-together
 left-to-right.
 */
+ (UIView *)panelWithViews:(NSArray *)views
                   ofWidth:(CGFloat)percentage
      vertAlignmentOfViews:(PEUIVerticalAlignmentType)vertAlignment
       horAlignmentOfViews:(PEUIHorizontalAlignmentType)horAlignment
                relativeTo:(UIView *)relativeToView
                  vpadding:(CGFloat)vpadding
                  hpadding:(CGFloat)hpadding;

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
               description:(NSAttributedString *)description
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
            availableWidth:(CGFloat)availableWidth;

+ (UIView *)panelWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
           descriptionText:(NSString *)descriptionText
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
           instructionText:(NSString *)instructionText
            availableWidth:(CGFloat)availableWidth;

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        footerDescription:(NSAttributedString *)footerDescription
              messageIcon:(UIImage *)messageIcon
    messageIconTopPadding:(CGFloat)messageIconTopPadding
           availableWidth:(CGFloat)availableWidth;

+ (UIView *)panelWithMsgs:(NSArray *)msgs
                    title:(NSString *)title
               titleImage:(UIImage *)titleImage
              description:(NSAttributedString *)description
      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        footerDescription:(NSAttributedString *)footerDescription
          descriptionFont:(UIFont *)descriptionFont
              messageIcon:(UIImage *)messageIcon
    messageIconTopPadding:(CGFloat)messageIconTopPadding
           availableWidth:(CGFloat)availableWidth;

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                width:(CGFloat)width;

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                          description:(NSAttributedString *)description
                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView;

+ (UIView *)failuresPanelWithFailures:(NSArray *)failures
                                title:(NSString *)title
                          description:(NSAttributedString *)description
                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      descriptionFont:(UIFont *)descriptionFont
                       relativeToView:(UIView *)relativeToView;

+ (UIView *)mixedResultsPanelWithSuccessMsgs:(NSArray *)successMsgs
                                       title:(NSString *)title
                                 description:(NSAttributedString *)description
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         failuresDescription:(NSAttributedString *)failuresDescription
                                    failures:(NSArray *)failures
                              relativeToView:(UIView *)relativeToView;

+ (UIView *)leftPaddingMessageWithText:(NSString *)text
                        relativeToView:(UIView *)relativeToView;

+ (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText
                                  relativeToView:(UIView *)relativeToView;

+ (UIView *)leftPaddingMessageWithAttributedText:(NSAttributedString *)attrText
                        fontForHeightCalculation:(UIFont *)fontForHeightCalculation
                                  relativeToView:(UIView *)relativeToView;

+ (UIView *)thinHeadingPanelWithKey:(NSString *)text
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                     relativeToView:(UIView *)relativeToView;

+ (CGFloat)expandingInfoPanelHPadding;

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
                                relativeToView:(UIView *)relativeToView;

#pragma mark - Alert Section Makers

+ (JGActionSheetSection *)alertSectionWithTitle:(NSString *)title
                                     titleImage:(UIImage *)titleImage
                               alertDescription:(NSAttributedString *)alertDescription
                            descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                 relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)alertSectionWithMsgs:(NSArray *)msgs
                                         title:(NSString *)title
                                    titleImage:(UIImage *)titleImage
                              alertDescription:(NSAttributedString *)alertDescription
                           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)warningAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)successAlertSectionWithTitle:(NSString *)title
                                      alertDescription:(NSAttributedString *)alertDescription
                                   descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                        relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)offlineModeEnabledAlertSectionWithTitle:(NSString *)title
                                                 alertDescription:(NSAttributedString *)alertDescription
                                              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                   relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)recordSavedWhileUnauthAlertSectionWithTitle:(NSString *)title
                                                     alertDescription:(NSAttributedString *)alertDescription
                                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                       relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)recordSavedWhileBadAccountAlertSectionWithTitle:(NSString *)title
                                                         alertDescription:(NSAttributedString *)alertDescription
                                                      descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                                           relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                     relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)infoAlertSectionWithTitle:(NSString *)title
                               alertDescriptionText:(NSString *)alertDescriptionText
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    instructionText:(NSString *)instructionText
                                     relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)infoAlertSectionWithMsgs:(NSArray *)msgs
                                             title:(NSString *)title
                                  alertDescription:(NSAttributedString *)alertDescription
                               descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)successAlertSectionWithMsgs:(NSArray *)msgs
                                                title:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)waitAlertSectionWithMsgs:(NSArray *)msgs
                                             title:(NSString *)title
                                  alertDescription:(NSAttributedString *)alertDescription
                               descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)errorAlertSectionWithMsgs:(NSArray *)msgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                     relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)dangerAlertSectionWithTitle:(NSString *)title
                                     alertDescription:(NSAttributedString *)alertDescription
                                  descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                       relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)questionAlertSectionWithTitle:(NSString *)title
                                       alertDescription:(NSAttributedString *)alertDescription
                                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                         relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)multiErrorAlertSectionWithFailures:(NSArray *)failures
                                                       title:(NSString *)title
                                            alertDescription:(NSAttributedString *)alertDescription
                                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                              relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)mixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                                            title:(NSString *)title
                                                 alertDescription:(NSAttributedString *)alertDescription
                                              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                              failuresDescription:(NSAttributedString *)failuresDescription
                                                         failures:(NSArray *)failures
                                                   relativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)becameUnauthenticatedSectionRelativeToView:(UIView *)relativeToView;

+ (JGActionSheetSection *)receivedNotPermittedSectionRelativeToView:(UIView *)relativeToView;

#pragma mark - Showing Alert Helpers

+ (CGFloat)topInsetForAlertsWithController:(UIViewController *)controller;

+ (UIView *)parentViewForAlertsForController:(UIViewController *)controller;

#pragma mark - Showing Alerts

+ (void)showAlertWithButtonTitle:(NSString *)buttonTitle
                        topInset:(CGFloat)topInset
                    buttonAction:(void(^)(void))buttonAction
                 addlButtonTitle:(NSString *)addlButtonTitle
                addlButtonAction:(void(^)(void))addlButtonAction
                 addlButtonStyle:(JGActionSheetButtonStyle)addlButtonStyle
                  relativeToView:(UIView *)relativeToView
                 contentSections:(NSArray *)contentSections;

+ (void)showAlertWithTitle:(NSString *)title
                titleImage:(UIImage *)titleImage
          alertDescription:(NSAttributedString *)alertDescription
       descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                  topInset:(CGFloat)topInset
               buttonTitle:(NSString *)buttonTitle
              buttonAction:(void(^)(void))buttonAction
            relativeToView:(UIView *)relativeToView;

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
                   relativeToView:(UIView *)relativeToView;

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
                   relativeToView:(UIView *)relativeToView;

+ (void)showWarningConfirmAlertWithTitle:(NSString *)title
                        alertDescription:(NSAttributedString *)alertDescription
                     descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                topInset:(CGFloat)topInset
                         okayButtonTitle:(NSString *)buttonTitle
                        okayButtonAction:(void(^)(void))buttonAction
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                      cancelButtonAction:(void(^)(void))cancelButtonAction
                          relativeToView:(UIView *)relativeToView;

+ (void)showWarningConfirmAlertWithMsgs:(NSArray *)msgs
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                               topInset:(CGFloat)topInset
                        okayButtonTitle:(NSString *)buttonTitle
                       okayButtonAction:(void(^)(void))buttonAction
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                     cancelButtonAction:(void(^)(void))cancelButtonAction
                         relativeToView:(UIView *)relativeToView;

+ (void)showWarningAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView;

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
                  relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        additionalContentSections:(NSArray *)additionalContentSections
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithTitle:(NSString *)title
                 alertDescription:(NSAttributedString *)alertDescription
              descLblHeightAdjust:(CGFloat)descLblHeightAdjust
         additionalContentSection:(JGActionSheetSection *)additionalContentSection
                         topInset:(CGFloat)topInset
                      buttonTitle:(NSString *)buttonTitle
                     buttonAction:(void(^)(void))buttonAction
                   relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
       additionalContentSections:(NSArray *)additionalContentSections
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView;

+ (void)showSuccessAlertWithMsgs:(NSArray *)msgs
                           title:(NSString *)title
                alertDescription:(NSAttributedString *)alertDescription
             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
        additionalContentSection:(JGActionSheetSection *)additionalContentSection
                        topInset:(CGFloat)topInset
                     buttonTitle:(NSString *)buttonTitle
                    buttonAction:(void(^)(void))buttonAction
                  relativeToView:(UIView *)relativeToView;

+ (void)showOfflineModeEnabledAlertWithTitle:(NSString *)title
                            alertDescription:(NSAttributedString *)alertDescription
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    topInset:(CGFloat)topInset
                                 buttonTitle:(NSString *)buttonTitle
                                buttonAction:(void(^)(void))buttonAction
                              relativeToView:(UIView *)relativeToView;

+ (void)recordSavedWhileUnauthAlertWithTitle:(NSString *)title
                            alertDescription:(NSAttributedString *)alertDescription
                         descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                    topInset:(CGFloat)topInset
                                 buttonTitle:(NSString *)buttonTitle
                                buttonAction:(void(^)(void))buttonAction
                              relativeToView:(UIView *)relativeToView;

+ (void)recordSavedWhileBadAccountAlertWithTitle:(NSString *)title
                                alertDescription:(NSAttributedString *)alertDescription
                             descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                        topInset:(CGFloat)topInset
                                     buttonTitle:(NSString *)buttonTitle
                                    buttonAction:(void(^)(void))buttonAction
                                  relativeToView:(UIView *)relativeToView;

+ (void)showInfoAlertWithTitle:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
     additionalContentSections:(NSArray *)additionalContentSections
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView;

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
                relativeToView:(UIView *)relativeToView;

+ (void)showInstructionalAlertWithTitle:(NSString *)title
                   alertDescriptionText:(NSString *)alertDescriptionText
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                        instructionText:(NSString *)instructionText
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView;

+ (void)showWaitAlertWithMsgs:(NSArray *)msgs
                        title:(NSString *)title
             alertDescription:(NSAttributedString *)alertDescription
          descLblHeightAdjust:(CGFloat)descLblHeightAdjust
    additionalContentSections:(NSArray *)additionalContentSections
                     topInset:(CGFloat)topInset
                  buttonTitle:(NSString *)buttonTitle
                 buttonAction:(void(^)(void))buttonAction
               relativeToView:(UIView *)relativeToView;

+ (void)showErrorAlertWithMsgs:(NSArray *)msgs
                         title:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView;

+ (void)showErrorAlertWithMsgs:(NSArray *)msgs
                         title:(NSString *)title
              alertDescription:(NSAttributedString *)alertDescription
           descLblHeightAdjust:(CGFloat)descLblHeightAdjust
     additionalContentSections:(NSArray *)additionalContentSections
                      topInset:(CGFloat)topInset
                   buttonTitle:(NSString *)buttonTitle
                  buttonAction:(void(^)(void))buttonAction
                relativeToView:(UIView *)relativeToView;

+ (void)showMultiErrorAlertWithFailures:(NSArray *)failures
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView;

+ (void)showMultiErrorAlertWithFailures:(NSArray *)failures
                                  title:(NSString *)title
                       alertDescription:(NSAttributedString *)alertDescription
                    descLblHeightAdjust:(CGFloat)descLblHeightAdjust
               additionalContentSection:(JGActionSheetSection *)additionalContentSection
                               topInset:(CGFloat)topInset
                            buttonTitle:(NSString *)buttonTitle
                           buttonAction:(void(^)(void))buttonAction
                         relativeToView:(UIView *)relativeToView;

+ (void)showMixedResultsAlertSectionWithSuccessMsgs:(NSArray *)successMsgs
                                              title:(NSString *)title
                                   alertDescription:(NSAttributedString *)alertDescription
                                descLblHeightAdjust:(CGFloat)descLblHeightAdjust
                                failuresDescription:(NSAttributedString *)failuresDescription
                                           failures:(NSArray *)failures
                                           topInset:(CGFloat)topInset
                                        buttonTitle:(NSString *)buttonTitle
                                       buttonAction:(void(^)(void))buttonAction
                                     relativeToView:(UIView *)relativeToView;

+ (void)showAlertForNSURLErrorCode:(NSInteger)errorCode
                             title:(NSString *)title
                          topInset:(CGFloat)topInset
                       buttonTitle:(NSString *)buttonTitle
                      buttonAction:(void(^)(void))buttonAction
                    relativeToView:(UIView *)relativeToView;

@end
