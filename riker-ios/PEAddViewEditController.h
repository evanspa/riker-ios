//
//  PEAddViewEditController.h
//

#import <UIKit/UIKit.h>
#import "PEUIToolkit.h"
#import "PEUIUtils.h"
#import "PELMMainSupport.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "PEUIDefs.h"

@class PEListViewController;
@class PEAddViewEditController;
@class RPanelToolkit;

@interface PEAddViewEditController : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate>

#pragma mark - Initializers

- (id)initWithParentEntity:(PELMMainSupport *)parentEntity
                    entity:(PELMMainSupport *)entity
        listViewController:(PEListViewController *)listViewController
                     isAdd:(BOOL)isAdd
                    isEdit:(BOOL)isEdit
                 indexPath:(NSIndexPath *)indexPath
                 uitoolkit:(PEUIToolkit *)uitoolkit
              itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
            itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
      entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
      entityViewPanelMaker:(PEEntityViewPanelMakerBlk)entityViewPanelMaker
       entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
       panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
               entityTitle:(NSString *)entityTitle
         entityNavbarTitle:(NSString *)entityNavbarTitle
      panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
         entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
               entityMaker:(PEEntityMakerBlk)entityMaker
               entitySaver:(PESaveEntityBlk)entitySaver
       newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
    doneEditingEntityLocal:(PEMarkAsDoneEditingLocalBlk)doneEditingEntityLocal
doneEditingEntityImmediateSync:(PEMarkAsDoneEditingImmediateSyncBlk)doneEditingEntityImmediateSync
           isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
            isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
              isBadAccount:(PEIsBadAccountBlk)isBadAccount
allowedToRemoteSaveWithBadAccount:(BOOL)allowedToRemoteSaveWithBadAccount
allowedToDownloadWithBadAccount:(BOOL)allowedToDownloadWithBadAccount
             isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
          viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
           entityValidator:(PEEntityValidatorBlk)entityValidator
                  uploader:(PEUploaderBlk)uploader
    uploadedSuccessMessage:(NSString *)uploadedSuccessMessage
     numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal                     
         fetchDependencies:(PEDependencyFetcherBlk)fetchDependencies
           updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
                downloader:(PEDownloaderBlk)downloader
alreadyHaveLatestDownloadedMsg:(NSString *)alreadyHaveLatestDownloadedMsg
         postDownloadSaver:(PEPostDownloaderSaver)postDownloadSaver
       itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
       itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
               itemDeleter:(PEItemDeleter)itemDeleter
          itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
        entitiesFromEntity:(PEEntitiesFromEntityBlk)entitiesFromEntity
     modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
        modalOperationDone:(PEModalOperationDone)modalOperationDone
entityAddedNotificationName:(NSString *)entityAddedNotificationName
entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
entityRemovedNotificationName:(NSString *)entityRemovedNotificationName
        addlContentSection:(PEAddlContentSection)addlContentSection
        masterEntityLoader:(id(^)(NSNumber *))masterEntityLoader
reauthReqdPostEditActivityBlk:(PEReauthReqdPostEditActivityBlk)reauthReqdPostEditActivityBlk
actionIfReauthReqdNotifObservedBlk:(PEActionIfReauthReqdNotifObservedBlk)actionIfReauthReqdNotifObservedBlk
  promptCurrentPasswordBlk:(PEPromptCurrentPasswordBlk)promptCurrentPasswordBlk
              panelToolkit:(RPanelToolkit *)panelToolkit
           promptGoOffline:(BOOL)promptGoOffline
                importedAt:(PEImportedAt)importedAt
   importLimitExceededMask:(NSNumber *)importLimitExceededMask
    hasExceededImportLimit:(PEHasExceededImportLimit)hasExceededImportLimit
            isUserVerified:(PEIsUserVerified)isUserVerified
           deletedCallback:(void(^)(void))deletedCallback
            viewDidLoadBlk:(void(^)(void))viewDidLoadBlk
           dismissCallback:(void(^)(void))dismissCallback;

