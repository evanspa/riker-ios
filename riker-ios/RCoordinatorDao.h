//
//  RCoordinatorDao.h
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PELMDefs.h"
#import "PEUserCoordinatorDao.h"
#import "RLocalDao.h"

@class HCCharset;
@class PELMUser;

@protocol RCoordinatorDao <RLocalDao>

#pragma mark - Initializers

- (id)initWithSqliteDataFilePath:(NSString *)sqliteDataFilePath
      localDatabaseCreationError:(PELMDaoErrorBlk)errorBlk
  timeoutForMainThreadOperations:(NSInteger)timeout
                   acceptCharset:(HCCharset *)acceptCharset
                  acceptLanguage:(NSString *)acceptLanguage
              contentTypeCharset:(HCCharset *)contentTypeCharset
                      authScheme:(NSString *)authScheme
              authTokenParamName:(NSString *)authTokenParamName
                       authToken:(NSString *)authToken
             errorMaskHeaderName:(NSString *)errorMaskHeaderName
      establishSessionHeaderName:(NSString *)establishHeaderSessionName
     authTokenResponseHeaderName:(NSString *)authTokenHeaderName
       ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
     ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
     loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
   accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
    bundleHoldingApiJsonResource:(NSBundle *)bundle
       nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
                 apiResMtVersion:(NSString *)apiResMtVersion
           changelogResMtVersion:(NSString *)changelogResMtVersion
                userResMtVersion:(NSString *)userResMtVersion
         bodySegmentResMtVersion:(NSString *)bodySegmentResMtVersion
         muscleGroupResMtVersion:(NSString *)muscleGroupResMtVersion
              muscleResMtVersion:(NSString *)muscleResMtVersion
         muscleAliasResMtVersion:(NSString *)muscleAliasResMtVersion
            movementResMtVersion:(NSString *)movementResMtVersion
       movementAliasResMtVersion:(NSString *)movementAliasResMtVersion
     movementVariantResMtVersion:(NSString *)movementVariantResMtVersion
   originationDeviceResMtVersion:(NSString *)originationDeviceResMtVersion
        userSettingsResMtVersion:(NSString *)userSettingsResMtVersion
  bodyMeasurementLogResMtVersion:(NSString *)bodyMeasurementLogResMtVersion
                 setResMtVersion:(NSString *)setResMtVersion
               authTokenDelegate:(id<PEAuthTokenDelegate>)authTokenDelegate
        allowInvalidCertificates:(BOOL)allowInvalidCertificates;

#pragma mark - Getters

- (id<PEUserCoordinatorDao>)userCoordinatorDao;

- (NSString *)apiResMtVersion;
- (NSString *)changelogResMtVersion;
- (NSString *)userResMtVersion;
- (NSString *)bodySegmentResMtVersion;
- (NSString *)muscleGroupResMtVersion;
- (NSString *)muscleResMtVersion;
- (NSString *)muscleAliasResMtVersion;
- (NSString *)movementResMtVersion;
- (NSString *)movementAliasResMtVersion;
- (NSString *)movementVariantResMtVersion;
- (NSString *)originationDeviceResMtVersion;
- (NSString *)userSettingsResMtVersion;
- (NSString *)bodyMeasurementLogResMtVersion;
- (NSString *)setResMtVersion;

#pragma mark - Flushing All Unsynced Edits to Remote Master

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(PELMUser *)user
                                entityNotFoundBlk:(void(^)(float))entityNotFoundBlk
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                     forbiddenBlk:(void(^)(float))forbiddenBlk
                                          allDone:(void(^)(NSInteger, NSInteger, NSInteger, NSInteger))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Unsynced Entities Check

- (BOOL)doesUserHaveAnyUnsyncedEntities:(PELMUser *)user;

- (BOOL)isUserSettingsUnsynced:(PELMUser *)user;

#pragma mark - Movement

- (void)fetchMovementWithGlobalId:(NSString *)globalIdentifier
                  ifModifiedSince:(NSDate *)ifModifiedSince
                          forUser:(PELMUser *)user
              notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                       successBlk:(void(^)(RMovement *))successBlk
               remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
               tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
              addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                     forbiddenBlk:(void(^)(void))forbiddenBlk;

- (void)fetchAndSaveNewMovementWithGlobalId:(NSString *)globalIdentifier
                                    forUser:(PELMUser *)user
                        notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                             addlSuccessBlk:(void(^)(RMovement *))addlSuccessBlk
                         remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                         tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                        addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                               forbiddenBlk:(void(^)(void))forbiddenBlk
                                      error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Movement Variant

- (void)fetchMovementVariantWithGlobalId:(NSString *)globalIdentifier
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 forUser:(PELMUser *)user
                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              successBlk:(void(^)(RMovementVariant *))successBlk
                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            forbiddenBlk:(void(^)(void))forbiddenBlk;

- (void)fetchAndSaveNewMovementVariantWithGlobalId:(NSString *)globalIdentifier
                                           forUser:(PELMUser *)user
                               notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                    addlSuccessBlk:(void(^)(RMovementVariant *))addlSuccessBlk
                                remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                      forbiddenBlk:(void(^)(void))forbiddenBlk
                                             error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - User Settings

