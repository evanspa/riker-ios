//
//  RMuscle.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RMuscle : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                      muscleGroupId:(NSNumber *)muscleGroupId
                      canonicalName:(NSString *)canonicalName
                abbrevCanonicalName:(NSString *)abbrevCanonicalName;

#pragma mark - Properties

@property (nonatomic) NSString *canonicalName;
@property (nonatomic) NSString *abbrevCanonicalName;
@property (nonatomic) NSNumber *muscleGroupId;

#pragma mark - Equality

- (BOOL)isEqualToMuscle:(RMuscle *)muscle;

@end
