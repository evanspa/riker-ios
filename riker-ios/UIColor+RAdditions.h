//
//  UIColor+RAdditions.h
//  riker-ios
//
//  Created by PEVANS on 10/27/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor (RAdditions)

- (NSString *)hexString;

+ (UIColor *)accessoryViewColor;
+ (UIColor *)rikerAppBlack;
+ (UIColor *)rikerAppBlackSemiClear;
+ (UIColor *)rikerAppBlackReallyClear;
+ (UIColor *)rikerAppBlackResultantNavbarColor;
+ (UIColor *)bootstrapPrimary;
+ (UIColor *)bootstrapPrimarySemiClear;
+ (UIColor *)failedPaymentHeadingTextColor;
+ (UIColor *)failedPaymentHeadingBgColor;
+ (UIColor *)cancelledAccountHeadingTextColor;
+ (UIColor *)cancelledAccountHeadingBgColor;
+ (UIColor *)goodStandingHeadingTextColor;
+ (UIColor *)goodStandingHeadingBgColor;
+ (UIColor *)trialAlmostExpiredHeadingTextColor;
+ (UIColor *)trialAlmostExpiredHeadingBgColor;
+ (UIColor *)upcomingMaintenanceBannerBgColor;
+ (UIColor *)maintenanceInProgressBannerBgColor;

+ (UIColor *)cochinealRed;
+ (UIColor *)cochinealRedSemiClear;

+ (UIColor *)greenBamboo;
+ (UIColor *)greenBambooSemiClear;

+ (UIColor *)noDataToChartBgColor;
+ (UIColor *)noDataToChartTextColor;

@end
