//
//  REntitySyncerController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/16/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
@import WatchConnectivity;

@interface REntitySyncerController : WKInterfaceController <WCSessionDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceImage *activityImage;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *label;

@end
