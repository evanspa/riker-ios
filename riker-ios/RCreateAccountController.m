//
//  RCreateAccountController.m
//  riker-ios
//
//  Created by PEVANS on 10/30/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RCreateAccountController.h"
#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import <BlocksKit/UIControl+BlocksKit.h>
#import "UIColor+RAdditions.h"
#import "RCoordinatorDao.h"
#import "PELMUser.h"
#import "RScreenToolkit.h"
#import "RUIUtils.h"
#import "RUserSettings.h"
#import "RUtils.h"
#import "NSString+PEAdditions.h"
#import "RAppNotificationNames.h"
#import "PEUtils.h"
#import "RErrorDomainsAndCodes.h"
#import "AppDelegate.h"
#import "RLogging.h"
#import "PELocalDao.h"
@import Firebase;
#import "RPanelToolkit.h"

typedef NS_ENUM (NSInteger, RCreateAccountTag) {
  RCreateAccountTagEmail = 1,
  RCreateAccountTagPassword,
  RCreateAccountTagConfirmPassword
};

@interface RCreateAccountController ()
@property (nonatomic) NSUInteger formStateMaskForAcctCreation;
@end

@implementation RCreateAccountController {
  id<RCoordinatorDao> _coordDao;
  UITextField *_emailTf;
  UITextField *_passwordTf;
  UITextField *_confirmPasswordTf;
  PEUIToolkit *_uitoolkit;
  RScreenToolkit *_screenToolkit;
  NSNumber *_preserveExistingLocalEntities;
  RACDisposable *_disposable;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                     uitoolkit:(PEUIToolkit *)uitoolkit
                 screenToolkit:(RScreenToolkit *)screenToolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"90-Day Trial Sign Up"];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(handleCancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleAccountCreation)]];
  [_confirmPasswordTf setDelegate:self];
}

