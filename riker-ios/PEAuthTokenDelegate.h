//
// PEAuthTokenDelegate.h
//

@import Foundation;

@class HCAuthentication;

@protocol PEAuthTokenDelegate <NSObject>

- (void)didReceiveNewAuthToken:(NSString *)authToken
       forUserGlobalIdentifier:(NSString *)userGlobalIdentifier;

- (void)authRequired:(HCAuthentication *)authentication;

@end
