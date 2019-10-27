//
//  PELMUIUtils.h
//

#import <Foundation/Foundation.h>
#import "PEUIToolkit.h"
#import "PEUIDefs.h"

@interface PELMUIUtils : NSObject

+ (PETableCellContentViewStyler)syncViewStylerWithUitoolkit:(PEUIToolkit *)uitoolkit
                                       subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                   subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                 isLoggedIn:(BOOL)isLoggedIn
                                               isEntityType:(BOOL)isEntityType;

+ (PETableCellContentViewStyler)syncViewStylerWithTitleBlk:(NSString *(^)(id))titleBlk
                                                 titleFont:(UIFont *)titleFont
                                          smallSubTitleBlk:(NSString *(^)(id))smallSubTitleBlk
                                        rightSideViewMaker:(UIView *(^)(id))rightSideViewMaker
                                    alwaysTopifyTitleLabel:(BOOL)alwaysTopifyTitleLabel
                                                 uitoolkit:(PEUIToolkit *)uitoolkit
                                      subtitleLeftHPadding:(CGFloat)subtitleLeftHPadding
                                  subtitleFitToWidthFactor:(CGFloat)subtitleFitToWidthFactor
                                                isLoggedIn:(BOOL)isLoggedIn
                                              isEntityType:(BOOL)isEntityType
                                   importLimitExceededMask:(NSNumber *)importLimitExceededMask
                     importedNotAllowedUnverifiedEmailMask:(NSNumber *)importedNotAllowedUnverifiedEmailMask;

@end
