//
//  UIView+PERoundify.h
//

@import Foundation;
@import UIKit;
@import QuartzCore;

/* http://stackoverflow.com/questions/4847163/round-two-corners-in-uiview */
@interface UIView (PERoundify)

-(void)addRoundedCorners:(UIRectCorner)corners
               withRadii:(CGSize)radii;

-(CALayer *)maskForRoundedCorners:(UIRectCorner)corners
                        withRadii:(CGSize)radii;

@end
