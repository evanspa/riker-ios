//
//  NSString+RAdditions.m
//  riker-ios
//
//  Created by PEVANS on 12/18/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "NSString+RAdditions.h"

@implementation NSString (RAdditions)

- (NSString *)sentenceCase {
  NSString *retVal;
  if (self.length < 2) {
    retVal = self.capitalizedString;
  } else {
    retVal = [NSString stringWithFormat:@"%@%@", [[self substringToIndex:1] uppercaseString], [[self substringFromIndex:1] lowercaseString]];
  }
  return retVal;
}

@end
