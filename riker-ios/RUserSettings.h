//
//  RUserSettings.h
//  riker-ios
//
//  Created by PEVANS on 10/19/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

FOUNDATION_EXPORT NSString * const RUserSettingsWeightUomField;
FOUNDATION_EXPORT NSString * const RUserSettingsSizeUomField;
FOUNDATION_EXPORT NSString * const RUserSettingsWeightIncDecAmountField;

@interface RUserSettings : PELMMainSupport <NSCopying>

#pragma mark - Initializers

- (id)initWithLocalMainIdentifier:(NSNumber *)localMainIdentifier
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt
             dateCopiedFromMaster:(NSDate *)dateCopiedFromMaster
                   editInProgress:(BOOL)editInProgress
                   syncInProgress:(BOOL)syncInProgress
                           synced:(BOOL)synced
                        editCount:(NSUInteger)editCount
                 syncHttpRespCode:(NSNumber *)syncHttpRespCode
                      syncErrMask:(NSNumber *)syncErrMask
                      syncRetryAt:(NSDate *)syncRetryAt
                        weightUom:(NSNumber *)weightUom
                          sizeUom:(NSNumber *)sizeUom
               weightIncDecAmount:(NSNumber *)weightIncDecAmount;

#pragma mark - Creation Functions

+ (instancetype)userSettingsWithWeightUom:(NSNumber *)weightUom
                                  sizeUom:(NSNumber *)sizeUom
                       weightIncDecAmount:(NSNumber *)weightIncDecAmount
                                mediaType:(HCMediaType *)mediaType;

+ (instancetype)userSettingsWithWeightUom:(NSNumber *)weightUom
                                  sizeUom:(NSNumber *)sizeUom
                       weightIncDecAmount:(NSNumber *)weightIncDecAmount
                         globalIdentifier:(NSString *)globalIdentifier
                                mediaType:(HCMediaType *)mediaType
                                relations:(NSDictionary *)relations
                                createdAt:(NSDate *)createdAt
                                deletedAt:(NSDate *)deletedAt
                                updatedAt:(NSDate *)updatedAt;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RUserSettings *)userSettings;

- (void)overwrite:(RUserSettings *)userSettings;

#pragma mark - Properties

@property (nonatomic) NSNumber *weightUom;
@property (nonatomic) NSNumber *sizeUom;
@property (nonatomic) NSNumber *weightIncDecAmount;

#pragma mark - Equality

- (BOOL)isEqualToUserSettings:(RUserSettings *)userSettings;

@end
