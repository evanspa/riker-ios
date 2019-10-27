//
//  REnterBmlController.m
//  riker-ios
//
//  Created by PEVANS on 5/8/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "REnterBmlController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RWatchUtils.h"
#import "NSString+RAdditions.h"

@implementation REnterBmlController {
  NSNumber *_bmlType;
  NSDecimalNumber *_value;
  NSNumberFormatter *_numberFormatter;
  NSInteger _rotationalScalingFactor;
  NSString *_titleText;
  NSNumber *_uomId;
  NSInteger _numFractionalDigits;
  NSString *_uomName;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *contextData = context;
  _bmlType = contextData[@"bml-type"];
  _titleText = contextData[@"title"];
  _uomId = contextData[@"uom-id"];
  [_titleLabel setText:_titleText];
  NSString *defaultValue = nil;
  NSDictionary *bmlsDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:BMLS_JSON_FILE_NAME];
  if (bmlsDict) {
    NSArray *bmls = bmlsDict[@"bmls"];
    NSInteger numBmls = bmls.count;
    NSString *bmlTypeKey = contextData[@"bml-type-key"];
    for (NSInteger i = 0; i < numBmls && !defaultValue; i++) {
      NSDictionary *bml = bmls[i];
      if (bml[bmlTypeKey]) {
        defaultValue = bml[@"value"];
      }
    }
  }
  if (!defaultValue) {
    defaultValue = contextData[@"default-value"];
  }
  if (defaultValue) {
    _value = [[NSDecimalNumber alloc] initWithString:defaultValue];
  } else {
    _value = [NSDecimalNumber zero];
  }
  [_valueLabel setText:_value.description];
  _uomName = context[@"uom-name"];
  [_uomLabel setText:_uomName];
  self.crownSequencer.delegate = self;
  _numberFormatter = [[NSNumberFormatter alloc] init];
  [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  _numFractionalDigits = ((NSNumber *)contextData[@"num-fraction-digits"]).integerValue;
  [_numberFormatter setMinimumFractionDigits:_numFractionalDigits];
  [_numberFormatter setMaximumFractionDigits:_numFractionalDigits];
  [_numberFormatter setRoundingMode:NSNumberFormatterRoundHalfUp];
  _rotationalScalingFactor = ((NSNumber *)contextData[@"rotational-scaling-factor"]).integerValue;
}

- (void)didAppear {
  [self.crownSequencer focus];
  if (EXT.canDismissEnterBmlScreen) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      EXT.canDismissEnterBmlScreen = NO;
      [self popController];
    });
  }
}

- (IBAction)save {
  if ([_value compare:[NSDecimalNumber zero]] == NSOrderedSame) {
    [self presentControllerWithName:@"Oops" context:[NSString stringWithFormat:@"%@ cannot be zero.", _titleText.lowercaseString.sentenceCase]];
  } else {
    _value = [_value decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                                       scale:_numFractionalDigits
                                                                                                            raiseOnExactness:NO
                                                                                                             raiseOnOverflow:NO
                                                                                                            raiseOnUnderflow:NO
                                                                                                         raiseOnDivideByZero:NO]];
    NSMutableDictionary *bml = [NSMutableDictionary dictionary];
    NSDate *now = [NSDate date];
    bml[@"logged-at"] = now;
    bml[@"value"] = _value;
    bml[@"uom-id"] = _uomId;
    bml[@"bml-type"] = _bmlType;
    bml[@"uuid"] = [[NSUUID UUID] UUIDString];
    NSString *entityType = @"bml";
    NSString *entityFileName = [RExtensionUtils saveToWatchEntity:bml entityType:entityType];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [REnterBmlController updateSettingsIfBodyWeightBmlType:bml];
      [RExtensionUtils extendBmlsWithLoggedAt:now
                                      bmlType:_bmlType.integerValue
                                        title:_titleText
                                        value:_value
                                     uomLabel:_uomName
                                     fileName:entityFileName];
    });
    [self presentControllerWithName:@"BmlSavedToWatch" context:nil];
  }
}

+ (void)updateSettingsIfBodyWeightBmlType:(NSMutableDictionary *)bml {
  NSNumber *bmlType = bml[@"bml-type"];
  NSNumber *value = bml[@"value"];
  if (bmlType.integerValue == RBmlTypeBodyWeight) {
    NSMutableDictionary *movementsAndSettings = EXT.movementsAndSettings;
    movementsAndSettings[@"body-weight"] = value;
    movementsAndSettings[@"body-weight-uom-name"] = movementsAndSettings[@"weight-uom-name"];
    movementsAndSettings[@"converted-body-weight"] = value;
    [RExtensionUtils saveDictionary:movementsAndSettings
      toDocumentsFolderWithFilename:MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME];
  }
}

#pragma mark - WKCrownDelegate protocol

- (void)crownDidRotate:(WKCrownSequencer *)crownSequencer
       rotationalDelta:(double)rotationalDelta {
  NSDecimalNumber *rotDeltaScaled = [[NSDecimalNumber alloc] initWithDouble:rotationalDelta * _rotationalScalingFactor];
  _value = [_value decimalNumberByAdding:rotDeltaScaled];
  if ([_value compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
    _value = [NSDecimalNumber zero];
  }
  [_valueLabel setText:[_numberFormatter stringFromNumber:_value]];
}

- (void)crownDidBecomeIdle:(WKCrownSequencer *)crownSequencer {}

@end



