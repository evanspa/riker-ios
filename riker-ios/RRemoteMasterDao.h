//
//  RRmoteMasterDao.h
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

@class RSet;
@class RBodyMeasurementLog;
@class PELMUser;
@class RUserSettings;

@protocol RRemoteMasterDao <PERemoteMasterDao>

#pragma mark - Movement Operations

- (void)fetchMovementWithGlobalId:(NSString *)globalId
                  ifModifiedSince:(NSDate *)ifModifiedSince
                          timeout:(NSInteger)timeout
                  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Movement Variant Operations

- (void)fetchMovementVariantWithGlobalId:(NSString *)globalId
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                               forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - User Settings Operations

- (void)saveExistingUserSettings:(RUserSettings *)userSettings
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchUserSettingsWithGlobalId:(NSString *)globalId
                      ifModifiedSince:(NSDate *)ifModifiedSince
                              timeout:(NSInteger)timeout
                      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                            forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Set Operations

- (void)saveNewSet:(RSet *)set
           forUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingSet:(RSet *)set
                timeout:(NSInteger)timeout
        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteSet:(RSet *)set
          timeout:(NSInteger)timeout
  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchSetWithGlobalId:(NSString *)globalId
             ifModifiedSince:(NSDate *)ifModifiedSince
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Body Measurement Log Operations

- (void)saveNewBml:(RBodyMeasurementLog *)bml
           forUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingBml:(RBodyMeasurementLog *)bml
                timeout:(NSInteger)timeout
        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteBml:(RBodyMeasurementLog *)bml
          timeout:(NSInteger)timeout
  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchBmlWithGlobalId:(NSString *)globalId
             ifModifiedSince:(NSDate *)ifModifiedSince
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

@end
