//
//  UIColor+RAdditions.m
//  riker-ios
//
//  Created by PEVANS on 10/27/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "UIColor+RAdditions.h"

@implementation UIColor (RAdditions)

- (NSString *)hexString {
  const CGFloat *components = CGColorGetComponents(self.CGColor);
  CGFloat r = components[0];
  CGFloat g = components[1];
  CGFloat b = components[2];  
  return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
          lroundf(r * 255),
          lroundf(g * 255),
          lroundf(b * 255)];
}

+ (UIColor *)accessoryViewColor {
  return [UIColor colorWithRed:(0xC7 / 255.0)
                         green:(0xC7 / 255.0)
                          blue:(0xC7 / 255.0)
                         alpha:1.0];
}

+ (UIColor *)rikerAppBlack {
  return [UIColor colorWithRed:(0x3F / 255.0)
                         green:(0x49 / 255.0)
                          blue:(0x52 / 255.0)
                         alpha:1.0];
}

+ (UIColor *)rikerAppBlackSemiClear {
  return [UIColor colorWithRed:(0x3F / 255.0)
                         green:(0x49 / 255.0)
                          blue:(0x52 / 255.0)
                         alpha:0.5];
}

+ (UIColor *)rikerAppBlackReallyClear {
  return [UIColor colorWithRed:(0x3F / 255.0)
                         green:(0x49 / 255.0)
                          blue:(0x52 / 255.0)
                         alpha:0.25];
}

+ (UIColor *)rikerAppBlackResultantNavbarColor {
  return [UIColor colorWithRed:(0x59 / 255.0)
                         green:(0x62 / 255.0)
                          blue:(0x6A / 255.0)
                         alpha:1.0];
}

+ (UIColor *)bootstrapPrimary {
  return [UIColor colorWithRed:(0x33 / 255.0)
                         green:(0x7A / 255.0)
                          blue:(0xB7 / 255.0)
                         alpha:1.0];
}

+ (UIColor *)bootstrapPrimarySemiClear {
  return [UIColor colorWithRed:(0x33 / 255.0)
                         green:(0x7A / 255.0)
                          blue:(0xB7 / 255.0)
                         alpha:0.5];
}

+ (UIColor *)failedPaymentHeadingTextColor {
  return [UIColor colorWithRed:(0xB2 / 255.0)
                         green:(0x4D / 255.0)
                          blue:(0x4B / 255.0)
                         alpha:1.0];
}

+ (UIColor *)failedPaymentHeadingBgColor {
  return [UIColor colorWithRed:(0xF1 / 255.0)
                         green:(0xD9 / 255.0)
                          blue:(0xDA / 255.0)
                         alpha:1.0];
}

+ (UIColor *)cancelledAccountHeadingTextColor {
  return [UIColor colorWithRed:(0xB2 / 255.0)
                         green:(0x4D / 255.0)
                          blue:(0x4B / 255.0)
                         alpha:1.0];
}

+ (UIColor *)cancelledAccountHeadingBgColor {
  return [UIColor colorWithRed:(0xF1 / 255.0)
                         green:(0xD9 / 255.0)
                          blue:(0xDA / 255.0)
                         alpha:1.0];
}

+ (UIColor *)goodStandingHeadingTextColor {
  return [UIColor colorWithRed:(0x3A / 255.0)
                         green:(0x77 / 255.0)
                          blue:(0x3A / 255.0)
                         alpha:1.0];
}

+ (UIColor *)goodStandingHeadingBgColor {
  return [UIColor colorWithRed:(0xD5 / 255.0)
                         green:(0xED / 255.0)
                          blue:(0xCC / 255.0)
                         alpha:1.0];
}

+ (UIColor *)trialAlmostExpiredHeadingTextColor {
  return [UIColor colorWithRed:(0x8A / 255.0)
                         green:(0x6D / 255.0)
                          blue:(0x37 / 255.0)
                         alpha:1.0];
}

+ (UIColor *)trialAlmostExpiredHeadingBgColor {
  return [UIColor colorWithRed:(0xFC / 255.0)
                         green:(0xF7 / 255.0)
                          blue:(0xDE / 255.0)
                         alpha:1.0];
}

+ (UIColor *)upcomingMaintenanceBannerBgColor {
  return [UIColor colorWithRed:(0x2D / 255.0)
                         green:(0x97 / 255.0)
                          blue:(0xDE / 255.0)
                         alpha:1.0];
}

+ (UIColor *)maintenanceInProgressBannerBgColor {
  return [UIColor colorWithRed:(0xED / 255.0)
                         green:(0x9E / 255.0)
                          blue:(0x16 / 255.0)
                         alpha:1.0];
}

+ (UIColor *)cochinealRed {
  return [UIColor colorWithRed:157/255.0 green:41/255.0 blue:51/255.0 alpha:1.0];
}

+ (UIColor *)cochinealRedSemiClear {
  return [UIColor colorWithRed:157/255.0 green:41/255.0 blue:51/255.0 alpha:0.5];
}

+ (UIColor *)greenBamboo {
  return [UIColor colorWithRed:0/255.0 green:100/255.0 blue:66/255.0 alpha:1.0];
}

+ (UIColor *)greenBambooSemiClear {
  return [UIColor colorWithRed:0/255.0 green:100/255.0 blue:66/255.0 alpha:0.5];
}

+ (UIColor *)noDataToChartBgColor {
  return [UIColor colorWithRed:0xE3/255.0 green:0xE5/255.0 blue:0xEC/255.0 alpha:1.0];
}

+ (UIColor *)noDataToChartTextColor {
  return [UIColor colorWithRed:0x97/255.0 green:0x99/255.0 blue:0xA0/255.0 alpha:1.0];
}

@end
