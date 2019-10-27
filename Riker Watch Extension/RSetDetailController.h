//
//  RSetDetailController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface RSetDetailController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *movementLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *movementVariantLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *repsAndWeightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *syncedLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *toFailureLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *negativesLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *deleteButton;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *editOrDeleteLabel;

@end
