//
//  UIScrollView+PEAdditions.m
//

#import "UIScrollView+PEAdditions.h"

@implementation UIScrollView (PEAdditions)

- (BOOL)isAtTop {
  return (self.contentOffset.y <= [self verticalOffsetForTop]);
}

- (BOOL)isAtBottom {
  return (self.contentOffset.y >= [self verticalOffsetForBottom]);
}

- (CGFloat)verticalOffsetForTop {
  CGFloat topInset = self.contentInset.top;
  return -topInset;
}

- (CGFloat)verticalOffsetForBottom {
  CGFloat scrollViewHeight = self.bounds.size.height;
  CGFloat scrollContentSizeHeight = self.contentSize.height;
  CGFloat bottomInset = self.contentInset.bottom;
  CGFloat scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight;
  return scrollViewBottomOffset;
}

@end
