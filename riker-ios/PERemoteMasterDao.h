//
// PERemoteMasterDao.h
//

#import "PELMUtils.h"

@class PELMUser;

@protocol PERemoteMasterDao <NSObject>

#pragma mark - General Operations

- (void)setAuthToken:(NSString *)authToken;

#pragma mark - User Operations

- (void)logoutUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)logoutAllOtherForUser:(PELMUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)resendVerificationEmailForUser:(PELMUser *)user
                               timeout:(NSInteger)timeout
                       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)sendPasswordResetEmailToEmail:(NSString *)email
                              timeout:(NSInteger)timeout
                      remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                    completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)establishAccountOrContinueForUser:(PELMUser *)user
                                  timeout:(NSInteger)timeout
                          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveExistingUser:(PELMUser *)user
                 timeout:(NSInteger)timeout
         remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
            authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
       completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)saveStripeTokenOfUser:(PELMUser *)user
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)loginWithEmail:(NSString *)email
              password:(NSString *)password
               timeout:(NSInteger)timeout
       remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
          authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
     completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)lightLoginForUser:(PELMUser *)user
                 password:(NSString *)password
                  timeout:(NSInteger)timeout
          remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
             authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
        completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)sendConfirmationEmailForUser:(PELMUser *)user
                             timeout:(NSInteger)timeout
                     remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                        authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                   completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)deleteUser:(PELMUser *)user
           timeout:(NSInteger)timeout
   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

- (void)fetchUserWithGlobalId:(NSString *)globalId
              ifModifiedSince:(NSDate *)ifModifiedSince
                      timeout:(NSInteger)timeout
              remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                 authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
            completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

#pragma mark - Changelog Operations

- (void)fetchChangelogWithGlobalId:(NSString *)globalId
                   ifModifiedSince:(NSDate *)ifModifiedSince
                           timeout:(NSInteger)timeout
                   remoteStoreBusy:(PELMRemoteMasterBusyBlk)busyHandler
                      authRequired:(PELMRemoteMasterAuthReqdBlk)authRequired
                 completionHandler:(PELMRemoteMasterCompletionHandler)complHandler;

@end
