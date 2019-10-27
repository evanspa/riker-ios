//
//  PERestRemoteMasterDao.h
//

@import Foundation;

#import "PERemoteMasterDao.h"
#import "HCDefs.h"

@class HCMediaType;
@class HCCharset;
@class HCRelationExecutor;
@class HCRelation;
@class HCResource;
@class HCAuthorization;
@class PELMUserSerializer;
@class PEChangelogSerializer;
@class PELoginSerializer;
@class PELogoutSerializer;
@class PEResendVerificationEmailSerializer;
@class PEPasswordResetSerializer;
@class PELMStripeTokenSerializer;
@protocol HCResourceSerializer;

FOUNDATION_EXPORT NSString * const LAST_MODIFIED_HEADER;

@interface PERestRemoteMasterDao : NSObject <PERemoteMasterDao>

#pragma mark - Initializers

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
 establishSessionHeaderName:(NSString *)establishHeaderSessionName
        authTokenHeaderName:(NSString *)authTokenHeaderName
  ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(PELMUserSerializer *)userSerializer
        changelogSerializer:(PEChangelogSerializer *)changelogSerializer
            loginSerializer:(PELoginSerializer *)loginSerializer
           logoutSerializer:(PELogoutSerializer *)logoutSerializer
resendVerificationEmailSerializer:(PEResendVerificationEmailSerializer *)resendVerificationEmailSerializer
    passwordResetSerializer:(PEPasswordResetSerializer *)passwordResetSerializer
      stripeTokenSerializer:(PELMStripeTokenSerializer *)stripeTokenSerializer
   allowInvalidCertificates:(BOOL)allowInvalidCertificates
   clientFaultedErrorDomain:(NSString *)clientFaultedErrorDomain
     userFaultedErrorDomain:(NSString *)userFaultedErrorDomain
   systemFaultedErrorDomain:(NSString *)systemFaultedErrorDomain
     connFaultedErrorDomain:(NSString *)connFaultedErrorDomain
           restApiRelations:(NSDictionary *)restApiRelations;

#pragma mark - Properties

@property (nonatomic) NSString *authToken;

@property (nonatomic, readonly) NSDictionary *restApiRelations;

@property (nonatomic, readonly) HCRelationExecutor *relationExecutor;

@property (nonatomic, readonly) NSString *authScheme;

@property (nonatomic, readonly) NSString *authTokenParamName;

@property (nonatomic, readonly) NSString *errorMaskHeaderName;

@property (nonatomic, readonly) NSString *establishSessionHeaderName;

@property (nonatomic, readonly) NSString *authTokenHeaderName;

@property (nonatomic, readonly) NSString *ifModifiedSinceHeaderName;

@property (nonatomic, readonly) NSString *ifUnmodifiedSinceHeaderName;

@property (nonatomic, readonly) NSString *loginFailedReasonHeaderName;

@property (nonatomic, readonly) NSString *accountClosedReasonHeaderName;

@property (nonatomic, readonly) PELMUserSerializer *userSerializer;

@property (nonatomic, readonly) PEChangelogSerializer *changelogSerializer;

@property (nonatomic, readonly) PELoginSerializer *loginSerializer;

@property (nonatomic, readonly) PELogoutSerializer *logoutSerializer;

@property (nonatomic, readonly) PEResendVerificationEmailSerializer *resendVerificationEmailSerializer;

@property (nonatomic, readonly) PEPasswordResetSerializer *passwordResetSerializer;

@property (nonatomic, readonly) PELMStripeTokenSerializer *stripeTokenSerializer;

@property (nonatomic, readonly) dispatch_queue_t serialQueue;

@property (nonatomic, readonly) NSString *clientFaultedErrorDomain;

@property (nonatomic, readonly) NSString *userFaultedErrorDomain;

@property (nonatomic, readonly) NSString *systemFaultedErrorDomain;

@property (nonatomic, readonly) NSString *connFaultedErrorDomain;

#pragma mark - Helpers

- (NSDictionary *)addDateHeaderToHeaders:(NSDictionary *)headers
                              headerName:(NSString *)headerName
                                   value:(NSDate *)value;

- (NSDictionary *)addFpIfUnmodifiedSinceHeaderToHeader:(NSDictionary *)headers
                                                entity:(PELMMasterSupport *)entity;

+ (HCServerUnavailableBlk)serverUnavailableBlk:(PELMRemoteMasterBusyBlk)busyHandler;

+ (HCForbiddenErrorBlk)forbiddenBlk:(PELMRemoteMasterForbiddenBlk)handler;

+ (HCResource *)resourceFromModel:(PELMModelSupport *)model;

+ (HCAuthReqdErrorBlk)toHCAuthReqdBlk:(PELMRemoteMasterAuthReqdBlk)authReqdBlk;

- (HCClientErrorBlk)newClientErrBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCRedirectionBlk)newRedirectionBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCServerErrorBlk)newServerErrBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCConnFailureBlk)newConnFailureBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCGETSuccessBlk)newGetSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCPOSTSuccessBlk)newPostSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCDELETESuccessBlk)newDeleteSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCPUTSuccessBlk)newPutSuccessBlk:(PELMRemoteMasterCompletionHandler)complHandler;

- (HCAuthorization *)authorization;

- (void)doPostToURLString:(NSString *)URLString
       resourceModelParam:(id)resourceModelParam
               serializer:(id<HCResourceSerializer>)serializer
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler
             otherHeaders:(NSDictionary *)otherHeaders;

@end
