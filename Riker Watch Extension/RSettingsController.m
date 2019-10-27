//
//  RSettingsController.m
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RSettingsController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"

@implementation RSettingsController

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  [_captureNegativesSwitch setOn:EXT.captureNegatives];
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *version = infoDictionary[@"CFBundleShortVersionString"];
  NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
  [_rikerVersion setText:[NSString stringWithFormat:@"%@  build: %@", version, build]];
}

- (IBAction)reloadMovementsAction {
  [self presentControllerWithName:@"LoadingiPhoneData" context:@"Re-loading data from iPhone..."];
}

- (IBAction)captureNegativesValueChanged:(BOOL)value {
  [EXT setCaptureNegatives:value];
  [EXT writeSettings];
}

@end



