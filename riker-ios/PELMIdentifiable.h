//
//  PELMIdentifiable.h
//

@protocol PELMIdentifiable <NSObject>

- (BOOL)doesHaveEqualIdentifiers:(id<PELMIdentifiable>)entity;

@optional

- (NSNumber *)localMainIdentifier;

- (NSNumber *)localMasterIdentifier;

- (NSString *)globalIdentifier;

@end
