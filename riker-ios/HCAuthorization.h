//
//  HCAuthorization.h
//

@import Foundation;

/**
 Represents the value to be set on the 'Authorization' header as defined by
 RFC2617.
 */
@interface HCAuthorization : NSObject

#pragma mark - Initializers

- (id)initWithAuthScheme:(NSString *)authScheme
              authParams:(NSDictionary *)authParams;

#pragma mark - Properties

@property (nonatomic, readonly) NSString *authScheme;

@property (nonatomic, readonly) NSDictionary *authParams;

#pragma mark - Equality

- (BOOL)isEqualToAuthorization:(HCAuthorization *)auth;

#pragma mark - Factory Functions

+ (HCAuthorization *)authWithScheme:(NSString *)authScheme
                singleAuthParamName:(NSString *)paramName
                     authParamValue:(NSString *)paramValue;

@end
