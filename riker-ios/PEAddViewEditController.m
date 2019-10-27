//
//  PEAddViewEditController.m
//

#import "PEAddViewEditController.h"
#import "PELMNotificationUtils.h"
#import "PEUIUtils.h"
#import "PEUtils.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "JGActionSheet.h"
#import "PEListViewController.h"
#import "UIColor+RAdditions.h"
#import "RAppNotificationNames.h"
#import "RUtils.h"
#import "NSString+RAdditions.h"
#import "AppDelegate.h"
#import "PEProvideCurrentPasswordController.h"
#import "RPanelToolkit.h"
#import "RUIUtils.h"
@import Firebase;

@interface PEAddViewEditController () <JGActionSheetDelegate>
@end

@implementation PEAddViewEditController {
  BOOL _isAdd;
  BOOL _isEdit;
  BOOL _isView;
  NSIndexPath *_entityIndexPath;
  PEItemAddedBlk _itemAddedBlk;
  PEItemChangedBlk _itemChangedBlk;
  UIBarButtonItem *_leftBarButtonItem;
  PEEntityPanelMakerBlk _entityFormPanelMaker;
  PEEntityViewPanelMakerBlk _entityViewPanelMaker;
  PEPanelToEntityBinderBlk _panelToEntityBinder;
  NSString *_entityTitle;
  NSString *_entityNavbarTitle;
  PEEnableDisablePanelBlk _panelEnablerDisabler;
  PEEntityMakerBlk _entityMaker;
  PESaveEntityBlk _entitySaver;
  PESaveNewEntityLocalBlk _newEntitySaverLocal;
  PESaveNewEntityImmediateSyncBlk _newEntitySaverImmediateSync;
  PEMarkAsDoneEditingLocalBlk _doneEditingEntityLocalSync;
  PEMarkAsDoneEditingImmediateSyncBlk _doneEditingEntityImmediateSync;
  PEPrepareUIForUserInteractionBlk _prepareUIForUserInteractionBlk;
  PEViewDidAppearBlk _viewDidAppearBlk;
  PEEntityValidatorBlk _entityValidator;
  PEEntityAddCancelerBlk _entityAddCanceler;
  PEEntitiesFromEntityBlk _entitiesFromEntity;
  id _newEntity;
  PELMMainSupport *_entityCopyBeforeEdit;
  MBProgressHUDMode _syncImmediateMBProgressHUDMode;
  PEIsLoggedInBlk _isUserLoggedIn;
  PEIsBadAccountBlk _isBadAccount;
  BOOL _allowedToRemoteSaveWithBadAccount;
  BOOL _allowedToDownloadWithBadAccount;
  UIBarButtonItem *_uploadBarButtonItem;
  UIBarButtonItem *_downloadBarButtonItem;
  UIBarButtonItem *_deleteBarButtonItem;
  PEUploaderBlk _uploader;
  NSString *_uploadedSuccessMessage;
  PEIsAuthenticatedBlk _isAuthenticatedBlk;
  UIView *_entityViewPanel;
  PENumRemoteDepsNotLocal _numRemoteDepsNotLocal;
  PEDependencyFetcherBlk _fetchDependencies;
  PEDownloaderBlk _downloader;
  NSString *_alreadyHaveLatestDownloadedMsg;
  PEPostDownloaderSaver _postDownloadSaver;
  PEUpdateDepsPanel _updateDepsPanel;
  PEIsOfflineModeBlk _isOfflineMode;
  PEItemChildrenCounter _itemChildrenCounter;
  PEItemChildrenMsgsBlk _itemChildrenMsgsBlk;
  PEItemDeleter _itemDeleter;
  PEItemLocalDeleter _itemLocalDeleter;
  PEModalOperationStarted _modalOperationStarted;
  PEModalOperationDone _modalOperationDone;
  NSString *_entityAddedNotificationName;
  NSString *_entityUpdatedNotificationName;
  NSString *_entityRemovedNotificationName;
  PEAddlContentSection _addlContentSection;
  id(^_masterEntityLoader)(NSNumber *);
  PEReauthReqdPostEditActivityBlk _reauthReqdPostEditActivityBlk;
  PEActionIfReauthReqdNotifObservedBlk _actionIfReauthReqdNotifObservedBlk;
  PEPromptCurrentPasswordBlk _promptCurrentPasswordBlk;
  BOOL _incrementEditCountOnEditPrepare;
  RPanelToolkit *_panelToolkit;
  BOOL _promptGoOffline;
  NSNumber *_importLimitExceededMask;
  PEHasExceededImportLimit _hasExceededImportLimit;
  PEImportedAt _importedAt;
  PEIsUserVerified _isUserVerified;
  void(^_deletedCallback)(void);
  void(^_viewDidLoadBlk)(void);
  void(^_dismissCallback)(void);
  UIInterfaceOrientation _currentOrientation;
  NSMutableDictionary *_screenTitlesLogged;
  BOOL _deviceWasRotated;
}

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
           dismissCallback:(void(^)(void))dismissCallback {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _isAdd = isAdd;
    if (!isAdd) {
      _isEdit = isEdit;
      _isView = !isEdit;
    }
    _parentEntity = parentEntity;
    _entity = entity;
    _entityIndexPath = indexPath;
    _uitoolkit = uitoolkit;
    _itemAddedBlk = itemAddedBlk;
    _itemChangedBlk = itemChangedBlk;
    _entityFormPanelMaker = entityFormPanelMaker;
    _entityViewPanelMaker = entityViewPanelMaker;
    _entityToPanelBinder = entityToPanelBinder;
    _panelToEntityBinder = panelToEntityBinder;
    _entityTitle = entityTitle;
    _entityNavbarTitle = entityNavbarTitle;
    _panelEnablerDisabler = panelEnablerDisabler;
    _entityAddCanceler = entityAddCanceler;
    _entityMaker = entityMaker;
    _entitySaver = entitySaver;
    _newEntitySaverLocal = newEntitySaverLocal;
    _newEntitySaverImmediateSync = newEntitySaverImmediateSync;
    _doneEditingEntityLocalSync = doneEditingEntityLocal;
    _doneEditingEntityImmediateSync = doneEditingEntityImmediateSync;
    _isUserLoggedIn = isUserLoggedIn;
    _isBadAccount = isBadAccount;
    _allowedToRemoteSaveWithBadAccount = allowedToRemoteSaveWithBadAccount;
    _allowedToDownloadWithBadAccount = allowedToDownloadWithBadAccount;
    _isOfflineMode = isOfflineMode;
    _syncImmediateMBProgressHUDMode = syncImmediateMBProgressHUDMode;
    _isAuthenticatedBlk = isAuthenticated;
    _prepareUIForUserInteractionBlk = prepareUIForUserInteractionBlk;
    _viewDidAppearBlk = viewDidAppearBlk;
    _entityValidator = entityValidator;
    _uploader = uploader;
    _uploadedSuccessMessage = uploadedSuccessMessage;
    _numRemoteDepsNotLocal = numRemoteDepsNotLocal;
    _fetchDependencies = fetchDependencies;
    _updateDepsPanel = updateDepsPanel;
    _downloader = downloader;
    _alreadyHaveLatestDownloadedMsg = alreadyHaveLatestDownloadedMsg;
    _postDownloadSaver = postDownloadSaver;
    _itemChildrenCounter = itemChildrenCounter;
    _itemChildrenMsgsBlk = itemChildrenMsgsBlk;
    _itemDeleter = itemDeleter;
    _itemLocalDeleter = itemLocalDeleter;
    _entitiesFromEntity = entitiesFromEntity;
    _modalOperationStarted = modalOperationStarted;
    _modalOperationDone = modalOperationDone;
    _entityAddedNotificationName = entityAddedNotificationName;
    _entityUpdatedNotificationName = entityUpdatedNotificationName;
    _entityRemovedNotificationName = entityRemovedNotificationName;
    _addlContentSection = addlContentSection;
    _scrollContentOffset = CGPointMake(0.0, 0.0);
    _hasPoppedKeyboard = NO;
    _masterEntityLoader = masterEntityLoader;
    _reauthReqdPostEditActivityBlk = reauthReqdPostEditActivityBlk;
    _actionIfReauthReqdNotifObservedBlk = actionIfReauthReqdNotifObservedBlk;
    _promptCurrentPasswordBlk = promptCurrentPasswordBlk;
    _incrementEditCountOnEditPrepare = YES;
    _panelToolkit = panelToolkit;
    _promptGoOffline = promptGoOffline;
    _importedAt = importedAt;
    _importLimitExceededMask = importLimitExceededMask;
    _hasExceededImportLimit = hasExceededImportLimit;
    _isUserVerified = isUserVerified;
    _deletedCallback = deletedCallback;
    _viewDidLoadBlk = viewDidLoadBlk;
    _dismissCallback = dismissCallback;
    _screenTitlesLogged = [NSMutableDictionary dictionary];
  }
  return self;
}

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
                                         dismissCallback:(void(^)(void))dismissCallback {
  return [PEAddViewEditController addEntityCtrlrWithUitoolkit:uitoolkit
                                           listViewController:listViewController
                                                 itemAddedBlk:itemAddedBlk
                                         entityFormPanelMaker:entityFormPanelMaker
                                          entityToPanelBinder:entityToPanelBinder
                                          panelToEntityBinder:panelToEntityBinder
                                                  entityTitle:entityTitle
                                            entityNavbarTitle:(NSString *)entityNavbarTitle
                                            entityAddCanceler:entityAddCanceler
                                                  entityMaker:entityMaker
                                          newEntitySaverLocal:newEntitySaverLocal
                                  newEntitySaverImmediateSync:newEntitySaverImmediateSync
                               prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                             viewDidAppearBlk:viewDidAppearBlk
                                              entityValidator:entityValidator
                                              isAuthenticated:isAuthenticated
                                               isUserLoggedIn:isUserLoggedIn
                                                 isBadAccount:isBadAccount
                            allowedToRemoteSaveWithBadAccount:allowedToRemoteSaveWithBadAccount
                              allowedToDownloadWithBadAccount:allowedToDownloadWithBadAccount
                                                isOfflineMode:isOfflineMode
                               syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                           entitiesFromEntity:nil
                                        modalOperationStarted:modalOperationStarted
                                           modalOperationDone:modalOperationDone
                                  entityAddedNotificationName:entityAddedNotificationName
                                           addlContentSection:addlContentSection
                                                 panelToolkit:panelToolkit
                                              promptGoOffline:promptGoOffline
                                                   importedAt:importedAt
                                      importLimitExceededMask:importLimitExceededMask
                                       hasExceededImportLimit:hasExceededImportLimit
                                               isUserVerified:isUserVerified
                                               viewDidLoadBlk:viewDidLoadBlk
                                              dismissCallback:dismissCallback];
}

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
                                         dismissCallback:(void(^)(void))dismissCallback {
  return [[PEAddViewEditController alloc] initWithParentEntity:nil
                                                        entity:nil
                                            listViewController:listViewController
                                                         isAdd:YES
                                                        isEdit:NO
                                                     indexPath:nil
                                                     uitoolkit:uitoolkit
                                                  itemAddedBlk:itemAddedBlk
                                                itemChangedBlk:nil
                                          entityFormPanelMaker:entityFormPanelMaker
                                          entityViewPanelMaker:nil
                                           entityToPanelBinder:entityToPanelBinder
                                           panelToEntityBinder:panelToEntityBinder
                                                   entityTitle:entityTitle
                                             entityNavbarTitle:entityNavbarTitle
                                          panelEnablerDisabler:nil
                                             entityAddCanceler:entityAddCanceler
                                                   entityMaker:entityMaker
                                                   entitySaver:nil
                                           newEntitySaverLocal:newEntitySaverLocal
                                   newEntitySaverImmediateSync:newEntitySaverImmediateSync
                                        doneEditingEntityLocal:nil
                                doneEditingEntityImmediateSync:nil
                                               isAuthenticated:isAuthenticated
                                                isUserLoggedIn:isUserLoggedIn
                                                  isBadAccount:isBadAccount
                             allowedToRemoteSaveWithBadAccount:allowedToRemoteSaveWithBadAccount
                               allowedToDownloadWithBadAccount:allowedToDownloadWithBadAccount
                                                 isOfflineMode:isOfflineMode
                                syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                              viewDidAppearBlk:viewDidAppearBlk
                                               entityValidator:entityValidator
                                                      uploader:nil
                                        uploadedSuccessMessage:nil
                                         numRemoteDepsNotLocal:nil
                                             fetchDependencies:nil
                                               updateDepsPanel:nil
                                                    downloader:nil
                                alreadyHaveLatestDownloadedMsg:nil
                                             postDownloadSaver:nil
                                           itemChildrenCounter:nil
                                           itemChildrenMsgsBlk:nil
                                                   itemDeleter:nil
                                              itemLocalDeleter:nil
                                            entitiesFromEntity:entitiesFromEntity
                                         modalOperationStarted:modalOperationStarted
                                            modalOperationDone:modalOperationDone
                                   entityAddedNotificationName:entityAddedNotificationName
                                 entityUpdatedNotificationName:nil
                                 entityRemovedNotificationName:nil
                                            addlContentSection:addlContentSection
                                            masterEntityLoader:nil
                                 reauthReqdPostEditActivityBlk:nil
                            actionIfReauthReqdNotifObservedBlk:nil
                                      promptCurrentPasswordBlk:nil
                                                  panelToolkit:panelToolkit
                                               promptGoOffline:promptGoOffline
                                                    importedAt:importedAt
                                       importLimitExceededMask:importLimitExceededMask
                                        hasExceededImportLimit:hasExceededImportLimit
                                                isUserVerified:isUserVerified
                                               deletedCallback:nil
                                                viewDidLoadBlk:viewDidLoadBlk
                                               dismissCallback:dismissCallback];
}

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
                                             dismissCallback:(void(^)(void))dismissCallback {
  return [[PEAddViewEditController alloc] initWithParentEntity:parentEntity
                                                        entity:entity
                                            listViewController:listViewController
                                                         isAdd:NO
                                                        isEdit:NO
                                                     indexPath:entityIndexPath
                                                     uitoolkit:uitoolkit
                                                  itemAddedBlk:nil
                                                itemChangedBlk:itemChangedBlk
                                          entityFormPanelMaker:entityFormPanelMaker
                                          entityViewPanelMaker:entityViewPanelMaker
                                           entityToPanelBinder:entityToPanelBinder
                                           panelToEntityBinder:panelToEntityBinder
                                                   entityTitle:entityTitle
                                             entityNavbarTitle:(NSString *)entityNavbarTitle
                                          panelEnablerDisabler:panelEnablerDisabler
                                             entityAddCanceler:entityAddCanceler
                                                   entityMaker:nil
                                                   entitySaver:entitySaver
                                           newEntitySaverLocal:nil
                                   newEntitySaverImmediateSync:nil
                                        doneEditingEntityLocal:doneEditingEntityLocal
                                doneEditingEntityImmediateSync:doneEditingEntityImmediateSync
                                               isAuthenticated:isAuthenticated
                                                isUserLoggedIn:isUserLoggedIn
                                                  isBadAccount:isBadAccount
                             allowedToRemoteSaveWithBadAccount:allowedToRemoteSaveWithBadAccount
                               allowedToDownloadWithBadAccount:allowedToDownloadWithBadAccount
                                                 isOfflineMode:isOfflineMode
                                syncImmediateMBProgressHUDMode:syncImmediateMBProgressHUDMode
                                prepareUIForUserInteractionBlk:prepareUIForUserInteractionBlk
                                              viewDidAppearBlk:viewDidAppearBlk
                                               entityValidator:entityValidator
                                                      uploader:uploader
                                        uploadedSuccessMessage:uploadedSuccessMessage
                                         numRemoteDepsNotLocal:numRemoteDepsNotLocal                                                         
                                             fetchDependencies:fetchDependencies
                                               updateDepsPanel:updateDepsPanel
                                                    downloader:downloader
                                alreadyHaveLatestDownloadedMsg:alreadyHaveLatestDownloadedMsg
                                             postDownloadSaver:postDownloadSaver
                                           itemChildrenCounter:itemChildrenCounter
                                           itemChildrenMsgsBlk:itemChildrenMsgsBlk
                                                   itemDeleter:itemDeleter
                                              itemLocalDeleter:itemLocalDeleter
                                            entitiesFromEntity:nil
                                         modalOperationStarted:modalOperationStarted
                                            modalOperationDone:modalOperationDone
                                   entityAddedNotificationName:nil
                                 entityUpdatedNotificationName:entityUpdatedNotificationName
                                 entityRemovedNotificationName:entityRemovedNotificationName
                                            addlContentSection:nil
                                            masterEntityLoader:masterEntityLoader
                                 reauthReqdPostEditActivityBlk:reauthReqdPostEditActivityBlk
                            actionIfReauthReqdNotifObservedBlk:actionIfReauthReqdNotifObservedBlk
                                      promptCurrentPasswordBlk:promptCurrentPasswordBlk
                                                  panelToolkit:panelToolkit
                                               promptGoOffline:promptGoOffline
                                                    importedAt:importedAt
                                       importLimitExceededMask:importLimitExceededMask
                                        hasExceededImportLimit:hasExceededImportLimit
                                                isUserVerified:isUserVerified
                                               deletedCallback:deletedCallback
                                                viewDidLoadBlk:viewDidLoadBlk
                                               dismissCallback:dismissCallback];
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  _scrollContentOffset = [scrollView contentOffset];
}

