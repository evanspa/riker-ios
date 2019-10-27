//
//  PEWebViewScreen.h
//  riker-ios
//
//  Created by PEVANS on 9/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEBaseController.h"

@class PEUIToolkit;

@interface PEWebViewScreen : PEBaseController <UIWebViewDelegate>

#pragma mark - Initializers

- (id)initWithUitoolkit:(PEUIToolkit *)uitoolkit
                  title:(NSString *)title
        loadingErrorMsg:(NSString *)loadingErrorMsg
              urlString:(NSString *)urlString;

@end
