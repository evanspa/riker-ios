//
//  RBodySegment.h
//  riker-ios
//
//  Created by PEVANS on 10/16/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface RBodySegment : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RBodySegment *)bodySegment;

- (void)overwrite:(RBodySegment *)bodySegment;

#pragma mark - Properties

@property (nonatomic) NSString *name;

#pragma mark - Equality

- (BOOL)isEqualToBodySegment:(RBodySegment *)bodySegment;

@end