#pragma mark - Reset Scroll Offset

- (void)resetScrollOffset {
  _scrollContentOffset = CGPointMake(0.0, 0.0);
}

#pragma mark - Dynamic Type notification

- (void)changeTextSize:(NSNotification *)notification {
  [self viewDidAppear:YES];
}

#pragma mark - Device Rotation notification

- (void)deviceRotated:(NSNotification *)notification {
  // For some reason, I need to have a delay here or the value of 'newOrientation'
  // will be old (for some reason, after a rotate, the value of [UIApplication sharedApplication].statusBarOrientation
  // takes a bit of time to actually reflect the new orientation).  So far, I'm only
  // seeing this delay on iPad, FYI.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    UIInterfaceOrientation newOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (_currentOrientation == newOrientation) {
      return;
    }
    _deviceWasRotated = YES;
    _currentOrientation = newOrientation;
    // we only want the currently-visible controller's viewDidAppear to be invoked
    if (self.isViewLoaded && self.view.window) { // http://stackoverflow.com/a/2777460/1034895      
      [self viewDidAppear:YES];
      MBProgressHUD *hud = [self.view viewWithTag:RHUD_TAG];
      if (hud && !hud.isHidden) {
        [self.view bringSubviewToFront:hud];
      }
    }
  });
}

#pragma mark - Offline notification handlers

- (void)offlineModeToggledOn:(NSNotification *)notification {
  [PEUIUtils addOfflineModeBarToController:self animate:YES];
}

- (void)offlineModeToggledOff:(NSNotification *)notification {
  [PEUIUtils removeOfflineModeBarFromController:self animated:YES];
}

#pragma mark - Hide Keyboard

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - Dismiss

- (void)dismiss {
  UINavigationController *navController = [self navigationController];
  if (navController.viewControllers.count == 1) {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  } else {
    [navController popViewControllerAnimated:YES];
  }
  if (_dismissCallback) {
    _dismissCallback();
  }
}

#pragma mark - View Controller Lifecyle

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (_isAdd) {
    id tmpEntity = _entityMaker(_entityFormPanel);
    UIView *tmpNewFormPanel = _entityFormPanelMaker(self);
    [_entityFormPanel removeFromSuperview];
    _entityFormPanel = tmpNewFormPanel;
    [PEUIUtils placeView:_entityFormPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];
    _entityToPanelBinder(tmpEntity, _entityFormPanel);
    if (_prepareUIForUserInteractionBlk) {
      _prepareUIForUserInteractionBlk(self, _entityFormPanel);
    }
  } else {
    /*[_entityViewPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
    [PEUIUtils placeView:_entityViewPanel atTopOf:self.view withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0.0 hpadding:0.0];*/
  }
  if (_viewDidAppearBlk) {
    _viewDidAppearBlk(self);
  }
  [PEUIUtils removeOfflineModeBarFromController:self animated:NO];
  if ([APP offlineMode]) {
    [PEUIUtils addOfflineModeBarToController:self animate:NO];
  }
  _deviceWasRotated = NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeTextSize:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceRotated:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reauthReqdNotification:)
                                               name:RAppReauthReqdNotification
                                             object:nil];
  UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [gestureRecognizer setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:gestureRecognizer];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  _leftBarButtonItem = [navItem leftBarButtonItem];
  UINavigationController *navController = [self navigationController];
  NSInteger numControllers = [navController viewControllers].count;
  if (numControllers == 1) {
    _leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss"
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(dismiss)];
    [navItem setLeftBarButtonItem:_leftBarButtonItem];
  }
  
  [self setEdgesForExtendedLayout:UIRectEdgeNone];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  _entityFormPanel = _entityFormPanelMaker(self);
  if (_entityViewPanelMaker) {
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
  }
  void (^placeAndBindEntityPanel)(UIView *, BOOL) = ^(UIView *entityPanel, BOOL doBind) {
    [PEUIUtils placeView:entityPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:0
                hpadding:0];
    if (doBind) {
      _entityToPanelBinder(_entity, entityPanel);
    }
  };
  if (_isView) {
    placeAndBindEntityPanel(_entityViewPanel, NO);
  } else if (_isEdit) {
    placeAndBindEntityPanel(_entityFormPanel, YES);
    [self prepareForEditing];
  } else {
    placeAndBindEntityPanel(_entityFormPanel, YES);
  }

  // ---------------------------------------------------------------------------
  // Setup the navigation item (left/center/right areas)
  // ---------------------------------------------------------------------------
  UIBarButtonItem *(^newSysItem)(UIBarButtonSystemItem, SEL) = ^ UIBarButtonItem *(UIBarButtonSystemItem item, SEL selector) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:selector];
  };
  if (_isAdd) {
    [navItem setLeftBarButtonItem:newSysItem(UIBarButtonSystemItemCancel, @selector(cancelAdd))];
  }
  [self updateTitle];
  [self setRightBarButonItems];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(offlineModeToggledOn:)
                                               name:ROfflineModeToggledOnNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(offlineModeToggledOff:)
                                               name:ROfflineModeToggledOffNotification
                                             object:nil];
  if ([APP offlineMode]) {
    [PEUIUtils addOfflineModeBarToController:self animate:NO];
  }
  if (_viewDidLoadBlk) {
    _viewDidLoadBlk();
  }
}

- (void)reauthReqdNotification:(NSNotification *)reauthReqdNotification {
  if (_actionIfReauthReqdNotifObservedBlk) {
    _actionIfReauthReqdNotifObservedBlk(self);
  }
}

- (void)updateTitle {
  NSString *title;
  if (_isEdit) {
    title = [NSString stringWithFormat:@"Edit %@", _entityNavbarTitle];
  } else if (_isView) {
    title = [NSString stringWithFormat:@"%@ Detail", _entityNavbarTitle];
  } else {
    title = [NSString stringWithFormat:@"Add %@", _entityNavbarTitle];
  }
  NSString *screenTitleToLog = _screenTitlesLogged[title];
  if (!screenTitleToLog) {
    [RUtils logScreen:title fromController:self];
    _screenTitlesLogged[title] = title;
  }
  UINavigationItem *navItem = [self navigationItem];
  // there's enough space if either of these is true to display the title
  if ([PEUIUtils isIpad] || !_isUserLoggedIn()) {
    [navItem setTitleView:[self titleWithText:title]];
  } else {
    if (_isAdd) { // title only fits on adds
      [navItem setTitleView:[self titleWithText:title]];
    }
  }
  [RUIUtils styleNavbarForController:self];
}

- (void)setRightBarButonItems {
  UINavigationItem *navItem = [self navigationItem];
  [navItem setRightBarButtonItems:@[]];
  UIBarButtonItem *(^newSysItem)(UIBarButtonSystemItem, SEL) = ^ UIBarButtonItem *(UIBarButtonSystemItem item, SEL selector) {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:selector];
  };
  UIBarButtonItem *(^newImgItem)(NSString *, SEL) = ^ UIBarButtonItem * (NSString *imgName, SEL selector) {
    UIBarButtonItem *item =
    [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:selector];
    [item setImage:[UIImage imageNamed:imgName]];
    return item;
  };
  NSMutableArray *rightBarButtonItems = [NSMutableArray array];
  if (_isView) {
    [rightBarButtonItems addObject:[self editButtonItem]];
  } else {
    if (_isAdd) {
      [rightBarButtonItems addObject:newSysItem(UIBarButtonSystemItemDone, @selector(doneWithAdd))];
    } else {
      [rightBarButtonItems addObject:newSysItem(UIBarButtonSystemItemDone, @selector(doneWithEdit))];
    }
  }
  if (_isUserLoggedIn()) {
    _uploadBarButtonItem = newImgItem(@"upload-icon", @selector(doUpload));
    _downloadBarButtonItem = newImgItem(@"download-icon", @selector(doDownload));
    if (_uploader) { [rightBarButtonItems addObject:_uploadBarButtonItem]; }
    if (_downloader) { [rightBarButtonItems addObject:_downloadBarButtonItem]; }
  }
  if (_itemDeleter) {
    _deleteBarButtonItem = newImgItem(@"delete-icon", @selector(promptDoDelete));
    [rightBarButtonItems addObject:_deleteBarButtonItem];
  }
  if ([APP isUserLoggedIn] && !_isAdd) {
    [rightBarButtonItems addObject:newImgItem(@"question-mark-icon", @selector(popIconHelp))];
  }
  [navItem setRightBarButtonItems:rightBarButtonItems animated:YES];
  [self setUploadDownloadDeleteBarButtonStates];
}

#pragma mark - JGActionSheetDelegate and Alert-related Helpers

- (void)actionSheetWillPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidPresent:(JGActionSheet *)actionSheet {}

- (void)actionSheetWillDismiss:(JGActionSheet *)actionSheet {}

- (void)actionSheetDidDismiss:(JGActionSheet *)actionSheet {}

#pragma mark - Notification Helpers

