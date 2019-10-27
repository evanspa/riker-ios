//
//  HCDeserializedPair.h
//

@import Foundation;

/**
 An abstraction representing the return-type of deserializing an HTTP response.
 An HTTP response can be thought of consisting of 2 logical pieces: an entity
 and a set of relations in which the entity is the subject resource.  The
 nomencalture given to entity is resource model.
 */
@interface HCDeserializedPair : NSObject

#pragma mark - Initializers

/**
 Creates and returns a new deserialized-pair instance with the given resource
 model and relation collection.
 @param resourceModel the model object that represents the deserialized entity
 @param relations the collection of deserialized relations from the HTTP
 response
 @return a new deserialized-pair instance
 */
- (id)initWithResourceModel:(id)resourceModel
                  relations:(NSDictionary *)relations;

/**
 The deserialized entity from the HTTP response as a model object.
 */
@property (nonatomic, readonly) id resourceModel;

/**
 The set of relations deserialized from the HTTP response.
 */
@property (nonatomic, readonly) NSDictionary *relations;

@end
