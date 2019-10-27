//
//  RBodyMeasurementLogSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RBodyMeasurementLogSerializer.h"
#import "RBodyMeasurementLog.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"
#import "PELMUserSerializer.h"

NSString * const RBmlIdKey                  = @"bodyjournallog/id";
NSString * const RBmlArmSizeKey             = @"bodyjournallog/arm-size";
NSString * const RBmlBodyWeightUomKey       = @"bodyjournallog/body-weight-uom";
NSString * const RBmlCalfSizeKey            = @"bodyjournallog/calf-size";
NSString * const RBmlBodyWeightKey          = @"bodyjournallog/body-weight";
NSString * const RBmlLoggedAtKey            = @"bodyjournallog/logged-at";
NSString * const RBmlSizeUomKey             = @"bodyjournallog/size-uom";
NSString * const RBmlChestSizeKey           = @"bodyjournallog/chest-size";
NSString * const RBmlNeckSizeKey            = @"bodyjournallog/neck-size";
NSString * const RBmlWaistSizeKey           = @"bodyjournallog/waist-size";
NSString * const RBmlThighSizeKey           = @"bodyjournallog/thigh-size";
NSString * const RBmlForearmSizeKey         = @"bodyjournallog/forearm-size";
NSString * const RBmlOriginationDeviceIdKey = @"bodyjournallog/origination-device-id";
NSString * const RBmlCreatedAtKey           = @"bodyjournallog/created-at";
NSString * const RBmlUpdatedAtKey           = @"bodyjournallog/updated-at";
NSString * const RBmlDeletedAtKey           = @"bodyjournallog/deleted-at";
NSString * const RBmlImportedAtKey          = @"bodyjournallog/imported-at";

@implementation RBodyMeasurementLogSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  RBodyMeasurementLog *bml = (RBodyMeasurementLog *)resourceModel;
  NSMutableDictionary *bmlDict = [NSMutableDictionary dictionary];
  [bmlDict nullSafeSetObject:[bml localMasterIdentifier] forKey:RBmlIdKey];
  [bmlDict nullSafeSetObject:[bml originationDeviceId] forKey:RBmlOriginationDeviceIdKey];
  [bmlDict setMillisecondsSince1970FromDate:[bml loggedAt] forKey:RBmlLoggedAtKey];
  [bmlDict nullSafeSetObject:[bml armSize] forKey:RBmlArmSizeKey];
  [bmlDict nullSafeSetObject:[bml bodyWeightUom] forKey:RBmlBodyWeightUomKey];
  [bmlDict nullSafeSetObject:[bml calfSize] forKey:RBmlCalfSizeKey];
  [bmlDict nullSafeSetObject:[bml bodyWeight] forKey:RBmlBodyWeightKey];
  [bmlDict nullSafeSetObject:[bml sizeUom] forKey:RBmlSizeUomKey];
  [bmlDict nullSafeSetObject:[bml neckSize] forKey:RBmlNeckSizeKey];
  [bmlDict nullSafeSetObject:[bml waistSize] forKey:RBmlWaistSizeKey];
  [bmlDict nullSafeSetObject:[bml forearmSize] forKey:RBmlForearmSizeKey];
  [bmlDict nullSafeSetObject:[bml thighSize] forKey:RBmlThighSizeKey];
  [bmlDict nullSafeSetObject:[bml chestSize] forKey:RBmlChestSizeKey];
  [bmlDict setMillisecondsSince1970FromDate:[bml importedAt] forKey:RBmlImportedAtKey];
  return bmlDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  RBodyMeasurementLog *bml =
  [RBodyMeasurementLog bmlWithBodyWeight:resDict[RBmlBodyWeightKey]
                           bodyWeightUom:resDict[RBmlBodyWeightUomKey]
                                 armSize:resDict[RBmlArmSizeKey]
                                calfSize:resDict[RBmlCalfSizeKey]
                               chestSize:resDict[RBmlChestSizeKey]
                                 sizeUom:resDict[RBmlSizeUomKey]
                                neckSize:resDict[RBmlNeckSizeKey]
                               waistSize:resDict[RBmlWaistSizeKey]
                               thighSize:resDict[RBmlThighSizeKey]
                             forearmSize:resDict[RBmlForearmSizeKey]
                                loggedAt:[resDict dateSince1970ForKey:RBmlLoggedAtKey]
                     originationDeviceId:resDict[RBmlOriginationDeviceIdKey]
                              importedAt:[resDict dateSince1970ForKey:RBmlImportedAtKey]
                   localMasterIdentifier:resDict[RBmlIdKey]
                        globalIdentifier:location
                               mediaType:mediaType
                               relations:relations
                               createdAt:[resDict dateSince1970ForKey:RBmlCreatedAtKey]
                               deletedAt:[resDict dateSince1970ForKey:RBmlDeletedAtKey]
                               updatedAt:[resDict dateSince1970ForKey:RBmlUpdatedAtKey]];
  [PELMUserSerializer populateUserFieldsOn:bml fromDictionary:resDict];
  return bml;
}

@end
