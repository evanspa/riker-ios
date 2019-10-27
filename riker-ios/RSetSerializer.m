//
//  RSetSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RSetSerializer.h"
#import "RSet.h"
#import "RMovement.h"
#import "RMovementVariant.h"
#import "ROriginationDevice.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"
#import "PELMUserSerializer.h"

NSString * const RSetIdKey                        = @"set/id";
NSString * const RSetMovementIdKey                = @"set/movement-id";
NSString * const RSetMovementGlobalIdKey          = @"set/movement";
NSString * const RSetMovementVariantIdKey         = @"set/movement-variant-id";
NSString * const RSetMovementVariantGlobalIdKey   = @"set/movement-variant";
NSString * const RSetOriginationDeviceIdKey       = @"set/origination-device-id";
NSString * const RSetOriginationDeviceGlobalIdKey = @"set/origination-device";
NSString * const RSetIgnoreTimeKey                = @"set/ignore-time";
NSString * const RSetWeightUomKey                 = @"set/weight-uom";
NSString * const RSetNumRepsKey                   = @"set/num-reps";
NSString * const RSetLoggedAtKey                  = @"set/logged-at";
NSString * const RSetNegativesKey                 = @"set/negatives";
NSString * const RSetToFailureKey                 = @"set/to-failure";
NSString * const RSetWeightKey                    = @"set/weight";
NSString * const RSetCreatedAtKey                 = @"set/created-at";
NSString * const RSetUpdatedAtKey                 = @"set/updated-at";
NSString * const RSetDeletedAtKey                 = @"set/deleted-at";
NSString * const RSetImportedAtKey                = @"set/imported-at";

@implementation RSetSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  RSet *set = (RSet *)resourceModel;
  NSMutableDictionary *setDict = [NSMutableDictionary dictionary];
  [setDict nullSafeSetObject:[set localMasterIdentifier] forKey:RSetIdKey];
  [setDict nullSafeSetObject:[set movementId] forKey:RSetMovementIdKey];
  [setDict nullSafeSetObject:[set movementVariantId] forKey:RSetMovementVariantIdKey];
  [setDict nullSafeSetObject:[set originationDeviceId] forKey:RSetOriginationDeviceIdKey];
  [setDict setMillisecondsSince1970FromDate:[set loggedAt] forKey:RSetLoggedAtKey];
  [setDict nullSafeSetObject:[NSNumber numberWithBool:[set ignoreTime]] forKey:RSetIgnoreTimeKey];
  [setDict nullSafeSetObject:[NSNumber numberWithBool:[set negatives]] forKey:RSetNegativesKey];
  [setDict nullSafeSetObject:[NSNumber numberWithBool:[set toFailure]] forKey:RSetToFailureKey];
  [setDict nullSafeSetObject:[set weight] forKey:RSetWeightKey];
  [setDict nullSafeSetObject:[set weightUom] forKey:RSetWeightUomKey];
  [setDict nullSafeSetObject:[set numReps] forKey:RSetNumRepsKey];
  [setDict setMillisecondsSince1970FromDate:[set importedAt] forKey:RSetImportedAtKey];
  return setDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  RSet *set =
  [RSet setWithNumReps:resDict[RSetNumRepsKey]
                weight:[resDict decimalNumberForKey:RSetWeightKey]
             weightUom:resDict[RSetWeightUomKey]
             negatives:[resDict boolForKey:RSetNegativesKey]
             toFailure:[resDict boolForKey:RSetToFailureKey]
              loggedAt:[resDict dateSince1970ForKey:RSetLoggedAtKey]
            ignoreTime:[resDict boolForKey:RSetIgnoreTimeKey]
            movementId:resDict[RSetMovementIdKey]
     movementVariantId:resDict[RSetMovementVariantIdKey]
   originationDeviceId:resDict[RSetOriginationDeviceIdKey]
            importedAt:[resDict dateSince1970ForKey:RSetImportedAtKey]
       correlationGuid:nil
 localMasterIdentifier:resDict[RSetIdKey]
      globalIdentifier:location
             mediaType:mediaType
             relations:relations
             createdAt:[resDict dateSince1970ForKey:RSetCreatedAtKey]
             deletedAt:[resDict dateSince1970ForKey:RSetDeletedAtKey]
             updatedAt:[resDict dateSince1970ForKey:RSetUpdatedAtKey]];
  [PELMUserSerializer populateUserFieldsOn:set fromDictionary:resDict];
  return set;
}

@end
