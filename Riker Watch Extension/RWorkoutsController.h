//
//  RWorkoutsController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface RWorkoutsController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *noWorkoutsFoundGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *workoutsTable;

@end
