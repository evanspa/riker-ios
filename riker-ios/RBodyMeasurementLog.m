//
//  RBodyMeasurementLog.m
//  riker-ios
//
//  Created by PEVANS on 10/19/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RBodyMeasurementLog.h"
#import "PEUtils.h"
#import "RDDLUtils.h"
#import "ROriginationDevice.h"

@implementation RBodyMeasurementLog

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
                       bodyWeight:(NSDecimalNumber *)bodyWeight
                    bodyWeightUom:(NSNumber *)bodyWeightUom
                          armSize:(NSDecimalNumber *)armSize
                         calfSize:(NSDecimalNumber *)calfSize
                        chestSize:(NSDecimalNumber *)chestSize
                          sizeUom:(NSNumber *)sizeUom
                         neckSize:(NSDecimalNumber *)neckSize
                        waistSize:(NSDecimalNumber *)waistSize
                        thighSize:(NSDecimalNumber *)thighSize
                      forearmSize:(NSDecimalNumber *)forearmSize
                         loggedAt:(NSDate *)loggedAt
              originationDeviceId:(NSNumber *)originationDeviceId
                       importedAt:(NSDate *)importedAt {
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
    _bodyWeight = bodyWeight;
    _bodyWeightUom = bodyWeightUom;
    _armSize = armSize;
    _calfSize = calfSize;
    _chestSize = chestSize;
    _sizeUom = sizeUom;
    _neckSize = neckSize;
    _waistSize = waistSize;
    _thighSize = thighSize;
    _forearmSize = forearmSize;
    _loggedAt = loggedAt;
    _originationDeviceId = originationDeviceId;
    _importedAt = importedAt;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RBodyMeasurementLog *copy =
  [[RBodyMeasurementLog alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                                bodyWeight:_bodyWeight
                                             bodyWeightUom:_bodyWeightUom
                                                   armSize:_armSize
                                                  calfSize:_calfSize
                                                 chestSize:_chestSize
                                                   sizeUom:_sizeUom
                                                  neckSize:_neckSize
                                                 waistSize:_waistSize
                                                 thighSize:_thighSize
                                               forearmSize:_forearmSize
                                                  loggedAt:_loggedAt
                                       originationDeviceId:_originationDeviceId
                                                importedAt:_importedAt];
  return copy;
}

#pragma mark - Creation Functions

+ (instancetype)bmlWithBodyWeight:(NSDecimalNumber *)bodyWeight
                    bodyWeightUom:(NSNumber *)bodyWeightUom
                          armSize:(NSDecimalNumber *)armSize
                         calfSize:(NSDecimalNumber *)calfSize
                        chestSize:(NSDecimalNumber *)chestSize
                          sizeUom:(NSNumber *)sizeUom
                         neckSize:(NSDecimalNumber *)neckSize
                        waistSize:(NSDecimalNumber *)waistSize
                        thighSize:(NSDecimalNumber *)thighSize
                      forearmSize:(NSDecimalNumber *)forearmSize
                         loggedAt:(NSDate *)loggedAt
              originationDeviceId:(NSNumber *)originationDeviceId
                       importedAt:(NSDate *)importedAt
                        mediaType:(HCMediaType *)mediaType {
  return [RBodyMeasurementLog bmlWithBodyWeight:bodyWeight
                                  bodyWeightUom:bodyWeightUom
                                        armSize:armSize
                                       calfSize:calfSize
                                      chestSize:chestSize
                                        sizeUom:sizeUom
                                       neckSize:neckSize
                                      waistSize:waistSize
                                      thighSize:thighSize
                                    forearmSize:forearmSize
                                       loggedAt:loggedAt
                            originationDeviceId:originationDeviceId
                                     importedAt:importedAt
                          localMasterIdentifier:nil
                               globalIdentifier:nil
                                      mediaType:mediaType
                                      relations:nil
                                      createdAt:nil
                                      deletedAt:nil
                                      updatedAt:nil];
}

+ (instancetype)bmlWithBodyWeight:(NSDecimalNumber *)bodyWeight
                    bodyWeightUom:(NSNumber *)bodyWeightUom
                          armSize:(NSDecimalNumber *)armSize
                         calfSize:(NSDecimalNumber *)calfSize
                        chestSize:(NSDecimalNumber *)chestSize
                          sizeUom:(NSNumber *)sizeUom
                         neckSize:(NSDecimalNumber *)neckSize
                        waistSize:(NSDecimalNumber *)waistSize
                        thighSize:(NSDecimalNumber *)thighSize
                      forearmSize:(NSDecimalNumber *)forearmSize
                         loggedAt:(NSDate *)loggedAt
              originationDeviceId:(NSNumber *)originationDeviceId
                       importedAt:(NSDate *)importedAt
            localMasterIdentifier:(NSNumber *)localMasterIdentifier
                 globalIdentifier:(NSString *)globalIdentifier
                        mediaType:(HCMediaType *)mediaType
                        relations:(NSDictionary *)relations
                        createdAt:(NSDate *)createdAt
                        deletedAt:(NSDate *)deletedAt
                        updatedAt:(NSDate *)updatedAt {
  return [[RBodyMeasurementLog alloc] initWithLocalMainIdentifier:nil
                                            localMasterIdentifier:localMasterIdentifier
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
                                                       bodyWeight:bodyWeight
                                                    bodyWeightUom:bodyWeightUom
                                                          armSize:armSize
                                                         calfSize:calfSize
                                                        chestSize:chestSize
                                                          sizeUom:sizeUom
                                                         neckSize:neckSize
                                                        waistSize:waistSize
                                                        thighSize:thighSize
                                                      forearmSize:forearmSize
                                                         loggedAt:loggedAt
                                              originationDeviceId:originationDeviceId
                                                       importedAt:importedAt];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RBodyMeasurementLog *)bodyMeasurementLog {
  [super overwriteDomainProperties:bodyMeasurementLog];
  [self setBodyWeight:bodyMeasurementLog.bodyWeight];
  [self setBodyWeightUom:bodyMeasurementLog.bodyWeightUom];
  [self setArmSize:bodyMeasurementLog.armSize];
  [self setCalfSize:bodyMeasurementLog.calfSize];
  [self setChestSize:bodyMeasurementLog.chestSize];
  [self setSizeUom:bodyMeasurementLog.sizeUom];
  [self setNeckSize:bodyMeasurementLog.neckSize];
  [self setWaistSize:bodyMeasurementLog.waistSize];
  [self setForearmSize:bodyMeasurementLog.forearmSize];
  [self setThighSize:bodyMeasurementLog.thighSize];
  [self setLoggedAt:bodyMeasurementLog.loggedAt];
  [self setOriginationDeviceId:bodyMeasurementLog.originationDeviceId];
}

- (void)overwrite:(RBodyMeasurementLog *)bodyMeasurementLog {
  [super overwrite:bodyMeasurementLog];
  [self overwriteDomainProperties:bodyMeasurementLog];
}

#pragma mark - Equality

- (BOOL)isEqualToBml:(RBodyMeasurementLog *)bodyMeasurementLog {
  if (!bodyMeasurementLog) { return NO; }
  if ([super isEqualToMainSupport:bodyMeasurementLog]) {
    return [PEUtils isNumProperty:@selector(bodyWeightUom) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(bodyWeight) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(armSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(calfSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(chestSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(sizeUom) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(neckSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(waistSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(thighSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(forearmSize) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isDateProperty:@selector(loggedAt) equalFor:self and:bodyMeasurementLog] &&
    [PEUtils isNumProperty:@selector(originationDeviceId) equalFor:self and:bodyMeasurementLog];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RBodyMeasurementLog class]]) { return NO; }
  return [self isEqualToBml:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self bodyWeight] hash] ^
  [[self bodyWeightUom] hash] ^
  [_armSize hash] ^
  [_calfSize hash] ^
  [_chestSize hash] ^
  [_sizeUom hash] ^
  [_neckSize hash] ^
  [_forearmSize hash] ^
  [_thighSize hash] ^
  [_waistSize hash] ^
  [_loggedAt hash] ^
  [_originationDeviceId hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, body weight: [%@], body weight uom: [%@], \
arm size: [%@], calf size: [%@], chest size: [%@], \
size uom: [%@], neck size: [%@], forearm size: [%@], waist size: [%@], \
thigh size: [%@], logged at: [%@], origination device id: [%@]",
          [super description],
          _bodyWeight,
          _bodyWeightUom,
          _armSize,
          _calfSize,
          _chestSize,
          _sizeUom,
          _neckSize,
          _forearmSize,
          _waistSize,
          _thighSize,
          _loggedAt,
          _originationDeviceId];
}

@end
