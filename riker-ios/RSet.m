//
//  RSet.m
//  riker-ios
//
//  Created by PEVANS on 10/17/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RSet.h"
#import "PEUtils.h"
#import "RDDLUtils.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"

NSString * const RSetNumRepsField = @"RSetsNumRepsField";
NSString * const RSetWeightField = @"RSetWeightField";
NSString * const RSetWeightUomField = @"RSetWeightUomField";
NSString * const RSetNegativesField = @"RSetNegativesField";
NSString * const RSetToFailureField = @"RSetToFailureField";
NSString * const RSetLoggedAtField = @"RSetLoggedAtField";
NSString * const RSetIgnoreTimeField = @"RSetIgnoreTimeField";
NSString * const RSetMovementIdField = @"RSetMovementIdField";
NSString * const RSetMovementVariantIdField = @"RSetMovementVariantIdField";
NSString * const RSetOriginationDeviceIdField = @"RSetOriginationDeviceIdField";

@implementation RSet

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
                  correlationGuid:(NSString *)correlationGuid {
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
    _numReps = numReps;
    _weight = weight;
    _weightUom = weightUom;
    _negatives = negatives;
    _toFailure = toFailure;
    _loggedAt = loggedAt;
    _ignoreTime = ignoreTime;
    _movementId = movementId;
    _movementVariantId = movementVariantId;
    _originationDeviceId = originationDeviceId;
    _importedAt = importedAt;
    _correlationGuid = correlationGuid;
  }
  return self;
}

#pragma mark - NSCopying

-(id)copyWithZone:(NSZone *)zone {
  RSet *copy =
  [[RSet alloc] initWithLocalMainIdentifier:[self localMainIdentifier]
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
                                    numReps:_numReps
                                     weight:_weight
                                  weightUom:_weightUom
                                  negatives:_negatives
                                  toFailure:_toFailure
                                   loggedAt:_loggedAt
                                 ignoreTime:_ignoreTime
                                 movementId:_movementId
                          movementVariantId:_movementVariantId
                        originationDeviceId:_originationDeviceId
                                 importedAt:_importedAt
                            correlationGuid:_correlationGuid];
  return copy;
}

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
                     mediaType:(HCMediaType *)mediaType {
  return [RSet setWithNumReps:numReps
                       weight:weight
                    weightUom:weightUom
                    negatives:negatives
                    toFailure:toFailure
                     loggedAt:loggedAt
                   ignoreTime:ignoreTime
                   movementId:movementId
            movementVariantId:movementVariantId
          originationDeviceId:originationDeviceId
                   importedAt:importedAt
              correlationGuid:correlationGuid
        localMasterIdentifier:nil
             globalIdentifier:nil
                    mediaType:mediaType
                    relations:nil
                    createdAt:nil
                    deletedAt:nil
                    updatedAt:nil];
}

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
                     updatedAt:(NSDate *)updatedAt {
  return [[RSet alloc] initWithLocalMainIdentifier:nil
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
                                           numReps:numReps
                                            weight:weight
                                         weightUom:weightUom
                                         negatives:negatives
                                         toFailure:toFailure
                                          loggedAt:loggedAt
                                        ignoreTime:ignoreTime
                                        movementId:movementId
                                 movementVariantId:movementVariantId
                               originationDeviceId:originationDeviceId
                                        importedAt:importedAt
                                   correlationGuid:(NSString *)correlationGuid];
}

+ (instancetype)setWithCSVArray:(NSArray *)csvArray {
  return [[RSet alloc] initWithLocalMainIdentifier:nil
                             localMasterIdentifier:nil
                                  globalIdentifier:nil
                                         mediaType:nil
                                         relations:nil
                                         createdAt:nil
                                         deletedAt:nil
                                         updatedAt:nil
                              dateCopiedFromMaster:nil
                                    editInProgress:NO
                                    syncInProgress:NO
                                            synced:NO
                                         editCount:0
                                  syncHttpRespCode:nil
                                       syncErrMask:nil
                                       syncRetryAt:nil
                                           numReps:nil
                                            weight:nil
                                         weightUom:nil
                                         negatives:NO
                                         toFailure:NO
                                          loggedAt:nil
                                        ignoreTime:NO
                                        movementId:nil
                                 movementVariantId:nil
                               originationDeviceId:nil
                                        importedAt:nil
                                   correlationGuid:nil];}

