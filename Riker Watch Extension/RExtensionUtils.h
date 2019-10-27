//
//  RExtensionUtils.h
//  riker-ios
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWatchUtils.h"

@class WKInterfaceLabel;

// Sugar for getting handle to extension delegate
#define EXT ((RExtensionDelegate *)[WKExtension sharedExtension].delegate)

FOUNDATION_EXPORT NSString * const MOVEMENTS_AND_SETTINGS_JSON_FILE_NAME;
FOUNDATION_EXPORT NSString * const WORKOUTS_JSON_FILE_NAME;
FOUNDATION_EXPORT NSString * const SETS_JSON_FILE_NAME;
FOUNDATION_EXPORT NSString * const BMLS_JSON_FILE_NAME;

@interface RExtensionUtils : NSObject

+ (void)setTextOrHideLabel:(WKInterfaceLabel *)label
                      text:(NSString *)text;

+ (void)persistPayload:(NSDictionary *)payload;

+ (NSNumber *)unixTimeFromDate:(NSDate *)date;

+ (BOOL)deleteEntity:(NSDictionary *)entityDict
         entityIndex:(NSInteger)entityIndex
    entitiesFileName:(NSString *)entitiesFileName
         entitiesKey:(NSString *)entitiesKey;

+ (NSDateFormatter *)dayOfWeekFormatter;

+ (NSDateFormatter *)dateTimeFormatter;

+ (NSDateFormatter *)dateFormatter;

+ (NSDate *)dateFromDict:(NSDictionary *)dictionary key:(NSString *)key;

+ (NSString *)absolutePathOfDocumentsFileWithFilename:(NSString *)filename;

+ (NSMutableDictionary *)dictionaryFromDocumentsFolderWithFilename:(NSString *)filename;

+ (NSMutableDictionary *)dictionaryFromAbsoluteFilePath:(NSString *)filepath;

+ (void)saveDictionary:(NSDictionary *)dictionary toDocumentsFolderWithFilename:(NSString *)filename;

+ (NSString *)saveToWatchEntity:(NSMutableDictionary *)entity entityType:(NSString *)entityType;

+ (void)reloadComplications;

+ (void)extendComplications;

+ (void)pruneOldestIfTooManyEntities:(NSMutableArray *)entities;

+ (void)extendSetsTimelineWithLoggedAt:(NSDate *)loggedAt
                          movementName:(NSString *)movementName
                   movementVariantName:(NSString *)movementVariantName
                               numReps:(NSInteger)numReps
                                weight:(NSDecimalNumber *)weight
                         weightUomName:(NSString *)weightUomName
                             toFailure:(BOOL)toFailure
                             negatives:(BOOL)negatives
                              fileName:(NSString *)fileName;

+ (void)extendBmlsWithLoggedAt:(NSDate *)loggedAt
                       bmlType:(RBmlType)bmlType
                         title:(NSString *)title
                         value:(NSDecimalNumber *)value
                      uomLabel:(NSString *)uomLabel
                      fileName:(NSString *)fileName;

@end