#pragma mark - Factory functions

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                      listViewController:(PEListViewController *)listViewController
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                    entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityNavbarTitle:(NSString *)entityNavbarTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                     newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
                             newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                            isBadAccount:(PEIsBadAccountBlk)isBadAccount
                       allowedToRemoteSaveWithBadAccount:(BOOL)allowedToRemoteSaveWithBadAccount
                         allowedToDownloadWithBadAccount:(BOOL)allowedToDownloadWithBadAccount
                                           isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                                   modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                      modalOperationDone:(PEModalOperationDone)modalOperationDone
                             entityAddedNotificationName:(NSString *)entityAddedNotificationName
                                      addlContentSection:(PEAddlContentSection)addlContentSection
                                            panelToolkit:(RPanelToolkit *)panelToolkit
                                         promptGoOffline:(BOOL)promptGoOffline
                                              importedAt:(PEImportedAt)importedAt
                                 importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                  hasExceededImportLimit:(PEHasExceededImportLimit)hasExceededImportLimit
                                          isUserVerified:(PEIsUserVerified)isUserVerified
                                          viewDidLoadBlk:(void(^)(void))viewDidLoadBlk
                                         dismissCallback:(void(^)(void))dismissCallback;

+ (PEAddViewEditController *)addEntityCtrlrWithUitoolkit:(PEUIToolkit *)uitoolkit
                                      listViewController:(PEListViewController *)listViewController
                                            itemAddedBlk:(PEItemAddedBlk)itemAddedBlk
                                    entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                     entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                     panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                             entityTitle:(NSString *)entityTitle
                                       entityNavbarTitle:(NSString *)entityNavbarTitle
                                       entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                             entityMaker:(PEEntityMakerBlk)entityMaker
                                     newEntitySaverLocal:(PESaveNewEntityLocalBlk)newEntitySaverLocal
                             newEntitySaverImmediateSync:(PESaveNewEntityImmediateSyncBlk)newEntitySaverImmediateSync
                          prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                        viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                         entityValidator:(PEEntityValidatorBlk)entityValidator
                                         isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                          isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                            isBadAccount:(PEIsBadAccountBlk)isBadAccount
                       allowedToRemoteSaveWithBadAccount:(BOOL)allowedToRemoteSaveWithBadAccount
                         allowedToDownloadWithBadAccount:(BOOL)allowedToDownloadWithBadAccount
                                           isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                          syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                                      entitiesFromEntity:(PEEntitiesFromEntityBlk)entitiesFromEntity
                                   modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                      modalOperationDone:(PEModalOperationDone)modalOperationDone
                             entityAddedNotificationName:(NSString *)entityAddedNotificationName
                                      addlContentSection:(PEAddlContentSection)addlContentSection
                                            panelToolkit:(RPanelToolkit *)panelToolkit
                                         promptGoOffline:(BOOL)promptGoOffline
                                              importedAt:(PEImportedAt)importedAt
                                 importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                  hasExceededImportLimit:(PEHasExceededImportLimit)hasExceededImportLimit
                                          isUserVerified:(PEIsUserVerified)isUserVerified
                                          viewDidLoadBlk:(void(^)(void))viewDidLoadBlk
                                         dismissCallback:(void(^)(void))dismissCallback;

