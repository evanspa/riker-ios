//
//  PEChangelogSerializer.h
//

#import "HCHalJsonSerializerExtensionSupport.h"

@interface PEChangelogSerializer : HCHalJsonSerializerExtensionSupport

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions
         changelogClass:(Class)changelogClass;

@end
