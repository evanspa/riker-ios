//
//  RMovementVariantSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovementVariantSerializer.h"
#import "RMovementVariant.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMovementVariantIdKey          = @"movementvariant/id";
NSString * const RMovementVariantNameKey        = @"movementvariant/name";
NSString * const RMovementVariantAbbrevNameKey  = @"movementvariant/abbrev-name";
NSString * const RMovementVariantSortOrderKey   = @"movementvariant/sort-order";
NSString * const RMovementVariantDescriptionKey = @"movementvariant/description";
NSString * const RMovementVariantCreatedAtKey   = @"movementvariant/created-at";
NSString * const RMovementVariantDeletedAtKey   = @"movementvariant/deleted-at";
NSString * const RMovementVariantUpdatedAtKey   = @"movementvariant/updated-at";

@implementation RMovementVariantSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  return nil; // not used
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  RMovementVariant *movementVariant =
  [[RMovementVariant alloc] initWithLocalMasterIdentifier:resDict[RMovementVariantIdKey]
                                         globalIdentifier:location
                                                mediaType:mediaType
                                                relations:relations
                                                createdAt:[resDict dateSince1970ForKey:RMovementVariantCreatedAtKey]
                                                deletedAt:[resDict dateSince1970ForKey:RMovementVariantDeletedAtKey]
                                                updatedAt:[resDict dateSince1970ForKey:RMovementVariantUpdatedAtKey]
                                                     name:resDict[RMovementVariantNameKey]
                                               abbrevName:resDict[RMovementVariantAbbrevNameKey]
                                       variantDescription:resDict[RMovementVariantDescriptionKey]
                                                sortOrder:resDict[RMovementVariantSortOrderKey]];
  return movementVariant;
}

@end
