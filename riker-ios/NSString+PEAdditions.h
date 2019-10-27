//
// NSString+PEAdditions.h
//

#import <Foundation/Foundation.h>

@interface NSString (PEAdditions)

/**
 *  @returns YES if this string is only composed of whitespace.  Otherwise
 returns NO.
 */
- (BOOL)isBlank;

- (NSString *)nonBreaking;

@end
