//
//  RMuscleAliasSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscleAliasSerializer.h"
#import "RMuscleAlias.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMuscleAliasIdKey        = @"musclealias/id";
NSString * const RMuscleAliasMuscleIdKey  = @"musclealias/muscle-id";
NSString * const RMuscleAliasAliasKey     = @"musclealias/alias";
NSString * const RMuscleAliasCreatedAtKey = @"musclealias/created-at";
NSString * const RMuscleAliasDeletedAtKey = @"musclealias/deleted-at";
NSString * const RMuscleAliasUpdatedAtKey = @"musclealias/updated-at";

@implementation RMuscleAliasSerializer

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
  RMuscleAlias *muscleAlias =
  [[RMuscleAlias alloc] initWithLocalMasterIdentifier:resDict[RMuscleAliasIdKey]
                                     globalIdentifier:location
                                            mediaType:mediaType
                                            relations:relations
                                            createdAt:[resDict dateSince1970ForKey:RMuscleAliasCreatedAtKey]
                                            deletedAt:[resDict dateSince1970ForKey:RMuscleAliasDeletedAtKey]
                                            updatedAt:[resDict dateSince1970ForKey:RMuscleAliasUpdatedAtKey]
                                             muscleId:resDict[RMuscleAliasMuscleIdKey]
                                                alias:resDict[RMuscleAliasAliasKey]];
  return muscleAlias;
}

@end
