//
//  PEProvideCurrentPasswordController.m
//  riker-ios
//
//  Created by PEVANS on 12/18/16.
//  Copyright © 2016 Riker. All rights reserved.
//

#import "PEProvideCurrentPasswordController.h"
#import "PEUIUtils.h"
#import "PEUIToolkit.h"
#import "NSString+PEAdditions.h"
@import Firebase;
#import "RUtils.h"
#import "RUIUtils.h"

@implementation PEProvideCurrentPasswordController {
  void(^_actionOnDone)(NSString *);
  void(^_cancelAction)(void);
  PEUIToolkit *_uitoolkit;
  UITextField *_passwordTf;
}

#pragma mark - Initializers

- (id)initWithActionOnDone:(void(^)(NSString *))actionOnDone
              cancelAction:(void(^)(void))cancelAction
                 uitoolkit:(PEUIToolkit *)uitoolkit {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:@"Enter Current Password"];
  if (self) {
    _actionOnDone = actionOnDone;
    _cancelAction = cancelAction;
    _uitoolkit = uitoolkit;
  }
  return self;
}

#pragma mark - Hide Keyboard

- (void)hideKeyboard {
  [self.view endEditing:YES];
}

#pragma mark - Bar Button Actions

- (void)done {
  [self hideKeyboard];
  NSString *passwordVal = [_passwordTf text];
  if ([passwordVal isBlank]) {
    [PEUIUtils showWarningAlertWithMsgs:nil
                                  title:@"Oops."
                       alertDescription:[[NSAttributedString alloc] initWithString:@"Please provide your current password."]
                    descLblHeightAdjust:0.0
                               topInset:[PEUIUtils topInsetForAlertsWithController:self]
                            buttonTitle:@"Okay"
                           buttonAction:nil
                         relativeToView:self.view];
  } else {
    [self dismissViewControllerAnimated:YES completion:^{ _actionOnDone(passwordVal); }];
  }
}

- (void)cancel {
  [self dismissViewControllerAnimated:YES completion:_cancelAction];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_passwordTf resignFirstResponder];
  [self done];
  return YES;
}

#pragma mark - Make Content

- (NSArray *)makeContentWithOldContentPanel:(UIView *)existingContentPanel {
  UIView *contentPanel = [PEUIUtils panelWithWidthOf:[PEUIUtils widthOfForContent] relativeToView:self.view fixedHeight:0.0];
  CGFloat leftPadding = 8.0;
  [PEUIUtils setFrameHeightOfView:contentPanel ofHeight:0.5 relativeTo:[self view]];
  UILabel *messageLabel = [PEUIUtils labelWithAttributeText:[PEUIUtils attributedTextWithTemplate:@"In order to carry out this operation, please provide your current password."
                                                                                     textToAccent:@"Done"
                                                                                   accentTextFont:[PEUIUtils boldFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]]
                                                       font:[UIFont preferredFontForTextStyle:[PEUIUtils subheadlineFontTextStyle]]
                                            backgroundColor:[UIColor clearColor]
                                                  textColor:[UIColor darkGrayColor]
                                        verticalTextPadding:3.0
                                                 fitToWidth:(contentPanel.frame.size.width - leftPadding - 10.0)];
  UIView *messageLabelWithPad = [PEUIUtils leftPadView:messageLabel padding:leftPadding];
  TextfieldMaker tfMaker = [_uitoolkit textfieldMakerForWidthOf:1.0 relativeTo:contentPanel];
  _passwordTf = tfMaker(@"Current password");
  [_passwordTf setSecureTextEntry:YES];
  [_passwordTf setReturnKeyType:UIReturnKeyDone];
  [_passwordTf setDelegate:self];
  [PEUIUtils setFrameHeight:[PEUIUtils heightForUserAccountTextfields] ofView:_passwordTf];
  // place views
  [PEUIUtils placeView:_passwordTf
               atTopOf:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:20.0
              hpadding:0.0];
  CGFloat totalHeight = _passwordTf.frame.size.height + 20.0;
  [PEUIUtils placeView:messageLabelWithPad
                 below:_passwordTf
                  onto:contentPanel
         withAlignment:PEUIHorizontalAlignmentTypeLeft
              vpadding:4.0
              hpadding:0.0];
  totalHeight += messageLabelWithPad.frame.size.height + 4.0;
  [PEUIUtils setFrameHeight:totalHeight ofView:contentPanel];
  return @[contentPanel, @(YES), @(NO)];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [RUIUtils styleNavbarForController:self];
  [[self view] setBackgroundColor:[_uitoolkit colorForWindows]];
  UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [gestureRecognizer setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:gestureRecognizer];
  UINavigationItem *navItem = [self navigationItem];
  [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]];
  [navItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [_passwordTf becomeFirstResponder];
}

@end
