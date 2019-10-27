//
//  PELMModelSupport.h
//

@import Foundation;
@class HCMediaType;

#import "PELMIdentifiable.h"

@interface PELMModelSupport : NSObject<PELMIdentifiable>

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier                  
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations;

#pragma mark - Methods

- (void)overwrite:(PELMModelSupport *)entity;

#pragma mark - Properties

//@property (nonatomic) NSNumber *localMainIdentifier;
- (NSNumber *)localMainIdentifier;

@property (nonatomic) NSNumber *localMasterIdentifier;

@property (nonatomic) NSString *globalIdentifier;

@property (nonatomic) HCMediaType *mediaType;

#pragma mark - Equality

- (BOOL)isEqualToModelSupport:(PELMModelSupport *)modelSupport;

@end
