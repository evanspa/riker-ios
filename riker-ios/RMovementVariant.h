//
//  RMovementVariant.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMovementVariant : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name
                         abbrevName:(NSString *)abbrevName
                 variantDescription:(NSString *)variantDescription
                          sortOrder:(NSNumber *)sortOrder;

#pragma mark - Properties

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *abbrevName;
@property (nonatomic) NSString *variantDescription;
@property (nonatomic) NSNumber *sortOrder;

#pragma mark - Equality

- (BOOL)isEqualToMovementVariant:(RMovementVariant *)movementVariant;

@end
