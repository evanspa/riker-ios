//
//  RMuscleGroupSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/22/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RMuscleGroupSerializer.h"
#import "RMuscleGroup.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RMuscleGroupIdKey            = @"musclegroup/id";
NSString * const RMuscleGroupNameKey          = @"musclegroup/name";
NSString * const RMuscleGroupAbbrevNameKey    = @"musclegroup/abbrev-name";
NSString * const RMuscleGroupBodySegmentIdKey = @"musclegroup/body-segment-id";
NSString * const RMuscleGroupCreatedAtKey     = @"musclegroup/created-at";
NSString * const RMuscleGroupDeletedAtKey     = @"musclegroup/deleted-at";
NSString * const RMuscleGroupUpdatedAtKey     = @"musclegroup/updated-at";

@implementation RMuscleGroupSerializer

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
  RMuscleGroup *muscleGroup =
  [[RMuscleGroup alloc] initWithLocalMasterIdentifier:resDict[RMuscleGroupIdKey]
                                     globalIdentifier:location
                                            mediaType:mediaType
                                            relations:relations
                                            createdAt:[resDict dateSince1970ForKey:RMuscleGroupCreatedAtKey]
                                            deletedAt:[resDict dateSince1970ForKey:RMuscleGroupDeletedAtKey]
                                            updatedAt:[resDict dateSince1970ForKey:RMuscleGroupUpdatedAtKey]
                                        bodySegmentId:resDict[RMuscleGroupBodySegmentIdKey]
                                                 name:resDict[RMuscleGroupNameKey]
                                           abbrevName:resDict[RMuscleGroupAbbrevNameKey]];
  return muscleGroup;
}

@end
