//
//  RLoadingDataFromiPhoneController.m
//  riker-ios
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "RLoadingDataFromiPhoneController.h"
#import "RExtensionDelegate.h"
#import "RExtensionUtils.h"
#import "RWatchUtils.h"

@implementation RLoadingDataFromiPhoneController {
  NSString *_loadingLabelText;
}

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  if (context) {
    _loadingLabelText = context;
  } else {
    _loadingLabelText = @"Loading data from iPhone...";
  }
  [_label setText:_loadingLabelText];
  [_activityImage setImageNamed:@"Activity"];
  [_activityImage startAnimatingWithImagesInRange:NSMakeRange(0, 15) duration:1.0 repeatCount:0];
}

- (void)willActivate {
  [super willActivate];
  WCSession *session = [WCSession defaultSession];
  if ([session activationState] == WCSessionActivationStateActivated) {
    if (session.reachable) {
      session.delegate = self;
      [self fetchiPhoneDataWithSession:session];
    } else {
      [self handleNotReachable];
    }
  } else {
    session.delegate = self;
    [session activateSession];
  }
}

- (void)switchToErrorStateWithMessage:(NSString *)message {
  [_activityImage stopAnimating];
  [_activityImage setImageNamed:@"oops-icon"];
  [_label setText:message];
}

- (void)handleNotReachable {
  // we need the slight delay to ensure the spinner icon has had enough time to
  // at least render itself once, so that real-estate is carved out for it, so
  // that when we display the oops icon, it will show up.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.125 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [self switchToErrorStateWithMessage:@"iPhone not reachable."];
  });
}

#pragma mark - Session activated handler

- (void)fetchiPhoneDataWithSession:(WCSession *)session {
  [session transferUserInfo:@{ RWATCHMSG_ACTION_KEY : @(RWatchMsgActionFetchAllIPhoneData) }];
}

#pragma mark - Watch Connectivity Delegate

- (void)session:(WCSession * __nonnull)session
didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer
          error:(nullable NSError *)error {
  session.delegate = EXT; // re-assign back to extension delegate
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.875 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [_activityImage stopAnimating];
    if (error) {
      [_activityImage setImageNamed:@"oops-icon"];
      [self setTitle:@"Problem connecting to iPhone.  Make sure it is reachable and try again."];
    } else {
      [_activityImage setImageNamed:@"success-icon"];
      [self setTitle:@"Close"];
      [_label setText:@"Open Riker on your iPhone to complete the sync."];
    }
  });
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  [EXT session:session didReceiveUserInfo:userInfo];
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
          error:(nullable NSError *)error {
  switch (activationState) {
    case WCSessionActivationStateInactive:
      session.delegate = EXT; // re-assign back to extension delegate
      [self handleNotReachable];
      break;
    case WCSessionActivationStateActivated:
      if (session.reachable) {
        [self fetchiPhoneDataWithSession:session];
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
}

@end