- (NSDictionary *)userInfoDictForNotifications {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  [userInfo setObject:_entity forKey:@"entity"];
  if (_entityIndexPath) {
    [userInfo setObject:_entityIndexPath forKey:@"indexPath"];
  }
  return userInfo;
}

#pragma mark - Uploading and Downloading (Sync)

- (void)setUploadDownloadDeleteBarButtonStates {
  [self setUploadBarButtonState];
  [self setDownloadBarButtonState];
  [self setDeleteBarButtonState];
}

- (void)setUploadBarButtonState {
  BOOL enableUploadItem = NO;
  if (_entity) {
    BOOL importLimitExceeded =
      [PEUtils isNotNil:_importLimitExceededMask] &&
      [PEUtils isNotNil:[_entity syncErrMask]] &&
      [_importLimitExceededMask isEqualToNumber:[_entity syncErrMask]];
    if (_uploader &&
        _isAuthenticatedBlk() &&
        [_entity localMainIdentifier] &&
        ![_entity synced] &&
        (!([_entity syncErrMask] &&
          ([_entity syncErrMask].integerValue > 0)) || importLimitExceeded)) {
      enableUploadItem = YES;
    }
  }
  [_uploadBarButtonItem setEnabled:enableUploadItem];
}

- (void)setDownloadBarButtonState {
  BOOL enableDownloadItem = NO;
  if (_entity) {
    if (_isAuthenticatedBlk() &&
        ([_entity synced] ||
         ([_entity localMainIdentifier] == nil) ||
         ([_entity editCount] == 0))) {
      enableDownloadItem = YES;
    }
  }
  [_downloadBarButtonItem setEnabled:enableDownloadItem];
}

- (void)setDeleteBarButtonState {
  BOOL enableDeleteItem = NO;
  if (_entity) {
    if (_isUserLoggedIn()) {
      if (_isAuthenticatedBlk() && YES // I can't remember why I put those below conditions in-place for enabling the delete icon
          /*([_entity synced] ||
           ([PEUtils isNil:[_entity localMainIdentifier]]) ||
           ([_entity editCount] == 0) ||
           ([PEUtils isNil:[_entity globalIdentifier]]))*/) {
        enableDeleteItem = YES;
      }
    } else {
      enableDeleteItem = YES;
    }
  }
  [_deleteBarButtonItem setEnabled:enableDeleteItem];
}

- (void)promptDoDelete {
  [self.view endEditing:YES];
  void (^deleter)(void) = ^{
    [PEUIUtils showConfirmAlertWithTitle:@"Are you sure?"
                              titleImage:nil //[UIImage imageNamed:@"question"]
                        alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Are you sure you want to delete this %@?", [_entityTitle lowercaseString]]]
                     descLblHeightAdjust:0.0
                                topInset:[PEUIUtils topInsetForAlertsWithController:self]
                         okayButtonTitle:@"Yes.  Delete it."
                        okayButtonAction:^{ [self doDelete]; }
                         okayButtonStyle:JGActionSheetButtonStyleRed
                       cancelButtonTitle:@"No.  Cancel."
                      cancelButtonAction:^{}
                        cancelButtonSyle:JGActionSheetButtonStyleDefault
                          relativeToView:[self parentViewForAlerts]];
  };
  if (_itemChildrenCounter) {
    NSInteger numChildren = _itemChildrenCounter(_entity);
    if (numChildren > 0) {
      [PEUIUtils showWarningConfirmAlertWithMsgs:_itemChildrenMsgsBlk(_entity)
                                           title:@"Are you sure?"
                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
Deleting this record will result in the following child-records being deleted.\n\n\
Are you sure you want to continue?"]
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                 okayButtonTitle:@"Yes, delete."
                                okayButtonAction:^{ [self doDelete]; }
                               cancelButtonTitle:@"No, cancel."
                              cancelButtonAction:^{}
                                  relativeToView:[self parentViewForAlerts]];
    } else {
      deleter();
    }
  } else {
    deleter();
  }
}

- (void)doDelete {
  NSMutableArray *errorsForDelete = [NSMutableArray array];
  // The meaning of the elements of the arrays found within errorsForDelete:
  //
  // errorsForDelete[*][0]: Error title (string)
  // errorsForDelete[*][1]: Is error user-fixable (bool)
  // errorsForDelete[*][2]: An NSArray of sub-error messages (strings)
  // errorsForDelete[*][3]: Is error type server busy (bool)
  // errorsForDelete[*][4]: Is error conflict-type (bool) - NA!
  // errorsForDelete[*][5]: Latest entity for conflict error - NA!
  // errorsForDelete[*][6]: Entity not found (bool)
  //
  NSMutableArray *successMessageTitlesForDelete = [NSMutableArray array];
  __block BOOL receivedAuthReqdErrorOnDeleteAttempt = NO;
  __block BOOL receivedForbiddenErrorOnDeleteAttempt = NO;
  if ([_entity globalIdentifier] && [APP isUserLoggedIn]) {
    if ([APP doesUserHaveValidAuthToken] && !_isBadAccount()) {
      __block MBProgressHUD *deleteHud;
      [self disableUi];
      void(^immediateDelDone)(NSString *) = ^(NSString *mainMsgTitle) {
        if ([errorsForDelete count] == 0) { // success
          dispatch_async(dispatch_get_main_queue(), ^{
            [deleteHud hideAnimated:YES];
            [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ deleted.", [_entityTitle sentenceCase]]
                                alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForDelete[0]]
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{
                                      [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                                          object:self
                                                                                        userInfo:[self userInfoDictForNotifications]];
                                      if (_modalOperationDone) { _modalOperationDone(); }
                                      [self dismiss];
                                      if (_deletedCallback) {
                                        _deletedCallback();
                                      }
                                    }
                                  relativeToView:[self parentViewForAlerts]];
            
          });
        } else { // error
          dispatch_async(dispatch_get_main_queue(), ^{
            [deleteHud hideAnimated:YES afterDelay:0];
            if ([errorsForDelete[0][3] boolValue]) { // server is busy
              [self handleServerBusyErrorWithAction:^{ [self enableUi]; }
                                  showOfflineOption:YES];
            } else if ([errorsForDelete[0][6] boolValue]) { // not found
              [PEUIUtils showInfoAlertWithTitle:@"Already deleted."
                               alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\
It looks like this %@ was already deleted from a different device. \
It has now been removed from this device.", [_entityTitle lowercaseString]]]
                            descLblHeightAdjust:0.0
                      additionalContentSections:nil
                                       topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                    buttonTitle:@"Okay."
                                   buttonAction:^{
                                     _itemLocalDeleter(self, _entity, _entityIndexPath);
                                     [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                                         object:self
                                                                                       userInfo:[self userInfoDictForNotifications]];
                                     if (_modalOperationDone) { _modalOperationDone(); }
                                     [self dismiss];
                                     if (_deletedCallback) {
                                       _deletedCallback();
                                     }
                                   }
                                 relativeToView:[self parentViewForAlerts]];
            } else { // any other error type
              NSString *title;
              NSString *message;
              NSArray *subErrors = errorsForDelete[0][2];
              NSString *entityTitleLowercase = [_entityTitle lowercaseString];
              if ([subErrors count] > 1) {
                message = [NSString stringWithFormat:@"There were problems deleting your %@ from the server.  The errors are as follows:", entityTitleLowercase];
                title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
              } else {
                message = [NSString stringWithFormat:@"There was a problem deleting your %@ from the server.  The error is as follows:", entityTitleLowercase];
                title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
              }
              NSMutableArray *sections = [NSMutableArray array];
              [sections addObject:[PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                 title:title
                                                      alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                   descLblHeightAdjust:0.0
                                                        relativeToView:[self parentViewForAlerts]]];
              if (receivedAuthReqdErrorOnDeleteAttempt) {
                [sections addObject:[PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              if (receivedForbiddenErrorOnDeleteAttempt) {
                [sections addObject:[PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                    message:nil
                                                                               buttonTitles:@[@"Okay."]
                                                                                buttonStyle:JGActionSheetButtonStyleDefault];
              [sections addObject:buttonsSection];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *btnIndexPath) {
                if (receivedAuthReqdErrorOnDeleteAttempt) {
                  [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                      object:self
                                                                    userInfo:nil];
                }
                [self enableUi];
                [sheet dismissAnimated:YES];
              }];
              [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
            }
          });
        }
      };
      void(^delNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Not found."]],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:YES]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                              NSString *mainMsgTitle,
                                                              NSString *recordTitle) {
        [successMessageTitlesForDelete addObject:[NSString stringWithFormat:@"%@ deleted successfully.", recordTitle]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSDate *retryAfter) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Server undergoing maintnenace.  Try again later."]],
                                     [NSNumber numberWithBool:YES],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^delServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Temporary server error."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^delServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSArray *computedErrMsgs) {
        BOOL isErrorUserFixable = YES;
        if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
          computedErrMsgs = @[@"Unknown server error."];
          isErrorUserFixable = NO;
        }
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:isErrorUserFixable],
                                     computedErrMsgs,
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        receivedAuthReqdErrorOnDeleteAttempt = YES;
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Authentication required."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void(^delForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        receivedForbiddenErrorOnDeleteAttempt = YES;
        [errorsForDelete addObject:@[[NSString stringWithFormat:@"%@ not deleted.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Not permitted."],
                                     [NSNumber numberWithBool:NO],
                                     [NSNumber numberWithBool:NO],
                                     [NSNull null],
                                     [NSNumber numberWithBool:NO]]];
        immediateDelDone(mainMsgTitle);
      };
      void (^deleteRemoteItem)(void) = ^{
        deleteHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        deleteHud.delegate = self;
        deleteHud.tag = RHUD_TAG;
        deleteHud.label.text = @"Deleting from server...";
        [errorsForDelete removeAllObjects];
        [successMessageTitlesForDelete removeAllObjects];
        receivedAuthReqdErrorOnDeleteAttempt = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          _itemDeleter(self,
                       _entity,
                       _entityIndexPath,
                       delNotFoundBlk,
                       delSuccessBlk,
                       delRetryAfterBlk,
                       delServerTempError,
                       delServerError,
                       delAuthReqdBlk,
                       delForbiddenBlk);
        });
      };
      deleteRemoteItem();
    } else {
      if (![APP doesUserHaveValidAuthToken]) {
        [self showNotCurrentlyAuthenticatedWarning];
      } else {
        [self showBadAccountWarning];
      }
    }
  } else {
    _itemLocalDeleter(self, _entity, _entityIndexPath);
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                          object:self
                                                        userInfo:[self userInfoDictForNotifications]];
      if (_modalOperationDone) { _modalOperationDone(); }
      [self dismiss];
      if (_deletedCallback) {
        _deletedCallback();
      }
    });
  }
}

