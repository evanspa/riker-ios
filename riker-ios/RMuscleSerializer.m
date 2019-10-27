//
//  RMuscleSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/22/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscleSerializer.h"
#import "RMuscle.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMuscleIdKey            = @"muscle/id";
NSString * const RMuscleCanonicalNameKey = @"muscle/canonical-name";
NSString * const RMuscleAbbrevCanonicalNameKey = @"muscle/abbrev-canonical-name";
NSString * const RMuscleMuscleGroupIdKey = @"muscle/muscle-group-id";
NSString * const RMuscleCreatedAtKey     = @"muscle/created-at";
NSString * const RMuscleDeletedAtKey     = @"muscle/deleted-at";
NSString * const RMuscleUpdatedAtKey     = @"muscle/updated-at";

@implementation RMuscleSerializer

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
  RMuscle *muscle =
  [[RMuscle alloc] initWithLocalMasterIdentifier:resDict[RMuscleIdKey]
                                globalIdentifier:location
                                       mediaType:mediaType
                                       relations:relations
                                       createdAt:[resDict dateSince1970ForKey:RMuscleCreatedAtKey]
                                       deletedAt:[resDict dateSince1970ForKey:RMuscleDeletedAtKey]
                                       updatedAt:[resDict dateSince1970ForKey:RMuscleUpdatedAtKey]
                                   muscleGroupId:resDict[RMuscleMuscleGroupIdKey]
                                   canonicalName:resDict[RMuscleCanonicalNameKey]
                             abbrevCanonicalName:resDict[RMuscleAbbrevCanonicalNameKey]];
  return muscle;
}

@end
