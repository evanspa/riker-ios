//
//  PELMStripeTokenSerializer.m
//  riker-ios
//
//  Created by PEVANS on 1/18/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import "PELMStripeTokenSerializer.h"
#import <Stripe/Stripe.h>
#import "PELMUser.h"

@implementation PELMStripeTokenSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMUser *user = (PELMUser *)resourceModel;
  return user.stripeToken.allResponseFields;
}

@end
