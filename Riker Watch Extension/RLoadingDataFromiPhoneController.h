//
//  RLoadingDataFromiPhoneController.h
//  riker-ios
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
@import WatchConnectivity;

@interface RLoadingDataFromiPhoneController : WKInterfaceController <WCSessionDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceImage *activityImage;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end