- (void)doDownload {
  if ([APP doesUserHaveValidAuthToken] && (!_isBadAccount() || _allowedToDownloadWithBadAccount)) {
    __block BOOL receivedAuthReqdErrorOnDownloadAttempt = NO;
    __block BOOL receivedForbiddenErrorOnDownloadAttempt = NO;
    __block CGFloat percentCompleteDownloadingEntity = 0.0;
    NSMutableArray *successMsgsForEntityDownload = [NSMutableArray array];
    NSMutableArray *errsForEntityDownload = [NSMutableArray array];
    // The meaning of the elements of the arrays found within errsForEntityDownload:
    //
    // errsForEntityDownload[*][0]: Error title (string)
    // errsForEntityDownload[*][1]: Is error user-fixable (bool)
    // errsForEntityDownload[*][2]: An NSArray of sub-error messages (strings)
    // errsForEntityDownload[*][3]: Is error type server-busy? (bool)
    // errsForEntityDownload[*][4]: Is entity not found (bool)
    //
    MBProgressHUD *downloadHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    downloadHud.tag = RHUD_TAG;
    [self disableUi];
    downloadHud.label.text = [NSString stringWithFormat:@"Downloading latest..."];
    void (^handleHudProgress)(float) = ^(float percentComplete) {
      percentCompleteDownloadingEntity += percentComplete;
      dispatch_async(dispatch_get_main_queue(), ^{
        downloadHud.progress = percentCompleteDownloadingEntity;
      });
    };
    void (^postDownloadActivities)(void) = ^{
      if (_itemChangedBlk) {
        _itemChangedBlk(_entity, _entityIndexPath);
      }
      [self enableUi];
      [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                          object:self
                                                        userInfo:[self userInfoDictForNotifications]];
      [_entityViewPanel removeFromSuperview];
      _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
      [PEUIUtils placeView:_entityViewPanel
                   atTopOf:[self view]
             withAlignment:PEUIHorizontalAlignmentTypeCenter
                  vpadding:0
                  hpadding:0];
      [PEUIUtils bringOfflineModeViewsToFrontForController:self];
    };
    void(^entityDownloadDone)(NSString *) = ^(NSString *mainMsgTitle) {
      if ([errsForEntityDownload count] == 0) { // success
        dispatch_async(dispatch_get_main_queue(), ^{
          [downloadHud hideAnimated:YES afterDelay:0.0];
          PELMMainSupport *downloadedEntity = successMsgsForEntityDownload[0][1];
          if ([downloadedEntity isEqual:[NSNull null]]) {
            [PEUIUtils showSuccessAlertWithTitle:@"You already have the latest."
                                alertDescription:[[NSAttributedString alloc] initWithString:_alreadyHaveLatestDownloadedMsg]
                             descLblHeightAdjust:0.0
                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                     buttonTitle:@"Okay."
                                    buttonAction:^{ [self enableUi]; }
                                  relativeToView:[self parentViewForAlerts]];
          } else {
            void (^fetchDepsThenTakeAction)(void(^)(void)) = [self downloadDepsForEntity:downloadedEntity
                                                               dismissErrAlertPostAction:^{ [self enableUi]; }];
            fetchDepsThenTakeAction(^{
              // If we're here, it means the entity was downloaded, and if it had any
              // dependencies, they were also successfully downloaded (if they *needed*
              // to be downloaded).  Also, this block executes on the main thread.
              [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ downloaded.", [_entityTitle sentenceCase]]
                                  alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\
The latest version of this %@ has been successfully downloaded to your device.", [_entityTitle lowercaseString]]]
                               descLblHeightAdjust:0.0
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                       buttonTitle:@"Okay."
                                      buttonAction:^{
                                        [_entity setUpdatedAt:[downloadedEntity updatedAt]];
                                        [_entity overwriteDomainProperties:downloadedEntity];
                                        downloadedEntity.localMasterIdentifier = _entity.localMasterIdentifier;
                                        _postDownloadSaver(self, downloadedEntity, _entity);
                                        postDownloadActivities();
                                      }
                                    relativeToView:[self parentViewForAlerts]];
            });
          }
        });
      } else { // error(s)
        dispatch_async(dispatch_get_main_queue(), ^{
          [downloadHud hideAnimated:YES afterDelay:0.0];
          if ([errsForEntityDownload[0][3] boolValue]) { // server busy
            [self handleServerBusyErrorWithAction:^{ [self enableUi]; }
                                showOfflineOption:YES];
          } else if ([errsForEntityDownload[0][4] boolValue]) { // not found
            [self handleNotFoundError];
          } else { // any other error type
            NSString *fetchErrMsg = [NSString stringWithFormat:@"There was a problem downloading the %@ record.", [_entityTitle lowercaseString]];
            JGActionSheetSection *addlSection = nil;
            if (receivedAuthReqdErrorOnDownloadAttempt) {
              addlSection = [PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]];
            } else if (receivedForbiddenErrorOnDownloadAttempt) {
              addlSection = [PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]];
            }
            [PEUIUtils showErrorAlertWithMsgs:errsForEntityDownload[0][2]
                                        title:@"Download error."
                             alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                          descLblHeightAdjust:0.0
                    additionalContentSections:addlSection != nil ? @[addlSection] : nil
                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                  buttonTitle:@"Okay."
                                 buttonAction:^{
                                   [self enableUi];
                                   if (receivedAuthReqdErrorOnDownloadAttempt) {
                                     [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                                         object:self
                                                                                       userInfo:nil];
                                   }
                                 }
                               relativeToView:[self parentViewForAlerts]];
          }
        });
      }
    };
    void(^downloadNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
      handleHudProgress(percentComplete);
      [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[[NSString stringWithFormat:@"Not found."]],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:YES]]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    PEDownloadSuccessBlk downloadSuccessBlk = ^(float percentComplete,
                                                NSString *mainMsgTitle,
                                                NSString *recordTitle,
                                                id downloadedEntity) {
      handleHudProgress(percentComplete);
      if (downloadedEntity == nil) { // server responded with 304
        downloadedEntity = [NSNull null];
      }
      [successMsgsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ downloaded.", recordTitle],
                                                downloadedEntity]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    void(^downloadRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                              NSString *mainMsgTitle,
                                                                              NSString *recordTitle,
                                                                              NSDate *retryAfter) {
      handleHudProgress(percentComplete);
      [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                         [NSNumber numberWithBool:YES],
                                         [NSNumber numberWithBool:NO]]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    void (^downloadServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                       NSString *mainMsgTitle,
                                                                       NSString *recordTitle) {
      handleHudProgress(percentComplete);
      [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Temporary server error."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO]]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    void(^downloadAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
      receivedAuthReqdErrorOnDownloadAttempt = YES;
      handleHudProgress(percentComplete);
      [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Authentication required."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO]]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    void(^downloadForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                   NSString *mainMsgTitle,
                                                                   NSString *recordTitle) {
      receivedForbiddenErrorOnDownloadAttempt = YES;
      handleHudProgress(percentComplete);
      [errsForEntityDownload addObject:@[[NSString stringWithFormat:@"%@ not downloaded.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Not permitted."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO]]];
      if (percentCompleteDownloadingEntity == 1.0) { entityDownloadDone(mainMsgTitle); }
    };
    _downloader(self,
                _entity,
                downloadNotFoundBlk,
                downloadSuccessBlk,
                downloadRetryAfterBlk,
                downloadServerTempError,
                downloadAuthReqdBlk,
                downloadForbiddenBlk);
  } else {
    if (![APP doesUserHaveValidAuthToken]) {
      [self showNotCurrentlyAuthenticatedWarning];
    } else {
      [self showBadAccountWarning];
    }
  }
}

- (NSArray *)importBooleans {
  BOOL allowedToSyncImport = YES;
  BOOL importLimitExceeded = NO;
  if ([PEUtils isNil:_entity.globalIdentifier] &&
      [PEUtils isNotNil:_importedAt] &&
      [PEUtils isNotNil:_importedAt(_entity)]) {
    if (_isUserVerified) {
      if (!_isUserVerified()) {
        allowedToSyncImport = NO;
      }
    }
    if (_hasExceededImportLimit) {
      importLimitExceeded = _hasExceededImportLimit();
    }
  }
  return @[@(allowedToSyncImport), @(importLimitExceeded)];
}

- (void)doUpload {
  NSArray *importBooleans = [self importBooleans];
  BOOL allowedToSyncImport = [(NSNumber *)importBooleans[0] boolValue];
  BOOL importLimitExceeded = [(NSNumber *)importBooleans[1] boolValue];
  if ([APP doesUserHaveValidAuthToken] && !_isBadAccount() && !importLimitExceeded && allowedToSyncImport) {
    void (^postUploadActivities)(void) = ^{
      if (_itemChangedBlk) {
        _itemChangedBlk(_entity, _entityIndexPath);
      }
      _isView = YES;
      [self enableUi];
      _panelEnablerDisabler(_entityFormPanel, NO);
      [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                          object:self
                                                        userInfo:[self userInfoDictForNotifications]];
    };
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.tag = RHUD_TAG;
    [self disableUi];
    HUD.delegate = self;
    HUD.mode = _syncImmediateMBProgressHUDMode;
    HUD.label.text = @"Uploading to server.";
    __block float percentCompleteUploadingEntity = 0.0;
    HUD.progress = percentCompleteUploadingEntity;
    NSMutableArray *errorsForUpload = [NSMutableArray array];
    // The meaning of the elements of the arrays found within errorsForUpload:
    //
    // errorsForUpload[*][0]: Error title (string)
    // errorsForUpload[*][1]: Is error user-fixable (bool)
    // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
    // errorsForUpload[*][3]: Is error type server busy (bool)
    // errorsForUpload[*][4]: Is error conflict-type (bool) NA!
    // errorsForUpload[*][5]: Latest entity for conflict error NA!
    // errorsForUpload[*][6]: Entity not found (bool)
    //
    NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
    __block BOOL receivedAuthReqdErrorOnUploadAttempt = NO;
    __block BOOL receivedForbiddenErrorOnUploadAttempt = NO;
    void(^uploadDone)(NSString *) = ^(NSString *mainMsgTitle) {
      if ([errorsForUpload count] == 0) { // success
        dispatch_async(dispatch_get_main_queue(), ^{
          [HUD hideAnimated:YES afterDelay:0.0];
          [PEUIUtils showSuccessAlertWithTitle:@"Uploaded."
                              alertDescription:[[NSAttributedString alloc] initWithString:_uploadedSuccessMessage]
                           descLblHeightAdjust:0.0
                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                   buttonTitle:@"Okay."
                                  buttonAction:^{ postUploadActivities(); }
                                relativeToView:[self parentViewForAlerts]];
        });
      } else { // error
        dispatch_async(dispatch_get_main_queue(), ^{
          [HUD hideAnimated:YES afterDelay:0];
          if ([errorsForUpload[0][3] boolValue]) { // server is busy
            [self handleServerBusyErrorWithAction:^{ postUploadActivities(); }
                                showOfflineOption:YES];
          } else if ([errorsForUpload[0][6] boolValue]) { // not found
            [self handleNotFoundError];
          } else {  // any other error type
            NSString *title;
            NSString *okayActionTitle = @"Okay.  I'll try again later.";
            NSString *message;
            NSArray *subErrors = errorsForUpload[0][2];
            if ([subErrors count] > 1) {
              message = @"There were problems uploading to the server.  The errors are as follows:";
              title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
            } else {
              message = @"There was a problem uploading to the server.  The error is as follows:";
              title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
            }
            JGActionSheetSection *addlSection = nil;
            if (receivedAuthReqdErrorOnUploadAttempt) {
              addlSection = [PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]];
            } else if (receivedForbiddenErrorOnUploadAttempt) {
              addlSection = [PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]];
            }
            JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                  title:title
                                                                       alertDescription:[[NSAttributedString alloc] initWithString:message]
                                                                    descLblHeightAdjust:0.0
                                                                         relativeToView:[self parentViewForAlerts]];
            JGActionSheetSection *buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                                  message:nil
                                                                             buttonTitles:@[okayActionTitle]
                                                                              buttonStyle:JGActionSheetButtonStyleDefault];
            JGActionSheet *alertSheet;
            if (addlSection) {
              alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, addlSection, buttonsSection]];
            } else {
              alertSheet = [JGActionSheet actionSheetWithSections:@[contentSection, buttonsSection]];
            }
            [alertSheet setDelegate:self];
            [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
            [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
              switch ([indexPath row]) {
                case 0: // okay
                  postUploadActivities();
                  if (receivedAuthReqdErrorOnUploadAttempt) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                        object:self
                                                                      userInfo:nil];
                  }
                  [sheet dismissAnimated:YES];
                  break;
              };
            }];
            [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
          }
        });
      }
    };
    void (^handleHudProgress)(float) = ^(float percentComplete) {
      percentCompleteUploadingEntity += percentComplete;
      dispatch_async(dispatch_get_main_queue(), ^{
        HUD.progress = percentCompleteUploadingEntity;
      });
    };
    void(^uploadNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Not found."]],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:YES]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
      handleHudProgress(percentComplete);
      [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server successfully.", recordTitle]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                            NSString *mainMsgTitle,
                                                                            NSString *recordTitle,
                                                                            NSDate *retryAfter) {
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                   [NSNumber numberWithBool:YES],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Temporary server error."],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSArray *computedErrMsgs) {
      handleHudProgress(percentComplete);
      BOOL isErrorUserFixable = YES;
      if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
        computedErrMsgs = @[@"Unknown server error."];
        isErrorUserFixable = NO;
      }
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                   [NSNumber numberWithBool:isErrorUserFixable],
                                   computedErrMsgs,
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
      receivedAuthReqdErrorOnUploadAttempt = YES;
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Authentication required."],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
      receivedForbiddenErrorOnUploadAttempt = YES;
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[@"Not permitted."],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    void(^uploadDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                      NSString *mainMsgTitle,
                                                                                      NSString *recordTitle,
                                                                                      NSString *dependencyErrMsg) {
      handleHudProgress(percentComplete);
      [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not uploaded.", recordTitle],
                                   [NSNumber numberWithBool:NO],
                                   @[dependencyErrMsg],
                                   [NSNumber numberWithBool:NO],
                                   [NSNumber numberWithBool:NO],
                                   [NSNull null],
                                   [NSNumber numberWithBool:NO]]];
      if (percentCompleteUploadingEntity == 1.0) {
        uploadDone(mainMsgTitle);
      }
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      _uploader(self,
                _entity,
                uploadNotFoundBlk,
                uploadSuccessBlk,
                uploadRetryAfterBlk,
                uploadServerTempError,
                uploadServerError,
                uploadAuthReqdBlk,
                uploadForbiddenBlk,
                uploadDependencyUnsyncedBlk);
    });
  } else {
    if (![APP doesUserHaveValidAuthToken]) {
      [self showNotCurrentlyAuthenticatedWarning];
    } else if (!allowedToSyncImport) {
      [self showImportNotAllowedUnverifiedAccountWarningWasEditing:NO buttonAction:^{}];
    } else if (importLimitExceeded) {
      [self showImportLimitExceededWarningWasEditing:NO buttonAction:^{}];
    } else {
      [self showBadAccountWarning];
    }
  }
}

#pragma mark - Screen Logging

- (void)clearScreenTitlesLogged {
  [_screenTitlesLogged removeAllObjects];
}

#pragma mark - Not Found and other helpers

- (UIView *)parentViewForAlerts {
  return [PEUIUtils parentViewForAlertsForController:self];
}

