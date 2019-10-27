//
//  RBmlsRowController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface RBmlsRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *bmlTypeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *bodyWeightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *armSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *chestSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *calfSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *thighSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *forearmSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *waistSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *neckSizeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *syncedLabel;

@end
