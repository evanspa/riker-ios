//
//  HCMediaType.h
//

@import Foundation;

/**
 A simple abstraction that models an internet media type.  A media type, from
 RFC 2616, consists of a type and a subtype (including optional parameters).
 */
@interface HCMediaType : NSObject

#pragma mark - Initializers

/**
 Creates and returns a media type with the given type and subtype tokens.
 @param type The major type.
 @param subType The subtype.
 @return a media type instnace
 */
- (id)initWithType:(NSString *)type subType:(NSString *)subType;

/**
 Creates and returns a media type with the given type, subtype, version and
 preferred-format tokens.
 @param type The major type
 @param subType The subtype
 @param version The version.
 @param format The preferred format (e.g., JSON).
 @return a media type instnace
 */
- (id)initWithType:(NSString *)type
           subType:(NSString *)subType
           version:(NSString *)version
            format:(NSString *)format;

#pragma mark - Factory Functions

/**
 Convenience function that creates a media type from a string of the form:
 'type/subtype'
 @param mediaTypeStr string-representation of a media type of the form:
 type/subtype
 @return a media type instance
 */
+ (HCMediaType *)MediaTypeFromString:(NSString *)mediaTypeStr;

#pragma mark - Equality

/**
 @param mediaType the media type with which to compare the receiving media type
 @return a Boolean value that indicates whether the receiving media type is
 equal to the given media type.
 */
- (BOOL)isEqualToMediaType:(HCMediaType *)mediaType;

#pragma mark - Properties

/**
 The type of the media type.
 */
@property (nonatomic, readonly) NSString *type;

/**
 The subtype of the media type.
 */
@property (nonatomic, readonly) NSString *subType;

/**
 The version of the media type.
 */
@property (nonatomic, readonly) NSString *version;

/**
 The preferred format of the media type.
 */
@property (nonatomic, readonly) NSString *format;

@end
