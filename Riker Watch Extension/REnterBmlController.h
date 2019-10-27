//
//  REnterBmlController.h
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface REnterBmlController : WKInterfaceController <WKCrownDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *valueLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *uomLabel;

+ (void)updateSettingsIfBodyWeightBmlType:(NSMutableDictionary *)bml;

@end
