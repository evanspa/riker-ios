//
//  RForgotPasswordController.m
//  riker-ios
//
//  Created by PEVANS on 10/28/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "RForgotPasswordController.h"
#import <ReactiveCocoa/UITextField+RACSignalSupport.h>
#import <ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACDisposable.h>
#import "AppDelegate.h"
#import "PEUtils.h"
#import "RCoordinatorDao.h"
#import "PELMUser.h"
#import "PEUIUtils.h"
#import "RUIUtils.h"
#import "RUtils.h"
#import "RErrorDomainsAndCodes.h"
#import "RAppNotificationNames.h"
@import Firebase;

@interface RForgotPasswordController ()
@property (nonatomic) NSInteger formStateMask;
@end

@implementation RForgotPasswordController {
  id<RCoordinatorDao> _coordDao;
  UITextField *_emailTf;
  CGFloat animatedDistance;
  PEUIToolkit *_uitoolkit;
  PELMUser *_user;
  RACDisposable *_disposable;
}

#pragma mark - Initializers

- (id)initWithStoreCoordinator:(id<RCoordinatorDao>)coordDao
                          user:(PELMUser *)user
                     uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Forgot Password"];
  if (self) {
    _coordDao = coordDao;
    _user = user;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - Cancel

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Controller Lifecyle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(cancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(handleSendPasswordResetLink)]];
  [_emailTf setDelegate:self];
  [_emailTf becomeFirstResponder];
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat iphoneXSafeInsetsSideVal = [PEUIUtils iphoneXSafeInsetsSide];
  CGFloat leftPadding = 8.0 + iphoneXSafeInsetsSideVal;
  UILabel *messageLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"Enter your email address and hit %@ and we'll send you an email with a link to reset your password."
                                                                                     textToAccent:@"Done"
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                       font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:(contentPanel.frame.size.width - (leftPadding * 2))];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  UIFont *font = [UIFont preferredFontForTextStyle:[PEUIUtils userAccountInfoFontTextStyle]];
  CGFloat commonTfHeight = [PEUIUtils heightForUserAccountTextfields];
  _emailTf = tfMaker(@"unauth.start.ca.emailtf.pht");
  [_emailTf setKeyboardType:UIKeyboardTypeEmailAddress];
  [_emailTf setFont:font];
  [PEUIUtils setFrameHeight:commonTfHeight ofView:_emailTf];
  [_emailTf setReturnKeyType:UIReturnKeyDone];
  if (_user) {
    [_emailTf setText:[_user email]];
  }
  
  // place views
  [PEUIUtils placeView:_emailTf
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:[RUIUtils contentPanelTopPadding]
              hpadding:0.0];
  CGFloat totalHeight = _emailTf.frame.size.height + [RUIUtils contentPanelTopPadding];
  [PEUIUtils placeView:messageLabelWithPad
                 below:_emailTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messageLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  [_disposable dispose];
  RACSignal *signal = [RACSignal combineLatest:@[_emailTf.rac_textSignal]
                                        reduce:^(NSString *email) {
                                          NSString *trimmedEmail = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                          // will just re-use existing 'save user' error codes for validation
                                          NSUInteger emailErrMask = 0;
                                          if ([trimmedEmail length] == 0) {
                                            emailErrMask = emailErrMask | RSaveUsrEmailNotProvided | RSaveUsrAnyIssues;
                                          } else if (![PEUtils validateEmailWithString:trimmedEmail]) {
                                            emailErrMask = emailErrMask | RSaveUsrInvalidEmail | RSaveUsrAnyIssues;
                                          }
                                          return @(emailErrMask);
                                        }];
  _disposable = [signal setKeyPath:@"formStateMask" onObject:self nilValue:nil];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_emailTf resignFirstResponder];
  [self handleSendPasswordResetLink];
  return YES;
}

#pragma mark - Login event handling

