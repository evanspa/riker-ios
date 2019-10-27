//
//  PEChangelog.h
//

@import Foundation;
@class PELMUser;
@class HCMediaType;

@interface PEChangelog : NSObject

#pragma mark - Initializers

- (id)initWithUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Creation Functions

+ (PEChangelog *)changelogOfClass:(Class)clazz
                    withUpdatedAt:(NSDate *)updatedAt;

#pragma mark - Properties

@property (nonatomic) NSString *globalIdentifier;

@property (nonatomic) HCMediaType *mediaType;

@property (nonatomic) NSDictionary *relations;

@property (nonatomic) NSDate *updatedAt;

#pragma mark - Methods

- (void)setUser:(PELMUser *)user;
- (PELMUser *)user;

@end
