//
//  ROriginationDeviceSerializer.m
//  riker-ios
//
//  Created by PEVANS on 10/23/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "ROriginationDeviceSerializer.h"
#import "ROriginationDevice.h"
#import "NSDictionary+PEAdditions.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PEUtils.h"
#import "HCUtils.h"

NSString * const ROriginationDeviceIdKey            = @"originationdevice/id";
NSString * const ROriginationDeviceNameKey          = @"originationdevice/name";
NSString * const ROriginationDeviceIconImageNameKey = @"originationdevice/icon-image-name";
NSString * const ROriginationDeviceCreatedAtKey     = @"originationdevice/created-at";
NSString * const ROriginationDeviceDeletedAtKey     = @"originationdevice/deleted-at";
NSString * const ROriginationDeviceUpdatedAtKey     = @"originationdevice/updated-at";

@implementation ROriginationDeviceSerializer

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
  ROriginationDevice *originationDevice =
  [[ROriginationDevice alloc] initWithLocalMasterIdentifier:resDict[ROriginationDeviceIdKey]
                                           globalIdentifier:location
                                                  mediaType:mediaType
                                                  relations:relations
                                                  createdAt:[resDict dateSince1970ForKey:ROriginationDeviceCreatedAtKey]
                                                  deletedAt:[resDict dateSince1970ForKey:ROriginationDeviceDeletedAtKey]
                                                  updatedAt:[resDict dateSince1970ForKey:ROriginationDeviceUpdatedAtKey]
                                                       name:resDict[ROriginationDeviceNameKey]
                                              iconImageName:resDict[ROriginationDeviceIconImageNameKey]
                                              hasLocalImage:NO];
  return originationDevice;
}

@end
