//
//  RUserSettings.m
//  riker-ios
//
//  Created by PEVANS on 10/19/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RUserSettings.h"
#import "PEUtils.h"
#import "RDDLUtils.h"
#import "ROriginationDevice.h"

NSString * const RUserSettingsWeightUomField = @"RUserSettingsWeightUomField";
NSString * const RUserSettingsSizeUomField = @"RUserSettingsSizeUomField";
NSString * const RUserSettingsWeightIncDecAmountField = @"RUserSettingsWeightIncDecAmountField";

@implementation RUserSettings

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
               weightIncDecAmount:(NSNumber *)weightIncDecAmount {
  self = [super initWithLocalMainIdentifier:localMainIdentifier
                      localMasterIdentifier:localMasterIdentifier
                           globalIdentifier:globalIdentifier
                                  mediaType:mediaType
                                  relations:relations
                                  createdAt:createdAt
                                  deletedAt:deletedAt
                                  updatedAt:updatedAt
                       dateCopiedFromMaster:dateCopiedFromMaster
                             editInProgress:editInProgress
                             syncInProgress:syncInProgress
                                     synced:synced
                                  editCount:editCount
                           syncHttpRespCode:syncHttpRespCode
                                syncErrMask:syncErrMask
                                syncRetryAt:syncRetryAt];
  if (self) {
    _weightUom = weightUom;
    _sizeUom = sizeUom;
    _weightIncDecAmount = weightIncDecAmount;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RUserSettings *copy =
  [[RUserSettings alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
                               localMasterIdentifier:[self localMasterIdentifier]
                                    globalIdentifier:[self globalIdentifier]
                                           mediaType:[self mediaType]
                                           relations:nil
                                           createdAt:[self createdAt]
                                           deletedAt:[self deletedAt]
                                           updatedAt:[self updatedAt]
                                dateCopiedFromMaster:[self dateCopiedFromMaster]
                                      editInProgress:NO
                                      syncInProgress:[self syncInProgress]
                                              synced:[self synced]
                                           editCount:[self editCount]
                                    syncHttpRespCode:[self syncHttpRespCode]
                                         syncErrMask:[self syncErrMask]
                                         syncRetryAt:[self syncRetryAt]
                                           weightUom:_weightUom
                                             sizeUom:_sizeUom
                                  weightIncDecAmount:_weightIncDecAmount];
  return copy;
}

#pragma mark - Creation Functions

+ (instancetype)userSettingsWithWeightUom:(NSNumber *)weightUom
                                  sizeUom:(NSNumber *)sizeUom
                       weightIncDecAmount:(NSNumber *)weightIncDecAmount
                                mediaType:(HCMediaType *)mediaType {
  return [RUserSettings userSettingsWithWeightUom:weightUom
                                          sizeUom:sizeUom
                               weightIncDecAmount:weightIncDecAmount
                                 globalIdentifier:nil
                                        mediaType:mediaType
                                        relations:nil
                                        createdAt:nil
                                        deletedAt:nil
                                        updatedAt:nil];
}

+ (instancetype)userSettingsWithWeightUom:(NSNumber *)weightUom
                                  sizeUom:(NSNumber *)sizeUom
                       weightIncDecAmount:(NSNumber *)weightIncDecAmount
                         globalIdentifier:(NSString *)globalIdentifier
                                mediaType:(HCMediaType *)mediaType
                                relations:(NSDictionary *)relations
                                createdAt:(NSDate *)createdAt
                                deletedAt:(NSDate *)deletedAt
                                updatedAt:(NSDate *)updatedAt {
  return [[RUserSettings alloc] initWithLocalMainIdentifier:nil
                                      localMasterIdentifier:nil
                                           globalIdentifier:globalIdentifier
                                                  mediaType:mediaType
                                                  relations:relations
                                                  createdAt:createdAt
                                                  deletedAt:deletedAt
                                                  updatedAt:updatedAt
                                       dateCopiedFromMaster:nil
                                             editInProgress:NO
                                             syncInProgress:NO
                                                     synced:NO
                                                  editCount:0
                                           syncHttpRespCode:nil
                                                syncErrMask:nil
                                                syncRetryAt:nil
                                                  weightUom:weightUom
                                                    sizeUom:sizeUom
                                         weightIncDecAmount:weightIncDecAmount];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RUserSettings *)userSettings {
  [super overwriteDomainProperties:userSettings];
  [self setWeightUom:userSettings.weightUom];
  [self setSizeUom:userSettings.sizeUom];
  [self setWeightIncDecAmount:userSettings.weightIncDecAmount];
}

- (void)overwrite:(RUserSettings *)userSettings {
  [super overwrite:userSettings];
  [self overwriteDomainProperties:userSettings];
}

#pragma mark - Equality

- (BOOL)isEqualToUserSettings:(RUserSettings *)userSettings {
  if (!userSettings) { return NO; }
  if ([super isEqualToMainSupport:userSettings]) {
    return [PEUtils isNumProperty:@selector(weightUom) equalFor:self and:userSettings] &&
    [PEUtils isNumProperty:@selector(sizeUom) equalFor:self and:userSettings] &&
    [PEUtils isNumProperty:@selector(weightIncDecAmount) equalFor:self and:userSettings];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RUserSettings class]]) { return NO; }
  return [self isEqualToUserSettings:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [_weightUom hash] ^
  [_sizeUom hash] ^
  [_weightIncDecAmount hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, weight uom: [%@], size uom: [%@], \
weight inc/dec amount: [%@]",
          [super description],
          _weightUom,
          _sizeUom,
          _weightIncDecAmount];
}

@end
