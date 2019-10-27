//
//  HCHalJsonSerializerExtensionSupport.h
//

#import "HCHalJsonSerializer.h"

/**
 Convenience class for creating custom serializers that extend from the HAL
 Json serializer class.  Sub-classes need only override 2 simple methods for
 achieving serialization / deserialization support.  Sub-classes essentially
 need only provide a way to map an NSDictionary to/from their model.
 */
@interface HCHalJsonSerializerExtensionSupport : HCHalJsonSerializer

#pragma mark - Serialization (Resource Model -> Dictionary)

/**
 Returns a dictionary from the given resource model object.
 @param resourceModel The model object.
 @return A dictionary representation of the given resource model object.
 */
- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel;

#pragma mark - Deserialization (Dictionary -> Resource Model)

/**
 Returns a resource model object from the given dictionary.
 @param resourceDictionary Dictionary representation of a model object.
 @return The model object represented by the given dictionary.
 */
- (id)resourceModelWithDictionary:(NSDictionary *)resourceDictionary
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified;

@end
