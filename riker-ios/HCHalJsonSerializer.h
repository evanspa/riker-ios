//
//  HCHalJsonSerializer.h
//

@import Foundation;
#import "HCResourceSerializerSupport.h"

FOUNDATION_EXPORT NSString * const HCEmbeddedResourceMediaTypeKey;
FOUNDATION_EXPORT NSString * const HCEmbeddedResourceLocationKey;
FOUNDATION_EXPORT NSString * const HCEmbeddedResourceLastModifiedKey;
FOUNDATION_EXPORT NSString * const HCEmbeddedResourcePayloadKey;
FOUNDATION_EXPORT NSString * const HCEmbeddedResource;

/**
 Only knows how to deserialize a JSON-formatted resource for the purpose of
 extracting the relations that follow the
 <a href="http://tools.ietf.org/html/draft-kelly-json-hal-06">HAL
 specification</a>.
 */
@interface HCHalJsonSerializer : HCResourceSerializerSupport

@end