+ (instancetype)setWithLocalMasterIdentifier:(NSNumber *)localMasterIdentifier {
  return [[RSet alloc] initWithLocalMainIdentifier:nil
                             localMasterIdentifier:localMasterIdentifier
                                  globalIdentifier:nil
                                         mediaType:nil
                                         relations:nil
                                         createdAt:nil
                                         deletedAt:nil
                                         updatedAt:nil
                              dateCopiedFromMaster:nil
                                    editInProgress:NO
                                    syncInProgress:NO
                                            synced:NO
                                         editCount:0
                                  syncHttpRespCode:nil
                                       syncErrMask:nil
                                       syncRetryAt:nil
                                           numReps:nil
                                            weight:nil
                                         weightUom:nil
                                         negatives:NO
                                         toFailure:NO
                                          loggedAt:nil
                                        ignoreTime:NO
                                        movementId:nil
                                 movementVariantId:nil
                               originationDeviceId:nil
                                        importedAt:nil
                                   correlationGuid:nil];
}

#pragma mark - Overwriting

- (void)overwriteDomainProperties:(RSet *)set {
  [super overwriteDomainProperties:set];
  [self setNumReps:[set numReps]];
  [self setWeight:[set weight]];
  [self setWeightUom:[set weightUom]];
  [self setNegatives:[set negatives]];
  [self setToFailure:[set toFailure]];
  [self setLoggedAt:[set loggedAt]];
  [self setMovementVariantId:[set movementVariantId]];
  [self setOriginationDeviceId:[set originationDeviceId]];
  [self setMovementId:[set movementId]];
  [self setIgnoreTime:[set ignoreTime]];
}

- (void)overwrite:(RSet *)set {
  [super overwrite:set];
  [self overwriteDomainProperties:set];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    _numReps = [coder decodeObjectForKey:RSetNumRepsField];
    _weight = [coder decodeObjectForKey:RSetWeightField];
    _weightUom = [coder decodeObjectForKey:RSetWeightUomField];
    _loggedAt = [coder decodeObjectForKey:RSetLoggedAtField];
    _movementId = [coder decodeObjectForKey:RSetMovementIdField];
    _movementVariantId = [coder decodeObjectForKey:RSetMovementVariantIdField];
    _ignoreTime = [coder decodeBoolForKey:RSetIgnoreTimeField];
    _negatives = [coder decodeBoolForKey:RSetNegativesField];
    _toFailure = [coder decodeBoolForKey:RSetToFailureField];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.numReps forKey:RSetNumRepsField];
  [coder encodeObject:self.weight forKey:RSetWeightField];
  [coder encodeObject:self.weightUom forKey:RSetWeightUomField];
  [coder encodeObject:self.loggedAt forKey:RSetLoggedAtField];
  [coder encodeObject:self.movementId forKey:RSetMovementIdField];
  [coder encodeObject:self.movementVariantId forKey:RSetMovementVariantIdField];
  [coder encodeBool:self.ignoreTime forKey:RSetIgnoreTimeField];
  [coder encodeBool:self.negatives forKey:RSetNegativesField];
  [coder encodeBool:self.toFailure forKey:RSetToFailureField];
}

#pragma mark - Equality

- (BOOL)isEqualToSet:(RSet *)set {
  if (!set) { return NO; }
  if ([super isEqualToMainSupport:set]) {
    return [PEUtils isNumProperty:@selector(numReps) equalFor:self and:set] &&
    [PEUtils isNumProperty:@selector(weight) equalFor:self and:set] &&
    [PEUtils isNumProperty:@selector(weightUom) equalFor:self and:set] &&
    [PEUtils isDateProperty:@selector(loggedAt) equalFor:self and:set] &&
    [PEUtils isNumProperty:@selector(movementId) equalFor:self and:set] &&
    [PEUtils isNumProperty:@selector(movementVariantId) equalFor:self and:set] &&
    [PEUtils isNumProperty:@selector(originationDeviceId) equalFor:self and:set];
  }
  return NO;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
  if (self == object) { return YES; }
  if (![object isKindOfClass:[RSet class]]) { return NO; }
  return [self isEqualToSet:object];
}

- (NSUInteger)hash {
  return [super hash] ^
  [[self numReps] hash] ^
  [[self weight] hash] ^
  [[self weightUom] hash] ^
  [[self loggedAt] hash] ^
  [[self movementVariantId] hash] ^
  [[self originationDeviceId] hash] ^
  [[self movementId] hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, num reps: [%@], weight: [%@], \
weight uom: [%@], negatives: [%d], to failure: [%d], logged at: [%@], \
ignore time: [%d], movement variant id: [%@], movement id: [%@], origination device id: [%@]",
          [super description],
          _numReps,
          _weight,
          _weightUom,
          _negatives,
          _toFailure,
          _loggedAt,
          _ignoreTime,
          _movementVariantId,
          _movementId,
          _originationDeviceId];
}

@end
