//
//  HCAFURLRequestSerializer.h
//

@import Foundation;
#import <AFNetworking/AFURLRequestSerialization.h>

@class HCAuthorization;
@class HCCharset;
@class HCMediaType;
@protocol HCResourceSerializer;

/**
 An implementation of AFNetworking's request serializer that would leverage an
 HC resource serializer.
*/
@interface HCAFURLRequestSerializer : AFHTTPRequestSerializer

#pragma mark - Initializers

/**
 Creates and returns a serializer to be used for requests that contain an entity
 body (i.e., HTTP POST and PUT).
 @param accept the media type to use for the Accept header
 @param acceptCharset the charset to use for the Accept-Charset header
 @param acceptLang the language to use for the Accept-Language header
 @param hcserializer the serializer to use to serialize a resource model when
        issuing the HTTP POST or PUT.
 @param timeout The amount of time in seconds to wait for the request to
 @param cachePolicy The cache policy to use for requests.
 @param otherHeaders Additional headers to include in the request.
 complete.
 @return an AFNetworking-compliant request serializer appropriate for HTTP POST
         and PUT requests.
 */
- (id)initWithAccept:(HCMediaType *)accept
       acceptCharset:(HCCharset *)acceptCharset
      acceptLanguage:(NSString *)acceptLang
       authorization:(HCAuthorization *)authorization
        hcserializer:(id<HCResourceSerializer>)hcserializer
             timeout:(NSInteger)timeout
         cachePolicy:(NSURLRequestCachePolicy)cachePolicy
        otherHeaders:(NSDictionary *)otherHeaders;

/**
 Creates and returns a serializer to be used for requests that do not contain
 an entity body (e.g., HTTP GET and HEAD).
 @param accept the media type to use for the Accept header
 @param acceptCharset the charset to use for the Accept-Charset header
 @param acceptLang the language to use for the Accept-Language header
 @param timeout The amount of time in seconds to wait for the request to
 complete.
 @param cachePolicy The cache policy to use for requests.
 @param otherHeaders Additional headers to include in the request.
 @return an AFNetworking-compliant request serializer appropriate for HTTP GET
 HEAD, etc requests.
*/
- (id)initWithAccept:(HCMediaType *)accept
       acceptCharset:(HCCharset *)acceptCharset
      acceptLanguage:(NSString *)acceptLang
       authorization:(HCAuthorization *)authorization
             timeout:(NSInteger)timeout
         cachePolicy:(NSURLRequestCachePolicy)cachePolicy
        otherHeaders:(NSDictionary *)otherHeaders;

@end
