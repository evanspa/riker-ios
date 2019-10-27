//
//  REnterRepsController.m
//  riker-ios
//
//  Created by PEVANS on 5/2/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "REnterRepsController.h"
#import "RExtensionUtils.h"
#import "RExtensionDelegate.h"
#import "RWatchUtils.h"
#import "NSString+RAdditions.h"

@implementation REnterRepsController {
  NSDecimalNumber *_weight;
  NSDecimalNumber *_reps;
  NSInteger _incDecWeightAmount;
  NSNumber *_weightUomId;
  BOOL _toFailureOn;
  BOOL _negativesOn;
  NSTimer *_timer;
  BOOL _weightLabelFocus;
  BOOL _repsLabelFocus;
  NSNumberFormatter *_numberFormatter;
  NSDecimalNumberHandler *_numRepsRoundingBehavior;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *settings = EXT.movementsAndSettings;
  void (^checkTimeAndPreopulateUi)(void) = ^{
    EXT.setNumber = 1;
    NSDate *lastVisited = [EXT enterRepsScreenLastVisitedAt];
    if (lastVisited) {
      double minutesSinceLastVisited = [[NSDate date] timeIntervalSinceDate:lastVisited] / 60;
      if (minutesSinceLastVisited <= 15) { // pre-populate if we're within 15 minutes of last-visited
        _toFailureOn = [EXT enterRepsScreenLastToFailure];
        [_toFailureSwitch setOn:_toFailureOn];
        _negativesOn = [EXT enterRepsScreenLastNegatives];
        [_negativesSwitch setOn:_negativesOn];
        NSNumber *lastSetNumber = [EXT enterRepsScreenLastSetNumber];
        if (lastSetNumber) {
          EXT.setNumber = [lastSetNumber integerValue];
        }
        _weight = [EXT enterRepsScreenLastWeight];
        _reps = [EXT enterRepsScreenLastReps];
      }
    }
  };
  void (^defaultUi)(void) = ^{ EXT.setNumber = 1; };
  NSNumber *lastSelectedMovementId = [EXT lastSelectedMovementId];
  NSNumber *lastSelectedMovementVariantId = [EXT lastSelectedMovementVariantId];
  if (lastSelectedMovementId) {
    if ([lastSelectedMovementId isEqualToNumber:EXT.selectedMovementId]) {
      if (lastSelectedMovementVariantId == nil) {
        if (EXT.selectedMovementVariantId == nil) {
          checkTimeAndPreopulateUi();
        } else {
          defaultUi();
        }
      } else if (EXT.selectedMovementVariantId && [lastSelectedMovementVariantId isEqualToNumber:EXT.selectedMovementVariantId]) {
        checkTimeAndPreopulateUi();
      } else {
        defaultUi();
      }
    } else {
      defaultUi();
    }
  } else {
    defaultUi();
  }
  
  [_negativesSwitch setHidden:!EXT.captureNegatives];
  if (EXT.selectedMovementVariantId) {
    [_movementAndVariantLabel setText:[NSString stringWithFormat:@"%@ - %@", EXT.selectedMovementName, EXT.selectedMovementVariantName]];
  } else {
    [_movementAndVariantLabel setText:[NSString stringWithFormat:@"%@", EXT.selectedMovementName]];
  }
  _incDecWeightAmount = ((NSNumber *)settings[@"inc-dec-weight-amount"]).integerValue;
  if (_incDecWeightAmount == 0) {
    _incDecWeightAmount = 5;
  }
  [_decrementWeightButton setTitle:[NSString stringWithFormat:@"-%ld", (long)_incDecWeightAmount]];
  _weightUomId = settings[@"weight-uom-id"];
  [_weightUomLabel setText:settings[@"weight-uom-name"]];
  [_incrementWeightButton setTitle:[NSString stringWithFormat:@"+%ld", (long)_incDecWeightAmount]];
  if (!_weight) {
    _weight = [NSDecimalNumber zero];
  }
  if (!_reps) {
    _reps = [NSDecimalNumber zero];
  }
  BOOL isBodyLift = NO;
  if (EXT.selectedMovementVariantId.integerValue == BODY_MOVEMENT_VARIANT_ID) {
    isBodyLift = YES;
  } else if (EXT.selectedMovementIsBodyLift && EXT.selectedMovementVariantId == nil) {
    isBodyLift = YES;
  }
  if (isBodyLift) {
    NSDecimalNumber *selectedMovementPercentageOfBodyWeight;
    if (EXT.selectedMovementPercentageOfBodyWeight) {
      selectedMovementPercentageOfBodyWeight = EXT.selectedMovementPercentageOfBodyWeight;
      if ([selectedMovementPercentageOfBodyWeight isKindOfClass:[NSNumber class]]) {
        selectedMovementPercentageOfBodyWeight = [[NSDecimalNumber alloc] initWithFloat:selectedMovementPercentageOfBodyWeight.floatValue];
        selectedMovementPercentageOfBodyWeight =
        [selectedMovementPercentageOfBodyWeight decimalNumberByRoundingAccordingToBehavior:
         [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                scale:2
                                                     raiseOnExactness:NO
                                                      raiseOnOverflow:NO
                                                     raiseOnUnderflow:NO
                                                  raiseOnDivideByZero:NO]];
      }
    } else {
      selectedMovementPercentageOfBodyWeight = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    }
    NSNumber *bodyWeight = settings[@"converted-body-weight"];
    if (bodyWeight) {
      if ([bodyWeight isKindOfClass:[NSDecimalNumber class]]) {
        _weight = (NSDecimalNumber *)bodyWeight;
      } else {
        _weight = [[NSDecimalNumber alloc] initWithInteger:bodyWeight.integerValue];
      }
      _weight =
      [[_weight decimalNumberByMultiplyingBy:selectedMovementPercentageOfBodyWeight] decimalNumberByRoundingAccordingToBehavior:
       [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                              scale:0
                                                   raiseOnExactness:NO
                                                    raiseOnOverflow:NO
                                                   raiseOnUnderflow:NO
                                                raiseOnDivideByZero:NO]];
      NSDate *dateSuppressed = [EXT suppressedWeightDefaultedToBodyWeightPopupAt];
      NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
      [dateComponents setMonth:4];
      NSCalendar *calendar = [NSCalendar currentCalendar];
      NSDate *dateSuppressedPlusSomeTime = nil;
      if (dateSuppressed) {
        dateSuppressedPlusSomeTime = [calendar dateByAddingComponents:dateComponents toDate:dateSuppressed options:0];
      }
      if (dateSuppressed == nil || [dateSuppressedPlusSomeTime compare:[NSDate date]] == NSOrderedAscending) {
        [self presentControllerWithName:@"AboutWeightDefaultedToBodyWeightPopup"
                                context:@{@"body-weight": settings[@"body-weight"],
                                          @"body-weight-uom-name": settings[@"body-weight-uom-name"],
                                          @"movement-name": EXT.selectedMovementName,
                                          @"percentage": selectedMovementPercentageOfBodyWeight,
                                          @"weight": _weight,
                                          @"weight-uom-name": settings[@"weight-uom-name"]}];
      }
    }
    [_bodyLiftLabel setText:[NSString stringWithFormat:@"%@ is a body-lift movement estimated to use %@%% of your body weight.",
                             EXT.selectedMovementName.sentenceCase, [[selectedMovementPercentageOfBodyWeight decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] description]]];
  } else {
    [_bodyLiftSeparator setHidden:YES];
    [_bodyLiftLabel setHidden:YES];
  }
  _numberFormatter = [[NSNumberFormatter alloc] init];
  [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [_numberFormatter setMinimumFractionDigits:0];
  [_numberFormatter setMaximumFractionDigits:0];
  [self bindRepsToUi];
  [self bindWeightToUi];
  [_weightLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
  _weightLabelFocus = NO;
  [_repsLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
  _repsLabelFocus = NO;
  self.crownSequencer.delegate = self;
  _numRepsRoundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                    scale:0
                                                                         raiseOnExactness:NO
                                                                          raiseOnOverflow:NO
                                                                         raiseOnUnderflow:NO
                                                                      raiseOnDivideByZero:NO];
}

- (void)willActivate {
  if (EXT.setNumber == 1) {
    [_setsCompletedLabel setText:@"-"];
  } else {
    [_setsCompletedLabel setText:[NSString stringWithFormat:@"%ld", (long)EXT.setNumber - 1]];
  }
  [_nextSetNumberLabel setText:[NSString stringWithFormat:@"%ld", (long)EXT.setNumber]];
}

- (void)willDisappear {
  [self persistScreenStateToSettings];
}

- (void)persistScreenStateToSettings {
  [EXT setLastSelectedMovementId:EXT.selectedMovementId];
  [EXT setLastSelectedMovementName:EXT.selectedMovementName];
  [EXT setLastSelectedMovementVariantId:EXT.selectedMovementVariantId];
  [EXT setLastSelectedMovementVariantName:EXT.selectedMovementVariantName];
  NSNumber *nowTime = [RExtensionUtils unixTimeFromDate:[NSDate date]];
  [EXT setEnterRepsScreenLastVisitedAtTime:nowTime];
  [EXT setEnterRepsScreenLastSetNumber:@(EXT.setNumber)];
  [EXT setEnterRepsScreenLastWeight:_weight];
  [EXT setEnterRepsScreenLastReps:_reps];
  [EXT setEnterRepsScreenLastToFailure:_toFailureOn];
  [EXT setEnterRepsScreenLastNegatives:_negativesOn];
  [EXT writeSettings];
}

- (void)bindRepsToUi {
  [_repsLabel setText:[_numberFormatter stringFromNumber:_reps]];
}

- (void)bindWeightToUi {
  [_weightLabel setText:[_numberFormatter stringFromNumber:_weight]];
}

- (void)longTapHandlerWithGestureRecognizer:(WKGestureRecognizer *)gestureRecognizer timerActionSelector:(SEL)timerActionSelector {
  WKGestureRecognizerState gestureRecoginizerState = gestureRecognizer.state;
  switch (gestureRecoginizerState) {
    case WKGestureRecognizerStatePossible:
    case WKGestureRecognizerStateRecognized:
    case WKGestureRecognizerStateChanged:
      // to get rid of compiler warning
      break;
    case WKGestureRecognizerStateBegan: {
      _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:timerActionSelector userInfo:nil repeats:YES];
      break;
    }
    case WKGestureRecognizerStateEnded:
    case WKGestureRecognizerStateCancelled:
    case WKGestureRecognizerStateFailed:
      [_timer invalidate];
      break;
  }
}

#pragma mark - IB actions

- (IBAction)handleDecrementWeightLongTapGesture:(WKGestureRecognizer*)gestureRecognizer {
  [self longTapHandlerWithGestureRecognizer:gestureRecognizer timerActionSelector:@selector(decrementWeight)];
}

- (IBAction)handleIncrementWeightLongTapGesture:(WKGestureRecognizer*)gestureRecognizer {
  [self longTapHandlerWithGestureRecognizer:gestureRecognizer timerActionSelector:@selector(incrementWeight)];
}

- (IBAction)handleDecrementRepsLongTapGesture:(WKGestureRecognizer*)gestureRecognizer {
  [self longTapHandlerWithGestureRecognizer:gestureRecognizer timerActionSelector:@selector(decrementReps)];
}

- (IBAction)handleIncrementRepsLongTapGesture:(WKGestureRecognizer*)gestureRecognizer {
  [self longTapHandlerWithGestureRecognizer:gestureRecognizer timerActionSelector:@selector(incrementReps)];
}

- (IBAction)decrementWeight {
  _weight = [_weight decimalNumberBySubtracting:[[NSDecimalNumber alloc] initWithInteger:_incDecWeightAmount]];
  if ([_weight compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
    _weight = [NSDecimalNumber zero];
  }
  [self bindWeightToUi];
}

- (IBAction)incrementWeight {
  _weight = [_weight decimalNumberByAdding:[[NSDecimalNumber alloc] initWithInteger:_incDecWeightAmount]];
  [self bindWeightToUi];
}

- (IBAction)decrementReps {
  _reps = [_reps decimalNumberBySubtracting:[NSDecimalNumber one]];
  if ([_reps compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
    _reps = [NSDecimalNumber zero];
  }
  [self bindRepsToUi];
}

- (IBAction)incrementReps {
  _reps = [_reps decimalNumberByAdding:[NSDecimalNumber one]];
  [self bindRepsToUi];
}

- (IBAction)toFailureValueChanged:(BOOL)value {
  _toFailureOn = value;
}

- (IBAction)negativesValueChanged:(BOOL)value {
  _negativesOn = value;
}

- (IBAction)weightLabelButtonTapped {
  _repsLabelFocus = NO;
  [_repsLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
  _weightLabelFocus = !_weightLabelFocus;
  if (_weightLabelFocus) {
    [_weightLabelGroupContainer setBackgroundColor:[UIColor greenColor]];
    [self.crownSequencer focus];
  } else {
    [_weightLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
    [self.crownSequencer resignFocus];
  }
}

- (IBAction)repsLabelButtonTapped {
  _weightLabelFocus = NO;
  [_weightLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
  _repsLabelFocus = !_repsLabelFocus;
  if (_repsLabelFocus) {
    [_repsLabelGroupContainer setBackgroundColor:[UIColor greenColor]];
    [self.crownSequencer focus];
  } else {
    [_repsLabelGroupContainer setBackgroundColor:[UIColor blackColor]];
    [self.crownSequencer resignFocus];
  }
}

- (IBAction)save {
  NSString *oopsMessage = nil;
  BOOL isWeightZero = [_weight compare:[NSDecimalNumber zero]] == NSOrderedSame;
  BOOL isRepsZero = [_reps compare:[NSDecimalNumber zero]] == NSOrderedSame;
  if (isRepsZero) {
    if (isWeightZero) {
        oopsMessage = @"Weight and reps cannot be zero.";
    } else {
      oopsMessage = @"Reps cannot be zero.";
    }
  } else if (isWeightZero) {
    oopsMessage = @"Weight cannot be zero.";
  }
  if (oopsMessage) {
    [self presentControllerWithName:@"Oops" context:oopsMessage];
  } else {
    NSMutableDictionary *set = [NSMutableDictionary dictionary];
    set[@"movement-id"] = EXT.selectedMovementId;
    if (EXT.selectedMovementVariantId) {
      set[@"variant-id"] = EXT.selectedMovementVariantId;
    }
    NSInteger repsInt = [self repsToInt];
    NSDecimalNumber *cleansedWeight = [self weightToCleansedBigDecimal];
    NSDate *loggedAt = [NSDate date];
    set[@"logged-at"] = loggedAt;
    set[@"reps"] = @(repsInt);
    set[@"weight"] = cleansedWeight;
    set[@"weight-uom-id"] = _weightUomId;
    set[@"to-failure"] = @(_toFailureOn);
    set[@"negatives"] = @(_negativesOn);
    set[@"uuid"] = [[NSUUID UUID] UUIDString];
    NSString *entityType = @"set";
    NSString *entityFileName = [RExtensionUtils saveToWatchEntity:set entityType:entityType];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [RExtensionUtils extendSetsTimelineWithLoggedAt:loggedAt
                                         movementName:EXT.selectedMovementName
                                  movementVariantName:EXT.selectedMovementVariantName
                                              numReps:repsInt
                                               weight:cleansedWeight
                                        weightUomName:EXT.movementsAndSettings[@"weight-uom-name"]
                                            toFailure:_toFailureOn
                                            negatives:_negativesOn
                                             fileName:entityFileName];
    });
    [self presentControllerWithName:@"SetSavedToWatch" context:nil];
  }
}

#pragma mark - WKCrownDelegate protocol

- (void)crownDidRotate:(WKCrownSequencer *)crownSequencer
       rotationalDelta:(double)rotationalDelta {
  NSDecimalNumber *rotDeltaScaled = [[NSDecimalNumber alloc] initWithDouble:rotationalDelta * 40];
  if (_weightLabelFocus) {
    _weight = [_weight decimalNumberByAdding:rotDeltaScaled];
    if ([_weight compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
      _weight = [NSDecimalNumber zero];
    }
    [self bindWeightToUi];
  } else {
    _reps = [_reps decimalNumberByAdding:rotDeltaScaled];
    if ([_reps compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
      _reps = [NSDecimalNumber zero];
    }
    [self bindRepsToUi];
  }
}

- (void)crownDidBecomeIdle:(WKCrownSequencer *)crownSequencer {}

#pragma mark - Helpers

- (NSInteger)repsToInt {
  return  [[NSDecimalNumber decimalNumberWithString:[_numberFormatter stringFromNumber:_reps]] integerValue];
}

- (NSDecimalNumber *)weightToCleansedBigDecimal {
  return [NSDecimalNumber decimalNumberWithString:[_numberFormatter stringFromNumber:_weight]];
}

@end



