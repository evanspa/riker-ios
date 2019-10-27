//
//  PELoginSerializer.h
//

#import "HCHalJsonSerializerExtensionSupport.h"

@class PELMUserSerializer;

@interface PELoginSerializer : HCHalJsonSerializerExtensionSupport

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
         userSerializer:(PELMUserSerializer *)userSerializer;

@end
