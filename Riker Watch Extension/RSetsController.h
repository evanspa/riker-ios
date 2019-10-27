//
//  RSetsController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/19/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface RSetsController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *noSetsFoundGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *setsTable;

@end
