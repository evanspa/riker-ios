//
//  RSetsRowController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface RSetsRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *movementLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *movementVariantLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *repsAndWeightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *syncedLabel;

@end
