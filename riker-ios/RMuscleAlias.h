//
//  RMuscleAlias.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMuscleAlias : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                           muscleId:(NSNumber *)muscleId
                              alias:(NSString *)alias;

#pragma mark - Properties

@property (nonatomic) NSString *alias;

@property (nonatomic) NSNumber *muscleId;

#pragma mark - Equality

- (BOOL)isEqualToMuscleAlias:(RMuscleAlias *)muscleAlias;

@end
