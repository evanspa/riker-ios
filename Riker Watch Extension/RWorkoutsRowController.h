//
//  RWorkoutsRowController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface RWorkoutsRowController : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dayOfWeekLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *caloriesLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *muscleGroup1;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *muscleGroup2;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *muscleGroup3;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *muscleGroup4;

@end
