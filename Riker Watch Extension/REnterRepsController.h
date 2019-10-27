//
//  REnterRepsController.h
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface REnterRepsController : WKInterfaceController <WKCrownDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *movementAndVariantLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *setsCompletedLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *nextSetNumberLabel;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *decrementWeightButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *weightLabelGroupContainer;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *weightLabelButton;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *weightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *weightUomLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *incrementWeightButton;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *decrementRepsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *repsLabelGroupContainer;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *repsLabelButton;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *repsLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *incrementRepsButton;

@property (weak, nonatomic) IBOutlet WKInterfaceSwitch *toFailureSwitch;
@property (weak, nonatomic) IBOutlet WKInterfaceSwitch *negativesSwitch;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *saveButton;

@property (weak, nonatomic) IBOutlet WKInterfaceSeparator *bodyLiftSeparator;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *bodyLiftLabel;

@end
