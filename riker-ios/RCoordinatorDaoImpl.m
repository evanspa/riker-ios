//
//  RCoordinatorDaoImpl.m
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RCoordinatorDaoImpl.h"
#import "RRemoteMasterDao.h"
#import "RRestRemoteMasterDao.h"
#import "RKnownMediaTypes.h"

#import "PEUtils.h"
#import "HCRelation.h"
#import "HCMediaType.h"
#import "RErrorDomainsAndCodes.h"

#import "RSet.h"
#import "RBodyMeasurementLog.h"
#import "RUserSettings.h"
#import "RChangeLog.h"

#import "PELMUser.h"
#import "PELMUtils.h"
#import "PELMNotificationUtils.h"
#import "PEUserCoordinatorDaoImpl.h"
#import "PEResendVerificationEmailSerializer.h"
#import "PEPasswordResetSerializer.h"
#import "PELMStripeTokenSerializer.h"
#import "PEChangelogSerializer.h"
#import "PELMUserSerializer.h"
#import "PELoginSerializer.h"
#import "PELogoutSerializer.h"

#import "RBodySegmentSerializer.h"
#import "RMuscleGroupSerializer.h"
#import "RMuscleSerializer.h"
#import "RMuscleAliasSerializer.h"
#import "RMovementSerializer.h"
#import "RMovementAliasSerializer.h"
#import "RMovementVariantSerializer.h"
#import "ROriginationDeviceSerializer.h"
#import "RUserSettingsSerializer.h"
#import "RSetSerializer.h"
#import "RBodyMeasurementLogSerializer.h"

