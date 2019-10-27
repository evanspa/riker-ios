//
//  RBodySegmentSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/22/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RBodySegmentSerializer.h"
#import "RBodySegment.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const RBodySegmentIdKey        = @"bodysegment/id";
NSString * const RBodySegmentNameKey      = @"bodysegment/name";
NSString * const RBodySegmentCreatedAtKey = @"bodysegment/created-at";
NSString * const RBodySegmentUpdatedAtKey = @"bodysegment/updated-at";
NSString * const RBodySegmentDeletedAtKey = @"bodysegment/deleted-at";

@implementation RBodySegmentSerializer

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
  RBodySegment *bodySegment =
  [[RBodySegment alloc] initWithLocalMasterIdentifier:resDict[RBodySegmentIdKey]
                                     globalIdentifier:location
                                            mediaType:mediaType
                                            relations:relations
                                            createdAt:[resDict dateSince1970ForKey:RBodySegmentCreatedAtKey]
                                            deletedAt:[resDict dateSince1970ForKey:RBodySegmentDeletedAtKey]
                                            updatedAt:[resDict dateSince1970ForKey:RBodySegmentUpdatedAtKey]
                                                 name:resDict[RBodySegmentNameKey]];
  return bodySegment;
}

@end
