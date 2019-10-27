//
//  RSet.h
//  riker-ios
//
//  Created by PEVANS on 10/17/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PELMMainSupport.h"

@class RMovement;
@class RMovementVariant;
@class ROriginationDevice;

@interface RSet : PELMMainSupport <NSCopying, NSCoding>

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
                          numReps:(NSNumber *)numReps
                           weight:(NSDecimalNumber *)weight
                        weightUom:(NSNumber *)weightUom
                        negatives:(BOOL)negatives
                        toFailure:(BOOL)toFailure
                         loggedAt:(NSDate *)loggedAt
                       ignoreTime:(BOOL)ignoreTime
                       movementId:(NSNumber *)movementId
                movementVariantId:(NSNumber *)movementVariantId
              originationDeviceId:(NSNumber *)originationDeviceId
                       importedAt:(NSDate *)importedAt
                  correlationGuid:(NSString *)correlationGuid;

#pragma mark - Creation Functions

+ (instancetype)setWithNumReps:(NSNumber *)numReps
                        weight:(NSDecimalNumber *)weight
                     weightUom:(NSNumber *)weightUom
                     negatives:(BOOL)negatives
                     toFailure:(BOOL)toFailure
                      loggedAt:(NSDate *)loggedAt
                    ignoreTime:(BOOL)ignoreTime
                    movementId:(NSNumber *)movementId
             movementVariantId:(NSNumber *)movementVariantId
           originationDeviceId:(NSNumber *)originationDeviceId
                    importedAt:(NSDate *)importedAt
               correlationGuid:(NSString *)correlationGuid
                     mediaType:(HCMediaType *)mediaType;

+ (instancetype)setWithNumReps:(NSNumber *)numReps
                        weight:(NSDecimalNumber *)weight
                     weightUom:(NSNumber *)weightUom
                     negatives:(BOOL)negatives
                     toFailure:(BOOL)toFailure
                      loggedAt:(NSDate *)loggedAt
                    ignoreTime:(BOOL)ignoreTime
                    movementId:(NSNumber *)movementId
             movementVariantId:(NSNumber *)movementVariantId
           originationDeviceId:(NSNumber *)originationDeviceId
                    importedAt:(NSDate *)importedAt
               correlationGuid:(NSString *)correlationGuid
         localMasterIdentifier:(NSNumber *)localMasterIdentifier
              globalIdentifier:(NSString *)globalIdentifier
                     mediaType:(HCMediaType *)mediaType
                     relations:(NSDictionary *)relations
                     createdAt:(NSDate *)createdAt
                     deletedAt:(NSDate *)deletedAt
                     updatedAt:(NSDate *)updatedAt;

+ (RSet *)setWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier;

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RSet *)set;

- (void)overwrite:(RSet *)set;

#pragma mark - Properties

@property (nonatomic) NSNumber *numReps;
@property (nonatomic) NSDecimalNumber *weight;
@property (nonatomic) NSNumber *weightUom;
@property (nonatomic) BOOL negatives;
@property (nonatomic) BOOL toFailure;
@property (nonatomic) NSDate *loggedAt;
@property (nonatomic) BOOL ignoreTime;
@property (nonatomic) NSNumber *movementId;
@property (nonatomic) NSNumber *movementVariantId;
@property (nonatomic) NSNumber *originationDeviceId;
@property (nonatomic) NSDate *importedAt;
@property (nonatomic) NSString *correlationGuid;

#pragma mark - Equality

- (BOOL)isEqualToSet:(RSet *)set;

@end
