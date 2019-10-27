//
//  RRestRemoteMasterDao.m
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RRestRemoteMasterDao.h"
#import "HCUtils.h"
#import "RKnownMediaTypes.h"
#import "RErrorDomainsAndCodes.h"
#import "RRemoteDaoErrorDomains.h"
#import "RBodySegmentSerializer.h"
#import "RMuscleGroupSerializer.h"
#import "RMuscleSerializer.h"
#import "RMuscleAliasSerializer.h"
#import "RMovementSerializer.h"
#import "RMovementAliasSerializer.h"
#import "RMovementVariantSerializer.h"
#import "ROriginationDeviceSerializer.h"
#import "RUserSettingsSerializer.h"
#import "RBodyMeasurementLogSerializer.h"
#import "RSetSerializer.h"
#import "PELMUser.h"
#import "RSet.h"
#import "RBodyMeasurementLog.h"
#import "HCRelationExecutor.h"
#import "RUserSettings.h"
#import "HCResource.h"

@implementation RRestRemoteMasterDao {
  RBodySegmentSerializer *_bodySegmentSerializer;
  RMuscleGroupSerializer *_muscleGroupSerializer;
  RMuscleSerializer *_muscleSerializer;
  RMuscleAliasSerializer *_muscleAliasSerializer;
  RMovementSerializer *_movementSerializer;
  RMovementAliasSerializer *_movementAliasSerializer;
  RMovementVariantSerializer *_movementVariantSerializer;
  ROriginationDeviceSerializer *_originationDeviceSerializer;
  RUserSettingsSerializer *_userSettingsSerializer;
  RBodyMeasurementLogSerializer *_bodyMeasurementLogSerializer;
  RSetSerializer *_setSerializer;
}

- (id)initWithAcceptCharset:(HCCharset *)acceptCharset
             acceptLanguage:(NSString *)acceptLanguage
         contentTypeCharset:(HCCharset *)contentTypeCharset
                 authScheme:(NSString *)authScheme
         authTokenParamName:(NSString *)authTokenParamName
                  authToken:(NSString *)authToken
        errorMaskHeaderName:(NSString *)errorMaskHeaderName
 establishSessionHeaderName:(NSString *)establishHeaderSessionName
        authTokenHeaderName:(NSString *)authTokenHeaderName
  ifModifiedSinceHeaderName:(NSString *)ifModifiedSinceHeaderName
ifUnmodifiedSinceHeaderName:(NSString *)ifUnmodifiedSinceHeaderName
loginFailedReasonHeaderName:(NSString *)loginFailedReasonHeaderName
accountClosedReasonHeaderName:(NSString *)accountClosedReasonHeaderName
bundleHoldingApiJsonResource:(NSBundle *)bundle
  nameOfApiJsonResourceFile:(NSString *)apiResourceFileName
            apiResMtVersion:(NSString *)apiResMtVersion
             userSerializer:(PELMUserSerializer *)userSerializer
        changelogSerializer:(PEChangelogSerializer *)changelogSerializer
            loginSerializer:(PELoginSerializer *)loginSerializer
           logoutSerializer:(PELogoutSerializer *)logoutSerializer
resendVerificationEmailSerializer:(PEResendVerificationEmailSerializer *)resendVerificationEmailSerializer
    passwordResetSerializer:(PEPasswordResetSerializer *)passwordResetSerializer
      stripeTokenSerializer:(PELMStripeTokenSerializer *)stripeTokenSerializer
      bodySegmentSerializer:(RBodySegmentSerializer *)bodySegmentSerializer
      muscleGroupSerializer:(RMuscleGroupSerializer *)muscleGroupSerializer
           muscleSerializer:(RMuscleSerializer *)muscleSerializer
      muscleAliasSerializer:(RMuscleAliasSerializer *)muscleAliasSerializer
         movementSerializer:(RMovementSerializer *)movementSerializer
    movementAliasSerializer:(RMovementAliasSerializer *)movementAliasSerializer
  movementVariantSerializer:(RMovementVariantSerializer *)movementVariantSerializer
originationDeviceSerializer:(ROriginationDeviceSerializer *)originationDeviceSerializer
     userSettingsSerializer:(RUserSettingsSerializer *)userSettingsSerializer
