//
// PEDatePickerController.h
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

/* A generic view controller for picking a date. */
@interface PEDatePickerController : PEBaseController

///------------------------------------------------
/// @name Initialization
///------------------------------------------------
#pragma mark - Initialization

/**
 * Returns and initializes a new date picker view controller.
 * @param title               The title for the view controller.
 * @param initialDate         The default date for the picker.
 * @param logDatePickedAction The block to execute upon the user selecting a date.
 * @return A newly initialized date picker.
 */
- (id)initWithTitle:(NSString *)title
   heightPercentage:(CGFloat)heightPercentage
        initialDate:(NSDate *)initialDate
     datePickerMode:(UIDatePickerMode)datePickerMode
logDatePickedAction:(void(^)(NSDate *))logDatePickedAction;

@end
