//
//  UIWindow+RAdditions.m
//  Riker
//
//  Created by PEVANS on 11/11/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import "UIWindow+RAdditions.h"

@implementation UIWindow (RAdditons)

- (UIViewController *)visibleViewController {
  UIViewController *rootViewController = self.rootViewController;
  return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
  if ([vc isKindOfClass:[UINavigationController class]]) {
    return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
  } else if ([vc isKindOfClass:[UITabBarController class]]) {
    return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
  } else {
    if (vc.presentedViewController) {
      return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
    } else {
      return vc;
    }
  }
}

@end
