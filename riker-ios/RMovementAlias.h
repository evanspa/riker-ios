//
//  RMovementAlias.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMovementAlias : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                         movementId:(NSNumber *)movementId
                              alias:(NSString *)alias;

#pragma mark - Properties

@property (nonatomic) NSString *alias;

@property (nonatomic) NSNumber *movementId;

#pragma mark - Equality

- (BOOL)isEqualToMovementAlias:(RMovementAlias *)movementAlias;

@end
