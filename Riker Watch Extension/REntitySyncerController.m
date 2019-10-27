//
//  REntitySyncerControllerr.m
//  Riker Watch Extension
//
//  Created by PEVANS on 10/16/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "REntitySyncerController.h"
#import "RExtensionDelegate.h"
#import "RExtensionUtils.h"
#import "RWatchUtils.h"

@implementation REntitySyncerController {
  NSString *_entityType;
  NSArray *_entityFiles;
  NSNumber *_msgAction;
  NSString *_entitiesJsonFileName;
  NSString *_entitiesJsonArrayKey;
  NSTimer *_timeoutTimer;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  NSDictionary *contextDict = (NSDictionary *)context;
  _entityType = contextDict[@"entity-type"];
  _entityFiles = contextDict[@"entity-files"];
  _msgAction = contextDict[@"msg-action"];
  _entitiesJsonFileName = contextDict[@"entities-json-filename"];
  _entitiesJsonArrayKey = contextDict[@"entities-json-array-key"];
  [_activityImage setImageNamed:@"Activity"];
  [_activityImage startAnimatingWithImagesInRange:NSMakeRange(0, 15) duration:1.0 repeatCount:0];
  [_label setText:[NSString stringWithFormat:@"Syncing %ld %@%@ to iPhone...",
                   (long)_entityFiles.count,
                   _entityType,
                   _entityFiles.count > 1 ? @"s" : @""]];
  WCSession *session = [WCSession defaultSession];
  if ([session activationState] == WCSessionActivationStateActivated) {
    if (session.reachable) {
      session.delegate = self;
      [self syncEntitiesToDeviceWithSession:session];
    } else {
      [self handleNotReachable];
    }
  } else {
    session.delegate = self;
    [session activateSession];
  }
}

- (void)handleNotReachable {
  // we need the slight delay to ensure the spinner icon has had enough time to
  // at least render itself once, so that real-estate is carved out for it, so
  // that when we display the oops icon, it will show up.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self handleError:@"iPhone not reachable."];
  });
}

- (void)handleUnknownError {
  [self handleError:@"Error syncing to iPhone.  It may not be reachable."];
}

- (void)handleError:(NSString *)msg {
  WCSession *session = [WCSession defaultSession];
  session.delegate = EXT; // re-assign back to extension delegate
  [_activityImage stopAnimating];
  [_activityImage setImageNamed:@"oops-icon"];
  [_label setText:msg];
  [self setTitle:@"Close"];
}

#pragma mark - Timeout Handler

- (void)timeoutHandler:(NSTimer *)timer {
  [timer invalidate];
  WCSession *session = [WCSession defaultSession];
  session.delegate = EXT; // re-assign back to extension delegate
  dispatch_async(dispatch_get_main_queue(), ^{
    [self presentControllerWithName:@"UntimelySync" context:nil];
  });
}

#pragma mark - Session activated handler

- (void)syncEntitiesToDeviceWithSession:(WCSession *)session {
  NSInteger numEntityFiles = _entityFiles.count;
  NSMutableArray *entitiesPayload = [NSMutableArray arrayWithCapacity:numEntityFiles];
  NSMutableArray *lastPathComponentEntityFiles = [NSMutableArray arrayWithCapacity:_entityFiles.count];
  for (NSInteger i = 0; i < numEntityFiles; i++) {
    NSString *entityFile = _entityFiles[i];
    [lastPathComponentEntityFiles addObject:entityFile.lastPathComponent];
    NSMutableDictionary *entity = [RExtensionUtils dictionaryFromAbsoluteFilePath:entityFile];
    NSNumber *loggedAtUnixTime = entity[@"logged-at"];
    entity[@"logged-at"] = [NSDate dateWithTimeIntervalSince1970:([loggedAtUnixTime doubleValue] / 1000.0)];
    [entitiesPayload addObject:entity];
  }
  _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                   target:self
                                                 selector:@selector(timeoutHandler:)
                                                 userInfo:nil
                                                  repeats:NO];
  [session transferUserInfo:@{ RWATCHMSG_ACTION_KEY : _msgAction,
                               RWATCHMSG_PAYLOAD_KEY : entitiesPayload,
                               RWATCHMSG_LOCAL_ENTITY_FILES_KEY: lastPathComponentEntityFiles }];
}

#pragma mark - Watch Connectivity Delegate

- (void)session:(WCSession * __nonnull)session
didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer
          error:(nullable NSError *)error {
  [_timeoutTimer invalidate];
  session.delegate = EXT; // re-assign back to extension delegate  
  NSInteger numEntityFiles = _entityFiles.count;
  NSNumber *syncRequested = error != nil ? @(NO) : @(YES);
  for (NSInteger i = 0; i < numEntityFiles; i++) {
    NSString *entityFile = _entityFiles[i];
    NSMutableDictionary *entity = [RExtensionUtils dictionaryFromAbsoluteFilePath:entityFile];
    entity[@"sync-requested"] = syncRequested;
    [RExtensionUtils saveDictionary:entity toDocumentsFolderWithFilename:[entityFile lastPathComponent]];
  }
  // update entities json file (used for displaying recent entities)
  NSDictionary *entitiesDict = [RExtensionUtils dictionaryFromDocumentsFolderWithFilename:_entitiesJsonFileName];
  NSArray *currentEntities = entitiesDict[_entitiesJsonArrayKey];
  NSMutableArray *newEntities = [NSMutableArray arrayWithCapacity:currentEntities.count];
  for (NSDictionary *entity in currentEntities) {
    NSMutableDictionary *mutableEntity = [NSMutableDictionary dictionaryWithDictionary:entity];
    NSNumber *syncedToIPhone = mutableEntity[@"synced-to-iphone"];
    if (!syncedToIPhone || !syncedToIPhone.boolValue) {
      mutableEntity[@"sync-requested"] = @(YES);
    }
    [newEntities addObject:mutableEntity];
  }
  [RExtensionUtils pruneOldestIfTooManyEntities:newEntities];
  [RExtensionUtils saveDictionary:@{ _entitiesJsonArrayKey: newEntities }
    toDocumentsFolderWithFilename:_entitiesJsonFileName];
  if (error) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [_activityImage stopAnimating];
      [_activityImage setImageNamed:@"oops-icon"];
      [self setTitle:@"Problem syncing to iPhone.  Make sure it is reachable and try again."];
    });
  } else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      [_activityImage stopAnimating];
      [_activityImage setImageNamed:@"success-icon"];
      [self setTitle:@"Close"];
      [_label setText:[NSString stringWithFormat:@"Your %d %@%@ been sent to your iPhone.", _entityFiles.count, _entityType, _entityFiles.count > 1 ? @"s have" : @" has"]];
    });
  }
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  [EXT session:session didReceiveUserInfo:userInfo];
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
          error:(nullable NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    switch (activationState) {
      case WCSessionActivationStateInactive:
        session.delegate = EXT; // re-assign back to extension delegate
        [self handleNotReachable];
        break;
      case WCSessionActivationStateActivated:
        if (session.reachable) {
          [self syncEntitiesToDeviceWithSession:session];
        } else {
          session.delegate = EXT; // re-assign back to extension delegate
          [self handleNotReachable];
        }
        break;
      case WCSessionActivationStateNotActivated:
        session.delegate = EXT; // re-assign back to extension delegate
        [self handleNotReachable];
        break;
    }
  });
}

@end



