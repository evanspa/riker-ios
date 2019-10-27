//
//  RBmlsController.h
//  Riker Watch Extension
//
//  Created by PEVANS on 10/20/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface RBmlsController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *noBmlsFoundGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *bmlsTable;

@end
