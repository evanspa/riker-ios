//
//  RUserSettingsSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RUserSettingsSerializer.h"
#import "RUserSettings.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"
#import "RUtils.h"
#import "PELMUserSerializer.h"

NSString * const RUserSettingsIdKey                 = @"usersettings/id";
NSString * const RUserSettingsWeightIncDecAmountKey = @"usersettings/weight-inc-dec-amount";
NSString * const RUserSettingsSizeUomKey            = @"usersettings/size-uom";
NSString * const RUserSettingsWeightUomKey          = @"usersettings/weight-uom";
NSString * const RUserSettingsCreatedAtKey          = @"usersettings/created-at";
NSString * const RUserSettingsUpdatedAtKey          = @"usersettings/updated-at";
NSString * const RUserSettingsDeletedAtKey          = @"usersettings/deleted-at";

@implementation RUserSettingsSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  RUserSettings *userSettings = (RUserSettings *)resourceModel;
  NSMutableDictionary *userSettingsDict = [NSMutableDictionary dictionary];
  [userSettingsDict nullSafeSetObject:[userSettings localMasterIdentifier] forKey:RUserSettingsIdKey];
  [userSettingsDict nullSafeSetObject:userSettings.sizeUom forKey:RUserSettingsSizeUomKey];
  [userSettingsDict nullSafeSetObject:userSettings.weightUom forKey:RUserSettingsWeightUomKey];
  [userSettingsDict nullSafeSetObject:userSettings.weightIncDecAmount forKey:RUserSettingsWeightIncDecAmountKey];
  return userSettingsDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  RUserSettings *userSettings =
  [RUserSettings userSettingsWithWeightUom:resDict[RUserSettingsWeightUomKey]
                                   sizeUom:resDict[RUserSettingsSizeUomKey]
                        weightIncDecAmount:resDict[RUserSettingsWeightIncDecAmountKey]
                          globalIdentifier:location
                                 mediaType:mediaType
                                 relations:relations
                                 createdAt:[resDict dateSince1970ForKey:RUserSettingsCreatedAtKey]
                                 deletedAt:[resDict dateSince1970ForKey:RUserSettingsDeletedAtKey]
                                 updatedAt:[resDict dateSince1970ForKey:RUserSettingsUpdatedAtKey]];
  [PELMUserSerializer populateUserFieldsOn:userSettings fromDictionary:resDict];
  return userSettings;
}

@end
