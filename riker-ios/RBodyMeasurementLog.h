//
//  RBodyMeasurementLog.h
//  riker-ios
//
//  Created by PEVANS on 10/19/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PELMMainSupport.h"

@class ROriginationDevice;

@interface RBodyMeasurementLog : PELMMainSupport <NSCopying>

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
                       importedAt:(NSDate *)importedAt;

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
                        mediaType:(HCMediaType *)mediaType;

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
                        updatedAt:(NSDate *)updatedAt;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RBodyMeasurementLog *)bodyMeasurementLog;

- (void)overwrite:(RBodyMeasurementLog *)bodyMeasurementLog;

#pragma mark - Properties

@property (nonatomic) NSDecimalNumber *bodyWeight;
@property (nonatomic) NSNumber *bodyWeightUom;
@property (nonatomic) NSDecimalNumber *armSize;
@property (nonatomic) NSDecimalNumber *calfSize;
@property (nonatomic) NSDecimalNumber *chestSize;
@property (nonatomic) NSDecimalNumber *waistSize;
@property (nonatomic) NSDecimalNumber *neckSize;
@property (nonatomic) NSDecimalNumber *forearmSize;
@property (nonatomic) NSDecimalNumber *thighSize;
@property (nonatomic) NSNumber *sizeUom;
@property (nonatomic) NSDate *loggedAt;
@property (nonatomic) NSNumber *originationDeviceId;
@property (nonatomic) NSDate *importedAt;

#pragma mark - Equality

- (BOOL)isEqualToBml:(RBodyMeasurementLog *)bodyMeasurementLog;

@end
