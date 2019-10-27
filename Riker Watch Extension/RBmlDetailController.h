//
//  RBmlDetailController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/22/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface RBmlDetailController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *bmlTypeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *labelsContainer;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *bodyWeightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *armSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *chestSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *calfSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *thighSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *forearmSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *waistSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *neckSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *syncedLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *deleteButton;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *editOrDeleteLabel;

@end