- (void)handleServerBusyErrorWithAction:(void(^)(void))action
                      showOfflineOption:(BOOL)showOfflineOption {
  [PEUIUtils showWaitAlertWithMsgs:nil
                             title:@"Busy with maintenance."
                  alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try this operation again later."]
               descLblHeightAdjust:0.0
         additionalContentSections:showOfflineOption && _promptGoOffline && ![APP offlineMode] ? @[[_panelToolkit goOfflineAlertSectionRelativeToView:[self parentViewForAlerts]]] : nil
                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                       buttonTitle:@"Okay."
                      buttonAction:action
                    relativeToView:[self parentViewForAlerts]];
}

- (void)handleNotFoundError {
  NSString *fetchErrMsg = [NSString stringWithFormat:@"\
It would appear this %@ record no longer exists and was probably deleted on \
a different device.\n\nTo keep the data on your device consistent \
with your account, it will be removed now.", [_entityTitle lowercaseString]];
  [PEUIUtils showErrorAlertWithMsgs:nil
                              title:@"Record not found."
                   alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                descLblHeightAdjust:0.0
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay."
                       buttonAction:^{
                         _itemLocalDeleter(self, _entity, _entityIndexPath);
                         [[NSNotificationCenter defaultCenter] postNotificationName:_entityRemovedNotificationName
                                                                             object:self
                                                                           userInfo:[self userInfoDictForNotifications]];
                         if (_modalOperationDone) { _modalOperationDone(); }
                         [self dismiss];
                         if (_deletedCallback) {
                           _deletedCallback();
                         }
                       }
                     relativeToView:[self parentViewForAlerts]];
}

- (void (^)(void(^)(void)))downloadDepsForEntity:(id)entity
                       dismissErrAlertPostAction:(void(^)(void))dismissErrAlertPostAction {
  __block BOOL receivedAuthReqdErrorOnDownloadDepsAttempt = NO;
  __block BOOL receivedForbiddenErrorOnDownloadDepsAttempt = NO;
  void (^fetchDepsThenTakeAction)(void(^)(void)) = ^(void(^postFetchAction)(void)) {
    if (_numRemoteDepsNotLocal) {
      NSInteger numDepsThatDontExistLocally = _numRemoteDepsNotLocal(entity);
      if (numDepsThatDontExistLocally == 0) {
        postFetchAction();
      } else {
        // Ugh.  This sucks. Okay, let's do this!
        __block float percentCompleteFetchingDeps = 0.0;
        NSMutableArray *successMsgsForDepsFetch = [NSMutableArray array];
        NSMutableArray *errsForDepsFetch = [NSMutableArray array];
        MBProgressHUD *depFetchHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        depFetchHud.tag = RHUD_TAG;
        depFetchHud.label.text = [NSString stringWithFormat:@"Synchronizing with server"];
        void (^handleHudProgress)(float) = ^(float percentComplete) {
          percentCompleteFetchingDeps += percentComplete;
          dispatch_async(dispatch_get_main_queue(), ^{
            depFetchHud.progress = percentCompleteFetchingDeps;
          });
        };
        void(^depFetchDone)(NSString *) = ^(NSString *mainMsgTitle) {
          if ([errsForDepsFetch count] == 0) { // success
            dispatch_async(dispatch_get_main_queue(), ^{
              depFetchHud.label.text = @"Synchronization complete";
              [depFetchHud hideAnimated:YES afterDelay:1.0];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                postFetchAction();
              });
            });
          } else { // error(s)
            dispatch_async(dispatch_get_main_queue(), ^{
              [depFetchHud hideAnimated:YES afterDelay:0];
              void (^dismissErrAlertAction)(void) = ^{
                [self setEditing:YES animated:YES];
                //reenableNavButtons();
                dismissErrAlertPostAction();
              };
              JGActionSheetSection *addlSection = nil;
              if (receivedAuthReqdErrorOnDownloadDepsAttempt) {
                addlSection = [PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]];
              } else if (receivedForbiddenErrorOnDownloadDepsAttempt) {
                addlSection = [PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]];
              }
              if ([errsForDepsFetch count] > 1) {
                NSString *fetchErrMsg = @"There were problems downloading this record's dependencies.";
                [PEUIUtils showMultiErrorAlertWithFailures:errsForDepsFetch
                                                     title:@"Fetch errors."
                                          alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                                       descLblHeightAdjust:0.0
                                  additionalContentSection:addlSection
                                                  topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                               buttonTitle:@"Okay."
                                              buttonAction:^{
                                                dismissErrAlertAction();
                                              }
                                            relativeToView:[self parentViewForAlerts]];
              } else {
                NSString *fetchErrMsg = @"There was a problem downloading this record's dependency.";
                [PEUIUtils showErrorAlertWithMsgs:errsForDepsFetch[0][2]
                                            title:@"Fetch error."
                                 alertDescription:[[NSAttributedString alloc] initWithString:fetchErrMsg]
                              descLblHeightAdjust:0.0
                        additionalContentSections:addlSection != nil ? @[addlSection] : nil
                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       dismissErrAlertAction();
                                     }
                                   relativeToView:[self parentViewForAlerts]];
              }
            });
          }
        };
        void(^depNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Not found."]],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [successMsgsForDepsFetch addObject:[NSString stringWithFormat:@"%@ fetched.", recordTitle]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                             NSString *mainMsgTitle,
                                                                             NSString *recordTitle,
                                                                             NSDate *retryAfter) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void (^depServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                      NSString *mainMsgTitle,
                                                                      NSString *recordTitle) {
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Temporary server error."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
          receivedAuthReqdErrorOnDownloadDepsAttempt = YES;
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Authentication required."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        void(^depForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                  NSString *mainMsgTitle,
                                                                  NSString *recordTitle) {
          receivedForbiddenErrorOnDownloadDepsAttempt = YES;
          handleHudProgress(percentComplete);
          [errsForDepsFetch addObject:@[[NSString stringWithFormat:@"%@ not fetched.", recordTitle],
                                        [NSNumber numberWithBool:NO],
                                        @[@"Not permitted."],
                                        [NSNumber numberWithBool:NO]]];
          if (percentCompleteFetchingDeps == 1.0) { depFetchDone(mainMsgTitle); }
        };
        _fetchDependencies(self,
                           entity,
                           depNotFoundBlk,
                           depSuccessBlk,
                           depRetryAfterBlk,
                           depServerTempError,
                           depAuthReqdBlk,
                           depForbiddenBlk);
      }
    } else {
      postFetchAction();
    }
  };
  return fetchDepsThenTakeAction;
}

- (void)showNotCurrentlyAuthenticatedWarning {
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSAttributedString *attrBecameUnauthMessage =
  [PEUIUtils attributedTextWithTemplate:@"You are not currently authenticated.\n\nTo re-authenticate, head over to:\n\n%@."
                           textToAccent:@"Account \u2794 Re-authenticate"
                         accentTextFont:boldDescFont];
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"Not Authenticated."
                     alertDescription:attrBecameUnauthMessage
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:^{
                           [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                               object:self
                                                                             userInfo:nil];
                           if (_reauthReqdPostEditActivityBlk) {
                             _reauthReqdPostEditActivityBlk(self);
                           }
                         }
                       relativeToView:[self parentViewForAlerts]];
}

- (void)showBadAccountWarning {
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSAttributedString *attrBecameUnauthMessage =
  [PEUIUtils attributedTextWithTemplate:@"This operation is not permitted because your account is currently in a bad state.\n\nThis is usually due to an expired trial account or a closed account subscription.  To address this, head over to:\n\n%@."
                           textToAccent:@"Account \u2794 Status"
                         accentTextFont:boldDescFont];
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:@"Operation not permitted."
                     alertDescription:attrBecameUnauthMessage
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:^{}
                       relativeToView:[self parentViewForAlerts]];
}

- (void)showImportLimitExceededWarningWasEditing:(BOOL)wasEditing
                                    buttonAction:(void(^)(void))buttonAction {
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  NSString *title;
  if (wasEditing) {
    title = @"Import limit exceeded, record saved locally.";
    [desc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"You're record was saved locally, but could not be synced at this time.\n\nYou have exceeded the amount of imported %@ data you're allowed to upload.  ", [_entityTitle lowercaseString]]]];
    [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Please contact %@ and we'll try to help you out."
                                                          textToAccent:[APP rikerSupportEmail]
                                                        accentTextFont:boldDescFont]];
  } else {
    title = @"Import limit exceeded.";
    [desc appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"You have exceeded the amount of imported %@ data you're allowed to upload.  ", [_entityTitle lowercaseString]]]];
    [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"Please contact %@ and we'll try to help you out."
                                                          textToAccent:[APP rikerSupportEmail]
                                                        accentTextFont:boldDescFont]];
  }
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:title
                     alertDescription:desc
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:buttonAction
                       relativeToView:[self parentViewForAlerts]];
}

- (void)showImportNotAllowedUnverifiedAccountWarningWasEditing:(BOOL)wasEditing
                                                  buttonAction:(void(^)(void))buttonAction {
  UIFont* boldDescFont = [PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]];
  NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
  NSString *title;
  if (wasEditing) {
    title = @"Import not allowed, record saved locally.";
    [desc appendAttributedString:AS(@"You're record was saved locally, but could not be synced at this time.\n\nSyncing imported records is only allowed for accounts with a verified email address.")];
    [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nHead over to the %@ tab if you need a new verification link email to you."
                                                          textToAccent:@"Account"
                                                        accentTextFont:boldDescFont]];
  } else {
    title = @"Import not allowed.";
    [desc appendAttributedString:AS(@"Syncing imported records is only allowed for accounts with a verified email address.")];
    [desc appendAttributedString:[PEUIUtils attributedTextWithTemplate:@"\n\nHead over to the %@ tab if you need a new verification link email to you."
                                                          textToAccent:@"Account"
                                                        accentTextFont:boldDescFont]];
  }
  [PEUIUtils showWarningAlertWithMsgs:nil
                                title:title
                     alertDescription:desc
                  descLblHeightAdjust:0.0
                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                          buttonTitle:@"Okay."
                         buttonAction:buttonAction
                       relativeToView:[self parentViewForAlerts]];
}

- (void)popIconHelp {
  UIView *relativeToView = [PEUIUtils parentViewForAlertsForController:self];
  [PEUIUtils showInfoAlertWithTitle:@"Icon Help"
                   alertDescription:AS(@"Explanation of toolbar icons:")
                descLblHeightAdjust:0.0
          additionalContentSections:@[[JGActionSheetSection sectionWithTitle:nil
                                                                     message:nil
                                                                 contentView:[_panelToolkit loggedInCrudToolbarHelpPanelWithWidth:0.905 * [PEUIUtils availableWidthForAlertPanelRelativeToView:relativeToView]]]]
                           topInset:[PEUIUtils topInsetForAlertsWithController:self]
                        buttonTitle:@"Okay."
                       buttonAction:^{}
                     relativeToView:relativeToView];
}

#pragma mark - Toggle into edit mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated {
  if (flag) {
    if ([self prepareForEditing]) {
      _entityCopyBeforeEdit = [_entity copy];
      _isEdit = YES;
      [self updateTitle];
      [super setEditing:flag animated:animated];
      if (_prepareUIForUserInteractionBlk) {
        _prepareUIForUserInteractionBlk(self, _entityFormPanel);
      }
      [self setRightBarButonItems];
    }
  } else {
    if ([self stopEditing]) {
      [super setEditing:false animated:animated];
    }
  }
}

#pragma mark - UI state changes

