//
//  RMovementAliasSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMovementAliasSerializer.h"
#import "RMovementAlias.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMovementAliasIdKey         = @"movementalias/id";
NSString * const RMovementAliasMovementIdKey = @"movementalias/movement-id";
NSString * const RMovementAliasAliasKey      = @"movementalias/alias";
NSString * const RMovementAliasCreatedAtKey  = @"movementalias/created-at";
NSString * const RMovementAliasDeletedAtKey  = @"movementalias/deleted-at";
NSString * const RMovementAliasUpdatedAtKey  = @"movementalias/updated-at";

@implementation RMovementAliasSerializer

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
  RMovementAlias *movementAlias =
  [[RMovementAlias alloc] initWithLocalMasterIdentifier:resDict[RMovementAliasIdKey]
                                       globalIdentifier:location
                                              mediaType:mediaType
                                              relations:relations
                                              createdAt:[resDict dateSince1970ForKey:RMovementAliasCreatedAtKey]
                                              deletedAt:[resDict dateSince1970ForKey:RMovementAliasDeletedAtKey]
                                              updatedAt:[resDict dateSince1970ForKey:RMovementAliasUpdatedAtKey]
                                             movementId:resDict[RMovementAliasMovementIdKey]
                                                  alias:resDict[RMovementAliasAliasKey]];
  return movementAlias;
}

@end
