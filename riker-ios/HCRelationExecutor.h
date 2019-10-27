//
//  HCRelationExecutor.h
//

@import Foundation;
#import "HCDefs.h"
@protocol HCResourceSerializer;
@class HCCharset;
@class HCAuthorization;
@class HCAuthentication;
@class HCResource;
@class HCMediaType;

FOUNDATION_EXPORT NSString * const HTTP_DATE_FORMAT;

/**
 An abstraction for executing a link relation by issuing an HTTP GET, POST, PUT,
 DELETE, etc against the URI of the relation's target resource.
 */
@interface HCRelationExecutor : NSObject

#pragma mark - Initializers

/**
 Creates and initializes a new relation executor with the given parameters used
 to populate request headers when requests are made.
 @param acceptCharset the value to use for the "Accept-Charset" header when
 making requests
 @param acceptLanguage the value to use for the "Accept-Language" header when
 making requests
 @param contentTypeCharset the value to use for the "charset" parameter of the
 "Content-Type" header value when making requests that contain an entity (i.e.,
 HTTP POST and PUT)
 @return a new, initialized HCRelationExecutor instance
 */
- (id)initWithDefaultAcceptCharset:(HCCharset *)acceptCharset
             defaultAcceptLanguage:(NSString *)acceptLanguage
         defaultContentTypeCharset:(HCCharset *)contentTypeCharset
          allowInvalidCertificates:(BOOL)allowInvalidCertificates;

#pragma mark - Properties

/** The 'Accept-Charset' to use for HTTP requests. */
@property (nonatomic, readonly) HCCharset *acceptCharset;

/** The 'Accept-Language' to use for HTTP requests. */
@property (nonatomic, readonly) NSString *acceptLanguage;

/** Whether or not invalid SSL certificates should be allowed. */
@property (nonatomic, readonly) BOOL allowInvalidCertificates;

/**
 The charset to use within the 'Content-Type' header for HTTP POST/PUT requests.
 */
@property (nonatomic, readonly) HCCharset *contentTypeCharset;

#pragma mark - Helpers

/**
 Returns a date formatter for the given pattern.
 @param pattern The date pattern.
 @return A date formatter for the given pattern.
 */
+ (NSDateFormatter *)dateFormatterWithPattern:(NSString *)pattern;

/**
 Returns the value of the scheme within an WWW-Authenticate response header.
 @param authHeaderVal The full value of the WWW-Authenticate response header.
 @return The value of the scheme.
 */
+ (NSString *)schemeForAuthHeaderValue:(NSString *)authHeaderVal;

/**
 Returns the value of the realm within an WWW-Authenticate response header.
 @param authHeaderVal The full value of the WWW-Authenticate response header.
 @return The value of the realm.
 */
+ (NSString *)realmForAuthHeaderValue:(NSString *)authHeaderVal;

#pragma mark - Executors

- (void)doGetForURLString:(NSString *)URLString
               parameters:(NSDictionary *)parameters
          ifModifiedSince:(NSDate *)modifiedSince
         targetSerializer:(id<HCResourceSerializer>)targetSerializer
             asynchronous:(BOOL)asynchronous
          completionQueue:(dispatch_queue_t)completionQueue
            authorization:(HCAuthorization *)authorization
                  success:(HCGETSuccessBlk)success
              redirection:(HCRedirectionBlk)redirection
              clientError:(HCClientErrorBlk)clientErr
           forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
   authenticationRequired:(HCAuthReqdErrorBlk)authRequired
              serverError:(HCServerErrorBlk)serverErr
         unavailableError:(HCServerUnavailableBlk)unavailableErr
        connectionFailure:(HCConnFailureBlk)connFailure
                  timeout:(NSInteger)timeout
              cachePolicy:(NSURLRequestCachePolicy)cachePolicy
             otherHeaders:(NSDictionary *)otherHeaders;

