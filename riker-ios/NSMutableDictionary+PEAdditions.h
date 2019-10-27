//
// NSMutableDictionary+PEAdditions.h
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (PEAdditions)

/**
 *  Adds object into the dictionary keyed under key, only if object is
 *  non-nil.  If object is nil, nothing is done.
 *  @param object The object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)setObjectIfNotNull:(id)object forKey:(id<NSCopying>)key;

/**
 *  Adds strValue into the dictionary keyed under key, only if strValue is
 *  non a blank string (whitespace only).  If strValue is blank, nothing is done.
 *  @param strValue The string object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)setStringIfNotBlank:(NSString *)strValue forKey:(id<NSCopying>)key;

/**
 *  Adds object into the dictionary keyed under key.  If object is nil, then
 *  [NSNull null] will be set as the object.
 *  @param object The object to add to the dictionary.
 *  @param key The key for the object.
 */
- (void)nullSafeSetObject:(id)object forKey:(id<NSCopying>)key;

/**
 *  Adds an NSNumber representing the number of milliseconds since 1970 that date represents,
 *  into the dictionary keyed under key, only if date is non-nil.  If date is nil,
 *  nothing is done.
 *  @param date The date object whose seconds-since-1970 representation to add to the
 *  dictionary.
 *  @param key The key for the object.
 */
- (void)setMillisecondsSince1970FromDate:(NSDate *)date forKey:(id<NSCopying>)key;

@end
