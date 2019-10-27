//
//  RSettingsController.h
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface RSettingsController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceSwitch *captureNegativesSwitch;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *rikerVersion;

@end
