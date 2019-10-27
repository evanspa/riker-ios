//
//  HCDeserializedPair.m
//

#import "HCDeserializedPair.h"

@implementation HCDeserializedPair {
  id _resourceModel;
  NSDictionary *_relations;
}

#pragma mark - Initializers

- (id)initWithResourceModel:(id)resourceModel
                  relations:(NSDictionary *)relations {
  self = [super init];
  if (self) {
    _resourceModel = resourceModel;
    _relations = relations;
  }
  return self;
}

@end
