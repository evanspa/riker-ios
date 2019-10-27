//
//  RRestRemoteMasterDao.h
//  riker-ios
//
//  Created by PEVANS on 10/25/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PERestRemoteMasterDao.h"
#import "RRemoteMasterDao.h"

@class PEChangelogSerializer;
@class PELMUserSerializer;
@class PELoginSerializer;
@class PELogoutSerializer;
@class PEPasswordResetSerializer;
@class PEResendVerificationEmailSerializer;
@class PELMStripeTokenSerializer;

@class RBodySegmentSerializer;
@class RMuscleGroupSerializer;
@class RMuscleSerializer;
@class RMuscleAliasSerializer;
@class RMovementSerializer;
@class RMovementAliasSerializer;
@class RMovementVariantSerializer;
@class ROriginationDeviceSerializer;
@class RUserSettingsSerializer;
@class RBodyMeasurementLogSerializer;
@class RSetSerializer;

@interface RRestRemoteMasterDao : PERestRemoteMasterDao <RRemoteMasterDao>

#pragma mark - Initializers

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
   allowInvalidCertificates:(BOOL)allowInvalidCertificates;

@end
