//
//  LineChartDataSet+RAdditions.m
//  Riker
//
//  Created by PEVANS on 1/29/18.
//  Copyright © 2018 Riker. All rights reserved.
//

#import "LineChartDataSet+RAdditions.h"
#import <objc/runtime.h>

@implementation LineChartDataSet (RAdditions)
@dynamic entityLocalMasterIdentifier;
@dynamic localId;

- (NSNumber *)entityLocalMasterIdentifier {
  return objc_getAssociatedObject(self, @selector(entityLocalMasterIdentifier));
}

- (void)setEntityLocalMasterIdentifier:(NSNumber *)entityLocalMasterIdentifier {
  objc_setAssociatedObject(self, @selector(entityLocalMasterIdentifier), entityLocalMasterIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)localId {
  return objc_getAssociatedObject(self, @selector(localId));
}

- (void)setLocalId:(NSNumber *)localId {
  objc_setAssociatedObject(self, @selector(localId), localId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
