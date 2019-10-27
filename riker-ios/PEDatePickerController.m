//
// PEDatePickerController.m
//

#import "PEDatePickerController.h"
@import Firebase;
#import "RUtils.h"

@implementation PEDatePickerController {
  NSDate *_date;
  CGFloat _heightPercentage;
  UIDatePicker *_datePicker;
  NSString *_title;
  UIDatePickerMode _datePickerMode;
  void (^_logDatePickedAction)(NSDate *);
}

#pragma mark - Initializers

- (id)initWithTitle:(NSString *)title
   heightPercentage:(CGFloat)heightPercentage
        initialDate:(NSDate *)initialDate
     datePickerMode:(UIDatePickerMode)datePickerMode
logDatePickedAction:(void(^)(NSDate *))logDatePickedAction {
  self = [super initWithRequireRepaintNotifications:nil screenTitle:title];
  if (self) {
    _title = title;
    _heightPercentage = heightPercentage;
    _date = initialDate;
    _datePickerMode = datePickerMode;
    _logDatePickedAction = logDatePickedAction;
  }
  return self;
}

#pragma mark - Build UI

- (void)buildUi {
  _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0,
                                                               80,
                                                               self.view.frame.size.width,
                                                               (_heightPercentage * self.view.frame.size.height))];
  [_datePicker setDatePickerMode:_datePickerMode];
  [_datePicker setDate:_date animated:YES];
  [[self view] addSubview:_datePicker];
}

#pragma mark - Device Rotation notification

- (void)willRepaintDueToRotate {
  _date = _datePicker.date;
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [[self view] setBackgroundColor:[UIColor whiteColor]];
  [self buildUi];
}

- (void)viewDidAppear:(BOOL)animated {
  if (self.needsRepaint) {
    if (_datePicker) {
      [_datePicker removeFromSuperview];
    }
    [self buildUi];
  }
  [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
  _logDatePickedAction([_datePicker date]);
  [super viewWillDisappear:animated];
}

@end