bodyMeasurementLogSerializer:(RBodyMeasurementLogSerializer *)bodyMeasurementLogSerializer
              setSerializer:(RSetSerializer *)setSerializer
   allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super initWithAcceptCharset:acceptCharset
                       acceptLanguage:acceptLanguage
                   contentTypeCharset:contentTypeCharset
                           authScheme:authScheme
                   authTokenParamName:authTokenParamName
                            authToken:authToken
                  errorMaskHeaderName:errorMaskHeaderName
           establishSessionHeaderName:establishHeaderSessionName
                  authTokenHeaderName:authTokenHeaderName
            ifModifiedSinceHeaderName:ifModifiedSinceHeaderName
          ifUnmodifiedSinceHeaderName:ifUnmodifiedSinceHeaderName
          loginFailedReasonHeaderName:loginFailedReasonHeaderName
        accountClosedReasonHeaderName:accountClosedReasonHeaderName
         bundleHoldingApiJsonResource:bundle
            nameOfApiJsonResourceFile:apiResourceFileName
                      apiResMtVersion:apiResMtVersion
                       userSerializer:userSerializer
                  changelogSerializer:changelogSerializer
                      loginSerializer:loginSerializer
                     logoutSerializer:logoutSerializer
    resendVerificationEmailSerializer:resendVerificationEmailSerializer
              passwordResetSerializer:passwordResetSerializer
                stripeTokenSerializer:stripeTokenSerializer
             allowInvalidCertificates:allowInvalidCertificates
             clientFaultedErrorDomain:RClientFaultedErrorDomain
               userFaultedErrorDomain:RUserFaultedErrorDomain
             systemFaultedErrorDomain:RSystemFaultedErrorDomain
               connFaultedErrorDomain:RConnFaultedErrorDomain
                     restApiRelations:[HCUtils relsFromLocalHalJsonResource:bundle
                                                                   fileName:apiResourceFileName
                                                       resourceApiMediaType:[RKnownMediaTypes apiMediaTypeWithVersion:apiResMtVersion]]];
  if (self) {
    _bodySegmentSerializer = bodySegmentSerializer;
    _muscleGroupSerializer = muscleGroupSerializer;
    _muscleSerializer = muscleSerializer;
    _muscleAliasSerializer = muscleAliasSerializer;
    _movementSerializer = movementSerializer;
    _movementAliasSerializer = movementAliasSerializer;
    _movementVariantSerializer = movementVariantSerializer;
    _originationDeviceSerializer = originationDeviceSerializer;
    _setSerializer = setSerializer;
    _bodyMeasurementLogSerializer = bodyMeasurementLogSerializer;
    _userSettingsSerializer = userSettingsSerializer;
  }
  return self;
}

#pragma mark - Movement Operations

- (void)fetchMovementWithGlobalId:(NSString *)globalId
                  ifModifiedSince:(NSDate *)ifModifiedSince
                          timeout:(NSInteger)timeout
                  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_movementSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

#pragma mark - Movement Variant Operations

- (void)fetchMovementVariantWithGlobalId:(NSString *)globalId
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 timeout:(NSInteger)timeout
                         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                               forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_movementVariantSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

#pragma mark - User Settings Operations

- (void)saveExistingUserSettings:(RUserSettings *)userSettings
                         timeout:(NSInteger)timeout
                 remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                       forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
               completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForURLString:userSettings.globalIdentifier
                        resourceModelParam:userSettings
                           paramSerializer:_userSettingsSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newPutSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:userSettings]];
}

- (void)fetchUserSettingsWithGlobalId:(NSString *)globalId
                      ifModifiedSince:(NSDate *)ifModifiedSince
                              timeout:(NSInteger)timeout
                      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                         authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                            forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
                    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_userSettingsSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

#pragma mark - Set Operations

- (void)saveNewSet:(RSet *)set
           forUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToURLString:[user setsUri]
       resourceModelParam:set
               serializer:_setSerializer
                  timeout:timeout
          remoteStoreBusy:busyHandler
             authRequired:authRequired
                forbidden:forbidden
        completionHandler:complHandler
             otherHeaders:@{}];
}

