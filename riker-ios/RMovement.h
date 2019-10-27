//
//  RMovement.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMovement : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      canonicalName:(NSString *)canonicalName
                         isBodyLift:(BOOL)isBodyLift
             percentageOfBodyWeight:(NSDecimalNumber *)percentageOfBodyWeight
                        variantMask:(NSNumber *)variantMask
                          sortOrder:(NSNumber *)sortOrder
                   primaryMuscleIds:(NSArray *)primaryMuscleIds
                 secondaryMuscleIds:(NSArray *)secondaryMuscleIds;

#pragma mark - Properties

@property (nonatomic) NSString *canonicalName;

@property (nonatomic) BOOL isBodyLift;

@property (nonatomic) NSDecimalNumber *percentageOfBodyWeight;

@property (nonatomic) NSNumber *variantMask;

@property (nonatomic) NSNumber *sortOrder;

@property (nonatomic) NSArray *primaryMuscleIds;

@property (nonatomic) NSArray *secondaryMuscleIds;

#pragma mark - Equality

- (BOOL)isEqualToMovement:(RMovement *)movement;

@end
