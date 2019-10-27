//
//  NSDate+RAdditions.m
//  Riker
//
//  Created by PEVANS on 10/16/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "NSDate+RAdditions.h"

@implementation NSDate(RAdditions)

- (NSDecimalNumber *)toUnixTime {
  NSDecimalNumber *dateNum = [[NSDecimalNumber alloc] initWithDouble:self.timeIntervalSince1970];
  dateNum = [dateNum decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithInteger:1000]];
  dateNum = [dateNum decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                                       scale:0
                                                                                                            raiseOnExactness:NO
                                                                                                             raiseOnOverflow:NO
                                                                                                            raiseOnUnderflow:NO                                                                                                         raiseOnDivideByZero:NO]];
  return dateNum;
}

@end
