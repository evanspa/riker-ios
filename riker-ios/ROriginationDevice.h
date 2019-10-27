//
//  ROriginationDevice.h
//  riker-ios
//
//  Created by PEVANS on 10/18/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMasterSupport.h"

@interface ROriginationDevice : PELMMasterSupport<NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier
                   globalIdentifier:(NSString *)globalIdentifier
                          mediaType:(HCMediaType *)mediaType
                          relations:(NSDictionary *)relations
                          createdAt:(NSDate *)createdAt
                          deletedAt:(NSDate *)deletedAt
                          updatedAt:(NSDate *)updatedAt
                               name:(NSString *)name
                      iconImageName:(NSString *)iconImageName
                      hasLocalImage:(BOOL)hasLocalImage;

#pragma mark - Properties

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *iconImageName;
@property (nonatomic) BOOL hasLocalImage;

#pragma mark - Equality

- (BOOL)isEqualToOriginationDevice:(ROriginationDevice *)originationDevice;

@end
