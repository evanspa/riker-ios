//
//  RMuscleGroup.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMuscleGroup : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      bodySegmentId:(NSNumber *)bodySegmentId
                               name:(NSString *)name
                         abbrevName:(NSString *)abbrevName;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RMuscleGroup *)bodySegment;

- (void)overwrite:(RMuscleGroup *)bodySegment;

#pragma mark - Properties

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *abbrevName;
@property (nonatomic) NSNumber *bodySegmentId;

#pragma mark - Equality

- (BOOL)isEqualToMuscleGroup:(RMuscleGroup *)muscleGroup;

@end