- (void)disableUi {
  [self.navigationItem setHidesBackButton:YES animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
  [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
  [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
  [_uploadBarButtonItem setEnabled:NO];
  [_downloadBarButtonItem setEnabled:NO];
  [_deleteBarButtonItem setEnabled:NO];
  if (_modalOperationStarted) { _modalOperationStarted(); }
}

- (void)enableUi {
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
  [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
  [[[self tabBarController] tabBar] setUserInteractionEnabled:YES];
  if (_modalOperationDone) { _modalOperationDone(); }
  [self setRightBarButonItems];
}

- (UILabel *)titleWithText:(NSString *)titleText {
  UIFont *font;
  CGFloat maxAllowedPointSize = [PEUIUtils valueIfiPhone5Width:22.0 iphone6Width:24.0 iphone6PlusWidth:24.0 ipad:28.0];
  if (titleText.length > 13) {
    font = [PEUIUtils fontWithMaxAllowedPointSize:maxAllowedPointSize
                                             font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
  } else {
    font = [PEUIUtils boldFontWithMaxAllowedPointSize:maxAllowedPointSize
                                                 font:[PEUIUtils boldFontForTextStyle:UIFontTextStyleBody]];
  }
  return [PEUIUtils labelWithKey:titleText
                            font:font
                 backgroundColor:[UIColor clearColor]
                       textColor:[RUIUtils navbarTextTintColor]
             verticalTextPadding:0.0];
}

- (BOOL)prepareForEditing {
  [_entityViewPanel removeFromSuperview];
  [_entityFormPanel removeFromSuperview];
  _entityFormPanel = _entityFormPanelMaker(self);
  [PEUIUtils placeView:_entityFormPanel atTopOf:[self view] withAlignment:PEUIHorizontalAlignmentTypeCenter vpadding:0 hpadding:0];
  _entityToPanelBinder(_entity, _entityFormPanel);
  _panelEnablerDisabler(_entityFormPanel, YES);
  [PEUIUtils bringOfflineModeViewsToFrontForController:self];
  return YES;
}

- (BOOL)stopEditing {
  void (^postEditActivities)(BOOL, BOOL) = ^(BOOL authReqd, BOOL isCancel) {
    [super setEditing:NO animated:YES];
    [self.view endEditing:YES];
    if (_itemChangedBlk) {
      _itemChangedBlk(_entity, _entityIndexPath);
    }
    _isEdit = NO;
    _isView = YES;
    [self updateTitle];
    [self enableUi];
    [[self navigationItem] setLeftBarButtonItem:_leftBarButtonItem];
    
    [self setRightBarButonItems];
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    
    _panelEnablerDisabler(_entityFormPanel, NO);
    if (!isCancel) {
      [[NSNotificationCenter defaultCenter] postNotificationName:_entityUpdatedNotificationName
                                                          object:self
                                                        userInfo:[self userInfoDictForNotifications]];
    }
    [_entityFormPanel removeFromSuperview];
    _entityViewPanel = _entityViewPanelMaker(self, _parentEntity, _entity);
    [PEUIUtils placeView:_entityViewPanel
                 atTopOf:[self view]
           withAlignment:PEUIHorizontalAlignmentTypeCenter
                vpadding:0
                hpadding:0];
    [PEUIUtils bringOfflineModeViewsToFrontForController:self];
    if (authReqd) {
      [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                            object:self
                                                          userInfo:nil];
      if (_reauthReqdPostEditActivityBlk) {
        _reauthReqdPostEditActivityBlk(self);
      }
    }
  };
 
    NSArray *errMsgs = nil;
    if (_entityValidator) {
      errMsgs = _entityValidator(_entityFormPanel);
    }
    BOOL isValidEntity = YES;
    if (errMsgs && [errMsgs count] > 0) {
      isValidEntity = NO;
    }
    if (isValidEntity) {
      NSArray *importBooleans = [self importBooleans];
      BOOL allowedToSyncImport = [(NSNumber *)importBooleans[0] boolValue];
      BOOL importLimitExceeded = [(NSNumber *)importBooleans[1] boolValue];
      if (_isAuthenticatedBlk() && (!_isBadAccount() || _allowedToRemoteSaveWithBadAccount) && (!_isOfflineMode() || (_doneEditingEntityLocalSync == nil)) && !importLimitExceeded && allowedToSyncImport) {
        void (^doRemoteSave)(void) = ^{
          MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          HUD.tag = RHUD_TAG;
          [self disableUi];
          HUD.delegate = self;
          HUD.mode = _syncImmediateMBProgressHUDMode;
          HUD.label.text = @"Saving to the server.";
          __block float percentCompleteUploadingEntity = 0.0;
          HUD.progress = percentCompleteUploadingEntity;
          NSMutableArray *errorsForUpload = [NSMutableArray array];
          // The meaning of the elements of the arrays found within errorsForUpload:
          //
          // errorsForUpload[*][0]: Error title (string)
          // errorsForUpload[*][1]: Is error user-fixable (bool)
          // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
          // errorsForUpload[*][3]: Is error type server-busy? (bool)
          // errorsForUpload[*][4]: Is error conflict-type (bool)
          // errorsForUpload[*][5]: The latest entity if err is conflict-type
          // errorsForUpload[*][6]: Is entity not found
          //
          NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
          __block BOOL receivedAuthReqdErrorOnSaveAttempt = NO;
          __block BOOL receivedForbiddenErrorOnSaveAttempt = NO;
          void(^immediateSyncDone)(NSString *) = ^(NSString *mainMsgTitle) {
            if ([errorsForUpload count] == 0) { // success
              dispatch_async(dispatch_get_main_queue(), ^{
                [HUD hideAnimated:YES];
                [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", [_entityTitle sentenceCase]]
                                    alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForUpload[0]]
                                 descLblHeightAdjust:0.0
                                            topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                         buttonTitle:@"Okay."
                                        buttonAction:^{ postEditActivities(NO, NO); }
                                      relativeToView:[self parentViewForAlerts]];
              });
            } else { // error
              dispatch_async(dispatch_get_main_queue(), ^{
                [HUD hideAnimated:YES afterDelay:0];
                if ([errorsForUpload[0][6] boolValue]) { // is entity not found
                  [self handleNotFoundError];
                } else if ([errorsForUpload[0][3] boolValue]) { // server busy
                  [PEUIUtils showWaitAlertWithMsgs:nil
                                             title:@"Busy with maintenance."
                                  alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
Your edits have been saved locally.  You can try to upload them later."]
                               descLblHeightAdjust:0.0
                         additionalContentSections:_promptGoOffline ? @[[_panelToolkit goOfflineAlertSectionRelativeToView:[self parentViewForAlerts]]] : nil
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                       buttonTitle:@"Okay."
                                      buttonAction:^{
                                        postEditActivities(NO, NO);
                                      }
                                    relativeToView:[self parentViewForAlerts]];
                } else { // all other error types
                  NSString *messageTemplate;
                  NSString *textToAccent;
                  NSAttributedString *attrMessage;
                  NSString *title;
                  NSString *fixNowActionTitle;
                  NSString *fixLaterActionTitle;
                  NSString *dealWithLaterActionTitle;
                  NSString *cancelActionTitle;
                  NSArray *subErrors = errorsForUpload[0][2]; // because only single-record edit, we can skip the "not saved" msg title, and just display the sub-errors
                  if (_doneEditingEntityLocalSync) {
                    if ([subErrors count] > 1) {
                      textToAccent = @"they have been saved locally";
                      messageTemplate = @"Although there were problems syncing your edits to the server, %@.  The errors are as follows:";
                      fixNowActionTitle = @"I'll fix them now.";
                      fixLaterActionTitle = @"I'll fix them later.";
                      dealWithLaterActionTitle = @"I'll try syncing them later.";
                      cancelActionTitle = @"Forget it.  Just cancel them.";
                      title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                    } else {
                      textToAccent = @"they have been saved locally";
                      messageTemplate = @"Although there was a problem syncing your edits to the server, %@.  The error is as follows:";
                      fixLaterActionTitle = @"I'll fix it later.";
                      fixNowActionTitle = @"I'll fix it now.";
                      dealWithLaterActionTitle = @"I'll try syncing it later.";
                      cancelActionTitle = @"Forget it.  Just cancel it.";
                      title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                    }
                  } else {
                    textToAccent = nil;
                    messageTemplate = @"There was a problem syncing your edits to the server.  The error is as follows:";
                    cancelActionTitle = @"Okay.  I'll try again later.";
                    title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                    dealWithLaterActionTitle = nil;
                    fixNowActionTitle = nil;
                    fixLaterActionTitle = nil;
                  }
                  if (textToAccent) {
                    attrMessage = [PEUIUtils attributedTextWithTemplate:messageTemplate
                                                           textToAccent:textToAccent
                                                         accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                  } else {
                    attrMessage = [[NSAttributedString alloc] initWithString:messageTemplate];
                  }
                  JGActionSheetSection *addlSection = nil;
                  if (receivedAuthReqdErrorOnSaveAttempt) {
                    addlSection = [PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]];
                  } else if (receivedForbiddenErrorOnSaveAttempt) {
                    addlSection = [PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]];
                  }
                  JGActionSheetSection *contentSection = [PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                                        title:title
                                                                             alertDescription:attrMessage
                                                                          descLblHeightAdjust:0.0
                                                                               relativeToView:[self parentViewForAlerts]];
                  JGActionSheetSection *buttonsSection;
                  void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
                  // 'fix' buttons here
                  void (^cancelAction)(void) = ^{
                    if (_entityCopyBeforeEdit) {
                      [_entity overwrite:_entityCopyBeforeEdit];
                    } else {
                      if ([PEUtils isNotNil:_entity.localMasterIdentifier]) {
                        [_entity overwriteDomainProperties:_masterEntityLoader(_entity.localMasterIdentifier)];
                      }
                    }
                    // now we can cancel the edit session as we normally would
                    _entityToPanelBinder(_entity, _entityFormPanel);
                    postEditActivities(receivedAuthReqdErrorOnSaveAttempt, NO);
                  };
                  if ([PEAddViewEditController areErrorsAllUserFixable:errorsForUpload]) {
                    NSMutableArray *buttonTitles = [NSMutableArray array];
                    NSMutableArray *buttonActions = [NSMutableArray array];
                    if (fixNowActionTitle) {
                      [buttonTitles addObject:fixNowActionTitle];
                      [buttonActions addObject:^{
                        [super setEditing:YES animated:NO];
                        [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
                        [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
                      }];
                    }
                    if (fixLaterActionTitle) {
                      [buttonTitles addObject:fixLaterActionTitle];
                      [buttonActions addObject:^{
                        postEditActivities(receivedAuthReqdErrorOnSaveAttempt, NO);
                      }];
                    }
                    [buttonTitles addObject:cancelActionTitle];
                    [buttonActions addObject:^{
                      cancelAction();
                    }];
                    buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                    message:nil
                                                               buttonTitles:buttonTitles
                                                                buttonStyle:JGActionSheetButtonStyleDefault];
                    [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:2];
                    buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                      void(^btnAction)(void) = buttonActions[indexPath.row];
                      btnAction();
                      [sheet dismissAnimated:YES];
                    };
                  } else {
                    NSMutableArray *buttonTitles = [NSMutableArray array];
                    NSMutableArray *buttonActions = [NSMutableArray array];
                    if (dealWithLaterActionTitle) {
                      [buttonTitles addObject:dealWithLaterActionTitle];
                      [buttonActions addObject:^{
                        postEditActivities(receivedAuthReqdErrorOnSaveAttempt, NO);
                      }];
                    }
                    if (cancelActionTitle) {
                      [buttonTitles addObject:cancelActionTitle];
                      [buttonActions addObject:^{
                        cancelAction();
                      }];
                    }
                    buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                    message:nil
                                                               buttonTitles:buttonTitles
                                                                buttonStyle:JGActionSheetButtonStyleDefault];
                    [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
                    buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                      void(^btnAction)(void) = buttonActions[indexPath.row];
                      btnAction();
                      [sheet dismissAnimated:YES];
                    };
                  }
                  NSMutableArray *sections = [NSMutableArray array];
                  [sections addObject:contentSection];
                  if (addlSection) {
                    [sections addObject:addlSection];
                  }
                  if (_promptGoOffline) {
                    [sections addObject:[_panelToolkit goOfflineAlertSectionRelativeToView:[self parentViewForAlerts]]];
                  }
                  [sections addObject:buttonsSection];
                  JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
                  [alertSheet setDelegate:self];
                  [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
                  [alertSheet setButtonPressedBlock:buttonsPressedBlock];
                  [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
                }
              });
            }
          };
          void (^handleHudProgress)(float) = ^(float percentComplete) {
            percentCompleteUploadingEntity += percentComplete;
            dispatch_async(dispatch_get_main_queue(), ^{
              HUD.progress = percentCompleteUploadingEntity;
            });
          };
          void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[[NSString stringWithFormat:@"Not found."]],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:YES]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                   NSString *mainMsgTitle,
                                                                   NSString *recordTitle) {
            handleHudProgress(percentComplete);
            [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server.", recordTitle]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                                NSString *mainMsgTitle,
                                                                                NSString *recordTitle,
                                                                                NSDate *retryAfter) {
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                         [NSNumber numberWithBool:YES],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void (^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                         NSString *mainMsgTitle,
                                                                         NSString *recordTitle) {
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Temporary server error."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void (^syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                                NSString *mainMsgTitle,
                                                                                NSString *recordTitle,
                                                                                NSArray *computedErrMsgs) {
            handleHudProgress(percentComplete);
            BOOL isErrorUserFixable = YES;
            if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
              computedErrMsgs = @[@"Unknown server error."];
              isErrorUserFixable = NO;
            }
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:isErrorUserFixable],
                                         computedErrMsgs,
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
            receivedAuthReqdErrorOnSaveAttempt = YES;
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Authentication required."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void(^syncForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                     NSString *mainMsgTitle,
                                                                     NSString *recordTitle) {
            receivedForbiddenErrorOnSaveAttempt = YES;
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[@"Not permitted."],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          void (^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                           NSString *mainMsgTitle,
                                                                                           NSString *recordTitle,
                                                                                           NSString *dependencyErrMsg) {
            handleHudProgress(percentComplete);
            [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                         [NSNumber numberWithBool:NO],
                                         @[dependencyErrMsg],
                                         [NSNumber numberWithBool:NO],
                                         [NSNumber numberWithBool:NO],
                                         [NSNull null],
                                         [NSNumber numberWithBool:NO]]];
            if (percentCompleteUploadingEntity == 1.0) {
              immediateSyncDone(mainMsgTitle);
            }
          };
          _panelToEntityBinder(_entityFormPanel, _entity);
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _entitySaver(self, _entity);
            _doneEditingEntityImmediateSync(self,
                                            _entity,
                                            syncNotFoundBlk,
                                            syncSuccessBlk,
                                            syncRetryAfterBlk,
                                            syncServerTempError,
                                            syncServerError,
                                            syncAuthReqdBlk,
                                            syncForbiddenBlk,
                                            syncDependencyUnsyncedBlk);
          });
        };
        
        
        // TODO - _promptCurrentPassword should be a block that like the validator, receives the form and
        // and returns a BOOL (whether or not to prompt for current password).  There is one use case (albeit, a sort of nonsensical one) where the user can edit their user account record, make no changes (don't change email, and don't provide a password/confirm-password), and tap 'Done' - in this case, because they're not changing their email or password, we should just let the save occur without prompting for their current password
        
        if (_promptCurrentPasswordBlk && _promptCurrentPasswordBlk(_entityFormPanel, _entityCopyBeforeEdit)) {
          UIViewController *promptCurrentPasswordController =
          [[PEProvideCurrentPasswordController alloc] initWithActionOnDone:^(NSString *providedPassword) {
            _entity.currentPassword = providedPassword;
            doRemoteSave();
          }
                                                              cancelAction:^{
                                                              }
                                                                 uitoolkit:_uitoolkit];
          [[self navigationController] presentViewController:[PEUIUtils navigationControllerWithController:promptCurrentPasswordController
                                                                                       navigationBarHidden:NO]
                                                    animated:YES
                                                  completion:nil];
          return NO;
        } else {
          doRemoteSave();
          return YES;
        }
      } else {
        [self disableUi];
        _panelToEntityBinder(_entityFormPanel, _entity);
        _entitySaver(self, _entity);
        if (_modalOperationStarted) { _modalOperationStarted(); }
        if (_doneEditingEntityLocalSync) { _doneEditingEntityLocalSync(self, _entity); }
        if (_isOfflineMode()) {
          [PEUIUtils showOfflineModeEnabledAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                         alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                      descLblHeightAdjust:0.0
                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                              buttonTitle:@"Okay."
                                             buttonAction:^{ postEditActivities(NO, NO); }
                                           relativeToView:[self parentViewForAlerts]];
        } else if (_isUserLoggedIn() && !_isAuthenticatedBlk()) {
          [PEUIUtils recordSavedWhileUnauthAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                         alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                      descLblHeightAdjust:0.0
                                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                              buttonTitle:@"Okay."
                                             buttonAction:^{ postEditActivities(NO, NO); }
                                           relativeToView:[self parentViewForAlerts]];
        } else if (_isUserLoggedIn() && _isBadAccount()) {
          [PEUIUtils recordSavedWhileBadAccountAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                             alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                          descLblHeightAdjust:0.0
                                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                  buttonTitle:@"Okay."
                                                 buttonAction:^{ postEditActivities(NO, NO); }
                                               relativeToView:[self parentViewForAlerts]];
        } else if (_isUserLoggedIn() && !allowedToSyncImport) {
          [self showImportNotAllowedUnverifiedAccountWarningWasEditing:YES
                                                          buttonAction:^{ postEditActivities(NO, NO); }];
        } else if (importLimitExceeded) {
          [self showImportLimitExceededWarningWasEditing:YES
                                            buttonAction:^{ postEditActivities(NO, NO); }];
        } else {
          
          [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", [_entityTitle sentenceCase]]
                              alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved.", [_entityTitle lowercaseString]]]
                           descLblHeightAdjust:0.0
                                      topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                   buttonTitle:@"Okay."
                                  buttonAction:^{ postEditActivities(NO, NO); }
                                relativeToView:[self parentViewForAlerts]];
        }
      }
      return YES;
    } else {
      [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                    title:@"Oops"
                         alertDescription:[[NSAttributedString alloc] initWithString:[self validationAlertTitleForErrMsgs:errMsgs]]
                      descLblHeightAdjust:0.0
                                 topInset:[PEUIUtils topInsetForAlertsWithController:self]
                              buttonTitle:@"Okay."
                             buttonAction:nil
                           relativeToView:[self view]];
      return NO;
    }
}