@implementation RCoordinatorDaoImpl {
  id<RRemoteMasterDao> _remoteMasterDao;
  NSInteger _timeout;
  NSString *_authScheme;
  NSString *_authTokenParamName;
  NSString *_apiResMtVersion;
  NSString *_changelogResMtVersion;
  NSString *_userResMtVersion;
  NSString *_bodySegmentResMtVersion;
  NSString *_muscleGroupResMtVersion;
  NSString *_muscleResMtVersion;
  NSString *_muscleAliasResMtVersion;
  NSString *_movementResMtVersion;
  NSString *_movementAliasResMtVersion;
  NSString *_movementVariantResMtVersion;
  NSString *_originationDeviceResMtVersion;
  NSString *_userSettingsResMtVersion;
  NSString *_bodyMeasurementLogResMtVersion;
  NSString *_setResMtVersion;
  id<PEUserCoordinatorDao> _userCoordDao;
}

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
        allowInvalidCertificates:(BOOL)allowInvalidCertificates {
  self = [super initWithSqliteDataFilePath:sqliteDataFilePath];
  if (self) {
    _timeout = timeout;
    _authScheme = authScheme;
    _authTokenParamName = authTokenParamName;
    _apiResMtVersion = apiResMtVersion;
    _changelogResMtVersion = changelogResMtVersion;
    _userResMtVersion = userResMtVersion;
    _bodySegmentResMtVersion = bodySegmentResMtVersion;
    _muscleGroupResMtVersion = muscleGroupResMtVersion;
    _muscleResMtVersion = muscleResMtVersion;
    _muscleAliasResMtVersion = muscleAliasResMtVersion;
    _movementResMtVersion = movementResMtVersion;
    _movementAliasResMtVersion = movementAliasResMtVersion;
    _movementVariantResMtVersion = movementVariantResMtVersion;
    _originationDeviceResMtVersion = originationDeviceResMtVersion;
    _userSettingsResMtVersion = userSettingsResMtVersion;
    _bodyMeasurementLogResMtVersion = bodyMeasurementLogResMtVersion;
    _setResMtVersion = setResMtVersion;
    RBodySegmentSerializer *bodySegmentSerializer =
    [[RBodySegmentSerializer alloc] initWithMediaType:[RKnownMediaTypes bodySegmentMediaTypeWithVersion:_bodySegmentResMtVersion]
                                              charset:acceptCharset
                      serializersForEmbeddedResources:@{}
                          actionsForEmbeddedResources:@{}];
    RMuscleGroupSerializer *muscleGroupSerializer =
    [[RMuscleGroupSerializer alloc] initWithMediaType:[RKnownMediaTypes muscleGroupMediaTypeWithVersion:_muscleGroupResMtVersion]
                                              charset:acceptCharset
                      serializersForEmbeddedResources:@{}
                          actionsForEmbeddedResources:@{}];
    RMuscleSerializer *muscleSerializer =
    [[RMuscleSerializer alloc] initWithMediaType:[RKnownMediaTypes muscleMediaTypeWithVersion:_muscleResMtVersion]
                                         charset:acceptCharset
                 serializersForEmbeddedResources:@{}
                     actionsForEmbeddedResources:@{}];
    RMuscleAliasSerializer *muscleAliasSerializer =
    [[RMuscleAliasSerializer alloc] initWithMediaType:[RKnownMediaTypes muscleAliasMediaTypeWithVersion:_muscleAliasResMtVersion]
                                              charset:acceptCharset
                      serializersForEmbeddedResources:@{}
                          actionsForEmbeddedResources:@{}];
    RMovementSerializer *movementSerializer =
    [[RMovementSerializer alloc] initWithMediaType:[RKnownMediaTypes movementMediaTypeWithVersion:_movementResMtVersion]
                                           charset:acceptCharset
                   serializersForEmbeddedResources:@{}
                       actionsForEmbeddedResources:@{}];
    RMovementAliasSerializer *movementAliasSerializer =
    [[RMovementAliasSerializer alloc] initWithMediaType:[RKnownMediaTypes movementAliasMediaTypeWithVersion:_movementAliasResMtVersion]
                                                charset:acceptCharset
                        serializersForEmbeddedResources:@{}
                            actionsForEmbeddedResources:@{}];
    RMovementVariantSerializer *movementVariantSerializer =
    [[RMovementVariantSerializer alloc] initWithMediaType:[RKnownMediaTypes movementVariantMediaTypeWithVersion:_movementVariantResMtVersion]
                                                  charset:acceptCharset
                          serializersForEmbeddedResources:@{}
                              actionsForEmbeddedResources:@{}];
    ROriginationDeviceSerializer *originationDeviceSerializer =
    [[ROriginationDeviceSerializer alloc] initWithMediaType:[RKnownMediaTypes originationDeviceMediaTypeWithVersion:_originationDeviceResMtVersion]
                                                    charset:acceptCharset
                            serializersForEmbeddedResources:@{}
                                actionsForEmbeddedResources:@{}];
    RUserSettingsSerializer *userSettingsSerializer =
    [[RUserSettingsSerializer alloc] initWithMediaType:[RKnownMediaTypes userSettingsMediaTypeWithVersion:_userSettingsResMtVersion]
                                               charset:acceptCharset
                       serializersForEmbeddedResources:@{}
                           actionsForEmbeddedResources:@{}];
    RSetSerializer *setSerializer =
    [[RSetSerializer alloc] initWithMediaType:[RKnownMediaTypes setMediaTypeWithVersion:_setResMtVersion]
                                      charset:acceptCharset
              serializersForEmbeddedResources:@{}
                  actionsForEmbeddedResources:@{}];
    RBodyMeasurementLogSerializer *bmlSerializer =
    [[RBodyMeasurementLogSerializer alloc] initWithMediaType:[RKnownMediaTypes bodyMeasurementLogMediaTypeWithVersion:_bodyMeasurementLogResMtVersion]
                                                     charset:acceptCharset
                             serializersForEmbeddedResources:@{}
                                 actionsForEmbeddedResources:@{}];
    PELMUserSerializer *userSerializer =
    [self userSerializerWithCharset:acceptCharset
              bodySegmentSerializer:bodySegmentSerializer
              muscleGroupSerializer:muscleGroupSerializer
                   muscleSerializer:muscleSerializer
              muscleAliasSerializer:muscleAliasSerializer
                 movementSerializer:movementSerializer
            movementAliasSerializer:movementAliasSerializer
          movementVariantSerializer:movementVariantSerializer
        originationDeviceSerializer:originationDeviceSerializer
             userSettingsSerializer:userSettingsSerializer
       bodyMeasurementLogSerializer:bmlSerializer
                      setSerializer:setSerializer];
    PEChangelogSerializer *changelogSerializer =
    [self changelogSerializerWithCharset:acceptCharset
                          userSerializer:userSerializer
                   bodySegmentSerializer:bodySegmentSerializer
                   muscleGroupSerializer:muscleGroupSerializer
                        muscleSerializer:muscleSerializer
                   muscleAliasSerializer:muscleAliasSerializer
                      movementSerializer:movementSerializer
                 movementAliasSerializer:movementAliasSerializer
               movementVariantSerializer:movementVariantSerializer
             originationDeviceSerializer:originationDeviceSerializer
                  userSettingsSerializer:userSettingsSerializer
            bodyMeasurementLogSerializer:bmlSerializer
                           setSerializer:setSerializer];
    PELoginSerializer *loginSerializer =
    [[PELoginSerializer alloc] initWithMediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                         charset:acceptCharset
                                  userSerializer:userSerializer];
    PELogoutSerializer *logoutSerializer =
    [[PELogoutSerializer alloc] initWithMediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                          charset:acceptCharset
                  serializersForEmbeddedResources:@{}
                      actionsForEmbeddedResources:@{}];
    PEResendVerificationEmailSerializer *resendVerificationEmailSerializer =
    [[PEResendVerificationEmailSerializer alloc] initWithMediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                           charset:acceptCharset
                                   serializersForEmbeddedResources:@{}
                                       actionsForEmbeddedResources:@{}];
    PEPasswordResetSerializer *passwordResetSerializer =
    [[PEPasswordResetSerializer alloc] initWithMediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                                 charset:acceptCharset
                         serializersForEmbeddedResources:@{}
                             actionsForEmbeddedResources:@{}];
    PELMStripeTokenSerializer *stripeTokenSerializer =
    [[PELMStripeTokenSerializer alloc] initWithMediaType:[RKnownMediaTypes stripeTokenMediaTypeWithVersion:_userResMtVersion]
                                                 charset:acceptCharset
                         serializersForEmbeddedResources:@{}
                             actionsForEmbeddedResources:@{}];
    _remoteMasterDao =
    [[RRestRemoteMasterDao alloc] initWithAcceptCharset:acceptCharset
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
                                  bodySegmentSerializer:bodySegmentSerializer
                                  muscleGroupSerializer:muscleGroupSerializer
                                       muscleSerializer:muscleSerializer
                                  muscleAliasSerializer:muscleAliasSerializer
                                     movementSerializer:movementSerializer
                                movementAliasSerializer:movementAliasSerializer
                              movementVariantSerializer:movementVariantSerializer
                            originationDeviceSerializer:originationDeviceSerializer
                                 userSettingsSerializer:userSettingsSerializer
                           bodyMeasurementLogSerializer:bmlSerializer
                                          setSerializer:setSerializer
                               allowInvalidCertificates:allowInvalidCertificates];
    _userCoordDao =
    [[PEUserCoordinatorDaoImpl alloc] initWithRemoteMasterDao:_remoteMasterDao
                                                     localDao:self
                                                    userMaker:^ PELMUser * (NSString *name, NSString *email, NSString *password) {
                                                      return [PELMUser userWithName:name
                                                                              email:email
                                                                           password:password
                                                                          mediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]];
                                                    }
                                      timeoutForMainThreadOps:timeout
                                            authTokenDelegate:authTokenDelegate
                                       userFaultedErrorDomain:RUserFaultedErrorDomain
                                     systemFaultedErrorDomain:RSystemFaultedErrorDomain
                                       connFaultedErrorDomain:RConnFaultedErrorDomain
                                           signInAnyIssuesBit:RSignInAnyIssues
                                        signInInvalidEmailBit:RSignInInvalidEmail
                                    signInEmailNotProvidedBit:RSignInEmailNotProvided
                                      signInPwdNotProvidedBit:RSignInPasswordNotProvided
                                  signInInvalidCredentialsBit:RSignInInvalidCredentials
                                     sendPwdResetAnyIssuesBit:RSendPasswordResetAnyIssues
                                  sendPwdResetUnknownEmailBit:RSendPasswordResetUnknownEmail
                             sendPwdResetAccountUnverifiedBit:RSendPasswordUnverifiedAccount
                                          saveUsrAnyIssuesBit:RSaveUsrAnyIssues
                                       saveUsrInvalidEmailBit:RSaveUsrInvalidEmail
                                   saveUsrEmailNotProvidedBit:RSaveUsrEmailNotProvided
                                     saveUsrPwdNotProvidedBit:RSaveUsrPasswordNotProvided
                             saveUsrEmailAlreadyRegisteredBit:RSaveUsrEmailAlreadyRegistered
                             saveUsrConfirmPwdOnlyProvidedBit:RSaveUsrConfirmPasswordOnlyProvided
                              saveUsrConfirmPwdNotProvidedBit:RSaveUsrConfirmPasswordNotProvided
                           saveUsrCurrentPasswordIncorrectBit:RSaveUsrCurrentPasswordIncorrect
                             saveUsrPwdConfirmPwdDontMatchBit:RSaveUsrPasswordConfirmPasswordDontMatch
                                            changeLogRelation:PELMChangelogRelation];
  }
  return self;
}

#pragma mark - Helpers

