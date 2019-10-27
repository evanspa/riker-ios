//
//  HCAuthentication.h
//

#import "HCAuthorization.h"

@interface HCAuthentication : HCAuthorization

#pragma mark - Initializers

- (id)initWithAuthScheme:(NSString *)authScheme
                   realm:(NSString *)realm
              authParams:(NSDictionary *)authParams;

#pragma mark - Properties

@property (nonatomic, readonly) NSString *realm;

#pragma mark - Equality

- (BOOL)isEqualToAuthentication:(HCAuthentication *)auth;

#pragma mark - Factory Functions

+ (HCAuthentication *)authWithScheme:(NSString *)authScheme
                               realm:(NSString *)realm;

+ (HCAuthentication *)authWithScheme:(NSString *)authScheme;

@end
