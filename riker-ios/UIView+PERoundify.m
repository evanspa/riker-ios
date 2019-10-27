//
//  UIView+PERoundify.m
//

#import "UIView+PERoundify.h"

@implementation UIView (PERoundify)

-(void)addRoundedCorners:(UIRectCorner)corners withRadii:(CGSize)radii {
  CALayer *tMaskLayer = [self maskForRoundedCorners:corners withRadii:radii];
  self.layer.mask = tMaskLayer;
}

-(CALayer*)maskForRoundedCorners:(UIRectCorner)corners withRadii:(CGSize)radii {
  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  maskLayer.frame = self.bounds;
  UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:
                               maskLayer.bounds byRoundingCorners:corners cornerRadii:radii];
  maskLayer.fillColor = [[UIColor whiteColor] CGColor];
  maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
  maskLayer.path = [roundedPath CGPath];
  return maskLayer;
}

@end