+ (PEAddViewEditController *)viewEntityCtrlrWithParentEntity:(PELMMainSupport *)parentEntity
                                                      entity:(PELMMainSupport *)entity
                                          listViewController:(PEListViewController *)listViewController
                                             entityIndexPath:(NSIndexPath *)entityIndexPath
                                                   uitoolkit:(PEUIToolkit *)uitoolkit
                                              itemChangedBlk:(PEItemChangedBlk)itemChangedBlk
                                        entityFormPanelMaker:(PEEntityPanelMakerBlk)entityFormPanelMaker
                                        entityViewPanelMaker:(PEEntityViewPanelMakerBlk)entityViewPanelMaker
                                         entityToPanelBinder:(PEEntityToPanelBinderBlk)entityToPanelBinder
                                         panelToEntityBinder:(PEPanelToEntityBinderBlk)panelToEntityBinder
                                                 entityTitle:(NSString *)entityTitle
                                           entityNavbarTitle:(NSString *)entityNavbarTitle
                                        panelEnablerDisabler:(PEEnableDisablePanelBlk)panelEnablerDisabler
                                           entityAddCanceler:(PEEntityAddCancelerBlk)entityAddCanceler
                                                 entitySaver:(PESaveEntityBlk)entitySaver
                                      doneEditingEntityLocal:(PEMarkAsDoneEditingLocalBlk)doneEditingEntityLocal
                              doneEditingEntityImmediateSync:(PEMarkAsDoneEditingImmediateSyncBlk)doneEditingEntityImmediateSync
                                             isAuthenticated:(PEIsAuthenticatedBlk)isAuthenticated
                                              isUserLoggedIn:(PEIsLoggedInBlk)isUserLoggedIn
                                                isBadAccount:(PEIsBadAccountBlk)isBadAccount
                           allowedToRemoteSaveWithBadAccount:(BOOL)allowedToRemoteSaveWithBadAccount
                             allowedToDownloadWithBadAccount:(BOOL)allowedToDownloadWithBadAccount
                                               isOfflineMode:(PEIsOfflineModeBlk)isOfflineMode
                              syncImmediateMBProgressHUDMode:(MBProgressHUDMode)syncImmediateMBProgressHUDMode
                              prepareUIForUserInteractionBlk:(PEPrepareUIForUserInteractionBlk)prepareUIForUserInteractionBlk
                                            viewDidAppearBlk:(PEViewDidAppearBlk)viewDidAppearBlk
                                             entityValidator:(PEEntityValidatorBlk)entityValidator
                                                    uploader:(PEUploaderBlk)uploader
                                      uploadedSuccessMessage:(NSString *)uploadedSuccessMessage
                                       numRemoteDepsNotLocal:(PENumRemoteDepsNotLocal)numRemoteDepsNotLocal                                                       
                                           fetchDependencies:(PEDependencyFetcherBlk)fetchDependencies
                                             updateDepsPanel:(PEUpdateDepsPanel)updateDepsPanel
                                                  downloader:(PEDownloaderBlk)downloader
                              alreadyHaveLatestDownloadedMsg:(NSString *)alreadyHaveLatestDownloadedMsg
                                           postDownloadSaver:(PEPostDownloaderSaver)postDownloadSaver
                                         itemChildrenCounter:(PEItemChildrenCounter)itemChildrenCounter
                                         itemChildrenMsgsBlk:(PEItemChildrenMsgsBlk)itemChildrenMsgsBlk
                                                 itemDeleter:(PEItemDeleter)itemDeleter
                                            itemLocalDeleter:(PEItemLocalDeleter)itemLocalDeleter
                                       modalOperationStarted:(PEModalOperationStarted)modalOperationStarted
                                          modalOperationDone:(PEModalOperationDone)modalOperationDone
                               entityUpdatedNotificationName:(NSString *)entityUpdatedNotificationName
                               entityRemovedNotificationName:(NSString *)entityRemovedNotificationName
                                          masterEntityLoader:(id(^)(NSNumber *))masterEntityLoader
                               reauthReqdPostEditActivityBlk:(PEReauthReqdPostEditActivityBlk)reauthReqdPostEditActivityBlk
                          actionIfReauthReqdNotifObservedBlk:(PEActionIfReauthReqdNotifObservedBlk)actionIfReauthReqdNotifObservedBlk
                                    promptCurrentPasswordBlk:(PEPromptCurrentPasswordBlk)promptCurrentPasswordBlk
                                                panelToolkit:(RPanelToolkit *)panelToolkit
                                             promptGoOffline:(BOOL)promptGoOffline
                                                  importedAt:(PEImportedAt)importedAt
                                     importLimitExceededMask:(NSNumber *)importLimitExceededMask
                                      hasExceededImportLimit:(PEHasExceededImportLimit)hasExceededImportLimit
                                              isUserVerified:(PEIsUserVerified)isUserVerified
                                             deletedCallback:(void(^)(void))deletedCallback
                                              viewDidLoadBlk:(void(^)(void))viewDidLoadBlk
                                             dismissCallback:(void(^)(void))dismissCallback;

#pragma mark - Properties

@property (readonly, nonatomic) PELMMainSupport *parentEntity;

@property (readonly, nonatomic) PELMMainSupport *entity;

@property (readonly, nonatomic) PEUIToolkit *uitoolkit;

@property (readonly, nonatomic) PEEntityToPanelBinderBlk entityToPanelBinder;

@property (nonatomic) UIView *entityFormPanel;

@property (nonatomic) CGPoint scrollContentOffset;

@property (nonatomic) BOOL hasPoppedKeyboard;

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset;

#pragma mark - Screen Logging

- (void)clearScreenTitlesLogged;

#pragma mark - Helpers

- (UIView *)parentViewForAlerts;

@end
