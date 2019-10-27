//
//  RMainMenuController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface RMainMenuController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceButton *strengthTrainButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *bodyLogButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *syncSetsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *syncBmlsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceSeparator *separator1;
@property (weak, nonatomic) IBOutlet WKInterfaceSeparator *separator2;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *workoutsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *setsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *bmlsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *settingsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceSeparator *separator4;

@end