- (void)handleSendPasswordResetLink {
  REnableUserInteractionBlk enableUserInteraction = ^(BOOL enable) {
    [[[self navigationItem] leftBarButtonItem] setEnabled:enable];
    [[[self navigationItem] rightBarButtonItem] setEnabled:enable];
    [[[self tabBarController] tabBar] setUserInteractionEnabled:enable];
  };
  [self.view endEditing:YES];
  if (!([self formStateMask] & RSignInAnyIssues)) {
    MBProgressHUD *sendPasswordResetEmailHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    sendPasswordResetEmailHud.tag = RHUD_TAG;
    enableUserInteraction(NO);
    sendPasswordResetEmailHud.label.text = @"Sending password reset email...";
    NSString *emailAddress = [_emailTf text];
    emailAddress = [emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [_coordDao.userCoordinatorDao sendPasswordResetEmailToEmail:emailAddress
                                             remoteStoreBusyBlk:^(NSDate *retryAfter) {
                                               [RUtils logEvent:@"busy_wh_sending_pwd_r_link"];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                 [sendPasswordResetEmailHud hideAnimated:YES afterDelay:0.0];
                                                 [PEUIUtils showWaitAlertWithMsgs:nil
                                                                            title:@"Busy with maintenance."
                                                                 alertDescription:[[NSAttributedString alloc] initWithString:@"\
The server is currently busy at the moment undergoing maintenance.\n\n\
We apologize for the inconvenience.  Please try this again later."]
                                                              descLblHeightAdjust:0.0
                                                        additionalContentSections:nil
                                                                         topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                      buttonTitle:@"Okay."
                                                                     buttonAction:^{ enableUserInteraction(YES); }
                                                                   relativeToView:self.tabBarController.view];
                                               });
                                             }
                                                     successBlk:^{
                                                       [RUtils logEvent:@"success_sending_reset_pwd_r_link"];
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                         [sendPasswordResetEmailHud hideAnimated:YES afterDelay:0.0];
                                                         NSAttributedString *attrMessage =
                                                         [PEUIUtils attributedTextWithTemplate:@"The password reset email was sent to: %@."
                                                                                  textToAccent:emailAddress
                                                                                accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]];
                                                         [PEUIUtils showSuccessAlertWithTitle:@"Password reset e-mail sent."
                                                                             alertDescription:attrMessage
                                                                          descLblHeightAdjust:0.0
                                                                                     topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                  buttonTitle:@"Okay."
                                                                                 buttonAction:^{
                                                                                   [self dismissViewControllerAnimated:YES completion:^{
                                                                                     enableUserInteraction(YES);
                                                                                   }];
                                                                                 }
                                                                               relativeToView:self.view];
                                                       });
                                                     }
                                                unknownEmailBlk:^{
                                                  [RUtils logEvent:@"unknown_email_wh_sending_pwd_r_link"];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                    [sendPasswordResetEmailHud hideAnimated:YES afterDelay:0.0];
                                                    [PEUIUtils showErrorAlertWithMsgs:nil
                                                                                title:@"Unknown e-mail address."
                                                                     alertDescription:[[NSAttributedString alloc] initWithString:@"The email address you provided is not associated with any Riker accounts."]
                                                                  descLblHeightAdjust:0.0
                                                                             topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                          buttonTitle:@"Okay."
                                                                         buttonAction:^{ enableUserInteraction(YES); }
                                                                       relativeToView:self.view];
                                                  });
                                                }
                                           accountUnverifiedBlk:^{
                                             [RUtils logEvent:@"unveri_acct_wh_sending_pwd_r_link"];
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                               [sendPasswordResetEmailHud hideAnimated:YES afterDelay:0.0];
                                               [PEUIUtils showErrorAlertWithMsgs:nil
                                                                           title:@"Unverified account."
                                                                alertDescription:[[NSAttributedString alloc] initWithString:@"\
The account associated with the provided email address is not verified.\n\nFor security reasons, we cannot send password-reset links to it."]
                                                             descLblHeightAdjust:0.0
                                                                        topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                     buttonTitle:@"Okay."
                                                                    buttonAction:^{ enableUserInteraction(YES); }
                                                                  relativeToView:self.view];
                                             });
                                           }
                                                       errorBlk:^{
                                                         [RUtils logEvent:@"error_wh_sending_pwd_r_link"];
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                           [sendPasswordResetEmailHud hideAnimated:YES afterDelay:0.0];
                                                           [PEUIUtils showErrorAlertWithMsgs:nil
                                                                                       title:@"Something went wrong."
                                                                            alertDescription:[[NSAttributedString alloc] initWithString:@"\
Oops.  Something went wrong in attempting to send you a password reset email.  Please try this again a little later."]
                                                                         descLblHeightAdjust:0.0
                                                                                    topInset:[PEUIUtils topInsetForAlertsWithController:self]
                                                                                 buttonTitle:@"Okay."
                                                                                buttonAction:^{ enableUserInteraction(YES); }
                                                                              relativeToView:self.view];
                                                         });
                                                       }];
  } else {
    [RUtils logEvent:@"form_val_errs_password_reset"];
    NSArray *errMsgs = [RUtils computeSaveUsrErrMsgs:_formStateMask];
    [PEUIUtils showWarningAlertWithMsgs:errMsgs
                                  title:@"Oops"
                       alertDescription:[[NSAttributedString alloc] initWithString:@"There are some validation errors:"]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay."
                           buttonAction:nil
                         relativeToView:self.view];
  }
}


@end