- (void)doneWithEdit {
  [self stopEditing];
}

+ (BOOL)areErrorsAllUserFixable:(NSArray *)errors {
  for (NSArray *error in errors) {
    NSNumber *isErrorUserFixable = error[1];
    if (![isErrorUserFixable boolValue]) {
      return NO;
    }
  }
  return YES;
}

+ (BOOL)areErrorsAllAuthenticationRequired:(NSArray *)errors {
  for (NSArray *error in errors) {
    NSNumber *isErrorAuthRequired = error[1];
    if (![isErrorAuthRequired boolValue]) {
      return NO;
    }
  }
  return YES;
}

- (UIView *)errorPanelWithTitle:(NSString *)title
                 forContentView:(UIView *)contentView
                         height:(CGFloat)height
                    leftImgIcon:(UIImage *)leftImgIcon {
  UIView *errorPanel = [PEUIUtils panelWithWidthOf:0.9 relativeToView:contentView fixedHeight:height];
  UIImageView *errImgView = [[UIImageView alloc] initWithImage:leftImgIcon];
  UILabel *errorMsgLbl = [PEUIUtils labelWithKey:title
                                            font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                 backgroundColor:[UIColor clearColor]
                                       textColor:[UIColor blackColor]
                             verticalTextPadding:0.0];
  [PEUIUtils placeView:errImgView
            inMiddleOf:errorPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              hpadding:0.0];
  [PEUIUtils placeView:errorMsgLbl
          toTheRightOf:errImgView
                  onto:errorPanel
         withAlignment:PEUIVerticalAlignmentTypeMiddle
              hpadding:5.0];
  return errorPanel;
}

- (NSArray *)panelsForMessages:(NSArray *)subErrors
                         forContentView:(UIView *)contentView
                            leftImgIcon:(UIImage *)leftImgIcon {
  NSMutableArray *subErrorPanels = [NSMutableArray arrayWithCapacity:[subErrors count]];
  for (NSString *subError in subErrors) {
    UIView *errorPanel = [self errorPanelWithTitle:subError
                                    forContentView:contentView
                                            height:25.0
                                       leftImgIcon:leftImgIcon];
    [subErrorPanels addObject:errorPanel];
  }
  return subErrorPanels;
}