- (void)doPostForURLString:(NSString *)URLString
        resourceModelParam:(id)resourceModelParam
           paramSerializer:(id<HCResourceSerializer>)paramSerializer
  responseEntitySerializer:(id<HCResourceSerializer>)responseEntitySerializer
              asynchronous:(BOOL)asynchronous
           completionQueue:(dispatch_queue_t)completionQueue
             authorization:(HCAuthorization *)authorization
                   success:(HCPOSTSuccessBlk)success
               redirection:(HCRedirectionBlk)redirection
               clientError:(HCClientErrorBlk)clientErr
            forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
    authenticationRequired:(HCAuthReqdErrorBlk)authRequired
               serverError:(HCServerErrorBlk)serverErr
          unavailableError:(HCServerUnavailableBlk)unavailableErr
         connectionFailure:(HCConnFailureBlk)connFailure
                   timeout:(NSInteger)timeout
              otherHeaders:(NSDictionary *)otherHeaders;

- (void)doPutForURLString:(NSString *)URLString
       resourceModelParam:(id)resourceModelParam
          paramSerializer:(id<HCResourceSerializer>)paramSerializer
             asynchronous:(BOOL)asynchronous
          completionQueue:(dispatch_queue_t)completionQueue
            authorization:(HCAuthorization *)authorization
                  success:(HCPUTSuccessBlk)success
              redirection:(HCRedirectionBlk)redirection
              clientError:(HCClientErrorBlk)clientErr
           forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
   authenticationRequired:(HCAuthReqdErrorBlk)authRequired
              serverError:(HCServerErrorBlk)serverErr
         unavailableError:(HCServerUnavailableBlk)unavailableErr
        connectionFailure:(HCConnFailureBlk)connFailure
                  timeout:(NSInteger)timeout
             otherHeaders:(NSDictionary *)otherHeaders;

- (void)doPutForURLString:(NSString *)URLString
        ifUnmodifiedSince:(NSDate *)unmodifiedSince
       resourceModelParam:(id)resourceModelParam
          paramSerializer:(id<HCResourceSerializer>)paramSerializer
             asynchronous:(BOOL)asynchronous
          completionQueue:(dispatch_queue_t)completionQueue
            authorization:(HCAuthorization *)authorization
                  success:(HCPUTSuccessBlk)success
              redirection:(HCRedirectionBlk)redirection
              clientError:(HCClientErrorBlk)clientErr
           forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
   authenticationRequired:(HCAuthReqdErrorBlk)authRequired
              serverError:(HCServerErrorBlk)serverErr
         unavailableError:(HCServerUnavailableBlk)unavailableErr
        connectionFailure:(HCConnFailureBlk)connFailure
                  timeout:(NSInteger)timeout
             otherHeaders:(NSDictionary *)otherHeaders;

- (void)doDeleteOfURLString:(NSString *)URLString
    wouldBeTargetSerializer:(id<HCResourceSerializer>)wouldBeTargetSerializer
               asynchronous:(BOOL)asynchronous
            completionQueue:(dispatch_queue_t)completionQueue
              authorization:(HCAuthorization *)authorization
                    success:(HCDELETESuccessBlk)success
                redirection:(HCRedirectionBlk)redirection
                clientError:(HCClientErrorBlk)clientErr
             forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
     authenticationRequired:(HCAuthReqdErrorBlk)authRequired
                serverError:(HCServerErrorBlk)serverErr
           unavailableError:(HCServerUnavailableBlk)unavailableErr
          connectionFailure:(HCConnFailureBlk)connFailure
                    timeout:(NSInteger)timeout
               otherHeaders:(NSDictionary *)otherHeaders;

- (void)doDeleteOfURLString:(NSString *)URLString
          ifUnmodifiedSince:(NSDate *)unmodifiedSince
    wouldBeTargetSerializer:(id<HCResourceSerializer>)wouldBeTargetSerializer
               asynchronous:(BOOL)asynchronous
            completionQueue:(dispatch_queue_t)completionQueue
              authorization:(HCAuthorization *)authorization
                    success:(HCDELETESuccessBlk)success
                redirection:(HCRedirectionBlk)redirection
                clientError:(HCClientErrorBlk)clientErr
             forbiddenError:(HCForbiddenErrorBlk)forbiddenErr
     authenticationRequired:(HCAuthReqdErrorBlk)authRequired
                serverError:(HCServerErrorBlk)serverErr
           unavailableError:(HCServerUnavailableBlk)unavailableErr
          connectionFailure:(HCConnFailureBlk)connFailure
                    timeout:(NSInteger)timeout
               otherHeaders:(NSDictionary *)otherHeaders;

@end
