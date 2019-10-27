//
//  NSMutableArray+PEAdditions.m
//

#import "NSMutableArray+PEAdditions.h"

@implementation NSMutableArray (PEAdditions)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to {
  if (to != from) {
    id obj = [self objectAtIndex:from];
    [self removeObjectAtIndex:from];
    if (to >= [self count]) {
      [self addObject:obj];
    } else {
      [self insertObject:obj atIndex:to];
    }
  }
}

@end
