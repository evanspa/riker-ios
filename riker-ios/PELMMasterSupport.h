//
//  PELMMasterSupport.h
//

#import "PELMModelSupport.h"

@interface PELMMasterSupport : PELMModelSupport

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt;

#pragma mark - Methods

- (void)overwrite:(PELMMasterSupport *)entity;

#pragma mark - Properties

@property (nonatomic) NSDate *createdAt;

@property (nonatomic) NSDate *updatedAt;

@property (nonatomic) NSDate *deletedAt;

#pragma mark - Equality

- (BOOL)isEqualToMasterSupport:(PELMMasterSupport *)masterSupport;

@end
