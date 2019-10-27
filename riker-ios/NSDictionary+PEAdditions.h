//
//  NSDictionary+PEAdditions.h
//

#import <Foundation/Foundation.h>

@interface NSDictionary (PEAdditions)

/**
 *  @key key The key into the dictionary containing the value.
 *  @return NSDate representation of the date value.
 */
- (NSDate *)dateSince1970ForKey:(NSString *)key;

/**
 * @return The BOOL value found in the dictionary for the given key; or NO
 * if no entry exists for the key.
 */
- (BOOL)boolForKey:(NSString *)key;

- (NSDecimalNumber *)decimalNumberForKey:(NSString *)key;

/**
 * @return The BOOL value found in the dictionary as an NSNumber; or nil
 * if no entry exists for the key.
 */
- (NSNumber *)numberFromBoolForKey:(NSString *)key;

/**
 * @return The BOOL value found in the dictionary for the given key; or defaultBool
 * if no entry exists for the key.
 */
- (BOOL)boolForKey:(NSString *)key defaultBool:(BOOL)defaultBool;

@end
