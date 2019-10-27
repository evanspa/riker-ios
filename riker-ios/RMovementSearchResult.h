//
//  RMovementSearchResult.h
//  riker-ios
//
//  Created by PEVANS on 5/15/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMovementSearchResult : NSObject

#pragma mark - Properties

@property (nonatomic) NSNumber *id;
@property (nonatomic) NSString *canonicalName;
@property (nonatomic) NSNumber *variantMask;
@property (nonatomic) BOOL isBodyLift;
@property (nonatomic) NSDecimalNumber *percentageOfBodyWeight;
@property (nonatomic, readonly) NSMutableArray *aliases;

@end