- (UIView *)parentViewForAlerts {
  return [PEUIUtils parentViewForAlertsForController:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_passwordTf resignFirstResponder];
  [self handleAccountCreation];
  return YES;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  CGFloat leftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UILabel *createAccountMsgLabel = [PEUIUtils labelWithKey:@"From here you can create a Riker account. This will \
enable your data records to be synced to Riker's server so you can access them from your other devices."
                                               font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                    backgroundColor:[UIColor clearColor]
                                          textColor:[UIColor darkGrayColor]
                                verticalTextPadding:3.0
                                         fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  UIView *createAccountMsgPanel = [PEUIUtils leftPadView:createAccountMsgLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]];
  CGFloat commonTfHeight = [PEUIUtils heightForUserAccountTextfields];
  _emailTf = tfMaker(@"unauth.start.ca.emailtf.pht");
  [_emailTf setTag:RCreateAccountTagEmail];
  [_emailTf setKeyboardType:UIKeyboardTypeEmailAddress];
  [_emailTf setFont:font];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_emailTf];
  _passwordTf = tfMaker(@"unauth.start.ca.pwdtf.pht");
  [_passwordTf setTag:RCreateAccountTagPassword];
  [_passwordTf setSecureTextEntry:YES];
  [_passwordTf setFont:font];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_passwordTf];
  _confirmPasswordTf = tfMaker(@"unauth.start.ca.pwdtf.cpht");
  [_confirmPasswordTf setSecureTextEntry:YES];
  [_confirmPasswordTf setReturnKeyType:UIReturnKeyGo];
  [_confirmPasswordTf setTag:RCreateAccountTagConfirmPassword];
  [_confirmPasswordTf setFont:font];
  if (@available(iOS 12.0, *)) {
    [_passwordTf setTextContentType:UITextContentTypeNewPassword];
    [_confirmPasswordTf setTextContentType:UITextContentTypeNewPassword];
  } else if (@available(iOS 11.0, *)) {
    [_passwordTf setTextContentType:UITextContentTypePassword];
    [_confirmPasswordTf setTextContentType:UITextContentTypePassword];
  }
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_confirmPasswordTf];
  if (existingContentPanel) {
    [_emailTf setText:[(UITextField *)[existingContentPanel viewWithTag:RCreateAccountTagEmail] text]];
    [_passwordTf setText:[(UITextField *)[existingContentPanel viewWithTag:RCreateAccountTagPassword] text]];
    [_confirmPasswordTf setText:[(UITextField *)[existingContentPanel viewWithTag:RCreateAccountTagConfirmPassword] text]];
  }
  UILabel *havingTroubleLabel = [PEUIUtils labelWithAttributeText:AS(@"Having trouble?  Drop us a line at:")
                                                             font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                  backgroundColor:[UIColor clearColor]
                                                        textColor:[UIColor darkGrayColor]
                                              verticalTextPadding:3.0
                                                       fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  UIButton *rikerSupportEmailLabel = [PEUIUtils buttonWithKey:[APP rikerSupportEmail]
                                                         font:[RUIUtils rikerSupportEmailFont]
                                              backgroundColor:[UIColor clearColor]
                                                    textColor:[UIColor bootstrapPrimary]
                                 disabledStateBackgroundColor:[UIColor clearColor]
                                       disabledStateTextColor:[UIColor clearColor]
                                              verticalPadding:3.0
                                            horizontalPadding:0.0
                                                 cornerRadius:0.0
                                                       target:nil
                                                       action:nil];
  [rikerSupportEmailLabel bk_addEventHandler:^(id sender) {
    [RUtils contactRikerSupport];
  } forControlEvents:UIControlEventTouchUpInside];
  // place views
  [PEUIUtils placeView:createAccountMsgPanel
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = createAccountMsgPanel.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:_emailTf
                 below:createAccountMsgPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:7.0
              hpadding:0];
  totalHeight += _emailTf.frame.size.height + 7.0;
  [PEUIUtils placeView:_passwordTf
                 below:_emailTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:0];
  totalHeight += _passwordTf.frame.size.height + 5.0;
  [PEUIUtils placeView:_confirmPasswordTf
                 below:_passwordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:5.0
              hpadding:0];
  totalHeight += _confirmPasswordTf.frame.size.height + 5.0;
  UILabel *instructionLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Fill out the form and tap %@."
                                                                                         textToAccent:@"Done"
                                                                                       accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                           font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                backgroundColor:[UIColor clearColor]
                                                      textColor:[UIColor darkGrayColor]
                                            verticalTextPadding:3.0
                                                     fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  [PEUIUtils setFrameWidthOfView:instructionLabel ofWidth:1.05 relativeTo:instructionLabel];
  UIView *instructionPanel = [PEUIUtils leftPadView:instructionLabel padding:leftPadding];
  [PEUIUtils placeView:instructionPanel
                 below:_confirmPasswordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += instructionPanel.frame.size.height + 4.0;
  UILabel *emailSensitivityLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Your email address will %@ be shared with anybody, and we will not spam you with junk mail."
                                                                                              textToAccent:@"NOT"
                                                                                            accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                                font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                                     backgroundColor:[UIColor clearColor]
                                                           textColor:[UIColor darkGrayColor]
                                                 verticalTextPadding:3.0
                                                          fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  [PEUIUtils placeView:emailSensitivityLabel
                 below:instructionPanel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:10.0
              hpadding:leftPadding];
  totalHeight += emailSensitivityLabel.frame.size.height + 10.0;
  [PEUIUtils placeView:havingTroubleLabel
                 below:emailSensitivityLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:20.0
              hpadding:leftPadding];
  totalHeight += havingTroubleLabel.frame.size.height + 20.0;
  [PEUIUtils placeView:rikerSupportEmailLabel
                 below:havingTroubleLabel
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
alignmentRelativeToView:contentPanel
              vpadding:4.0
              hpadding:leftPadding];
  totalHeight += rikerSupportEmailLabel.frame.size.height;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  RACSignal *signal =
    [RACSignal combineLatest:@[_emailTf.rac_textSignal,
                               _passwordTf.rac_textSignal,
                               _confirmPasswordTf.rac_textSignal]
                      reduce:^(NSString *email,
                               NSString *password,
                               NSString *confirmPassword) {
                        NSUInteger createUsrErrMask = 0;
                        NSString *emailTrimmed = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        if ([emailTrimmed isBlank]) {
                          createUsrErrMask = createUsrErrMask | RSaveUsrEmailNotProvided | RSaveUsrAnyIssues;
                        } else if (![PEUtils validateEmailWithString:emailTrimmed]) {
                          createUsrErrMask = createUsrErrMask | RSaveUsrInvalidEmail | RSaveUsrAnyIssues;
                        }
                        if ([password isBlank]) {
                          createUsrErrMask = createUsrErrMask | RSaveUsrPasswordNotProvided | RSaveUsrAnyIssues;
                          if (![confirmPassword isBlank]) {
                            createUsrErrMask = createUsrErrMask | RSaveUsrConfirmPasswordOnlyProvided | RSaveUsrAnyIssues;
                          }
                        } else {
                          if ([confirmPassword isBlank]) {
                            createUsrErrMask = createUsrErrMask | RSaveUsrConfirmPasswordNotProvided | RSaveUsrAnyIssues;
                          } else {
                            if (![password isEqualToString:confirmPassword]) {
                              createUsrErrMask = createUsrErrMask | RSaveUsrPasswordConfirmPasswordDontMatch | RSaveUsrAnyIssues;
                            }
                          }
                        }
                        return @(createUsrErrMask);
                      }];
  _disposable = [signal setKeyPath:@"formStateMaskForAcctCreation" onObject:self nilValue:nil];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Event handling

- (void)handleCancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAccountCreation {
  [[self view] endEditing:YES];
  if (!([self formStateMaskForAcctCreation] & RSaveUsrAnyIssues)) {
    [RUtils handleAccountCreationOrContinueWithCoordDao:_coordDao
                                  enableUserInteraction:[self makeUserEnabledBlock]
                                             controller:self
                                   watchSessionDelegate:self
                                            hudDelegate:self
                                                  email:[_emailTf text]
                                               password:[_passwordTf text]
                                         facebookUserId:nil
                          preserveExistingLocalEntities:_preserveExistingLocalEntities
                  promptedPreserveExistingLocalEntities:^(BOOL preserve) {
                    _preserveExistingLocalEntities = [NSNumber numberWithBool:preserve];
                  }
                                 onSuccessDialogDismiss:^{
                                   [self dismissViewControllerAnimated:YES completion:nil];
                                 }];
  } else {
    NSArray *errMsgs = [RUtils computeSaveUsrErrMsgs:_formStateMaskForAcctCreation];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:[self parentViewForAlerts]];
  }
}

#pragma mark - Watch Session Delegate

- (void)session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
          error:(nullable NSError *)error {
  session.delegate = APP; // re-assign back to app delegate
  if (activationState == WCSessionActivationStateActivated) {
    [RUtils transferAllDataToAppleWatchInBgWithCoordDao:_coordDao session:session];
  }
}

- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo {
  // it's very unlikely this callback would ever get called.  The only way it can
  // get called is if immediately after tapping the 'push' button, they tap
  // to sync local bmls or sets from their Apple Watch.
  [APP session:session didReceiveUserInfo:userInfo];
}

@end
