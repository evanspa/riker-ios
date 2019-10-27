//
//  HCRelation.h
//

@import Foundation;
@class HCResource;

/**
 An abstraction for modeling a hyperlink relation.  A link relation
 has a name, and relates 2 resources together (dubbed 'subject' and
 'target' by this abstraction).
 */
@interface HCRelation : NSObject

#pragma mark - Initializers

/**
 Creates and returns a new relation with the given name, and relates the given
 resources.
 @param name the name of the relation
 @param subject the subject resource
 @param target the target resource
 */
- (id)initWithName:(NSString *)name
   subjectResource:(HCResource *)subject
    targetResource:(HCResource *)target;

#pragma mark - Equality

/**
 @param relation the relation with which to compare the receiving relation
 @return a Boolean value that indicates whether the receiving relation is
 equal to the given relation.
*/
- (BOOL)isEqualToRelation:(HCRelation *)relation;

#pragma mark - Properties

/**
 The name of the relation.
 */
@property (nonatomic, readonly) NSString *name;

/**
 The subject resource of the relation.
 */
@property (nonatomic, readonly) HCResource *subject;

/**
 The target resource of the relation.
 */
@property (nonatomic, readonly) HCResource *target;

@end