- (void)doneWithAdd {
  [self.view endEditing:NO];
  NSArray *errMsgs = _entityValidator(_entityFormPanel);
  BOOL isValidEntity = YES;
  if (errMsgs && [errMsgs count] > 0) {
    isValidEntity = NO;
  }
  if (isValidEntity) {
    _newEntity = _entityMaker(_entityFormPanel);
    void (^notificationSenderForAdd)(id) = ^(id theNewEntity) {
      NSArray *entitiesFromEntity;
      if (_entitiesFromEntity) {
        entitiesFromEntity = _entitiesFromEntity(theNewEntity);
      } else {
        entitiesFromEntity = @[theNewEntity];
      }
      for (id entity in entitiesFromEntity) {
        [[NSNotificationCenter defaultCenter] postNotificationName:_entityAddedNotificationName
                                                            object:self
                                                          userInfo:@{@"entity": entity}];
      }
    };
    if (_isAuthenticatedBlk() && !_isOfflineMode() &&!_isBadAccount()) {
      MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      HUD.tag = RHUD_TAG;
      [self disableUi];
      HUD.delegate = self;
      HUD.mode = _syncImmediateMBProgressHUDMode;
      HUD.label.text = @"Saving to the server...";
      __block float percentCompleteUploadingEntity = 0.0;
      HUD.progress = percentCompleteUploadingEntity;
      NSMutableArray *errorsForUpload = [NSMutableArray array];
      // The meaning of the elements of the arrays found within errorsForUpload:
      //
      // errorsForUpload[*][0]: Error title (string)
      // errorsForUpload[*][1]: Is error user-fixable (bool)
      // errorsForUpload[*][2]: An NSArray of sub-error messages (strings)
      // errorsForUpload[*][3]: Is error type server-busy? (bool)
      //
      NSMutableArray *successMessageTitlesForUpload = [NSMutableArray array];
      __block BOOL receivedAuthReqdErrorOnAddAttempt = NO;
      __block BOOL receivedForbiddenErrorOnAddAttempt = NO;
      void(^immediateSaveDone)(NSString *) = ^(NSString *mainMsgTitle) {
        BOOL isMultiStepAdd = ([errorsForUpload count] + [successMessageTitlesForUpload count]) > 1;
        if ([errorsForUpload count] == 0) { // no errors
          dispatch_async(dispatch_get_main_queue(), ^{
            notificationSenderForAdd(_newEntity);
            if (isMultiStepAdd) { // all successes
              [HUD hideAnimated:YES afterDelay:0];
              [PEUIUtils showSuccessAlertWithMsgs:successMessageTitlesForUpload
                                            title:[NSString stringWithFormat:@"%@ saved.", mainMsgTitle]
                                 alertDescription:[[NSAttributedString alloc] initWithString:@"Your records have been successfully saved to the server."]
                              descLblHeightAdjust:0.0
                         additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                      buttonTitle:@"Okay."
                                     buttonAction:^{
                                       notificationSenderForAdd(_newEntity);
                                       if (_itemAddedBlk) {
                                         _itemAddedBlk(self, _newEntity);
                                       }
                                       if (_modalOperationDone) { _modalOperationDone(); }
                                     }
                                   relativeToView:[self parentViewForAlerts]];
            } else { // single add success
              [HUD hideAnimated:YES];
              [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", [_entityTitle sentenceCase]]
                                  alertDescription:[[NSAttributedString alloc] initWithString:successMessageTitlesForUpload[0]]
                               descLblHeightAdjust:0.0
                          additionalContentSection:(_addlContentSection != nil) ? _addlContentSection(self, _entityFormPanel, _newEntity) : nil
                                          topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                       buttonTitle:@"Okay."
                                      buttonAction:^{
                                        if (_itemAddedBlk) {
                                          _itemAddedBlk(self, _newEntity);  // this is what causes this controller to be dismissed
                                        }
                                        if (_modalOperationDone) { _modalOperationDone(); }
                                      }
                                    relativeToView:[self parentViewForAlerts]];
            }
          });
        } else { // mixed results or only errors
          NSMutableArray *sections = [NSMutableArray array];
          BOOL (^doesContainBusyError)(void) = ^{
            BOOL containsBusyError = NO;
            for (NSArray *failure in errorsForUpload) {
              containsBusyError = [failure[3] boolValue];
              break;
            }
            return containsBusyError;
          };
          BOOL (^areAllBusyErrors)(void) = ^{
            BOOL allBusyErrors = YES;
            for (NSArray *failure in errorsForUpload) {
              if (![failure[3] boolValue]) {
                allBusyErrors = NO;
                break;
              }
            }
            return allBusyErrors;
          };
          void (^addServerBusySection)(void) = ^{
            NSString *msg;
            if (isMultiStepAdd) {
              msg = @"\
While attempting to sync at least one your records, the server reported it is busy \
undergoing maintenance.  All your records have been saved locally and can be synced later.";
            } else {
              NSString *entityTitleLowercase = [_entityTitle lowercaseString];
              msg = [NSString stringWithFormat:@"\
While attempting to sync your %@, the server reported that it is busy undergoing \
maintenance.  Your %@ has been saved locally.  Try uploading it later.", entityTitleLowercase, entityTitleLowercase];
            }
            [sections addObject:[PEUIUtils waitAlertSectionWithMsgs:nil
                                                              title:@"Busy with maintenance."
                                                   alertDescription:[[NSAttributedString alloc] initWithString:msg]
                                                descLblHeightAdjust:0.0
                                                     relativeToView:[self parentViewForAlerts]]];
            if (_promptGoOffline) {
              [sections addObject:[_panelToolkit goOfflineAlertSectionRelativeToView:[self parentViewForAlerts]]];
            }
          };
          NSArray *(^stripOutBusyErrors)(void) = ^ NSArray * {
            NSMutableArray *errorsSansBusyErrs = [NSMutableArray array];
            for (NSArray *failure in errorsForUpload) {
              if (![failure[3] boolValue]) {
                [errorsSansBusyErrs addObject:failure];
              }
            }
            return errorsSansBusyErrs;
          };
          dispatch_async(dispatch_get_main_queue(), ^{
            [HUD hideAnimated:YES afterDelay:0];
            if ([successMessageTitlesForUpload count] > 0) { // mixed results
              if (receivedAuthReqdErrorOnAddAttempt) {
                [sections addObject:[PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              if (receivedForbiddenErrorOnAddAttempt) {
                [sections addObject:[PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]]];
              }
              if (doesContainBusyError()) {
                addServerBusySection();
              }
              if (!areAllBusyErrors()) {
                NSString *title = [NSString stringWithFormat:@"Mixed results saving %@.", [mainMsgTitle lowercaseString]];
                NSAttributedString *attrMessage = [PEUIUtils attributedTextWithTemplate:@"Some of the edits were saved to the server and some were not. \
The ones that did not %@ and will need to be fixed individually."
                                                       textToAccent:@"have been saved locally"
                                                     accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                [sections addObject:[PEUIUtils mixedResultsAlertSectionWithSuccessMsgs:successMessageTitlesForUpload
                                                                                 title:title
                                                                      alertDescription:attrMessage
                                                                   descLblHeightAdjust:0.0
                                                                   failuresDescription:[[NSAttributedString alloc] initWithString:@"The problems are:"]
                                                                              failures:stripOutBusyErrors()
                                                                        relativeToView:[self parentViewForAlerts]]];
              }
              // buttons section
              [sections addObject:[JGActionSheetSection sectionWithTitle:nil
                                                                 message:nil
                                                            buttonTitles:@[@"Okay."]
                                                             buttonStyle:JGActionSheetButtonStyleDefault]];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                switch ([indexPath row]) {
                  case 0: // okay
                    notificationSenderForAdd(_newEntity);
                    if (_itemAddedBlk) {
                      _itemAddedBlk(self, _newEntity);
                    }
                    if (receivedAuthReqdErrorOnAddAttempt) {
                      [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                          object:self
                                                                        userInfo:nil];
                      if (_reauthReqdPostEditActivityBlk) {
                        _reauthReqdPostEditActivityBlk(self);
                      }
                    }
                    [sheet dismissAnimated:YES];
                    break;
                };}];
              [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
            } else { // only error(s)
              NSString *title;
              NSString *fixNowActionTitle;
              NSString *fixLaterActionTitle;
              NSString *dealWithLaterActionTitle;
              NSString *cancelActionTitle;
              if (doesContainBusyError()) {
                addServerBusySection();
              }
              if (isMultiStepAdd) {
                NSString *textToAccent = @"they have been saved locally";
                NSString *messageTemplate = @"Although there were problems saving your edits to the server, %@.  The details are as follows:";
                fixNowActionTitle = @"I'll fix them now.";
                fixLaterActionTitle = @"I'll fix them later.";
                cancelActionTitle = @"Forget it.  Just cancel them.";
                dealWithLaterActionTitle = @"I'll try uploading them later.";
                title = [NSString stringWithFormat:@"Problems saving %@.", [mainMsgTitle lowercaseString]];
                if (!areAllBusyErrors()) {
                  [sections addObject:[PEUIUtils multiErrorAlertSectionWithFailures:stripOutBusyErrors()
                                                                              title:title
                                                                   alertDescription:[PEUIUtils attributedTextWithTemplate:messageTemplate
                                                                                                             textToAccent:textToAccent
                                                                                                           accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                                descLblHeightAdjust:0.0
                                                                     relativeToView:[self parentViewForAlerts]]];
                }
              } else {
                NSString *messageTemplate;
                NSString *textToAccent = @"they have been saved locally";
                dealWithLaterActionTitle = @"I'll try uploading it later.";
                cancelActionTitle = @"Forget it.  Just cancel this.";
                NSArray *subErrors = errorsForUpload[0][2]; // because only single-record add, we can skip the "not saved" msg title, and just display the sub-errors
                if ([subErrors count] > 1) {
                  title = [NSString stringWithFormat:@"Errors %@.", mainMsgTitle];
                  messageTemplate = @"Although there were problems saving your records to the server, %@.  The errors are as follows:";
                  fixNowActionTitle = @"I'll fix them now.";
                  fixLaterActionTitle = @"I'll fix them later.";
                } else {
                  textToAccent = [NSString stringWithFormat:@"your %@ has been saved locally", [_entityTitle lowercaseString]];
                  title = [NSString stringWithFormat:@"Error %@.", mainMsgTitle];
                  messageTemplate = @"Although there was a problem saving to the server, %@.  The error is as follows:";
                  fixLaterActionTitle = @"I'll fix it later.";
                  fixNowActionTitle = @"I'll fix it now.";
                }
                if (!areAllBusyErrors()) {
                  [sections addObject:[PEUIUtils errorAlertSectionWithMsgs:subErrors
                                                                     title:title
                                                          alertDescription:[PEUIUtils attributedTextWithTemplate:messageTemplate
                                                                                                    textToAccent:textToAccent
                                                                                                  accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                       descLblHeightAdjust:0.0
                                                            relativeToView:[self parentViewForAlerts]]];
                }
              }
              BOOL promptGoOffline = _promptGoOffline;
              if (receivedAuthReqdErrorOnAddAttempt) {
                [sections addObject:[PEUIUtils becameUnauthenticatedSectionRelativeToView:[self parentViewForAlerts]]];
                promptGoOffline = NO;
              }
              if (receivedForbiddenErrorOnAddAttempt) {
                [sections addObject:[PEUIUtils receivedNotPermittedSectionRelativeToView:[self parentViewForAlerts]]];
                promptGoOffline = NO;
              }
              if (promptGoOffline) {
                [sections addObject:[_panelToolkit goOfflineAlertSectionRelativeToView:[self parentViewForAlerts]]];
              }
              JGActionSheetSection *buttonsSection;
              void (^buttonsPressedBlock)(JGActionSheet *, NSIndexPath *);
              if ([PEAddViewEditController areErrorsAllUserFixable:errorsForUpload]) {
                buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                message:nil
                                                           buttonTitles:@[fixNowActionTitle,
                                                                          fixLaterActionTitle,
                                                                          cancelActionTitle]
                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:2];
                buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                  switch ([indexPath row]) {
                    case 0: // fix now
                      _entityAddCanceler(self, NO, _newEntity);
                      [self enableUi];
                      break;
                    case 1: // fix later
                      notificationSenderForAdd(_newEntity);
                      if (_itemAddedBlk) {
                        _itemAddedBlk(self, _newEntity);
                      }
                      break;
                    case 2: // cancel
                      _entityAddCanceler(self, YES, _newEntity);
                      break;
                  }
                  if (receivedAuthReqdErrorOnAddAttempt) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                        object:self
                                                                      userInfo:nil];
                    if (_reauthReqdPostEditActivityBlk) {
                      _reauthReqdPostEditActivityBlk(self);
                    }
                  }
                  if (_modalOperationDone) { _modalOperationDone(); }
                  [sheet dismissAnimated:YES];
                };
              } else {
                buttonsSection = [JGActionSheetSection sectionWithTitle:nil
                                                                message:nil
                                                           buttonTitles:@[dealWithLaterActionTitle,
                                                                          cancelActionTitle]
                                                            buttonStyle:JGActionSheetButtonStyleDefault];
                [buttonsSection setButtonStyle:JGActionSheetButtonStyleRed forButtonAtIndex:1];
                buttonsPressedBlock = ^(JGActionSheet *sheet, NSIndexPath *indexPath) {
                  switch ([indexPath row]) {
                    case 0:  // sync/deal-with it later
                      notificationSenderForAdd(_newEntity);
                      if (_itemAddedBlk) {
                        _itemAddedBlk(self, _newEntity);
                      }
                      break;
                    case 1:  // cancel
                      _entityAddCanceler(self, YES, _newEntity);
                      break;
                  }
                  if (receivedAuthReqdErrorOnAddAttempt) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:RAppReauthReqdNotification
                                                                        object:self
                                                                      userInfo:nil];
                    if (_reauthReqdPostEditActivityBlk) {
                      _reauthReqdPostEditActivityBlk(self);
                    }
                  }
                  if (_modalOperationDone) { _modalOperationDone(); }
                  [sheet dismissAnimated:YES];
                };
              }
              [sections addObject:buttonsSection];
              JGActionSheet *alertSheet = [JGActionSheet actionSheetWithSections:sections];
              [alertSheet setDelegate:self];
              [alertSheet setInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
              [alertSheet setButtonPressedBlock:buttonsPressedBlock];
              [alertSheet showInView:[PEUIUtils parentViewForAlertsForController:self] animated:YES];
            }
          });
        }
      };
      void(^handleHudProgress)(float) = ^(float percentComplete) {
        percentCompleteUploadingEntity += percentComplete;
        dispatch_async(dispatch_get_main_queue(), ^{
          HUD.progress = percentCompleteUploadingEntity;
        });
      };
      void(^syncNotFoundBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Not found."]],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncSuccessBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                               NSString *mainMsgTitle,
                                                               NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [successMessageTitlesForUpload addObject:[NSString stringWithFormat:@"%@ saved to the server successfully.", recordTitle]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncRetryAfterBlk)(float, NSString *, NSString *, NSDate *) = ^(float percentComplete,
                                                                            NSString *mainMsgTitle,
                                                                            NSString *recordTitle,
                                                                            NSDate *retryAfter) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[[NSString stringWithFormat:@"Server undergoing maintenance.  Try again later."]],
                                     [NSNumber numberWithBool:YES]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncServerTempError)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                    NSString *mainMsgTitle,
                                                                    NSString *recordTitle) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Temporary server error."],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncServerError)(float, NSString *, NSString *, NSArray *) = ^(float percentComplete,
                                                                           NSString *mainMsgTitle,
                                                                           NSString *recordTitle,
                                                                           NSArray *computedErrMsgs) {
        handleHudProgress(percentComplete);
        BOOL isErrorUserFixable = YES;
        if (!computedErrMsgs || ([computedErrMsgs count] == 0)) {
          computedErrMsgs = @[@"Unknown server error."];
          isErrorUserFixable = NO;
        }
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:isErrorUserFixable],
                                     computedErrMsgs,
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncAuthReqdBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                NSString *mainMsgTitle,
                                                                NSString *recordTitle) {
        receivedAuthReqdErrorOnAddAttempt = YES;
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Authentication required."],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncForbiddenBlk)(float, NSString *, NSString *) = ^(float percentComplete,
                                                                 NSString *mainMsgTitle,
                                                                 NSString *recordTitle) {
        receivedForbiddenErrorOnAddAttempt = YES;
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[@"Not permitted."],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      void(^syncDependencyUnsyncedBlk)(float, NSString *, NSString *, NSString *) = ^(float percentComplete,
                                                                                      NSString *mainMsgTitle,
                                                                                      NSString *recordTitle,
                                                                                      NSString *dependencyErrMsg) {
        handleHudProgress(percentComplete);
        [errorsForUpload addObject:@[[NSString stringWithFormat:@"%@ not saved to the server.", recordTitle],
                                     [NSNumber numberWithBool:NO],
                                     @[dependencyErrMsg],
                                     [NSNumber numberWithBool:NO]]];
        if (percentCompleteUploadingEntity == 1.0) {
          immediateSaveDone(mainMsgTitle);
        }
      };
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _newEntitySaverImmediateSync(_entityFormPanel,
                                     _newEntity,
                                     syncNotFoundBlk,
                                     syncSuccessBlk,
                                     syncRetryAfterBlk,
                                     syncServerTempError,
                                     syncServerError,
                                     syncAuthReqdBlk,
                                     syncForbiddenBlk,
                                     syncDependencyUnsyncedBlk);
      });
    } else {
      _newEntitySaverLocal(_entityFormPanel, _newEntity);
      [[[self navigationItem] leftBarButtonItem] setEnabled:NO]; // cancel btn (so they can't cancel it after we'ved saved and we're displaying the HUD)
      [[[self navigationItem] rightBarButtonItem] setEnabled:NO]; // done btn
      [[[self tabBarController] tabBar] setUserInteractionEnabled:NO];
      if (_modalOperationStarted) { _modalOperationStarted(); }
      void (^buttonAction)(void) = ^{
        if (_modalOperationDone) { _modalOperationDone(); }
        notificationSenderForAdd(_newEntity);
        if (_itemAddedBlk) {
          _itemAddedBlk(self, _newEntity);
        }
      };
      if (_isOfflineMode()) {
        [PEUIUtils showOfflineModeEnabledAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                       alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                    descLblHeightAdjust:0.0
                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                            buttonTitle:@"Okay."
                                           buttonAction:buttonAction
                                         relativeToView:[self parentViewForAlerts]];
      } else if (_isUserLoggedIn() && !_isAuthenticatedBlk()) {
        [PEUIUtils recordSavedWhileUnauthAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                       alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                    descLblHeightAdjust:0.0
                                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                            buttonTitle:@"Okay."
                                           buttonAction:buttonAction
                                         relativeToView:[self parentViewForAlerts]];
      } else if (_isUserLoggedIn() && _isBadAccount()) {
        [PEUIUtils recordSavedWhileBadAccountAlertWithTitle:[NSString stringWithFormat:@"%@ saved locally.", [_entityTitle sentenceCase]]
                                           alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved locally.", [_entityTitle lowercaseString]]]
                                        descLblHeightAdjust:0.0
                                                   topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                buttonTitle:@"Okay."
                                               buttonAction:buttonAction
                                             relativeToView:[self parentViewForAlerts]];
      } else {
        [PEUIUtils showSuccessAlertWithTitle:[NSString stringWithFormat:@"%@ saved.", [_entityTitle sentenceCase]]
                            alertDescription:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Your %@ has been saved.", [_entityTitle lowercaseString]]]
                         descLblHeightAdjust:0.0
                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                 buttonTitle:@"Okay."
                                buttonAction:buttonAction
                              relativeToView:[self parentViewForAlerts]];
      }
    }
  } else {
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:[self validationAlertTitleForErrMsgs:errMsgs]]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:^{  }
                         relativeToView:[self view]];
  }
}

- (NSString *)validationAlertTitleForErrMsgs:(NSArray *)errMsgs {
  if (errMsgs.count == 1) {
    return @"A problem to fix:";
  } else {
    return @"Some problems to fix:";
  }
}

#pragma mark - Cancellation

- (void)cancelAdd {
  if (_isAdd) {
    _entityAddCanceler(self, YES, _newEntity);
    _newEntity = nil;
  }
}

@end