- (void)saveExistingSet:(RSet *)set
                timeout:(NSInteger)timeout
        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForURLString:set.globalIdentifier
                        resourceModelParam:set
                           paramSerializer:_setSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newPutSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:set]];
}

- (void)deleteSet:(RSet *)set
          timeout:(NSInteger)timeout
  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfURLString:set.globalIdentifier
                     wouldBeTargetSerializer:_setSerializer
                                asynchronous:YES
                             completionQueue:self.serialQueue
                               authorization:[self authorization]
                                     success:[self newDeleteSuccessBlk:complHandler]
                                 redirection:[self newRedirectionBlk:complHandler]
                                 clientError:[self newClientErrBlk:complHandler]
                              forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                      authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                 serverError:[self newServerErrBlk:complHandler]
                            unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                           connectionFailure:[self newConnFailureBlk:complHandler]
                                     timeout:timeout
                                otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:set]];
}

- (void)fetchSetWithGlobalId:(NSString *)globalId
             ifModifiedSince:(NSDate *)ifModifiedSince
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_setSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

#pragma mark - Body Measurement Log Operations

- (void)saveNewBml:(RBodyMeasurementLog *)bml
           forUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
         forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self doPostToURLString:[user bmlsUri]
       resourceModelParam:bml
               serializer:_bodyMeasurementLogSerializer
                  timeout:timeout
          remoteStoreBusy:busyHandler
             authRequired:authRequired
                forbidden:forbidden
        completionHandler:complHandler
             otherHeaders:@{}];
}

- (void)saveExistingBml:(RBodyMeasurementLog *)bml
                timeout:(NSInteger)timeout
        remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
           authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
              forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
      completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doPutForURLString:bml.globalIdentifier
                        resourceModelParam:bml
                           paramSerializer:_bodyMeasurementLogSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newPutSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                              otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:bml]];
}

- (void)deleteBml:(RBodyMeasurementLog *)bml
          timeout:(NSInteger)timeout
  remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
     authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doDeleteOfURLString:bml.globalIdentifier
                     wouldBeTargetSerializer:_bodyMeasurementLogSerializer
                                asynchronous:YES
                             completionQueue:self.serialQueue
                               authorization:[self authorization]
                                     success:[self newDeleteSuccessBlk:complHandler]
                                 redirection:[self newRedirectionBlk:complHandler]
                                 clientError:[self newClientErrBlk:complHandler]
                              forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                      authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                                 serverError:[self newServerErrBlk:complHandler]
                            unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                           connectionFailure:[self newConnFailureBlk:complHandler]
                                     timeout:timeout
                                otherHeaders:[self addFpIfUnmodifiedSinceHeaderToHeader:@{} entity:bml]];
}

- (void)fetchBmlWithGlobalId:(NSString *)globalId
             ifModifiedSince:(NSDate *)ifModifiedSince
                     timeout:(NSInteger)timeout
             remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   forbidden:(PELMRemoteMasterForbiddenBlk)forbidden
           completionHandler:(PELMRemoteMasterCompletionHandler)complHandler {
  [self.relationExecutor doGetForURLString:globalId
                                parameters:nil
                           ifModifiedSince:nil
                          targetSerializer:_bodyMeasurementLogSerializer
                              asynchronous:YES
                           completionQueue:self.serialQueue
                             authorization:[self authorization]
                                   success:[self newGetSuccessBlk:complHandler]
                               redirection:[self newRedirectionBlk:complHandler]
                               clientError:[self newClientErrBlk:complHandler]
                            forbiddenError:[RRestRemoteMasterDao forbiddenBlk:forbidden]
                    authenticationRequired:[RRestRemoteMasterDao toHCAuthReqdBlk:authRequired]
                               serverError:[self newServerErrBlk:complHandler]
                          unavailableError:[RRestRemoteMasterDao serverUnavailableBlk:busyHandler]
                         connectionFailure:[self newConnFailureBlk:complHandler]
                                   timeout:timeout
                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              otherHeaders:[self addDateHeaderToHeaders:@{}
                                                             headerName:self.ifModifiedSinceHeaderName
                                                                  value:ifModifiedSince]];
}

@end
