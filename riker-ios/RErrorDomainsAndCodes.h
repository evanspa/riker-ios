//
//  RErrorDomainsAndCodes.h
//  riker-ios
//
//  Created by PEVANS on 10/22/16.
//  Copyright © 2016 Riker. All rights reserved.
//

@import Foundation;

/**
 Error domain for errors that are fundamentally the fault of the user (e.g.,
 providing invalid input).
 */
FOUNDATION_EXPORT NSString * const RUserFaultedErrorDomain;

/**
 Error domain for errors that are fundamentally connection-related (neither the
 fault of the user, or the backend system.  The error codes used for this
 domain are listed here:
 https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
 This error domain effectively mirrors the NSURLErrorDomain domain.
 */
FOUNDATION_EXPORT NSString * const RConnFaultedErrorDomain;

/**
 Error domain for errors that are fundamentally the fault of the system (e.g.,
 the database is down).
 */
FOUNDATION_EXPORT NSString * const RSystemFaultedErrorDomain;

typedef NS_OPTIONS(NSUInteger, FPSignInMsg) {
  RSignInAnyIssues                  = 1 << 0,
  RSignInInvalidEmail               = 1 << 1,
  RSignInEmailNotProvided           = 1 << 2,
  RSignInPasswordNotProvided        = 1 << 3,
  RSignInInvalidCredentials         = 1 << 4
};

typedef NS_OPTIONS(NSUInteger, RSendPasswordResetEmailMsg) {
  RSendPasswordResetAnyIssues       = 1 << 0,
  RSendPasswordResetUnknownEmail    = 1 << 1,
  RSendPasswordTokenNotFound        = 1 << 2,
  RSendPasswordTokenFlagged         = 1 << 3,
  RSendPasswordTokenExpired         = 1 << 4,
  RSendPasswordTokenAlreadyUsed     = 1 << 5,
  RSendPasswordTokenNotPrepared     = 1 << 6,
  RSendPasswordUnverifiedAccount    = 1 << 7,
  RSendPasswordTrialAndGraceExpired = 1 << 8
};

typedef NS_OPTIONS(NSUInteger, RSaveUserMsg) {
  RSaveUsrAnyIssues                        = 1 << 0,
  RSaveUsrInvalidEmail                     = 1 << 1,
  RSaveUsrEmailNotProvided                 = 1 << 2,
  RSaveUsrPasswordNotProvided              = 1 << 3,
  RSaveUsrEmailAlreadyRegistered           = 1 << 4,
  RSaveUsrUsernameAlreadyRegistered        = 1 << 5, // not applicable
  RSaveUsrCurrentPasswordNotProvided       = 1 << 6,
  RSaveUsrCurrentPasswordIncorrect         = 1 << 7,
  RSaveUsrPasswordConfirmPasswordDontMatch = 1 << 8, // local only
  RSaveUsrConfirmPasswordNotProvided       = 1 << 9, // local only
  RSaveUsrConfirmPasswordOnlyProvided      = 1 << 10 // local only
};

typedef NS_OPTIONS(NSUInteger, RSaveSetMsg) {
  RSaveSetAnyIssues             = 1 << 0,
  RSaveSetMovementDoesNotExist  = 1 << 1, // not relevant at this time
  RSaveSetSupersetDoesNotExist  = 1 << 2, // not relevant at this time
  RSaveSetImportLimitExceeded   = 1 << 3,
  RSaveSetImportUnverifiedEmail = 1 << 4
};

typedef NS_OPTIONS(NSUInteger, RSaveBmleMsg) {
  RSaveBmlAnyIssues             = 1 << 0,
  RSaveBmlImportLimitExceeded   = 1 << 1,
  RSaveBmlImportUnverifiedEmail = 1 << 2
};

