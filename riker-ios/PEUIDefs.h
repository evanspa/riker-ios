//
//  PEUIDefs.h
//

#import <UIKit/UIKit.h>

@class PEListViewController;
@class PEAddViewEditController;
@class JGActionSheetSection;
@class PELMMainSupport;

typedef NSArray *(^PEPageRefresherBlk)(id);
typedef NSArray *(^PEPageLoaderBlk)(id);
typedef void (^PETableCellContentViewStyler)(UITableViewCell *, UIView *, id);
typedef void (^PEItemSelectedAction)(id, NSIndexPath *, UIViewController *, UITableView *);
typedef void (^PEItemChangedBlk)(id, NSIndexPath *);
typedef UIViewController *(^PEDetailViewMaker)(PEListViewController *, id, NSIndexPath *, PEItemChangedBlk);
typedef BOOL (^PEDoesEntityBelongToListView)(PELMMainSupport *);
typedef NSIndexPath *(^PEWouldBeIndexOfEntity)(id);

typedef NSDictionary *(^PEComponentsMakerBlk)(UIViewController *, UIView *);
typedef UIView *(^PEEntityPanelMakerBlk)(PEAddViewEditController *);
typedef UIView *(^PEEntityViewPanelMakerBlk)(PEAddViewEditController *, id, id);
typedef void (^PEPanelToEntityBinderBlk)(UIView *, id);
typedef void (^PEEntityToPanelBinderBlk)(id, UIView *);
typedef void (^PEEnableDisablePanelBlk)(UIView *, BOOL);
typedef BOOL (^PEEntityEditPreparerBlk)(PEAddViewEditController *, id, BOOL);
typedef void (^PEEntityEditCancelerBlk)(PEAddViewEditController *, id);
typedef void (^PEEntityAddCancelerBlk)(PEAddViewEditController *, BOOL, id);
typedef NSArray *(^PEEntitiesFromEntityBlk)(id);
typedef id   (^PEEntityMakerBlk)(UIView *);
typedef void (^PESaveEntityBlk)(PEAddViewEditController *, id);
typedef void (^PESyncNotFoundBlk)(float, NSString *, NSString *);
typedef void (^PESyncSuccessBlk)(float, NSString *, NSString *);
typedef void (^PEDownloadSuccessBlk)(float, NSString *, NSString *, id);
typedef void (^PESyncServerTempErrorBlk)(float, NSString *, NSString *);
typedef void (^PESyncForbiddenErrorBlk)(float, NSString *, NSString *);
typedef void (^PESyncServerErrorBlk)(float, NSString *, NSString *, NSArray *);
typedef void (^PESyncAuthRequiredBlk)(float, NSString *, NSString *);
typedef void (^PESyncForbiddenBlk)(float, NSString *, NSString *);
typedef void (^PESyncRetryAfterBlk)(float, NSString *, NSString *, NSDate *);
typedef void (^PESyncDependencyUnsynced)(float, NSString *, NSString *, NSString *);
typedef void (^PEEntitySyncCancelerBlk)(PELMMainSupport *, NSError *, NSNumber *);
typedef BOOL (^PEIsAuthenticatedBlk)(void);
typedef BOOL (^PEIsLoggedInBlk)(void);
typedef BOOL (^PEIsBadAccountBlk)(void);
typedef BOOL (^PEIsOfflineModeBlk)(void);
typedef NSInteger (^PENumRemoteDepsNotLocal)(id);
typedef void (^PEUpdateDepsPanel)(PEAddViewEditController *, id);
typedef void (^PEPostDownloaderSaver)(PEAddViewEditController *, id, id);
typedef NSInteger (^PEItemChildrenCounter)(id);
typedef NSArray * (^PEItemChildrenMsgsBlk)(id);
typedef void (^PEDependencyFetcherBlk)(PEAddViewEditController *,
                                       id,
                                       PESyncNotFoundBlk,
                                       PESyncSuccessBlk,
                                       PESyncRetryAfterBlk,
                                       PESyncServerTempErrorBlk,
                                       PESyncAuthRequiredBlk,
                                       PESyncForbiddenBlk);
typedef void (^PEDownloaderBlk)(PEAddViewEditController *,
                                id,
                                PESyncNotFoundBlk,
                                PEDownloadSuccessBlk,
                                PESyncRetryAfterBlk,
                                PESyncServerTempErrorBlk,
                                PESyncAuthRequiredBlk,
                                PESyncForbiddenBlk);
typedef void (^PEMarkAsDoneEditingLocalBlk)(PEAddViewEditController *, id);
typedef void (^PEMarkAsDoneEditingImmediateSyncBlk)(PEAddViewEditController *,
                                                    id,
                                                    PESyncNotFoundBlk,
                                                    PESyncSuccessBlk,
                                                    PESyncRetryAfterBlk,
                                                    PESyncServerTempErrorBlk,
                                                    PESyncServerErrorBlk,
                                                    PESyncAuthRequiredBlk,
                                                    PESyncForbiddenBlk,
                                                    PESyncDependencyUnsynced);
typedef void (^PEUploaderBlk)(PEAddViewEditController *,
                              id,
                              PESyncNotFoundBlk,
                              PESyncSuccessBlk,
                              PESyncRetryAfterBlk,
                              PESyncServerTempErrorBlk,
                              PESyncServerErrorBlk,
                              PESyncAuthRequiredBlk,
                              PESyncForbiddenBlk,
                              PESyncDependencyUnsynced);
typedef NSArray * (^PESaveNewEntityLocalBlk)(UIView *, id);
typedef void (^PESaveNewEntityImmediateSyncBlk)(UIView *,
                                                id,
                                                PESyncNotFoundBlk,
                                                PESyncSuccessBlk,
                                                PESyncRetryAfterBlk,
                                                PESyncServerTempErrorBlk,
                                                PESyncServerErrorBlk,
                                                PESyncAuthRequiredBlk,
                                                PESyncForbiddenBlk,
                                                PESyncDependencyUnsynced);
typedef void (^PEItemDeleter)(UIViewController *,
                              id,
                              NSIndexPath *,
                              PESyncNotFoundBlk,
                              PESyncSuccessBlk,
                              PESyncRetryAfterBlk,
                              PESyncServerTempErrorBlk,
                              PESyncServerErrorBlk,
                              PESyncAuthRequiredBlk,
                              PESyncForbiddenBlk);
typedef void (^PEItemLocalDeleter)(UIViewController *, id, NSIndexPath *);
typedef void (^PEItemLocalDiscarder)(UIViewController *, id, NSIndexPath *);
typedef void (^PEItemAddedBlk)(PEAddViewEditController *, id);
typedef void (^PEPrepareUIForUserInteractionBlk)(PEAddViewEditController *, UIView *);
typedef void (^PEViewDidAppearBlk)(id);
typedef NSArray *(^PEEntityValidatorBlk)(UIView *);
typedef BOOL (^PEPromptCurrentPasswordBlk)(UIView *, id);
typedef NSArray *(^PEMessagesFromErrMask)(NSInteger);
typedef void (^PEModalOperationStarted)(void);
typedef void (^PEModalOperationDone)(void);
typedef JGActionSheetSection *(^PEAddlContentSection)(PEAddViewEditController *, UIView *, id);
typedef void (^PEReauthReqdPostEditActivityBlk)(UIViewController *);
typedef void (^PEActionIfReauthReqdNotifObservedBlk)(UIViewController *);
typedef NSDate *(^PEImportedAt)(id);
typedef BOOL (^PEHasExceededImportLimit)(void);
typedef BOOL (^PEIsUserVerified)(void);