- (void)flushUnsyncedChangesToUserSettings:(RUserSettings *)userSettings
                                   forUser:(PELMUser *)user
                   writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                       notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                            addlSuccessBlk:(void(^)(void))addlSuccessBlk
                    addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                    addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                       addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                          addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                     error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncUserSettingsImmediate:(RUserSettings *)userSettings
                                              forUser:(PELMUser *)user
                              writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                       addlSuccessBlk:(void(^)(void))addlSuccessBlk
                               addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                               addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                                   addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                     addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                                error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchUserSettingsWithGlobalId:(NSString *)globalIdentifier
                      ifModifiedSince:(NSDate *)ifModifiedSince
                              forUser:(PELMUser *)user
                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                           successBlk:(void(^)(RUserSettings *))successBlk
                   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                   tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                         forbiddenBlk:(void(^)(void))forbiddenBlk;

#pragma mark - Set

- (RSet *)setWithNumReps:(NSNumber *)numReps
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
         correlationGuid:(NSString *)correlationGuid;

- (void)saveNewAndSyncImmediateSet:(RSet *)set
                           forUser:(PELMUser *)user
           writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
               notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                    addlSuccessBlk:(void(^)(void))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                  addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToSet:(RSet *)set
                          forUser:(PELMUser *)user
          writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
              notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                   addlSuccessBlk:(void(^)(void))addlSuccessBlk
           addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
           addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
               addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
              addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncSetImmediate:(RSet *)set
                                     forUser:(PELMUser *)user
                     writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk                             
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                       error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteSet:(RSet *)set
          forUser:(PELMUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
   addlSuccessBlk:(void(^)(void))addlSuccessBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
   remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
     forbiddenBlk:(void(^)(void))forbiddenBlk
            error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchSetWithGlobalId:(NSString *)globalIdentifier
             ifModifiedSince:(NSDate *)ifModifiedSince
                     forUser:(PELMUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                  successBlk:(void(^)(RSet *))successBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                forbiddenBlk:(void(^)(void))forbiddenBlk;

- (void)fetchAndSaveNewSetWithGlobalId:(NSString *)globalIdentifier
                               forUser:(PELMUser *)user
               writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(RSet *))addlSuccessBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                          forbiddenBlk:(void(^)(void))forbiddenBlk
                                 error:(PELMDaoErrorBlk)errorBlk;

#pragma mark - Body Measurement Log

- (RBodyMeasurementLog *)bmlWithBodyWeight:(NSDecimalNumber *)bodyWeight
                             bodyWeightUom:(NSNumber *)bodyWeightUom
                                   armSize:(NSDecimalNumber *)armSize
                                  calfSize:(NSDecimalNumber *)calfSize
                                 chestSize:(NSDecimalNumber *)chestSize
                                   sizeUom:(NSNumber *)sizeUom
                                  neckSize:(NSDecimalNumber *)neckSize
                                 waistSize:(NSDecimalNumber *)waistSize
                                 thighSize:(NSDecimalNumber *)thighSize
                               forearmSize:(NSDecimalNumber *)forearmSize
                                  loggedAt:(NSDate *)loggedAt
                       originationDeviceId:(NSNumber *)originationDeviceId
                                importedAt:(NSDate *)importedAt;

- (void)saveNewAndSyncImmediateBml:(RBodyMeasurementLog *)bml
                           forUser:(PELMUser *)user
           writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
               notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                    addlSuccessBlk:(void(^)(void))addlSuccessBlk
            addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
            addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                  addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                             error:(PELMDaoErrorBlk)errorBlk;

- (void)flushUnsyncedChangesToBml:(RBodyMeasurementLog *)bml
                          forUser:(PELMUser *)user
          writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
              notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                   addlSuccessBlk:(void(^)(void))addlSuccessBlk
           addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
           addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
               addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
              addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                 addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                            error:(PELMDaoErrorBlk)errorBlk;

- (void)markAsDoneEditingAndSyncBmlImmediate:(RBodyMeasurementLog *)bml
                                     forUser:(PELMUser *)user
                     writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))addlSuccessBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)addlRemoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))addlTempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))addlRemoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                       error:(PELMDaoErrorBlk)errorBlk;

- (void)deleteBml:(RBodyMeasurementLog *)bml
          forUser:(PELMUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
   addlSuccessBlk:(void(^)(void))addlSuccessBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
   remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
     forbiddenBlk:(void(^)(void))forbiddenBlk
            error:(PELMDaoErrorBlk)errorBlk;

- (void)fetchBmlWithGlobalId:(NSString *)globalIdentifier
             ifModifiedSince:(NSDate *)ifModifiedSince
                     forUser:(PELMUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                  successBlk:(void(^)(RBodyMeasurementLog *))successBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                forbiddenBlk:(void(^)(void))forbiddenBlk;

- (void)fetchAndSaveNewBmlWithGlobalId:(NSString *)globalIdentifier
                               forUser:(PELMUser *)user
               writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(RBodyMeasurementLog *))addlSuccessBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                          forbiddenBlk:(void(^)(void))forbiddenBlk
                                 error:(PELMDaoErrorBlk)errorBlk;

@end
