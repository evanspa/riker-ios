//
//  HCCharset.h
//

@import Foundation;

/**
 Abstraction that represents a charset.
 */
@interface HCCharset : NSObject

#pragma mark - Initializers

- (id)initWithEncoding:(NSStringEncoding)encoding
           description:(NSString *)description;

#pragma mark - Properties

@property (nonatomic, readonly) NSStringEncoding encoding;

#pragma mark - Equality

- (BOOL)isEqualToCharset:(HCCharset *)charset;

#pragma mark - Class methods

/**
 @return a character set instance representing UTF-8
 */
+ (HCCharset *)UTF8;

/**
 @return a character set instance representing ISO Latin-1
 */
+ (HCCharset *)Latin1;

@end