- (PEChangelogSerializer *)changelogSerializerWithCharset:(HCCharset *)charset
                                           userSerializer:(PELMUserSerializer *)userSerializer
                                    bodySegmentSerializer:(RBodySegmentSerializer *)bodySegmentSerializer
                                    muscleGroupSerializer:(RMuscleGroupSerializer *)muscleGroupSerializer
                                         muscleSerializer:(RMuscleSerializer *)muscleSerializer
                                    muscleAliasSerializer:(RMuscleAliasSerializer *)muscleAliasSerializer
                                       movementSerializer:(RMovementSerializer *)movementSerializer
                                  movementAliasSerializer:(RMovementAliasSerializer *)movementAliasSerializer
                                movementVariantSerializer:(RMovementVariantSerializer *)movementVariantSerializer
                              originationDeviceSerializer:(ROriginationDeviceSerializer *)originationDeviceSerializer
                                   userSettingsSerializer:(RUserSettingsSerializer *)userSettingsSerializer
                             bodyMeasurementLogSerializer:(RBodyMeasurementLogSerializer *)bmlSerializer
                                            setSerializer:(RSetSerializer *)setSerializer {
  HCActionForEmbeddedResource actionForEmbeddedUser = ^(RChangeLog *changelog, id embeddedUser) {
    [changelog setUser:embeddedUser];
  };
  HCActionForEmbeddedResource actionForEmbeddedBodySegment = ^(RChangeLog *changelog, id embedded) {
    [changelog addBodySegment:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscleGroup = ^(RChangeLog *changelog, id embedded) {
    [changelog addMuscleGroup:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscle = ^(RChangeLog *changelog, id embedded) {
    [changelog addMuscle:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscleAlias = ^(RChangeLog *changelog, id embedded) {
    [changelog addMuscleAlias:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovement = ^(RChangeLog *changelog, id embedded) {
    [changelog addMovement:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovementAlias = ^(RChangeLog *changelog, id embedded) {
    [changelog addMovementAlias:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovementVariant = ^(RChangeLog *changelog, id embedded) {
    [changelog addMovementVariant:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedOriginationDevice = ^(RChangeLog *changelog, id embedded) {
    [changelog addOriginationDevice:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedSet = ^(RChangeLog *changelog, id embeddedSet) {
    [changelog addSet:embeddedSet];
  };
  HCActionForEmbeddedResource actionForEmbeddedBml = ^(RChangeLog *changelog, id embeddedBml) {
    [changelog addBodyMeasurementLog:embeddedBml];
  };
  HCActionForEmbeddedResource actionForEmbeddedSettings = ^(RChangeLog *changelog, id embeddedSettings) {
    [changelog setUserSettings:embeddedSettings];
  };
  return [[PEChangelogSerializer alloc] initWithMediaType:[RKnownMediaTypes changelogMediaTypeWithVersion:_changelogResMtVersion]
                                                  charset:charset
                          serializersForEmbeddedResources:@{[[userSerializer mediaType] description] : userSerializer,
                                                            [[bodySegmentSerializer mediaType] description] : bodySegmentSerializer,
                                                            [[muscleGroupSerializer mediaType] description] : muscleGroupSerializer,
                                                            [[muscleSerializer mediaType] description] : muscleSerializer,
                                                            [[muscleAliasSerializer mediaType] description] : muscleAliasSerializer,
                                                            [[movementSerializer mediaType] description] : movementSerializer,
                                                            [[movementAliasSerializer mediaType] description] : movementAliasSerializer,
                                                            [[movementVariantSerializer mediaType] description] : movementVariantSerializer,
                                                            [[originationDeviceSerializer mediaType] description] : originationDeviceSerializer,
                                                            [[userSettingsSerializer mediaType] description] : userSettingsSerializer,
                                                            [[setSerializer mediaType] description] : setSerializer,
                                                            [[bmlSerializer mediaType] description] : bmlSerializer}
                              actionsForEmbeddedResources:@{[[userSerializer mediaType] description] : actionForEmbeddedUser,
                                                            [[bodySegmentSerializer mediaType] description] : actionForEmbeddedBodySegment,
                                                            [[muscleGroupSerializer mediaType] description] : actionForEmbeddedMuscleGroup,
                                                            [[muscleSerializer mediaType] description] : actionForEmbeddedMuscle,
                                                            [[muscleAliasSerializer mediaType] description] : actionForEmbeddedMuscleAlias,
                                                            [[movementSerializer mediaType] description] : actionForEmbeddedMovement,
                                                            [[movementAliasSerializer mediaType] description] : actionForEmbeddedMovementAlias,
                                                            [[movementVariantSerializer mediaType] description] : actionForEmbeddedMovementVariant,
                                                            [[originationDeviceSerializer mediaType] description] : actionForEmbeddedOriginationDevice,
                                                            [[userSettingsSerializer mediaType] description] : actionForEmbeddedSettings,
                                                            [[setSerializer mediaType] description] : actionForEmbeddedSet,
                                                            [[bmlSerializer mediaType] description] : actionForEmbeddedBml}
                                           changelogClass:[RChangeLog class]];
}

- (PELMUserSerializer *)userSerializerWithCharset:(HCCharset *)charset
                            bodySegmentSerializer:(RBodySegmentSerializer *)bodySegmentSerializer
                            muscleGroupSerializer:(RMuscleGroupSerializer *)muscleGroupSerializer
                                 muscleSerializer:(RMuscleSerializer *)muscleSerializer
                            muscleAliasSerializer:(RMuscleAliasSerializer *)muscleAliasSerializer
                               movementSerializer:(RMovementSerializer *)movementSerializer
                          movementAliasSerializer:(RMovementAliasSerializer *)movementAliasSerializer
                        movementVariantSerializer:(RMovementVariantSerializer *)movementVariantSerializer
                      originationDeviceSerializer:(ROriginationDeviceSerializer *)originationDeviceSerializer
                           userSettingsSerializer:(RUserSettingsSerializer *)userSettingsSerializer
                     bodyMeasurementLogSerializer:(RBodyMeasurementLogSerializer *)bmlSerializer
                                    setSerializer:(RSetSerializer *)setSerializer {
  HCActionForEmbeddedResource actionForEmbeddedBodySegment = ^(PELMUser *user, id embedded) {
    [user addBodySegment:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscleGroup = ^(PELMUser *user, id embedded) {
    [user addMuscleGroup:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscle = ^(PELMUser *user, id embedded) {
    [user addMuscle:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMuscleAlias = ^(PELMUser *user, id embedded) {
    [user addMuscleAlias:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovement = ^(PELMUser *user, id embedded) {
    [user addMovement:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovementAlias = ^(PELMUser *user, id embedded) {
    [user addMovementAlias:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedMovementVariant = ^(PELMUser *user, id embedded) {
    [user addMovementVariant:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedOriginationDevice = ^(PELMUser *user, id embedded) {
    [user addOriginationDevice:embedded];
  };
  HCActionForEmbeddedResource actionForEmbeddedSet = ^(PELMUser *user, id embeddedSet) {
    [user addSet:embeddedSet];
  };
  HCActionForEmbeddedResource actionForEmbeddedBml = ^(PELMUser *user, id embeddedBml) {
    [user addBodyMeasurementLog:embeddedBml];
  };
  HCActionForEmbeddedResource actionForEmbeddedSettings = ^(PELMUser *user, id embeddedSettings) {
    [user setUserSettings:embeddedSettings];
  };
  return [[PELMUserSerializer alloc] initWithMediaType:[RKnownMediaTypes userMediaTypeWithVersion:_userResMtVersion]
                                               charset:charset
                       serializersForEmbeddedResources:@{[[bodySegmentSerializer mediaType] description] : bodySegmentSerializer,
                                                         [[muscleGroupSerializer mediaType] description] : muscleGroupSerializer,
                                                         [[muscleSerializer mediaType] description] : muscleSerializer,
                                                         [[muscleAliasSerializer mediaType] description] : muscleAliasSerializer,
                                                         [[movementSerializer mediaType] description] : movementSerializer,
                                                         [[movementAliasSerializer mediaType] description] : movementAliasSerializer,
                                                         [[movementVariantSerializer mediaType] description] : movementVariantSerializer,
                                                         [[originationDeviceSerializer mediaType] description] : originationDeviceSerializer,
                                                         [[userSettingsSerializer mediaType] description] : userSettingsSerializer,
                                                         [[setSerializer mediaType] description] : setSerializer,
                                                         [[bmlSerializer mediaType] description] : bmlSerializer}
                           actionsForEmbeddedResources:@{[[bodySegmentSerializer mediaType] description] : actionForEmbeddedBodySegment,
                                                         [[muscleGroupSerializer mediaType] description] : actionForEmbeddedMuscleGroup,
                                                         [[muscleSerializer mediaType] description] : actionForEmbeddedMuscle,
                                                         [[muscleAliasSerializer mediaType] description] : actionForEmbeddedMuscleAlias,
                                                         [[movementSerializer mediaType] description] : actionForEmbeddedMovement,
                                                         [[movementAliasSerializer mediaType] description] : actionForEmbeddedMovementAlias,
                                                         [[movementVariantSerializer mediaType] description] : actionForEmbeddedMovementVariant,
                                                         [[originationDeviceSerializer mediaType] description] : actionForEmbeddedOriginationDevice,
                                                         [[userSettingsSerializer mediaType] description] : actionForEmbeddedSettings,
                                                         [[setSerializer mediaType] description] : actionForEmbeddedSet,
                                                         [[bmlSerializer mediaType] description] : actionForEmbeddedBml}];
}

+ (void)invokeErrorBlocksForHttpStatusCode:(NSNumber *)httpStatusCode
                                     error:(NSError *)err
                        tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                            remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk {
  if (httpStatusCode) {
    if ([[err domain] isEqualToString:RUserFaultedErrorDomain]) {
      if ([err code] > 0) {
        if (remoteErrorBlk) remoteErrorBlk([err code]);
      } else {
        if (tempRemoteErrorBlk) tempRemoteErrorBlk();
      }
    } else {
      if (tempRemoteErrorBlk) tempRemoteErrorBlk();
    }
  } else {
    // if no http status code, then it was a connection failure, and that by nature is temporary
    if (tempRemoteErrorBlk) tempRemoteErrorBlk();
  }
}

#pragma mark - Getters

- (NSString *)authToken {
  return [_userCoordDao authToken];
}

- (id<PEUserCoordinatorDao>)userCoordinatorDao {
  return _userCoordDao;
}

- (NSString *)apiResMtVersion { return _apiResMtVersion; }
- (NSString *)changelogResMtVersion { return _changelogResMtVersion; }
- (NSString *)userResMtVersion { return _userResMtVersion; }
- (NSString *)bodySegmentResMtVersion { return _bodySegmentResMtVersion; }
- (NSString *)muscleGroupResMtVersion { return _muscleGroupResMtVersion; }
- (NSString *)muscleResMtVersion { return _muscleResMtVersion; }
- (NSString *)muscleAliasResMtVersion { return _muscleAliasResMtVersion; }
- (NSString *)movementResMtVersion { return _movementResMtVersion; }
- (NSString *)movementAliasResMtVersion { return _movementAliasResMtVersion; }
- (NSString *)movementVariantResMtVersion { return _movementVariantResMtVersion; }
- (NSString *)originationDeviceResMtVersion { return _originationDeviceResMtVersion; }
- (NSString *)userSettingsResMtVersion { return _userSettingsResMtVersion; }
- (NSString *)bodyMeasurementLogResMtVersion { return _bodyMeasurementLogResMtVersion; }
- (NSString *)setResMtVersion { return _setResMtVersion; }

#pragma mark - Flushing All Unsynced Edits to Remote Master

- (void)flushUnsyncedChangesToEntities:(NSArray *)entitiesToSync
                                syncer:(void(^)(PELMMainSupport *))syncerBlk {
  for (PELMMainSupport *entity in entitiesToSync) {
    if ([entity syncInProgress]) {
      syncerBlk(entity);
    }
  }
}

- (NSInteger)flushAllUnsyncedEditsToRemoteForUser:(PELMUser *)user
                                entityNotFoundBlk:(void(^)(float))entityNotFoundBlk
                                       successBlk:(void(^)(float))successBlk
                               remoteStoreBusyBlk:(void(^)(float, NSDate *))remoteStoreBusyBlk
                               tempRemoteErrorBlk:(void(^)(float))tempRemoteErrorBlk
                                   remoteErrorBlk:(void(^)(float, NSInteger))remoteErrorBlk
                                  authRequiredBlk:(void(^)(float))authRequiredBlk
                                     forbiddenBlk:(void(^)(float))forbiddenBlk
                                          allDone:(void(^)(NSInteger, NSInteger, NSInteger, NSInteger))allDoneBlk
                                            error:(PELMDaoErrorBlk)errorBlk {
  NSArray *markSetsAsSyncArray = [self markSetsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *setsToSync = markSetsAsSyncArray[0];
  NSNumber *numImportedSetsNotSyncedDueToNotAllowed = markSetsAsSyncArray[1];
  NSNumber *numImportedSetsNotSyncedDueToMaxExceeded = markSetsAsSyncArray[2];

  NSArray *markBmlsAsSyncArray = [self markBmlsAsSyncInProgressForUser:user error:errorBlk];
  NSArray *bmlsToSync = markBmlsAsSyncArray[0];
  NSNumber *numImportedBmlsNotSyncedDueToNotAllowed = markBmlsAsSyncArray[1];
  NSNumber *numImportedBmlsNotSyncedDueToMaxExceeded = markBmlsAsSyncArray[2];
  
  RUserSettings *userSettingsToSync = [self markUserSettingsAsSyncInProgressForUser:user error:errorBlk];
  NSInteger totalNumSetsToSync = [setsToSync count];
  NSInteger totalNumBmlsToSync = [bmlsToSync count];
  NSInteger userSettingsToSyncCount = 0;
  if ([PEUtils isNotNil:userSettingsToSync]) {
    userSettingsToSyncCount++;
  }
  NSInteger totalNumToSync = totalNumSetsToSync + totalNumBmlsToSync + userSettingsToSyncCount;
  if (totalNumToSync == 0) {
    allDoneBlk(numImportedSetsNotSyncedDueToNotAllowed.integerValue,
               numImportedSetsNotSyncedDueToMaxExceeded.integerValue,
               numImportedBmlsNotSyncedDueToNotAllowed.integerValue,
               numImportedBmlsNotSyncedDueToMaxExceeded.integerValue);
    return 0;
  }
  NSDecimalNumber *individualEntitySyncProgress = [[NSDecimalNumber one] decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld", (long)totalNumToSync]]];
  __block NSInteger totalSyncAttempted = 0;
  void (^incrementSyncAttemptedAndCheckDoneness)(void) = ^{
    totalSyncAttempted++;
    if (totalSyncAttempted == totalNumToSync) {
      allDoneBlk(numImportedSetsNotSyncedDueToNotAllowed.integerValue,
                 numImportedSetsNotSyncedDueToMaxExceeded.integerValue,
                 numImportedBmlsNotSyncedDueToNotAllowed.integerValue,
                 numImportedBmlsNotSyncedDueToMaxExceeded.integerValue);
    }
  };
  void (^commonEntityNotFoundBlk)(void) = ^{
    if (entityNotFoundBlk) entityNotFoundBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonSuccessBlk)(void) = ^{
    if (successBlk) successBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteStoreyBusyBlk)(NSDate *) = ^(NSDate *retryAfter) {
    if (remoteStoreBusyBlk) remoteStoreBusyBlk([individualEntitySyncProgress floatValue], retryAfter);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonTempRemoteErrorBlk)(void) = ^{
    if (tempRemoteErrorBlk) tempRemoteErrorBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonForbiddenBlk)(void) = ^{
    if (forbiddenBlk) forbiddenBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonRemoteErrorBlk)(NSInteger) = ^(NSInteger errMask) {
    if (remoteErrorBlk) remoteErrorBlk([individualEntitySyncProgress floatValue], errMask);
    incrementSyncAttemptedAndCheckDoneness();
  };
  void (^commonAuthReqdBlk)(void) = ^{
    if (authRequiredBlk) authRequiredBlk([individualEntitySyncProgress floatValue]);
    incrementSyncAttemptedAndCheckDoneness();
  };
  __block NSInteger totalSetsSyncAttempted = 0;
  if (totalNumSetsToSync > 0) {
    void (^setSyncAttempted)(void) = ^{
      totalSetsSyncAttempted++;
    };
    [self flushUnsyncedChangesToEntities:setsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToSet:(RSet *)entity
                                                                                            forUser:user
                                                                            writeUserReadonlyFields:NO
                                                                                notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                     addlSuccessBlk:^{ commonSuccessBlk(); setSyncAttempted(); }
                                                                             addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); setSyncAttempted(); }
                                                                             addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); setSyncAttempted(); }
                                                                                 addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); setSyncAttempted(); }
                                                                                addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                   addlForbiddenBlk:commonForbiddenBlk
                                                                                              error:errorBlk];}];
  }
  __block NSInteger totalBmlsSyncAttempted = 0;
  if (totalNumBmlsToSync > 0) {
    void (^bmlSyncAttempted)(void) = ^{
      totalBmlsSyncAttempted++;
    };
    [self flushUnsyncedChangesToEntities:bmlsToSync
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToBml:(RBodyMeasurementLog *)entity
                                                                                            forUser:user
                                                                            writeUserReadonlyFields:NO
                                                                                notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                     addlSuccessBlk:^{ commonSuccessBlk(); bmlSyncAttempted(); }
                                                                             addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); bmlSyncAttempted(); }
                                                                             addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); bmlSyncAttempted(); }
                                                                                 addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); bmlSyncAttempted(); }
                                                                                addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                   addlForbiddenBlk:commonForbiddenBlk
                                                                                              error:errorBlk];}];
  }
  if (userSettingsToSyncCount > 0) {
    [self flushUnsyncedChangesToEntities:@[userSettingsToSync]
                                  syncer:^(PELMMainSupport *entity){[self flushUnsyncedChangesToUserSettings:(RUserSettings *)entity
                                                                                                     forUser:user
                                                                                     writeUserReadonlyFields:NO
                                                                                         notFoundOnServerBlk:^{ commonEntityNotFoundBlk(); }
                                                                                              addlSuccessBlk:^{ commonSuccessBlk(); }
                                                                                      addlRemoteStoreBusyBlk:^(NSDate *d) { commonRemoteStoreyBusyBlk(d); }
                                                                                      addlTempRemoteErrorBlk:^{ commonTempRemoteErrorBlk(); }
                                                                                          addlRemoteErrorBlk:^(NSInteger mask) { commonRemoteErrorBlk(mask); }
                                                                                         addlAuthRequiredBlk:commonAuthReqdBlk
                                                                                            addlForbiddenBlk:commonForbiddenBlk
                                                                                                       error:errorBlk];}];
  }
  return totalNumToSync;
}


#pragma mark - Unsynced Entities Check

- (BOOL)doesUserHaveAnyUnsyncedEntities:(PELMUser *)user {
  return ([self totalNumUnsyncedEntitiesForUser:user] > 0);
}

- (BOOL)isUserSettingsUnsynced:(PELMUser *)user {
  return [self numSyncNeededSettingsForUser:user] > 0;
}

#pragma mark - Movement

- (void)fetchMovementWithGlobalId:(NSString *)globalIdentifier
                  ifModifiedSince:(NSDate *)ifModifiedSince
                          forUser:(PELMUser *)user
              notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                       successBlk:(void(^)(RMovement *))successBlk
               remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
               tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
              addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                     forbiddenBlk:(void(^)(void))forbiddenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(RMovement *fetchedMovement) {
                                    if (successBlk) { successBlk(fetchedMovement); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchMovementWithGlobalId:globalIdentifier
                              ifModifiedSince:ifModifiedSince
                                      timeout:_timeout
                              remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                 authRequired:^(HCAuthentication *auth) {
                                   [_userCoordDao authReqdBlk](auth);
                                   if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                 }
                                    forbidden:forbiddenBlk
                            completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewMovementWithGlobalId:(NSString *)globalIdentifier
                                    forUser:(PELMUser *)user
                        notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                             addlSuccessBlk:(void(^)(RMovement *))addlSuccessBlk
                         remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                         tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                        addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                               forbiddenBlk:(void(^)(void))forbiddenBlk
                                      error:(PELMDaoErrorBlk)errorBlk {
  [self fetchMovementWithGlobalId:globalIdentifier
                  ifModifiedSince:nil
                          forUser:user
              notFoundOnServerBlk:notFoundOnServerBlk
                       successBlk:^(RMovement *fetchedMovement) {
                         [self saveNewMasterMovement:fetchedMovement error:errorBlk];
                         if (addlSuccessBlk) { addlSuccessBlk(fetchedMovement); }
                       }
               remoteStoreBusyBlk:remoteStoreBusyBlk
               tempRemoteErrorBlk:tempRemoteErrorBlk
              addlAuthRequiredBlk:addlAuthRequiredBlk
                     forbiddenBlk:forbiddenBlk];
}

#pragma mark - Movement Variant

- (void)fetchMovementVariantWithGlobalId:(NSString *)globalIdentifier
                         ifModifiedSince:(NSDate *)ifModifiedSince
                                 forUser:(PELMUser *)user
                     notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              successBlk:(void(^)(RMovementVariant *))successBlk
                      remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                     addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            forbiddenBlk:(void(^)(void))forbiddenBlk{
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(RMovementVariant *fetchedMovementVariant) {
                                    if (successBlk) { successBlk(fetchedMovementVariant); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchMovementVariantWithGlobalId:globalIdentifier
                                     ifModifiedSince:ifModifiedSince
                                             timeout:_timeout
                                     remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                        authRequired:^(HCAuthentication *auth) {
                                          [_userCoordDao authReqdBlk](auth);
                                          if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                        }
                                           forbidden:forbiddenBlk
                                   completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewMovementVariantWithGlobalId:(NSString *)globalIdentifier
                                           forUser:(PELMUser *)user
                               notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                                    addlSuccessBlk:(void(^)(RMovementVariant *))addlSuccessBlk
                                remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                                tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                               addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                                      forbiddenBlk:(void(^)(void))forbiddenBlk
                                             error:(PELMDaoErrorBlk)errorBlk {
  [self fetchMovementVariantWithGlobalId:globalIdentifier
                         ifModifiedSince:nil
                                 forUser:user
                     notFoundOnServerBlk:notFoundOnServerBlk
                              successBlk:^(RMovementVariant *fetchedMovementVariant) {
                                [self saveNewMasterMovementVariant:fetchedMovementVariant error:errorBlk];
                                if (addlSuccessBlk) { addlSuccessBlk(fetchedMovementVariant); }
                              }
                      remoteStoreBusyBlk:remoteStoreBusyBlk
                      tempRemoteErrorBlk:tempRemoteErrorBlk
                     addlAuthRequiredBlk:addlAuthRequiredBlk
                            forbiddenBlk:forbiddenBlk];
}

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
                                     error:(PELMDaoErrorBlk)errorBlk {
  if ([userSettings synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:userSettings
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForUserSettings:userSettings httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [RCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                        error:err
                                                                           tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                               remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                      markAsSyncCompleteForNewEntityBlk:nil // should not be possible for a NEW user settings instance to be created on server
                 markAsSyncCompleteForExistingEntityBlk:^(RUserSettings *respUserSettings) {
                   [self markAsSyncCompleteForUpdatedUserSettings:respUserSettings
                                                          forUser:user
                                          writeUserReadonlyFields:writeUserReadonlyFields
                                                            error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForUserSettings:userSettings httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForUserSettings:userSettings httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  PELMRemoteMasterForbiddenBlk forbiddenBlk = ^{
    [self cancelSyncForUserSettings:userSettings httpRespCode:@(403) errorMask:nil retryAt:nil error:errorBlk];
    if (addlForbiddenBlk) { addlForbiddenBlk(); }
  };
  if ([userSettings globalIdentifier]) { // this should ALWAYS be true (because when a user creates an account, a user settings row is created for them automatically on the server)
    // also, as part of login or account creation, in the "link" call, the main user
    // settings row is tied to the newly-inserted master row, so, that is why here we don't need
    // to do the the "hasPrefix" check that occurs in the flush call for sets and bmls,
    // just fyi...
    [_remoteMasterDao saveExistingUserSettings:userSettings
                                       timeout:_timeout
                               remoteStoreBusy:remoteStoreBusyBlk
                                  authRequired:authRequiredBlk
                                     forbidden:forbiddenBlk
                             completionHandler:complHandler];
  }
}

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
                                                error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncUserSettings:userSettings error:errorBlk];
  [self flushUnsyncedChangesToUserSettings:userSettings
                                   forUser:user
                   writeUserReadonlyFields:writeUserReadonlyFields
                       notFoundOnServerBlk:notFoundOnServerBlk
                            addlSuccessBlk:addlSuccessBlk
                    addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
                    addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
                        addlRemoteErrorBlk:addlRemoteErrorBlk
                       addlAuthRequiredBlk:addlAuthRequiredBlk
                          addlForbiddenBlk:addlForbiddenBlk
                                     error:errorBlk];
}

- (void)fetchUserSettingsWithGlobalId:(NSString *)globalIdentifier
                      ifModifiedSince:(NSDate *)ifModifiedSince
                              forUser:(PELMUser *)user
                  notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                           successBlk:(void(^)(RUserSettings *))successBlk
                   remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                   tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                  addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                         forbiddenBlk:(void(^)(void))forbiddenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(RUserSettings *fetchedUserSettings) {
                                    if (successBlk) { successBlk(fetchedUserSettings); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchUserSettingsWithGlobalId:globalIdentifier
                                  ifModifiedSince:ifModifiedSince
                                          timeout:_timeout
                                  remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                                     authRequired:^(HCAuthentication *auth) {
                                       [_userCoordDao authReqdBlk](auth);
                                       if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                                     }
                                        forbidden:forbiddenBlk
                                completionHandler:remoteStoreComplHandler];
}

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
         correlationGuid:(NSString *)correlationGuid {
  return [RSet setWithNumReps:numReps
                       weight:weight
                    weightUom:weightUom
                    negatives:negatives
                    toFailure:toFailure
                     loggedAt:loggedAt
                   ignoreTime:ignoreTime
                   movementId:movementId
            movementVariantId:movementVariantId
          originationDeviceId:originationDeviceId
                   importedAt:importedAt
              correlationGuid:correlationGuid
                    mediaType:[RKnownMediaTypes setMediaTypeWithVersion:_setResMtVersion]];
}

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
                             error:(PELMDaoErrorBlk)errorBlk {  
  [self saveNewAndSyncImmediateSet:set forUser:user error:errorBlk];
  [self flushUnsyncedChangesToSet:set
                          forUser:user
          writeUserReadonlyFields:writeUserReadonlyFields
              notFoundOnServerBlk:notFoundOnServerBlk
                   addlSuccessBlk:addlSuccessBlk
           addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
           addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
               addlRemoteErrorBlk:addlRemoteErrorBlk
              addlAuthRequiredBlk:addlAuthRequiredBlk
                 addlForbiddenBlk:addlForbiddenBlk
                            error:errorBlk];
}

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
                            error:(PELMDaoErrorBlk)errorBlk {
  if ([set synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:set
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForSet:set httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [RCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                        error:err
                                                                           tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                               remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                      markAsSyncCompleteForNewEntityBlk:^(RSet *respSet) {
                        [self markAsSyncCompleteForNewSet:respSet forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^(RSet *respSet) {
                   [self markAsSyncCompleteForUpdatedSet:respSet forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForSet:set httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForSet:set httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  PELMRemoteMasterForbiddenBlk forbiddenBlk = ^{
    [self cancelSyncForSet:set httpRespCode:@(403) errorMask:nil retryAt:nil error:errorBlk];
    if (addlForbiddenBlk) { addlForbiddenBlk(); }
  };
  NSString *setGlobalIdentifier = [set globalIdentifier];
  void (^saveNewSet)(RSet *) = ^(RSet *theSet){
    [_remoteMasterDao saveNewSet:theSet
                         forUser:user
                         timeout:_timeout
                 remoteStoreBusy:remoteStoreBusyBlk
                    authRequired:authRequiredBlk
                       forbidden:forbiddenBlk
               completionHandler:complHandler];
  };
  if (setGlobalIdentifier) {
    if ([setGlobalIdentifier hasPrefix:user.globalIdentifier]) {
      [_remoteMasterDao saveExistingSet:set
                                timeout:_timeout
                        remoteStoreBusy:remoteStoreBusyBlk
                           authRequired:authRequiredBlk
                              forbidden:forbiddenBlk
                      completionHandler:complHandler];
    } else {
      // This can happen if the user logs out, chooses not to delete local data, and
      // then a different user logs in or creates an account.
      [set setGlobalIdentifier:nil];
      saveNewSet(set);
    }
  } else {
    saveNewSet(set);
  }
}

- (void)markAsDoneEditingAndSyncSetImmediate:(RSet *)set
                                     forUser:(PELMUser *)user
                     writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))successBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                            addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                       error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncSet:set error:errorBlk];
  [self flushUnsyncedChangesToSet:set
                          forUser:user
          writeUserReadonlyFields:writeUserReadonlyFields
              notFoundOnServerBlk:notFoundOnServerBlk
                   addlSuccessBlk:successBlk
           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
           addlTempRemoteErrorBlk:tempRemoteErrorBlk
               addlRemoteErrorBlk:remoteErrorBlk
              addlAuthRequiredBlk:addlAuthRequiredBlk
                 addlForbiddenBlk:addlForbiddenBlk
                            error:errorBlk];
}

- (void)deleteSet:(RSet *)set
          forUser:(PELMUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
   addlSuccessBlk:(void(^)(void))addlSuccessBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
   remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
     forbiddenBlk:(void(^)(void))forbiddenBlk
            error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToDeleteEntity:set
                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                      [RCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                        error:err
                                                           tempRemoteErrorBlk:tempRemoteErrorBlk
                                                               remoteErrorBlk:remoteErrorBlk];
                    }
                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                       deleteSuccessBlk:^{
                         [self deleteSet:set error:errorBlk];
                         if (addlSuccessBlk) { addlSuccessBlk(); }
                       }
                        newAuthTokenBlk:^(NSString *newAuthTkn) {[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteSet:set
                      timeout:_timeout
              remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                 authRequired:^(HCAuthentication *auth) {
                   [_userCoordDao authReqdBlk](auth);
                   if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                 }
                    forbidden:forbiddenBlk
            completionHandler:remoteStoreComplHandler];
}

- (void)fetchSetWithGlobalId:(NSString *)globalIdentifier
             ifModifiedSince:(NSDate *)ifModifiedSince
                     forUser:(PELMUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                  successBlk:(void(^)(RSet *))successBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                forbiddenBlk:(void(^)(void))forbiddenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(RSet *fetchedSet) {
                                    if (successBlk) { successBlk(fetchedSet); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchSetWithGlobalId:globalIdentifier
                         ifModifiedSince:ifModifiedSince
                                 timeout:_timeout
                         remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                            authRequired:^(HCAuthentication *auth) {
                              [_userCoordDao authReqdBlk](auth);
                              if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                            }
                               forbidden:forbiddenBlk
                       completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewSetWithGlobalId:(NSString *)globalIdentifier
                               forUser:(PELMUser *)user
               writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(RSet *))addlSuccessBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                          forbiddenBlk:(void(^)(void))forbiddenBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [self fetchSetWithGlobalId:globalIdentifier
             ifModifiedSince:nil
                     forUser:user
         notFoundOnServerBlk:notFoundOnServerBlk
                  successBlk:^(RSet *fetchedSet) {
                    [self saveNewMasterSet:fetchedSet forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                    if (addlSuccessBlk) { addlSuccessBlk(fetchedSet); }
                  }
          remoteStoreBusyBlk:remoteStoreBusyBlk
          tempRemoteErrorBlk:tempRemoteErrorBlk
         addlAuthRequiredBlk:addlAuthRequiredBlk
                forbiddenBlk:forbiddenBlk];
}

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
                                importedAt:(NSDate *)importedAt {
  return [RBodyMeasurementLog bmlWithBodyWeight:bodyWeight
                                  bodyWeightUom:bodyWeightUom
                                        armSize:armSize
                                       calfSize:calfSize
                                      chestSize:chestSize
                                        sizeUom:sizeUom
                                       neckSize:neckSize
                                      waistSize:waistSize
                                      thighSize:thighSize
                                    forearmSize:forearmSize
                                       loggedAt:loggedAt
                            originationDeviceId:originationDeviceId
                                     importedAt:importedAt
                                      mediaType:[RKnownMediaTypes bodyMeasurementLogMediaTypeWithVersion:_bodyMeasurementLogResMtVersion]];
}

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
                             error:(PELMDaoErrorBlk)errorBlk {
  [self saveNewAndSyncImmediateBml:bml forUser:user error:errorBlk];
  [self flushUnsyncedChangesToBml:bml
                          forUser:user
          writeUserReadonlyFields:writeUserReadonlyFields
              notFoundOnServerBlk:notFoundOnServerBlk
                   addlSuccessBlk:addlSuccessBlk
           addlRemoteStoreBusyBlk:addlRemoteStoreBusyBlk
           addlTempRemoteErrorBlk:addlTempRemoteErrorBlk
               addlRemoteErrorBlk:addlRemoteErrorBlk
              addlAuthRequiredBlk:addlAuthRequiredBlk
                 addlForbiddenBlk:addlForbiddenBlk
                            error:errorBlk];
}

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
                            error:(PELMDaoErrorBlk)errorBlk {
  if ([bml synced]) {
    return;
  }
  PELMRemoteMasterCompletionHandler complHandler =
  [PELMUtils complHandlerToFlushUnsyncedChangesToEntity:bml
                                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                                      [self cancelSyncForBml:bml httpRespCode:httpStatusCode errorMask:@([err code]) retryAt:nil error:errorBlk];
                                      [RCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                                        error:err
                                                                           tempRemoteErrorBlk:addlTempRemoteErrorBlk
                                                                               remoteErrorBlk:addlRemoteErrorBlk];
                                    }
                                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                      markAsSyncCompleteForNewEntityBlk:^(RBodyMeasurementLog *respBml) {
                        [self markAsSyncCompleteForNewBml:respBml forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                        if (addlSuccessBlk) { addlSuccessBlk(); }
                      }
                 markAsSyncCompleteForExistingEntityBlk:^(RBodyMeasurementLog *respBml) {
                   [self markAsSyncCompleteForUpdatedBml:respBml forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                   if (addlSuccessBlk) { addlSuccessBlk(); }
                 }
                                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  PELMRemoteMasterBusyBlk remoteStoreBusyBlk = ^(NSDate *retryAt) {
    [self cancelSyncForBml:bml httpRespCode:@(503) errorMask:nil retryAt:retryAt error:errorBlk];
    if (addlRemoteStoreBusyBlk) { addlRemoteStoreBusyBlk(retryAt); }
  };
  PELMRemoteMasterAuthReqdBlk authRequiredBlk = ^(HCAuthentication *auth) {
    [_userCoordDao authReqdBlk](auth);
    [self cancelSyncForBml:bml httpRespCode:@(401) errorMask:nil retryAt:nil error:errorBlk];
    if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
  };
  PELMRemoteMasterForbiddenBlk forbiddenBlk = ^{
    [self cancelSyncForBml:bml httpRespCode:@(403) errorMask:nil retryAt:nil error:errorBlk];
    if (addlForbiddenBlk) { addlForbiddenBlk(); }
  };
  NSString *bmlGlobalIdentifier = [bml globalIdentifier];
  void (^saveNewBml)(RBodyMeasurementLog *) = ^(RBodyMeasurementLog *theBml) {
    [_remoteMasterDao saveNewBml:theBml
                         forUser:user
                         timeout:_timeout
                 remoteStoreBusy:remoteStoreBusyBlk
                    authRequired:authRequiredBlk
                       forbidden:forbiddenBlk
               completionHandler:complHandler];
  };
  if (bmlGlobalIdentifier) {
    if ([bmlGlobalIdentifier hasPrefix:user.globalIdentifier]) {
      [_remoteMasterDao saveExistingBml:bml
                                timeout:_timeout
                        remoteStoreBusy:remoteStoreBusyBlk
                           authRequired:authRequiredBlk
                              forbidden:forbiddenBlk
                      completionHandler:complHandler];
    } else {
      // This can happen if the user logs out, chooses not to delete local data, and
      // then a different user logs in or creates an account.
      [bml setGlobalIdentifier:nil];
      saveNewBml(bml);
    }
  } else {
    saveNewBml(bml);
  }  
}

- (void)markAsDoneEditingAndSyncBmlImmediate:(RBodyMeasurementLog *)bml
                                     forUser:(PELMUser *)user
                     writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                              addlSuccessBlk:(void(^)(void))successBlk
                      addlRemoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                      addlTempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                          addlRemoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
                         addlAuthRequiredBlk:(void(^)(void))authRequiredBlk
                            addlForbiddenBlk:(void(^)(void))addlForbiddenBlk
                                       error:(PELMDaoErrorBlk)errorBlk {
  [self markAsDoneEditingImmediateSyncBml:bml error:errorBlk];
  [self flushUnsyncedChangesToBml:bml
                          forUser:user
          writeUserReadonlyFields:writeUserReadonlyFields
              notFoundOnServerBlk:notFoundOnServerBlk
                   addlSuccessBlk:successBlk
           addlRemoteStoreBusyBlk:remoteStoreBusyBlk
           addlTempRemoteErrorBlk:tempRemoteErrorBlk
               addlRemoteErrorBlk:remoteErrorBlk
              addlAuthRequiredBlk:authRequiredBlk
                 addlForbiddenBlk:addlForbiddenBlk
                            error:errorBlk];
}

- (void)deleteBml:(RBodyMeasurementLog *)bml
          forUser:(PELMUser *)user
notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
   addlSuccessBlk:(void(^)(void))addlSuccessBlk
remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
   remoteErrorBlk:(void(^)(NSInteger))remoteErrorBlk
addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
     forbiddenBlk:(void(^)(void))forbiddenBlk
            error:(PELMDaoErrorBlk)errorBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToDeleteEntity:bml
                    remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) {
                      [RCoordinatorDaoImpl invokeErrorBlocksForHttpStatusCode:httpStatusCode
                                                                        error:err
                                                           tempRemoteErrorBlk:tempRemoteErrorBlk
                                                               remoteErrorBlk:remoteErrorBlk];
                    }
                      entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }                      
                       deleteSuccessBlk:^{
                         [self deleteBml:bml error:errorBlk];
                         if (addlSuccessBlk) { addlSuccessBlk(); }
                       }
                        newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao deleteBml:bml
                      timeout:_timeout
              remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                 authRequired:^(HCAuthentication *auth) {
                   [_userCoordDao authReqdBlk](auth);
                   if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                 }
                    forbidden:forbiddenBlk
            completionHandler:remoteStoreComplHandler];
}

- (void)fetchBmlWithGlobalId:(NSString *)globalIdentifier
             ifModifiedSince:(NSDate *)ifModifiedSince
                     forUser:(PELMUser *)user
         notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                  successBlk:(void(^)(RBodyMeasurementLog *))successBlk
          remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
          tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
         addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                forbiddenBlk:(void(^)(void))forbiddenBlk {
  PELMRemoteMasterCompletionHandler remoteStoreComplHandler =
  [PELMUtils complHandlerToFetchEntityWithGlobalId:globalIdentifier
                               remoteStoreErrorBlk:^(NSError *err, NSNumber *httpStatusCode) { if (tempRemoteErrorBlk) { tempRemoteErrorBlk(); } }
                                 entityNotFoundBlk:^{ if (notFoundOnServerBlk) { notFoundOnServerBlk(); } }
                                  fetchCompleteBlk:^(RBodyMeasurementLog *fetchedBml) {
                                    if (successBlk) { successBlk(fetchedBml); }
                                  }
                                   newAuthTokenBlk:^(NSString *newAuthTkn){[_userCoordDao processNewAuthToken:newAuthTkn forUser:user];}];
  [_remoteMasterDao fetchBmlWithGlobalId:globalIdentifier
                         ifModifiedSince:ifModifiedSince
                                 timeout:_timeout
                         remoteStoreBusy:^(NSDate *retryAfter) { if (remoteStoreBusyBlk) { remoteStoreBusyBlk(retryAfter); } }
                            authRequired:^(HCAuthentication *auth) {
                              [_userCoordDao authReqdBlk](auth);
                              if (addlAuthRequiredBlk) { addlAuthRequiredBlk(); }
                            }
                               forbidden:forbiddenBlk
                       completionHandler:remoteStoreComplHandler];
}

- (void)fetchAndSaveNewBmlWithGlobalId:(NSString *)globalIdentifier
                               forUser:(PELMUser *)user
               writeUserReadonlyFields:(BOOL)writeUserReadonlyFields
                   notFoundOnServerBlk:(void(^)(void))notFoundOnServerBlk
                        addlSuccessBlk:(void(^)(RBodyMeasurementLog *))addlSuccessBlk
                    remoteStoreBusyBlk:(PELMRemoteMasterBusyBlk)remoteStoreBusyBlk
                    tempRemoteErrorBlk:(void(^)(void))tempRemoteErrorBlk
                   addlAuthRequiredBlk:(void(^)(void))addlAuthRequiredBlk
                          forbiddenBlk:(void(^)(void))forbiddenBlk
                                 error:(PELMDaoErrorBlk)errorBlk {
  [self fetchBmlWithGlobalId:globalIdentifier
             ifModifiedSince:nil
                     forUser:user
         notFoundOnServerBlk:notFoundOnServerBlk
                  successBlk:^(RBodyMeasurementLog *fetchedBml) {
                    [self saveNewMasterBml:fetchedBml forUser:user writeUserReadonlyFields:writeUserReadonlyFields error:errorBlk];
                    if (addlSuccessBlk) { addlSuccessBlk(fetchedBml); }
                  }
          remoteStoreBusyBlk:remoteStoreBusyBlk
          tempRemoteErrorBlk:tempRemoteErrorBlk
         addlAuthRequiredBlk:addlAuthRequiredBlk
                forbiddenBlk:forbiddenBlk];
}

@end
